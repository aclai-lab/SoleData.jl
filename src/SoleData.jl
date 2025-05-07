module SoleData

using Reexport
using SoleBase
using SoleBase: AbstractDataset, slicedataset
import SoleBase: eachinstance

using DataFrames
using MultiData
using MultiData: AbstractDimensionalDataset

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
export ExplicitBooleanModalLogiset, checkcondition
export ExplicitModalLogiset, ScalarCondition

export ninstances
export MultiLogiset, modality, nmodalities, modalities

export scalarlogiset

export initlogiset, maxchannelsize, worldtype, dimensionality, frame, featvalue, nvariables

export FullDimensionalFrame

@reexport using SoleLogics
import SoleLogics: frame

using SoleLogics: value

using SoleLogics: OneWorld
using SoleLogics: Point, Point1D, Point2D, Point3D
using SoleLogics: Interval, Interval2D

using SoleLogics: Full0DFrame, Full1DFrame, Full2DFrame
using SoleLogics: X, Y, Z
using SoleLogics: AbstractWorld, IdentityRel
import SoleLogics: syntaxstring

using MultiData: _isnan
import MultiData: maxchannelsize, channelsize
import MultiData: hasnans, nvariables
import MultiData: instance, get_instance, displaystructure, concatdatasets
import MultiData: displaystructure
import MultiData: dimensionality

import MultiData: ninstances
import MultiData: _isnan
import MultiData: hasnans, instances, concatdatasets
import MultiData: displaystructure

import Tables: istable, rows, subset, getcolumn, columnnames, rowaccess

export AbstractFeature, parsefeature

# Features to be computed on worlds of dataset instances
include("types/features.jl")

export parsecondition

# Conditions on the features, to be wrapped in Atom's
include("types/conditions.jl")

export accessibles, allworlds, representatives

# Interface for representative accessibles, for optimized model checking on specific frames
include("types/representatives.jl")

export ninstances, eachinstance
export featvalue, displaystructure, isminifiable, minify
export alphabet
export features, nfeatures

# Logical datasets, where the instances are logical interpretations on scalar alphabets
include("types/logiset.jl")

# Logical datasets, where the instances are Kripke structure on scalar alphabets
include("types/modal-logiset.jl")

# Memoization structures for logisets
include("types/memoset.jl")

export check

# Model checking algorithms for logisets and multilogisets
include("check.jl")

################################################################################
################################################################################
################################################################################

export ScalarMetaCondition

export MixedCondition


export ValueCondition, FunctionalCondition


export Feature

export UnivariateNamedFeature,
        UnivariateFeature,
        VariableValue

export VarFeature,
        VariableMin, VariableMax, i_variable, featurename,
        VariableSoftMin, VariableSoftMax,
        MultivariateFeature


include("utils/features.jl")


export MultiLogiset, eachmodality, modality, nmodalities
export MultiFormula, modforms

# Multi-frame version of logisets, for representing multimodal datasets
include("utils/multilogiset.jl")


export @scalarformula

include("scalar/main.jl")

export initlogiset, ninstances, maxchannelsize, worldtype, dimensionality, allworlds, featvalue

export nvariables

include("types/dimensional-structures.jl")

include("dimensional-structures/main.jl")


################################################################################

include("utils/conditions.jl")

# Templates for formulas of conditions (e.g., templates for ⊤, p, ⟨R⟩p, etc.)
include("utils/templated-formulas.jl")

include("utils/modal-logiset.jl")

include("utils/memoset.jl")

include("utils/supported-logiset.jl")

function default_relmemoset_type(X::AbstractModalLogiset)
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

function default_onestep_memoset_type(X::AbstractModalLogiset)
    if featvaltype(X) <: Real
        ScalarOneStepMemoset
    else
        OneStepMemoset
    end
end
function default_full_memoset_type(X::AbstractModalLogiset)
    # if ...
    #     ScalarChainedMemoset TODO
    # else
        FullMemoset
    # end
end

using .DimensionalDatasets: OneWorld
using .DimensionalDatasets: Point, Point1D, Point2D, Point3D
using .DimensionalDatasets: Interval, Interval2D
using .DimensionalDatasets: IARelations
using .DimensionalDatasets: IA2DRelations
using .DimensionalDatasets: identityrel
using .DimensionalDatasets: globalrel

# Tables interface for (modal) logiset's, so that it can be integrated with MLJ
include("types/logiset-MLJ-interface.jl")

include("utils/autologiset-tools.jl")

"""
Logical datasets with scalar features.
"""
const AbstractScalarLogiset{
    W<:AbstractWorld,
    U<:Number,
    FT<:AbstractFeature,
    FR<:AbstractFrame{W}
} = AbstractModalLogiset{W,U,FT,FR}

nrelations(X::SupportedLogiset{W,U,FT,FR,L,N,<:Tuple{<:ScalarOneStepMemoset}}) where {W,U,FT,FR,L,N} = nrelations(supports(X)[1])
nrelations(X::SupportedLogiset{W,U,FT,FR,L,N,<:Tuple{<:ScalarOneStepMemoset,<:AbstractFullMemoset}}) where {W,U,FT,FR,L,N} = nrelations(supports(X)[1])
relations(X::SupportedLogiset{W,U,FT,FR,L,N,<:Tuple{<:ScalarOneStepMemoset}}) where {W,U,FT,FR,L,N} = relations(supports(X)[1])
relations(X::SupportedLogiset{W,U,FT,FR,L,N,<:Tuple{<:ScalarOneStepMemoset,<:AbstractFullMemoset}}) where {W,U,FT,FR,L,N} = relations(supports(X)[1])
nmetaconditions(X::SupportedLogiset{W,U,FT,FR,L,N,<:Tuple{<:ScalarOneStepMemoset}}) where {W,U,FT,FR,L,N} = nmetaconditions(supports(X)[1])
nmetaconditions(X::SupportedLogiset{W,U,FT,FR,L,N,<:Tuple{<:ScalarOneStepMemoset,<:AbstractFullMemoset}}) where {W,U,FT,FR,L,N} = nmetaconditions(supports(X)[1])
metaconditions(X::SupportedLogiset{W,U,FT,FR,L,N,<:Tuple{<:ScalarOneStepMemoset}}) where {W,U,FT,FR,L,N} = metaconditions(supports(X)[1])
metaconditions(X::SupportedLogiset{W,U,FT,FR,L,N,<:Tuple{<:ScalarOneStepMemoset,<:AbstractFullMemoset}}) where {W,U,FT,FR,L,N} = metaconditions(supports(X)[1])

include("scalar-pla.jl")
include("minimize.jl")
include("deprecate.jl")

end # module
