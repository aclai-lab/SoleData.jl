"""
    Scalar DNF Formula Visualization Module

This module provides functionality for creating graphical representations of 
Normal Form scalar formulas (e.g., DNF) using interval-based visualizations.
"""

export show_scalardnf

using Printf: @sprintf
using SoleData: AbstractScalarCondition

using .IntervalSetsWrap: infimum, supremum, isleftopen, isrightopen

# ============================================================================================
# Interval Extraction Functions
# ============================================================================================

"""
    extract_intervals(formula::LeftmostConjunctiveForm{<:Atom}) -> Dict{Any, IntervalSetsWrap.Interval}
    extract_intervals(formula::LeftmostDisjunctiveForm{<:Atom}) -> Dict{Any, IntervalSetsWrap.Interval}

Extract interval constraints for each variable from a scalar conjunction/disjunction.

This function handles both conjunctive and disjunctive forms:
- For conjunctions, constraints on the same variable are intersected (AND operation)
- For disjunctions, constraints on the same variable are unioned (OR operation)

Returns a dictionary mapping each feature/variable to its constraint interval.

# Examples
```julia
extract_intervals(@scalarformula (V1 ≥ 2.0) ∧ (V1 < 5.0) ∧ (V2 > 1.0))
# Returns: Dict(V1 => [2.0, 5.0), V2 => (1.0, +∞))

extract_intervals(@scalarformula (V1 < 3.0) ∨ (V1 > 7.0))
# Returns: Dict(V1 => (-∞, 3.0) ∪ (7.0, +∞))
```
"""
function extract_intervals(conjunction::LeftmostConjunctiveForm)::Dict{Any, IntervalSetsWrap.Interval}
    _extract_intervals(SoleLogics.conjuncts(conjunction), true)
end

function extract_intervals(disjunction::LeftmostDisjunctiveForm)::Dict{Any, IntervalSetsWrap.Interval}
    _extract_intervals(SoleLogics.disjuncts(disjunction), false)
end

"""
This function processes each atom by:
1. Extracting the scalar condition and its associated feature
2. Converting the condition to an interval representation
3. Combining intervals for the same variable according to the polarity:
   - `polarity=true`: Intersection (∩) for conjunctions
   - `polarity=false`: Union (∪) for disjunctions
"""
function _extract_intervals(atoms::Vector, polarity::Bool)::Dict{Any, IntervalSetsWrap.Interval}
    by_var = Dict{Any, IntervalSetsWrap.Interval}()
    
    for atom in atoms
        @assert atom isa Atom "Cannot handle non-Atom leaves; got $(typeof(atom)) instead."
        
        # Extract the scalar condition from the atom
        cond = SoleLogics.value(atom)
        @assert cond isa AbstractScalarCondition typeof(cond)
        
        # Get the feature (variable) and convert condition to interval
        feat = SoleData.feature(cond)
        interval = tointervalset(cond)
        
        # Combine intervals for the same variable
        by_var[feat] = if haskey(by_var, feat)
            if polarity
                # Conjunction: intersect intervals (both conditions must hold)
                by_var[feat] ∩ interval
            else
                # Disjunction: union intervals (either condition can hold)
                by_var[feat] ∪ interval
            end
        else
            # First time seeing this variable
            interval
        end
    end
    by_var
end

# ============================================================================================
# Threshold Collection and Processing
# ============================================================================================

# Collect and sort all unique threshold values from interval boundaries.
function collect_thresholds(all_intervals::Vector{Dict{Any, IntervalSetsWrap.Interval}})::Vector{Any}
    thresholds = Set{Number}()
    
    # Collect all interval boundaries
    for intervals in all_intervals
        for interval in values(intervals)
            push!(thresholds, infimum(interval))  # Lower bound
            push!(thresholds, supremum(interval)) # Upper bound
        end
    end
    
    sort(collect(thresholds))
end

# ============================================================================================
# Interval Type and Segment Processing
# ============================================================================================

"""
    IntervalType

Mutable structure representing the boundary properties of an interval segment.

# Fields
- `left_closed::Bool`: Whether the left boundary is closed (inclusive)
- `full::Bool`: Whether this segment is fully covered by the interval
- `right_closed::Bool`: Whether the right boundary is closed (inclusive)

This structure is used to track how interval boundaries map to visualization segments,
determining whether to draw '[' or '(' for left boundaries and ']' or ')' for right boundaries.
"""
mutable struct IntervalType
    left_closed::Bool    # Whether left boundary uses '[' (closed) or '(' (open)
    full::Bool          # Whether this segment should be filled
    right_closed::Bool  # Whether right boundary uses ']' (closed) or ')' (open)
end

"""
    compute_segmenttypes(interval, thresholds) -> (Vector{IntervalType}, Union{Int,Nothing}, Union{Int,Nothing})

Compute how an interval maps to visualization segments defined by threshold values.

This function determines which segments between consecutive thresholds are covered
by the given interval and how the interval boundaries should be displayed.

# Arguments
- `interval`: An interval object with infimum, supremum, and boundary type information
- `thresholds`: Sorted vector of threshold values defining segment boundaries

# Returns
- `Vector{IntervalType}`: Array describing the visual properties of each segment
- `Union{Int,Nothing}`: Index of first non-empty segment (for left boundary marker)
- `Union{Int,Nothing}`: Index of last non-empty segment (for right boundary marker)

# Algorithm
1. Extract interval bounds and boundary types (open/closed)
2. For each segment between consecutive thresholds, determine if it intersects the interval
3. Mark segments as full/empty and set appropriate boundary markers
4. Handle open vs closed boundaries by adjusting the first and last segment markers
"""
function compute_segmenttypes(interval, thresholds)
    # Extract interval properties
    (minv, mini, maxv, maxi) = (
        infimum(interval),      # Lower bound value
        !isleftopen(interval),  # Is left boundary closed?
        supremum(interval),     # Upper bound value
        !isrightopen(interval)  # Is right boundary closed?
    )
    
    nseg = length(thresholds) - 1

    # Determine which segments are non-empty (intersect with the interval)
    isnonempty = [begin
        t0 = thresholds[i]      # Left threshold of segment
        t1 = thresholds[i+1]    # Right threshold of segment
        
        # Segment intersects interval if interval doesn't end before segment starts
        # or start after segment ends
        if maxv <= t0 || minv >= t1
            false
        else
            true
        end
    end for i in 1:nseg]

    # Initialize all segments: non-empty segments are marked as full and closed
    segmenttypes = map(nonempty -> IntervalType(nonempty, nonempty, nonempty), isnonempty)
    
    # Find the first and last non-empty segments for boundary markers
    first_idx = findfirst(identity, isnonempty)
    last_idx  = findlast(identity, isnonempty)
    
    # Adjust boundary markers for open intervals
    if !mini && first_idx !== nothing
        # Left boundary is open: use '(' instead of '['
        segmenttypes[first_idx].left_closed = false
    end
    if !maxi && last_idx !== nothing
        # Right boundary is open: use ')' instead of ']'
        segmenttypes[last_idx].right_closed = false
    end
    
    segmenttypes, first_idx, last_idx
end

# ============================================================================================
# Bar Drawing and Visualization
# ============================================================================================

"""
    draw_bar(segmenttypes, first_idx, last_idx; colwidth=5, body_char="=") -> String

Generate ASCII art representation of an interval as a horizontal bar.

# Examples
```julia
# For an interval [2.0, 5.0) across thresholds [0, 2, 3, 5, 7]:
# Returns: "     [==========)     "
#          ^     ^    ^    ^     ^
#         [0,2] [2,3] [3,5] [5,7]
```
"""
function draw_bar(segmenttypes, first_idx, last_idx; colwidth=5, body_char="=")
    # Initialize all segments as empty spaces
    segments_str = fill(" " ^ colwidth, length(segmenttypes))

    # Fill segments that are covered by the interval
    for i in 1:length(segmenttypes)
        if segmenttypes[i].full
            segments_str[i] = body_char ^ colwidth
        end
    end

    # Add left boundary marker
    if !isnothing(first_idx)
        segments_str[first_idx] = let x = collect(segments_str[first_idx])
            x[1] = (segmenttypes[first_idx].left_closed ? '[' : '(')
            String(x)
        end
    end
    
    # Add right boundary marker
    if !isnothing(last_idx)
        segments_str[last_idx] = let x = collect(segments_str[last_idx])
            x[colwidth] = (segmenttypes[last_idx].right_closed ? ']' : ')')
            String(x)
        end
    end

    # Add leading space and join all segments
    " " ^ colwidth * join(segments_str)
end

# ============================================================================================
# Main Visualization Functions
# ============================================================================================


"""
    show_scalardnf(io::IO, formula::DNF; kwargs...)
    show_scalardnf(formula::DNF; kwargs...)

Create and display a graphical representation of a scalar DNF formula.

This function generates an ASCII art visualization showing how each variable's
constraints are satisfied across different threshold ranges. Each disjunct
in the DNF is shown separately, with variables displayed as horizontal bars
indicating their valid ranges.

# Arguments
- `io::IO`: Output stream to write the visualization
- `formula::DNF`: The scalar DNF formula to visualize

# Keyword Arguments
- `show_all_variables::Bool = false`: Whether to display variables with infinite ranges (always-true constraints)
- `print_disjunct_nrs::Bool = false`: Whether to print disjunct numbers and formulas
- `palette::Vector = [:cyan, :green, :yellow, :magenta, :blue]`: Colors for different variables
- `colwidth::Int = 5`: Width of each threshold column (minimum 5)
- `body_char::Char = '='`: Character used to fill interval bars (alternatives: '■', '━')

# Visualization Format

The output consists of:
1. **Header**: Threshold values aligned with columns
2. **Disjunct sections**: Each disjunct shown separately with:
   - Optional disjunct number and formula (if `print_disjunct_nrs=true`)
   - Variable bars showing constraint ranges
   - Color coding for different variables

# Examples

```julia
f = @scalarformula(
    ((V1 < 5.85) ∧ (V1 ≥ 5.65) ∧ (V2 < 2.85)) ∨
    ((V1 < 5.3) ∧ (V2 ≥ 2.85))
) |> dnf

show_scalardnf(f; colwidth=6)
# Output:
#            -Inf  2.85  5.30  5.65  5.85   Inf
#
#   V1 :                        [===)
#   V2 :       [===)
#
#   V1 :       [==========)
#   V2 :             [================]

show_scalardnf(f; print_disjunct_nrs=true, body_char='■')
# Shows disjunct formulas and uses ■ for bars
```

# Extended Help

The algorithm is as follows:

1. **Normalization**: Normalize the input formula
2. **Interval extraction**: Convert each disjunct to variable intervals
3. **Threshold collection**: Gather all interval boundaries
4. **Grid setup**: Create column layout based on thresholds
5. **Visualization**: For each disjunct and variable:
   - Compute segment coverage
   - Draw interval bar with appropriate boundaries
   - Apply color coding
   - Output formatted result

Notes:

- Variables with infinite ranges ((-∞, +∞)) are hidden unless `show_all_variables=true`
- Interval boundaries are shown as '[' (closed) or '(' (open) on the left,
  and ']' (closed) or ')' (open) on the right
- Colors cycle through the palette for variables
- The `colwidth` must be at least 5 to accommodate boundary markers
"""
show_scalardnf(f::DNF; kwargs...) = show_scalardnf(stdout, f; kwargs...)

function show_scalardnf(
    io::IO,
    formula::DNF;
    show_all_variables=false,
    print_disjunct_nrs=false,
    palette=[:cyan, :green, :yellow, :magenta, :blue],
    colwidth=5,
    body_char='=', # alternatives: ■, ━
)
    @assert colwidth >= 5 "Column width must be at least 5 to accommodate boundary markers."
    
    # Normalize the formula for consistent processing
    formula = normalize(formula)
    disjs = SoleLogics.disjuncts(formula)
    
    # Extract interval constraints for each disjunct
    all_intervals = [extract_intervals(d) for d in disjs]
    
    # Collect all variables mentioned in any disjunct
    all_vars = Set{Any}()
    for intervals in all_intervals, v in keys(intervals)
        push!(all_vars, v)
    end
    all_vars = sort(collect(all_vars))
    
    # Collect all threshold values for the grid
    all_thresholds = collect_thresholds(all_intervals)

    # Calculate layout parameters
    namewidth = maximum(length(syntaxstring(v)) for v in all_vars)

    # Generate and print header with threshold values
    header = " " ^ (3 + colwidth + namewidth)  # Space for variable names and separators
    for t in all_thresholds
        header *= @sprintf("%-*.*f", colwidth, 2, t)
    end
    println(io, header)
    println(io)  # Empty line after header

    # Assign colors to variables (cycling through palette)
    var_colors = Dict{Any,Symbol}()
    for (i, v) in enumerate(all_vars)
        var_colors[v] = get(var_colors, v, palette[(i-1) % length(palette) + 1])
    end

    # Process and display each disjunct
    for (i, (d, intervals)) in enumerate(zip(disjs, all_intervals))
        # Optional disjunct header
        print_disjunct_nrs && println(io, "Disjunct $i: ", syntaxstring(normalize(d)))
        
        # Display each variable's constraints in this disjunct
        for v in all_vars
            # Determine the interval for this variable in this disjunct
            if !haskey(intervals, v)
                if show_all_variables
                    # Variable is unconstrained (always true)
                    interval = IntervalSetsWrap.Interval(-Inf, Inf)
                else
                    # Skip unconstrained variables
                    continue
                end
            else
                interval = intervals[v]
            end

            # Skip infinite intervals unless explicitly requested
            if interval == IntervalSetsWrap.Interval(-Inf, Inf) && !show_all_variables
                continue
            end

            # Compute how this interval maps to the visualization segments
            segmenttypes, first_idx, last_idx = compute_segmenttypes(interval, all_thresholds)

            # Generate the bar representation
            bar = draw_bar(segmenttypes, first_idx, last_idx; colwidth, body_char)
            
            # Output the variable name and colored bar
            color = var_colors[v]
            print(io, "  ")  # Indentation
            printstyled(io, rpad(syntaxstring(v), namewidth), " : ", bar, color=color)
            println(io)
        end
        println(io)  # Empty line between disjuncts
    end
end

