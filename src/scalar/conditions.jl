import SoleLogics: randatom
############################################################################################

const DEFAULT_SCALARCOND_FEATTYPE = SoleData.VarFeature

# TODO ScalarMetaCondition is more like... an Alphabet, than a Condition.
"""
    struct ScalarMetaCondition{FT<:AbstractFeature,O<:TestOperator} <: AbstractCondition{FT}
        feature::FT
        test_operator::O
    end

A metacondition representing a scalar comparison method.
Here, the `feature` is a scalar function that can be computed on a world
of an instance of a logical dataset.
A test operator is a binary mathematical relation, comparing the computed feature value
and an external threshold value (see `ScalarCondition`). A metacondition can also be used
for representing the infinite set of conditions that arise with a free threshold
(see `UnboundedScalarAlphabet`): \${min[V1] ≥ a, a ∈ ℝ}\$.

See also
[`AbstractCondition`](@ref),
[`ScalarCondition`](@ref).
"""
struct ScalarMetaCondition{FT<:AbstractFeature,O<:TestOperator} <: AbstractCondition{FT}

    # Feature: a scalar function that can be computed on a world
    feature::FT

    # Test operator (e.g. ≥)
    test_operator::O

end

# TODO
# featuretype(::Type{<:ScalarMetaCondition{FT}}) where {FT<:AbstractFeature} = FT
# featuretype(m::ScalarMetaCondition) = featuretype(typeof(FT))

feature(m::ScalarMetaCondition) = m.feature
test_operator(m::ScalarMetaCondition) = m.test_operator

hasdual(::ScalarMetaCondition) = true
dual(m::ScalarMetaCondition) = ScalarMetaCondition(feature(m), inverse_test_operator(test_operator(m)))

syntaxstring(m::ScalarMetaCondition; kwargs...) =
    "$(_syntaxstring_metacondition(m; kwargs...)) ⍰"

function _syntaxstring_metacondition(
    m::ScalarMetaCondition;
    use_feature_abbreviations::Bool = false,
    kwargs...,
)
    if use_feature_abbreviations
        _st_featop_abbr(feature(m), test_operator(m); kwargs...)
    else
        _st_featop_name(feature(m), test_operator(m); kwargs...)
    end
end

_st_featop_name(feature::AbstractFeature,   test_operator::TestOperator; kwargs...)     = "$(syntaxstring(feature; kwargs...)) $(_st_testop_name(test_operator))"

_st_testop_name(test_op::Any) = "$(test_op)"
_st_testop_name(::typeof(>=)) = "≥"
_st_testop_name(::typeof(<=)) = "≤"

# Abbreviations

_st_featop_abbr(feature::AbstractFeature,   test_operator::TestOperator; kwargs...)     = _st_featop_name(feature, test_operator; kwargs...)

############################################################################################

function groupbyfeature(
    metaconditions::AbstractVector{<:ScalarMetaCondition},
    features::Union{Nothing,AbstractVector{<:AbstractFeature}} = nothing,
)
    if isnothing(features)
        features = unique(feature.(metaconditions))
    end
    groups = map(_feature->begin
        these_metaconds = filter(m->feature(m) == _feature, metaconditions)
        # these_testops = unique(test_operator.(these_metaconds))
        (_feature, these_metaconds)
    end, features)
    all_matched_metaconds = unique(vcat(last.(groups)...))
    unmatched_metaconds = filter(m->!(m in all_matched_metaconds), metaconditions)
    if length(unmatched_metaconds) != 0
        if length(unmatched_metaconds) == length(metaconditions)
            error("Could not find features for any of the $(length(metaconditions)) " *
                "metaconditions: $(metaconditions). Features: $(features).")
        end
        @warn "Could not find features for $(length(unmatched_metaconds)) " *
            "metaconditions: $(unmatched_metaconds)."
    end
    return groups
end

############################################################################################

"""
    struct ScalarCondition{U,FT,M<:ScalarMetaCondition{FT}} <: AbstractCondition{FT}
        metacond::M
        a::U
    end

A scalar condition comparing a computed feature value (see `ScalarMetaCondition`)
and a threshold value `a`.
It can be evaluated on a world of an instance of a logical dataset.

For example: \$min[V1] ≥ 10\$, which translates to
"Within this world, the minimum of variable 1 is greater or equal than 10."
In this case, the feature a [`UnivariateMin`](@ref) object.

See also
[`AbstractCondition`](@ref),
[`ScalarMetaCondition`](@ref).
"""
struct ScalarCondition{U,FT,M<:ScalarMetaCondition{FT}} <: AbstractCondition{FT}

  # Metacondition
  metacond::M

  # Threshold value
  threshold::U

  function ScalarCondition(
      metacond       :: M,
      threshold      :: U
  ) where {FT<:AbstractFeature,M<:ScalarMetaCondition{FT},U}
      new{U,FT,M}(metacond, threshold)
  end

  function ScalarCondition(
      condition      :: ScalarCondition{U,M},
      threshold      :: U
  ) where {FT<:AbstractFeature,M<:ScalarMetaCondition{FT},U}
      new{U,FT,M}(metacond(condition), threshold)
  end

  function ScalarCondition(
      feature       :: AbstractFeature,
      test_operator :: TestOperator,
      threshold     :: U
  ) where {U}
      metacond = ScalarMetaCondition(feature, test_operator)
      ScalarCondition(metacond, threshold)
  end
end

metacond(c::ScalarCondition) = c.metacond
threshold(c::ScalarCondition) = c.threshold

feature(c::ScalarCondition) = feature(metacond(c))
test_operator(c::ScalarCondition) = test_operator(metacond(c))

hasdual(::ScalarCondition) = true
dual(c::ScalarCondition) = ScalarCondition(dual(metacond(c)), threshold(c))

function checkcondition(c::ScalarCondition, args...; kwargs...)
    apply_test_operator(test_operator(c), featvalue(feature(c), args...; kwargs...), threshold(c))
end

function syntaxstring(
    m::ScalarCondition;
    threshold_digits::Union{Nothing,Integer} = nothing,
    threshold_display_method::Union{Nothing,Base.Callable} = nothing,
    kwargs...
)
    if (!isnothing(threshold_digits) && !isnothing(threshold_display_method))
        @warn "Prioritizing threshold_display_method parameter over threshold_digits " *
            "in syntaxstring for `ScalarCondition`."
    end
    threshold_display_method = begin
        if !isnothing(threshold_display_method)
            threshold_display_method
        elseif !isnothing(threshold_digits)
            x->round(x; digits=threshold_digits)
        else
            identity
        end
    end
    string(_syntaxstring_metacondition(metacond(m); kwargs...)) * " " *
    string(threshold_display_method(threshold(m)))
end

function parsecondition(
    ::Type{ScalarCondition},
    expr::String;
    featuretype::Union{Nothing,Type} = nothing,
    featvaltype::Union{Nothing,Type} = nothing,
    kwargs...
)
    if isnothing(featvaltype)
        featvaltype = DEFAULT_VARFEATVALTYPE
        @warn "Please, specify a type for the feature values (featvaltype = ...). " *
            "$(featvaltype) will be used, but note that this may raise type errors. " *
            "(expr = $(repr(expr)))"
    end
    if isnothing(featuretype)
        featuretype = DEFAULT_SCALARCOND_FEATTYPE
        @warn "Please, specify a feature type (featuretype = ...). " *
            "$(featuretype) will be used. " *
            "(expr = $(repr(expr)))"
    end
    _parsecondition(ScalarCondition{featvaltype,featuretype}, expr; kwargs...)
end

function parsecondition(
    ::Type{C},
    expr::String;
    featuretype::Union{Nothing,Type} = nothing,
    kwargs...
) where {U,C<:ScalarCondition{U}}
    if isnothing(featuretype)
        featuretype = DEFAULT_SCALARCOND_FEATTYPE
        @warn "Please, specify a feature type (featuretype = ...). " *
            "$(featuretype) will be used. " *
            "(expr = $(repr(expr)))"
    end
    _parsecondition(C{featuretype}, expr; kwargs...)
end

function parsecondition(
    ::Type{C},
    expr::String;
    featuretype::Union{Nothing,Type} = nothing,
    kwargs...
) where {U,FT,C<:ScalarCondition{U,FT}}
    @assert isnothing(featuretype) || featuretype == FT "Cannot parse condition of type $(C) with " *
        "featuretype = $(featuretype). (expr = $(repr(expr)))"
    _parsecondition(C, expr; kwargs...)
end

function _parsecondition(
    ::Type{C},
    expr::String;
    kwargs...
) where {U,FT,C<:ScalarCondition{U,FT}}
    r = Regex("^\\s*(\\S+)\\s+([^\\s\\d]+)\\s*(\\S+)\\s*\$")
    slices = match(r, expr)

    @assert !isnothing(slices) && length(slices) == 3 "Could not parse ScalarCondition from " *
        "expression $(repr(expr))."

    slices = string.(slices)

    feature = parsefeature(FT, slices[1]; featvaltype = U, kwargs...)
    test_operator = eval(Meta.parse(slices[2]))
    threshold = eval(Meta.parse(slices[3]))

    condition = ScalarCondition(feature, test_operator, threshold)
    # if !(condition isa C)
    #     @warn "Could not parse expression $(repr(expr)) as condition of type $(C); " *
    #         " $(typeof(condition)) was used."
    # end
    condition
end

############################################################################################
############################################################################################
############################################################################################

# TODO remove in favor of UnionAlphabet{UnboundedUnivariateScalarAlphabet}
# """
#     struct UnboundedScalarAlphabet{C<:ScalarCondition} <: AbstractAlphabet{C}
#         metaconditions::Vector{<:ScalarMetaCondition}
#     end

# An infinite alphabet of conditions induced from a finite set of metaconditions.
# For example, if `metaconditions = [ScalarMetaCondition(UnivariateMin(1), ≥)]`,
# the alphabet represents the (infinite) set: \${min[V1] ≥ a, a ∈ ℝ}\$.

# See also
# [`UnivariateScalarAlphabet`](@ref),
# [`ScalarCondition`](@ref),
# [`ScalarMetaCondition`](@ref).
# """
# struct UnboundedScalarAlphabet{C<:ScalarCondition} <: AbstractAlphabet{C}
#     metaconditions::Vector{<:ScalarMetaCondition}

#     function UnboundedScalarAlphabet{C}(
#         metaconditions::Vector{<:ScalarMetaCondition}
#     ) where {C<:ScalarCondition}
#         new{C}(metaconditions)
#     end

#     function UnboundedScalarAlphabet(
#         features       :: AbstractVector{C},
#         test_operators :: AbstractVector,
#     ) where {C<:ScalarCondition}
#         metaconditions =
#             [ScalarMetaCondition(f, t) for f in features for t in test_operators]
#         UnboundedScalarAlphabet{C}(metaconditions)
#     end
# end

# Base.isfinite(::Type{<:UnboundedScalarAlphabet}) = false

# function Base.in(p::Atom{<:ScalarCondition}, a::UnboundedScalarAlphabet)
#     fc = SoleLogics.value(p)
#     idx = findfirst(mc->mc == metacond(fc), a.metaconditions)
#     return !isnothing(idx)
# end

############################################################################################
############################################################################################
############################################################################################

"""
    struct UnivariateScalarAlphabet <: AbstractAlphabet{ScalarCondition}
        featcondition::Vector{UnivariateScalarAlphabet}
    end

A finite alphabet of conditions, grouped by (a finite set of) metaconditions.

See also
[`UnboundedScalarAlphabet`](@ref),
[`ScalarCondition`](@ref),
[`ScalarMetaCondition`](@ref).
"""
struct UnivariateScalarAlphabet <: AbstractAlphabet{ScalarCondition}
    featcondition::Tuple{ScalarMetaCondition,Vector}
end

function atoms(c::UnivariateScalarAlphabet)
    mc, thresholds = c.featcondition
    return Iterators.map(threshold -> Atom(ScalarCondition(mc, threshold)), thresholds)
end

metacond(c::UnivariateScalarAlphabet)   = c.featcondition[1]
thresholds(c::UnivariateScalarAlphabet) = c.featcondition[2]

feature(c::UnivariateScalarAlphabet)        = feature(metacond(c))
test_operator(c::UnivariateScalarAlphabet)  = test_operator(metacond(c))

natoms(c::UnivariateScalarAlphabet) = length(thresholds(c))

function Base.show(io::IO, c::UnivariateScalarAlphabet)
    mc, thresholds = c.featcondition
    println(io, "\t$(syntaxstring(mc)) ⇒ $(thresholds)")
end

# Optimized lookup for alphabet union
function Base.in(p::Atom{<:ScalarCondition}, a::UnionAlphabet{ScalarCondition,<:UnivariateScalarAlphabet})
    fc = SoleLogics.value(p)
    chas = alphabets(a)
    idx = findfirst((chas) -> chas.featcondition[1] == metacond(fc), chas)
    return !isnothing(idx) && Base.in(threshold(fc), chas[idx].featcondition[2])
end

function randatom(
    rng::AbstractRNG,
    a::UnivariateScalarAlphabet
)::Atom
    (mc, thresholds) = a.featcondition
    threshold = rand(rng, thresholds)
    return Atom(ScalarCondition(mc, threshold))
end

############################################################################################

using LinearAlgebra

"""
    ObliqueScalarCondition(features, b, u, test_operator)

An oblique scalar condition (see *oblique decision trees*),
such as \$((features - b) ⋅ u) ≥ 0\$, where `features` is
a set of \$m\$ features, and \$b,u ∈ ℝ^m\$.

See also
[`AbstractCondition`](@ref),
[`ScalarCondition`](@ref).
"""
struct ObliqueScalarCondition{FT<:AbstractFeature,O<:TestOperator} <: AbstractCondition{FT}

    # Feature: a scalar function that can be computed on a world
    features::Vector{<:FT}
    b::Vector{<:Real}
    u::Vector{<:Real}

    # Test operator (e.g. ≥)
    test_operator::O

end

test_operator(m::ObliqueScalarCondition) = m.test_operator

hasdual(::ObliqueScalarCondition) = true
dual(c::ObliqueScalarCondition) = ObliqueScalarCondition(c.features, c.b, c.u, inverse_test_operator(test_operator(c)))

syntaxstring(c::ObliqueScalarCondition; kwargs...) = "($(syntaxstring.(c.features)) - [$(join(", ", c.b))]) * [$(join(", ", c.u))] ⋈ 0"

function checkcondition(c::ObliqueScalarCondition, args...; kwargs...)
    f = [featvalue(f, args...; kwargs...) for f in c.features]
    val = LinearAlgebra.dot((f .- c.b), c.u)
    apply_test_operator(test_operator(c), val, 0)
end