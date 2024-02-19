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


alphabet(X, [≥]) |> atoms .|> syntaxstring
alphabet(X, [≥, <]) |> atoms .|> x->syntaxstring(x; show_colon = false)

a = (alphabet(X, [≥, <]) |> atoms)[1]
@test_nowarn value(a) isa SoleDataUnivariateSymbolValue

@test_broken begin
    f = parsefeature(SoleData.UnivariateSymbolValue, "x < 0.03425152849651658")
    f isa SoleData.UnivariateSymbolValue && isapprox(SoleData.threshold(f), 0.03425152849651658)
end

@test_nowarn interpret(a, X)
