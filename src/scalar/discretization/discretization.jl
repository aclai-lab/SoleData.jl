using Discretizers

"""
    function discretizedomain(
        X::Vector{<:Real},
        metacondition::Vector{<:AbstractCondition},
        discretizer::Vector{<:DiscretizationAlgorithm};
        cutextrema::Bool=true
    )
    function discretizedomain(
        X::Vector{<:Vector{<:Real}},
        metacondition::Vector{<:AbstractCondition},
        discretizer::Vector{<:DiscretizationAlgorithm};
        consider_all_subintervals::Bool=false,
        kwargs...
    )

Select an alphabet, that is, a set of [`Item`](@ref)s wrapping `SoleData.AbstractCondition`.

# Arguments
- `X::Vector{<:Vector{<:Real}}`: dataset column containing real numbers or real vectors;
- `metacondition::Vector{<:AbstractCondition}`: abstract type for representing a condition
    that can be interpreted end evaluated on worlds of logical dataset instances
    (e.g., a generic "max[V1] ≤ ⍰" where "?" is a threshold that has to be defined);
- `discretizer::Vector{<:DiscretizationAlgoritm}`: a strategy to perform binning over
    a distribution.

# Keyword Arguments
- `cutextrema::Bool=true`: remove the extrema obtained by the binning;
- `consider_all_subintervals::Bool=false`: when true, each given vector is cutted in all
    its subintervals; `metacondition` is applied on such intervals, thus obtaining a new
    distribution.

# Examples
```julia
julia> using Discretizers

# an easy dataframe with 20 instances and only one column
julia> X = [rand(10) for i in 1:20]

# to generate an alphabet, we choose a variable (a column of X) and our metacondition
julia> variable = 1
julia> max_metacondition = ScalarMetaCondition(VariableMax(variable), <=)
 ScalarMetaCondition{VariableMax{Integer}, typeof(<=)}: max[V1] ≤ ⍰

# we choose how we want to discretize the distribution of the variable
julia> nbins = 5
# we specify a strategy to perform discretization
julia> discretizer = Discretizers.DiscretizeQuantile(nbins)

# we obtain one alphabet and pretty print it
julia> alphabet1 = discretizedomain(X[:,variable], max_metacondition, discretizer)
julia> syntaxstring.(alphabet1)
4-element Vector{String}:
 "max[V1] ≤ 0.21"
 "max[V1] ≤ 0.41"
 "max[V1] ≤ 0.61"
 "max[V1] ≤ 0.78"

# for each time series in X (or for the only time series X), consider each possible
# interval and apply the feature on it; if you are considering other kind of dimensional
# data (e.g., spatial), adapt the following list comprehension.
julia> max_applied_on_all_intervals = [
        SoleData.computeunivariatefeature(max_metacondition |> SoleData.feature, v[i:j])
        for v in X[:,variable]
        for i in 1:length(v)
        for j in i+1:length(v)
    ]

# now you can call `discretizedomain` with the new preprocessed time series.
julia> alphabet2 = discretizedomain(
    max_applied_on_all_intervals, max_metacondition, discretizer)
julia> syntaxstring.(alphabet2)
4-element Vector{String}:
 "max[V1] ≤ 0.64"
 "max[V1] ≤ 0.74"
 "max[V1] ≤ 0.87"
 "max[V1] ≤ 0.97"

# we can obtain the same result as before by simplying setting `consider_all_subintervals`
julia> alphabet3 = discretizedomain(X[:,variable], max_metacondition, discretizer;
            consider_all_subintervals=true)
julia> syntaxstring.(alphabet3) == syntaxstring.(alphabet2)
true
```

See also `Discretizers.DiscretizationAlgorithm`, [`Item`](@ref),
`SoleData.AbstractCondition`, `SoleData.ScalarMetaCondition`.
"""
function discretizedomain(
    X::Vector{<:Real},
    metacondition::AbstractCondition,
    discretizer::DiscretizationAlgorithm;
    cutextrema::Bool=true # considerations in https://github.com/aclai-lab/SoleData.jl/pull/19
)
    alphabet = Vector{AbstractCondition}()

    # for each strategy, found the edges of each bin
    _binedges = binedges(discretizer, X)

    # extrema bins are removed, if requested and if possible
    if cutextrema
        _binedges_length = length(_binedges)
        if _binedges_length <= 2
            throw(
                ArgumentError("Cannot remove extrema: $(_binedges_length) bins found"))
        else
            popfirst!(_binedges)
            pop!(_binedges)
        end
    end

    # for each metacondition, apply a threshold (a bin edge)

    for threshold in _binedges
        push!(alphabet, ScalarCondition(metacondition, round(threshold, digits=2)))
    end

    return alphabet
end

function discretizedomain(
    X::Vector{<:Vector{<:Real}},
    metacondition::AbstractCondition,
    discretizer::DiscretizationAlgorithm;
    consider_all_subintervals::Bool=false,
    kwargs...
)
    _X = _intervalbased_discretizealphabet(X, metacondition; kwargs...)

    return discretizedomain(_X, metacondition, discretizer; kwargs...)
end

function _intervalbased_discretizealphabet(
    X::Vector{<:Vector{<:Real}}, 
    metacondition::AbstractCondition;
    consider_all_subintervals::Bool=false
)
    if consider_all_subintervals
        _X = [
                SoleData.computeunivariatefeature(metacondition |> SoleData.feature, v[i:j])
                # for each vector, we consider the superior triangular matrix
                for v in X
                for i in 1:length(v)
                for j in i+1:length(v)
            ]
    else
        _X = reduce(vcat, X)
    end
end

"""
    function discretizealphabet(
        a::UnivariateScalarAlphabet,
        discretizer::DiscretizationAlgorithm;
        kwargs...
    )

    function discretizealphabet(
        a::MultivariateScalarAlphabet,
        discretizer::DiscretizationAlgorithm;
        kwargs...
    )

Unpack `a`, then fallback to [`discretizedomain`](@ref).

See also [`discretizedomain`](@ref), [`UnivariateScalarAlphabet`](@ref).
"""
function discretizealphabet(
    a::UnivariateScalarAlphabet,
    discretizer::DiscretizationAlgorithm;
    kwargs...
)
    return discretizedomain(thresholds(a), metacond(a), discretizer; kwargs...)
end


# TODO: could be a cool idea to unpack a MultivariateScalarAlphabet argument
# see https://github.com/aclai-lab/SoleData.jl/pull/19
# function discretizealphabet(
#     a::MultivariateScalarAlphabet,
#     discretizer::DiscretizationAlgorithm;
#     kwargs...
# )
# end
