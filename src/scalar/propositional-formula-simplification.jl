using SoleLogics: Atom, Formula, SyntaxLeaf, NamedConnective
using SoleLogics: CONJUNCTION
using SoleLogics: atoms, disjuncts, conjuncts, connective, grandchildren
using SoleLogics: value, ispos, dual, hasdual

using SoleData
using SoleData: ScalarCondition, RangeScalarCondition
using SoleData: feature, test_operator, threshold, polarity, isstrict
using SoleData: minval, maxval, minincluded, maxincluded
using SoleData: _rangescalarcond_to_scalarconds_in_conjunction

# ---------------------------------------------------------------------------- #
#                         scalar simplification utils                          #
# ---------------------------------------------------------------------------- #
_isless(::T, ::T) where {T} = false
_isless(::typeof(<), ::typeof(≤)) = true
_isless(::typeof(≤), ::typeof(<)) = false
_isless(::typeof(>), ::typeof(≥)) = false
_isless(::typeof(≥), ::typeof(>)) = true

_isless(::typeof(<), ::typeof(>)) = false
_isless(::typeof(>), ::typeof(<)) = false
_isless(::typeof(≥), ::typeof(≥)) = false
_isless(::typeof(≤), ::typeof(≤)) = false

# ---------------------------------------------------------------------------- #
#                             update mixmax domain                             #
# ---------------------------------------------------------------------------- #
function mixmax_domain(min_domain, max_domain, cond, conn_polarity)
    @assert !SoleData.isordered(test_operator) "Unexpected test operator: $(test_operator)."

    this_domain = (test_operator(cond), threshold(cond))
    p = polarity(test_operator(cond))

    isnothing(p) && throw(
        ArgumentError(
            "Cannot simplify scalar formula with test operator = $(test_operator(cond))"
        ),
    )

    if !p && (
        (
            isless(this_domain[2], max_domain[2]) ||
            (==(this_domain[2], max_domain[2]) && _isless(this_domain[1], max_domain[1]))
        ) == conn_polarity
    )
        max_domain = this_domain
    end

    if p && (
        (
            !(isless(this_domain[2], min_domain[2])) ||
            (==(this_domain[2], min_domain[2]) && _isless(this_domain[1], min_domain[1]))
        ) == conn_polarity
    )
        min_domain = this_domain
    end

    return min_domain, max_domain
end

# ---------------------------------------------------------------------------- #
#                            scalar simplification                             #
# ---------------------------------------------------------------------------- #
function scalar_simplification(φ::Formula; silent=false, kwargs...)
    !silent && @warn "Could not perform scalar simplification on formula of type " *
        " $(typeof(φ))."
    φ
end

function scalar_simplification(φ::SyntaxLeaf; silent=false, kwargs...)
    φ
end

function scalar_simplification(φ::DNF; kwargs...)
    LeftmostDisjunctiveForm(map(d->scalar_simplification(d; kwargs...), disjuncts(φ)))
end

function scalar_simplification(φ::CNF; kwargs...)
    LeftmostConjunctiveForm(map(d->scalar_simplification(d; kwargs...), conjuncts(φ)))
end

function scalar_simplification(
    φ::Union{LeftmostConjunctiveForm,LeftmostDisjunctiveForm}; kwargs...
)
    φ = LeftmostLinearForm(
        connective(φ), map(ch->begin
            if ch isa Atom
                ch
            elseif ch isa Literal
                if ispos(ch)
                    atom(ch)
                elseif hasdual(atom(ch))
                    dual(atom(ch))
                else
                    ch
                end
            else
                ch
            end
        end, grandchildren(φ))
    )

    if !all(c->c isa Atom{<:Union{ScalarCondition,RangeScalarCondition}}, grandchildren(φ))
        return φ
    end

    scalar_simplification(atoms(φ), connective(φ); kwargs...)
end

function scalar_simplification(
    atomslist::Vector{Atom}, conn::NamedConnective; allow_scalar_range_conditions::Bool=false
)
    scalar_conds = value.(atomslist)
    feats = feature.(scalar_conds)

    feature_groups = [(f, map(x->x==f, feats)) for f in unique(feats)]

    conn_polarity = (conn == CONJUNCTION)

    ch = collect(
        Iterators.flatten([
            begin
                conds = scalar_conds[bitmask]

                min_domain = (≥, Real(-Inf))
                max_domain = (≤, Real(Inf))
                T = eltype(threshold.(conds))

                for cond in conds
                    cond isa ScalarCondition &&
                        (test_operator(cond) == (==)) &&
                        begin
                            cond = RangeScalarCondition(
                                feature(cond),
                                minval(cond),
                                maxval(cond),
                                SoleData.minincluded(cond),
                                SoleData.maxincluded(cond),
                            )
                        end

                    min_domain, max_domain = if cond isa RangeScalarCondition
                        if conn_polarity
                            begin
                                rconds = _rangescalarcond_to_scalarconds_in_conjunction(cond)
                                rminmax = [
                                    mixmax_domain(min_domain, max_domain, c, conn_polarity) for c in rconds
                                ]
                                min_domain, max_domain = last(last(rminmax)),
                                first(first(rminmax))
                            end
                        else
                            error(
                                "Cannot convert RangeScalarCondition to ScalarCondition: $(cond).",
                            )
                        end
                    else
                        min_domain, max_domain = mixmax_domain(
                            min_domain, max_domain, cond, conn_polarity
                        )
                    end
                end

                out = Atom[]

                if !(max_domain[2] == Inf) &&
                    !(min_domain[2] == -Inf) &&
                    (max_domain[2] < min_domain[2]) # TODO make it more finegrained so that it captures cases with < and >=
                    nothing
                elseif (min_domain[2] == -Inf) && (max_domain[2] == Inf)
                    nothing
                else
                    if allow_scalar_range_conditions
                        min_domain = (min_domain[2] == -Inf) ? (≥, -Inf) : min_domain
                        max_domain = (max_domain[2] == Inf) ? (≤, Inf) : max_domain

                        minincluded = (!isstrict(min_domain[1])) || (min_domain[2] == -Inf)
                        maxincluded =
                            (!SoleData.isstrict(max_domain[1])) || (max_domain[2] == Inf)

                        push!(
                            out,
                            Atom(
                                RangeScalarCondition(
                                    feat,
                                    min_domain[2],
                                    max_domain[2],
                                    minincluded,
                                    maxincluded,
                                ),
                            ),
                        )
                    else
                        if !(min_domain[2] == -Inf)
                            push!(
                                out,
                                Atom(ScalarCondition(feat, min_domain[1], min_domain[2])),
                            )
                        end
                        if !(max_domain[2] == Inf)
                            push!(
                                out,
                                Atom(ScalarCondition(feat, max_domain[1], max_domain[2])),
                            )
                        end
                    end
                end

                out
            end for (feat, bitmask) in feature_groups
        ]),
    )

    return (
        length(ch) == 0 ? (⊤) : (length(ch) == 1 ? first(ch) : LeftmostLinearForm(conn, ch))
    )
end

scalar_simplification(a::Atom; kwargs...) = a
