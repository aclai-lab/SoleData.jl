using Test
using SoleData

using MLJ

_nvars = 2
n_instances = 20

multidataset, multirelations = collect.(
    zip(
        [
            (Array(reshape(1.0:40.0, _nvars, n_instances)), [globalrel]),
            (
                Array(reshape(1.0:120.0, 3, _nvars, n_instances)),
                [IARelations..., globalrel],
            ),
            (
                Array(reshape(1.0:360.0, 3, 3, _nvars, n_instances)),
                [IA2DRelations..., globalrel],
            ),
        ]...,
    ),
)

multidataset = map(d->eachslice(d; dims=ndims(d)), multidataset)
multilogiset = @test_nowarn scalarlogiset(multidataset)
multilogiset = scalarlogiset(
    multidataset;
    relations=multirelations,
    conditions=vcat(
        [
            [
                SoleData.ScalarMetaCondition(VariableMin(i), >),
                SoleData.ScalarMetaCondition(VariableMax(i), <),
            ] for i in 1:_nvars
        ]...,
    ),
)

X = @test_nowarn modality(multilogiset, 1)
@test_nowarn selectrows(X, 1:10)
@test_nowarn selectrows(multilogiset, 1:10)
@test_nowarn selectrows(SoleData.base(X), 1:10)
X = @test_nowarn modality(multilogiset, 2)
@test_nowarn selectrows(SoleData.base(X), 1:10)

mod2 = modality(multilogiset, 2)
mod2_part = modality(MLJ.partition(multilogiset, 0.8)[1], 2)
check(
    SyntaxTree(Atom(ScalarCondition(VariableMin(2), >, 301))),
    mod2_part,
    1,
    SoleData.Interval(1, 2),
)
check(
    (DiamondRelationalConnective(IA_L)(Atom(ScalarCondition(VariableMin(2), >, 0)))),
    mod2_part,
    1,
    SoleData.Interval(1, 2),
)

@test mod2_part != MLJ.partition(mod2, 0.8)[1]
@test nmemoizedvalues(mod2_part) == nmemoizedvalues(MLJ.partition(mod2, 0.8)[1])
