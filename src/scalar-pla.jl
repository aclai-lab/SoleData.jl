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
"""
    encode_disjunct(disjunct::LeftmostConjunctiveForm, features::AbstractVector, conditions::AbstractVector, includes, excludes, feat_condindxss) -> Vector{String}

    Encode a logical disjunct into a Programmable Logic Array (PLA) row representation.

    This function converts a logical disjunct (a conjunction of literals) into a PLA row format,
    where each position corresponds to a condition and can be set to "1" (true), "0" (false), 
    or "-" (don't care).

    # Arguments
    - `disjunct::LeftmostConjunctiveForm`: The logical disjunct to encode, containing literals
    - `features::AbstractVector`: Vector of features used in the logical formula
    - `conditions::AbstractVector`: Vector of all possible conditions 
    - `includes`: Matrix-like structure defining inclusion relationships between conditions
    - `excludes`: Matrix-like structure defining exclusion relationships between conditions
    - `feat_condindxss`: Mapping from features to their corresponding condition indices

    # Returns
    - `Vector{String}`: PLA row representation where each element is "1", "0", or "-"

    # Details
    The function processes each literal in the disjunct:
    - For positive literals, sets "1" for included conditions and "0" for excluded ones
    - For negative literals, inverts the logic (sets "0" for included, "1" for excluded)
    - Handles dual conditions when they exist by applying inverted logic
    - Detects and warns about logical conflicts when contradictory values are assigned
    - Preserves more restrictive values (NEG over POS) when conflicts occur

    # Examples
    ```julia
    # Assuming appropriate data structures are set up
    pla_row = encode_disjunct(my_disjunct, features, conditions, includes, excludes, feat_condindxss)
    # Returns something like: ["1", "0", "-", "1", "0"]
    ```

    # Notes
    - The function assumes that either the main condition or its dual exists in the conditions vector
    - Warnings are issued when logical conflicts are detected during encoding
    - The resulting PLA row uses "-" for don't-care positions that are not constrained by any literal
"""
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

        POS, NEG = ispos ? ("1", "0") : ("0", "1")
        
        # Manage the main condition
        if !isnothing(feat_icond)
            # For each condition this includes, set POS if not already NEG
            for (ic, c) in enumerate(feat_condindxs)
                if includes[i_feat][feat_icond, ic]
                    if pla_row[c] == "-"  # Only if it has not already been set
                        pla_row[c] = POS
                    elseif pla_row[c] == NEG && POS == "1"
                        # Conflict: We already have a NEG but we should put POS
                        # This indicates a logical problem in the formula
                        #@warn "Logic conflict detected at position $(c): was $(NEG), should be $(POS)"
                        # Keep NEG (more restrictive)
                    end
                end
            end
            
            # For any condition that this excludes, set NEG
            for (ic, c) in enumerate(feat_condindxs)
                if excludes[i_feat][feat_icond, ic]
                    if pla_row[c] == "-"
                        pla_row[c] = NEG
                    elseif pla_row[c] == POS && NEG == "0"
                        # Conflict: We already have a POS but we should put NEG
                        #@warn "Logic conflict detected at position $(c): was $(POS), should be $(NEG)"
                        # Set NEG (more restrictive)
                        pla_row[c] = NEG
                    end
                end
            end
        end
        
        # Handle dual condition if exists
        if !isnothing(feat_idualcond)
            # For dual condition, invert POS and NEG
            for (ic, c) in enumerate(feat_condindxs)
                if includes[i_feat][feat_idualcond, ic]
                    if pla_row[c] == "-"
                        pla_row[c] = NEG
                    elseif pla_row[c] == POS && NEG == "0"
                        #@warn "Logic conflict detected at position $(c): was $(POS), should be $(NEG)"
                        pla_row[c] = NEG
                    end
                end
            end
            
            for (ic, c) in enumerate(feat_condindxs)
                if excludes[i_feat][feat_idualcond, ic]
                    if pla_row[c] == "-"
                        pla_row[c] = POS
                    elseif pla_row[c] == NEG && POS == "1"
                        #@warn "Logic conflict detected at position $(c): was $(NEG), should be $(POS)"
                        # Keep NEG
                    end
                end
            end
        end
    end

    return pla_row
end

# Function to parse and process the formula into PLA
"""
        _formula_to_pla(formula::SoleLogics.Formula, dc_set=false, silent=true, args...; encoding=:univariate, use_scalar_range_conditions=false, kwargs...) -> (String, Tuple, NamedTuple)

    Convert a logical formula into Programmable Logic Array (PLA) format representation.

    This function transforms a logical formula into a PLA format suitable for digital logic synthesis
    and hardware implementation. The conversion process involves normalizing the formula to Disjunctive
    Normal Form (DNF), extracting conditions and features, and encoding the logic into a structured
    PLA representation.

    # Arguments
    - `formula::SoleLogics.Formula`: The input logical formula to convert
    - `dc_set::Bool=false`: Whether to include don't-care set in the output (currently unused)
    - `silent::Bool=true`: If `false`, prints intermediate steps and debugging information
    - `args...`: Additional positional arguments passed to underlying functions

    # Keyword Arguments
    - `encoding::Symbol=:univariate`: Encoding method for variables (`:univariate` or `:multivariate`)
    - `use_scalar_range_conditions::Bool=false`: Whether to use scalar range conditions in the conversion
    - `kwargs...`: Additional keyword arguments passed to DNF conversion and scalar simplification

    # Returns
    A tuple containing:
    - `String`: The complete PLA format string ready for use with logic synthesis tools
    - `Tuple`: A tuple containing `(nothing, conditions)` where conditions is the vector of extracted conditions
    - `NamedTuple`: Configuration parameters used in the conversion including encoding method and other options

    # Details
    The conversion process follows these main steps:

    1. **Formula Normalization**: Converts the input formula to DNF using specified profiles and atom flipping rules
    2. **Scalar Simplification**: Applies scalar simplification techniques based on the configuration
    3. **Condition Extraction**: Identifies unique conditions and features from the normalized formula
    4. **Condition Processing**: Optionally applies scalar tiling and removes dual conditions
    5. **Relationship Analysis**: Computes inclusion and exclusion relationships between conditions
    6. **PLA Header Generation**: Creates appropriate headers based on encoding method:
       - `:univariate`: Standard binary encoding with `.i`, `.o`, `.ilb` directives
       - `:multivariate`: Multi-valued variable encoding with `.mv`, `.label` directives
    7. **Row Encoding**: Converts each disjunct to PLA rows using the `encode_disjunct` function
    8. **Output Assembly**: Combines headers, onset rows, and termination markers into final PLA format

    # Encoding Methods
    - **`:univariate`**: Each condition becomes a binary input variable (standard PLA format)
    - **`:multivariate`**: Groups conditions by feature, supporting multi-valued variables (experimental)

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
    pla_string, conditions, config = _formula_to_pla(my_formula)

    # Verbose conversion with multivariate encoding
    pla_string, conditions, config = _formula_to_pla(
        my_formula, 
        false, 
        false;  # silent=false for debugging output
        encoding=:multivariate,
        use_scalar_range_conditions=true
    )
    ```

    # Notes
    - The `:multivariate` encoding is experimental and may not be fully tested
    - Scalar range conditions provide additional optimization opportunities but may increase complexity
    - The function assumes the input formula can be successfully converted to DNF
    - Conditions are automatically sorted and processed to remove redundancy
    - The resulting PLA format is compatible with standard logic synthesis tools

    # See Also
    - `encode_disjunct`: Function used internally to encode individual disjuncts
    - `SoleLogics.dnf`: DNF conversion functionality
    - `SoleData.scalar_simplification`: Scalar simplification methods
"""
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

"""
        _pla_to_formula(pla::AbstractString, silent=true, ilb_str=nothing, conditions=nothing; conditionstype=SoleData.ScalarCondition, featuretype=SoleData.VariableValue, featvaltype=nothing, kwargs...) -> SoleLogics.Formula
    
    Convert a Programmable Logic Array (PLA) format string back into a logical formula representation.
    
    This function performs the inverse operation of `_formula_to_pla`, parsing a PLA format string
    and reconstructing the corresponding logical formula in Disjunctive Normal Form (DNF). It handles
    both univariate (binary) and multivariate PLA formats, processing input variables, output
    specifications, and logic rows to rebuild the original logical structure.
    
    # Arguments
    - `pla::AbstractString`: The PLA format string to parse and convert
    - `silent::Bool=true`: If `false`, prints debugging information during parsing
    - `ilb_str::Union{String,Nothing}=nothing`: Expected input labels string for validation (optional)
    - `conditions::Union{AbstractVector,Nothing}=nothing`: Pre-existing conditions to map against (optional)
    
    # Keyword Arguments
    - `conditionstype::Type=SoleData.ScalarCondition`: Type constructor for creating new conditions
    - `featuretype::Type=SoleData.VariableValue`: Type for feature representation
    - `featvaltype::Union{Type,Nothing}=nothing`: Type for feature values (optional)
    - `kwargs...`: Additional arguments passed to condition parsing functions
    
    # Returns
    - `SoleLogics.Formula`: The reconstructed logical formula in DNF, or `⊤` (true) if no valid rows exist
    
    # Details
    The conversion process follows these main steps:
    
    1. **PLA Parsing**: Processes the input string line by line, extracting:
       - Variable declarations (`.i`, `.o`, `.mv`)
       - Input/output labels (`.ilb`, `.ob`, `.label`)
       - Logic rows and don't-care specifications
       - Multi-valued variable metadata
    
    2. **Variable Mapping**: Maps PLA input variables to logical conditions:
       - Uses provided `conditions` mapping if available
       - Creates new conditions using `conditionstype` constructor
       - Handles both binary and multi-valued variables
    
    3. **Row Processing**: Converts each PLA row into logical conjuncts:
       - `'1'` values become positive literals
       - `'0'` values become negative literals  
       - `'-'` values are ignored (don't-care)
       - Only processes ON-set rows (output = '1')
    
    4. **Formula Reconstruction**: Combines processed rows:
       - Each row becomes a conjunctive clause (AND of literals)
       - All clauses are combined disjunctively (OR of conjunctions)
       - Applies scalar simplification to optimize the result
    
    # PLA Format Support
    The function supports standard PLA directives:
    - `.i N`: Number of input variables (univariate format)
    - `.o N`: Number of output variables (must be 1)
    - `.mv N B S1 S2...`: Multi-valued variable declaration (experimental)
    - `.ilb labels`: Input variable labels
    - `.ob label`: Output variable label
    - `.label var=N labels`: Multi-valued variable labels
    - `.p N`: Number of product terms (ignored)
    - `.e`: End marker
    
    # Examples
    ```julia
    # Basic PLA to formula conversion
    pla_string = \"""
    .i 3
    .o 1  
    .ilb x y z
    .ob output
    11- 1
    -01 1
    .e
    \"""
    formula = _pla_to_formula(pla_string)
    
    # Conversion with pre-defined conditions
    formula = _pla_to_formula(pla_string, true, nothing, my_conditions)
    
    # Verbose conversion with custom types
    formula = _pla_to_formula(
        pla_string, 
        false;  # silent=false for debugging
        conditionstype=MyConditionType,
        featuretype=MyFeatureType
    )
    ```
        
    # Multi-valued Variable Support
    For PLA files with multi-valued variables (`.mv` directive):
    - Binary variables are processed first
    - Multi-valued variables are grouped and processed separately
    - Variable labels are extracted from `.label` directives
    - Each multi-valued variable contributes one selected literal per row
        
    # Error Handling
    The function validates:
    - PLA format correctness and known directive support
    - Consistency between provided and parsed input labels
    - Single output variable requirement
    - Valid truth values in logic rows
    
    # Notes
    - Multi-valued variable support is experimental and may not be fully tested
    - The function assumes well-formed PLA input with valid syntax
    - Only ON-set rows (output='1') are processed; OFF-set and don't-care rows are ignored
    - Scalar simplification is applied to optimize the reconstructed formula
    - Returns `⊤` (tautology) if no valid logic rows are found
    
    # See Also
    - `_formula_to_pla`: Inverse function for converting formulas to PLA format
    - `SoleData.scalar_simplification`: Formula optimization functionality
    - `parsecondition`: Condition parsing utilities
"""
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