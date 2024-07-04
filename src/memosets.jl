"""
    abstract type AbstractMemoset{
        W<:AbstractWorld,
        U,
        FT<:AbstractFeature,
        FR<:AbstractFrame,
    } <: AbstractModalLogiset{W,U,FT,FR} end

Abstract type for memoization structures to be used when checking
formulas on logisets.

See also
[`FullMemoset`](@ref),
[`SupportedLogiset`](@ref),
[`AbstractModalLogiset`](@ref).
"""
abstract type AbstractMemoset{
    W<:AbstractWorld,
    U,
    FT<:AbstractFeature,
    FR<:AbstractFrame,
} <: AbstractModalLogiset{W,U,FT,FR} end

function capacity(Xm::AbstractMemoset)
    return error("Please, provide method capacity(::$(typeof(Xm))).")
end

function nmemoizedvalues(Xm::AbstractMemoset)
    return error("Please, provide method nmemoizedvalues(::$(typeof(Xm))).")
end

function nonnothingshare(Xm::AbstractMemoset)
    return (isinf(capacity(Xm)) ? NaN : nmemoizedvalues(Xm)/capacity(Xm))
end

function memoizationinfo(Xm::AbstractMemoset)
    if isinf(capacity(Xm))
        "$(nmemoizedvalues(Xm)) memoized values"
    else
        "$(nmemoizedvalues(Xm))/$(capacity(Xm)) = $(round(nonnothingshare(Xm)*100, digits=2))% memoized values"
    end
end

function displaystructure(
    Xm::AbstractMemoset;
    indent_str = "",
    include_ninstances = true,
    include_worldtype = missing,
    include_featvaltype = missing,
    include_featuretype = missing,
    include_frametype = missing,
)
    padattribute(l,r) = string(l) * lpad(r,32+length(string(r))-(length(indent_str)+2+length(l)))
    pieces = []
    push!(pieces, "")
    if ismissing(include_worldtype) || include_worldtype != worldtype(Xm)
        push!(pieces, "$(padattribute("worldtype:", worldtype(Xm)))")
    end
    if ismissing(include_featvaltype) || include_featvaltype != featvaltype(Xm)
        push!(pieces, "$(padattribute("featvaltype:", featvaltype(Xm)))")
    end
    if ismissing(include_featuretype) || include_featuretype != featuretype(Xm)
        push!(pieces, "$(padattribute("featuretype:", featuretype(Xm)))")
    end
    if ismissing(include_frametype) || include_frametype != frametype(Xm)
        push!(pieces, "$(padattribute("frametype:", frametype(Xm)))")
    end
    if include_ninstances
        push!(pieces, "$(padattribute("# instances:", ninstances(Xm)))")
    end
    # push!(pieces, "$(padattribute("# memoized values:", nmemoizedvalues(Xm)))")

    return "$(nameof(typeof(Xm))) ($(memoizationinfo(Xm)), $(humansize(Xm)))" *
        join(pieces, "\n$(indent_str)├ ", "\n$(indent_str)└ ")
end

############################################################################################

"""
Abstract type for one-step memoization structures for checking formulas of type `⟨R⟩p`;
with these formulas, so-called "one-step" optimizations can be performed.

These structures can be stacked and coupled with *full* memoization structures
(see [`SupportedLogiset`](@ref)).

See [`ScalarOneStepMemoset`](@ref), [`AbstractFullMemoset`](@ref), [`representatives`](@ref).
"""
abstract type AbstractOneStepMemoset{W<:AbstractWorld,U,FT<:AbstractFeature,FR<:AbstractFrame{W}} <: AbstractMemoset{W,U,FT,FR}     end

"""
Abstract type for full memoization structures for checking generic formulas.

These structures can be stacked and coupled with *one-step* memoization structures
(see [`SupportedLogiset`](@ref)).

See [`AbstractOneStepMemoset`](@ref), [`FullMemoset`](@ref).
"""
abstract type AbstractFullMemoset{W<:AbstractWorld,U,FT<:AbstractFeature,FR<:AbstractFrame{W}} <: AbstractMemoset{W,U,FT,FR}     end

############################################################################################

# # Examples
# TODO add example showing that checking is faster when using this structure.
"""
A generic, full memoization structure that works for any *crisp* logic;
For each instance of a dataset,
this structure associates formulas to the set of worlds where the
formula holds; it was introduced by Emerson-Clarke for the
well-known model checking algorithm for CTL*.

See also
[`SupportedLogiset`](@ref),
[`AbstractMemoset`](@ref),
[`AbstractModalLogiset`](@ref).
"""
struct FullMemoset{
    W<:AbstractWorld,
    D<:AbstractVector{<:AbstractDict{<:Formula,<:Worlds{W}}},
} <: AbstractFullMemoset{W,U where U,FT where FT<:AbstractFeature,FR where FR<:AbstractFrame{W}}

    d :: D

    function FullMemoset{W,D}(
        d::D
    ) where {W,D<:AbstractVector{<:AbstractDict{<:Formula,<:Union{<:AbstractWorlds{W},Nothing}}}}
        new{W,D}(d)
    end

    function FullMemoset(
        d::D
    ) where {W,D<:AbstractVector{<:AbstractDict{<:Formula,<:Union{<:AbstractWorlds{W},Nothing}}}}
        new{W,D}(d)
    end

    function FullMemoset(
        X::AbstractModalLogiset{W,U,FT,FR},
        perform_initialization = false,
    ) where {W,U,FT<:AbstractFeature,FR<:AbstractFrame{W}}
        d = [ThreadSafeDict{SyntaxTree,Worlds{W}}() for i_instance in 1:ninstances(X)]
        D = typeof(d)
        FullMemoset{W,D}(d)
    end
end

ninstances(Xm::FullMemoset)      = length(Xm.d)

capacity(Xm::FullMemoset)        = Inf
nmemoizedvalues(Xm::FullMemoset) = sum(length.(Xm.d))

@inline function Base.haskey(
    Xm           :: FullMemoset{W},
    i_instance   :: Integer,
    f            :: Formula,
) where {W<:AbstractWorld}
    haskey(Xm.d[i_instance], f)
end

@inline function Base.getindex(
    Xm           :: FullMemoset{W},
    i_instance   :: Integer,
) where {W<:AbstractWorld}
    Xm.d[i_instance]
end
@inline function Base.getindex(
    Xm           :: FullMemoset{W},
    i_instance   :: Integer,
    f            :: Formula,
) where {W<:AbstractWorld}
    Xm.d[i_instance][f]
end
@inline function Base.setindex!(
    Xm           :: FullMemoset{W},
    i_instance   :: Integer,
    f            :: Formula,
    ws           :: Worlds{W},
) where {W}
    Xm.d[i_instance][f] = ws
end

function check(
    f::Formula,
    i::SoleLogics.LogicalInstance{<:FullMemoset{W}},
    w::W;
    kwargs...
) where {W<:AbstractWorld}
    Xm, i_instance = SoleLogics.splat(i)
    w in Base.getindex(Xm, i_instance, f)
end

function instances(
    Xm::FullMemoset,
    inds::AbstractVector,
    return_view::Union{Val{true},Val{false}} = Val(false);
    kwargs...
)
    FullMemoset(if return_view == Val(true) @view Xm.d[inds] else Xm.d[inds] end)
end

function concatdatasets(Xms::FullMemoset...)
    FullMemoset(vcat([Xm.d for Xm in Xms]...))
end

usesfullmemo(::FullMemoset) = true
fullmemo(Xm::FullMemoset) = Xm

hasnans(::FullMemoset) = false

function displaystructure(
    Xm::FullMemoset;
    indent_str = "",
    include_ninstances = true,
    include_worldtype = missing,
    include_featvaltype = missing,
    include_featuretype = missing,
    include_frametype = missing,
)
    padattribute(l,r) = string(l) * lpad(r,32+length(string(r))-(length(indent_str)+2+length(l)))
    pieces = []
    push!(pieces, "")
    if ismissing(include_worldtype) || include_worldtype != worldtype(Xm)
        push!(pieces, "$(padattribute("worldtype:", worldtype(Xm)))")
    end
    if include_ninstances
        push!(pieces, "$(padattribute("# instances:", ninstances(Xm)))")
    end
    # push!(pieces, "$(padattribute("# memoized values:", nmemoizedvalues(Xm)))")

    return "$(nameof(typeof(Xm))) ($(memoizationinfo(Xm)), $(humansize(Xm)))" *
        join(pieces, "\n$(indent_str)├ ", "\n$(indent_str)└ ")
end

# Base.size(::FullMemoset) = ()
