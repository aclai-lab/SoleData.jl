export show_scalardnf

using Printf: @sprintf
using SoleData: AbstractScalarCondition

function extract_ranges(conjunction::LeftmostConjunctiveForm)
    by_var = Dict{Any, Tuple{Float64,Bool,Float64,Bool}}()
    for atom in SoleLogics.conjuncts(conjunction)
        @assert atom isa Atom
        cond = SoleLogics.value(atom)
        @assert cond isa AbstractScalarCondition typeof(cond)
        feat = SoleData.feature(cond)
        minv = isnothing(SoleData.minval(cond)) ? -Inf : SoleData.minval(cond)
        maxv = isnothing(SoleData.maxval(cond)) ? Inf : SoleData.maxval(cond)
        mini = SoleData.minincluded(cond)
        maxi = SoleData.maxincluded(cond)
        if haskey(by_var, feat)
            # Intersezione: aggiorna i bordi
            (curmin, curmini, curmax, curmaxi) = by_var[feat]
            # aggiorna min
            if minv > curmin
                curmin = minv
                curmini = mini
            elseif minv == curmin
                curmini = curmini && mini
            end
            # aggiorna max
            if maxv < curmax
                curmax = maxv
                curmaxi = maxi
            elseif maxv == curmax
                curmaxi = curmaxi && maxi
            end
            by_var[feat] = (curmin, curmini, curmax, curmaxi)
        else
            by_var[feat] = (minv, mini, maxv, maxi)
        end
    end
    return by_var
end


function collect_thresholds(all_ranges)
    thresholds = Set{Float64}()
    for ranges in all_ranges
        for (_, (minv, _mini, maxv, _maxi)) in pairs(ranges)
            push!(thresholds, minv)
            push!(thresholds, maxv)
        end
    end
    return sort(collect(thresholds))
end

function draw_bar(minv, mini, maxv, maxi, thresholds; colwidth=5, body_char = "-")
  nseg = length(thresholds) - 1
  segments = fill(" " ^ colwidth, nseg)

  for i = 1:nseg
      t0 = thresholds[i]
      t1 = thresholds[i+1]
      if maxv <= t0 || minv >= t1
          continue
      else
          segments[i] = body_char ^ colwidth
      end
  end

  first_idx = findfirst(s -> occursin(body_char, s), segments)
  last_idx  = findlast(s -> occursin(body_char, s), segments)

  if first_idx !== nothing
      segments[first_idx] = let x = collect(segments[first_idx])
          x[1] = (mini ? '[' : '(')
          String(x)
      end
  end
  if last_idx !== nothing
      segments[last_idx] = let x = collect(segments[last_idx])
          x[colwidth] = (maxi ? ']' : ')')
          String(x)
      end
  end

  return  " " ^ colwidth * join(segments)
end


show_scalardnf(f::DNF; kwargs...) = show_scalardnf(stdout, f; kwargs...)

function show_scalardnf(
  io::IO,
  formula::DNF;
  show_unbounded=true,
  colwidth=5,
  body_char='=', # alternatives: ■, ━
  print_disjuncts=false,
  palette=[:cyan, :green, :yellow, :magenta, :blue]
)
  @assert colwidth >= 5
  formula = normalize(formula)
  disjs = SoleLogics.disjuncts(formula)
  all_ranges = [extract_ranges(d) for d in disjs]

  # raccogli tutte le variabili
  all_vars = Set{Any}()
  for ranges in all_ranges, v in keys(ranges)
      push!(all_vars, v)
  end
  all_vars = sort(collect(all_vars))
  thresholds = collect_thresholds(all_ranges)

  # calcola larghezza massima nome variabile
  namewidth = maximum(length(syntaxstring(v)) for v in all_vars)

  # header
  header = " " ^ (3+colwidth+namewidth)
  for t in thresholds
      header *= @sprintf("%-*.*f", colwidth, 2, t)
  end
  println(io, header)
  println(io)

  # mappa variabili -> colori
  colors=Dict(),
  var_colors = Dict{Any,Symbol}()
  for (i, v) in enumerate(all_vars)
      var_colors[v] = get(colors, v, palette[(i-1) % length(palette) + 1])
  end

  for (i, (d, ranges)) in enumerate(zip(disjs, all_ranges))
      print_disjuncts && println(io, "Disjunct $i: ", syntaxstring(normalize(d)))
      for v in all_vars
          if haskey(ranges, v)
              (minv, mini, maxv, maxi) = ranges[v]
          elseif show_unbounded
              minv, mini, maxv, maxi = (-Inf, true, +Inf, true)
          else
              continue
          end
          bar = draw_bar(minv, mini, maxv, maxi, thresholds; colwidth, body_char)
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
