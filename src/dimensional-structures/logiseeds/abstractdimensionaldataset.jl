using SoleData: AbstractUnivariateFeature

using MultiData: AbstractDimensionalDataset

import MultiData: ninstances, nvariables

import SoleData:
    islogiseed,
    initlogiset,
    frame,
    featchannel,
    readfeature,
    featvalue,
    vareltype,
    featvaltype

using SoleLogics: nparameters

function islogiseed(dataset::AbstractDimensionalDataset)
    ndims(eltype(dataset)) >= 1
end

DEFAULT_WORLDTYPE_BY_DIM = Dict{Int,Type{<:SoleLogics.AbstractWorld}}([
    0 => OneWorld, 1 => Interval{Int64}, 2 => Interval2D{Int64}
])

"""
    function initlogiset(
        dataset::AbstractDimensionalDataset,
        features::AbstractVector;
        worldtype_by_dim::Union{Nothing,AbstractDict{<:Integer,<:Type}}=nothing
    )::UniformFullDimensionalLogiset

Given an [`AbstractDimensionalDataset`](@ref), build a
[`UniformFullDimensionalLogiset`](@ref).

# Keyword Arguments
- worldtype_by_dim::Union{Nothing,AbstractDict{<:Integer,<:Type}}=nothing:
map between a dimensionality, as integer, and the [`AbstractWorld`](@ref) type associated;
when unspecified, this is defaulted to `Dict(0 => OneWorld, 1 => Interval, 2 => Interval2D)`.

See also [`AbstractDimensionalDataset`](@ref),
SoleLogics.AbstractWorld,
MultiData.dimensionality,
[`UniformFullDimensionalLogiset`](@ref).
"""
function initlogiset(
    dataset::AbstractDimensionalDataset,
    features::AbstractVector;
    worldtype_by_dim::Union{Nothing,<:AbstractDict{<:Integer,<:Type}}=nothing,
)::UniformFullDimensionalLogiset
    worldtype_by_dim =
        isnothing(worldtype_by_dim) ? DEFAULT_WORLDTYPE_BY_DIM : worldtype_by_dim

    _ninstances = ninstances(dataset)

    # Note: a dimension is for the variables
    _worldtype(instancetype::Type{<:AbstractArray{T,1}}) where {T} = worldtype_by_dim[0]
    _worldtype(instancetype::Type{<:AbstractArray{T,2}}) where {T} = worldtype_by_dim[1]
    _worldtype(instancetype::Type{<:AbstractArray{T,3}}) where {T} = worldtype_by_dim[2]

    function _worldtype(instancetype::Type{<:AbstractArray})
        error(
            "Cannot initialize logiset with dimensional instances of type " *
            "`$(instancetype)`. Please, provide " *
            "instances of size X × Y × ... × nvariables." *
            "Note that, currently, only ndims ≤ 4 (dimensionality ≤ 2) is supported.",
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

    repeatdim = N > 0 ? div(nparameters(W), N) : N

    if allequal(map(i_instance->channelsize(dataset, i_instance), 1:ninstances(dataset)))
        _maxchannelsize = maxchannelsize(dataset)

        featstruct = Array{U,nparameters(W)+2}(
            undef,
            repeat(collect(_maxchannelsize); inner=repeatdim)...,
            _ninstances,
            length(features),
        )
        if !isconcretetype(U) # TODO only in this case but this breaks code
            @warn "Abstract featvaltype detected upon initializing UniformFullDimensionalLogiset logiset: $(U)."
            fill!(featstruct, 0)
        end

        return UniformFullDimensionalLogiset{U,W,N}(featstruct, features)
    else
        error("Different frames encountered for different dataset instances.")
        # @warn "Different frames encountered for different dataset instances." *
        #     "A generic logiset structure will be used, but be advised that it may be very slow."
        # # SoleData.frame(dataset, i_instance)
        # return ExplicitModalLogiset([begin
        #     fr = SoleData.frame(dataset, i_instance)
        #     (Dict{W,Dict{FT,U}}([w => Dict{FT,U}() for w in allworlds(fr)]), fr)
        #     end for i_instance in 1:ninstances(dataset)])
    end
end

function frame(
    dataset::AbstractDimensionalDataset,
    i_instance::Integer;
    worldtype_by_dim::Union{Nothing,AbstractDict{<:Integer,<:Type}}=nothing,
    kwargs...,
)
    worldtype =
        !isnothing(worldtype_by_dim) ? worldtype_by_dim[dimensionality(dataset)] : nothing
    FullDimensionalFrame(channelsize(dataset, i_instance), worldtype)
end

function featchannel(
    dataset::AbstractDimensionalDataset, i_instance::Integer, f::AbstractFeature
)
    get_instance(dataset, i_instance)
end

function readfeature(
    dataset::AbstractDimensionalDataset, featchannel::Any, w::W, f::VarFeature
) where {W<:AbstractWorld}
    _interpret_world(::OneWorld, instance::AbstractArray{T,1}) where {T} = instance
    _interpret_world(w::Interval, instance::AbstractArray{T,2}) where {T} = instance[
        w.x:(w.y - 1), :,
    ]
    _interpret_world(w::Interval2D, instance::AbstractArray{T,3}) where {T} = instance[
        w.x.x:(w.x.y - 1), w.y.x:(w.y.y - 1), :,
    ]
    wchannel = _interpret_world(w, featchannel)
    computefeature(f, wchannel)
end

function featvalue(
    feature::AbstractFeature, dataset::AbstractDimensionalDataset, i_instance::Integer, w::W
) where {W<:AbstractWorld}
    readfeature(dataset, featchannel(dataset, i_instance, feature), w, feature)
end

function vareltype(dataset::AbstractDimensionalDataset{T}, i_variable::VariableId) where {T}
    T
end

varnames(X::AbstractDimensionalDataset{T}) where {T} = nothing

############################################################################################
