using SoleLogics: Point, Point1D, Point2D, Point3D

import Base: size, ndims, getindex, setindex!

"""
    abstract type AbstractUniformFullDimensionalLogiset{
        U,
        N,
        W<:AbstractWorld,
        FT<:AbstractFeature,
        FR<:FullDimensionalFrame{N,W}
    } <: AbstractModalLogiset{W,U,FT,FR} end

Abstract type for optimized, uniform logisets with full dimensional frames.

Here, *uniform* refers to the fact that all instances have the same frame,
and *full* refers to the fact that all worlds of a given kind are considered
(e.g., *all* points/intervals/rectangles).

See also [`AbstractModalLogiset`](@ref), [`UniformFullDimensionalLogiset`](@ref),
`SoleLogics.FullDimensionalFrame`.
"""
abstract type AbstractUniformFullDimensionalLogiset{
    U,
    N,
    W<:AbstractWorld,
    FT<:AbstractFeature,
    FR<:FullDimensionalFrame{N,W}
} <: AbstractModalLogiset{W,U,FT,FR} end

function maxchannelsize(X::AbstractUniformFullDimensionalLogiset)
    return error("Please, provide method maxchannelsize(::$(typeof(X))).")
end

function channelsize(X::AbstractUniformFullDimensionalLogiset, i_instance::Integer)
    return error("Please, provide method channelsize(::$(typeof(X)), i_instance::Integer).")
end

function dimensionality(X::AbstractUniformFullDimensionalLogiset{U,N}) where {U,N}
    N
end

function frame(X::AbstractUniformFullDimensionalLogiset{U,N,W}, i_instance::Integer) where {U,N,W<:AbstractWorld}
    return FullDimensionalFrame{N,W}(channelsize(X, i_instance))
end

############################################################################################

"""
    struct UniformFullDimensionalLogiset{
        U,
        W<:AbstractWorld,
        N,
        D<:AbstractArray{U},
        FT<:AbstractFeature,
        FR<:FullDimensionalFrame{N,W},
    } <: AbstractUniformFullDimensionalLogiset{U,N,W,FT,FR}


Uniform scalar logiset with full dimensional frames of dimensionality `N`,
storing values for each world in a `ninstances` × `nfeatures` array.

The size of the internal structure (or `featstruct`) depends on the (unique) world type
considered.

# Examples

## Interval-based frames

With an interval-based, `N`-dimensional frame, the worlds are `N`-intervals, and have `2*N`
parameters, which are used to index an `(N*2+2)`-dimensional `featstruct` (recall that two
dimensions are reserved for instances and features).

For example, consider the case of a 1-dimensional frame with three points:
        1       2       3
    ─────────────────────────

Given an instance and a feature, the `featstruct` will map the hyper-intervals across two
dimensions:
┌───┬───────┬───────┬───────┐
│   │   1   │   2   │   3   │
├───┼───────┼───────┼───────┤
│ 1 │ [1,1] │ [1,2] │ [1,3] │
├───┼───────┼───────┼───────┤
│ 2 │       │ [2,2] │ [2,3] │
├───┼───────┼───────┼───────┤
│ 3 │       │       │ [3,3] │
└───┴───────┴───────┴───────┘

See also [`AbstractModalLogiset`](@ref), [`AbstractUniformFullDimensionalLogiset`](@ref),
`SoleLogics.FullDimensionalFrame`.
"""
struct UniformFullDimensionalLogiset{
    U,
    W<:AbstractWorld,
    N,
    D<:AbstractArray{U},
    FT<:AbstractFeature,
    FR<:FullDimensionalFrame{N,W},
} <: AbstractUniformFullDimensionalLogiset{U,N,W,FT,FR}

    # Multi-dimensional structure
    featstruct::D

    # Features
    features::UniqueVector{FT}

    function UniformFullDimensionalLogiset{U,W,N,D,FT,FR}(
        featstruct::D,
        features::AbstractVector{FT},
    ) where {
        U,
        W<:AbstractWorld,
        N,
        D<:AbstractArray{U},
        FT<:AbstractFeature,
        FR<:FullDimensionalFrame{N,W}
    }
        features = UniqueVector(features)
        new{U,W,N,D,FT,FR}(featstruct, features)
    end

    function UniformFullDimensionalLogiset{U,W,N}(
        featstruct::D,
        features::AbstractVector{FT},
    ) where {U,W<:AbstractWorld,N,D<:AbstractArray{U},FT<:AbstractFeature}
        UniformFullDimensionalLogiset{U,W,N,D,FT,FullDimensionalFrame{N,W}}(
            featstruct, features)
    end

    function UniformFullDimensionalLogiset(
        featstruct::Any,
        features::AbstractVector{<:VarFeature},
        worldtype::Type,
    )
        # TODO move to SoleLogics geometrical worlds interface
        numparams(::Type{<:OneWorld}) = 0
        numparams(::Type{<:Point{N}}) where {N} = N
        numparams(::Type{<:Interval}) = 2
        numparams(::Type{<:Interval2D}) = 4

        U = eltype(featstruct)
        W = worldtype
        # T=D*P+2
        N = (ndims(featstruct)-2)//numparams(worldtype)
        UniformFullDimensionalLogiset{U,W,N}(featstruct, features)
    end

end

Base.size(X::UniformFullDimensionalLogiset, args...) = size(X.featstruct, args...)
Base.ndims(X::UniformFullDimensionalLogiset, args...) = ndims(X.featstruct, args...)

ninstances(X::UniformFullDimensionalLogiset)  = size(X, ndims(X)-1)
nfeatures(X::UniformFullDimensionalLogiset) = size(X, ndims(X))

features(X::UniformFullDimensionalLogiset) = X.features

################################### maxchannelsize #########################################
maxchannelsize(X::UniformFullDimensionalLogiset{U,OneWorld}) where {U} = ()
maxchannelsize(X::UniformFullDimensionalLogiset{U,<:Point{N}}) where {U,N} = begin
    (size(X)[1:N]...,)
end
maxchannelsize(X::UniformFullDimensionalLogiset{U,<:Interval}) where {U} = (size(X, 1),)
maxchannelsize(X::UniformFullDimensionalLogiset{U,<:Interval2D}) where {U} = begin
    (size(X, 1), size(X, 3),)
end
channelsize(X::UniformFullDimensionalLogiset, i_instance::Integer) = maxchannelsize(X)

############### featchannel, featvalues!, readfeature, featvalue, featvalue! ###############
#################################### OneWorld ##############################################

Base.@propagate_inbounds @inline function featchannel(
    X::UniformFullDimensionalLogiset{U,OneWorld},
    i_instance::Integer,
    feature     :: AbstractFeature,
    i_feature   :: Union{Nothing,Integer} = nothing
) where {U}
    if isnothing(i_feature)
        i_feature = _findfirst(isequal(feature), features(X))
        if isnothing(i_feature)
            error("Could not find feature $(feature) in logiset of type $(typeof(X)).")
        end
    end

    X.featstruct[i_instance, i_feature]
end
Base.@propagate_inbounds @inline function featvalues!(
    X::UniformFullDimensionalLogiset{U,OneWorld},
    featslice   :: AbstractArray{U,1},
    feature     :: AbstractFeature,
    i_feature   :: Union{Nothing,Integer} = nothing,
) where {U}
    if isnothing(i_feature)
        i_feature = _findfirst(isequal(feature), features(X))
        if isnothing(i_feature)
            error("Could not find feature $(feature) in logiset of type $(typeof(X)).")
        end
    end

    X.featstruct[:, i_feature] = featslice
end
function readfeature(
    X::UniformFullDimensionalLogiset{U,OneWorld},
    featchannel::U,
    w::OneWorld,
    f::AbstractFeature
) where {U}
    featchannel
end

@inline function featvalue(
    feature     :: AbstractFeature,
    X           :: UniformFullDimensionalLogiset{U,OneWorld},
    i_instance  :: Integer,
    w           :: OneWorld,
    i_feature   :: Union{Nothing,Integer} = nothing
) where {U}
    if isnothing(i_feature)
        i_feature = _findfirst(isequal(feature), features(X))
        if isnothing(i_feature)
            error("Could not find feature $(feature) in logiset of type $(typeof(X)).")
        end
    end

    X.featstruct[i_instance, i_feature]
end

@inline function featvalue!(
    feature::AbstractFeature,
    X::UniformFullDimensionalLogiset{U,OneWorld},
    featval::U,
    i_instance::Integer,
    w::OneWorld,
    i_feature::Union{Nothing,Integer} = nothing
) where {U}
    if isnothing(i_feature)
        i_feature = _findfirst(isequal(feature), features(X))
        if isnothing(i_feature)
            error("Could not find feature $(feature) in logiset of type $(typeof(X)).")
        end
    end

    X.featstruct[i_instance, i_feature] = featval
end

############### featchannel, featvalues!, readfeature, featvalue, featvalue! ###############
##################################### Point ################################################

Base.@propagate_inbounds @inline function featchannel(
    X::UniformFullDimensionalLogiset{U,<:Point},
    i_instance::Integer,
    feature     :: AbstractFeature,
    i_feature   :: Union{Nothing,Integer} = nothing
) where {U}
    if isnothing(i_feature)
        i_feature = _findfirst(isequal(feature), features(X))
        if isnothing(i_feature)
            error("Could not find feature $(feature) in logiset of type $(typeof(X)).")
        end
    end

    @views X.featstruct[:, i_instance, i_feature]
end
Base.@propagate_inbounds @inline function featvalues!(
    X::UniformFullDimensionalLogiset{U,<:Point},
    featslice   :: AbstractArray{U},
    feature     :: AbstractFeature,
    i_feature   :: Union{Nothing,Integer} = nothing,
) where {U}
    _ndims_featslice = ndims(featslice)

    if dimensionality(X) == _ndims_featslice-1
        throw(ArgumentError("Mismatching dimensionality between `X` " *
        "($(dimensionality(X))) and `featslice`-1 ($(_ndims_featslice-1))."))
    end

    if isnothing(i_feature)
        i_feature = _findfirst(isequal(feature), features(X))
        if isnothing(i_feature)
            error("Could not find feature $(feature) in logiset of type $(typeof(X)).")
        end
    end

    X.featstruct[[(:) for i in 1:_ndims_featslice]..., i_feature] = featslice
end
function readfeature(
    X::UniformFullDimensionalLogiset{U,<:Point},
    featchannel::AbstractArray{U,1},
    w::Point,
    f::AbstractFeature
) where {U}
    # to @giopaglia from @mauro-milella: tuple splatting works, but maybe I need to
    # correct the last coordinate with a -1 as in Interval case?
    featchannel[w.xyz...]
end

@inline function featvalue(
    feature     :: AbstractFeature,
    X           :: UniformFullDimensionalLogiset{U,<:Point},
    i_instance  :: Integer,
    w           :: Point,
    i_feature   :: Union{Nothing,Integer} = nothing
) where {U}
    if isnothing(i_feature)
        i_feature = _findfirst(isequal(feature), features(X))
        if isnothing(i_feature)
            error("Could not find feature $(feature) in logiset of type $(typeof(X)).")
        end
    end

    X.featstruct[w.xyz..., i_instance, i_feature]
end

@inline function featvalue!(
    feature::AbstractFeature,
    X::UniformFullDimensionalLogiset{U,<:Point},
    featval::U,
    i_instance::Integer,
    w::Point,
    i_feature::Union{Nothing,Integer} = nothing
) where {U}
    if isnothing(i_feature)
        i_feature = _findfirst(isequal(feature), features(X))
        if isnothing(i_feature)
            error("Could not find feature $(feature) in logiset of type $(typeof(X)).")
        end
    end

    X.featstruct[w.xyz..., i_instance, i_feature] = featval
end


############### featchannel, featvalues!, readfeature, featvalue, featvalue! ###############
#################################### Interval ##############################################

Base.@propagate_inbounds @inline function featchannel(
    X::UniformFullDimensionalLogiset{U,<:Interval},
    i_instance::Integer,
    feature     :: AbstractFeature,
    i_feature   :: Union{Nothing,Integer} = nothing
) where {U}
    if isnothing(i_feature)
        i_feature = _findfirst(isequal(feature), features(X))
        if isnothing(i_feature)
            error("Could not find feature $(feature) in logiset of type $(typeof(X)).")
        end
    end

    @views X.featstruct[:, :, i_instance, i_feature]
end
Base.@propagate_inbounds @inline function featvalues!(
    X::UniformFullDimensionalLogiset{U,<:Interval},
    featslice   :: AbstractArray{U,3},
    feature     :: AbstractFeature,
    i_feature   :: Union{Nothing,Integer} = nothing,
) where {U}
    if isnothing(i_feature)
        i_feature = _findfirst(isequal(feature), features(X))
        if isnothing(i_feature)
            error("Could not find feature $(feature) in logiset of type $(typeof(X)).")
        end
    end

    X.featstruct[:, :, :, i_feature] = featslice
end
function readfeature(
    X::UniformFullDimensionalLogiset{U,<:Interval},
    featchannel::AbstractArray{U,2},
    w::Interval,
    f::AbstractFeature
) where {U}
    featchannel[w.x, w.y-1]
end

@inline function featvalue(
    feature     :: AbstractFeature,
    X           :: UniformFullDimensionalLogiset{U,<:Interval},
    i_instance  :: Integer,
    w           :: Interval,
    i_feature   :: Union{Nothing,Integer} = nothing
) where {U}
    if isnothing(i_feature)
        i_feature = _findfirst(isequal(feature), features(X))
        if isnothing(i_feature)
            error("Could not find feature $(feature) in logiset of type $(typeof(X)).")
        end
    end

    X.featstruct[w.x, w.y-1, i_instance, i_feature]
end

@inline function featvalue!(
    feature::AbstractFeature,
    X::UniformFullDimensionalLogiset{U,<:Interval},
    featval::U,
    i_instance::Integer,
    w::Interval,
    i_feature::Union{Nothing,Integer} = nothing
) where {U}
    if isnothing(i_feature)
        i_feature = _findfirst(isequal(feature), features(X))
        if isnothing(i_feature)
            error("Could not find feature $(feature) in logiset of type $(typeof(X)).")
        end
    end

    X.featstruct[w.x, w.y-1, i_instance, i_feature] = featval
end

############### featchannel, featvalues!, readfeature, featvalue, featvalue! ###############
################################### Interval2D #############################################

Base.@propagate_inbounds @inline function featchannel(
    X::UniformFullDimensionalLogiset{U,<:Interval2D},
    i_instance::Integer,
    feature     :: AbstractFeature,
    i_feature   :: Union{Nothing,Integer} = nothing
) where {U}
    if isnothing(i_feature)
        i_feature = _findfirst(isequal(feature), features(X))
        if isnothing(i_feature)
            error("Could not find feature $(feature) in logiset of type $(typeof(X)).")
        end
    end

    @views X.featstruct[:, :, :, :, i_instance, i_feature]
end
Base.@propagate_inbounds @inline function featvalues!(
    X::UniformFullDimensionalLogiset{U,<:Interval2D},
    featslice   :: AbstractArray{U,5},
    feature     :: AbstractFeature,
    i_feature   :: Union{Nothing,Integer} = nothing,
) where {U}
    if isnothing(i_feature)
        i_feature = _findfirst(isequal(feature), features(X))
        if isnothing(i_feature)
            error("Could not find feature $(feature) in logiset of type $(typeof(X)).")
        end
    end

    X.featstruct[:, :, :, :, :, i_feature] = featslice
end
function readfeature(
    X::UniformFullDimensionalLogiset{U,<:Interval2D},
    featchannel::AbstractArray{U,4},
    w::Interval2D,
    f::AbstractFeature
) where {U}
    featchannel[w.x.x, w.x.y-1, w.y.x, w.y.y-1]
end

@inline function featvalue(
    feature     :: AbstractFeature,
    X           :: UniformFullDimensionalLogiset{U,<:Interval2D},
    i_instance  :: Integer,
    w           :: Interval2D,
    i_feature   :: Union{Nothing,Integer} = nothing
) where {U}
    if isnothing(i_feature)
        i_feature = _findfirst(isequal(feature), features(X))
        if isnothing(i_feature)
            error("Could not find feature $(feature) in logiset of type $(typeof(X)).")
        end
    end
    X.featstruct[w.x.x, w.x.y-1, w.y.x, w.y.y-1, i_instance, i_feature]
end

@inline function featvalue!(
    feature::AbstractFeature,
    X::UniformFullDimensionalLogiset{U,<:Interval2D},
    featval::U,
    i_instance::Integer,
    w::Interval2D,
    i_feature::Union{Nothing,Integer} = nothing
) where {U}
    if isnothing(i_feature)
        i_feature = _findfirst(isequal(feature), features(X))
        if isnothing(i_feature)
            error("Could not find feature $(feature) in logiset of type $(typeof(X)).")
        end
    end

    X.featstruct[w.x.x, w.x.y-1, w.y.x, w.y.y-1, i_instance, i_feature] = featval
end

############################################################################################

function allfeatvalues(
    X::UniformFullDimensionalLogiset,
)
    unique(X.featstruct)
end

function allfeatvalues(
    X::UniformFullDimensionalLogiset,
    i_instance,
)
    return error("Please, provide method allfeatvalues(::" *
        "$(typeof(X)), i_instance::$(typeof(i_instance)), f::$(typeof(f))).")
end

function allfeatvalues(
    X::UniformFullDimensionalLogiset,
    i_instance,
    f,
)
    return error("Please, provide method allfeatvalues(::" *
        "$(typeof(X)), i_instance::$(typeof(i_instance)), f::$(typeof(f))).")
end

############################################################################################

function instances(
    X::UniformFullDimensionalLogiset{U,W,0},
    inds::AbstractVector,
    return_view::Union{Val{true},Val{false}} = Val(false)
) where {U,W}
    UniformFullDimensionalLogiset{U,W,0}(
        if return_view == Val(true) @view X.featstruct[inds,:]
        else X.featstruct[inds,:] end, features(X)
    )
end

function instances(
    X::UniformFullDimensionalLogiset{U,W,1},
    inds::AbstractVector,
    return_view::Union{Val{true},Val{false}} = Val(false)
) where {U,W}
    UniformFullDimensionalLogiset{U,W,1}(
        if return_view == Val(true) @view X.featstruct[:,:,inds,:]
        else X.featstruct[:,:,inds,:] end, features(X)
    )
end

function instances(
    X::UniformFullDimensionalLogiset{U,W,2},
    inds::AbstractVector,
    return_view::Union{Val{true},Val{false}} = Val(false)
) where {U,W}
    UniformFullDimensionalLogiset{U,W,2}(
        if return_view == Val(true) @view X.featstruct[:,:,:,:,inds,:]
        else X.featstruct[:,:,:,:,inds,:] end, features(X)
    )
end

############################################################################################

function concatdatasets(
    Xs::UniformFullDimensionalLogiset{U,W,N}...
) where {U,W<:AbstractWorld,N}
    @assert allequal(features.(Xs)) "Cannot concatenate " *
        "UniformFullDimensionalLogiset's with different features: " *
        "$(@show features.(Xs))"
    UniformFullDimensionalLogiset{U,W,N}(
        cat([X.featstruct for X in Xs]...; dims=1+N*2), features(first(Xs)))
end

isminifiable(::UniformFullDimensionalLogiset) = true

function minify(X::UniformFullDimensionalLogiset{U,W,N}) where {U,W<:AbstractWorld,N}
    new_d, backmap = minify(X.featstruct)
    X = UniformFullDimensionalLogiset{U,W,N}(
        minify(new_d),
        features(X),
    )
    X, backmap
end

############################################################################################

function displaystructure(
    X::UniformFullDimensionalLogiset{U,W,N};
    indent_str = "",
    include_ninstances = true,
    include_worldtype = missing,
    include_featvaltype = missing,
    include_featuretype = missing,
    include_frametype = missing,
) where {U,W<:AbstractWorld,N}
    padattribute(l,r) = string(l) *
        lpad(r, 32+length(string(r)) - (length(indent_str) + 2 + length(l)))
    pieces = []
    push!(pieces, "UniformFullDimensionalLogiset " * (
        dimensionality(X) == 0 ? "of dimensionality 0" :
        dimensionality(X) == 1 ? "of channel size $(maxchannelsize(X))" :
            "of channel size $(join(maxchannelsize(X), " × "))"
        ) * " ($(humansize(X)))")
    if ismissing(include_worldtype) || include_worldtype != worldtype(X)
        push!(pieces, "$(padattribute("worldtype:", worldtype(X)))")
    end
    if ismissing(include_featvaltype) || include_featvaltype != featvaltype(X)
        push!(pieces, "$(padattribute("featvaltype:", featvaltype(X)))")
    end
    if ismissing(include_featuretype) || include_featuretype != featuretype(X)
        push!(pieces, "$(padattribute("featuretype:", featuretype(X)))")
    end
    if ismissing(include_frametype) || include_frametype != frametype(X)
        push!(pieces, "$(padattribute("frametype:", frametype(X)))")
    end
    if include_ninstances
        push!(pieces, "$(padattribute("# instances:", ninstances(X)))")
    end
    push!(pieces, "$(padattribute("size × eltype:", "$(size(X.featstruct)) × " *
        "$(eltype(X.featstruct))"))")
    # push!(pieces, "$(padattribute("dimensionality:", dimensionality(X)))")
    # push!(pieces, "$(padattribute("maxchannelsize:", maxchannelsize(X)))")
    # push!(pieces, "$(padattribute("# features:", nfeatures(X)))")
    push!(pieces, "$(padattribute("features:", "$(nfeatures(X)) -> " *
        "$(SoleLogics.displaysyntaxvector(features(X); quotes = false))"))")

    return join(pieces, "\n$(indent_str)├ ", "\n$(indent_str)└ ")
end

############################################################################################

function capacity(X::UniformFullDimensionalLogiset{U,OneWorld}) where {U}
    prod(size(X))
end
function capacity(X::UniformFullDimensionalLogiset{U,<:Interval}) where {U}
    prod([
        ninstances(X),
        nfeatures(X),
        div(size(X, 1)*(size(X, 2)+1),2),
    ])
end
function capacity(X::UniformFullDimensionalLogiset{U,<:Interval2D}) where {U}
    prod([
        ninstances(X),
        nfeatures(X),
        div(size(X, 1)*(size(X, 2)+1),2),
        div(size(X, 3)*(size(X, 4)+1),2),
    ])
end

############################################################################################

function hasnans(X::UniformFullDimensionalLogiset{U,OneWorld}) where {U}
    any(_isnan.(X.featstruct))
end
function hasnans(X::UniformFullDimensionalLogiset{U,<:Interval}) where {U}
    any([hasnans(X.featstruct[x,y-1,:,:])
        for x in 1:size(X, 1) for y in (x+1):(size(X, 2)+1)])
end
function hasnans(X::UniformFullDimensionalLogiset{U,<:Interval2D}) where {U}
    any([hasnans(X.featstruct[xx,xy-1,yx,yy-1,:,:])
        for xx in 1:size(X, 1) for xy in (xx+1):(size(X, 2)+1)
        for yx in 1:size(X, 3) for yy in (yx+1):(size(X, 4)+1)])
end

############################################################################################
