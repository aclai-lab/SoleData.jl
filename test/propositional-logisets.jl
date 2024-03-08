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

a,b,c,d = (alphabet(X, [≥, <]) |> atoms)[1:4]

@test value(a) isa SoleData.ScalarCondition
@test SoleData.feature(value(a)) isa SoleData.UnivariateSymbolValue

@test_broken begin
    f = parsefeature(SoleData.UnivariateSymbolValue, "x < 0.03425152849651658")
    f isa SoleData.UnivariateSymbolValue && isapprox(SoleData.threshold(f), 0.03425152849651658)
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
