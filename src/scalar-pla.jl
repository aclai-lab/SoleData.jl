module PLA

using SoleData
using SoleData: test_operator, feature, threshold
using SoleLogics
import SoleLogics as SL
using DataStructures: OrderedDict

_removewhitespaces = x->replace(x, (' ' => ""))

# # Function to extract thresholds and build domains for each variable
# function extract_domains(conds::AbstractVector{<:SoleData.AbstractCondition})
#     # @assert all(a->test_operator(a) in [(<), (<=), (>), (>=), (==), (!=)], conds)
#     domains = OrderedDict{SoleData.AbstractFeature,Set}()
#     map(conds) do cond
#         if cond isa SoleData.ScalarCondition
#             push!(get!(domains, feature(cond), Set()), threshold(cond))
#         elseif cond isa SoleData.RangeScalarCondition
#             let x = SoleData.minval(cond)
#                 !isnothing(x) && push!(get!(domains, feature(cond), Set()), x)
#             end
#             let x = SoleData.maxval(cond)
#                 !isnothing(x) && push!(get!(domains, feature(cond), Set()), x)
#             end
#         end
#     end
#     return OrderedDict(k => sort(collect(v)) for (k, v) in domains)
# end


# Function to encode a disjunct into a PLA row
function encode_disjunct(disjunct::LeftmostConjunctiveForm, features::AbstractVector, conditions::AbstractVector, includes, excludes, cond_idxss)
    pla_row = fill("-", length(conditions))
    # For each atom in the disjunct, add zeros or ones to relevants
    for lit in SoleLogics.grandchildren(disjunct)
        # @show lit
        cond = SoleLogics.value(atom(lit))
        feature = SoleData.feature(cond)
        i_feat = findfirst((f)->f==feature, features)
        cond_idxs = cond_idxss[i_feat]
        @show cond_idxs
        @show cond
        icond = findfirst(c->c==cond, conditions[cond_idxs])
        @show icond
        # pla_row[map(c->c==cond, conditions)] .= SoleLogics.ispos(lit) ? "1" : "0"
        if SoleData.hasdual(cond)
            idualcond = findfirst(c->c==SoleData.dual(cond), conditions[cond_idxs])
            @show idualcond
            # pla_row[map(c->c==SoleData.dual(cond), conditions)] .= SoleLogics.ispos(lit) ? "0" : "1"
        end

        if SoleLogics.ispos(lit)
            if !isnothing(icond)
                @views pla_row[cond_idxs][map(((ic,c),)->includes[i_feat][icond,ic], enumerate(cond_idxs))] .= "1"
                @views pla_row[cond_idxs][map(((ic,c),)->excludes[i_feat][icond,ic], enumerate(cond_idxs))] .= "0"
            end
        else
            if SoleData.hasdual(cond) && !isnothing(idualcond)
                @views pla_row[cond_idxs][map(((ic,c),)->includes[i_feat][idualcond,ic], enumerate(cond_idxs))] .= "1"
                @views pla_row[cond_idxs][map(((ic,c),)->excludes[i_feat][idualcond,ic], enumerate(cond_idxs))] .= "0"
            end
        end
    end

    return pla_row
end

# Function to parse and process the formula into PLA
# function _formula_to_pla(syntaxtree::SoleLogics.Formula, dc_set = false, silent = true, args...; encoding = :multivariate, kwargs...)
function _formula_to_pla(syntaxtree::SoleLogics.Formula, dc_set = false, silent = true, args...; encoding = :univariate, kwargs...)
    @assert encoding in [:univariate, :multivariate]
    
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
    features = unique(SoleData.feature.(conditions))
    # nnbinary_vars =div(length(setdiff(_duals, conditions)), 2)
    _patchnothing(v, d) = isnothing(v) ? d : v
    sort!(conditions, by=cond->(syntaxstring(SoleData.feature(cond)), _patchnothing(SoleData.minval(cond), -Inf), _patchnothing(SoleData.maxval(cond), Inf)))
    original_conditions = conditions
    println(SoleLogics.displaysyntaxvector(original_conditions))
    conditions = begin
        newconds = SoleData.AbstractCondition[]
        for feat in features
            conds = filter(c->feature(c) == feat, conditions)
            # @show syntaxstring.(conds)
            minextremes = [(true, (SoleData.minval(cond), !SoleData.minincluded(cond))) for cond in conds]
            maxextremes = [(false, (SoleData.maxval(cond), SoleData.maxincluded(cond))) for cond in conds]
            extremes = [minextremes..., maxextremes...]
            sort!(extremes, by=((ismin, (mv, mi)),)->(_patchnothing(mv, ismin ? -Inf : Inf), mi))
            extremes = map(last, extremes)
            extremes = unique(extremes)
            @show extremes
            for (minextreme,maxextreme) in zip(extremes[1:end-1], extremes[2:end])
                # @show maxextreme
                cond = SoleData.RangeScalarCondition(feat, minextreme[1], maxextreme[1], !minextreme[2], maxextreme[2])
                push!(newconds, cond)
            end
        end
        # @show syntaxstring.(newconds)
        newconds
    end
    @assert length(setdiff(original_conditions, conditions)) == 0 "$(setdiff(original_conditions, conditions))"
    # readline()
    conditions = begin
        SoleData.hasdual.(conditions)
        newconditions = similar(conditions, (0,))
        for cond in conditions
            if !SoleData.hasdual(cond) || !(SoleData.dual(cond) in newconditions)
                push!(newconditions, cond)
            end
        end
        # conditions = [condition for condition in conditions if !(condition in _duals)]
        newconditions
    end
    # readline()
    sort!(conditions, by=cond->(syntaxstring(SoleData.feature(cond)), _patchnothing(SoleData.minval(cond), -Inf), _patchnothing(SoleData.maxval(cond), Inf)))
    # @show length(conditions)
    # @show syntaxstring.(conditions)

    println(SoleLogics.displaysyntaxvector(conditions))
    feat_nvars = []
    varlabelss = []
    for feat in features
        conds = filter(c->feature(c) == feat, conditions)
        push!(feat_nvars, length(conds))
        varlabels = _removewhitespaces.(syntaxstring.(conds))
        push!(varlabelss, varlabels)
    end

    @show syntaxstring.(conditions)
    @show feat_nvars
    # @show varlabelss
    
    cond_idxss = []
    includes = []
    excludes = []
    for feat in features
        cond_idxs = findall(c->feature(c) == feat, conditions)
        push!(cond_idxss, cond_idxs)
        push!(includes, [SoleData.includes(conditions[cond_i], conditions[cond_j]) for cond_i in cond_idxs, cond_j in cond_idxs])
        push!(excludes, [SoleData.excludes(conditions[cond_j], conditions[cond_i]) for cond_i in cond_idxs, cond_j in cond_idxs])
    end

    # @show ilb_str
    # Generate PLA header
    pla_header = []
    if encoding == :multivariate
        num_binary_vars = sum(feat_nvars .== 1)
        num_nonbinary_vars = sum(feat_nvars .> 1) + 1
        @show feat_nvars .== 1
        @show num_binary_vars
        @show num_nonbinary_vars
        num_vars = num_binary_vars + num_nonbinary_vars
        push!(pla_header, ".mv $(num_vars) $(num_binary_vars) $(join(feat_nvars[feat_nvars .> 1], " ")) 1")
        if num_binary_vars > 0
            ilb_str = join(vcat(varlabelss[feat_nvars .== 1]...), " ")
            push!(pla_header, ".ilb " * ilb_str)  # Input variable labels
        end
        for i_var in 1:length(feat_nvars[feat_nvars .> 1])
            if feat_nvars[feat_nvars .> 1][i_var] > 1
                this_ilb_str = join(varlabelss[i_var], " ")
                push!(pla_header, ".label var=$(num_binary_vars+i_var-1) $(this_ilb_str)")
            end
        end
    else
        num_outputs = 1
        num_vars = length(conditions)
        ilb_str = join(vcat(varlabelss...), " ")
        push!(pla_header, ".i $(num_vars)")
        push!(pla_header, ".o $(num_outputs)")
        push!(pla_header, ".ilb " * ilb_str)  # Input variable labels
        push!(pla_header, ".ob formula_output")
    end

    @show pla_header

    # Generate ON-set rows for each disjunct
    end_idxs = cumsum(feat_nvars)
    @show feat_nvars
    feat_varidxs = [(startidx:endidx) for (startidx,endidx) in zip([1, (end_idxs.+1)...],end_idxs)]
    @show feat_varidxs
    pla_onset_rows = []
    for disjunct in SoleLogics.disjuncts(dnfformula)
        row = encode_disjunct(disjunct, features, conditions, includes, excludes, cond_idxss)
        if encoding == :multivariate
            # Binary variables first
            @show row
            binary_variable_idxs = findall(feat_nvar->feat_nvar == 1, feat_nvars)
            nonbinary_variable_idxs = findall(feat_nvar->feat_nvar > 1, feat_nvars)
            row = vcat(
                [row[feat_varidxs[i_var]] for i_var in binary_variable_idxs]...,
                (num_binary_vars > 0 ? ["|"] : [])...,
                [[row[feat_varidxs[i_var]]..., "|"] for i_var in nonbinary_variable_idxs]...
            )
            push!(pla_onset_rows, "$(join(row, ""))1")
        else
            push!(pla_onset_rows, "$(join(row, "")) 1")  # Append "1" for the ON-set output
        end
    end

    # # Generate DC-set rows for each disjunct
    pla_dcset_rows = []
    # TODO remove
    # @assert !(dc_set && encoding == :multivariate)
    # if dc_set
    #     for feat in features
    #         cond_idxs = findall(c->feature(c) == feat, conditions)
    #         # cond_idxs = collect(eachindex(conditions))
    #         # cond_mask = map((c)->feature(c) == feat, conditions)
    #         includes = [SoleData.includes(conditions[cond_i], conditions[cond_j]) for cond_i in cond_idxs, cond_j in cond_idxs]
    #         excludes = [SoleData.excludes(conditions[cond_i], conditions[cond_j]) for cond_i in cond_idxs, cond_j in cond_idxs]
    #         for (i,cond_i) in enumerate(cond_idxs)
    #             for (j,cond_j) in enumerate(cond_idxs)
    #                 if includes[i, j]
    #                     println("$(syntaxstring(conditions[cond_i])) -> $(syntaxstring(conditions[cond_j]))")
    #                 end
    #                 if excludes[j, i]
    #                     println("$(syntaxstring(conditions[cond_i])) -> !$(syntaxstring(conditions[cond_j]))")
    #                 end
    #             end
    #         end
    #         print(includes)
    #         print(excludes)
    #         for (i,cond_i) in enumerate(cond_idxs)
    #             row = fill("-", length(conditions))
    #             row[cond_i] = "1"
    #             for (j,cond_j) in enumerate(cond_idxs)
    #                 if includes[j, i]
    #                     row[cond_j] = "1"
    #                 elseif excludes[j, i]
    #                     row[cond_j] = "0"
    #                 end
    #             end
    #             push!(pla_dcset_rows, "$(join(row, "")) -") # Append "-" for the DC-set output
    #         end
    #     end
    #     println(pla_dcset_rows)
    #     # readline()
    # end

    # Combine PLA components
    pla_content = [
        join(pla_header, "\n"),
        join(pla_dcset_rows, "\n"),
        join(pla_onset_rows, "\n"),
        ".e"
    ]
    c = strip(join(pla_content, "\n"))
    return c, nothing, conditions
end

function _pla_to_formula(pla::AbstractString, ilb_str = nothing, conditions = nothing)
    # @show ilb_str, conditions
    # Split the PLA into lines and parse key components
    lines = split(pla, '\n')
    input_vars = []
    output_var = ""
    rows = []

    multivalued_info = Dict()  # To store multi-valued variable metadata
    total_vars, nbinary_vars, multivalued_sizes = 0, 0, []
    println(lines)
    # Parse header and rows
    for line in lines
        line = strip(line)
        @show line
        parts = split(line)

        isempty(parts) && continue

        cmd, args = parts[1], parts[2:end]

        if cmd == ".mv"
            total_vars, nbinary_vars = parse(Int, args[1]), parse(Int, args[2])
            multivalued_sizes = parse.(Int, args[3:end])
        elseif cmd == ".label"
            var_id = parse(Int, match(r"var=(\d+)", line).captures[1])
            labels = args[2:end]
            multivalued_info[var_id] = labels
        elseif cmd == ".i"  # Input variables count
            total_vars, nbinary_vars = parse(Int, args[1]), parse(Int, args[1])
        elseif cmd == ".o"  # Output variables count
            @assert parse(Int, args[1]) == 1
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
        elseif cmd[1] in ['0', '1', '-', '|']
            push!(rows, join(parts, ""))  # Add rows to data structure
        else
            throw("Unknown PLA command: $cmd")
        end
    end

    # Map input variables to conditions
    conditions_map = if !isempty(conditions)
        Dict(_removewhitespaces(syntaxstring(c)) => c for c in conditions)
    else
        Dict()
    end

    @show total_vars, nbinary_vars
    @show input_vars
    # parsed_conditions = [begin
    #     if !isnothing(conditions)
    #         idx = findfirst(c->_removewhitespaces(syntaxstring(c)) == _removewhitespaces(var_str), conditions)
    #         !isnothing(idx) ? conditions[idx] : parsecondition(ScalarCondition, var_str)
    #     else
    #         parsecondition(ScalarCondition, var_str)
    #     end
    # end for var_str in input_vars]

    @show multivalued_info
    parsed_conditions = []
    binary_idx = 1
    parsefun = c->parsecondition(SoleData.RangeScalarCondition, c, featuretype = SoleData.VariableValue)
    for (i, size) in enumerate([(1:nbinary_vars)..., multivalued_sizes...])
        if i <= nbinary_vars
            cond = (binary_idx ∈ eachindex(input_vars) ? conditions_map[input_vars[binary_idx]] : parsefun(input_vars[binary_idx]))
            push!(parsed_conditions, cond)
            binary_idx += 1
        else
            # Multi-valued conditions are stored as a group
            condnames = (haskey(multivalued_info, i) ? multivalued_info[i] : [])
            conds = map(parsefun, condnames)
            push!(parsed_conditions, conds)
        end
    end

    @show syntaxstring.(parsed_conditions)

    # Process rows to build the formula
    disjuncts = []
    for row in rows
        parts = split(row, "|")
        
        binary_part = parts[1]

        if (total_vars == nbinary_vars)
            binary_part, output_value = binary_part[1:end-1], binary_part[end]
            # @show row_values
            if output_value != '1'  # Only process ON-set rows
                continue
            end
        end
        conjuncts = []        

        # Process binary variables
        # Convert row values back into parsed_conditions
        for (idx, value) in enumerate(binary_part)
            @show value            
            cond = parsed_conditions[idx]
            if value == '1'
                push!(conjuncts, Atom(cond))
            elseif value == '0'
                push!(conjuncts, ¬(Atom(cond)))
            end
        end
        
        if length(parts) > 1
            multiple_part = parts[2:end]
            # Process multi-valued variables
            for (i, multi_part) in enumerate(multiple_part)
                var_labels = multivalued_info[nbinary_vars + i + 1]
                selected = findfirst('1' == c for c in multi_part)
                if selected
                    push!(conjuncts, Atom(var_labels[selected]))
                end
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
