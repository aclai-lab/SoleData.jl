
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
    i_instance::Integer
)
    # dataset_dimensional, varnames = dataframe2dimensional(dataset; dry_run = true)
    # FullDimensionalFrame(channelsize(dataset_dimensional, i_instance))
    column = dataset[:,1]
    # frame(column, i_instance)
    v = column[i_instance]
    (v == ()) ? OneWorld() : FullDimensionalFrame(size(v))
end

# Note: used in naturalgrouping.
function frame(
    dataset::AbstractDataFrame,
    column::Vector,
    i_instance::Integer
)
    v = column[i_instance]
    (v == ()) ? OneWorld() : FullDimensionalFrame(size(v))
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
