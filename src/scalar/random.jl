import Base: rand
using SoleLogics

# Author: @Michele21
# """
#     Base.rand(
#         rng::AbstractRNG,
#         a::UnionAlphabet{ScalarCondition,<:UnivariateScalarAlphabet};
#         metaconditions::Union{Nothing,ScalarMetaCondition,AbstractVector{<:ScalarMetaCondition}} = nothing,
#         feature::Union{Nothing,AbstractFeature,AbstractVector{<:AbstractFeature}} = nothing,
#         test_operator::Union{Nothing,TestOperator,AbstractVector{<:TestOperator}} = nothing,
#     )::Atom

# Randomly sample an `Atom` holding a `ScalarCondition` from scalar alphabet `a`,
# such that:
# - if `metaconditions` are specified, then the set of metaconditions (feature-operator pairs)
# is limited to `metaconditions`;
# - if `feature` is specified, then the set of metaconditions (feature-operator pairs)
# is limited to those with `feature`;
# - if `test_operator` is specified, then the set of metaconditions (feature-operator pairs)
# is limited to those with `test_operator`.

# See also
# [`UnionAlphabet`](@ref),
# [`UnivariateScalarAlphabet`](@ref),
# [`ScalarCondition`](@ref),
# [`ScalarMetaCondition`](@ref).
# """
function Base.rand(
    rng::AbstractRNG,
    a::UnionAlphabet{ScalarCondition,<:UnivariateScalarAlphabet};
    metaconditions::Union{Nothing,ScalarMetaCondition,AbstractVector{<:ScalarMetaCondition}} = nothing,
    features::Union{Nothing,AbstractFeature,AbstractVector{<:AbstractFeature}} = nothing,
    test_operators::Union{Nothing,TestOperator,AbstractVector{<:TestOperator}} = nothing,
)::Atom
    @warn "TODO this function is untested."
    
    # Transform values to singletons
    metaconditions = metaconditions isa ScalarMetaCondition ? [metaconditions] : metaconditions
    features = features isa AbstractFeature ? [features] : features
    test_operators = test_operators isa TestOperator ? [test_operators] : test_operators

    @assert !(!isnothing(metaconditions) &&
        (!isnothing(features) || !isnothing(test_operators))) "" *
            "Ambiguous output, there are more choices; only one metacondition, one " *
            "feature or one operator must be specified\n Now: \n" *
            "metaconditions: $(metaconditions)\n" *
            "feature: $(feature)\n" *
            "test operator: $(test_operator)\n"

    grouped_featconditions = map(sa -> sa.featcondition, subalphabets(a))

    filtered_featconds = begin
        if !isnothing(metaconditions)
            filtered_featconds = filter(mc_thresholds->first(mc_thresholds) in [metaconditions..., dual.(metaconditions)...], grouped_featconditions)
            @assert length(filtered_featconds) == length(metaconditions) "" *
                "There is at least one metacondition passed that is not among the " *
                "possible ones\n metaconditions: $(metaconditions)\n filtered " *
                "metaconditions: $(filtered_featconds)\n" *
                "grouped_featconditions: $(map(first,grouped_featconditions))"
            filtered_featconds
        elseif !isnothing(features) || !isnothing(test_operators)
            filtered_featconds = filter(mc_thresholds->begin
                mc = first(mc_thresholds)
                return (isnothing(features) || feature(mc) in features) &&
                    (isnothing(test_operators) || test_operator(mc) in test_operators)
            end, grouped_featconditions)
            # TODO check with alphabet
            #=@assert length(filtered_featconds) == length(metaconditions) "" *
                "There is at least one metacondition passed that is not among the " *
                "possible ones\n metaconditions: $(metaconditions)\n filtered " *
                "metaconditions: $(filtered_featconds)" *
                "grouped_featconditions: $(map(first,grouped_featconditions))" =#
            filtered_featconds
        else
            grouped_featconditions
        end
    end

    mc_thresholds = rand(rng, filtered_featconds)

    return Atom(ScalarCondition(first(mc_thresholds), rand(rng, last(mc_thresholds))))
end
