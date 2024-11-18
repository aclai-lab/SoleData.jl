
using Test
using SoleData
using SoleData: PLA
using SoleLogics

formula0 = @scalarformula ((V1 > 10) ∧ (V2 < 0) ∧ (V2 < 0) ∧ (V2 <= 0)) ∨ ((V1 <= 0) ∧ ((V1 <= 3)) ∧ (V2 == 2))
@test_broken PLA._formula_to_pla(formula0)

formula0 = @scalarformula ((V1 > 10) ∧ (V2 < 0) ∧ (V2 < 0) ∧ (V2 <= 0)) ∨ ((V1 <= 0) ∧ ((V1 <= 3)) ∧ (V2 >= 2))

SoleData.scalar_simplification(dnf(formula0, Atom))
PLA._formula_to_pla(formula0)[1] |> println

formula01 = tree(PLA._pla_to_formula(PLA._formula_to_pla(formula0)...))
formula0_min = PLA.espresso_minimize(formula0)


formula0 = @scalarformula ((V1 > 10) ∧ (V2 < 0) ∧ (V2 < 0) ∧ (V2 <= 0)) ∨ ((V1 <= 0) ∧ (V2 <= 10) ∧ ((V1 <= 3)) ∧ (V2 < 0))
formula0 = SoleData.scalar_simplification(dnf(formula0, Atom))
PLA._formula_to_pla(formula0)[1] |> println
formula0_min = PLA.espresso_minimize(formula0)
@test_nowarn SoleData.scalar_simplification(formula0_min)

Note that formula0_min is not smaller than

println(pla_result)



using Test

pla = """
.i 1
.o 1
.ilb V1>10
.ob formula_output
1 1
.e
"""

formula = PLA._pla_to_formula(pla)


pla = """.i 2
.o 1
.ilb V1>10 V2<0 V2<=2
.ob formula_output
1-1 1
0-1 1
.e"""

@test PLA._formula_to_pla(@scalarformula ((V1 <= 0)) ∨ ((V1 <= 0) ∧ (V2 <= 0)))[1] == """.i 2
.o 1
.ilb V1>0 V2>0
.ob formula_output
0- 1
00 1
.e"""

formula = PLA._pla_to_formula(""".i 2
.o 1
.ilb V1>0 V2>0
.ob formula_output
.p 1
0- 1
.e""")

PLA._formula_to_pla(@scalarformula ((V1 <= 0)) ∨ (¬(V1 <= 0) ∧ (V2 <= 0)))

formula = PLA._pla_to_formula(pla)
@test isa(formula, SoleLogics.LeftmostDisjunctiveForm)
