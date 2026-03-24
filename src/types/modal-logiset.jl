using SoleLogics: AbstractKripkeStructure

############################################################################################

"""
    abstract type AbstractModalLogiset{
        W<:AbstractWorld,
        U,
        FT<:AbstractFeature,
        FR<:AbstractFrame{W},
    } <: AbstractLogiset end

Abstract type for logisets, that is, logical datasets for
symbolic learning where each instance is a
[Kripke structure](https://en.wikipedia.org/wiki/Kripke_structure_(model_checking))
associating feature values to each world.
Conditions (see [`AbstractCondition`](@ref)), and logical formulas
with conditional letters can be checked on worlds of instances of the dataset.

# Interface
- `readfeature(X::AbstractModalLogiset, featchannel::Any, w::W, feature::AbstractFeature)`
- `featchannel(X::AbstractModalLogiset, i_instance::Integer, feature::AbstractFeature)`
- `featvalue(feature::AbstractFeature, X::AbstractModalLogiset, i_instance::Integer, args...; kwargs...)`
- `featvalue!(feature::AbstractFeature, X::AbstractModalLogiset{W}, featval, i_instance::Integer, w::W)`
- `featvalues!(feature::AbstractFeature, X::AbstractModalLogiset{W}, featslice)`
- `frametype(X::AbstractModalLogiset)`
- `worldtype(X::AbstractModalLogiset)`

See also
[`AbstractCondition`](@ref),
[`AbstractFeature`](@ref),
[`SoleLogics.AbstractKripkeStructure`](@ref),
[`SoleLogics.AbstractInterpretationSet`](@ref).
"""
abstract type AbstractModalLogiset{
    W<:AbstractWorld,U,FT<:AbstractFeature,FR<:AbstractFrame{W}
} <: AbstractLogiset end

function featchannel(
    X::AbstractModalLogiset{W}, i_instance::Integer, feature::AbstractFeature
) where {W<:AbstractWorld}
    return error(
        "Please, provide method featchannel(::$(typeof(X)), i_instance::$(typeof(i_instance)), feature::$(typeof(feature))).",
    )
end

function readfeature(
    X::AbstractModalLogiset{W}, featchannel::Any, w::W, feature::AbstractFeature
) where {W<:AbstractWorld}
    return error(
        "Please, provide method readfeature(::$(typeof(X)), featchannel::$(typeof(featchannel)), w::$(typeof(w)), feature::$(typeof(feature))).",
    )
end

function featvalue(
    feature::AbstractFeature,
    X::AbstractModalLogiset,
    i_instance::Integer,
    args...;
    kwargs...,
)
    readfeature(X, featchannel(X, i_instance, feature), args..., feature; kwargs...)
end

function featvalue!(
    feature::AbstractFeature, X::AbstractModalLogiset{W}, featval, i_instance::Integer, w::W
) where {W<:AbstractWorld}
    return error(
        "Please, provide method featvalue!(feature::$(typeof(feature)), X::$(typeof(X)), featval::$(typeof(featval)), i_instance::$(typeof(i_instance)), w::$(typeof(w))).",
    )
end

function featvalues!(
    feature::AbstractFeature, X::AbstractModalLogiset{W}, featslice
) where {W<:AbstractWorld}
    return error(
        "Please, provide method featvalues!(feature::$(typeof(feature)), X::$(typeof(X)), featslice::$(typeof(featslice))).",
    )
end

function frame(X::AbstractModalLogiset, i_instance::Integer)
    return error(
        "Please, provide method frame(::$(typeof(X)), i_instance::$(typeof(i_instance)))."
    )
end

############################################################################################

featvaltype(::Type{<:AbstractModalLogiset{W,U}}) where {W<:AbstractWorld,U} = U
featvaltype(X::AbstractModalLogiset) = featvaltype(typeof(X))

function featuretype(
    ::Type{<:AbstractModalLogiset{W,U,FT}}
) where {W<:AbstractWorld,U,FT<:AbstractFeature}
    FT
end
featuretype(X::AbstractModalLogiset) = featuretype(typeof(X))

############################################################################################

worldtype(::Type{<:AbstractModalLogiset{W}}) where {W<:AbstractWorld} = W
worldtype(X::AbstractModalLogiset) = worldtype(typeof(X))

function frametype(
    ::Type{<:AbstractModalLogiset{W,U,FT,FR}}
) where {W<:AbstractWorld,U,FT<:AbstractFeature,FR<:AbstractFrame}
    FR
end
frametype(X::AbstractModalLogiset) = frametype(typeof(X))

function representatives(X::AbstractModalLogiset, i_instance::Integer, args...)
    representatives(frame(X, i_instance), args...)
end

############################################################################################
