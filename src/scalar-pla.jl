module PLA

using SoleData
using SoleData: test_operator, feature, threshold
using SoleLogics
import SoleLogics as SL
using DataStructures: OrderedDict

_removewhitespaces = x->replace(x, (' ' => ""))

# Function to extract thresholds and build domains for each variable
function extract_domains(conds::AbstractVector{<:SoleData.AbstractCondition})
    # @assert all(a->test_operator(a) in [(<), (<=), (>), (>=), (==), (!=)], conds)
    domains = OrderedDict{SoleData.AbstractFeature,Set}()
    map(conds) do cond
        if cond isa SoleData.ScalarCondition
            push!(get!(domains, feature(cond), Set()), threshold(cond))
        elseif cond isa SoleData.RangeScalarCondition
            let x = SoleData.minval(cond)
                !isnothing(x) && push!(get!(domains, feature(cond), Set()), x)
            end
            let x = SoleData.maxval(cond)
                !isnothing(x) && push!(get!(domains, feature(cond), Set()), x)
            end
        end
    end
    return OrderedDict(k => sort(collect(v)) for (k, v) in domains)
end

# Function to encode a disjunct into a PLA row
function encode_disjunct(disjunct::LeftmostConjunctiveForm, domains::OrderedDict, conditions::AbstractVector)
    # pla_row = []
    pla_row = fill("-", length(conditions))
    
    # For each atom in the disjunct, add zeros or ones to relevants
    for lit in SoleLogics.grandchildren(disjunct)
        # @show lit
        cond = SoleLogics.value(atom(lit))
        pla_row[map(c->c==cond, conditions)] .= SoleLogics.ispos(lit) ? "1" : "0"
        # cond = SoleLogics.value(atom)
        # feat = SoleData.feature(cond)
        # @show cond
        # domain = domains[feat]
        # @show domain
        # first_idx = findfirst(cond->SoleData.feature(cond) == feat, conditions)
        # minidxs = map(d->SoleData.honors_minval(cond, d), domain)  # Find the threshold index
        # maxidxs = map(d->SoleData.honors_maxval(cond, d), domain)  # Find the threshold index
        # @show minidxs
        # @show maxidxs
        # pla_row[first_idx:(first_idx+length(domain)-1)][(!).(minidxs) .&& maxidxs] .= "1"
        # pla_row[first_idx:(first_idx+length(domain)-1)][minidxs .&& (!).(maxidxs)] .= "0"
    end

    # # For each atom in the disjunct, add zeros or ones to relevants
    # for atom in atoms(disjunct)
    #     cond = SoleLogics.value(atom)
    #     feat = SoleData.feature(cond)
    #     @show cond
    #     domain = domains[feat]
    #     @show domain
    #     first_idx = findfirst(cond->SoleData.feature(cond) == feat, conditions)
    #     minidxs = map(d->SoleData.honors_minval(cond, d), domain)  # Find the threshold index
    #     maxidxs = map(d->SoleData.honors_maxval(cond, d), domain)  # Find the threshold index
    #     @show minidxs
    #     @show maxidxs
    #     pla_row[first_idx:(first_idx+length(domain)-1)][(!).(minidxs) .&& maxidxs] .= "1"
    #     pla_row[first_idx:(first_idx+length(domain)-1)][minidxs .&& (!).(maxidxs)] .= "0"
    # end

    # for cond in conditions
    #     feat = SoleData.feature(cond)
    #     domain = domains[feat]
    #     @show syntaxstring(cond), syntaxstring(feat), domain
    #     # Default row is all "-" (don't care)

    #     # Check if the feature appears in the disjunct
    #     atms = Iterators.filter(a->SoleData.feature(SoleLogics.value(a)) == feat, atoms(disjunct))
    #     @assert length(collect(atms)) <= 1 "$(collect(atms))"
    #     for atom in atms
    #         cond = SoleLogics.value(atom)
    #         @show cond
    #         # operator = SoleData.test_operator(cond)
    #         feat = SoleData.feature(cond)
    #         minidxs = map(d->SoleData.honors_minval(cond, d), domain)  # Find the threshold index
    #         maxidxs = map(d->SoleData.honors_maxval(cond, d), domain)  # Find the threshold index
    #         @show minidxs
    #         @show maxidxs
    #         row[(!).(minidxs) .&& maxidxs] .= "1"
    #         row[minidxs .&& (!).(maxidxs)] .= "0"
    #     end

    #     # # Append the encoded row for this variable
    #     # push!(pla_row, join(row, ""))
    # end
    return join(pla_row, "")  # Combine into a single string
    # return pla_row
end

# Function to parse and process the formula into PLA
function _formula_to_pla(syntaxtree::SoleLogics.Formula, dc_set = false, silent = true, args...; kwargs...)

    scalar_kwargs = (;
        profile = :nnf,
        allow_atom_flipping = true,
    )

    dnfformula = SoleLogics.dnf(syntaxtree, Atom; scalar_kwargs..., kwargs...)

    silent || @show dnfformula

    dnfformula = SoleLogics.LeftmostDisjunctiveForm(map(d->SoleData.scalar_simplification(d; force_scalar_range_conditions=true), SoleLogics.disjuncts(dnfformula)))

    silent || @show dnfformula

    # scalar_kwargs = (;
    #     profile = :nnf,
    #     allow_atom_flipping = true,
    #     forced_negation_removal = false,
    #     # flip_atom = a -> SoleData.polarity(SoleData.test_operator(SoleLogics.value(a))) == false
    # )

    dnfformula = SoleLogics.dnf(dnfformula; scalar_kwargs..., kwargs...)

    silent || @show dnfformula

    # Extract domains
    conditions = unique(map(SoleLogics.value, atoms(dnfformula)))
    _patchnothing(v, d) = isnothing(v) ? d : v
    sort!(conditions, by=cond->(syntaxstring(SoleData.feature(cond)), _patchnothing(SoleData.minval(cond), -Inf), _patchnothing(SoleData.maxval(cond), Inf)))
    domains = extract_domains(conditions)
    # @show domains
    # @show syntaxstring.(conditions)

    allvarlabels = []
    for (i_feat, (feat, domain)) in enumerate(pairs(domains))
        conds = filter(c->feature(c) == feat, conditions)
        varlabels = _removewhitespaces.(syntaxstring.(conds))
        append!(allvarlabels, varlabels)
    end
    ilb_str = join(allvarlabels, " ")
    # @show ilb_str
    # Generate PLA header
    # num_vars = sum(length(v) for v in values(domains))  # Total PLA variables
    num_vars = length(conditions)
    # @show [length(v) for v in values(domains)]
    # featnames = map(syntaxstring, collect(keys(domains)))
    num_outputs = 1
    pla_header = [
        # ".mv $(num_vars + num_outputs) $(num_vars + num_outputs)",
        ".i $(num_vars)",
        ".o $(num_outputs)",
        ".ilb " * ilb_str,  # Input variable labels
        ".ob formula_output"
    ]

    # Generate variable labels
    # pla_labels = String[]
    # push!(pla_labels, ".label var=$(i_feat-1) $(join(varlabels, ' '))")

    # Generate DC-set rows for each disjunct
    pla_dcset_rows = []
    if dc_set
        for (i_feat, (feat, domain)) in enumerate(pairs(domains))
            cond_idxs = findall(c->feature(c) == feat, conditions)
            # cond_idxs = collect(eachindex(conditions))
            # cond_mask = map((c)->feature(c) == feat, conditions)
            inclusions = [SoleData.includes(conditions[cond_i], conditions[cond_j]) for cond_i in cond_idxs, cond_j in cond_idxs]
            excludes = [SoleData.excludes(conditions[cond_i], conditions[cond_j]) for cond_i in cond_idxs, cond_j in cond_idxs]
            for (i,cond_i) in enumerate(cond_idxs)
                for (j,cond_j) in enumerate(cond_idxs)
                    if inclusions[i, j]
                        println("$(syntaxstring(conditions[cond_i])) -> $(syntaxstring(conditions[cond_j]))")
                    end
                    if excludes[j, i]
                        println("$(syntaxstring(conditions[cond_i])) -> !$(syntaxstring(conditions[cond_j]))")
                    end
                end
            end
            print(inclusions)
            print(excludes)
            for (i,cond_i) in enumerate(cond_idxs)
                row = fill("-", length(conditions))
                row[cond_i] = "1"
                for (j,cond_j) in enumerate(cond_idxs)
                    if inclusions[j, i]
                        row[cond_j] = "1"
                    elseif excludes[j, i]
                        row[cond_j] = "0"
                    end
                end
                push!(pla_dcset_rows, "$(join(row, "")) -") # Append "-" for the DC-set output
            end
        end
        println(pla_dcset_rows)
        readline()
    end

    # Generate ON-set rows for each disjunct
    pla_onset_rows = []
    for disjunct in SoleLogics.disjuncts(dnfformula)
        row = encode_disjunct(disjunct, domains, conditions)
        push!(pla_onset_rows, "$row 1")  # Append "1" for the ON-set output
    end

    # Combine PLA components
    pla_content = [
        join(pla_header, "\n"),
        # join(pla_labels, "\n"),
        join(pla_dcset_rows, "\n"),
        join(pla_onset_rows, "\n"),
        ".e"
    ]
    c = strip(join(pla_content, "\n"))
    return c, ilb_str, conditions
end

function _pla_to_formula(pla::AbstractString, ilb_str = nothing, conditions = nothing)
    # @show ilb_str, conditions
    # Split the PLA into lines and parse key components
    lines = split(pla, '\n')
    input_vars = []
    output_var = ""
    rows = []

    # Parse header and rows
    for line in lines
        line = strip(line)
        # @show line
        parts = split(line)

        isempty(parts) && continue

        cmd = parts[1]
        args = parts[2:end]

        if cmd == ".i"  # Input variables count
            continue
        elseif cmd == ".o"  # Output variables count
            continue
        elseif cmd == ".p"
            continue
        elseif cmd == ".ilb"  # Input labels
            this_ilb_str = join(args, " ")
            if !isnothing(ilb_str)
                @assert ilb_str == this_ilb_str "Mismatch between given ilb_str and parsed .ilb."
            end
            input_vars = split(this_ilb_str)  # Extract input variable labels
        elseif cmd == ".ob"  # Output labels
            output_var = join(args, " ")  # Extract output variable label
        elseif cmd == ".e"  # End marker
            break
        elseif cmd[1] in ['0', '1', '-']
            push!(rows, join(parts, ""))  # Add rows to data structure
        else
            throw("Unknown PLA command: $cmd")
        end
    end

    # @show domains
    # @show input_vars
    conditions
    this_conditions = [begin
        if !isnothing(conditions)
            idx = findfirst(c->_removewhitespaces(syntaxstring(c)) == _removewhitespaces(var_str), conditions)
            !isnothing(idx) ? conditions[idx] : parsecondition(ScalarCondition, var_str)
        else
            parsecondition(ScalarCondition, var_str)
        end
    end for var_str in input_vars]
    # @show syntaxstring.(this_conditions)

    # Process rows to build the formula
    disjuncts = []
    for row in rows
        # @show row
        row_values, output_value = row[1:end-1], row[end]
        # @show row_values
        if output_value != '1'  # Only process ON-set rows
            continue
        end
        conjuncts = []

        # Convert row values back into this_conditions
        for (idx,value) in enumerate(row_values)
            # @show value
            if value == '1'
                push!(conjuncts, Atom(this_conditions[idx]))
            elseif value == '0'
                push!(conjuncts, ¬(Atom(this_conditions[idx])))
            end
        end

        # Combine conjuncts into a conjunctive form
        if !isempty(conjuncts)
            push!(disjuncts, SL.LeftmostConjunctiveForm(conjuncts))
        end
    end


    # Combine disjuncts into a disjunctive form
    φ = if !isempty(disjuncts)
        map!(d->SoleData.scalar_simplification(d; force_scalar_range_conditions=false), disjuncts, disjuncts)
        return SL.LeftmostDisjunctiveForm(disjuncts)
    else
        return ⊤  # True formula
    end
end


function formula_to_emacs(expr::SyntaxTree) end


end
