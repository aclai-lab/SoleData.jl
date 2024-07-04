using SoleLogics
using SoleLogics: Atom
using SoleData:  AbstractFeature, ScalarCondition, VariableValue, LeftmostConjunctiveForm
using SoleData: feature, value, test_operator, threshold, polarity

const SatMask = BitVector

function scalar_simplification(φ::SoleLogics.Formula; silent = false, kwargs...)
    !silent && @warn "Could not perform scalar simplification on formula of type " *
        " $(typeof(φ))."
    φ
end

function scalar_simplification(φ::SoleLogics.SyntaxLeaf; silent = false, kwargs...)
    φ
end

function scalar_simplification(
    φ::Union{LeftmostConjunctiveForm,LeftmostDisjunctiveForm};
    silent = false,
    allow_scalar_range_conditions = true,
    kwargs...,
)
    # @show φ
    # @show typeof.(SoleLogics.children(φ))
    # @show all(c->c isa Atom{<:ScalarCondition}, SoleLogics.children(φ))
    if !all(c->c isa Atom{<:ScalarCondition}, SoleLogics.children(φ))
        !silent && error("Cannot perform scalar simplification on linear form ($(syntaxstring(φ))) on" *
            " $(Union{map(typeof, SoleLogics.children(φ))...}).")
    end

    atomslist = SoleLogics.children(φ)

    scalar_conditions = SoleLogics.value.(atomslist)
    feats = feature.(scalar_conditions)

    feature_groups = [(f, map(x->x==f, feats)) for f in unique(feats)]

    conn_polarity = SoleLogics.connective(φ) == SoleLogics.CONJUNCTION

    mostspecific(cs::AbstractVector{<:Real}, ::typeof(<=)) = findmin(cs)[1]
    mostspecific(cs::AbstractVector{<:Real}, ::typeof(>=)) = findmax(cs)[1]

    # [filter(cond->feature(cond) == feat, scalar_conditions) for feat in unique(feats)]
    # SoleBase._groupby(feature, scalar_conditions)
    # SoleBase._groupby(feature, scalar_conditions, Dict{VariableValue,Vector})

    my_isless(::T, ::T) where T = false
    my_isless(::typeof(<), ::typeof(<=)) = true
    my_isless(::typeof(<=), ::typeof(<)) = false
    my_isless(::typeof(>), ::typeof(>=)) = false
    my_isless(::typeof(>=), ::typeof(>)) = true

    my_isless(::typeof(<), ::typeof(>)) = false
    my_isless(::typeof(>), ::typeof(<)) = false
    my_isless(::typeof(>=), ::typeof(>=)) = false
    my_isless(::typeof(<=), ::typeof(<=)) = false

    ch = collect(Iterators.flatten([begin
            conds = scalar_conditions[bitmask]

            min_domain = nothing
            max_domain = nothing

            for cond in conds
                @assert !SoleData.isordered(test_operator) "Unexpected test operator: $(test_operator)."
                this_domain = (test_operator(cond), threshold(cond))
                if !polarity(test_operator(cond))
                    if isnothing(max_domain) ||
                        (
                            (isless(this_domain[2], max_domain[2]) ||
                                (==(this_domain[2], max_domain[2]) && my_isless(this_domain[1], max_domain[1]))
                                ) == conn_polarity)
                        max_domain = this_domain
                    end
                # end
                # if !polarity(test_operator(cond))
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
            # @show min_domain, max_domain

            if !isnothing(max_domain) && !isnothing(min_domain) && (max_domain[2] < min_domain[2]) # TODO make it more finegrained so that it captures cases with < and >=
                nothing
            else
                if allow_scalar_range_conditions && (!isnothing(min_domain) && !isnothing(max_domain))
                    push!(out, Atom(SoleData.RangeScalarCondition(feat, min_domain[2], max_domain[2], !SoleData.isstrict(min_domain[1]), !SoleData.isstrict(max_domain[1]), )))
                else
                    if !isnothing(min_domain)
                        push!(out, Atom(ScalarCondition(feat, min_domain[1], min_domain[2])))
                    end
                    if !isnothing(max_domain)
                        push!(out, Atom(ScalarCondition(feat, max_domain[1], max_domain[2])))
                    end
                end
            end
            # @show out
            out
            # # thresholds for operator
            # ths_foroperator = Dict{Function,Real}([])
            # for to in TEST_OPS

            #     compatible_sc = [sc for sc in conds if test_operator(sc)==to]
            #     ths = Float64.(threshold.(compatible_sc))
            #     isempty(ths) && break


            #     push!(reduced_conditions, ScalarCondition(feat, to, mostspecific(ths, to)))
            # end
            # if length(reduced_conditions) > 1
            #     (c1, c2) = reduced_conditions
            #     if test_operator(c1)(threshold.(reduceduni_conditions))
            #         push!(reducered_conditions, reduceduni_conditions)
            #     else
            #         return BOT
            #     end
            # else
            #     push!(reducered_conditions, reduceduni_conditions)
            # end
            # # Adesso ho solo il numero minimo di atomi che mi servono a descrivere l' intervallo
            # # per una USC. Devo capire se tale intervallo è ⊤, ⊥, o corrisponde ad un solo valore.
        end for (feat, bitmask) in feature_groups]))

    ψ = (length(ch) == 0 ? (⊤) : (length(ch) == 1 ? first(ch) : LeftmostLinearForm(SoleLogics.connective(φ), ch)))
end
