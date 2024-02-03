using UniqueVectors
import Base: in, findfirst

_in(item, uv) = Base.in(item, uv)
_findfirst(p::UniqueVectors.EqualTo, uv) = Base.findfirst(p, uv)

function Base.in(item, uv::UniqueVector{<:Union{AbstractFeature,AbstractCondition,AbstractRelation}})
    haskey(uv.lookup, item)
end

function Base.in(item::T, uv::UniqueVector{T}) where {T<:Union{AbstractFeature,AbstractCondition,AbstractRelation}}
    haskey(uv.lookup, item)
end

function Base.findfirst(p::UniqueVectors.EqualTo, uv::UniqueVector{<:Union{AbstractFeature,AbstractCondition,AbstractRelation}})
    get(uv.lookup, p.x, nothing)
end

_in(item, uv::UniqueVector{<:Union{AbstractFeature,AbstractCondition,AbstractRelation}}) = haskey(uv.lookup, item)
_findfirst(p::UniqueVectors.EqualTo, uv::UniqueVector{<:Union{AbstractFeature,AbstractCondition,AbstractRelation}}) = get(uv.lookup, p.x, nothing)

# TODO complete and explain
"""
A full memoization structure used for checking formulas of scalar conditions on
datasets with scalar features. This structure is the equivalent to [`FullMemoset`](@ref),
but with scalar features some important optimizations can be done.

See also
[`FullMemoset`](@ref),
[`SupportedLogiset`](@ref),
[`AbstractLogiset`](@ref).
"""
struct ScalarChainedMemoset{
    W<:AbstractWorld,
    U,
    FR<:AbstractFrame{W},
    D<:AbstractVector{<:AbstractDict{<:Formula,U}},
} <: AbstractFullMemoset{W,U,FT where FT<:AbstractFeature,FR}

    d :: D

    function ScalarChainedMemoset{W,U,FR,D}(
        d::D
    ) where {W<:AbstractWorld,U,FR<:AbstractFrame{W},D<:AbstractVector{<:AbstractDict{<:Formula,U}}}
        new{W,U,FR,D}(d)
    end

    function ScalarChainedMemoset(
        X::AbstractLogiset{W,U,FT,FR},
        # perform_initialization = false,
    ) where {W<:AbstractWorld,U,FT<:AbstractFeature,FR<:AbstractFrame{W}}
        d = [ThreadSafeDict{SyntaxTree,Worlds{W}}() for i_instance in 1:ninstances(X)]
        D = typeof(d)
        ScalarChainedMemoset{W,U,FR,D}(d)
    end
end

ninstances(Xm::ScalarChainedMemoset)      = length(Xm.d)

capacity(Xm::ScalarChainedMemoset)        = Inf
nmemoizedvalues(Xm::ScalarChainedMemoset) = sum(length.(Xm.d))


@inline function Base.haskey(
    Xm           :: ScalarChainedMemoset,
    i_instance   :: Integer,
    f            :: Formula,
)
    haskey(Xm.d[i_instance], f)
end

@inline function Base.getindex(
    Xm           :: ScalarChainedMemoset,
    i_instance   :: Integer,
)
    Xm.d[i_instance]
end
@inline function Base.getindex(
    Xm           :: ScalarChainedMemoset,
    i_instance   :: Integer,
    f            :: Formula,
)
    Xm.d[i_instance][f]
end
@inline function Base.setindex!(
    Xm           :: ScalarChainedMemoset,
    i_instance   :: Integer,
    f            :: Formula,
    threshold    :: U,
) where {U}
    Xm.d[i_instance][f] = threshold
end

function check(
    f::Formula,
    i::SoleLogics.LogicalInstance{<:ScalarChainedMemoset{W}},
    w::W;
    kwargs...
) where {W<:AbstractWorld}
    Xm, i_instance = SoleLogics.splat(i)
    return error("TODO implement chained threshold checking algorithm.")
end

function instances(
    Xm::ScalarChainedMemoset,
    inds::AbstractVector{<:Integer},
    return_view::Union{Val{true},Val{false}} = Val(false);
    kwargs...
)
    ScalarChainedMemoset(if return_view == Val(true) @view Xm.d[inds] else Xm.d[inds] end)
end

function concatdatasets(Xms::ScalarChainedMemoset...)
    ScalarChainedMemoset(vcat([Xm.d for Xm in Xms]...))
end

usesfullmemo(::ScalarChainedMemoset) = true
fullmemo(Xm::ScalarChainedMemoset) = Xm

hasnans(::ScalarChainedMemoset) = false
