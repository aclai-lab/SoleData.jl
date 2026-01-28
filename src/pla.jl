using SoleLogics
using SoleData
using SoleModels

using SoleData: PLA

# ---------------------------------------------------------------------------- #
#                                   types                                      #
# ---------------------------------------------------------------------------- #
const LiteralBool = Dict('1' => true, '0' => false)

# ---------------------------------------------------------------------------- #
#                                get conjuncts                                 #
# ---------------------------------------------------------------------------- #
@inline  _get_conjuncts(a::Vector{Vector{Atom}}) = _get_conjuncts.(a)
@inline  _get_conjuncts(a::Vector{Atom}) = isempty(a) ? ⊤ : LeftmostConjunctiveForm{Literal}(Literal.(a))

# ---------------------------------------------------------------------------- #
#                                 print utils                                  #
# ---------------------------------------------------------------------------- #
_featurename(f::SoleData.VariableValue) = isnothing(f.i_name) ? "V$(f.i_variable)" : "[$(f.i_name)]"

# ---------------------------------------------------------------------------- #
#                             disjuncts encoding                               #
# ---------------------------------------------------------------------------- #
"""
    _encode_disjunct(
        disjunct::SoleLogics.LeftmostConjunctiveForm{SoleLogics.Literal},
        features::Vector{<:SoleData.VariableValue},
        conditions::Vector{<:SoleData.ScalarCondition},
        includes::Vector{BitMatrix},
        excludes::Vector{BitMatrix},
        feat_condindxss::Vector{Vector{Int64}}
    ) -> Vector{String}

    Encode a logical disjunct into a Programmable Logic Array (PLA) row representation.

    This function converts a logical disjunct (a conjunction of literals) into a PLA row format,
    where each position corresponds to a condition and can be set to "1" (true), "0" (false), 
    or "-" (don't care).

    # Arguments
    - `disjunct::SoleLogics.LeftmostConjunctiveForm{SoleLogics.Literal}`: The logical disjunct to encode, containing literals
    - `features::Vector{<:SoleData.VariableValue}`: Vector of features used in the logical formula
    - `conditions::Vector{<:SoleData.ScalarCondition}`: Vector of all possible conditions 
    - `includes::Vector{BitMatrix}`: Matrix-like structure defining inclusion relationships between conditions
    - `excludes::Vector{BitMatrix}`: Matrix-like structure defining exclusion relationships between conditions
    - `feat_condindxss::Vector{Vector{Int64}}`: Mapping from features to their corresponding condition indices

    # Returns
    - `Vector{String}`: PLA row representation where each element is "1", "0", or "-"

    # Details
    The function processes each literal in the disjunct:
    - For positive literals, sets "1" for included conditions and "0" for excluded ones
    - For negative literals, inverts the logic (sets "0" for included, "1" for excluded)
    - Handles dual conditions when they exist by applying inverted logic
    - Preserves more restrictive values (NEG over POS) when conflicts occur

    # Notes
    - The function assumes that either the main condition or its dual exists in the conditions vector
    - The resulting PLA row uses "-" for don't-care positions that are not constrained by any literal
"""
function _encode_disjunct(
    disjunct        :: SoleLogics.LeftmostConjunctiveForm{SoleLogics.Literal},
    features        :: Vector{<:SoleData.VariableValue},
    conditions      :: Vector{<:SoleData.ScalarCondition},
    includes        :: Vector{BitMatrix},
    excludes        :: Vector{BitMatrix},
    feat_condindxss :: Vector{Vector{Int64}}
)
    pla_row = fill("-", length(conditions))
    
    # for each atom in the disjunct, add zeros or ones to relevants
    for lit in SoleLogics.grandchildren(disjunct)
        ispos = SoleLogics.ispos(lit)
        cond  = SoleLogics.value(atom(lit))

        i_feat         = findfirst((f)->f==SoleData.feature(cond), features)
        feat_condindxs = feat_condindxss[i_feat]

        feat_icond     = findfirst(c->c==cond, conditions[feat_condindxs])
        feat_idualcond = SoleData.hasdual(cond) ? findfirst(c->c==SoleData.dual(cond), conditions[feat_condindxs]) : nothing

        @assert !(isnothing(feat_icond) && isnothing(feat_idualcond))

        POS, NEG = ispos ? ("1", "0") : ("0", "1")
        
        for (ic, c) in enumerate(feat_condindxs)
            # set pos for included conditions
            if !isnothing(feat_icond)
                includes[i_feat][feat_icond, ic] && pla_row[c] == "-" &&
                    (pla_row[c] = POS)
                excludes[i_feat][feat_icond, ic] &&
                    (pla_row[c] = (pla_row[c] == "-" ? NEG : (pla_row[c] == POS && NEG == "0" ? NEG : pla_row[c])))
            end
            # handle dual condition if exists
            if !isnothing(feat_idualcond)
                includes[i_feat][feat_idualcond, ic] &&
                    (pla_row[c] = (pla_row[c] == "-" ? NEG : (pla_row[c] == POS && NEG == "0" ? NEG : pla_row[c])))
                excludes[i_feat][feat_idualcond, ic] && pla_row[c] == "-" &&
                    (pla_row[c] = POS)
            end
        end
    end

    return pla_row
end

# ---------------------------------------------------------------------------- #
#                               read conditions                                #
# ---------------------------------------------------------------------------- #
"""
    _read_conditions(
        line::AbstractString,
        conditionstype::Type,
        fnames::Vector{<:SoleModels.Label}
    ) -> Vector{SoleLogics.Atom}

Parse a PLA input label line (`.ilb`) and extract scalar conditions as atoms.

This function processes a single line from a Programmable Logic Array (PLA) file that 
defines input variable labels and their associated conditions. It parses each condition 
specification and creates corresponding `SoleLogics.Atom` objects.

# Arguments
- `line::AbstractString`: The `.ilb` command line from a PLA file, containing space-separated condition specifications
- `conditionstype::Type`: The type of condition to create (e.g., `SoleData.ScalarCondition`, `RangeScalarCondition`)
- `fnames::Vector{<:SoleModels.Label}`: Vector of feature names used to resolve variable indices for `SoleData.VariableValue` structs

# Returns
- `Vector{SoleLogics.Atom}`: Vector of atoms, each containing a scalar condition parsed from the input line

# Format
Each condition in the line follows the pattern: `[feature_name]operator threshold`
- Feature name is enclosed in square brackets `[]`
- Operator can be either `<` or `≥`
- Threshold is typically floating-point number

# Details
The function:
1. Splits the line on spaces and skips the first element (`.ilb` command)
2. For each part, extracts:
   - Feature name (between `[` and `]`)
   - Operator (`<` or `≥`)
   - Threshold value (remaining string parsed as Float64)
3. Creates a `SoleData.VariableValue` from the feature name and its index
4. Constructs a condition object and wraps it in an `SoleLogics.Atom`

# Notes
- The feature name must exist in `fnames` to determine the variable index
"""
function _read_conditions(
    line           :: AbstractString,
    conditionstype :: Type,
    fnames         :: Vector{<:SoleModels.Label}
)
    parts = split(line, ' ')[2:end]  # skip '.ilb' command
    
    return map(parts) do part
        # find the closing bracket position
        close_bracket_idx = findfirst(']', part)
        
        # extract feature, between '[]'
        varname   = Symbol(part[2:close_bracket_idx-1])
        i_var     = findfirst(==(varname), fnames)
        value     = SoleData.VariableValue(i_var, varname)
        
        # extract operator, character after ']'
        op_start  = nextind(part, close_bracket_idx)
        operator  = part[op_start] == '<' ? (<) : (≥)
        
        # extract threshold, remaining string
        threshold_start = nextind(part, op_start)
        threshold = parse(Float64, @view part[threshold_start:end])

        condition = conditionstype(value, operator, threshold)

        return SoleLogics.Atom{typeof(condition)}(condition)
    end
end

# ---------------------------------------------------------------------------- #
#                               univariate utils                               #
# ---------------------------------------------------------------------------- #
function _header(conditions::Vector{<:SoleData.ScalarCondition}, feat_condnames::Vector{Vector{String}})
    num_outputs = 1
    num_vars = length(conditions)
    ilb_str = join(vcat(feat_condnames...), " ")
    return [".i $(num_vars)\n.o $(num_outputs)\n.ilb $(ilb_str)\n.ob formula_output"]
end

_onset_rows(row::Vector{String}) = "$(join(row, "")) 1" # Append "1" for the ON-set output

# ---------------------------------------------------------------------------- #
#                              multivariate utils                              #
# ---------------------------------------------------------------------------- #
function _header(feat_nconds::Vector{Int64}, feat_condnames::Vector{Vector{String}})
    num_binary_vars = sum(feat_nconds .== 1)
    num_nonbinary_vars = sum(feat_nconds .> 1) + 1
    num_vars = num_binary_vars + num_nonbinary_vars

    pla_header = []

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

    return pla_header
end

function _onset_rows(feat_nconds::Vector{Int64}, row::Vector{String})
    num_binary_vars = sum(feat_nconds .== 1)

    # generate on-set rows for each disjunct    
    end_idxs = cumsum(feat_nconds)
    feat_varidxs = [(startidx:endidx) for (startidx,endidx) in zip([1, (end_idxs.+1)...], end_idxs)]

    # binary variables first
    binary_variable_idxs = findall(feat_nvar->feat_nvar == 1, feat_nconds)
    nonbinary_variable_idxs = findall(feat_nvar->feat_nvar > 1, feat_nconds)
    row = vcat(
        [row[feat_varidxs[i_var]] for i_var in binary_variable_idxs]...,
        (num_binary_vars > 0 ? ["|"] : [])...,
        [[row[feat_varidxs[i_var]]..., "|"] for i_var in nonbinary_variable_idxs]...
    )
    return "$(join(row, ""))1"
end

# ---------------------------------------------------------------------------- #
#                                formula to pla                                #
# ---------------------------------------------------------------------------- #
formula_to_pla(formula::SoleLogics.Formula; kwargs...) =
    formula_to_pla(SoleLogics.dnf(formula, SoleLogics.Atom; profile=:nnf, allow_atom_flipping=true); kwargs...)

function formula_to_pla(
    dnfformula              :: SoleLogics.DNF;
    scalar_range_conditions :: Bool=false,
    kwargs...
)
    scalar_simplification_kwargs = (;
        force_scalar_range = scalar_range_conditions, 
        allow_scalar_range = scalar_range_conditions,
    )

    dnfformula = scalar_simplification(dnfformula; scalar_simplification_kwargs...)
    dnfformula = SoleLogics.dnf(dnfformula; profile=:nnf, allow_atom_flipping=true, kwargs...)

    formula_to_pla(collect.(atoms(dnfformula).it); scalar_range_conditions, kwargs...)
end

function formula_to_pla(
    atoms :: Vector{Vector{SoleLogics.Atom}};
    encoding                :: Symbol=:univariate,
    scalar_range_conditions :: Bool=false
)
    @assert encoding in [:univariate, :multivariate]

    # extract domains
    conditions = unique(map(SoleLogics.value, reduce(vcat, atoms)))
    features   = unique(SoleData.feature.(conditions))

    sort!(conditions, by=SoleData._scalarcondition_sortby)
    sort!(features, by=syntaxstring)

    conditions = SoleData.removeduals(conditions)

    # TODO check and test it
    if scalar_range_conditions
        original_conditions = conditions
        conditions = SoleData.scalartiling(conditions, features)
        @assert length(setdiff(original_conditions, conditions)) == 0 "$(SoleLogics.displaysyntaxvector(setdiff(original_conditions, conditions)))"
    end

    # for each feature, derive the conditions, and their names
    feat_condindxss = Vector{Vector{Int64}}(undef, length(features))
    feat_condnames  = Vector{Vector{String}}(undef, length(features))

    @inbounds for (i, feat) in enumerate(features)
        feat_condindxs = findall(c->SoleData.feature(c) == feat, conditions)
        conds          = filter(c->SoleData.feature(c)  == feat, conditions)
        condname = [string(_featurename(SoleData.feature(c)), SoleData.test_operator(c), SoleData.threshold(c)) for c in conds]
        
        feat_condindxss[i] = feat_condindxs
        feat_condnames[i]  = condname
    end

    feat_nconds = length.(feat_condindxss)

    # derive inclusions and exclusions between conditions
    includes, excludes = Vector{BitMatrix}(undef, length(features)), Vector{BitMatrix}(undef, length(features))
    @inbounds for (i, feat_condindxs) in enumerate(feat_condindxss)
        includes[i] = BitMatrix([SoleData.includes(conditions[cond_i], conditions[cond_j]) for cond_i in feat_condindxs, cond_j in feat_condindxs])
        excludes[i] = BitMatrix([SoleData.excludes(conditions[cond_j], conditions[cond_i]) for cond_i in feat_condindxs, cond_j in feat_condindxs])
    end

    # generate pla _header
    pla_header = encoding == :multivariate ? _header(feat_nconds, feat_condnames) : _header(conditions, feat_condnames)

    conjuncts      = _get_conjuncts(atoms)
    pla_onset_rows = Vector{String}(undef, length(conjuncts))

    Threads.@threads for i in eachindex(conjuncts)
        row = _encode_disjunct(conjuncts[i], features, conditions, includes, excludes, feat_condindxss)
        pla_onset_rows[i] = encoding == :multivariate ? _onset_rows(feat_nconds, row) : _onset_rows(row)
    end

    # Combine PLA components
    pla_content = join([join(pla_header, "\n"), ".p $(length(pla_onset_rows))", join(pla_onset_rows, "\n"), ".e"], "\n")

    return pla_content
end

# ---------------------------------------------------------------------------- #
#                                pla to formula                                #
# ---------------------------------------------------------------------------- #
function pla_to_formula(
    pla            :: String,
    fnames         :: Vector{<:SoleModels.Label};
    conditionstype :: Type=SoleData.SoleData.ScalarCondition,
)
    lines             = split(pla, '\n')
    parsed_conditions = SoleLogics.Atom[]
    binaries          = String[]

    for line in lines
        startswith(line, ".ilb") && append!(parsed_conditions, _read_conditions(line, conditionstype, fnames))
        startswith(line, ['0', '1', '-', '|']) && append!(binaries, [line[1:end-2]])
    end

    disjuncts = [
        SoleLogics.LeftmostConjunctiveForm([
            SoleLogics.Literal(LiteralBool[value], parsed_conditions[idx])
            for (idx, value) in enumerate(binary)
            if value ∈ ['1', '0']
        ])
        for binary in binaries
    ]

    return !isempty(disjuncts) ?
        collect(scalar_simplification(d; force_scalar_range=false, allow_scalar_range=false) for d in disjuncts) :
        ⊤
end

# ---------------------------------------------------------------------------- #
#                         scalar simplification utils                          #
# ---------------------------------------------------------------------------- #
mostspecific(cs::AbstractVector{<:Real}, ::typeof(<=)) = findmin(cs)[1]
mostspecific(cs::AbstractVector{<:Real}, ::typeof(>=)) = findmax(cs)[1]

my_isless(::T, ::T) where T           = false
my_isless(::typeof(<),  ::typeof(<=)) = true
my_isless(::typeof(<=), ::typeof(<))  = false
my_isless(::typeof(>),  ::typeof(>=)) = false
my_isless(::typeof(>=), ::typeof(>))  = true

my_isless(::typeof(<),  ::typeof(>))  = false
my_isless(::typeof(>),  ::typeof(<))  = false
my_isless(::typeof(>=), ::typeof(>=)) = false
my_isless(::typeof(<=), ::typeof(<=)) = false

# ---------------------------------------------------------------------------- #
#                            scalar simplification                             #
# ---------------------------------------------------------------------------- #
scalar_simplification(φ::DNF, args...; kwargs...) =
    map(d->scalar_simplification(d, args...; kwargs...), SoleLogics.disjuncts(φ)) |> LeftmostDisjunctiveForm

scalar_simplification(φ::CNF, args...; kwargs...) =
    map(d->scalar_simplification(d, args...; kwargs...), SoleLogics.conjuncts(φ)) |> LeftmostConjunctiveForm

function scalar_simplification(
    φ :: Union{LeftmostConjunctiveForm,LeftmostDisjunctiveForm};
    kwargs...
)
    φ = LeftmostLinearForm(SoleLogics.connective(φ), map(ch->begin
        if ch isa Atom
            ch
        elseif ch isa Literal
            if SoleLogics.ispos(ch)
                atom(ch)
            elseif SoleLogics.hasdual(atom(ch))
                SoleLogics.dual(atom(ch))
            else
                ch
            end
        else
            ch
        end
    end, SoleLogics.grandchildren(φ)))

    if !all(c->c isa Atom{<:Union{SoleData.ScalarCondition,SoleData.RangeScalarCondition}}, SoleLogics.grandchildren(φ))
        return φ
    end

    scalar_simplification(SoleLogics.atoms(φ), SoleLogics.connective(φ); kwargs...)
end

function scalar_simplification(
    atomslist          :: Vector{SoleLogics.Atom},
    conn               :: SoleLogics.NamedConnective;
    force_scalar_range :: Bool=false,
    allow_scalar_range :: Bool=true,
)
    scalar_conditions = SoleLogics.value.(atomslist)
    feats = SoleData.feature.(scalar_conditions)

    feature_groups = [(f, map(x->x==f, feats)) for f in unique(feats)]

    conn_polarity = (conn == SoleLogics.CONJUNCTION)

    ch = collect(Iterators.flatten([begin
            conds = scalar_conditions[bitmask]

            conds = [if cond isa ScalarCondition && (SoleData.test_operator(cond) == (==))
                        SoleData.RangeScalarCondition(
                            SoleData.feature(cond),
                            SoleData.minval(cond),
                            SoleData.maxval(cond),
                            SoleData.minincluded(cond),
                            SoleData.maxincluded(cond),
                        )
                    else
                        cond
                    end for cond in conds]

            conds = Iterators.flatten([
                if cond isa ScalarCondition
                    [cond]
                elseif cond isa SoleData.RangeScalarCondition
                    if conn_polarity
                        conds = SoleData._rangescalarcond_to_scalarconds_in_conjunction(cond)
                    else
                        error("Cannot convert SoleData.RangeScalarCondition to ScalarCondition: $(cond).")
                    end
                else
                    error("Unexpected condition: $(cond)")
                end for cond in conds])

            min_domain = nothing
            max_domain = nothing
            T = eltype(SoleData.threshold.(conds))
            for cond in conds
                @assert !SoleData.isordered(SoleData.test_operator) "Unexpected test operator: $(SoleData.test_operator)."
                this_domain = (SoleData.test_operator(cond), SoleData.threshold(cond))
                p = SoleData.polarity(SoleData.test_operator(cond))
                if isnothing(p)
                    throw(ArgumentError("Cannot simplify scalar formula with test operator = $(SoleData.test_operator(cond))"))
                elseif !p
                    if isnothing(max_domain) ||
                        (
                            (isless(this_domain[2], max_domain[2]) ||
                                (==(this_domain[2], max_domain[2]) && my_isless(this_domain[1], max_domain[1]))
                                ) == conn_polarity)
                        max_domain = this_domain
                    end
                else
                    if isnothing(min_domain) ||
                        (
                            (!(isless(this_domain[2], min_domain[2])) ||
                                (==(this_domain[2], min_domain[2]) && my_isless(this_domain[1], min_domain[1]))
                                ) == conn_polarity)
                        min_domain = this_domain
                    end
                end
            end
            out = []

            if !isnothing(max_domain) && !isnothing(min_domain) && (max_domain[2] < min_domain[2]) # TODO make it more finegrained so that it captures cases with < and >=
                nothing
            elseif isnothing(min_domain) && isnothing(max_domain)
                nothing
            else
                if force_scalar_range
                    min_domain = isnothing(min_domain) ? (>=, nothing #= typemin(T) =#) : min_domain
                    max_domain = isnothing(max_domain) ? (<=, nothing #= typemax(T) =#) : max_domain
                end
                if allow_scalar_range && (!isnothing(min_domain) && !isnothing(max_domain))
                    minincluded = (!SoleData.isstrict(min_domain[1])) || isnothing(min_domain[2])
                    maxincluded = (!SoleData.isstrict(max_domain[1])) || isnothing(max_domain[2])
                    push!(out, Atom(SoleData.RangeScalarCondition(feat, min_domain[2], max_domain[2], minincluded, maxincluded)))
                else
                    if !isnothing(min_domain)
                        push!(out, Atom(ScalarCondition(feat, min_domain[1], min_domain[2])))
                    end
                    if !isnothing(max_domain)
                        push!(out, Atom(ScalarCondition(feat, max_domain[1], max_domain[2])))
                    end
                end
            end

            out
        end for (feat, bitmask) in feature_groups]))

    return (length(ch) == 0 ? (⊤) : (length(ch) == 1 ? first(ch) : LeftmostLinearForm(conn, ch)))
end

formula0 = @scalarformula ((V1 > 10) ∧ (V2 < 0) ∧ (V2 < 0) ∧ (V2 <= 0)) ∨ ((V1 <= 0) ∧ ((V1 <= 3)) ∧ (V2 == 2))

@show SoleData.PLA._formula_to_pla(formula0)[1]
@show formula_to_pla(formula0)

# ".i 5\n.o 1\n.ilb V1≤0 V1>10 V2<0 V2≤2 V2≥2\n.ob formula_output\n\n.p 2\n10011 1\n011-0 1\n.e"
# ".i 5\n.o 1\n.ilb V1<=0 V1>10 V2<0 V2<=2 V2>=2\n.ob formula_output\n.p 1\n00010 1\n.e"
