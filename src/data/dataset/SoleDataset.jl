module SoleDataset

using DataFrames
using ScientificTypes

import ScientificTypes: show
import Base: eltype, isempty, iterate, map, getindex, length
import Base: firstindex, lastindex, ndims, size, show
import Base: isequal, isapprox
import Base: ==, ≈
import Base: in, issubset, setdiff, setdiff!, union, union!, intersect, intersect!
import Base: ∈, ⊆, ∪, ∩

# -------------------------------------------------------------
# exports

# export types
export AbstractDataset, AbstractMultiFrameDataset
export MultiFrameDataset

# information gathering
export instance, ninstances
export frame, nframes
export attributes, nattributes, dimension, spareattributes, hasattribute, hasattributes
export attributeindex
export isapproxeq, ≊

# instance manipulation
export pushinstance!, deleteinstance!, keeponlyinstances!

# attribute manipulation
export insertattribute!, dropattribute!, dropattributes!, keeponlyattributes!
export dropspareattributes!

# frame manipulation
export addframe!, removeframe!, addattribute_toframe!, removeattribute_fromframe!
export insertframe!, dropframe!

# re-export from DataFrames
export describe
# re-export from ScientificTypes
export schema

# -------------------------------------------------------------
# Abbreviations
# Such abbreviations break things? That is, are exported outside or work only locally within
# the framework?
const ST = ScientificTypes
const DF = DataFrames

"""
GENERAL TODOs:
* find a unique template to return, for example, AssertionError messages.
* control that `add`/`remove` and `insert`/`drop` are coherent.
* use `return` at the end of the functions
* consider to add names to frames
* add Logger; in particular, it should be nice to have a module SoleLogger(s)
* consider making this a `SoleDataset` module to Reexport form `SoleBase`
"""

# -------------------------------------------------------------
# Abstract types

"""
Abstract supertype for all datasets.
"""
abstract type AbstractDataset end


"""
Abstract supertype for all multiframe datasets.

A concrete MultiFrameDatset should always provides accessors [`descriptor`](@ref), to
access the frame descriptor, and [`data`](@ref), to access the inner data.
"""
abstract type AbstractMultiFrameDataset <: AbstractDataset end

# -------------------------------------------------------------
# AbstractMultiFrameDataset - accessors
#
# Inspired by the "Delegation pattern" of "Hands-On Design Patterns and Best Practices with
# Julia" Chap. 5 by Tom Kwong

function descriptor(amfd::AbstractMultiFrameDataset)
    error("`descriptor` accessor not implemented for type " * string(typeof(amfd)))
end
frame_descriptor(amfd::AbstractMultiFrameDataset) = descriptor(amfd)
function data(amfd::AbstractMultiFrameDataset)
    error("`data` accessor not implemented for type " * string(typeof(amfd)))
end

"""
    dimension(df)

Get the dimension of a dataframe `df`.

If the dataframe has attributes of various dimensions `:mixed` is returned.

If the dataframe is empty (no instances) `:empty` is returned.
This behavior can be changed by setting the keyword argument `force`:

- `:no` (default): return `:mixed` in case of mixed dimension
- `:max`: return the greatest dimension
- `:min`: return the lowest dimension
"""
function dimension(df::AbstractDataFrame; force::Symbol = :no)::Union{Symbol,Integer}
    @assert force in [:no, :max, :min] "`force` can be either :no, :max or :min"

    if nrow(df) == 0
        return :empty
    end

    dims = [maximum(x -> isa(x, AbstractVector) ? ndims(x) : 0, [inst for inst in c])
        for c in eachcol(df)]

    if all(y -> y == dims[1], dims)
        return dims[1]
    elseif force == :max
        return max(dims...)
    elseif force == :min
        return min(dims...)
    else
        return :mixed
    end
end
function dimension(mfd::AbstractMultiFrameDataset, i::Integer; kwargs...)
    dimension(frame(mfd, i); kwargs...)
end
function dimension(mfd::AbstractMultiFrameDataset; kwargs...)
    Tuple([dimension(frame; kwargs...) for frame in mfd])
end
dimension(dfc::DF.DataFrameColumns; kwargs...) = dimension(DataFrame(dfc); kwargs...)


include("iterable.jl")
include("utils.jl")
include("comparison.jl")
include("set.jl")
include("attributes.jl")
include("instances.jl")
include("frames.jl")
include("MultiFrameDataset.jl")

# -------------------------------------------------------------
# schema

function ST.schema(mfd::AbstractMultiFrameDataset; kwargs...)
    results = ST.Schema[]
    for frame in mfd
        push!(results, ST.schema(frame, kwargs...))
    end

    return results
end
function ST.schema(mfd::AbstractMultiFrameDataset, i::Integer; kwargs...)
    ST.schema(frame(mfd, i); kwargs...)
end

# -------------------------------------------------------------
# describe

function DF.describe(mfd::AbstractMultiFrameDataset; kwargs...)
    results = DataFrame[]
    for frame in mfd
        push!(results, DF.describe(frame; kwargs...))
    end
    return results
end
function DF.describe(mfd::AbstractMultiFrameDataset, i::Integer; kwargs...)
    DF.describe(frame(mfd, i), kwargs...)
end

end # module
