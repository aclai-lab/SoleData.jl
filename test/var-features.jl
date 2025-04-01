using Test
using SoleData

# Tests for VariableDistance

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