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
abstract type AbstractMemoset{W<:AbstractWorld,U,FT<:AbstractFeature,FR<:AbstractFrame} <:
              AbstractModalLogiset{W,U,FT,FR} end

"""
Return the capacity of a memoset, that is, the number of memoizable values (if finite).

See also
[`AbstractMemoset`](@ref).
"""
function capacity(Xm::AbstractMemoset)
    return error("Please, provide method capacity(::$(typeof(Xm))).")
end

"""
Return the number of memoized values in a memoset.

See also
[`AbstractMemoset`](@ref).
"""
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
    indent_str="",
    include_ninstances=true,
    include_worldtype=missing,
    include_featvaltype=missing,
    include_featuretype=missing,
    include_frametype=missing,
)
    padattribute(l, r) =
        string(l) * lpad(r, 32+length(string(r))-(length(indent_str)+2+length(l)))
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
abstract type AbstractOneStepMemoset{
    W<:AbstractWorld,U,FT<:AbstractFeature,FR<:AbstractFrame{W}
} <: AbstractMemoset{W,U,FT,FR} end

"""
Abstract type for full memoization structures for checking generic formulas.

These structures can be stacked and coupled with *one-step* memoization structures
(see [`SupportedLogiset`](@ref)).

See [`AbstractOneStepMemoset`](@ref), [`FullMemoset`](@ref).
"""
abstract type AbstractFullMemoset{
    W<:AbstractWorld,U,FT<:AbstractFeature,FR<:AbstractFrame{W}
} <: AbstractMemoset{W,U,FT,FR} end
