
using Test
using SoleData
using SoleLogics

@test_nowarn SoleData.RangeScalarCondition(parsefeature(VarFeature, "V1"), nothing,1,true,true)
@test_broken SoleData.RangeScalarCondition(parsefeature(VarFeature, "V1"), nothing,nothing,true,true)


formula1 = @scalarformula ((V1 > 10) ∧ (V2 < 0)) ∨ ((V1 <= 0) ∧ (V2 == 2))
formula2 = @scalarformula ((V1 > 10) && (V2 < 0)) ∨ ((V1 <= 0) && (V2 == 2))
formula3 = @scalarformula ((V1 > 10) && (V2 < 0)) || ((V1 <= 0) && (V2 == 2))

@test formula1 isa SoleLogics.SyntaxTree
@test formula2 isa SoleLogics.SyntaxTree
@test formula3 isa SoleLogics.SyntaxTree

@test eltype(SoleLogics.value.(atoms(formula1))) <: SoleData.ScalarCondition
@test eltype(SoleLogics.value.(atoms(formula2))) <: SoleData.ScalarCondition
@test eltype(SoleLogics.value.(atoms(formula3))) <: SoleData.ScalarCondition

@test formula1 == formula2 == formula3

formula = @scalarformula ((V1 > 10) ∧ (V2 < 0) ∧ (V3 > 10)) ∨ ((V1 <= 0) ∧ (V2 == 2) ∧ (V3 != 10))
formulacnf = SoleLogics.cnf(formula)
@test SoleLogics.nconjuncts(formulacnf) == 9


formulacnf = SoleLogics.dnf(formula)
@test SoleLogics.ndisjuncts(formulacnf) == 2

formuladnfcnf = SoleLogics.dnf(SoleLogics.cnf(formula))
@test SoleLogics.nconjuncts(formuladnfcnf) == 4

formulacnfdnf = SoleLogics.cnf(SoleLogics.dnf(formula))
@test SoleLogics.nconjuncts(formulacnfdnf) == 4


formula1 = @scalarformula ((V1 > 10) ∧ (V2 < 0)) ∨ ((V1 <= 0) ∧ (V2 == 2))
formula2 = @scalarformula ¬(¬(V1 > 10) ∨ ¬(V2 < 0)) ∨ ((V1 <= 0) ∧ (V2 == 2))
formula3 = @scalarformula (¬¬(V1 > 10) ∧ ¬¬(V2 < 0)) ∨ ((V1 <= 0) ∧ (V2 == 2))
formula4 = @scalarformula ((V1 > 10) ∧ ¬(V2 ≥ 0)) ∨ ((V1 <= 0) ∧ (V2 == 2))
formula5 = @scalarformula (¬(V1 <= 10) ∧ ¬(V2 ≥ 0)) ∨ ((V1 <= 0) ∧ (V2 == 2))

@test formula1 != formula2 != formula3 != formula4 != formula5

my_dnf = x->SoleLogics.dnf(x; (;
            profile = :nnf,
            allow_atom_flipping = true,
            forced_negation_removal = false,
            flip_atom = a -> SoleData.polarity(SoleData.test_operator(SoleLogics.value(a))) == false
        )...
    )

@test_broken my_dnf(formula1) == my_dnf(formula2) == my_dnf(formula3) == my_dnf(formula4) == my_dnf(formula5)
@test string(my_dnf(formula1)) == string(my_dnf(formula2)) == string(my_dnf(formula3)) == string(my_dnf(formula4)) == string(my_dnf(formula5))
