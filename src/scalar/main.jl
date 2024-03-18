
# Features for (multi)variate data
include("var-features.jl")

# Test operators to be used for comparing features and threshold values
include("test-operators.jl")

# Alphabets of conditions on the features, to be used in logical datasets
include("conditions.jl")

# Templates for formulas of scalar conditions (e.g., templates for ⊤, f ⋈ t, ⟨R⟩ f ⋈ t, etc.)
include("templated-formulas.jl")

include("random.jl")

include("representatives.jl")

# # Types for representing common associations between features and operators
include("canonical-conditions.jl") # TODO remove

const MixedCondition = Union{
    CanonicalCondition,
    #
    <:SoleData.AbstractFeature,                                            # feature
    <:Base.Callable,                                                         # feature function (i.e., callables to be associated to all variables);
    <:Tuple{Base.Callable,Integer},                                          # (callable,var_id);
    <:Tuple{TestOperator,<:Union{SoleData.AbstractFeature,Base.Callable}}, # (test_operator,features);
    <:ScalarMetaCondition,                                                   # ScalarMetaCondition;
}

include("dataset-bindings.jl")

include("memosets.jl")

include("onestep-memoset.jl")
export PropositionalLogiset

include("scalar-propositional-logisets.jl")
