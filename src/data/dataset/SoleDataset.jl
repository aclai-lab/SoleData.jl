module SoleDataset

using DataFrames
using ScientificTypes
using DataStructures
using Statistics
using Catch22
using CSV

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
export AbstractLabeledMultiFrameDataset
export LabeledMultiFrameDataset

# information gathering
export instance, ninstances
export frame, nframes
export attributes, nattributes, dimension, spareattributes, hasattributes, hasattributess
export attributeindex
export isapproxeq, ≊
export isapprox

# filesystem
export datasetinfo, loaddataset, savedataset

# instance manipulation
export pushinstances!, deleteinstances!, keeponlyinstances!

# attribute manipulation
export insertattributes!, dropattributes!, keeponlyattributes!, dropspareattributes!

# frame manipulation
export addframe!, removeframe!, addattribute_toframe!, removeattribute_fromframe!
export insertframe!, dropframe!

# labels manipulation
export nlabels, label, labels, labeldomain, setaslabel!, removefromlabels!, spareattributes

# re-export from DataFrames
export describe
# re-export from ScientificTypes
export schema

# -------------------------------------------------------------
# Abbreviations
const ST = ScientificTypes
const DF = DataFrames

"""
Resolve these todos..

GENERAL TODOs:
* find a unique template to return, for example, AssertionError messages.
    * a solution could be to have a module SoleDiagnosis to have a set of templates for
    warnings, loggers, errors, exceptions, etc..
* control that `add`/`remove` and `insert`/`drop` are coherent; done?
* use `return` at the end of the functions
* consider to add names to frames
* add Logger; in particular, it should be nice to have a module SoleLogger(s)
* consider making enforcing class type check (ex: classes should not be of scitype Continuous)
* enforce class (and regressor) attributes not be part any frame
"""

# -------------------------------------------------------------
# Abstract types

"""
Abstract supertype for all datasets.
"""
abstract type AbstractDataset end


"""
Abstract supertype for all multiframe datasets.

A concrete MultiFrameDataset should always provide accessors [`descriptor`](@ref), to
access the frame descriptor, and [`data`](@ref), to access the inner data.
"""
abstract type AbstractMultiFrameDataset <: AbstractDataset end

"""
Abstract supertype for all multiframe datasets for supervised learning.

A concrete LabeledFrameDataset should always provide accessors [`descriptor`](@ref), to
access the frame descriptor, and [`data`](@ref), to access the inner data just like any
other MultiFrameDataset. In addition to these it is required an implementation for accessors
[`labels_descriptor`](@ref), to access the labels descriptor and [`dataset`](@ref), to
access the MultiFrameDataset (forgetting about the labels).
"""
abstract type AbstractLabeledMultiFrameDataset <: AbstractMultiFrameDataset end

# -------------------------------------------------------------
# AbstractMultiFrameDataset - accessors
#
# Inspired by the "Delegation pattern" of "Hands-On Design Patterns and Best Practices with
# Julia" Chap. 5 by Tom Kwong

function descriptor(amfd::AbstractMultiFrameDataset)
    return error("`descriptor` accessor not implemented for type "
        * string(typeof(amfd)))
end
frame_descriptor(amfd::AbstractMultiFrameDataset) = descriptor(amfd)
function data(amfd::AbstractMultiFrameDataset)
    return error("`data` accessor not implemented for type "
        * string(typeof(amfd)))
end

# -------------------------------------------------------------
# AbstractClassificationMultiFrameDataset - accessors

function labels_descriptor(lmfd::AbstractLabeledMultiFrameDataset)
    return error("`labels_descriptor` accessor not implemented for type " *
        string(typeof(lmfd)))
end
function dataset(lmfd::AbstractLabeledMultiFrameDataset)
    return error("`dataset` accessor not implemented for type $(string(typeof(lmfd)))")
end

# -------------------------------------------------------------
# AbstractMultiFrameDataset - infos

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
    return dimension(frame(mfd, i); kwargs...)
end
function dimension(mfd::AbstractMultiFrameDataset; kwargs...)
    return Tuple([dimension(frame; kwargs...) for frame in mfd])
end
dimension(dfc::DF.DataFrameColumns; kwargs...) = dimension(DataFrame(dfc); kwargs...)

include("filesystem.jl")
include("iterable.jl")
include("utils.jl")
include("comparison.jl")
include("set.jl")
include("attributes.jl")
include("instances.jl")
include("frames.jl")
include("MultiFrameDataset.jl")

include("LabeledMultiFrameDataset.jl")
include("labels.jl")

include("schema.jl")
include("describe.jl")

end # module
