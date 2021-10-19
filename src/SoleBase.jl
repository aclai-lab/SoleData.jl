module SoleBase

using DataFrames
using ScientificTypes

import ScientificTypes: show
import Base: eltype, isempty, iterate, map, getindex, length
import Base: firstindex, lastindex, ndims, size, show
import Base: ==, ≈

# -------------------------------------------------------------
# exports

# export types
export MultiFrameDataset

# constructors
export multiframedataset

# information gathering
export instance, ninstances, frame, nframes, attributes, nattributes, dimension, spareattributes

# instance manipulation
export addinstance!, removeinstance!, keeponlyinstances!

# frame manipulation
export addframe!, removeframe!, addattribute_toframe!, removeattribute_fromframe!
export newframe!, dropattributes!, dropframe!

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

# include("data/types.jl")
include("data/dataset.jl")
# include("data/testing.jl")

end # module
