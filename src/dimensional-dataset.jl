# -------------------------------------------------------------
# Dimensional dataset: a simple dataset structure (basically, an hypercube)

import Base: eltype

_isnan(n::Number) = isnan(n)
_isnan(n::Nothing) = false
hasnans(n::Number) = _isnan(n)

############################################################################################

"""
    AbstractDimensionalDataset{T<:Number,D}             = AbstractArray{T,D}

An `D`-dimensional dataset is a multi-dimensional `Array` representing a set of
 (multivariate) `D`-dimensional instances (or samples):
The size of the `Array` is X × Y × ... × nvariables × ninstances
The dimensionality of the channel is denoted as N = D-2 (e.g. 1 for time series,
 2 for images), and its dimensionalities are denoted as X, Y, Z, etc.

Note: It'd be nice to define these with N being the dimensionality of the channel:
  e.g. const AbstractDimensionalInstance{T,N} = AbstractArray{T,N+2}
Unfortunately, this is not currently allowed ( see https://github.com/JuliaLang/julia/issues/8322 )

Note: This implementation assumes that all instances have uniform channel size (e.g. time
 series with same number of points, or images of same width and height)
"""
const AbstractDimensionalDataset{T<:Number,D}     = AbstractArray{T,D}
const AbstractDimensionalChannel{T<:Number,N}     = AbstractArray{T,N}
const AbstractDimensionalInstance{T<:Number,MN}   = AbstractArray{T,MN}

const DimensionalChannel{T<:Number,N}            = Union{Array{T,N},SubArray{T,N}}
const DimensionalInstance{T<:Number,MN}          = Union{Array{T,MN},SubArray{T,MN}}

hasnans(n::AbstractDimensionalDataset{<:Union{Nothing, Number}}) = any(_isnan.(n))

dimensionality(::Type{<:AbstractDimensionalDataset{T,D}}) where {T,D} = D-1-1
dimensionality(d::AbstractDimensionalDataset) = dimensionality(typeof(d))

ninstances(d::AbstractDimensionalDataset{T,D})        where {T,D} = size(d, D)
nvariables(d::AbstractDimensionalDataset{T,D})     where {T,D} = size(d, D-1)

function instances(d::AbstractVector, inds::AbstractVector{<:Integer}, return_view::Union{Val{true},Val{false}} = Val(false))
    if return_view == Val(true) @views d[inds]       else d[inds]    end
end
function instances(d::AbstractDimensionalDataset{T,2}, inds::AbstractVector{<:Integer}, return_view::Union{Val{true},Val{false}} = Val(false)) where {T}
    if return_view == Val(true) @views d[:, inds]       else d[:, inds]    end
end
function instances(d::AbstractDimensionalDataset{T,3}, inds::AbstractVector{<:Integer}, return_view::Union{Val{true},Val{false}} = Val(false)) where {T}
    if return_view == Val(true) @views d[:, :, inds]    else d[:, :, inds] end
end
function instances(d::AbstractDimensionalDataset{T,4}, inds::AbstractVector{<:Integer}, return_view::Union{Val{true},Val{false}} = Val(false)) where {T}
    if return_view == Val(true) @views d[:, :, :, inds] else d[:, :, :, inds] end
end

function concatdatasets(ds::AbstractDimensionalDataset{T,N}...) where {T,N}
    cat(ds...; dims=N)
end

function displaystructure(d::AbstractDimensionalDataset; indent_str = "", include_ninstances = true)
    padattribute(l,r) = string(l) * lpad(r,32+length(string(r))-(length(indent_str)+2+length(l)))
    pieces = []
    push!(pieces, "AbstractDimensionalDataset")
    push!(pieces, "$(padattribute("dimensionality:", dimensionality(d)))")
    if include_ninstances
        push!(pieces, "$(padattribute("# instances:", ninstances(d)))")
    end
    push!(pieces, "$(padattribute("# variables:", nvariables(d)))")
    push!(pieces, "$(padattribute("channelsize:", channelsize(d)))")
    push!(pieces, "$(padattribute("maxchannelsize:", maxchannelsize(d)))")
    push!(pieces, "$(padattribute("size × eltype:", "$(size(d)) × $(eltype(d))"))")

    return join(pieces, "\n$(indent_str)├ ", "\n$(indent_str)└ ") * "\n"
end

instance(d::AbstractDimensionalDataset{T,2},     idx::Integer) where T = @views d[:, idx]         # N=0
instance(d::AbstractDimensionalDataset{T,3},     idx::Integer) where T = @views d[:, :, idx]      # N=1
instance(d::AbstractDimensionalDataset{T,4},     idx::Integer) where T = @views d[:, :, :, idx]   # N=2

# TODO remove? @ferdiu
get_instance(args...) = instance(args...)

instance_channelsize(d::AbstractDimensionalDataset, i_instance::Integer) = instance_channelsize(get_instance(d, i_instance))
instance_channelsize(inst::DimensionalInstance{T,MN}) where {T,MN} = size(inst)[1:end-1]

channelvariable(inst::DimensionalInstance{T,1}, i_var::Integer) where T = @views inst[      i_var]::T                       # N=0
channelvariable(inst::DimensionalInstance{T,2}, i_var::Integer) where T = @views inst[:,    i_var]::DimensionalChannel{T,1} # N=1
channelvariable(inst::DimensionalInstance{T,3}, i_var::Integer) where T = @views inst[:, :, i_var]::DimensionalChannel{T,2} # N=2

############################################################################################

const UniformDimensionalDataset{T<:Number,D}     = Union{Array{T,D},SubArray{T,D}}

hasnans(X::UniformDimensionalDataset) = any(_isnan.(X))

channelsize(d::UniformDimensionalDataset) = size(d)[1:end-2]
maxchannelsize(d::UniformDimensionalDataset) = channelsize(d)

instance_channelsize(d::UniformDimensionalDataset, i_instance::Integer) = channelsize(d)

############################################################################################
