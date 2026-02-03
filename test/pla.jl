using Test
using SoleData

using SoleData.Artifacts
using SoleData: PLA
# using SoleLogics

function cleanlines(str::AbstractString)
  join(filter(!isempty, split(str, "\n")), "\n")
end

function my_espresso_minimize(args...; kwargs...)
  espressoPath = SoleData.load(MITESPRESSOLoader())
  espressobinary = joinpath(espressoPath, "espresso")
  return SoleData.espresso_minimize(args...; espressobinary = espressobinary, kwargs...)
end


formula0 = @scalarformula ((V1 > 10) ∧ (V2 < 0) ∧ (V2 < 0) ∧ (V2 <= 0)) ∨ ((V1 <= 0) ∧ ((V1 <= 3)) ∧ (V2 == 2))

pla, fnames = PLA.formula_to_pla(formula0)
@test cleanlines(pla) in [cleanlines("""
.i 5
.o 1
.ilb V1<=0 V1>10 V2<0 V2<=2 V2>=2
.ob formula_output

.p 2
011-0 1
10011 1
.e
"""), cleanlines("""
.i 5
.o 1
.ilb V1<=0 V1>10 V2<0 V2<=2 V2>=2
.ob formula_output

.p 2
10011 1
011-0 1
.e
""")]

pla, fnames = PLA.formula_to_pla(formula0; scalar_range=true)
@test cleanlines(pla) in [cleanlines("""
.i 6
.o 1
.ilb V1∈[-Inf,0] V1∈(0,10] V1∈(10,Inf] V2∈[-Inf,0) V2∈[0,2) V2∈[2,2]
.ob formula_output
.p 2
100001 1
001100 1
.e
"""),
cleanlines("""
.i 6
.o 1
.ilb V1∈[-Inf,0] V1∈(0,10] V1∈(10,Inf] V2∈[-Inf,0) V2∈[0,2) V2∈[2,2]
.ob formula_output
.p 2
001100 1
100001 1
.e
""")]

formula0 = @scalarformula ((V1 > 10) ∧ (V2 < 0) ∧ (V2 < 0) ∧ (V2 <= 0)) ∨ ((V1 <= 0) ∧ ((V1 <= 3)) ∧ (V2 >= 2))
pla, fnames = PLA.formula_to_pla(formula0)
@test pla == ".i 4\n.o 1\n.ilb V1<=0 V1>10 V2<0 V3>10\n.ob formula_output\n\n.p 3\n011- 1\n1011 1\n101- 1\n.e"
@test cleanlines(PLA.formula_to_pla(formula0)) in [cleanlines("""
.i 4
.o 1
.ilb V1<=0 V1>10 V2<0 V2>=2
.ob formula_output

.p 2
0110 1
1001 1
.e
"""), cleanlines("""
.i 4
.o 1
.ilb V<=0 V1>10 V2<0 V2>=2
.ob formula_output

.p 2
1001 1
0110 1
.e
""")]

@test_nowarn SoleData.scalar_simplification(dnf(formula0, Atom))

f = PLA.formula_to_pla(formula0)
fnames = [:V1, :V2]
formula01 = PLA.pla_to_formula(f, fnames)
tree01 = tree(LeftmostDisjunctiveForm(formula0))
formula0_min = my_espresso_minimize(tree01)

formula0 = @scalarformula ((V1 > 10) ∧ (V2 < 0) ∧ (V2 < 0) ∧ (V2 <= 0)) ∨ ((V1 <= 0) ∧ (V2 <= 10) ∧ ((V1 <= 3)) ∧ (V2 < 0))
formula0 = SoleData.scalar_simplification(dnf(formula0, Atom))
PLA.formula_to_pla(formula0)[1] |> println
formula0_min = my_espresso_minimize(formula0)
println(formula0); println(formula0_min);
@test_nowarn SoleData.scalar_simplification(formula0_min)


formula0 = @scalarformula ((V1 > 10) ∧ (V2 < 0) ∧ (V2 < 0) ∧ (V2 <= 0) ∨ ((V1 <= 0) ∧ (V2 <= 10) ∧ ((V1 <= 3)) ∧ (V2 < 0)) ∨ (V1 <= 0) ∧ (V2 < 0) ∧ (V1 <= 10) ∧ (V3 > 10))
formula0 = SoleData.scalar_simplification(dnf(formula0, Atom))
PLA.formula_to_pla(formula0)[1] |> println
formula0_min = my_espresso_minimize(formula0)
println(formula0); println(formula0_min);



φ = @scalarformula (V4 < 0.7 && V2 ≥ 2.6500000000000004 && V3 ≥ 5.0) ||
(V4 < 0.7 && V2 < 2.6500000000000004 && V3 ≥ 5.0) ||
(V4 < 0.7 && V2 ≥ 2.6500000000000004 && V3 < 5.0 && V3 ≥ 4.95) ||
(V4 < 0.7 && V2 < 2.6500000000000004 && V3 < 5.0 && V3 ≥ 4.95) ||
(V4 < 0.7 && V2 ≥ 2.6500000000000004 && V3 < 4.95) ||
(V4 < 0.7 && V2 < 2.6500000000000004 && V3 < 4.95)
# φ_min = my_espresso_minimize(φ, false; encoding = :univariate)
φ_min = my_espresso_minimize(φ; encoding = :univariate)
φ_min = my_espresso_minimize(φ, false, "exact"; encoding = :univariate)

println(φ); println(φ_min);
@test syntaxstring(φ_min) == syntaxstring(@scalarformula (V4 < 0.7))

# φ_min = my_espresso_minimize(φ, false; encoding = :multivariate)
# println(φ); println(φ_min);
# @test syntaxstring(φ_min) == syntaxstring(@scalarformula (V4 < 0.7))


φ = @scalarformula (V4 ≥ 1.7000000000000002) ∧ (V2 ≥ 2.6500000000000004) ∧ (V3 ≥ 5.0) ∨
(V4 ≥ 1.7000000000000002) ∧ (V2 < 2.6500000000000004) ∧ (V3 ≥ 5.0) ∨
(V4 ≥ 1.7000000000000002) ∧ (V2 ≥ 2.6500000000000004) ∧ (V3 < 5.0) ∧ (V3 ≥ 4.95) ∨
(V4 ≥ 1.7000000000000002) ∧ (V2 < 2.6500000000000004) ∧ (V3 < 5.0) ∧ (V3 ≥ 4.95) ∨
(V4 ≥ 1.7000000000000002) ∧ (V2 ≥ 2.6500000000000004) ∧ (V3 < 4.95) ∨
(V4 ≥ 1.7000000000000002) ∧ (V2 < 2.6500000000000004) ∧ (V3 < 4.95)
φ_min = my_espresso_minimize(φ)
# φ_min = my_espresso_minimize(φ, false)
println(φ); println(φ_min);
@test syntaxstring(φ_min) == syntaxstring(@scalarformula (V4 ≥ 1.7000000000000002))

# φ_min = my_espresso_minimize(φ, false; encoding = :multivariate)
# println(φ); println(φ_min);
# @test syntaxstring(φ_min) == syntaxstring(@scalarformula (V4 ≥ 1.7000000000000002))


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

@test_nowarn formula = PLA.pla_to_formula(pla; featvaltype = Float64)
@test_nowarn formula = PLA.pla_to_formula(""".i 5
.o 1
.ilb V1>10 V2<0 V2<=2 V3>10 V4!=10
.p 2
01--0 1
01-1- 1
.e
"""; featvaltype = Float64)

@test_nowarn formula = PLA.pla_to_formula(""".i 5
.o 1
.ilb V1>10 V2<0 V2<=2 V3>10 V4>=10
.p 2
01--0 1
01-1- 1
.e
""", featvaltype = Float32)



formula = @test_nowarn PLA.pla_to_formula(""".i 5
.o 1
.ilb V1>10 V2<0 V2<=2 V3>10 V4>=10
01010 1
01110 1
01011 1
01111 1
01010 1
01000 1
01100 1
.e
""", featvaltype = Float32)

@test syntaxstring(formula) == "((V1 <= 10) ∧ (V3 > 10) ∧ (V4 < 10)) ∨ ((V1 ≤ 10) ∧ (V2 < 0) ∧ (V3 > 10) ∧ (V4 < 10)) ∨ ((V1 ≤ 10) ∧ (V3 > 10) ∧ (V4 ≥ 10)) ∨ ((V1 ≤ 10) ∧ (V2 < 0) ∧ (V3 > 10) ∧ (V4 ≥ 10)) ∨ ((V1 ≤ 10) ∧ (V3 > 10) ∧ (V4 < 10)) ∨ ((V1 ≤ 10) ∧ (V3 ≤ 10) ∧ (V4 < 10)) ∨ ((V1 ≤ 10) ∧ (V2 < 0) ∧ (V3 ≤ 10) ∧ (V4 < 10))"

@test cleanlines(PLA.formula_to_pla(formula)[1]) == cleanlines("""
.i 4
.o 1
.ilb V1≤10 V2<0 V3≤10 V4<10
.ob formula_output

.p 6
1-01 1
1101 1
1-00 1
1100 1
1-11 1
1111 1
.e
""")



@test cleanlines((PLA.formula_to_pla(@scalarformula((V1 <= 0.0) ∨ (V1 <= 0.0) ∧ (V2 <= 0.0))))[1]) in [
cleanlines(""".i 2
.o 1
.ilb V1≤0.0 V2≤0.0
.ob formula_output
.p 2
11 1
1- 1
.e"""),
cleanlines(""".i 2
.o 1
.ilb V1≤0.0 V2≤0.0
.ob formula_output
.p 2
1- 1
11 1
.e""")
]

formula = PLA.pla_to_formula(""".i 2
.o 1
.ilb V1>0 V2>0
.ob formula_output
.p 1
0- 1
.e""")

PLA.formula_to_pla(@scalarformula ((V1 <= 0)) ∨ (¬(V1 <= 0) ∧ (V2 <= 0)))

pla = """.i 3
.o 1
.ilb V1>10 V2<0 V2<=2
.ob formula_output
1-1 1
0-1 1
.e"""

formula = PLA.pla_to_formula(pla)
@test isa(formula, SoleLogics.LeftmostDisjunctiveForm)
@test syntaxstring(formula) == "((V1 > 10) ∧ (V2 ≤ 2)) ∨ ((V1 ≤ 10) ∧ (V2 ≤ 2))"


# Espresso minimization

@test_nowarn my_espresso_minimize(@scalarformula ((V1 <= 0)) ∨ ((V1 <= 0) ∧ (V2 <= 0)))

@test syntaxstring(my_espresso_minimize(@scalarformula ((V1 <= 0)) ∨ ((V1 <= 0) ∧ (V2 <= 0)))) == "V1 ≤ 0"
