# using Test
# using StatsBase
# using Random
# using SoleLogics
# using SoleData
# using DataFrames
# using SoleData.DimensionalDatasets

n_instances = 2
_nvars = 2

dataset, relations = (DataFrame(; NamedTuple([Symbol(i_var) => [rand(3,3) for i_instance in 1:n_instances] for i_var in 1:_nvars])...), [IA2DRelations..., globalrel])

nvars = nvariables(dataset)

features = collect(Iterators.flatten([[VariableMax(i_var), VariableMin(i_var)] for i_var in 1:nvars]))
logiset = scalarlogiset(dataset, features; use_full_memoization = false, use_onestep_memoization = false)

logiset = @test_nowarn scalarlogiset(dataset; use_full_memoization = false, use_onestep_memoization = false)
logiset = @test_nowarn scalarlogiset(dataset; use_full_memoization = true, use_onestep_memoization = false)

metaconditions = [ScalarMetaCondition(feature, >) for feature in features]

println("1")
@test_nowarn scalarlogiset(dataset; use_full_memoization = true, use_onestep_memoization = true, relations = relations, conditions = metaconditions)
println("2")
@test_throws AssertionError scalarlogiset(dataset; use_full_memoization = true, use_onestep_memoization = false, relations = relations, conditions = metaconditions)
println("3")
@test_nowarn scalarlogiset(dataset; use_full_memoization = false, relations = relations, conditions = metaconditions, onestep_precompute_globmemoset = false, onestep_precompute_relmemoset = false)
println("4")
@test_nowarn scalarlogiset(dataset; use_full_memoization = false, relations = relations, conditions = metaconditions, onestep_precompute_globmemoset = true, onestep_precompute_relmemoset = true)
println("5")

logiset = @test_nowarn scalarlogiset(dataset; use_full_memoization = false, relations = relations, conditions = metaconditions)

generic_complete_metaconditions = vcat([[ScalarMetaCondition(feature, >), ScalarMetaCondition(feature, <)] for feature in features]...)

complete_logiset = @test_nowarn scalarlogiset(dataset; use_full_memoization = false, relations = relations, conditions = generic_complete_metaconditions)

rng = Random.MersenneTwister(1)
alph = ExplicitAlphabet([SoleData.ScalarCondition(rand(rng, features), rand(rng, [>, <]), rand(rng)) for i in 1:n_instances]);
syntaxstring.(alph)
_formulas = [randformula(rng, 3, alph, [SoleLogics.BASE_PROPOSITIONAL_CONNECTIVES..., vcat([[DiamondRelationalConnective(r), BoxRelationalConnective(r)] for r in relations]...)[1:16:end]...]) for i in 1:20];
syntaxstring.(_formulas) .|> println;

i_instance = 1
@test_nowarn checkcondition(SoleLogics.value(alph.atoms[1]), complete_logiset, i_instance, first(allworlds(complete_logiset, i_instance)))

c1 = @test_nowarn [
        [check(φ, logiset, i_instance, w) for φ in _formulas]
    for w in allworlds(logiset, i_instance)]
c2 = @test_nowarn [
        [check(φ, complete_logiset, i_instance, w) for φ in _formulas]
    for w in allworlds(complete_logiset, i_instance)]

@test c1 == c2


@test_nowarn slicedataset(logiset, [1])
@test_nowarn slicedataset(complete_logiset, [1])

@test_nowarn concatdatasets(logiset, logiset, logiset)
@test_nowarn concatdatasets(complete_logiset, complete_logiset, complete_logiset)
