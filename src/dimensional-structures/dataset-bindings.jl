using SoleData: AbstractUnivariateFeature

using MultiData: AbstractDimensionalDataset

import MultiData: ninstances, nvariables

import SoleData:
    islogiseed, initlogiset, frame,
    featchannel, readfeature, featvalue, vareltype, featvaltype

function islogiseed(dataset::AbstractDimensionalDataset)
    ndims(eltype(dataset)) >= 1
end

function initlogiset(
    dataset::AbstractDimensionalDataset,
    features::AbstractVector,
)

    _ninstances = ninstances(dataset)

    _worldtype(instancetype::Type{<:AbstractArray{T,1}}) where {T} = OneWorld
    _worldtype(instancetype::Type{<:AbstractArray{T,2}}) where {T} = Interval{Int}
    _worldtype(instancetype::Type{<:AbstractArray{T,3}}) where {T} = Interval2D{Int}

    function _worldtype(instancetype::Type{<:AbstractArray})
        error("Cannot initialize logiset with dimensional instances of type " *
            "`$(instancetype)`. Please, provide " *
            "instances of size X × Y × ... × nvariables." *
            "Note that, currently, only ndims ≤ 4 (dimensionality ≤ 2) is supported."
        )
    end

    W = _worldtype(eltype(dataset))
    N = dimensionality(dataset)

    @assert all(f->f isa VarFeature, features)
    features = UniqueVector(features)
    nfeatures = length(features)
    FT = eltype(features)

    # @show dataset
    # @show features
    # @show typeof(dataset)
    U = Union{map(f->featvaltype(dataset, f), features)...}

    if allequal(map(i_instance->channelsize(dataset, i_instance), 1:ninstances(dataset)))
        _maxchannelsize = maxchannelsize(dataset)
        featstruct = Array{U,length(_maxchannelsize)*2+2}(
                undef,
                vcat([[s, s] for s in _maxchannelsize]...)...,
                _ninstances,
                length(features)
            )
        # if !isconcretetype(U) # TODO only in this case but this breaks code
            # @warn "Abstract featvaltype detected upon initializing UniformFullDimensionalLogiset logiset: $(U)."
            fill!(featstruct, 0)
        # end
        return UniformFullDimensionalLogiset{U,W,N}(featstruct, features)
    else
        error("Different frames encountered for different dataset instances.")
        # @warn "Different frames encountered for different dataset instances." *
        #     "A generic logiset structure will be used, but be advised that it may be very slow."
        # # SoleData.frame(dataset, i_instance)
        # return ExplicitLogiset([begin
        #     fr = SoleData.frame(dataset, i_instance)
        #     (Dict{W,Dict{FT,U}}([w => Dict{FT,U}() for w in allworlds(fr)]), fr)
        #     end for i_instance in 1:ninstances(dataset)])
    end
end

function frame(
    dataset::AbstractDimensionalDataset,
    i_instance::Integer
)
    FullDimensionalFrame(channelsize(dataset, i_instance))
end

function featchannel(
    dataset::AbstractDimensionalDataset,
    i_instance::Integer,
    f::AbstractFeature,
)
    get_instance(dataset, i_instance)
end

function readfeature(
    dataset::AbstractDimensionalDataset,
    featchannel::Any,
    w::W,
    f::VarFeature,
) where {W<:AbstractWorld}
    _interpret_world(::OneWorld, instance::AbstractArray{T,1}) where {T} = instance
    _interpret_world(w::Interval, instance::AbstractArray{T,2}) where {T} = instance[w.x:w.y-1,:]
    _interpret_world(w::Interval2D, instance::AbstractArray{T,3}) where {T} = instance[w.x.x:w.x.y-1,w.y.x:w.y.y-1,:]
    wchannel = _interpret_world(w, featchannel)
    computefeature(f, wchannel)
end

function featvalue(
    dataset::AbstractDimensionalDataset,
    i_instance::Integer,
    w::W,
    feature::AbstractFeature,
) where {W<:AbstractWorld}
    readfeature(dataset, featchannel(dataset, i_instance, feature), w, feature)
end

function vareltype(
    dataset::AbstractDimensionalDataset{T},
    i_variable::Integer
) where {T}
    T
end

############################################################################################

using DataFrames

using MultiData: dataframe2dimensional

function islogiseed(
    dataset::AbstractDataFrame,
)
    true
end

function initlogiset(
    dataset::AbstractDataFrame,
    features::AbstractVector{<:VarFeature},
)
    _ninstances = nrow(dataset)

    dimensional, varnames = dataframe2dimensional(dataset; dry_run = true)

    initlogiset(dimensional, features)
end

function frame(
    dataset::AbstractDataFrame,
    i_instance::Integer
)
    # dataset_dimensional, varnames = dataframe2dimensional(dataset; dry_run = true)
    # FullDimensionalFrame(channelsize(dataset_dimensional, i_instance))
    column = dataset[:,1]
    # frame(column, i_instance)
    FullDimensionalFrame(size(column[i_instance]))
end

# Note: used in naturalgrouping.
function frame(
    dataset::AbstractDataFrame,
    column::Vector,
    i_instance::Integer
)
    FullDimensionalFrame(size(column[i_instance]))
end

# # Remove!! dangerous
# function frame(
#     column::Vector,
#     i_instance::Integer
# )
#     FullDimensionalFrame(size(column[i_instance]))
# end

function featchannel(
    dataset::AbstractDataFrame,
    i_instance::Integer,
    f::AbstractFeature,
)
    @views dataset[i_instance, :]
end

function readfeature(
    dataset::AbstractDataFrame,
    featchannel::Any,
    w::W,
    f::VarFeature,
) where {W<:AbstractWorld}
    _interpret_world(::OneWorld, instance::DataFrameRow) = instance
    _interpret_world(w::Interval, instance::DataFrameRow) = map(varchannel->varchannel[w.x:w.y-1], instance)
    _interpret_world(w::Interval2D, instance::DataFrameRow) = map(varchannel->varchannel[w.x.x:w.x.y-1,w.y.x:w.y.y-1], instance)
    wchannel = _interpret_world(w, featchannel)
    computefeature(f, wchannel)
end

function featchannel(
    dataset::AbstractDataFrame,
    i_instance::Integer,
    f::AbstractUnivariateFeature,
)
    @views dataset[i_instance, SoleData.i_variable(f)]
end

function readfeature(
    dataset::AbstractDataFrame,
    featchannel::Any,
    w::W,
    f::AbstractUnivariateFeature,
) where {W<:AbstractWorld}
    _interpret_world(::OneWorld, varchannel::T) where {T} = varchannel
    _interpret_world(w::Interval, varchannel::AbstractArray{T,1}) where {T} = varchannel[w.x:w.y-1]
    _interpret_world(w::Interval2D, varchannel::AbstractArray{T,2}) where {T} = varchannel[w.x.x:w.x.y-1,w.y.x:w.y.y-1]
    wchannel = _interpret_world(w, featchannel)
    computeunivariatefeature(f, wchannel)
end

function featvalue(
    dataset::AbstractDataFrame,
    i_instance::Integer,
    w::W,
    feature::AbstractFeature,
) where {W<:AbstractWorld}
    readfeature(dataset, featchannel(dataset, i_instance, feature), w, feature)
end

function vareltype(
    dataset::AbstractDataFrame,
    i_variable::Integer
)
    eltype(eltype(dataset[:,i_variable]))
end
