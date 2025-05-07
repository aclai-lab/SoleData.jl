module DimensionalDatasets

import Base: size, show, getindex, iterate, length, push!, eltype

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
import MultiData: instance, get_instance, displaystructure, concatdatasets
import MultiData: displaystructure
import MultiData: dimensionality


using SoleData
using SoleBase

using SoleData: Aggregator, AbstractCondition
using SoleData: UnivariateScalarAlphabet, UnionAlphabet, MultivariateScalarAlphabet
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
import SoleData: get_instance, ninstances, nvariables, eltype, varnames

using SoleData: scalarlogiset
using SoleData: VariableId
############################################################################################

export UniformFullDimensionalLogiset

import SoleData: AbstractUniformFullDimensionalLogiset,
      maxchannelsize,
      channelsize,
      dimensionality,
      frame

# Frame-specific logisets
include("logiset.jl")

import SoleData: AbstractUniformFullDimensionalOneStepRelationalMemoset,
      innerstruct,
      nmemoizedvalues
include("onestep-memosets.jl")

export initlogiset, ninstances, maxchannelsize, worldtype, dimensionality, allworlds, featvalue

export nvariables

include("computefeature.jl")

# Bindings for interpreting dataset structures as logisets
include("logiseeds/abstractdimensionaldataset.jl")
include("logiseeds/abstractdataframe.jl")
include("logiseeds/namedtuple.jl")

using SoleLogics: Full0DFrame, Full1DFrame, Full2DFrame
using SoleLogics: X, Y, Z

# Representatives for dimensional frames
include("representatives/Full0DFrame.jl")
include("representatives/Full1DFrame.jl")
include("representatives/Full1DFrame+IA.jl")
include("representatives/Full1DFrame+RCC.jl")
include("representatives/Full2DFrame.jl")

end
