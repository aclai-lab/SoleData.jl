using DataFrames
using Test
using SoleData
using MLJBase

X..., y = MLJBase.load_iris()
X_df = DataFrame(collect(values(X)), collect(keys(X)))
X = scalarlogiset(X_df; allow_propositional = true)

myalphabet_int = alphabet(X, test_operators = [<], force_i_variables = true)
myalphabet_symbol = alphabet(X, test_operators = [<])

a = ExplicitAlphabet(collect(atoms(myalphabet_int)))
@test_nowarn SoleData.scalaralphabet(a)

a = ExplicitAlphabet(collect(atoms(myalphabet_symbol)))
@test_nowarn SoleData.scalaralphabet(a)

a = ExplicitAlphabet(collect(atoms(alphabet(X, test_operators = [<, ≥]))))
@test_throws ErrorException SoleData.scalaralphabet(a; discretizedomain = true)
@test_nowarn SoleData.scalaralphabet(a; discretizedomain = true, y = y)
