
# Features for (multi)variate data
include("var-features.jl")

# Test operators to be used for comparing features and threshold values
include("test-operators.jl")

# Alphabets of conditions on the features, to be used in logical datasets
include("conditions.jl")

include("scalarformula.jl")

# Templates for formulas of scalar conditions (e.g., templates for ⊤, f ⋈ t, ⟨R⟩ f ⋈ t, etc.)
include("templated-formulas.jl")

include("random.jl")

include("representatives.jl")

# # Types for representing common associations between features and operators
# include("canonical-conditions.jl") # TODO remove

struct PatchedFunction
    f::Base.Callable
    fname::String
end

"""
A union type for all condition-inducing objects. An object of this type, coupled
with a (e.g., dimensional) dataset will induce a set of conditions in [`scalarlogiset`](@ref).
"""
const MixedCondition = Union{
    # CanonicalCondition,
    #
    <:SoleData.AbstractFeature,                                            # feature
    <:Base.Callable,                                                         # feature function (i.e., callables to be associated to all variables);
    <:PatchedFunction,
    <:Tuple{Base.Callable,Integer},                                          # (callable,var_id);
    <:Tuple{TestOperator,<:Union{SoleData.AbstractFeature,Base.Callable,PatchedFunction}}, # (test_operator,features);
    <:ScalarMetaCondition,                                                   # ScalarMetaCondition;
}

include("logiseed.jl")

include("scalarlogiset.jl")

include("memoset.jl")

include("onestep-memoset.jl")

export PropositionalLogiset
include("propositional-logiset.jl")
include("propositional-formula-simplification.jl")
