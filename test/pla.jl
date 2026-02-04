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
    return SoleData.espresso_minimize(args...; espressobinary=espressobinary, kwargs...)
end

formula0 = @scalarformula ((V1 > 10) ∧ (V2 < 0) ∧ (V2 < 0) ∧ (V2 <= 0)) ∨
    ((V1 <= 0) ∧ ((V1 <= 3)) ∧ (V2 == 2))

pla, fnames = PLA._formula_to_pla(formula0)
@test pla in [
    ".i 5\n.o 1\n.ilb V1<=0 V1>10 V2<0 V2<=2 V2>=2\n.ob formula_output\n.p 2\n10011 1\n011-0 1\n.e",
    ".i 5\n.o 1\n.ilb V1<=0 V1>10 V2<0 V2<=2 V2>=2\n.ob formula_output\n.p 2\n011-0 1\n10011 1\n.e"
]
@test fnames == [VariableValue(1), VariableValue(2)]

pla, fnames = PLA._formula_to_pla(formula0; allow_scalar_range_conditions=true)
@test pla in [
    ".i 6\n.o 1\n.ilb V1∈[-Inf,0] V1∈(0,10] V1∈(10,Inf] V2∈[-Inf,0) V2∈[0,2) V2∈[2,2]\n.ob formula_output\n.p 2\n100001 1\n001100 1\n.e",
    ".i 6\n.o 1\n.ilb V1∈[-Inf,0] V1∈(0,10] V1∈(10,Inf] V2∈[-Inf,0) V2∈[0,2) V2∈[2,2]\n.ob formula_output\n.p 2\n001100 1\n100001 1\n.e"
]

formula0 = @scalarformula ((V1 > 10) ∧ (V2 < 0) ∧ (V2 < 0) ∧ (V2 <= 0)) ∨
    ((V1 <= 0) ∧ ((V1 <= 3)) ∧ (V2 >= 2))

pla, fnames = PLA._formula_to_pla(formula0)
@test pla in [
    ".i 4\n.o 1\n.ilb V1<=0 V1>10 V2<0 V2>=2\n.ob formula_output\n.p 2\n1001 1\n0110 1\n.e",
    ".i 4\n.o 1\n.ilb V1<=0 V1>10 V2<0 V2>=2\n.ob formula_output\n.p 2\n0110 1\n1001 1\n.e"
]
@test fnames == [VariableValue(1), VariableValue(2)]

simplify = SoleData.scalar_simplification(dnf(formula0))
@test simplify isa DNF

pla, fnames = PLA._formula_to_pla(formula0)
formula01 = PLA._pla_to_formula(pla, fnames)
@test formula01 isa Vector{SyntaxStructure}

tree01 = tree(LeftmostDisjunctiveForm(formula0))
formula0_min = my_espresso_minimize(tree01)
@test syntaxstring(formula0_min) isa String

formula0 = @scalarformula (
    (V1 > 10) ∧ (V2 < 0) ∧ (V2 < 0) ∧ (V2 <= 0) ∨
    ((V1 <= 0) ∧ (V2 <= 10) ∧ ((V1 <= 3)) ∧ (V2 < 0)) ∨
    (V1 <= 0) ∧ (V2 < 0) ∧ (V1 <= 10) ∧ (V3 > 10)
)

formula0 = SoleData.scalar_simplification(dnf(formula0, Atom))
@test formula0 isa DNF

φ = @scalarformula (V4 < 0.7 && V2 ≥ 2.6500000000000004 && V3 ≥ 5.0) ||
    (V4 < 0.7 && V2 < 2.6500000000000004 && V3 ≥ 5.0) ||
    (V4 < 0.7 && V2 ≥ 2.6500000000000004 && V3 < 5.0 && V3 ≥ 4.95) ||
    (V4 < 0.7 && V2 < 2.6500000000000004 && V3 < 5.0 && V3 ≥ 4.95) ||
    (V4 < 0.7 && V2 ≥ 2.6500000000000004 && V3 < 4.95) ||
    (V4 < 0.7 && V2 < 2.6500000000000004 && V3 < 4.95)

φ_min = my_espresso_minimize(φ)
@test syntaxstring(φ_min) == "[V4] < 0.7"

φ_min = my_espresso_minimize(φ, false, "exact")
@test syntaxstring(φ_min) == "[V4] < 0.7"

φ = @scalarformula (V4 ≥ 1.7000000000000002) ∧ (V2 ≥ 2.6500000000000004) ∧ (V3 ≥ 5.0) ∨
    (V4 ≥ 1.7000000000000002) ∧ (V2 < 2.6500000000000004) ∧ (V3 ≥ 5.0) ∨
    (V4 ≥ 1.7000000000000002) ∧ (V2 ≥ 2.6500000000000004) ∧ (V3 < 5.0) ∧
    (V3 ≥ 4.95) ∨
    (V4 ≥ 1.7000000000000002) ∧ (V2 < 2.6500000000000004) ∧ (V3 < 5.0) ∧
    (V3 ≥ 4.95) ∨
    (V4 ≥ 1.7000000000000002) ∧ (V2 ≥ 2.6500000000000004) ∧ (V3 < 4.95) ∨
    (V4 ≥ 1.7000000000000002) ∧ (V2 < 2.6500000000000004) ∧ (V3 < 4.95)

φ_min = my_espresso_minimize(φ)
@test syntaxstring(φ_min) == "[V4] ≥ 1.7000000000000002"

pla = """
.i 1
.o 1
.ilb V1>10
.ob formula_output
1 1
.e
"""
fnames = [VariableValue(1)]

formula = PLA._pla_to_formula(pla, fnames)
@test syntaxstring(LeftmostDisjunctiveForm(formula)) == "[V1] > 10.0"

formula = PLA._pla_to_formula(pla, fnames; conjunct=true)
@test syntaxstring(formula) == "[V1] > 10.0"

pla = """.i 5
.o 1
.ilb V1>10 V2<0 V2<=2 V3>10 V4!=10
.p 2
01--0 1
01-1- 1
.e
"""
fnames = [VariableValue(1), VariableValue(2), VariableValue(3), VariableValue(4)]

formula = PLA._pla_to_formula(pla, fnames; conjunct=true)
@test syntaxstring(formula) ==
    "(([V1] ≤ 10.0) ∧ ([V2] < 0.0) ∧ ([V4] ≤ 10.0) ∧ ([V4] ≥ 10.0)) ∨ (([V1] ≤ 10.0) ∧ ([V2] < 0.0) ∧ ([V3] > 10.0))"

pla, fnames = PLA._formula_to_pla(@scalarformula ((V1 <= 0)) ∨ (¬(V1 <= 0) ∧ (V2 <= 0)))
@test pla in [
    ".i 2\n.o 1\n.ilb V1<=0 V2<=0\n.ob formula_output\n.p 2\n1- 1\n01 1\n.e",
    ".i 2\n.o 1\n.ilb V1<=0 V2<=0\n.ob formula_output\n.p 2\n01 1\n1- 1\n.e"
]

@test syntaxstring(
    my_espresso_minimize(@scalarformula ((V1 <= 0)) ∨ ((V1 <= 0) ∧ (V2 <= 0)))
) == "[V1] ≤ 0.0"
