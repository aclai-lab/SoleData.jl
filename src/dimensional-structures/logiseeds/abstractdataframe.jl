
using DataFrames

using MultiData: dataframe2dimensional

function islogiseed(
    dataset::AbstractDataFrame,
)
    true
end

function initlogiset(
    dataset::AbstractDataFrame,
    features::AbstractVector{<:VarFeature};
    kwargs...,
)
    _ninstances = nrow(dataset)
    dimensional, varnames = dataframe2dimensional(dataset; dry_run = true)

    initlogiset(dimensional, features; kwargs...)
end

function frame(
    dataset::AbstractDataFrame,
    i_instance::Integer;
    kwargs...
)
    column = dataset[:,1]
    frame(dataset, column, i_instance; kwargs...)
end


# Note: used in naturalgrouping.
function frame(
    dataset::AbstractDataFrame,
    column::Vector,
    i_instance::Integer;
    # worldtype_by_dim::Union{Nothing,AbstractDict{<:Integer,<:Type}}=nothing
)
    v = column[i_instance]
    if v == ()
        OneWorld()
    else
        # worldtype_by_dim = isnothing(worldtype_by_dim) ? DEFAULT_WORLDTYPE_BY_DIM :
        #     worldtype_by_dim
        # N = dimensionality(dataset)
        # W = worldtype_by_dim[N]
        # FullDimensionalFrame{N,W}(size(v))# _worldtype(eltype(dataset)))
        FullDimensionalFrame(size(v))
    end
end

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

function _get_wchannel(w::W, featchannel::Any) where {W<:AbstractWorld}
    _interpret_world(
        ::OneWorld,
        varchannel::T
    ) where {T} = varchannel

    _interpret_world(
        ::Point{N},
        varchannel::AbstractArray{T,N}
    ) where {T,N} = varchannel[w.xyz...]

    _interpret_world(
        w::Interval,
        varchannel::AbstractArray{T,1}
    ) where {T} = varchannel[w.x:w.y-1]

    _interpret_world(
        w::Interval2D,
        varchannel::AbstractArray{T,2}
    ) where {T} = varchannel[w.x.x:w.x.y-1,w.y.x:w.y.y-1]

    return _interpret_world(w, featchannel)
end

function readfeature(
    dataset::AbstractDataFrame,
    featchannel::Any,
    w::W,
    f::AbstractUnivariateFeature,
) where {W<:AbstractWorld}
    wchannel = _get_wchannel(w, featchannel)
    computeunivariatefeature(f, wchannel)
end

function readfeature(
    dataset::AbstractDataFrame,
    featchannel::Any,
    w::W,
    f::VariableDistance,
) where {W<:AbstractWorld}
    wchannel = _get_wchannel(w, featchannel)

    # when we apply a the feature wrapped within VariableDistance, we expect its argument
    # to be a channel of a specific size;
    try
        return computeunivariatefeature(f, wchannel)
    catch _error
        # when the property above is not true, just put a "nothing" placeholder
        if isa(_error, DimensionMismatch)
            return Inf
        else
            rethrow(_error)
        end
    end
end

function featvalue(
    feature::AbstractFeature,
    dataset::AbstractDataFrame,
    i_instance::Integer,
    w::W,
) where {W<:AbstractWorld}
    readfeature(dataset, featchannel(dataset, i_instance, feature), w, feature)
end

function vareltype(
    dataset::AbstractDataFrame,
    i_variable::VariableId,
)
    eltype(eltype(dataset[:,i_variable]))
end

varnames(dataset::AbstractDataFrame) = names(dataset)
