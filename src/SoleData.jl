
__precompile__()

module SoleData

using DataFrames
using ScientificTypes
using DataStructures
using Statistics
using Catch22
using CSV
using Random
using Reexport
using SoleBase
using SoleBase: AbstractDataset, slicedataset

@reexport using DataFrames

import Base: eltype, isempty, iterate, map, getindex, length
import Base: firstindex, lastindex, ndims, size, show, summary
import Base: isequal, isapprox
import Base: ==, ≈
import Base: in, issubset, setdiff, setdiff!, union, union!, intersect, intersect!
import Base: ∈, ⊆, ∪, ∩
import DataFrames: describe
import ScientificTypes: show
import SoleBase: instances, ninstances

# -------------------------------------------------------------
# exports

# export types
export AbstractDataset, AbstractMultiModalDataset
export MultiModalDataset
export AbstractLabeledMultiModalDataset
export LabeledMultiModalDataset

# information gathering
export instance, ninstances
export modality, nmodalities
export variables, nvariables, dimension, sparevariables, hasvariables
export variableindex
export isapproxeq, ≊
export isapprox

export eachinstance, eachmodality, slicedataset

# filesystem
export datasetinfo, loaddataset, savedataset

# instance manipulation
export pushinstances!, deleteinstances!, keeponlyinstances!

# variable manipulation
export insertvariables!, dropvariables!, keeponlyvariables!, dropsparevariables!

# modality manipulation
export addmodality!, removemodality!, addvariable_tomodality!, removevariable_frommodality!
export insertmodality!, dropmodalities!

# labels manipulation
export nlabelingvariables, label, labels, labeldomain, setaslabelinging!, removefromlabels!, joinlabels!

# re-export from DataFrames
export describe
# re-export from ScientificTypes
export schema

# -------------------------------------------------------------
# Abbreviations
const DF = DataFrames

# -------------------------------------------------------------
# Abstract types


"""
Abstract supertype for all multimodal datasets.

A concrete multimodal dataset should always provide accessors
[`data`](@ref), to access the underlying tabular structure (e.g., `DataFrame`) and
[`grouped_variables`](@ref), to access the grouping of variables
(a vector of vectors of column indices).
"""
abstract type AbstractMultiModalDataset <: AbstractDataset end

"""
Abstract supertype for all labelled multimodal datasets (used in supervised learning).

As any multimodal dataset, any concrete labeled multimodal dataset should always provide
the accessors [`data`](@ref), to access the underlying tabular structure (e.g., `DataFrame`) and
[`grouped_variables`](@ref), to access the grouping of variables.
In addition to these, implementations are required for
[`labeling_variables`](@ref), to access the indices of the labeling variables.

See also [`AbstractMultiModalDataset`](@ref).
"""
abstract type AbstractLabeledMultiModalDataset <: AbstractMultiModalDataset end

# -------------------------------------------------------------
# AbstractMultiModalDataset - accessors
#
# Inspired by the "Delegation pattern" of "Design Patterns and Best Practices with
# Julia" Chap. 5 by Tom KwongHands-On

"""
    grouped_variables(amd)::Vector{Vector{Int}}

Return the indices of the variables grouped by modality, of an `AbstractMultiModalDataset`.
The grouping describes how the different modalities are composed from the underlying
`AbstractDataFrame` structure.

See also [`data`](@ref), [`AbstractMultiModalDataset`](@ref).
"""
function grouped_variables(amd::AbstractMultiModalDataset)::Vector{Vector{Int}}
    return error("`grouped_variables` accessor not implemented for type "
        * string(typeof(amd))) * "."
end

"""
    data(amd)::AbstractDataFrame

Return the structure that underlies an `AbstractMultiModalDataset`.

See also [`grouped_variables`](@ref), [`AbstractMultiModalDataset`](@ref).
"""
function data(amd::AbstractMultiModalDataset)::AbstractDataFrame
    return error("`data` accessor not implemented for type "
        * string(typeof(amd))) * "."
end

# -------------------------------------------------------------
# AbstractLabeledMultiModalDataset - accessors

"""
    labeling_variables(lmd)::Vector{Int}

Return the indices of the labelling variables, of the `AbstractLabeledMultiModalDataset`.
with respect to the underlying `AbstractDataFrame` structure (see [`data`](@ref)).

See also [`grouped_variables`](@ref), [`AbstractLabeledMultiModalDataset`](@ref).
"""
function labeling_variables(lmd::AbstractLabeledMultiModalDataset)::Vector{Int}
    return error("`labeling_variables` accessor not implemented for type " *
        string(typeof(lmd)))
end

Base.summary(amd::AbstractMultiModalDataset) = string(length(amd), "-modality ", typeof(amd))
Base.summary(io::IO, amd::AbstractMultiModalDataset) = print(stdout, summary(amd))

include("utils.jl")
include("schema.jl")
include("describe.jl")
include("iterable.jl")
include("comparison.jl")
include("set.jl")
include("variables.jl")
include("instances.jl")
include("modalities.jl")

include("MultiModalDataset.jl")

include("labels.jl")
include("LabeledMultiModalDataset.jl")

include("filesystem.jl")

include("dimensionality.jl")

export get_instance, concat_datasets, max_channel_size

include("dimensional-dataset.jl")

end # module
