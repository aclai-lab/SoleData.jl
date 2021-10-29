module SoleBase

using DataFrames
using ScientificTypes
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
export MultiFrameDataset

# information gathering
export instance, ninstances
export frame, nframes
export attributes, nattributes, dimension, spareattributes, hasattribute, hasattributes
export attributeindex
export isapproxeq, ≊

# instance manipulation
export addinstance!, removeinstance!, keeponlyinstances!

# attribute manipulation
export insertattribute!, dropattribute!, dropattributes!, keeponlyattributes!
export dropspareattributes!

# frame manipulation
export addframe!, removeframe!, addattribute_toframe!, removeattribute_fromframe!
export newframe!, dropframe!

# re-export from DataFrames
export describe
# re-export from ScientificTypes
export schema

# loading dataset
export loaddataset

# -------------------------------------------------------------
# Abbreviations
# Such abbreviations break things? That is, are exported outside or work only locally within
# the framework?
const ST = ScientificTypes
const DF = DataFrames

# include("data/types.jl")
include("data/dataset.jl")

include("data/load-dataset.jl")

end # module
