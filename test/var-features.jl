using Test
using SoleData

# Tests for VariableDistance

# let's consider a motif, that is, a little representative shapelet
sequence = [0.1, 0.2, 0.3, 0.4, 0.5]
sequences = [sequence, sequence.+1, sequence.+2]
too_long_sequence = [0.0, 0.0, 0.0, 0.3, 0.4, 0.5]

vd = VariableDistance(1, sequence) # id=1 is totally arbitrary
@test i_variable(vd) == 1
@test references(vd) == sequence

@test computeunivariatefeature(vd, references(vd)) == 0
@test_throws DimensionMismatch computeunivariatefeature(vd, too_long_sequence) == 0.4

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


# case in which a VariableDistance wraps multiple references
vd = VariableDistance(1, sequences)
@test references(vd) |> length == 3
@test computeunivariatefeature(vd, sequence) == 0
