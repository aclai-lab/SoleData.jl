
using SoleLogics: AbstractAlphabet
using Random
import SoleLogics: hasdual, dual, atoms

import Base: in, isfinite, length

"""
    abstract type AbstractCondition{FT<:AbstractFeature} end

Abstract type for representing conditions that can be interpreted and evaluated
on worlds of instances of a logical dataset. In logical contexts,
these are wrapped into `Atom`s.

See also
[`Atom`](@ref),
[`syntaxstring`](@ref),
[`ScalarMetaCondition`](@ref),
[`ScalarCondition`](@ref).
"""
abstract type AbstractCondition{FT<:AbstractFeature} end

# Check a condition (e.g., on a world of a logiset instance)
function checkcondition(c::AbstractCondition, args...; kwargs...)
    return error("Please, provide method checkcondition(::$(typeof(c)), " *
        join(map(t->"::$(t)", typeof.(args)), ", ") * "; kwargs...). " *
        "Note that this value must be unique.")
end

# function checkcondition(
#     c::AbstractCondition,
#     X::AbstractModalLogiset{W,U,FT},
#     i_instance::Integer,
#     w::W,
# ) where {W<:AbstractWorld,U,FT<:AbstractFeature}
#     error("Please, provide method checkcondition(c::$(typeof(c)), X::$(typeof(X)), i_instance::$(typeof(i_instance)), w::$(typeof(w))).")
# end

function syntaxstring(c::AbstractCondition; kwargs...)
    return error("Please, provide method syntaxstring(::$(typeof(c)); kwargs...). " *
        "Note that this value must be unique.")
end

function Base.show(io::IO, c::AbstractCondition)
    # print(io, "Feature of type $(typeof(c))\n\t-> $(syntaxstring(c))")
    print(io, "$(typeof(c)): $(syntaxstring(c))")
    # print(io, "$(syntaxstring(c))")
end

# # This makes sure that, say, a Float64 min[V1] is equal to a Float32 min[V1]
# # Useful, but not exactly correct
# Base.isequal(a::AbstractCondition, b::AbstractCondition) = syntaxstring(a) == syntaxstring(b) # nameof(x) == nameof(feature)
# Base.hash(a::AbstractCondition) = Base.hash(syntaxstring(a))
# TODO remove
Base.isequal(a::AbstractCondition, b::AbstractCondition) = Base.isequal(map(x->getfield(a, x), fieldnames(typeof(a))), map(x->getfield(b, x), fieldnames(typeof(b))))
Base.hash(a::AbstractCondition) = Base.hash(map(x->getfield(a, x), fieldnames(typeof(a))), Base.hash(typeof(a)))

"""
    parsecondition(C::Type{<:AbstractCondition}, expr::String; kwargs...)

Parse a condition of type `C` from its [`syntaxstring`](@ref) representation.
Depending on `C`, specifying
keyword arguments such as `featuretype::Type{<:AbstractFeature}`,
and `featvaltype::Type` may be required or recommended.

See also [`parsefeature`](@ref).
"""
function parsecondition(
    C::Type{<:AbstractCondition},
    expr::String;
    kwargs...
)
    return error("Please, provide method parsecondition(::$(Type{C}), expr::$(typeof(expr)); kwargs...).")
end

############################################################################################

"""
    struct ValueCondition{FT<:AbstractFeature} <: AbstractCondition{FT}
        feature::FT
    end

A condition which yields a truth value equal to the value of a feature.

See also [`AbstractFeature`](@ref).
"""
struct ValueCondition{FT<:AbstractFeature} <: AbstractCondition{FT}
    feature::FT
end

checkcondition(c::ValueCondition, args...; kwargs...) = featvalue(c.feature, args...; kwargs...)

syntaxstring(c::ValueCondition; kwargs...) = syntaxstring(c.feature)

function parsecondition(
    ::Type{ValueCondition},
    expr::String;
    featuretype = Feature,
    kwargs...
)
    ValueCondition(featuretype(expr))
end

############################################################################################

# TODO remove and harmonize
function featvalue(
    feature::AbstractFeature,
    X,
    i_instance::Integer,
    w::W,
) where {W<:AbstractWorld}
    featvalue(X, i_instance, w, feature)
end

function featvalue(
    feature::AbstractFeature,
    X::AbstractLogiset,
    i_instance::Integer,
    args...
) where {W<:AbstractWorld}
    featvalue(X, i_instance, feature, args...)
end

############################################################################################

"""
    struct FunctionalCondition{FT<:AbstractFeature} <: AbstractCondition{FT}
        feature::FT
        f::FT
    end

A condition which yields a truth value equal to the value of a function.

See also [`AbstractFeature`](@ref).
"""
struct FunctionalCondition{FT<:AbstractFeature} <: AbstractCondition{FT}
    feature::FT
    f::Function
end

checkcondition(c::FunctionalCondition, args...; kwargs...) = (c.f)(featvalue(c.feature, args...; kwargs...))

syntaxstring(c::FunctionalCondition; kwargs...) = string(c.f, "(", syntaxstring(c.feature), ")")

function parsecondition(
    ::Type{FunctionalCondition},
    expr::String;
    featuretype = Feature,
    kwargs...
)
    r = Regex("^\\s*(\\w+)\\(\\s*(\\w+)\\s*\\)\\s*\$")
    slices = match(r, expr)

    @assert !isnothing(slices) && length(slices) == 2 "Could not parse FunctionalCondition from " *
        "expression $(repr(expr))."

    slices = string.(slices)

    feature = featuretype(slices[1])
    f = eval(Meta.parse(slices[2]))

    FunctionalCondition(feature, f)
end
