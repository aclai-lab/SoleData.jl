using Test
using SoleData
using SoleData: RangeScalarCondition

compareincludes(a,b) = (SoleData.includes(a,b), SoleData.includes(b,a))
compareexcludes(a,b) = (SoleData.excludes(a,b), SoleData.excludes(b,a))
@testset "RangeScalarCondition" begin
    @test compareincludes(RangeScalarCondition(VariableValue(:a), 0, 1, true, true), RangeScalarCondition(VariableValue(:a), 0, 1, true, true)) == (true, true)
    @test compareincludes(RangeScalarCondition(VariableValue(:a), 0, 1, true, true), RangeScalarCondition(VariableValue(:a), 0, 1, true, false)) == (true, false)
    @test compareincludes(RangeScalarCondition(VariableValue(:a), 0, 1, true, true), RangeScalarCondition(VariableValue(:a), 0, 1, false, true)) == (true, false)
    @test compareincludes(RangeScalarCondition(VariableValue(:a), 0, 1, true, true), RangeScalarCondition(VariableValue(:a), 0, 1, false, false)) == (true, false)
    @test compareincludes(RangeScalarCondition(VariableValue(:a), 0, 1, true, true), RangeScalarCondition(VariableValue(:a), 0.5, 1, true, true)) == (true, false)
    @test compareincludes(RangeScalarCondition(VariableValue(:a), 0, 1, true, true), RangeScalarCondition(VariableValue(:a), 0, 0.5, true, true)) == (true, false)
    
    @test compareincludes(RangeScalarCondition(VariableValue(:b), 0, 1, true, true), RangeScalarCondition(VariableValue(:a), 0, 0.5, true, true)) == (false, false)

    a = parsecondition(SoleData.RangeScalarCondition, "V2 ∈ [2,∞]")
    b = parsecondition(SoleData.RangeScalarCondition, "V2 ∈ [-∞,0)")

    @test SoleData.includes(a, b) == false
    @test SoleData.includes(b, a) == false

    a = parsecondition(SoleData.RangeScalarCondition, "V1 ∈ (10,∞]")
    b = parsecondition(SoleData.RangeScalarCondition, "V1 ∈ [-∞,0]")

    @test SoleData.includes(a, b) == false
    @test SoleData.includes(b, a) == false

    @test compareexcludes(RangeScalarCondition(VariableValue(:a), 0, 1, true, true), RangeScalarCondition(VariableValue(:a), 0, 1, true, true)) == (false, false)
    @test compareexcludes(RangeScalarCondition(VariableValue(:a), 0, 1, true, true), RangeScalarCondition(VariableValue(:a), 0, 1, true, false)) == (false, false)
    @test compareexcludes(RangeScalarCondition(VariableValue(:a), 0, 1, true, true), RangeScalarCondition(VariableValue(:a), 0, 1, false, true)) == (false, false)
    @test compareexcludes(RangeScalarCondition(VariableValue(:a), 0, 1, true, true), RangeScalarCondition(VariableValue(:a), 0, 1, false, false)) == (false, false)
    @test compareexcludes(RangeScalarCondition(VariableValue(:a), 0, 1, true, true), RangeScalarCondition(VariableValue(:a), 0.5, 1, true, true)) == (false, false)
    @test compareexcludes(RangeScalarCondition(VariableValue(:a), 0, 1, true, true), RangeScalarCondition(VariableValue(:a), 0, 0.5, true, true)) == (false, false)
    
    @test compareexcludes(RangeScalarCondition(VariableValue(:b), 0, 1, true, true), RangeScalarCondition(VariableValue(:a), 0, 0.5, true, true)) == (false, false)
end
