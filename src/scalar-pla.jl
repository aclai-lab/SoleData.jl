module PLA

using SoleLogics
const SL = SoleLogics

using SoleData
const SD = SoleData

# ---------------------------------------------------------------------------- #
#                                   types                                      #
# ---------------------------------------------------------------------------- #
const OPERATORS = "<=|>=|==|!=|<|≤|>|≥|≠|∈|∉"
const OP_REGEX = Regex("^\\[?(.+?)\\]?(" * OPERATORS * ")(.+)\$")
const OPERATOR_MAP = Dict(
    "<" => (<),
    "<=" => (<=),
    "≤" => (≤),
    ">" => (>),
    ">=" => (>=),
    "≥" => (≥),
    "==" => (==),
    "!=" => (!=),
    "≠" => (!=),
    "∈" => (∈),
    "∉" => (∉),
)

const LiteralBool = Dict('1' => true, '0' => false)

# ---------------------------------------------------------------------------- #
#                                get conjuncts                                 #
# ---------------------------------------------------------------------------- #
@inline _get_conjuncts(a::Vector{Vector{Atom}}) = _get_conjuncts.(a)
@inline _get_conjuncts(a::Vector{Atom}) =
    isempty(a) ? ⊤ : LeftmostConjunctiveForm{Literal}(Literal.(a))

# ---------------------------------------------------------------------------- #
#                                 print utils                                  #
# ---------------------------------------------------------------------------- #
function _featurename(f::SD.VariableValue)
    return if isnothing(f.i_name)
        f.i_variable isa Union{Symbol,AbstractString} ?
        "$(f.i_variable)" : "V$(f.i_variable)"
    else
        "$(f.i_name)"
    end
end

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
        feat_condindxss::Vector{Vector{Int}}
    ) -> Vector{String}

Encode a logical disjunct into a Programmable Logic Array (PLA) row
representation. Each position corresponds to a condition and can be set to
"1" (true), "0" (false), or "-" (don't care). See original docstring for
full details -- unchanged by this patch.
"""
function _encode_disjunct(
    disjunct::SL.LeftmostConjunctiveForm{SL.Literal},
    features::Vector{<:SD.VariableValue},
    conditions::Vector{<:SD.AbstractScalarCondition},
    includes::Vector{BitMatrix},
    excludes::Vector{BitMatrix},
    feat_condindxss::Vector{Vector{Int}},
)
    pla_row = fill("-", length(conditions))

    # for each atom in the disjunct, add zeros or ones to relevants
    for lit in SL.grandchildren(disjunct)
        ispos = SL.ispos(lit)
        cond = SL.value(atom(lit))

        i_feat = findfirst((f)->f==SD.feature(cond), features)
        feat_condindxs = feat_condindxss[i_feat]

        feat_icond = findfirst(c->c==cond, conditions[feat_condindxs])
        feat_idualcond = if SD.hasdual(cond)
            findfirst(c->c==SD.dual(cond), conditions[feat_condindxs])
        else
            nothing
        end

        @assert !(isnothing(feat_icond) && isnothing(feat_idualcond))

        POS, NEG = ispos ? ("1", "0") : ("0", "1")

        for (ic, c) in enumerate(feat_condindxs)
            # set pos for included conditions
            if !isnothing(feat_icond)
                includes[i_feat][feat_icond, ic] && pla_row[c] == "-" && (pla_row[c] = POS)
                excludes[i_feat][feat_icond, ic] && (
                    pla_row[c] = (
                        if pla_row[c] == "-"
                            NEG
                        else
                            (pla_row[c] == POS && NEG == "0" ? NEG : pla_row[c])
                        end
                    )
                )
            end
            # handle dual condition if exists
            if !isnothing(feat_idualcond)
                includes[i_feat][feat_idualcond, ic] && (
                    pla_row[c] = (
                        if pla_row[c] == "-"
                            NEG
                        else
                            (pla_row[c] == POS && NEG == "0" ? NEG : pla_row[c])
                        end
                    )
                )
                excludes[i_feat][feat_idualcond, ic] &&
                    pla_row[c] == "-" &&
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
    _read_conditions(line, conditionstype, fnames; float_type=Float64)

Parse a PLA `.ilb` line into a vector of `SoleLogics.Atom`. Unchanged by
this patch.
"""
function _read_conditions(
    line::AbstractString,
    conditionstype::Type,
    fnames::Vector{<:VariableValue};
    float_type::Type=Float64
)
    parts = split(line, ' ')[2:end]

    return map(parts) do part
        m = match(OP_REGEX, part)
        m === nothing && throw(ArgumentError("Invalid condition token: $(part)"))

        varname = Symbol(m.captures[1])

        i_fname = findfirst(f -> Symbol(featurename(f)) == varname, fnames)
        i_fname === nothing && throw(ArgumentError("Unknown feature name: $(varname)"))
        i_var = fnames[i_fname].i_variable

        value = SD.VariableValue(i_var, varname)

        operator = OPERATOR_MAP[m.captures[2]]
        threshold = parse(float_type, m.captures[3])

        condition = conditionstype(value, operator, threshold)

        return SL.Atom{typeof(condition)}(condition)
    end
end

# ---------------------------------------------------------------------------- #
#                     onset / offset row helpers (PATCHED)                     #
# ---------------------------------------------------------------------------- #
"""
    _onset_rows(row::Vector{String}) -> String

Univariate ON-set row: appends output `"1"`. Unchanged.
"""
_onset_rows(row::Vector{String}) = "$(join(row, "")) 1"

"""
    _offset_rows(row::Vector{String}) -> String

NEW. Univariate OFF-set row: appends output `"0"`. Symmetric to
`_onset_rows`, used ONLY when the caller of `formula_to_pla` passes an
explicit `offset`. Without this, Espresso has no way to distinguish
"confirmed OFF" from "not yet seen" (which must stay don't-care).
"""
_offset_rows(row::Vector{String}) = "$(join(row, "")) 0"

function _onset_rows(feat_nconds::Vector{Int}, row::Vector{String})
    num_binary_vars = sum(feat_nconds .== 1)
    end_idxs = cumsum(feat_nconds)
    feat_varidxs = [
        (startidx:endidx) for (startidx, endidx) in zip([1, (end_idxs .+ 1)...], end_idxs)
    ]
    binary_variable_idxs = findall(feat_nvar->feat_nvar == 1, feat_nconds)
    nonbinary_variable_idxs = findall(feat_nvar->feat_nvar > 1, feat_nconds)
    row = vcat(
        [row[feat_varidxs[i_var]] for i_var in binary_variable_idxs]...,
        (num_binary_vars > 0 ? ["|"] : [])...,
        [[row[feat_varidxs[i_var]]..., "|"] for i_var in nonbinary_variable_idxs]...,
    )
    return "$(join(row, ""))1"
end

"""
    _offset_rows(feat_nconds::Vector{Int}, row::Vector{String}) -> String

NEW. Multivariate counterpart of the univariate `_offset_rows` above --
same layout logic as `_onset_rows(feat_nconds, row)` but output `"0"`.
"""
function _offset_rows(feat_nconds::Vector{Int}, row::Vector{String})
    num_binary_vars = sum(feat_nconds .== 1)
    end_idxs = cumsum(feat_nconds)
    feat_varidxs = [
        (startidx:endidx) for (startidx, endidx) in zip([1, (end_idxs .+ 1)...], end_idxs)
    ]
    binary_variable_idxs = findall(feat_nvar->feat_nvar == 1, feat_nconds)
    nonbinary_variable_idxs = findall(feat_nvar->feat_nvar > 1, feat_nconds)
    row = vcat(
        [row[feat_varidxs[i_var]] for i_var in binary_variable_idxs]...,
        (num_binary_vars > 0 ? ["|"] : [])...,
        [[row[feat_varidxs[i_var]]..., "|"] for i_var in nonbinary_variable_idxs]...,
    )
    return "$(join(row, ""))0"
end

# ---------------------------------------------------------------------------- #
#                    header: emette .type fr quando serve (PATCHED)            #
# ---------------------------------------------------------------------------- #
"""
    _header(conditions, feat_condnames; has_offset=false)

Univariate header. NEW keyword `has_offset`: if `true`, inserts the line
`.type fr` right after `.ob`, explicitly telling Espresso "I'm giving you
both the ON-set (output 1) and the OFF-set (output 0); anything you don't
see among the rows is don't-care". If `false` (default), behavior is
IDENTICAL to before -- no `.type` line -- so `lumen()` classic and every
other existing caller is unaffected.
"""
function _header(
    conditions::Vector{<:SD.AbstractScalarCondition},
    feat_condnames::Vector{Vector{String}};
    has_offset::Bool=false,
)
    num_outputs = 1
    num_vars = length(conditions)
    ilb_str = join(vcat(feat_condnames...), " ")
    hdr = [".i $(num_vars)\n.o $(num_outputs)\n.ilb $(ilb_str)\n.ob formula_output"]
    has_offset && push!(hdr, ".type fr")
    return hdr
end

"""
    _header(feat_nconds, feat_condnames; has_offset=false)

Multivariate header, same `.type fr` treatment as the univariate variant
above.
"""
function _header(
    feat_nconds::Vector{Int},
    feat_condnames::Vector{Vector{String}};
    has_offset::Bool=false,
)
    num_binary_vars = sum(feat_nconds .== 1)
    num_nonbinary_vars = sum(feat_nconds .> 1) + 1
    num_vars = num_binary_vars + num_nonbinary_vars

    pla_header = []

    push!(
        pla_header,
        ".mv $(num_vars) $(num_binary_vars) $(join(feat_nconds[feat_nconds .> 1], " ")) 1",
    )
    if num_binary_vars > 0
        ilb_str = join(vcat(feat_condnames[feat_nconds .== 1]...), " ")
        push!(pla_header, ".ilb " * ilb_str)
    end
    for i_var in 1:length(feat_nconds[feat_nconds .> 1])
        if feat_nconds[feat_nconds .> 1][i_var] > 1
            this_ilb_str = join(feat_condnames[feat_nconds .> 1][i_var], " ")
            push!(pla_header, ".label var=$(num_binary_vars+i_var-1) $(this_ilb_str)")
        end
    end
    has_offset && push!(pla_header, ".type fr")

    return pla_header
end

# ---------------------------------------------------------------------------- #
#                                formula to pla                                #
# ---------------------------------------------------------------------------- #
"""
    formula_to_pla(
        formula::SoleLogics.Formula;
        allow_scalar_range_conditions::Bool=false, kwargs...
    ) -> (String, Vector{VariableValue})
    formula_to_pla(
        dnfformula::SoleLogics.DNF;
        allow_scalar_range_conditions::Bool=false, kwargs...
    ) -> (String, Vector{VariableValue})
    formula_to_pla(
        atoms::Vector{Vector{SoleLogics.Atom}};
        encoding::Symbol=:univariate,
        allow_scalar_range_conditions::Bool=false,
        offset::Union{Nothing,Vector{Vector{SoleLogics.Atom}}}=nothing,
        kwargs...
    ) -> (String, Vector{VariableValue})

Convert a logical formula into Programmable Logic Array (PLA) format.
See original module docstring for the full step-by-step description --
unchanged except for the NEW `offset` keyword documented below.

# `offset` (NEW, only on the `atoms::Vector{Vector{Atom}}` method)
If `nothing` (default): behavior IDENTICAL to before -- implicit `.type f`
PLA, Espresso computes the absolute complement. No change for any existing
caller that doesn't pass `offset`.

If given: `offset` is, like `atoms`, a `Vector{Vector{Atom}}` -- one cube
per row -- but represents cubes CONFIRMED OFF (not "unknown"). It is
encoded with `_encode_disjunct` using EXACTLY the same condition space
(`conditions`, `includes`, `excludes`, `feat_condindxss`) as the ON-set, so
PLA columns stay aligned between the two halves, then its rows are emitted
with output `"0"` instead of `"1"`. The `.type fr` header line is also
emitted, which is what tells Espresso "everything else is don't-care, not
complement".

Conditions that appear ONLY in `offset` (not in `atoms`) are still folded
into the global condition space (same mechanism already used for
`universe_conditions`), otherwise an off-set cube mentioning a
feature/threshold never seen in the on-set couldn't be encoded correctly.
"""
function formula_to_pla(
    dnfformula::SL.DNF;
    allow_scalar_range_conditions::Bool=false,
    kwargs...
)
    dnfformula = SD.scalar_simplification(dnfformula; allow_scalar_range_conditions)
    dnfformula = SL.dnf(dnfformula; profile=:nnf, allow_atom_flipping=true, kwargs...)

    atoms_per_disjunct = Vector{Vector{SL.Atom}}([
        collect(SL.atoms(d)) for d in SL.disjuncts(dnfformula)
    ])

    formula_to_pla(atoms_per_disjunct; allow_scalar_range_conditions, kwargs...)
end

function formula_to_pla(
    atoms::Vector{Vector{SL.Atom}};
    encoding::Symbol=:univariate,
    allow_scalar_range_conditions::Bool=false,
    removewhitespaces::Bool=true,
    pretty_op::Bool=false,
    universe_conditions::Union{Nothing,Vector{<:SD.AbstractScalarCondition}}=nothing,
    offset::Union{Nothing,Vector{Vector{SL.Atom}}}=nothing,
)
    @assert encoding in [:univariate, :multivariate]

    has_offset = !isnothing(offset) && !isempty(offset)

    # extract domains: ON-set + (if present) OFF-set, so conditions
    # mentioned ONLY in the offset still enter the shared condition space.
    local_conditions = map(SL.value, reduce(vcat, atoms))
    if has_offset
        offset_conditions = map(SL.value, reduce(vcat, offset))
        local_conditions = vcat(local_conditions, offset_conditions)
    end

    if isnothing(universe_conditions)
        conditions = unique(local_conditions)
    else
        conditions = unique(vcat(collect(universe_conditions), local_conditions))
    end

    fnames = unique(SD.feature.(conditions))
    nfnames = length(fnames)

    sort!(conditions; by=SD._scalarcondition_sortby)
    sort!(fnames; by=syntaxstring)

    if allow_scalar_range_conditions
        original_conditions = conditions
        conditions = SD.scalartiling(conditions, fnames)
        @assert length(setdiff(original_conditions, conditions)) == 0
    end

    conditions = SD.removeduals(conditions)

    feat_condindxss = Vector{Vector{Int}}(undef, nfnames)
    feat_condnames = Vector{Vector{String}}(undef, nfnames)

    @inbounds for (i, feat) in enumerate(fnames)
        feat_condindxs = findall(c->SD.feature(c) == feat, conditions)
        conds = filter(c->SD.feature(c) == feat, conditions)
        condname = SoleLogics.syntaxstring.(conds; removewhitespaces, pretty_op)

        feat_condindxss[i] = feat_condindxs
        feat_condnames[i] = condname
    end

    feat_nconds = length.(feat_condindxss)

    includes, excludes = Vector{BitMatrix}(undef, nfnames),
    Vector{BitMatrix}(undef, nfnames)
    @inbounds for (i, feat_condindxs) in enumerate(feat_condindxss)
        includes[i] = BitMatrix([
            SD.includes(conditions[cond_i], conditions[cond_j]) for
            cond_i in feat_condindxs, cond_j in feat_condindxs
        ])
        excludes[i] = BitMatrix([
            SD.excludes(conditions[cond_j], conditions[cond_i]) for
            cond_i in feat_condindxs, cond_j in feat_condindxs
        ])
    end

    pla_header = if encoding == :multivariate
        _header(feat_nconds, feat_condnames; has_offset)
    else
        _header(conditions, feat_condnames; has_offset)
    end

    # --- ON-set rows -----------------------------------------------------
    conjuncts = _get_conjuncts(atoms)
    pla_onset_rows = Vector{String}(undef, length(conjuncts))
    Threads.@threads for i in eachindex(conjuncts)
        row = _encode_disjunct(
            conjuncts[i], fnames, conditions, includes, excludes, feat_condindxss
        )
        pla_onset_rows[i] =
            encoding == :multivariate ? _onset_rows(feat_nconds, row) : _onset_rows(row)
    end

    # --- OFF-set rows (NEW, only if `offset` given) -----------------------
    # Same conditions/includes/excludes/feat_condindxss as the ON-set: this
    # reuse is exactly what guarantees column alignment between the two
    # halves of the PLA.
    pla_offset_rows = String[]
    if has_offset
        offset_conjuncts = _get_conjuncts(offset)
        pla_offset_rows = Vector{String}(undef, length(offset_conjuncts))
        Threads.@threads for i in eachindex(offset_conjuncts)
            row = _encode_disjunct(
                offset_conjuncts[i], fnames, conditions, includes, excludes, feat_condindxss
            )
            pla_offset_rows[i] =
                encoding == :multivariate ? _offset_rows(feat_nconds, row) : _offset_rows(row)
        end
    end

    all_rows = vcat(pla_onset_rows, pla_offset_rows)

    pla_content = join(
        [
            join(pla_header, "\n"),
            ".p $(length(all_rows))",
            join(all_rows, "\n"),
            ".e",
        ],
        "\n",
    )

    return pla_content, fnames
end

# ---------------------------------------------------------------------------- #
#                                pla to formula                                #
# ---------------------------------------------------------------------------- #
"""
    pla_to_formula(
        pla::String,
        fnames::Vector{<:VariableValue};
        conditionstype::Type=SoleData.ScalarCondition,
        conjunct::Bool=false,
        float_type::Type=Float64
    ) -> Union{SoleLogics.Formula, Vector{SyntaxStructure}}

Convert a PLA string back into a formula. Unchanged by this patch: it
already only reads rows starting with `['0','1','-','|']` and, of those,
only the ones ending "1" ever become atoms in the ON-set fed back to the
caller (`_onset_rows`/`_offset_rows` distinction is irrelevant here, since
Espresso's OUTPUT PLA -- what this function parses -- is always the
minimized single ON-set again, regardless of whether the INPUT PLA was
`.type f` or `.type fr`).
"""
function pla_to_formula(
    pla::String,
    fnames::Vector{<:VariableValue};
    conditionstype::Type=SD.ScalarCondition,
    conjunct::Bool=false,
    float_type::Type=Float64
)
    lines = split(pla, '\n')
    parsed_conditions = SoleLogics.Atom[]
    binaries = String[]

    for line in lines
        startswith(line, ".ilb") &&
            append!(parsed_conditions, _read_conditions(line, conditionstype, fnames; float_type))
        startswith(line, ['0', '1', '-', '|']) && append!(binaries, [line[1:(end-2)]])
    end

    isempty(binaries) && return ⊤

    disjuncts = Vector{SyntaxStructure}(undef, length(binaries))

    Threads.@threads for i in eachindex(binaries)
        binary = binaries[i]
        disjuncts[i] = SD.scalar_simplification(
            SL.LeftmostConjunctiveForm([
                SL.Literal(LiteralBool[value], parsed_conditions[idx]) for
                (idx, value) in enumerate(binary) if value ∈ ['1', '0']
            ]);
            allow_scalar_range_conditions=false
        )
    end

    return conjunct ? LeftmostDisjunctiveForm(disjuncts) : disjuncts
end

end