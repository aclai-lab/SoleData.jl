

using Test
using SoleData
using MLJBase

X = MLJBase.load_iris()
X = PropositionalLogiset(X)
alphabet(X) |> atoms .|> syntaxstring

φ =
Atom(parsecondition(SoleData.ScalarCondition, "sepal_length > 5.8"; featuretype = SoleData.VariableValue)) ∧
Atom(parsecondition(SoleData.ScalarCondition, "sepal_width < 3.0";  featuretype = SoleData.VariableValue)) ∨
Atom(parsecondition(SoleData.ScalarCondition, "target == \"setosa\"";      featuretype = SoleData.VariableValue))

c1 = check(φ, X)

φ =
parseformula("sepal_length > 5.8 ∧ sepal_width < 3.0 ∨ target == \"setosa\"";
    atom_parser = a->Atom(parsecondition(SoleData.ScalarCondition, a; featuretype = SoleData.VariableValue))
)

c2 = check(φ, X)

@test c1 == c2


############################################################################################
############################################################################################
############################################################################################

using Test
using SoleData
using Tables
using DataFrames

df = DataFrame(x=[rand(10,10) for i in 1:4], y=[4:5, 3:4, 2:3, 1:2])
@test_throws AssertionError PropositionalLogiset(df)

df = DataFrame(x=[rand() for i in 1:4], y=[rand() for i in 1:4])
X = PropositionalLogiset(df)

@test Tables.istable(X)
@test ! (X[1, :y] isa PropositionalLogiset)
@test ! (X[1, [:y]] isa PropositionalLogiset)
@test ! (X[[1], :y] isa PropositionalLogiset)
@test X[[1], [:y]] isa PropositionalLogiset
@test X[[1], :] isa PropositionalLogiset
@test X[:, [:y]] isa PropositionalLogiset
@test X[:, :] isa PropositionalLogiset

@test_nowarn alphabet(X) |> atoms .|> syntaxstring
@test_nowarn alphabet(X; test_operators = [≥]) |> atoms .|> syntaxstring
@test_nowarn alphabet(X, false; test_operators = [≥]) |> atoms .|> syntaxstring
@test_nowarn alphabet(X, true; test_operators = [≥]) |> atoms .|> syntaxstring
@test_nowarn alphabet(X; test_operators = [≥, <]) |> atoms .|> x->syntaxstring(x; show_colon = false)
@test_nowarn alphabet(X, false)
@test_throws ErrorException alphabet(X, false; discretizedomain = true)
@test_nowarn alphabet(X, false; discretizedomain = true, y = [rand() for i in 1:4])

a,b,c,d = collect((alphabet(X; test_operators = [≥, <]) |> atoms))[1:4]

@test SoleLogics.value(a) isa SoleData.ScalarCondition
@test SoleData.feature(SoleLogics.value(a)) isa SoleData.VariableValue

@test_broken begin
    f = parsefeature(SoleData.VariableValue, ":x")
    c = parsecondition(SoleData.ScalarCondition, "x < 0.03425152849651658"; featuretype = SoleData.VariableValue)
    f isa SoleData.VariableValue && isapprox(SoleData.threshold(f), 0.03425152849651658)
end

# test interpret - Atom
@test_nowarn interpret(a, X)
@test_nowarn interpret(a, SoleLogics.LogicalInstance(X, 1))
@test_nowarn interpret(a, X, 1)

sb = randformula(3, [a,b,c,d], [NEGATION, CONJUNCTION])
# test interpret - SyntaxBranch
@test_nowarn interpret(sb, X)
@test_nowarn interpret(sb, SoleLogics.LogicalInstance(X, 1))
@test_nowarn interpret(sb, X, 1)

# test interpret - Truth
@test_nowarn interpret(TOP, X)
@test_nowarn interpret(TOP, SoleLogics.LogicalInstance(X, 1))
@test_nowarn interpret(TOP, X, 1)

# test check - Atom
@test_nowarn check(a, X)
@test_nowarn check(a, SoleLogics.LogicalInstance(X, 1))
@test_nowarn check(a, X, 1)

sb = randformula(3, [a,b,c,d], [NEGATION, CONJUNCTION])
# test check - SyntaxBranch
@test_nowarn check(sb, X)
@test_nowarn check(sb, SoleLogics.LogicalInstance(X, 1))
@test_nowarn check(sb, X, 1)

# test check - Truth
@test_nowarn check(TOP, X)
@test_nowarn check(TOP, SoleLogics.LogicalInstance(X, 1))
@test_nowarn check(TOP, X, 1)
