module PLA

using SoleData
using SoleLogics

using SoleData: scalar_simplification

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
function _featurename(f::SoleData.VariableValue)
    isnothing(f.i_name) ? "V$(f.i_variable)" : "[$(f.i_name)]"
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
    disjunct::SoleLogics.LeftmostConjunctiveForm{SoleLogics.Literal},
    features::Vector{<:SoleData.VariableValue},
    conditions::Vector{<:SoleData.AbstractScalarCondition},
    includes::Vector{BitMatrix},
    excludes::Vector{BitMatrix},
    feat_condindxss::Vector{Vector{Int64}},
)
    pla_row = fill("-", length(conditions))

    # for each atom in the disjunct, add zeros or ones to relevants
    for lit in SoleLogics.grandchildren(disjunct)
        ispos = SoleLogics.ispos(lit)
        cond = SoleLogics.value(atom(lit))

        i_feat = findfirst((f)->f==SoleData.feature(cond), features)
        feat_condindxs = feat_condindxss[i_feat]

        feat_icond = findfirst(c->c==cond, conditions[feat_condindxs])
        feat_idualcond = if SoleData.hasdual(cond)
            findfirst(c->c==SoleData.dual(cond), conditions[feat_condindxs])
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
    _read_conditions(
        line::AbstractString,
        conditionstype::Type,
        fnames::Vector
    ) -> Vector{SoleLogics.Atom}

Parse a PLA input label line (`.ilb`) and extract scalar conditions as atoms.

This function processes a single line from a Programmable Logic Array (PLA) file that 
defines input variable labels and their associated conditions. It parses each condition 
specification and creates corresponding `SoleLogics.Atom` objects.

# Arguments
- `line::AbstractString`: The `.ilb` command line from a PLA file, containing space-separated condition specifications
- `conditionstype::Type`: The type of condition to create (e.g., `SoleData.ScalarCondition`, `RangeScalarCondition`)
- `fnames::Vector`: Vector of feature names used to resolve variable indices for `SoleData.VariableValue` structs

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
    line::AbstractString, conditionstype::Type, fnames::Vector{<:VariableValue}
)
    parts = split(line, ' ')[2:end]  # skip '.ilb' command
    fnames = Symbol.(featurename.(fnames))

    return map(parts) do part
        # split with regex
        m = match(OP_REGEX, part)
        m === nothing && throw(ArgumentError("Invalid condition token: $(part)"))

        # reconstruct VariableValue
        varname = Symbol(m.captures[1])
        i_var = findfirst(==(varname), fnames)
        value = SoleData.VariableValue(i_var, varname)

        operator = OPERATOR_MAP[m.captures[2]]
        threshold = threshold = parse(Float64, m.captures[3])

        condition = conditionstype(value, operator, threshold)

        return SoleLogics.Atom{typeof(condition)}(condition)
    end
end

# ---------------------------------------------------------------------------- #
#                               univariate utils                               #
# ---------------------------------------------------------------------------- #
function _header(
    conditions::Vector{<:SoleData.AbstractScalarCondition},
    feat_condnames::Vector{Vector{String}},
)
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

    push!(
        pla_header,
        ".mv $(num_vars) $(num_binary_vars) $(join(feat_nconds[feat_nconds .> 1], " ")) 1",
    )
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
    feat_varidxs = [
        (startidx:endidx) for (startidx, endidx) in zip([1, (end_idxs .+ 1)...], end_idxs)
    ]

    # binary variables first
    binary_variable_idxs = findall(feat_nvar->feat_nvar == 1, feat_nconds)
    nonbinary_variable_idxs = findall(feat_nvar->feat_nvar > 1, feat_nconds)
    row = vcat(
        [row[feat_varidxs[i_var]] for i_var in binary_variable_idxs]...,
        (num_binary_vars > 0 ? ["|"] : [])...,
        [[row[feat_varidxs[i_var]]..., "|"] for i_var in nonbinary_variable_idxs]...,
    )
    return "$(join(row, ""))1"
end

# ---------------------------------------------------------------------------- #
#                                formula to pla                                #
# ---------------------------------------------------------------------------- #
"""
    _formula_to_pla(formula::SoleLogics.Formula; allow_scalar_range_conditions::Bool=false, kwargs...) -> (String, Vector{VariableValue})
    _formula_to_pla(dnfformula::SoleLogics.DNF; allow_scalar_range_conditions::Bool=false, kwargs...) -> (String, Vector{VariableValue})
    _formula_to_pla(atoms::Vector{Vector{SoleLogics.Atom}}; encoding::Symbol=:univariate, allow_scalar_range_conditions::Bool=false) -> (String, Vector{VariableValue})

Convert a logical formula into Programmable Logic Array (PLA) format representation.

This function transforms a logical formula into a PLA format suitable for digital logic synthesis
and hardware implementation. The conversion process involves normalizing the formula to Disjunctive
Normal Form (DNF), extracting conditions and features, and encoding the logic into a structured
PLA representation.

# Arguments
- `formula::SoleLogics.Formula`: The input logical formula to convert (first method)
- `dnfformula::SoleLogics.DNF`: A formula already in DNF form (second method)
- `atoms::Vector{Vector{SoleLogics.Atom}}`: Vector of atom vectors representing disjuncts (third method)

# Keyword Arguments
- `allow_scalar_range_conditions::Bool=false`: Whether to apply scalar tiling to conditions
- `encoding::Symbol=:univariate`: Encoding method for variables (`:univariate` or `:multivariate`)
- `kwargs...`: Additional keyword arguments passed to DNF conversion and scalar simplification

# Returns
A tuple containing:
- `String`: The complete PLA format string ready for use with logic synthesis tools
- `Vector{VariableValue}`: Vector of features (variable names) used in the formula

# Encoding Methods
- **`:univariate`**: Each condition becomes a binary input variable (standard PLA format)
- **`:multivariate`**: Groups conditions by feature, supporting multi-valued variables (experimental)

# Details
The conversion process follows these main steps:

1. **Formula Normalization**: Converts the input formula to DNF using NNF profile and atom flipping
2. **Scalar Simplification**: Applies scalar simplification techniques based on the configuration
3. **Condition Extraction**: Identifies unique conditions and features from the normalized formula
4. **Condition Processing**: Optionally applies scalar tiling and removes dual conditions
5. **Relationship Analysis**: Computes inclusion and exclusion relationships between conditions
6. **PLA Header Generation**: Creates appropriate headers based on encoding method:
   - `:univariate`: Standard binary encoding with `.i`, `.o`, `.ilb` directives
   - `:multivariate`: Multi-valued variable encoding with `.mv`, `.label` directives
7. **Row Encoding**: Converts each disjunct to PLA rows using the `_encode_disjunct` function
8. **Output Assembly**: Combines headers, onset rows, and termination markers into final PLA format

# PLA Format Output
The generated PLA string includes:
- Variable declarations (`.i`, `.o` for univariate; `.mv` for multivariate)
- Input/output labels (`.ilb`, `.ob`, `.label`)
- Product term count (`.p`)
- Logic onset rows (condition patterns with output values)
- End marker (`.e`)

# Examples
```julia
# Basic conversion with default settings
pla_string, features = _formula_to_pla(my_formula)

# Conversion with scalar range conditions
pla_string, features = _formula_to_pla(my_formula; allow_scalar_range_conditions=true)

# Multivariate encoding with pretty operators
pla_string, features = _formula_to_pla(
    my_dnf_formula;
    encoding=:multivariate,
    allow_scalar_range_conditions=true,
    pretty_op=true
)
```

# Notes
- The `:multivariate` encoding is experimental and may not be fully tested
- Scalar range conditions provide additional optimization opportunities through tiling
- The function automatically converts formulas to DNF with NNF profile and atom flipping enabled
- Conditions are automatically sorted and processed to remove redundancy and dual conditions
- The resulting PLA format is compatible with standard logic synthesis tools

# See Also
- `_encode_disjunct`: Function used internally to encode individual disjuncts
- `SoleLogics.dnf`: DNF conversion functionality
- `SoleData.scalar_simplification`: Scalar simplification methods
- `_pla_to_formula`: Inverse operation to convert PLA back to formula
"""
function _formula_to_pla(formula::SoleLogics.Formula; kwargs...)
    _formula_to_pla(
        SoleLogics.dnf(formula, SoleLogics.Atom; profile=:nnf, allow_atom_flipping=true);
        kwargs...,
    )
end

function _formula_to_pla(dnfformula::SoleLogics.DNF; allow_scalar_range_conditions::Bool=false, kwargs...)
    dnfformula = scalar_simplification(dnfformula; allow_scalar_range_conditions)
    dnfformula = SoleLogics.dnf(
        dnfformula; profile=:nnf, allow_atom_flipping=true, kwargs...
    )

    atoms_per_disjunct = Vector{Vector{SoleLogics.Atom}}([
        collect(SoleLogics.atoms(d)) for d in SoleLogics.disjuncts(dnfformula)
    ])

    _formula_to_pla(atoms_per_disjunct; allow_scalar_range_conditions, kwargs...)
end

function _formula_to_pla(
    atoms::Vector{Vector{SoleLogics.Atom}};
    encoding::Symbol=:univariate,
    allow_scalar_range_conditions::Bool=false,
    removewhitespaces::Bool=true,
    pretty_op::Bool=false,
)
    @assert encoding in [:univariate, :multivariate]

    # extract domains
    conditions = unique(map(SoleLogics.value, reduce(vcat, atoms)))
    fnames = unique(SoleData.feature.(conditions))
    nfnames = length(fnames)

    sort!(conditions; by=SoleData._scalarcondition_sortby)
    sort!(fnames; by=syntaxstring)

    if allow_scalar_range_conditions
        original_conditions = conditions
        conditions = SoleData.scalartiling(conditions, fnames)
        @assert length(setdiff(original_conditions, conditions)) == 0
            "$(SoleLogics.displaysyntaxvector(setdiff(original_conditions, conditions)))"
    end

    conditions = SoleData.removeduals(conditions)

    # for each feature, derive the conditions, and their names
    feat_condindxss = Vector{Vector{Int64}}(undef, nfnames)
    feat_condnames = Vector{Vector{String}}(undef, nfnames)

    @inbounds for (i, feat) in enumerate(fnames)
        feat_condindxs = findall(c->SoleData.feature(c) == feat, conditions)
        conds = filter(c->SoleData.feature(c) == feat, conditions)
        condname = SoleLogics.syntaxstring.(conds; removewhitespaces, pretty_op)

        feat_condindxss[i] = feat_condindxs
        feat_condnames[i] = condname
    end

    feat_nconds = length.(feat_condindxss)

    # derive inclusions and exclusions between conditions
    includes, excludes = Vector{BitMatrix}(undef, nfnames),
    Vector{BitMatrix}(undef, nfnames)
    @inbounds for (i, feat_condindxs) in enumerate(feat_condindxss)
        includes[i] = BitMatrix([
            SoleData.includes(conditions[cond_i], conditions[cond_j]) for
            cond_i in feat_condindxs, cond_j in feat_condindxs
        ])
        excludes[i] = BitMatrix([
            SoleData.excludes(conditions[cond_j], conditions[cond_i]) for
            cond_i in feat_condindxs, cond_j in feat_condindxs
        ])
    end

    # generate pla _header
    pla_header = if encoding == :multivariate
        _header(feat_nconds, feat_condnames)
    else
        _header(conditions, feat_condnames)
    end

    conjuncts = _get_conjuncts(atoms)
    pla_onset_rows = Vector{String}(undef, length(conjuncts))

    Threads.@threads for i in eachindex(conjuncts)
        row = _encode_disjunct(
            conjuncts[i], fnames, conditions, includes, excludes, feat_condindxss
        )
        pla_onset_rows[i] =
            encoding == :multivariate ? _onset_rows(feat_nconds, row) : _onset_rows(row)
    end

    # Combine PLA components
    pla_content = join(
        [
            join(pla_header, "\n"),
            ".p $(length(pla_onset_rows))",
            join(pla_onset_rows, "\n"),
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
    _pla_to_formula(
        pla::String,
        fnames::Vector{<:VariableValue};
        conditionstype::Type=SoleData.ScalarCondition,
        conjunct::Bool=false
    ) -> Union{SoleLogics.Formula, Vector{SyntaxStructure}}

Convert a Programmable Logic Array (PLA) format string back into a logical formula representation.

This function performs the inverse operation of `_formula_to_pla`, parsing a PLA format string
and reconstructing the corresponding logical formula. It processes input variable labels,
logic rows, and outputs the result either as a disjunctive normal form or as a vector of
conjunctive clauses.

# Arguments
- `pla::String`: The PLA format string to parse and convert
- `fnames::Vector{<:VariableValue}`: Vector of features corresponding to the variables in the PLA

# Keyword Arguments
- `conditionstype::Type=SoleData.ScalarCondition`: Type constructor for creating conditions from parsed input labels
- `conjunct::Bool=false`: If `true`, returns a `LeftmostDisjunctiveForm`; if `false`, returns a vector of disjuncts

# Returns
- If `conjunct=false`: `Vector{SyntaxStructure}` - Vector of conjunctive clauses (disjuncts)
- If `conjunct=true`: `LeftmostDisjunctiveForm` - Complete DNF formula
- Returns `⊤` (tautology) if no valid logic rows exist in the PLA

# Details
The conversion process follows these main steps:

1. **PLA Parsing**: Processes the input string line by line, extracting:
   - Input labels from `.ilb` directive
   - Logic rows (lines starting with '0', '1', '-', or '|')

2. **Condition Extraction**: Parses `.ilb` line using `_read_conditions`:
   - Creates `SoleLogics.Atom` objects from condition specifications
   - Matches feature names from `fnames` to construct `VariableValue` objects
   - Supports various operators defined in `OPERATOR_MAP`

3. **Row Processing**: Converts each PLA row into logical conjuncts:
   - `'1'` values become positive literals
   - `'0'` values become negative literals  
   - `'-'` and `'|'` values are ignored (don't-care or separator)
   - Extracts the binary pattern (excludes last 2 characters which are output and newline)

4. **Formula Reconstruction**: 
   - Each row becomes a `LeftmostConjunctiveForm` (conjunction of literals)
   - Applies `scalar_simplification` with `allow_scalar_range_conditions=false` to each disjunct
   - Multi-threaded processing for efficiency
   - Optionally wraps result in `LeftmostDisjunctiveForm` if `conjunct=true`

# PLA Format Support
The function expects standard PLA directives:
- `.ilb labels`: Input variable labels with condition specifications (required)
- Logic rows: Binary patterns with '0', '1', '-' characters, ending with output value
- Multi-valued rows: Supports '|' separator for multivariate encoding

# Examples
```julia
# Basic PLA to formula conversion
pla_string = \"\"\"
.i 3
.o 1  
.ilb [x]<5.0 [y]≥10.0 [z]<2.5
.ob output
11- 1
-01 1
.e
\"\"\"
features = [VariableValue(1, :x), VariableValue(2, :y), VariableValue(3, :z)]
disjuncts = _pla_to_formula(pla_string, features)

# Get complete DNF formula
formula = _pla_to_formula(pla_string, features; conjunct=true)

# Use custom condition type
formula = _pla_to_formula(
    pla_string, 
    features;
    conditionstype=MyCustomCondition,
    conjunct=true
)
```

# Processing Details
- **Simplification**: Each disjunct is simplified using `scalar_simplification`
- **Output Filtering**: Only processes rows ending with '1' (ON-set), automatically filtered by row extraction

# Notes
- The function assumes well-formed PLA input with valid syntax
- Feature names in `fnames` must match those in the `.ilb` directive
- The function strips the last 2 characters from each logic row (output value and potential whitespace)
- Returns `⊤` (tautology) if the PLA contains no valid logic rows
- Multi-valued variables (with '|' separators) are supported in the parsing

# See Also
- `_formula_to_pla`: Inverse function for converting formulas to PLA format
- `_read_conditions`: Helper function for parsing condition specifications
- `SoleData.scalar_simplification`: Formula optimization functionality
- `SoleLogics.LeftmostConjunctiveForm`: Conjunctive clause representation
- `SoleLogics.LeftmostDisjunctiveForm`: Disjunctive normal form representation
"""
function _pla_to_formula(
    pla::String,
    fnames::Vector{<:VariableValue};
    conditionstype::Type=SoleData.SoleData.ScalarCondition,
    conjunct::Bool=false,
)
    lines = split(pla, '\n')
    parsed_conditions = SoleLogics.Atom[]
    binaries = String[]

    for line in lines
        startswith(line, ".ilb") &&
            append!(parsed_conditions, _read_conditions(line, conditionstype, fnames))
        startswith(line, ['0', '1', '-', '|']) && append!(binaries, [line[1:(end - 2)]])
    end

    isempty(binaries) && return ⊤

    disjuncts = Vector{SyntaxStructure}(undef, length(binaries))

    Threads.@threads for i in eachindex(binaries)
        binary = binaries[i]
        disjuncts[i] = scalar_simplification(
            SoleLogics.LeftmostConjunctiveForm([
                SoleLogics.Literal(LiteralBool[value], parsed_conditions[idx]) for
                (idx, value) in enumerate(binary) if value ∈ ['1', '0']
            ]);
            allow_scalar_range_conditions=false,
        )
    end

    return conjunct ? LeftmostDisjunctiveForm(disjuncts) : disjuncts
end

end
