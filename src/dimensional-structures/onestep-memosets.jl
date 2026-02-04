using SoleData: AbstractScalarOneStepRelationalMemoset

import Base: size, ndims, getindex, setindex!

"""
A relational memoset optimized for uniform scalar logisets with
full dimensional frames of dimensionality `N`, storing values for each world in
a `ninstances` × `nmetaconditions` × `nrelations` array.
Each world is a hyper-interval, and its `N*2` components are used to index different array
dimensions, ultimately resulting in a `(N*2+3)`-dimensional array.

See also
[`UniformFullDimensionalLogiset`](@ref),
[`FullDimensionalFrame`](@ref),
[`AbstractModalLogiset`](@ref).
"""
struct UniformFullDimensionalOneStepRelationalMemoset{
    U,W<:AbstractWorld,N,D<:AbstractArray{UU} where UU<:Union{U,Nothing}
} <: AbstractUniformFullDimensionalOneStepRelationalMemoset{U,W,FullDimensionalFrame{N,W}}

    # Multi-dimensional structure
    d::D

    function UniformFullDimensionalOneStepRelationalMemoset{U,W,N,D}(
        d::D
    ) where {U,W<:AbstractWorld,N,D<:AbstractArray{UU} where UU<:Union{U,Nothing}}
        new{U,W,N,D}(d)
    end

    function UniformFullDimensionalOneStepRelationalMemoset{U,W,N}(
        d::D
    ) where {U,W<:AbstractWorld,N,D<:AbstractArray{UU} where UU<:Union{U,Nothing}}
        UniformFullDimensionalOneStepRelationalMemoset{U,W,N,D}(d)
    end

    function UniformFullDimensionalOneStepRelationalMemoset(
        X::UniformFullDimensionalLogiset{U,W,0},
        metaconditions::AbstractVector{<:ScalarMetaCondition},
        relations::AbstractVector{<:AbstractRelation},
        perform_initialization::Bool=true,
    ) where {U,W<:OneWorld}
        nmetaconditions = length(metaconditions)
        nrelations = length(relations)
        # TODO
        # if nrelations > 0
        #     @warn "Note that using a relational memoset with W = $(OneWorld) is " *
        #         "overkill $(@show nrelations)."
        # end
        d = begin
            if perform_initialization
                d = Array{Union{U,Nothing},3}(undef, ninstances(X), nmetaconditions, nrelations)
                fill!(d, nothing)
            else
                Array{U,3}(undef, ninstances(X), nmetaconditions, nrelations)
            end
        end
        UniformFullDimensionalOneStepRelationalMemoset{U,W,0}(d)
    end

    function UniformFullDimensionalOneStepRelationalMemoset(
        X::UniformFullDimensionalLogiset{U,W,1},
        metaconditions::AbstractVector{<:ScalarMetaCondition},
        relations::AbstractVector{<:AbstractRelation},
        perform_initialization::Bool=true,
    ) where {U,W<:Interval}
        nmetaconditions = length(metaconditions)
        nrelations = length(relations)
        d = begin
            if perform_initialization
                d = Array{Union{U,Nothing},5}(
                    undef,
                    size(X, 1),
                    size(X, 2),
                    ninstances(X),
                    nmetaconditions,
                    nrelations,
                )
                fill!(d, nothing)
            else
                Array{U,5}(
                    undef,
                    size(X, 1),
                    size(X, 2),
                    ninstances(X),
                    nmetaconditions,
                    nrelations,
                )
            end
        end
        UniformFullDimensionalOneStepRelationalMemoset{U,W,1}(d)
    end

    function UniformFullDimensionalOneStepRelationalMemoset(
        X::UniformFullDimensionalLogiset{U,W,2},
        metaconditions::AbstractVector{<:ScalarMetaCondition},
        relations::AbstractVector{<:AbstractRelation},
        perform_initialization::Bool=true,
    ) where {U,W<:Interval2D}
        nmetaconditions = length(metaconditions)
        nrelations = length(relations)
        d = begin
            if perform_initialization
                d = Array{Union{U,Nothing},7}(
                    undef,
                    size(X, 1),
                    size(X, 2),
                    size(X, 3),
                    size(X, 4),
                    ninstances(X),
                    nmetaconditions,
                    nrelations,
                )
                fill!(d, nothing)
            else
                Array{U,7}(
                    undef,
                    size(X, 1),
                    size(X, 2),
                    size(X, 3),
                    size(X, 4),
                    ninstances(X),
                    nmetaconditions,
                    nrelations,
                )
            end
        end
        UniformFullDimensionalOneStepRelationalMemoset{U,W,2}(d)
    end
end

Base.size(Xm::UniformFullDimensionalOneStepRelationalMemoset, args...) = size(Xm.d, args...)
function Base.ndims(Xm::UniformFullDimensionalOneStepRelationalMemoset, args...)
    ndims(Xm.d, args...)
end

ninstances(Xm::UniformFullDimensionalOneStepRelationalMemoset) = size(Xm, ndims(Xm)-2)
nmetaconditions(Xm::UniformFullDimensionalOneStepRelationalMemoset) = size(Xm, ndims(Xm)-1)
nrelations(Xm::UniformFullDimensionalOneStepRelationalMemoset) = size(Xm, ndims(Xm))

############################################################################################

function capacity(Xm::UniformFullDimensionalOneStepRelationalMemoset{U,OneWorld}) where {U}
    prod(size(Xm))
end
function capacity(
    Xm::UniformFullDimensionalOneStepRelationalMemoset{U,<:Interval}
) where {U}
    prod([
        ninstances(Xm),
        nmetaconditions(Xm),
        nrelations(Xm),
        div(size(Xm, 1)*(size(Xm, 1)+1), 2),
    ])
end
function capacity(
    Xm::UniformFullDimensionalOneStepRelationalMemoset{U,<:Interval2D}
) where {U}
    prod([
        ninstances(Xm),
        nmetaconditions(Xm),
        nrelations(Xm),
        div(size(Xm, 1)*(size(Xm, 1)+1), 2),
        div(size(Xm, 3)*(size(Xm, 3)+1), 2),
    ])
end

############################################################################################

@inline function Base.getindex(
    Xm::UniformFullDimensionalOneStepRelationalMemoset{U,W},
    i_instance::Integer,
    w::W,
    i_metacond::Integer,
    i_relation::Integer,
) where {U,W<:OneWorld}
    Xm.d[i_instance, i_metacond, i_relation]
end
@inline function Base.getindex(
    Xm::UniformFullDimensionalOneStepRelationalMemoset{U,W},
    i_instance::Integer,
    w::W,
    i_metacond::Integer,
    i_relation::Integer,
) where {U,W<:Interval}
    Xm.d[w.x, w.y - 1, i_instance, i_metacond, i_relation]
end
@inline function Base.getindex(
    Xm::UniformFullDimensionalOneStepRelationalMemoset{U,W},
    i_instance::Integer,
    w::W,
    i_metacond::Integer,
    i_relation::Integer,
) where {U,W<:Interval2D}
    Xm.d[w.x.x, w.x.y - 1, w.y.x, w.y.y - 1, i_instance, i_metacond, i_relation]
end

############################################################################################

Base.@propagate_inbounds @inline function Base.setindex!(
    Xm::UniformFullDimensionalOneStepRelationalMemoset{U,OneWorld},
    gamma::U,
    i_instance::Integer,
    w::OneWorld,
    i_metacond::Integer,
    i_relation::Integer,
) where {U}
    Xm.d[i_instance, i_metacond, i_relation] = gamma
end

Base.@propagate_inbounds @inline function Base.setindex!(
    Xm::UniformFullDimensionalOneStepRelationalMemoset{U,<:Interval},
    gamma::U,
    i_instance::Integer,
    w::Interval,
    i_metacond::Integer,
    i_relation::Integer,
) where {U}
    Xm.d[w.x, w.y - 1, i_instance, i_metacond, i_relation] = gamma
end

Base.@propagate_inbounds @inline function Base.setindex!(
    Xm::UniformFullDimensionalOneStepRelationalMemoset{U,<:Interval2D},
    gamma::U,
    i_instance::Integer,
    w::Interval2D,
    i_metacond::Integer,
    i_relation::Integer,
) where {U}
    Xm.d[w.x.x, w.x.y - 1, w.y.x, w.y.y - 1, i_instance, i_metacond, i_relation] = gamma
end

############################################################################################

function hasnans(Xm::UniformFullDimensionalOneStepRelationalMemoset{U,OneWorld}) where {U}
    any(_isnan.(Xm.d))
end
function hasnans(Xm::UniformFullDimensionalOneStepRelationalMemoset{U,<:Interval}) where {U}
    any([
        hasnans(Xm.d[x, y - 1, :, :, :]) for x in 1:size(Xm, 1) for
        y in (x + 1):(size(Xm, 2) + 1)
    ])
end
function hasnans(
    Xm::UniformFullDimensionalOneStepRelationalMemoset{U,<:Interval2D}
) where {U}
    any([
        hasnans(Xm.d[xx, xy - 1, yx, yy - 1, :, :, :]) for xx in 1:size(Xm, 1) for
        xy in (xx + 1):(size(Xm, 2) + 1) for yx in 1:size(Xm, 3) for
        yy in (yx + 1):(size(Xm, 4) + 1)
    ])
end

############################################################################################

function instances(
    Xm::UniformFullDimensionalOneStepRelationalMemoset{U,W,N},
    inds::AbstractVector,
    return_view::Union{Val{true},Val{false}}=Val(false),
) where {U,W<:OneWorld,N}
    UniformFullDimensionalOneStepRelationalMemoset{U,W,N}(
        if return_view == Val(true)
            @view Xm.d[inds, :, :]
        else
            Xm.d[inds, :, :]
        end,
    )
end
function instances(
    Xm::UniformFullDimensionalOneStepRelationalMemoset{U,W,N},
    inds::AbstractVector,
    return_view::Union{Val{true},Val{false}}=Val(false),
) where {U,W<:Interval,N}
    UniformFullDimensionalOneStepRelationalMemoset{U,W,N}(
        if return_view == Val(true)
            @view Xm.d[:, :, inds, :, :]
        else
            Xm.d[:, :, inds, :, :]
        end,
    )
end
function instances(
    Xm::UniformFullDimensionalOneStepRelationalMemoset{U,W,N},
    inds::AbstractVector,
    return_view::Union{Val{true},Val{false}}=Val(false),
) where {U,W<:Interval2D,N}
    UniformFullDimensionalOneStepRelationalMemoset{U,W,N}(
        if return_view == Val(true)
            @view Xm.d[:, :, :, :, inds, :, :]
        else
            Xm.d[:, :, :, :, inds, :, :]
        end,
    )
end

############################################################################################

function concatdatasets(
    Xms::UniformFullDimensionalOneStepRelationalMemoset{U,W,N}...
) where {U,W<:AbstractWorld,N}
    UniformFullDimensionalOneStepRelationalMemoset{U,W,N}(
        cat([Xm.d for Xm in Xms]...; dims=1+2*N)
    )
end

isminifiable(::UniformFullDimensionalOneStepRelationalMemoset) = true

function minify(Xm::UniformFullDimensionalOneStepRelationalMemoset)
    new_d, backmap = minify(Xm.d)
    Xm = UniformFullDimensionalOneStepRelationalMemoset(new_d)
    Xm, backmap
end

############################################################################################

function displaystructure(
    Xm::UniformFullDimensionalOneStepRelationalMemoset{U,W,N};
    indent_str="",
    include_ninstances=true,
    include_nmetaconditions=true,
    include_nrelations=true,
    include_worldtype=missing,
    include_featvaltype=missing,
    include_featuretype=missing,
    include_frametype=missing,
) where {U,W<:AbstractWorld,N}
    padattribute(l, r) =
        string(l) * lpad(r, 32+length(string(r))-(length(indent_str)+2+length(l)))
    pieces = []
    push!(pieces, "$(nameof(typeof(Xm))) ($(memoizationinfo(Xm)), $(humansize(Xm)))")
    if ismissing(include_worldtype) || include_worldtype != worldtype(Xm)
        push!(pieces, "$(padattribute("worldtype:", worldtype(Xm)))")
    end
    if ismissing(include_featvaltype) || include_featvaltype != featvaltype(Xm)
        push!(pieces, "$(padattribute("featvaltype:", featvaltype(Xm)))")
    end
    # if ismissing(include_featuretype) || include_featuretype != featuretype(Xm)
    #     push!(pieces, "$(padattribute("featuretype:", featuretype(Xm)))")
    # end
    # if ismissing(include_frametype) || include_frametype != frametype(Xm)
    #     push!(pieces, "$(padattribute("frametype:", frametype(Xm)))")
    # end
    if include_ninstances
        push!(pieces, "$(padattribute("# instances:", ninstances(Xm)))")
    end
    if include_nmetaconditions
        push!(pieces, "$(padattribute("# metaconditions:", nmetaconditions(Xm)))")
    end
    if include_nrelations
        push!(pieces, "$(padattribute("# relations:", nrelations(Xm)))")
    end
    push!(
        pieces,
        "$(padattribute("size × eltype:", "$(size(innerstruct(Xm))) × $(eltype(innerstruct(Xm)))"))",
    )

    return join(pieces, "\n$(indent_str)├ ", "\n$(indent_str)└ ")
end

############################################################################################
