using SoleLogics: AbstractWorld, FullDimensionalFrame

"""
Abstract type for optimized, uniform logisets with
full dimensional frames. Here, "uniform" refers to the fact that
all instances have the same frame, and "full" refers to the fact that
*all* worlds of a given kind are considered (e.g., *all* points/intervals/rectangles)

See also
[`UniformFullDimensionalLogiset`](@ref),
[`SoleLogics.FullDimensionalFrame`](@ref),
[`AbstractModalLogiset`](@ref).
"""
abstract type AbstractUniformFullDimensionalLogiset{U,N,W<:AbstractWorld,FT<:AbstractFeature,FR<:FullDimensionalFrame{N,W}} <: AbstractModalLogiset{W,U,FT,FR} end

function maxchannelsize(X::AbstractUniformFullDimensionalLogiset)
    return error("Please, provide method maxchannelsize(::$(typeof(X))).")
end

function channelsize(X::AbstractUniformFullDimensionalLogiset, i_instance::Integer)
    return error("Please, provide method channelsize(::$(typeof(X)), i_instance::Integer).")
end

function dimensionality(X::AbstractUniformFullDimensionalLogiset{U,N}) where {U,N}
    N
end

frame(X::AbstractUniformFullDimensionalLogiset, i_instance::Integer) = FullDimensionalFrame(channelsize(X, i_instance))

"""
Abstract type for relational memosets optimized for uniform logisets with
full dimensional frames.

See also
[`UniformFullDimensionalLogiset`](@ref),
[`AbstractScalarOneStepRelationalMemoset`](@ref),
[`SoleLogics.FullDimensionalFrame`](@ref),
[`AbstractModalLogiset`](@ref).
"""
abstract type AbstractUniformFullDimensionalOneStepRelationalMemoset{U,W<:AbstractWorld,FR<:AbstractFrame{W}} <: AbstractScalarOneStepRelationalMemoset{W,U,FR} end

innerstruct(Xm::AbstractUniformFullDimensionalOneStepRelationalMemoset) = Xm.d

function nmemoizedvalues(Xm::AbstractUniformFullDimensionalOneStepRelationalMemoset)
    count(!isnothing, innerstruct(Xm))
end


