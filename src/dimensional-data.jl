# -------------------------------------------------------------
# Dimensional dataset: a simple dataset structure (basically, an hypercube)

import Base: eltype
import SoleBase: dimensionality, channelsize

_isnan(n::Number) = isnan(n)
_isnan(n::Nothing) = false
hasnans(n::Number) = _isnan(n)

############################################################################################

"""
    AbstractDimensionalDataset{T<:Number,D} = AbstractArray{T,D}

An `D`-dimensional dataset is a multi-dimensional `Array` representing a set of
 (multivariate) `D`-dimensional instances (or samples):
The size of the `Array` is X × Y × ... × nvariables × ninstances
The dimensionality of the channel is denoted as N = D-2 (e.g. 1 for time series,
 2 for images), and its dimensionalities are denoted as X, Y, Z, etc.

Note: It'd be nice to define these with N being the dimensionality of the channel:
  e.g. const AbstractDimensionalDataset{T<:Number,N} = AbstractArray{T,N+2}
Unfortunately, this is not currently allowed ( see https://github.com/JuliaLang/julia/issues/8322 )

Note: This implementation assumes that all instances have uniform channel size (e.g. time
 series with same number of points, or images of same width and height)
"""
const AbstractDimensionalDataset{T<:Number,D}     = AbstractArray{T,D}

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

    return join(pieces, "\n$(indent_str)├ ", "\n$(indent_str)└ ")
end

instance(d::AbstractDimensionalDataset{T,2},     idx::Integer) where T = @views d[:, idx]         # N=0
instance(d::AbstractDimensionalDataset{T,3},     idx::Integer) where T = @views d[:, :, idx]      # N=1
instance(d::AbstractDimensionalDataset{T,4},     idx::Integer) where T = @views d[:, :, :, idx]   # N=2

# TODO remove? @ferdiu
get_instance(args...) = instance(args...)

instance_channelsize(d::AbstractDimensionalDataset, i_instance::Integer) = instance_channelsize(get_instance(d, i_instance))
instance_channelsize(instance::AbstractArray) = size(instance)[1:end-1]

channelvariable(instance::AbstractArray{T,1}, i_var::Integer) where T = @views instance[      i_var]::T                       # N=0
channelvariable(instance::AbstractArray{T,2}, i_var::Integer) where T = @views instance[:,    i_var]::AbstractArray{T,1} # N=1
channelvariable(instance::AbstractArray{T,3}, i_var::Integer) where T = @views instance[:, :, i_var]::AbstractArray{T,2} # N=2

############################################################################################

const UniformDimensionalDataset{T<:Number,D}     = Union{Array{T,D},SubArray{T,D}}

hasnans(X::UniformDimensionalDataset) = any(_isnan.(X))

channelsize(d::UniformDimensionalDataset) = size(d)[1:end-2]
maxchannelsize(d::UniformDimensionalDataset) = channelsize(d)

instance_channelsize(d::UniformDimensionalDataset, i_instance::Integer) = channelsize(d)

############################################################################################
############################################################################################
############################################################################################

# import Tables: subset

# function Tables.subset(X::AbstractDimensionalDataset, inds; viewhint = nothing)
#     slicedataset(X, inds; return_view = (isnothing(viewhint) || viewhint == true))
# end

# using MLJBase
# using MLJModelInterface
# import MLJModelInterface: selectrows, _selectrows

# # From MLJModelInferface.jl/src/data_utils.jl
# function MLJModelInterface._selectrows(X::AbstractDimensionalDataset{T,3}, r) where {T}
#     slicedataset(X, inds; return_view = (isnothing(viewhint) || viewhint == true))
# end
# function MLJModelInterface._selectrows(X::AbstractDimensionalDataset{T,4}, r) where {T}
#     slicedataset(X, inds; return_view = (isnothing(viewhint) || viewhint == true))
# end
# function MLJModelInterface.selectrows(::MLJBase.FI, ::Val{:table}, X::AbstractDimensionalDataset, r)
#     r = r isa Integer ? (r:r) : r
#     return Tables.subset(X, r)
# end

function cube2dataframe(X::AbstractArray, colnames = nothing) # colnames = :auto
    varslices = eachslice(X; dims=ndims(X)-1)
    if isnothing(colnames)
        colnames = ["V$(i_var)" for i_var in 1:length(varslices)]
    end
    DataFrame(eachslice.(varslices; dims=ndims(X)-1), colnames)
end

function dataframe2cube(
    df::AbstractDataFrame;
    dry_run::Bool = false,
)
    coltypes = eltype.(eachcol(df))
    wrong_coltypes = filter(t->!(t <: Union{Real,AbstractArray}), coltypes)

    @assert length(wrong_coltypes) == 0 "Column types not allowed: " *
        "$(join(wrong_coltypes, ", "))"

    wrong_eltypes = filter(t->!(t <: Real), eltype.(coltypes))

    @assert length(wrong_eltypes) == 0 "Column eltypes not allowed: " *
        "$(join(wrong_eltypes, ", "))"

    common_eltype = Union{eltype.(coltypes)...}
    @assert common_eltype <: Real
    if !isconcretetype(common_eltype)
        @warn "Common variable eltype `$(common_eltype)` is not concrete. " *
            "consider converting all values to $(promote_type(eltype.(coltypes)...))."
    end

    # _channelndims = (x)->ndims(x) # (hasmethod(ndims, (typeof(x),)) ? ndims(x) : missing)
    # _channelsize = (x)->size(x) # (hasmethod(size, (typeof(x),)) ? size(x) : missing)

    df_ndims = ndims.(df)
    percol_channelndimss = [(colname => unique(df_ndims[:,colname])) for colname in names(df)]
    wrong_percol_channelndimss = filter(((colname, ndimss),)->length((ndimss)) != 1, percol_channelndimss)
    @assert length(wrong_percol_channelndimss) == 0 "All instances should have the same " *
        "ndims for each variable. Got ndims's: $(wrong_percol_channelndimss)"

    df_size = size.(df)
    percol_channelsizess = [(colname => unique(df_size[:,colname])) for colname in names(df)]
    wrong_percol_channelsizess = filter(((colname, channelsizess),)->length((channelsizess)) != 1, percol_channelsizess)
    @assert length(wrong_percol_channelsizess) == 0 "All instances should have the same " *
        "size for each variable. Got sizes: $(wrong_percol_channelsizess)"

    channelsizes = first.(last.(percol_channelsizess))

    @assert allequal(channelsizes) "All variables should have the same " *
        "channel size. Got: $(SoleBase._groupby(channelsizes, names(df))))"
    __channelsize = first(channelsizes)

    n_variables = ncol(df)
    n_instances = nrow(df)

    cube = Array{common_eltype}(undef, __channelsize..., n_variables, n_instances)
    if !dry_run
        for (i_col, colname) in enumerate(eachcol(df))
            for (i_row, row) in enumerate(colname)
                cube[[(:) for i in 1:length(size(row))]...,i_col,i_row] = row
            end
        end
    end

    return cube, names(df)
end
