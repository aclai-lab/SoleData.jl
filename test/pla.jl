
using Test
using SoleData
using SoleData: PLA
using SoleLogics

formula0 = @scalarformula ((V1 > 10) ∧ (V2 < 0) ∧ (V2 < 0) ∧ (V2 <= 0)) ∨ ((V1 <= 0) ∧ ((V1 <= 3)) ∧ (V2 == 2))
@test_broken PLA._formula_to_pla(formula0)

formula0 = @scalarformula ((V1 > 10) ∧ (V2 < 0) ∧ (V2 < 0) ∧ (V2 <= 0)) ∨ ((V1 <= 0) ∧ ((V1 <= 3)) ∧ (V2 >= 2))
SoleData.scalar_simplification(dnf(formula0, Atom))
PLA._formula_to_pla(formula0, true)[1] |> println

formula01 = tree(PLA._pla_to_formula(PLA._formula_to_pla(formula0)...))
formula0_min = SoleData.espresso_minimize(formula0)


formula0 = @scalarformula ((V1 > 10) ∧ (V2 < 0) ∧ (V2 < 0) ∧ (V2 <= 0)) ∨ ((V1 <= 0) ∧ (V2 <= 10) ∧ ((V1 <= 3)) ∧ (V2 < 0))
formula0 = SoleData.scalar_simplification(dnf(formula0, Atom))
PLA._formula_to_pla(formula0)[1] |> println
formula0_min = SoleData.espresso_minimize(formula0)
println(formula0); println(formula0_min);
@test_nowarn SoleData.scalar_simplification(formula0_min)


formula0 = @scalarformula ((V1 > 10) ∧ (V2 < 0) ∧ (V2 < 0) ∧ (V2 <= 0) ∨ ((V1 <= 0) ∧ (V2 <= 10) ∧ ((V1 <= 3)) ∧ (V2 < 0)) ∨ (V1 <= 0) ∧ (V2 < 0) ∧ (V1 <= 10) ∧ (V3 > 10))
formula0 = SoleData.scalar_simplification(dnf(formula0, Atom))
PLA._formula_to_pla(formula0)[1] |> println
formula0_min = SoleData.espresso_minimize(formula0)
println(formula0); println(formula0_min);



φ = @scalarformula (V4 < 0.7 && V2 ≥ 2.6500000000000004 && V3 ≥ 5.0) ||
(V4 < 0.7 && V2 < 2.6500000000000004 && V3 ≥ 5.0) ||
(V4 < 0.7 && V2 ≥ 2.6500000000000004 && V3 < 5.0 && V3 ≥ 4.95) ||
(V4 < 0.7 && V2 < 2.6500000000000004 && V3 < 5.0 && V3 ≥ 4.95) ||
(V4 < 0.7 && V2 ≥ 2.6500000000000004 && V3 < 4.95) ||
(V4 < 0.7 && V2 < 2.6500000000000004 && V3 < 4.95)
φ_min = SoleData.espresso_minimize(φ)
println(φ); println(φ_min);
@test syntaxstring(φ_min) == syntaxstring(@scalarformula (V4 < 0.7))


φ = @scalarformula (V4 ≥ 1.7000000000000002) ∧ (V2 ≥ 2.6500000000000004) ∧ (V3 ≥ 5.0) ∨
(V4 ≥ 1.7000000000000002) ∧ (V2 < 2.6500000000000004) ∧ (V3 ≥ 5.0) ∨
(V4 ≥ 1.7000000000000002) ∧ (V2 ≥ 2.6500000000000004) ∧ (V3 < 5.0) ∧ (V3 ≥ 4.95) ∨
(V4 ≥ 1.7000000000000002) ∧ (V2 < 2.6500000000000004) ∧ (V3 < 5.0) ∧ (V3 ≥ 4.95) ∨
(V4 ≥ 1.7000000000000002) ∧ (V2 ≥ 2.6500000000000004) ∧ (V3 < 4.95) ∨
(V4 ≥ 1.7000000000000002) ∧ (V2 < 2.6500000000000004) ∧ (V3 < 4.95)
φ_min = SoleData.espresso_minimize(φ, false; encoding = :multivariate)
println(φ); println(φ_min);
@test syntaxstring(φ_min) == syntaxstring(@scalarformula (V4 ≥ 1.7000000000000002))


# Looks okay?

using Test

pla = """
.i 1
.o 1
.ilb V1>10
.ob formula_output
1 1
.e
"""

@test_nowarn formula = PLA._pla_to_formula(pla)


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
