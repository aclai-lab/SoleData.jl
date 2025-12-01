using Test
using SoleData

using SoleLogics
using Random
using DataFrames

# create a time-series dataset for testing
X = DataFrame([[rand(3) for _ in 1:10] for _ in 1:5], :auto)

@test isempty(SoleData.readrelations(:none, X))
@test SoleData.readrelations(:IA, X) == [GlobalRel(), SoleLogics._IA_A(), SoleLogics._IA_L(), SoleLogics._IA_B(), SoleLogics._IA_E(), SoleLogics._IA_D(), SoleLogics._IA_O(), SoleLogics._IA_Ai(), SoleLogics._IA_Li(), SoleLogics._IA_Bi(), SoleLogics._IA_Ei(), SoleLogics._IA_Di(), SoleLogics._IA_Oi()]
@test SoleData.readrelations(:IA7, X) == [GlobalRel(), SoleLogics._IA_AorO(), SoleLogics._IA_L(), SoleLogics._IA_DorBorE(), SoleLogics._IA_AiorOi(), SoleLogics._IA_Li(), SoleLogics._IA_DiorBiorEi()]
@test SoleData.readrelations(:IA3, X) == [GlobalRel(), SoleLogics._IA_I(), SoleLogics._IA_L(), SoleLogics._IA_Li()]
@test SoleData.readrelations(:RCC8, X) == [GlobalRel(), SoleLogics._Topo_DC(), SoleLogics._Topo_EC(), SoleLogics._Topo_PO(), SoleLogics._Topo_TPP(), SoleLogics._Topo_TPPi(), SoleLogics._Topo_NTPP(), SoleLogics._Topo_NTPPi()]
@test SoleData.readrelations(:RCC5, X) == [GlobalRel(), SoleLogics._Topo_DR(), SoleLogics._Topo_PO(), SoleLogics._Topo_PP(), SoleLogics._Topo_PPi()]

@test SoleData.autorelations(:IA7) == (:IA7, "")
@test a=SoleData.autorelations(:invalid) == (nothing, "relations should be in [:none, :IA, :IA3, :IA7, :RCC5, :RCC8] or a vector of SoleLogics.AbstractRelation's, but invalid was provided. Defaulting to either no relation (adimensional data), IA7 interval relations (1- and 2-dimensional data)..\n")

# y = rand(["a", "b", "c"], 10)
# y = MLJ.levelcode.(categorical(y)) 

# using ModalDecisionTrees
# using MLJ

# model = ModalDecisionTree(; relations = :IA7)
# mach = machine(model, X, y) |> fit!

# this function is taken from package ModalDecisionTrees:
# that package is the only one that's actually uses SoleData's autologiset
function wrapdataset(
    X,
    model,
    force_var_grouping::Union{Nothing,AbstractVector{<:AbstractVector}} = nothing;
    passive_mode = false,
)
    SoleData.autologiset(
        X;
        force_var_grouping = force_var_grouping,
        downsize           = model.downsize,
        conditions         = model.conditions,
        featvaltype        = model.featvaltype,
        relations          = model.relations,
        fixcallablenans    = model.fixcallablenans,
        force_i_variables  = model.force_i_variables,
        passive_mode       = passive_mode,
    )
end

# since we cannot use ModalDecisionTrees in testing SoleData,
# due to avoid circular dependencies,
# to test relations we need to define a custom model for testing.
mutable struct Fake_MDT_autologiset_test # <: MMI.Probabilistic
    downsize               :: Union{Bool,NTuple{N,Integer} where N,Function}
    conditions             :: Union{
        Nothing,
        Vector{<:Union{SoleData.VarFeature,Base.Callable}},
        Vector{<:Tuple{Base.Callable,Integer}},
        Vector{<:Tuple{SoleData.TestOperator,<:Union{SoleData.VarFeature,Base.Callable}}},
        Vector{<:SoleData.ScalarMetaCondition},
    }
    featvaltype            :: Type
    relations              :: Union{
        Nothing,
        Symbol,
        Vector{<:AbstractRelation},
        Function
    }
    fixcallablenans        :: Bool
    force_i_variables      :: Bool

    function Fake_MDT_autologiset_test(;
        downsize          = identity,
        conditions        = nothing,
        featvaltype       = Float64,
        relations         = nothing,
        fixcallablenans   = false,
        force_i_variables = true,
    )
        new(downsize, conditions, featvaltype, relations, fixcallablenans, force_i_variables)
    end
end

model = Fake_MDT_autologiset_test(; relations=:none)
logiset_none = wrapdataset(X, model)

model = Fake_MDT_autologiset_test(; relations=:IA)
logiset_IA   = wrapdataset(X, model)

model = Fake_MDT_autologiset_test(; relations=:IA7)
logiset_IA7  = wrapdataset(X, model)

model = Fake_MDT_autologiset_test(; relations=:IA3)
logiset_IA3  = wrapdataset(X, model)

model = Fake_MDT_autologiset_test(; relations=:RCC8)
logiset_RCC8 = wrapdataset(X, model)

model = Fake_MDT_autologiset_test(; relations=:RCC5)
logiset_RCC5 = wrapdataset(X, model)

@test isempty(logiset_none[1].modalities[1].supports[1].relations)
@test logiset_IA[1].modalities[1].supports[1].relations   == [SoleLogics._IA_A(), SoleLogics._IA_L(), SoleLogics._IA_B(), SoleLogics._IA_E(), SoleLogics._IA_D(), SoleLogics._IA_O(), SoleLogics._IA_Ai(), SoleLogics._IA_Li(), SoleLogics._IA_Bi(), SoleLogics._IA_Ei(), SoleLogics._IA_Di(), SoleLogics._IA_Oi()]
@test logiset_IA7[1].modalities[1].supports[1].relations  == [SoleLogics._IA_AorO(), SoleLogics._IA_L(), SoleLogics._IA_DorBorE(), SoleLogics._IA_AiorOi(), SoleLogics._IA_Li(), SoleLogics._IA_DiorBiorEi()]
@test logiset_IA3[1].modalities[1].supports[1].relations  == [SoleLogics._IA_I(), SoleLogics._IA_L(), SoleLogics._IA_Li()]
@test logiset_RCC8[1].modalities[1].supports[1].relations == [SoleLogics._Topo_DC(), SoleLogics._Topo_EC(), SoleLogics._Topo_PO(), SoleLogics._Topo_TPP(), SoleLogics._Topo_TPPi(), SoleLogics._Topo_NTPP(), SoleLogics._Topo_NTPPi()]
@test logiset_RCC5[1].modalities[1].supports[1].relations == [SoleLogics._Topo_DR(), SoleLogics._Topo_PO(), SoleLogics._Topo_PP(), SoleLogics._Topo_PPi()]

@test eltype(logiset_none[1].modalities[1].supports[1].relations) <: SoleLogics.AbstractRelation
@test eltype(logiset_IA[1].modalities[1].supports[1].relations)   <: SoleLogics.AbstractRelation
@test eltype(logiset_IA7[1].modalities[1].supports[1].relations)  <: SoleLogics.AbstractRelation
@test eltype(logiset_IA3[1].modalities[1].supports[1].relations)  <: SoleLogics.AbstractRelation
@test eltype(logiset_RCC8[1].modalities[1].supports[1].relations) <: SoleLogics.AbstractRelation
@test eltype(logiset_RCC5[1].modalities[1].supports[1].relations) <: SoleLogics.AbstractRelation

n_instances = 2
_nvars = 2

X, relations = (DataFrame(; NamedTuple([Symbol(i_var) => [rand(3,3) for i_instance in 1:n_instances] for i_var in 1:_nvars])...), [IA2DRelations..., globalrel])
nvars = nvariables(X)
metaconditions = [ScalarMetaCondition(feature, >) for feature in features]

logiset_none = scalarlogiset(X; use_full_memoization = false, relations = SoleData.readrelations(:none, X), conditions = metaconditions)
logiset_IA   = scalarlogiset(X; use_full_memoization = false, relations = SoleData.readrelations(:IA, X),   conditions = metaconditions)
logiset_IA7  = scalarlogiset(X; use_full_memoization = false, relations = SoleData.readrelations(:IA7, X),  conditions = metaconditions)
logiset_IA3  = scalarlogiset(X; use_full_memoization = false, relations = SoleData.readrelations(:IA3, X),  conditions = metaconditions)
logiset_RCC8 = scalarlogiset(X; use_full_memoization = false, relations = SoleData.readrelations(:RCC8, X), conditions = metaconditions)
logiset_RCC5 = scalarlogiset(X; use_full_memoization = false, relations = SoleData.readrelations(:RCC5, X), conditions = metaconditions)

@test length(logiset_none.supports[1].relations) == 0
@test length(logiset_IA.supports[1].relations)   == 168
@test length(logiset_IA7.supports[1].relations)  == 48
@test length(logiset_IA3.supports[1].relations)  == 15
@test length(logiset_RCC8.supports[1].relations) == 7
@test length(logiset_RCC5.supports[1].relations) == 4

@test eltype(logiset_none.supports[1].relations) <: SoleLogics.AbstractRelation
@test eltype(logiset_IA.supports[1].relations)   <: SoleLogics.AbstractRelation
@test eltype(logiset_IA7.supports[1].relations)  <: SoleLogics.AbstractRelation
@test eltype(logiset_IA3.supports[1].relations)  <: SoleLogics.AbstractRelation
@test eltype(logiset_RCC8.supports[1].relations) <: SoleLogics.AbstractRelation
@test eltype(logiset_RCC5.supports[1].relations) <: SoleLogics.AbstractRelation