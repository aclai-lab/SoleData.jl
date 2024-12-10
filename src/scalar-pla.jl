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
function encode_disjunct(disjunct::LeftmostConjunctiveForm, features::AbstractVector, conditions::AbstractVector, includes, excludes, feat_condindxss)
    pla_row = fill("-", length(conditions))
    # For each atom in the disjunct, add zeros or ones to relevants
    for lit in SoleLogics.grandchildren(disjunct)
        # @show syntaxstring(lit)
        ispos = SoleLogics.ispos(lit)
        cond = SoleLogics.value(atom(lit))
        # @show cond

        i_feat = findfirst((f)->f==SoleData.feature(cond), features)
        feat_condindxs = feat_condindxss[i_feat]
        # @show feat_condindxs
        feat_icond = findfirst(c->c==cond, conditions[feat_condindxs])
        feat_idualcond = SoleData.hasdual(cond) ? findfirst(c->c==SoleData.dual(cond), conditions[feat_condindxs]) : nothing
        # @show feat_icond, feat_idualcond
        @assert !(isnothing(feat_icond) && isnothing(feat_idualcond))

        # if ispos
        #     @show excludes[i_feat]
        #     if !isnothing(feat_icond)
        #         @views pla_row[feat_condindxs][map(ic->includes[i_feat][feat_icond,ic], eachindex(feat_condindxs))] .= "1"
        #         @views pla_row[feat_condindxs][map(ic->excludes[i_feat][feat_icond,ic], eachindex(feat_condindxs))] .= "0"
        #     end
        # else
        #     # if !isnothing(feat_idualcond)
        #     #     @views pla_row[feat_condindxs][map(ic->includes[i_feat][feat_idualcond,ic], eachindex(feat_condindxs))] .= "0"
        #     #     @views pla_row[feat_condindxs][map(ic->excludes[i_feat][feat_idualcond,ic], eachindex(feat_condindxs))] .= "1"
        #     # end
        # end
        POS, NEG = ispos ? ("1", "0") : ("0", "1")
        if !isnothing(feat_icond)
            @views pla_row[feat_condindxs][map(((ic,c),)->includes[i_feat][feat_icond,ic], enumerate(feat_condindxs))] .= POS
            @views pla_row[feat_condindxs][map(((ic,c),)->excludes[i_feat][feat_icond,ic], enumerate(feat_condindxs))] .= NEG
        end
        if !isnothing(feat_idualcond)
            @views pla_row[feat_condindxs][map(((ic,c),)->includes[i_feat][feat_idualcond,ic], enumerate(feat_condindxs))] .= NEG
            @views pla_row[feat_condindxs][map(((ic,c),)->excludes[i_feat][feat_idualcond,ic], enumerate(feat_condindxs))] .= POS
        end
    end
    # println(pla_row)
    return pla_row
end

# Function to parse and process the formula into PLA
function _formula_to_pla(
    formula::SoleLogics.Formula,
    dc_set = false,
    silent = true,
    args...;
    encoding = :univariate,
    use_scalar_range_conditions = false,
    kwargs...
)
    @assert encoding in [:univariate, :multivariate]
    
    scalar_kwargs = (;
        profile = :nnf,
        allow_atom_flipping = true,
    )

    dnfformula = SoleLogics.dnf(formula, Atom; scalar_kwargs..., kwargs...)

    scalar_simplification_kwargs = (;
        force_scalar_range_conditions = use_scalar_range_conditions, 
        allow_scalar_range_conditions = use_scalar_range_conditions,
    )
    silent || @show dnfformula
    
    dnfformula = SoleData.scalar_simplification(dnfformula;
        scalar_simplification_kwargs...
    )

    silent || @show dnfformula

    # scalar_kwargs = (;
    #     profile = :nnf,
    #     allow_atom_flipping = true,
    #     forced_negation_removal = false,
    #     # flip_atom = a -> SoleData.polarity(SoleData.test_operator(SoleLogics.value(a))) == false
    # )

    dnfformula = SoleLogics.dnf(dnfformula; scalar_kwargs..., 
    kwargs...)

    _patchnothing(v, d) = isnothing(v) ? d : v

    for ch in SoleLogics.grandchildren(dnfformula)
        sort!(SoleLogics.grandchildren(ch), by=lit->SoleData._scalarcondition_sortby(SoleLogics.value(SoleLogics.atom(lit))))
    end
    silent || @show dnfformula

    # Extract domains
    conditions = unique(map(SoleLogics.value, atoms(dnfformula)))
    features = unique(SoleData.feature.(conditions))
    sort!(features, by=syntaxstring)
    # nnbinary_vars =div(length(setdiff(_duals, conditions)), 2)
    sort!(conditions, by=SoleData._scalarcondition_sortby)
    silent || println(SoleLogics.displaysyntaxvector(features))
    silent || println(SoleLogics.displaysyntaxvector(conditions))
    if use_scalar_range_conditions
        original_conditions = conditions
        silent || println(SoleLogics.displaysyntaxvector(conditions))
        conditions = SoleData.scalartiling(conditions, features)
        @assert length(setdiff(original_conditions, conditions)) == 0 "$(SoleLogics.displaysyntaxvector(setdiff(original_conditions, conditions)))"
    end
    # readline()
    conditions = SoleData.removeduals(conditions)
    silent || println(SoleLogics.displaysyntaxvector(conditions))

    # For each feature, derive the conditions, and their names.
    feat_condindxss, feat_conds, feat_condnames = zip(map(features) do feat
        feat_condindxs = findall(c->feature(c) == feat, conditions)
        conds = filter(c->feature(c) == feat, conditions)
        condname = _removewhitespaces.(syntaxstring.(conds))
        (feat_condindxs, conds, condname)
    end...)

    feat_nconds = length.(feat_conds)
    
    silent || @show feat_nconds
    silent || @show feat_condnames
    
    # Derive inclusions and exclusions between conditions
    includes, excludes = [], []
    for (i,feat_condindxs) in enumerate(feat_condindxss)
        # silent || @show feat_condnames[i]
        this_includes = [SoleData.includes(conditions[cond_i], conditions[cond_j]) for cond_i in feat_condindxs, cond_j in feat_condindxs]
        this_excludes = [SoleData.excludes(conditions[cond_j], conditions[cond_i]) for cond_i in feat_condindxs, cond_j in feat_condindxs]
        # println(this_includes)
        # println(this_excludes)
        push!(includes, this_includes)
        push!(excludes, this_excludes)
    end

    # silent || @show ilb_str
    # Generate PLA header
    pla_header = []
    if encoding == :multivariate
        @warn "encoding = :multivariate is untested."
        num_binary_vars = sum(feat_nconds .== 1)
        num_nonbinary_vars = sum(feat_nconds .> 1) + 1
        silent || @show feat_nconds .== 1
        silent || @show num_binary_vars
        silent || @show num_nonbinary_vars
        num_vars = num_binary_vars + num_nonbinary_vars
        push!(pla_header, ".mv $(num_vars) $(num_binary_vars) $(join(feat_nconds[feat_nconds .> 1], " ")) 1")
        if num_binary_vars > 0
            ilb_str = join(vcat(feat_condnames[feat_nconds .== 1]...), " ")
            push!(pla_header, ".ilb " * ilb_str)  # Input variable labels
        end
        for i_var in 1:length(feat_nconds[feat_nconds .> 1])
            if feat_nconds[feat_nconds .> 1][i_var] > 1
                this_ilb_str = join(feat_condnames[feat_nconds .> 1][i_var], " ")
                push!(pla_header, ".label var=$(num_binary_vars+i_var-1) $(this_ilb_str)")
            end
        end
    else
        num_outputs = 1
        num_vars = length(conditions)
        ilb_str = join(vcat(feat_condnames...), " ")
        push!(pla_header, ".i $(num_vars)")
        push!(pla_header, ".o $(num_outputs)")
        push!(pla_header, ".ilb " * ilb_str)  # Input variable labels
        push!(pla_header, ".ob formula_output")
    end

    silent || @show pla_header

    # Generate ON-set rows for each disjunct
    end_idxs = cumsum(feat_nconds)
    silent || @show feat_nconds
    feat_varidxs = [(startidx:endidx) for (startidx,endidx) in zip([1, (end_idxs.+1)...], end_idxs)]
    silent || @show feat_varidxs
    pla_onset_rows = []
    for disjunct in SoleLogics.disjuncts(dnfformula)
        row = encode_disjunct(disjunct, features, conditions, includes, excludes, feat_condindxss)
        if encoding == :multivariate
            # Binary variables first
            silent || @show row
            binary_variable_idxs = findall(feat_nvar->feat_nvar == 1, feat_nconds)
            nonbinary_variable_idxs = findall(feat_nvar->feat_nvar > 1, feat_nconds)
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
    #         feat_condindxs = findall(c->feature(c) == feat, conditions)
    #         # feat_condindxs = collect(eachindex(conditions))
    #         # cond_mask = map((c)->feature(c) == feat, conditions)
    #         includes = [SoleData.includes(conditions[cond_i], conditions[cond_j]) for cond_i in feat_condindxs, cond_j in feat_condindxs]
    #         excludes = [SoleData.excludes(conditions[cond_i], conditions[cond_j]) for cond_i in feat_condindxs, cond_j in feat_condindxs]
    #         for (i,cond_i) in enumerate(feat_condindxs)
    #             for (j,cond_j) in enumerate(feat_condindxs)
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
    #         for (i,cond_i) in enumerate(feat_condindxs)
    #             row = fill("-", length(conditions))
    #             row[cond_i] = "1"
    #             for (j,cond_j) in enumerate(feat_condindxs)
    #                 if includes[j, i]
    #                     row[cond_j] = "1"
    #                 elseif excludes[j, i]
    #                     row[cond_j] = NEG
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
        ".p $(length(pla_onset_rows))",
        join(pla_onset_rows, "\n"),
        ".e"
    ]
    c = strip(join(pla_content, "\n"))
    return c, (nothing, conditions), (
        encoding = encoding,
        use_scalar_range_conditions = use_scalar_range_conditions,
        kwargs...
    )
end

function _pla_to_formula(
    pla::AbstractString,
    silent = true,
    ilb_str = nothing,
    conditions = nothing;
    conditionstype = SoleData.ScalarCondition,
    featuretype = SoleData.VariableValue,
    featvaltype = nothing,
    kwargs...
)
    # @show ilb_str, conditions
    # Split the PLA into lines and parse key components
    lines = split(pla, '\n')
    input_vars = []
    output_var = ""
    rows = []

    multivalued_info = Dict()  # To store multi-valued variable metadata
    total_vars, nbinary_vars, multivalued_sizes = 0, 0, []
    silent || println(lines)
    # Parse header and rows
    for line in lines
        line = strip(line)
        silent || @show line
        parts = split(line)

        isempty(parts) && continue

        cmd, args = parts[1], parts[2:end]

        if cmd == ".mv"
            @warn "PLA: Multivalued variables not tested."
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
                @assert ilb_str == this_ilb_str "Mismatch between given ilb_str and parsed .ilb.\n$(ilb_str)\n$(this_ilb_str)."
            end
            input_vars = split(this_ilb_str)  # Extract input variable labels
        elseif cmd == ".ob"  # Output labels
            output_var = join(args, " ")  # Extract output variable label
        elseif cmd == ".e"  # End marker
            break
        elseif cmd[1] in ['0', '1', '-', '|']
            push!(rows, join(parts, ""))  # Add rows to data structure
        else
            throw(ArgumentError("Unknown PLA command: $cmd"))
        end
    end

    # Map input variables to conditions
    conditions_map = if !isnothing(conditions)
        Dict(_removewhitespaces(syntaxstring(c)) => c for c in conditions)
    else
        Dict()
    end

    silent || @show total_vars, nbinary_vars
    silent || @show input_vars
    # parsed_conditions = [begin
    #     if !isnothing(conditions)
    #         idx = findfirst(c->_removewhitespaces(syntaxstring(c)) == _removewhitespaces(var_str), conditions)
    #         !isnothing(idx) ? conditions[idx] : parsecondition(ScalarCondition, var_str)
    #     else
    #         parsecondition(ScalarCondition, var_str)
    #     end
    # end for var_str in input_vars]

    silent || @show multivalued_info
    parsed_conditions = []
    binary_idx = 1
    parsefun = c->parsecondition(conditionstype, c; featuretype, featvaltype)
    silent || @show nbinary_vars, multivalued_sizes
    for (i_var, domain_size) in enumerate([fill(2, nbinary_vars)..., multivalued_sizes...])
        silent || @show (i_var, domain_size)
        if i_var <= nbinary_vars
            silent || @show i_var ∈ eachindex(input_vars)
            silent || @show input_vars
            silent || @show conditions_map
            condname = i_var ∈ eachindex(input_vars) ? input_vars[i_var] : "?"
            cond = (condname ∈ keys(conditions_map) ? conditions_map[condname] : parsefun(condname))
            push!(parsed_conditions, cond)
        else
            # Multi-valued conditions are stored as a group
            condnames = (haskey(multivalued_info, i_var) ? multivalued_info[i_var] : [])
            conds = map(parsefun, condnames)
            push!(parsed_conditions, conds)
        end
    end

    silent || @show syntaxstring.(parsed_conditions)

    # Process rows to build the formula
    disjuncts = []
    for row in rows
        parts = split(row, r" |\|")
        silent || @show parts
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
            # @show value            
            cond = parsed_conditions[idx]
            if value == '1'
                push!(conjuncts, Literal(true, Atom(cond)))
            elseif value == '0'
                push!(conjuncts, Literal(false, Atom(cond)))
            elseif value == '-'
                nothing
            else
                error("Unexpected truth value: '$(value)'.")
            end
        end
        
        if length(parts) > 1
            multiple_part = parts[2:end]
            # Process multi-valued variables
            for (i, multi_part) in enumerate(multiple_part)
                var_labels = multivalued_info[nbinary_vars + i + 1]
                selected = findfirst('1' == c for c in multi_part)
                if selected
                    push!(conjuncts, Literal(true, Atom(var_labels[selected])))
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
        map!(d->SoleData.scalar_simplification(d;
            force_scalar_range_conditions=false,
            allow_scalar_range_conditions=false,
        ), disjuncts, disjuncts)
        return SL.LeftmostDisjunctiveForm(disjuncts)
    else
        return ⊤  # True formula
    end
end


# function formula_to_emacs(expr::SyntaxTree) end


end
