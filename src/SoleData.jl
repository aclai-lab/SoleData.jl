
__precompile__()

module SoleData

using Reexport
using SoleBase
using SoleBase: AbstractDataset, slicedataset

using DataFrames
using MultiData

const DF = DataFrames
const MD = MultiData

############################################################################################
############################################################################################
############################################################################################

export minify, isminifiable

# Minification interface for lossless data compression
include("utils/minify.jl")

include("MLJ-utils.jl")

include("example-datasets.jl")


export atoms

export slicedataset, concatdatasets

export World, Feature, featvalue
export SupportedLogiset, nmemoizedvalues
export ExplicitBooleanLogiset, checkcondition
export ExplicitLogiset, ScalarCondition

export ninstances
export MultiLogiset, modality, nmodalities, modalities

export scalarlogiset

export initlogiset, maxchannelsize, worldtype, dimensionality, frame, featvalue, nvariables

export FullDimensionalFrame

using ThreadSafeDicts

using SoleLogics
import SoleLogics: frame

using SoleLogics: OneWorld, Interval, Interval2D
using SoleLogics: Full0DFrame, Full1DFrame, Full2DFrame
using SoleLogics: X, Y, Z
using SoleLogics: AbstractWorld, IdentityRel
import SoleLogics: syntaxstring

using MultiData: _isnan
import MultiData: maxchannelsize, channelsize
import MultiData: hasnans, nvariables
import MultiData: instance, get_instance, concatdatasets
import MultiData: displaystructure
import MultiData: dimensionality

import MultiData: ninstances
import MultiData: _isnan
import MultiData: hasnans, instances, concatdatasets
import MultiData: displaystructure

# TODO fix
import MultiData: eachinstance
import Tables: istable, rows, subset, getcolumn, columnnames, rowaccess


export AbstractFeature, Feature

export UnivariateNamedFeature,
        UnivariateFeature

export computefeature

export parsefeature

export VarFeature,
        UnivariateMin, UnivariateMax,
        UnivariateSoftMin, UnivariateSoftMax,
        MultivariateFeature

# Features to be computed on worlds of dataset instances
include("features.jl")

export ScalarMetaCondition

export MixedCondition, CanonicalCondition, canonical_geq, canonical_leq

export canonical_geq_95, canonical_geq_90, canonical_geq_85, canonical_geq_80, canonical_geq_75, canonical_geq_70, canonical_geq_60,
       canonical_leq_95, canonical_leq_90, canonical_leq_85, canonical_leq_80, canonical_leq_75, canonical_leq_70, canonical_leq_60

export parsecondition

export ValueCondition, FunctionalCondition
export parsecondition

# Conditions on the features, to be wrapped in Atom's
include("conditions.jl")

# Templates for formulas of conditions (e.g., templates for ⊤, p, ⟨R⟩p, etc.)
include("templated-formulas.jl")

export accessibles, allworlds, representatives

# Interface for representative accessibles, for optimized model checking on specific frames
include("representatives.jl")

export ninstances, featvalue, displaystructure, isminifiable, minify

# Logical datasets, where the instances are Kripke structures with conditional alphabets
include("logiset.jl")

include("memosets.jl")

include("supported-logiset.jl")

export MultiLogiset, eachmodality, modality, nmodalities

export MultiFormula, modforms

# Multi-frame version of logisets, for representing multimodal datasets
include("multilogiset.jl")

export check

# Model checking algorithms for logisets and multilogisets
include("check.jl")

export nfeatures

include("scalar/main.jl")

# Tables interface for logiset's, so that it can be integrated with MLJ
include("MLJ-interface.jl")

export initlogiset, ninstances, maxchannelsize, worldtype, dimensionality, allworlds, featvalue

export nvariables

include("dimensional-structures/main.jl")

function default_relmemoset_type(X::AbstractLogiset)
    # if X isa DimensionalDatasets.UniformFullDimensionalLogiset
    frames = [SoleLogics.frame(X, i_instance) for i_instance in 1:ninstances(X)]
    if allequal(frames) # Uniform logiset
        _frame = first(unique(frames))
        if _frame isa DimensionalDatasets.FullDimensionalFrame
            DimensionalDatasets.UniformFullDimensionalOneStepRelationalMemoset
        else
            # error("Unknown frame of type $(typeof(_frame)).")
            ScalarOneStepRelationalMemoset
        end
    else
        ScalarOneStepRelationalMemoset
    end
end

function default_onestep_memoset_type(X::AbstractLogiset)
    if featvaltype(X) <: Real
        ScalarOneStepMemoset
    else
        OneStepMemoset
    end
end
function default_full_memoset_type(X::AbstractLogiset)
    # if ...
    #     ScalarChainedMemoset TODO
    # else
        FullMemoset
    # end
end

using .DimensionalDatasets: OneWorld, Interval, Interval2D
using .DimensionalDatasets: IARelations
using .DimensionalDatasets: IA2DRelations
using .DimensionalDatasets: identityrel
using .DimensionalDatasets: globalrel

include("deprecate.jl")

end # module
