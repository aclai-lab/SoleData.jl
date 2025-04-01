using Test
using SoleData

# Tests for VariableDistance

# let's consider a motif, that is, a little representative shapelet
motif_example = [0.1, 0.2, 0.3, 0.4, 0.5]
my_motif = [0.0, 0.0, 0.0, 0.3, 0.4, 0.5]
 
vd = VariableDistance(1, motif_example) # id=1 is totally arbitrary
@test i_variable(vd) == 1
@test reference(vd) == motif_example

@test computeunivariatefeature(vd, reference(vd)) == 0
@test computeunivariatefeature(vd, my_motif) == 0.4

propositional_vd = VariableDistance(1, 36)
@test computeunivariatefeature(propositional_vd, 37) == 1.0

vnamed = VariableValue(1, "feature_name")
@test i_variable(vnamed) == 1
@test featurename(vnamed) == "feature_name"

U = Float64
var_id::SoleData.VariableId = 1
var_name::SoleData.VariableName = "feature_name"

unf1 = UnivariateNamedFeature{U}(var_id, var_name)
@test unf1 isa UnivariateNamedFeature{Float64, Int64}
@test i_variable(unf1) == 1
@test featurename(unf1) == "feature_name"
@test syntaxstring(unf1) == "[feature_name]"

unf2 = UnivariateNamedFeature(var_id, var_name)
@test unf2 isa UnivariateNamedFeature{Real, Int64}
@test i_variable(unf2) == 1
@test featurename(unf2) == "feature_name"
@test syntaxstring(unf2) == "[feature_name]"
