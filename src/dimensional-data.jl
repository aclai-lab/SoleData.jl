# -------------------------------------------------------------
# Dimensional dataset: a simple dataset structure (basically, an hypercube)

using StatsBase
import Base: eltype
import SoleBase: dimensionality, channelsize

_isnan(n::Number) = isnan(n)
_isnan(n::Nothing) = false
hasnans(n::Number) = _isnan(n)
hasnans(a::AbstractArray) = any(_isnan.(a))

############################################################################################

"""
    AbstractDimensionalDataset{T<:Number,D} = AbstractVector{<:AbstractArray{T,D}}

A `D`-dimensional dataset is a vector of
 (multivariate) `D`-dimensional instances (or samples):
Each instance is an `Array` with size X × Y × ... × nvariables
The dimensionality of the channel is denoted as N = D-1 (e.g. 1 for time series,
 2 for images), and its dimensionalities are denoted as X, Y, Z, etc.

Note: It'd be nice to define these with N being the dimensionality of the channel:
  e.g. `const AbstractDimensionalDataset{T<:Number,N} = AbstractVector{<:AbstractArray{T,N+1}}`
Unfortunately, this is not currently allowed (see https://github.com/JuliaLang/julia/issues/8322 )
"""
const AbstractDimensionalDataset{T<:Number,D} = AbstractVector{<:AbstractArray{T,D}}

function eachinstance(X::AbstractDimensionalDataset)
    X
end

hasnans(d::AbstractDimensionalDataset{<:Union{Nothing,Number}}) = any(hasnans, eachinstance(d))

dimensionality(::Type{<:AbstractDimensionalDataset{T,D}}) where {T<:Number,D} = D-1
dimensionality(d::AbstractDimensionalDataset) = dimensionality(typeof(d))

ninstances(d::AbstractDimensionalDataset{T,D}) where {T<:Number,D} = length(d)
function checknvariables(d::AbstractDimensionalDataset{T,D}) where {T<:Number,D}
    if !allequal(map(instance->size(instance, D), eachinstance(d)))
        error("Non-uniform nvariables in dimensional dataset:" *
            " $(countmap(map(instance->size(instance, D), eachinstance(d))))")
    else
        true
    end
end
nvariables(d::AbstractDimensionalDataset{T,D}) where {T<:Number,D} = size(first(eachinstance(d)), D)

function instances(d::AbstractDimensionalDataset, inds::AbstractVector{<:Integer}, return_view::Union{Val{true},Val{false}} = Val(false))
    if return_view == Val(true) @views d[inds] else d[inds]    end
end

function concatdatasets(ds::AbstractDimensionalDataset{T}...) where {T<:Number}
    vcat(ds...)
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
    push!(pieces, "$(padattribute("channelsize countmap:", StatsBase.countmap(map(i_instance->channelsize(d, i_instance), 1:ninstances(d)))))")
    push!(pieces, "$(padattribute("maxchannelsize:", maxchannelsize(d)))")
    push!(pieces, "$(padattribute("size × eltype:", "$(size(d)) × $(eltype(d))"))")

    return join(pieces, "\n$(indent_str)├ ", "\n$(indent_str)└ ")
end

# TODO remove one of the two. @ferdiu
instance(d::AbstractDimensionalDataset, idx::Integer) = @views d[idx]
get_instance(args...) = instance(args...)

channelsize(d::AbstractDimensionalDataset, i_instance::Integer) = instance_channelsize(d[i_instance])
maxchannelsize(d::AbstractDimensionalDataset) = maximum(i_instance->channelsize(d, i_instance), 1:ninstances(d))

instance_channel(instance::AbstractArray{T,1}, i_var::Integer) where T = @views instance[      i_var]::T                       # N=0
instance_channel(instance::AbstractArray{T,2}, i_var::Integer) where T = @views instance[:,    i_var]::AbstractArray{T,1} # N=1
instance_channel(instance::AbstractArray{T,3}, i_var::Integer) where T = @views instance[:, :, i_var]::AbstractArray{T,2} # N=2

instance_channelsize(instance::AbstractArray) = size(instance)[1:end-1]
instance_nvariables(instance::AbstractArray) = size(instance, ndims(instance))

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
# function MLJModelInterface._selectrows(X::AbstractDimensionalDataset{T,4}, r) where {T<:Number}
#     slicedataset(X, inds; return_view = (isnothing(viewhint) || viewhint == true))
# end
# function MLJModelInterface._selectrows(X::AbstractDimensionalDataset{T,5}, r) where {T<:Number}
#     slicedataset(X, inds; return_view = (isnothing(viewhint) || viewhint == true))
# end
# function MLJModelInterface.selectrows(::MLJBase.FI, ::Val{:table}, X::AbstractDimensionalDataset, r)
#     r = r isa Integer ? (r:r) : r
#     return Tables.subset(X, r)
# end


function _check_dataframe(df::AbstractDataFrame)
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
end


function dimensional2dataframe(X::AbstractDimensionalDataset, colnames = nothing) # colnames = :auto
    SoleData.checknvariables(X)
    varslices = [begin
        map(instance->SoleData.instance_channel(instance, i_variable), eachinstance(X))
    end for i_variable in 1:nvariables(X)]
    if isnothing(colnames)
        colnames = ["V$(i_var)" for i_var in 1:length(varslices)]
    end
    DataFrame(varslices, colnames)
end

function dataframe2dimensional(
    df::AbstractDataFrame;
    dry_run::Bool = false,
)
    SoleData,_check_dataframe(df)

    coltypes = eltype.(eachcol(df))
    common_eltype = Union{eltype.(coltypes)...}

    n_variables = ncol(df)

    dataset = [begin
        instance = begin
            # if !dry_run
            cat(collect(row)...; dims=ndims(row[1])+1)
            # else
            #     Array{common_eltype}(undef, __channelsize..., n_variables)
            # end
        end
        instance
    end for row in eachrow(df)]

    return dataset, names(df)
end


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
    _check_dataframe(df)

    coltypes = eltype.(eachcol(df))
    common_eltype = Union{eltype.(coltypes)...}

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
                if ndims(row) == 0
                    row = first(row)
                end
                cube[[(:) for i in 1:length(size(row))]...,i_col,i_row] = row
            end
        end
    end

    return cube, names(df)
end
