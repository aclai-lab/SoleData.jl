using Test
using SoleData

# Tests for VariableDistance

vnamed1 = VariableValue(1, "feature_name")
@test i_variable(vnamed1) == 1
@test featurename(vnamed1) == "feature_name"
@test syntaxstring(vnamed1) == "[feature_name]"
vnamed2 = VariableValue(vnamed1)
@test syntaxstring(vnamed2) == "V1"

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

unf3 = UnivariateNamedFeature{U}(unf1)
@test unf3 isa UnivariateNamedFeature{Float64, Int64}
@test i_variable(unf3) == 1
@test featurename(unf3) == "feature_name"
@test syntaxstring(unf3) == "[feature_name]"

ds = [1.0, 2.0, 3.0]
@test SoleData.featvaltype(ds, unf3) == Float64