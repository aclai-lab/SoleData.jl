using SoleLogics

# ==============================================================================
# Core Data Structures
# ==============================================================================

"""
    VariableBounds

Immutable structure representing effective bounds for a single variable.
Handles multiple constraints by storing the most restrictive bounds.

# Fields
- `lower_bound::Float64`: The lower bound threshold
- `upper_bound::Float64`: The upper bound threshold  
- `has_lower::Bool`: Whether a lower bound constraint exists
- `has_upper::Bool`: Whether an upper bound constraint exists
- `lower_inclusive::Bool`: Whether the lower bound is inclusive (≥ vs >)
- `upper_inclusive::Bool`: Whether the upper bound is inclusive (≤ vs <)

# Constructors
- `VariableBounds()`: Creates unconstrained bounds
- `VariableBounds(relation, threshold)`: Creates bounds from a single constraint
"""
struct VariableBounds
    lower_bound::Float64
    upper_bound::Float64
    has_lower::Bool
    has_upper::Bool
    lower_inclusive::Bool
    upper_inclusive::Bool
    
    # Default constructor: unconstrained
    VariableBounds() = new(-Inf, Inf, false, false, true, true)
    
    # Constructor from single constraint
    function VariableBounds(relation::Function, threshold::Float64)
        if relation === ≥
            new(threshold, Inf, true, false, true, true)
        elseif relation === >
            new(threshold, Inf, true, false, false, true)
        elseif relation === <
            new(-Inf, threshold, false, true, true, false)
        elseif relation === ≤
            new(-Inf, threshold, false, true, true, true)
        else
            throw(ArgumentError("Unsupported relation: $relation"))
        end
    end
    
    # Full constructor (internal use)
    VariableBounds(lb, ub, hl, hu, li, ui) = new(lb, ub, hl, hu, li, ui)
end

# ==============================================================================
# Constraint Extraction
# ==============================================================================

"""
    Constraint

Simple struct to hold constraint information for cleaner code.
"""
struct Constraint   # TODO maybe in sole we have most value type of variables and this isnt important or necessary 
    variable_id::Int
    relation::Function
    threshold::Float64
end

"""
    extract_constraint(atom; silent::Bool=true) -> Constraint

Extract constraint information from a SoleLogics atom.

# Arguments
- `atom`: An atomic constraint from SoleLogics
- `silent`: Controls debug output

# Returns
- `Constraint` object containing variable ID, relation, and threshold
"""
function extract_constraint(atom; silent::Bool=true)::Constraint
    metacond = atom.value.metacond
    var_id = metacond.feature.i_variable
    threshold = atom.value.threshold
    
    # Extract relation from type parameters
    relation = _extract_relation(typeof(metacond), silent)
    
    !silent && @info "Extracted constraint" var_id relation threshold
    
    return Constraint(var_id, relation, threshold)
end

"""
    _extract_relation(metacond_type::Type, silent::Bool) -> Function

Internal function to extract relation from metacondition type.
"""
function _extract_relation(metacond_type::Type, silent::Bool)::Function
    # Try to get relation from type parameters
    if metacond_type <: ScalarMetaCondition && length(metacond_type.parameters) ≥ 2
        rel_type = metacond_type.parameters[2]
        relation = _type_to_relation(rel_type)
        relation !== nothing && return relation
    end
    
    # Fallback to string parsing
    type_str = string(metacond_type)
    !silent && @debug "Parsing type string" type_str
    
    return _parse_relation_from_string(type_str)
end

"""
    _type_to_relation(rel_type::Type) -> Union{Function, Nothing}

Convert a relation type to the corresponding function.
"""
function _type_to_relation(rel_type::Type)
    rel_type == typeof(<) && return <
    rel_type == typeof(≥) && return ≥
    rel_type == typeof(>=) && return ≥
    rel_type == typeof(>) && return >
    rel_type == typeof(≤) && return ≤
    rel_type == typeof(<=) && return ≤
    return nothing
end

"""
    _parse_relation_from_string(type_str::String) -> Function

Parse relation from type string representation.
"""
function _parse_relation_from_string(type_str::String)::Function
    occursin("typeof(<)", type_str) && return <
    (occursin("typeof(≥)", type_str) || occursin("typeof(>=)", type_str)) && return ≥
    occursin("typeof(>)", type_str) && return >
    (occursin("typeof(≤)", type_str) || occursin("typeof(<=)", type_str)) && return ≤
    
    @warn "Could not parse relation from type string, using default ≥" type_str
    return ≥
end

# ==============================================================================
# Bounds Operations
# ==============================================================================

"""
    merge_bounds(vb1::VariableBounds, vb2::VariableBounds) -> VariableBounds

Merge two VariableBounds objects, keeping the most restrictive constraints.
"""
function merge_bounds(vb1::VariableBounds, vb2::VariableBounds)::VariableBounds
    # Determine most restrictive lower bound
    new_lower, new_has_lower, new_lower_inclusive = if !vb1.has_lower && !vb2.has_lower
        (-Inf, false, true)
    elseif !vb1.has_lower
        (vb2.lower_bound, true, vb2.lower_inclusive)
    elseif !vb2.has_lower
        (vb1.lower_bound, true, vb1.lower_inclusive)
    elseif vb1.lower_bound > vb2.lower_bound
        (vb1.lower_bound, true, vb1.lower_inclusive)
    elseif vb2.lower_bound > vb1.lower_bound
        (vb2.lower_bound, true, vb2.lower_inclusive)
    else  # Equal bounds
        (vb1.lower_bound, true, vb1.lower_inclusive && vb2.lower_inclusive)
    end
    
    # Determine most restrictive upper bound
    new_upper, new_has_upper, new_upper_inclusive = if !vb1.has_upper && !vb2.has_upper
        (Inf, false, true)
    elseif !vb1.has_upper
        (vb2.upper_bound, true, vb2.upper_inclusive)
    elseif !vb2.has_upper
        (vb1.upper_bound, true, vb1.upper_inclusive)
    elseif vb1.upper_bound < vb2.upper_bound
        (vb1.upper_bound, true, vb1.upper_inclusive)
    elseif vb2.upper_bound < vb1.upper_bound
        (vb2.upper_bound, true, vb2.upper_inclusive)
    else  # Equal bounds
        (vb1.upper_bound, true, vb1.upper_inclusive && vb2.upper_inclusive)
    end
    
    return VariableBounds(new_lower, new_upper, new_has_lower, new_has_upper, 
                         new_lower_inclusive, new_upper_inclusive)
end

"""
    add_constraint(vb::VariableBounds, constraint::Constraint) -> VariableBounds

Add a constraint to existing bounds, returning new bounds with the constraint applied.
"""
function add_constraint(vb::VariableBounds, constraint::Constraint)::VariableBounds
    new_bound = VariableBounds(constraint.relation, constraint.threshold)
    return merge_bounds(vb, new_bound)
end

"""
    get_atoms(conjunctive_form) -> Vector

Get all atoms from a conjunctive form, handling both single atoms and complex forms.
This fixes the issue with `grandchildren` not existing on Atom types.
"""
function get_atoms(conjunctive_form)
    # If it's already an Atom, return it as a single-element vector
    if isa(conjunctive_form, Atom)
        return [conjunctive_form]
    end
    
    # If it has children field (more common in SoleLogics)
    if hasfield(typeof(conjunctive_form), :children)
        return conjunctive_form.children
    end
    
    # If it has grandchildren field  
    if hasfield(typeof(conjunctive_form), :grandchildren)
        return conjunctive_form.grandchildren
    end
    
    # Try to iterate directly if it's iterable
    try
        return collect(conjunctive_form)
    catch
        # Fallback: treat as single atom
        return [conjunctive_form]
    end
end

"""
    extract_term_bounds(conjunctive_form; silent::Bool=true) -> Dict{Int,VariableBounds}

Extract bounds for all variables in a conjunctive term.
Fixed to handle both single Atoms and complex conjunctive forms.
"""
function extract_term_bounds(conjunctive_form; silent::Bool=true)::Dict{Int,VariableBounds}
    # Get atoms using our safe function
    atoms = get_atoms(conjunctive_form)
    
    !silent && @info "Processing conjunctive form" n_atoms=length(atoms) type=typeof(conjunctive_form)
    
    constraints = [extract_constraint(atom; silent) for atom in atoms]
    
    # Group constraints by variable ID and merge bounds
    bounds_dict = Dict{Int,VariableBounds}()
    
    for constraint in constraints
        var_id = constraint.variable_id
        old_bounds = get(bounds_dict, var_id, VariableBounds())
        bounds_dict[var_id] = add_constraint(old_bounds, constraint)
    end
    
    return bounds_dict
end

# ==============================================================================
# Domination Logic
# ==============================================================================

"""
    strictly_dominates(vb1::VariableBounds, vb2::VariableBounds) -> Bool

 Check if bounds vb1 strictly dominate bounds vb2.
vb1 strictly dominates vb2 if vb1 represents a WEAKER constraint that COVERS MORE space.
"""
function strictly_dominates(vb1::VariableBounds, vb2::VariableBounds)::Bool
    # If vb2 has no constraints, vb1 cannot dominate it
    (!vb2.has_lower && !vb2.has_upper) && return false
    
    # Check lower bound domination (vb1 is weaker/covers more)
    lower_dominates_or_equal = if !vb1.has_lower && vb2.has_lower
        true  # vb1 has no lower bound, vb2 has one -> vb1 covers more
    elseif !vb1.has_lower && !vb2.has_lower
        true  # Both have no lower bound -> equal
    elseif vb1.has_lower && !vb2.has_lower
        false # vb1 has constraint, vb2 doesn't -> vb1 doesn't dominate
    elseif vb1.lower_bound < vb2.lower_bound
        true  # vb1 allows smaller values -> covers more
    elseif vb1.lower_bound == vb2.lower_bound
        # Same threshold: vb1 dominates if it's more inclusive
        !vb2.lower_inclusive || vb1.lower_inclusive
    else
        false # vb1.lower_bound > vb2.lower_bound -> vb1 is more restrictive
    end
    
    # Check upper bound domination (vb1 is weaker/covers more)
    upper_dominates_or_equal = if !vb1.has_upper && vb2.has_upper
        true  # vb1 has no upper bound, vb2 has one -> vb1 covers more
    elseif !vb1.has_upper && !vb2.has_upper
        true  # Both have no upper bound -> equal
    elseif vb1.has_upper && !vb2.has_upper
        false # vb1 has constraint, vb2 doesn't -> vb1 doesn't dominate
    elseif vb1.upper_bound > vb2.upper_bound
        true  # vb1 allows larger values -> covers more
    elseif vb1.upper_bound == vb2.upper_bound
        # Same threshold: vb1 dominates if it's more inclusive
        !vb2.upper_inclusive || vb1.upper_inclusive
    else
        false # vb1.upper_bound < vb2.upper_bound -> vb1 is more restrictive
    end
    
    # Check if vb1 is strictly weaker (at least one dimension strictly dominates)
    lower_strictly_dominates = if !vb1.has_lower && vb2.has_lower
        true  # vb1 unconstrained, vb2 constrained
    elseif !vb1.has_lower || !vb2.has_lower
        false # One is unconstrained
    elseif vb1.lower_bound < vb2.lower_bound
        true  # vb1 strictly weaker lower bound
    elseif vb1.lower_bound == vb2.lower_bound
        vb1.lower_inclusive && !vb2.lower_inclusive  # vb1 more inclusive
    else
        false
    end
    
    upper_strictly_dominates = if !vb1.has_upper && vb2.has_upper
        true  # vb1 unconstrained, vb2 constrained
    elseif !vb1.has_upper || !vb2.has_upper
        false # One is unconstrained
    elseif vb1.upper_bound > vb2.upper_bound
        true  # vb1 strictly weaker upper bound
    elseif vb1.upper_bound == vb2.upper_bound
        vb1.upper_inclusive && !vb2.upper_inclusive  # vb1 more inclusive
    else
        false
    end
    
    # For strict domination: both dimensions must dominate or be equal,
    # and at least one must strictly dominate
    return lower_dominates_or_equal && upper_dominates_or_equal && 
           (lower_strictly_dominates || upper_strictly_dominates)
end

"""
    strictly_dominates(bounds1::Dict{Int,VariableBounds}, bounds2::Dict{Int,VariableBounds}) -> Bool

 Check if term with bounds1 strictly dominates term with bounds2.

    A term dominates another ONLY if it covers a SUPERSET of the solution space.
This means bounds1 must have weaker or equal constraints on ALL variables.
"""
function strictly_dominates(bounds1::Dict{Int,VariableBounds}, bounds2::Dict{Int,VariableBounds})::Bool
    # CRITICAL: Get all variables that appear in either term
    all_variables = Set(union(keys(bounds1), keys(bounds2)))
    
    has_strictly_weaker_constraint = false
    
    for var_id in all_variables
        vb1 = get(bounds1, var_id, VariableBounds())  # No constraint if missing
        vb2 = get(bounds2, var_id, VariableBounds())  # No constraint if missing
        
        # Check if vb1 dominates or equals vb2 for this variable
        if strictly_dominates(vb1, vb2)
            has_strictly_weaker_constraint = true
        elseif !bounds_equal(vb1, vb2)
            # vb1 neither dominates nor equals vb2 -> vb1 cannot dominate bounds2
            return false
        end
    end
    
    # bounds1 dominates bounds2 only if:
    # 1. All variables: vb1 dominates or equals vb2
    # 2. At least one variable: vb1 strictly dominates vb2
    return has_strictly_weaker_constraint
end

"""
    bounds_equal(vb1::VariableBounds, vb2::VariableBounds) -> Bool

Check if two VariableBounds represent exactly the same constraint.
"""
function bounds_equal(vb1::VariableBounds, vb2::VariableBounds)::Bool
    return (vb1.has_lower == vb2.has_lower) &&
           (vb1.has_upper == vb2.has_upper) &&
           (!vb1.has_lower || (vb1.lower_bound == vb2.lower_bound && vb1.lower_inclusive == vb2.lower_inclusive)) &&
           (!vb1.has_upper || (vb1.upper_bound == vb2.upper_bound && vb1.upper_inclusive == vb2.upper_inclusive))
end

# ==============================================================================
# DNF Minimization
# ==============================================================================
"""
    refine_dnf(dnf_formula; silent::Bool=true) → DNF

Perform logical minimization of a Disjunctive Normal Form (DNF) formula by eliminating 
redundant terms while preserving the complete solution space through dominance analysis.

The algorithm identifies and removes terms that are strictly dominated by other terms,
where term A dominates term B if A's constraints are a proper subset of B's constraints,
ensuring that any solution satisfying B will also satisfy A.

# Arguments
- `dnf_formula`: The DNF formula to minimize
- `silent::Bool=true`: Controls verbosity of the minimization process
  - `true`: Silent execution with minimal output  
  - `false`: Detailed progress reporting and term analysis

# Returns
- **DNF Formula**: Minimized formula of the same type as input, guaranteed to have
  identical solution space but potentially fewer terms
"""
function refine_dnf(dnf_formula; silent::Bool=true) 
    
    !silent && println("refine_dnf are running")
    
    terms = get_atoms(dnf_formula)
    n_terms = length(terms)
    
    !silent && @info "Starting DNF minimization" original_terms=n_terms formula_type=typeof(dnf_formula)
    
    # Handle edge case of single term
    if n_terms <= 1
        !silent && @info "Formula has ≤1 terms, no minimization needed"
        return dnf_formula
    end
    
    # Extract bounds for all terms
    all_bounds = map(term -> extract_term_bounds(term; silent), terms)
    
    # DEBUG: Print all terms and their bounds if not silent
    if !silent
        println("\n=== TERMS ANALYSIS ===")
        for (i, bounds) in enumerate(all_bounds)
            println("Term $i:")
            println("dump(bounds)",dump(bounds)) # TODO notice is only for debug... maybe we can remove this?
        end
        println()
    end
    
    # Find terms that are NOT strictly dominated by any other term
    keep_mask = map(enumerate(all_bounds)) do (i, bounds_i)
        is_dominated = any(enumerate(all_bounds)) do (j, bounds_j)
            if i != j
                dominates = strictly_dominates(bounds_j, bounds_i)
                if !silent && dominates
                    println("✓ Term $j dominates term $i -> eliminating term $i")
                end
                return dominates
            end
            return false
        end
        return !is_dominated
    end
    
    kept_indices = findall(keep_mask)
    minimized_terms = terms[kept_indices]
    
    # Safety check: never return empty formula
    if isempty(minimized_terms)
        @warn "All terms were dominated (this indicates a BUG!), keeping all terms for safety"
        return dnf_formula
    end
    
    reduction = n_terms - length(kept_indices)
    reduction_percent = round((reduction / n_terms) * 100, digits=1)
    
    # Return same type as input with minimized terms
    return typeof(dnf_formula)(minimized_terms)
end