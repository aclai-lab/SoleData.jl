# using Test
# using StatsBase
# using SoleLogics
# using SoleData
# using Graphs
# using Random
# using ThreadSafeDicts

features = SoleData.Feature.(string.('p':'z'))
worlds = SoleLogics.World.(1:10)
fr = SoleLogics.ExplicitCrispUniModalFrame(worlds, SimpleDiGraph(length(worlds), 4))

i_instance = 1

# Boolean
rng = Random.MersenneTwister(1)
bool_logiset = SoleData.ExplicitBooleanModalLogiset([(
    Dict([w => sample(rng, features, 2, replace=false) for w in worlds]), fr)])
bool_condition = SoleData.ValueCondition(features[1])

# TODO fix with StableRNG?

# @test [SoleData.checkcondition(bool_condition, bool_logiset, i_instance, w)
#     for w in worlds] == Bool[0, 1, 1, 1, 0, 0, 0, 0, 0, 0]

# Scalar (Float)
rng = Random.MersenneTwister(1)
scalar_logiset = SoleData.ExplicitModalLogiset([(Dict([w => Dict([f => rand(rng) for f in features]) for w in worlds]), fr)])
scalar_condition = SoleData.ScalarCondition(features[1], >, 0.5)

# TODO fix with StableRNG?

# @test [SoleData.checkcondition(scalar_condition, scalar_logiset, i_instance, w)
#     for w in worlds] == Bool[0, 0, 1, 1, 0, 1, 0, 1, 0, 0]

# Non-scalar (Vector{Float})
rng = Random.MersenneTwister(2)
nonscalar_logiset = SoleData.ExplicitModalLogiset([(Dict([w => Dict([f => rand(rng, rand(rng, 1:3)) for f in features]) for w in worlds]), fr)])

nonscalar_condition = SoleData.FunctionalCondition(features[1], (vals)->length(vals) >= 2)

# TODO fix with StableRNG?

# @test [SoleData.checkcondition(nonscalar_condition, nonscalar_logiset, i_instance, w)
#     for w in worlds] == Bool[0, 1, 0, 0, 1, 1, 1, 0, 1, 1]


multilogiset = MultiLogiset([bool_logiset, scalar_logiset, nonscalar_logiset])

@test SoleData.modalitytype(multilogiset) <:
SoleData.AbstractModalLogiset{SoleLogics.World{Int64}, U, SoleData.Feature{String}, SoleLogics.ExplicitCrispUniModalFrame{SoleLogics.World{Int64}, SimpleDiGraph{Int64}}} where U

SoleData.AbstractModalLogiset{SoleLogics.World{Int64}, U, Feature{String}, SoleLogics.ExplicitCrispUniModalFrame{SoleLogics.World{Int64}, SimpleDiGraph{Int64}}} where U <: SoleData.AbstractModalLogiset{SoleLogics.World{Int64}, U, Feature{String}, SoleLogics.ExplicitCrispUniModalFrame{SoleLogics.World{Int64}, SimpleDiGraph{Int64}}} where U


@test_nowarn displaystructure(bool_logiset)
@test_nowarn displaystructure(scalar_logiset)
@test_nowarn displaystructure(multilogiset)


############################################################################################

for w in worlds
    @test accessibles(fr, w) == accessibles(scalar_logiset, 1, w)
    @test representatives(fr, w, scalar_condition) == representatives(scalar_logiset, 1, w, scalar_condition)
end

cond1 = SoleData.ScalarCondition(features[1], >, 0.9)
cond2 = SoleData.ScalarCondition(features[2], >, 0.3)

for w in worlds
    @test (featvalue(features[1], scalar_logiset, 1, w) > 0.9) == check(Atom(cond1) ∧ ⊤, scalar_logiset, 1, w)
    @test (featvalue(features[2], scalar_logiset, 1, w) > 0.3) == check(Atom(cond2) ∧ ⊤, scalar_logiset, 1, w)
end

# Propositional formula
φ = ⊤ → Atom(cond1) ∧ Atom(cond2)
for w in worlds
    @test ((featvalue(features[1], scalar_logiset, 1, w) > 0.9) && (featvalue(features[2], scalar_logiset, 1, w) > 0.3)) == check(φ, scalar_logiset, 1, w)
end

# Modal formula
φ = ◊(⊤ → Atom(cond1) ∧ Atom(cond2))
for w in worlds
    @test check(φ, scalar_logiset, 1, w) == (length(accessibles(fr, w)) > 0 && any([
        ((featvalue(features[1], scalar_logiset, 1, v) > 0.9) && (featvalue(features[2], scalar_logiset, 1, v) > 0.3))
    for v in accessibles(fr, w)]))
end

# Modal formula on multilogiset
for w in worlds
    @test check(φ, multilogiset, 2, 1, w) == (length(accessibles(fr, w)) > 0 && any([
        ((featvalue(features[1], multilogiset, 2, 1, v) > 0.9) && (featvalue(features[2], multilogiset, 2, 1, v) > 0.3))
    for v in accessibles(fr, w)]))
end

############################################################################################

# Check with memoset

w = worlds[1]
W = worldtype(bool_logiset)
bool_supported_logiset = @test_nowarn SupportedLogiset(bool_logiset)
scalar_supported_logiset = @test_nowarn SupportedLogiset(scalar_logiset)
nonscalar_supported_logiset = @test_nowarn SupportedLogiset(nonscalar_logiset)

@test SoleData.featvalue(features[1], nonscalar_logiset, 1, worlds[1]) == SoleData.featvalue(features[1], nonscalar_supported_logiset, 1, worlds[1])

@test_nowarn displaystructure(bool_supported_logiset)
@test_nowarn displaystructure(scalar_supported_logiset)
@test_nowarn displaystructure(nonscalar_supported_logiset)

@test_nowarn slicedataset(bool_logiset, [1])
@test_nowarn slicedataset(bool_logiset, [1]; return_view = true)
@test_nowarn slicedataset(bool_supported_logiset, [1])

@test_nowarn SoleData.allfeatvalues(bool_logiset)
@test_nowarn SoleData.allfeatvalues(bool_logiset, 1)
@test_nowarn SoleData.allfeatvalues(bool_logiset, 1, features[1])
@test_nowarn SoleData.allfeatvalues(bool_supported_logiset)
@test_nowarn SoleData.allfeatvalues(bool_supported_logiset, 1)
@test_nowarn SoleData.allfeatvalues(bool_supported_logiset, 1, features[1])

@test SoleLogics.allworlds(bool_logiset, 1) == SoleLogics.allworlds(bool_supported_logiset, 1)
@test SoleLogics.nworlds(bool_logiset, 1) == SoleLogics.nworlds(bool_supported_logiset, 1)
@test SoleLogics.frame(bool_logiset, 1) == SoleLogics.frame(bool_supported_logiset, 1)


@test_throws ArgumentError SoleData.parsecondition(SoleData.ScalarCondition, "p > 0.5")
@test_nowarn SoleData.parsecondition(SoleData.ScalarCondition, "p > 0.5"; featvaltype = String, featuretype = Feature)
@test SoleData.ScalarCondition(features[1], >, 0.5) == SoleData.parsecondition(SoleData.ScalarCondition, "p > 0.5"; featvaltype = String, featuretype = Feature)

############################################################################################
# Memoset's
############################################################################################

memoset = [ThreadSafeDict{SyntaxTree,Worlds{W}}() for i_instance in 1:ninstances(bool_supported_logiset)]

@test_nowarn check(φ, bool_logiset, 1, w)
@test_nowarn check(φ, bool_logiset, 1, w; use_memo = nothing)
@test_nowarn check(φ, bool_logiset, 1, w; use_memo = memoset)
@test_nowarn check(φ, bool_supported_logiset, 1, w)
@test_nowarn check(φ, bool_supported_logiset, 1, w; use_memo = nothing)
@test_logs (:warn,) check(φ, bool_supported_logiset, 1, w; use_memo = memoset)


bool_supported_logiset2 = @test_nowarn SupportedLogiset(bool_logiset, memoset)
bool_supported_logiset2 = @test_nowarn SupportedLogiset(bool_logiset, (memoset,))
bool_supported_logiset2 = @test_nowarn SupportedLogiset(bool_logiset, [memoset])

@test_throws AssertionError SupportedLogiset(bool_supported_logiset2)

@test_nowarn SupportedLogiset(bool_logiset, bool_supported_logiset2)

@test_nowarn SupportedLogiset(bool_logiset, (bool_supported_logiset2,))
@test_nowarn SupportedLogiset(bool_logiset, [bool_supported_logiset2])


rng = Random.MersenneTwister(1)
alph = ExplicitAlphabet([SoleData.ScalarCondition(rand(rng, features), rand(rng, [>, <]), rand(rng)) for i in 1:10])
syntaxstring.(alph)
_formulas = [randformula(
    rng, 4, alph, [NEGATION, CONJUNCTION, IMPLICATION, DIAMOND, BOX]; mode=:exactheight)
    for i in 1:10
]
@test_nowarn syntaxstring.(_formulas)
@test_nowarn syntaxstring.(_formulas; threshold_digits = 2)

c1 = @test_nowarn [check(φ, bool_logiset, 1, w) for φ in _formulas]
c2 = @test_nowarn [check(φ, bool_logiset, 1, w; use_memo = nothing) for φ in _formulas]
c3 = @test_nowarn [check(φ, bool_logiset, 1, w; use_memo = memoset) for φ in _formulas]
c4 = @test_nowarn [check(φ, SupportedLogiset(bool_logiset), 1, w) for φ in _formulas]
c5 = @test_nowarn [check(φ, SupportedLogiset(bool_logiset), 1, w; use_memo = nothing) for φ in _formulas]
# @test (@test_logs (:warn,) [check(φ, bool_supported_logiset, 1, w; use_memo = memoset) for φ in _formulas])
# c6 = [check(φ, bool_supported_logiset, 1, w; use_memo = memoset) for φ in _formulas]

@test c1 == c2 == c3 == c4 == c5

w = worlds[1]
W = worldtype(scalar_logiset)
memoset = [ThreadSafeDict{SyntaxTree,Worlds{W}}() for i_instance in 1:ninstances(scalar_logiset)]
@test_throws AssertionError check(φ, scalar_logiset, 1; use_memo = nothing)
@time check(φ, scalar_logiset, 1, w; use_memo = nothing)
@time check(φ, scalar_logiset, 1, w; use_memo = memoset)
