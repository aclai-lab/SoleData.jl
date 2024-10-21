module DimensionalDatasets

import Base: size, show, getindex, iterate, length, push!, eltype

using ThreadSafeDicts

# TODO remove
using SoleData: _in, _findfirst


using BenchmarkTools
using ProgressMeter
using UniqueVectors

using SoleBase

using SoleLogics
using SoleLogics: Formula, AbstractWorld, AbstractRelation
using SoleLogics: AbstractFrame, AbstractDimensionalFrame, FullDimensionalFrame
import SoleLogics: worldtype, accessibles, allworlds, alphabet

using SoleData
using MultiData: _isnan
import MultiData: maxchannelsize, channelsize
import MultiData: hasnans, nvariables
import MultiData: instance, get_instance, concatdatasets
import MultiData: displaystructure
import MultiData: dimensionality


using SoleData
using SoleBase

using SoleData: Aggregator, AbstractCondition
using SoleData: UnivariateScalarAlphabet, UnionAlphabet
using SoleData: AbstractModalLogiset, AbstractMultiModalFrame
using SoleData: MultiLogiset, AbstractModalLogiset
using SoleData: apply_test_operator, existential_aggregator, aggregator_bottom, aggregator_to_binary

import SoleData: features, nfeatures
using SoleData: worldtype, featvaltype, featuretype, frametype

import SoleData: representatives, ScalarMetaCondition, ScalarCondition, ObliqueScalarCondition, featvaltype
import SoleData: ninstances, nrelations, nfeatures, check, instances, minify
import SoleData: displaystructure, frame
import SoleData: alphabet, isminifiable

import SoleData: nmetaconditions
import SoleData: capacity, nmemoizedvalues
using SoleData: memoizationinfo

import SoleData: worldtype, allworlds, featvalue, featvalue!
import SoleData: featchannel, readfeature, featvalues!, allfeatvalues
import SoleData: get_instance, ninstances, nvariables, eltype

using SoleData: scalarlogiset
using SoleData: VariableId
############################################################################################

export UniformFullDimensionalLogiset

# Frame-specific logisets
include("logiset.jl")

include("onestep-memosets.jl")

export initlogiset, ninstances, maxchannelsize, worldtype, dimensionality, allworlds, featvalue

export nvariables

include("computefeature.jl")

# Bindings for interpreting dataset structures as logisets
include("dataset-bindings.jl")

using SoleLogics: Full0DFrame, Full1DFrame, Full2DFrame
using SoleLogics: X, Y, Z

# Representatives for dimensional frames
include("representatives/Full0DFrame.jl")
include("representatives/Full1DFrame.jl")
include("representatives/Full1DFrame+IA.jl")
include("representatives/Full1DFrame+RCC.jl")
include("representatives/Full2DFrame.jl")

end
