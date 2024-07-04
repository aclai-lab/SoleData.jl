
using SoleLogics
using SoleLogics: Atom
using SoleData:  AbstractFeature, ScalarCondition, VariableValue, LeftmostConjunctiveForm
using SoleData: feature, value, test_operator, threshold, polarity

x_u1 =  Atom{ScalarCondition}(ScalarCondition(VariableValue(:x), ≤, 10))
x_u2 =  Atom{ScalarCondition}(ScalarCondition(VariableValue(:x), ≤, 9))
x_u3 =  Atom{ScalarCondition}(ScalarCondition(VariableValue(:x), ≤, 7))
x_u4 =  Atom{ScalarCondition}(ScalarCondition(VariableValue(:x), ≤, 6))
x_l1 =  Atom{ScalarCondition}(ScalarCondition(VariableValue(:x), ≥, 1))
x_l1 =  Atom{ScalarCondition}(ScalarCondition(VariableValue(:x), >, 1))
x_l2 =  Atom{ScalarCondition}(ScalarCondition(VariableValue(:x), ≥, 3))
x_l2 =  Atom{ScalarCondition}(ScalarCondition(VariableValue(:x), >, 3))

y_u1 =  Atom{ScalarCondition}(ScalarCondition(VariableValue(:y), ≤, 10))
y_u2 =  Atom{ScalarCondition}(ScalarCondition(VariableValue(:y), ≤, 9))
y_u3 =  Atom{ScalarCondition}(ScalarCondition(VariableValue(:y), ≤, 7))
y_u4 =  Atom{ScalarCondition}(ScalarCondition(VariableValue(:y), ≤, 6))
y_u4 =  Atom{ScalarCondition}(ScalarCondition(VariableValue(:y), <, 6))



# atomslist = Atom{ScalarCondition}[x_u1, x_u2, x_u3, x_u4, x_l1, x_l2, y_u1, y_u2, y_u3, y_u4]
atomslist = [x_u1, x_u2, x_u3, x_u4, x_l1, x_l2, y_u1, y_u2, y_u3, y_u4]

φ = LeftmostConjunctiveForm(atomslist)
# Start function

SoleData.scalar_simplification(φ)
(φ)
