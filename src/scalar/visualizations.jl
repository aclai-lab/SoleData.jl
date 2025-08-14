export show_scalardnf

using Printf: @sprintf
using SoleData: AbstractScalarCondition

using .IntervalSetsWrap: infimum, supremum, isleftopen, isrightopen, :(..)

function extract_intervals(conjunction::LeftmostConjunctiveForm)
    _extract_intervals(SoleLogics.conjuncts(conjunction), true)
end
function extract_intervals(disjunction::LeftmostDisjunctiveForm)
    _extract_intervals(SoleLogics.disjuncts(disjunction), false)
end

# polarity = true computes the intersection
# polarity = false computes the union
function _extract_intervals(atoms::Vector, polarity::Bool)
    by_var = Dict{Any, IntervalSetsWrap.Interval}()
    
    for atom in atoms
        @assert atom isa Atom
        cond = SoleLogics.value(atom)
        @assert cond isa AbstractScalarCondition typeof(cond)
        feat = SoleData.feature(cond)
        interval = tointervalset(cond)
        by_var[feat] = if haskey(by_var, feat)
            # Update borders
            if polarity
                by_var[feat] ∩ interval
            else
                by_var[feat] ∪ interval
            end
        else
            interval
        end
    end
    return by_var
end


function collect_thresholds(all_intervals)
    thresholds = Set{Number}()
    for intervals in all_intervals
        for interval in values(intervals)
            push!(thresholds, infimum(interval))
            push!(thresholds, supremum(interval))
        end
    end
    return sort(collect(thresholds))
end

mutable struct IntervalType
    left_closed::Bool
    full::Bool
    right_closed::Bool
end

function compute_segmenttypes(interval, thresholds)
    (minv, mini, maxv, maxi) = infimum(interval), !isleftopen(interval), supremum(interval), !isrightopen(interval)
    nseg = length(thresholds) - 1

    isnonempty = [begin
        t0 = thresholds[i]
        t1 = thresholds[i+1]
        if maxv <= t0 || minv >= t1
            false
        else
            true
        end
    end for i in 1:nseg]

    # Default all non-empty segmenttypes to be closed
    segmenttypes = map(i-> IntervalType(i, i, i), isnonempty)
    first_idx = findfirst(identity, isnonempty)
    last_idx  = findlast(identity, isnonempty)
    if !mini && first_idx !== nothing
        segmenttypes[first_idx].left_closed = false
    end
    if !maxi && last_idx !== nothing
        segmenttypes[last_idx].right_closed = false
    end
    return segmenttypes, first_idx, last_idx
end

function draw_bar(segmenttypes, first_idx, last_idx; colwidth=5, body_char = "=")
    
    segments_str = fill(" " ^ colwidth, length(segmenttypes))

    for i in 1:length(segmenttypes)
        if segmenttypes[i].full
            segments_str[i] = body_char ^ colwidth
        end
    end

    if !isnothing(first_idx)
        segments_str[first_idx] = let x = collect(segments_str[first_idx])
            x[1] = (segmenttypes[first_idx].left_closed ? '[' : '(')
            String(x)
        end
    end
    if !isnothing(last_idx)
        segments_str[last_idx] = let x = collect(segments_str[last_idx])
            x[colwidth] = (segmenttypes[last_idx].right_closed ? ']' : ')')
            String(x)
        end
    end

    return  " " ^ colwidth * join(segments_str)
end


show_scalardnf(f::DNF; kwargs...) = show_scalardnf(stdout, f; kwargs...)

"""
Produce a graphical representation for a scalar DNF formula.

- `show_all_variables::Bool = false`: whether to force the printing of always-true variable constraints (e.g., \$-∞ <= V1 <= ∞\$)
- `print_disjunct_nrs::Bool = false`: whether to print the progressive number for each disjunct
- `palette::Vector`
"""
function show_scalardnf(
    io::IO,
    formula::DNF;
    show_all_variables=false,
    print_disjunct_nrs=false,
    palette=[:cyan, :green, :yellow, :magenta, :blue],
    colwidth=5,
    body_char='=', # alternatives: ■, ━
)
    @assert colwidth >= 5
    formula = normalize(formula)
    disjs = SoleLogics.disjuncts(formula)
    all_intervals = [extract_intervals(d) for d in disjs]
    # Gather all variables
    all_vars = Set{Any}()
    for intervals in all_intervals, v in keys(intervals)
        push!(all_vars, v)
    end
    all_vars = sort(collect(all_vars))
    all_thresholds = collect_thresholds(all_intervals)

    # Maximum length for variable names
    namewidth = maximum(length(syntaxstring(v)) for v in all_vars)

    # header
    header = " " ^ (3+colwidth+namewidth)
    for t in all_thresholds
        header *= @sprintf("%-*.*f", colwidth, 2, t)
    end
    println(io, header)
    println(io)

    # Variable-color mapping
    colors = Dict()
    var_colors = Dict{Any,Symbol}()
    for (i, v) in enumerate(all_vars)
        var_colors[v] = get(colors, v, palette[(i-1) % length(palette) + 1])
    end

    # For each disjunct, produce a set of colored bars
    for (i, (d, intervals)) in enumerate(zip(disjs, all_intervals))
        print_disjunct_nrs && println(io, "Disjunct $i: ", syntaxstring(normalize(d)))
        for v in all_vars
            if !haskey(intervals, v)
                if show_all_variables
                    interval = IntervalSetsWrap.Interval(-Inf .. Inf)
                else
                    continue
                end
            else
                interval = intervals[v]
            end

            # Variable is in disjunct
            if interval == IntervalSetsWrap.Interval(-Inf .. Inf) && !show_all_variables
                # Avoid showing all variables
                continue
            end

            segmenttypes, first_idx, last_idx = compute_segmenttypes(interval, all_thresholds)

            bar = draw_bar(segmenttypes, first_idx, last_idx; colwidth, body_char)
            # colore
            color = var_colors[v]
            # stampo nome e barre
            print(io, "  ")
            printstyled(io, rpad(syntaxstring(v), namewidth), " : ", bar, color=color)
            println(io)
        end
        println(io)
    end
end

