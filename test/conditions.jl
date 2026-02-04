# ---------------------------------------------------------------------------- #
#                             ScalarMetaCondition                              #
# ---------------------------------------------------------------------------- #
cond = ScalarMetaCondition(VariableValue(:y), ≤)

@test SoleData.feature(cond) == VariableValue(:y)
@test SoleData.test_operator(cond) == (<=)

@test SoleData.hasdual(cond) == true
@test SoleData.dual(cond) == ScalarMetaCondition(VariableValue(:y), >)

@test syntaxstring(cond) == "y ≤ ⍰"
@test SoleData._syntaxstring_metacondition(cond) == "y ≤"

# ---------------------------------------------------------------------------- #
#                                syntaxstring                                  #
# ---------------------------------------------------------------------------- #
cond = ScalarCondition(VariableValue(:y), ==, 10)
result = syntaxstring(cond)
@test result == "y == 10"

cond = ScalarCondition(VariableValue(:y), ≥, 10)
result = syntaxstring(cond)
@test result == "y ≥ 10"

cond = ScalarCondition(VariableValue(:y), ≤, 10)
result = syntaxstring(cond)
@test result == "y ≤ 10"

result = syntaxstring(cond; removewhitespaces=true)
@test result == "y≤10"

cond = ScalarCondition(VariableValue(:y), ≤, 3.123456789)

result = syntaxstring(cond; threshold_digits=2)
@test result == "y ≤ 3.12"

threshold_display_method=(x->x^2)
result = syntaxstring(cond; threshold_display_method)
@test result == "y ≤ 9.755982312750191"

cond = ScalarCondition(VariableValue(:y), >=, 10)
result = syntaxstring(cond; pretty_op=false)
@test result == "y >= 10"

cond = ScalarCondition(VariableValue(:y), <=, 10)
result = syntaxstring(cond; pretty_op=false)
@test result == "y <= 10"

result = syntaxstring(cond; style=true)
@test result == "\e[1my ≤\e[0m 10"
