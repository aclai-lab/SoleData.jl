using Test
using Logging
using SoleData


using SoleData: AbstractUnivariateFeature, Feature
using SoleData: ScalarCondition
using SoleData: feature


@test_nowarn parsefeature(VarFeature, "min[V1]")
@test_nowarn parsefeature(VarFeature, "min[V1]"; featvaltype = Float64)
@test_nowarn parsefeature(VarFeature, "min[V1]"; featvaltype = Int64)
@test_nowarn parsefeature(AbstractUnivariateFeature, "min[V1]")
# @test_logs (:warn,) parsefeature(VariableMin, "min[V1]")
@test_nowarn parsefeature(VariableMin, "min[V1]")



@test_logs (:warn,) parsecondition(ScalarCondition, "F1 > 2"; featuretype = Feature)
@test_logs (:warn,) parsecondition(ScalarCondition, "1 > 2"; featuretype = Feature{Int})

C = ScalarCondition

@test_logs min_level=Logging.Error parsecondition(C, "min[V1] <= 32")
@test_logs (:warn,) parsecondition(C, "min[V1] <= 32"; featvaltype = Float64)
@test_nowarn parsecondition(C, "min[V1] <= 32"; featvaltype = Float64, featuretype = AbstractUnivariateFeature)

@test_nowarn parsecondition(C, "min[V1] <= 32"; featvaltype = Float64, featuretype = AbstractUnivariateFeature)
@test_nowarn parsecondition(C, "max[V2] <= 435"; featvaltype = Float64, featuretype = AbstractUnivariateFeature)
@test_nowarn parsecondition(C, "minimum[V6]    > 250.631"; featvaltype = Float64, featuretype = AbstractUnivariateFeature)
@test_throws AssertionError parsecondition(C, "   minimum   [V7]    > 11.2"; featvaltype = Float64, featuretype = AbstractUnivariateFeature)
@test_throws AssertionError parsecondition(C, "avg [V8]    > 63.2  "; featvaltype = Float64, featuretype = AbstractUnivariateFeature)
@test_nowarn parsecondition(C, "mean[V9] <= 1.0e100"; featvaltype = Float64, featuretype = AbstractUnivariateFeature)

@test_nowarn parsecondition(C, "max{3] <= 12"; featvaltype = Float64, opening_parenthesis="{", variable_name_prefix = "", featuretype = AbstractUnivariateFeature)
@test_nowarn parsecondition(C, "  min[V4}    > 43.25  "; featvaltype = Float64, closing_parenthesis="}", featuretype = AbstractUnivariateFeature)
@test_nowarn parsecondition(C, "max{5} <= 250"; featvaltype = Float64, opening_parenthesis="{", closing_parenthesis="}", variable_name_prefix = "", featuretype = AbstractUnivariateFeature)
@test_nowarn parsecondition(C, "mean[V9] <= 1.0e100"; featvaltype = Float64, featuretype = AbstractUnivariateFeature)
@test_nowarn parsecondition(C, "mean🌅V9🌄 <= 1.0e100"; featvaltype = Float64, opening_parenthesis="🌅", closing_parenthesis="🌄", featuretype = AbstractUnivariateFeature)

@test_nowarn feature(parsecondition(C, "mean[V10]    > 462.2"; featvaltype = Float64, featuretype = AbstractUnivariateFeature))
@test_nowarn feature(parsecondition(C, "mean[V11] < 1.0e100"; featvaltype = Float64, featuretype = AbstractUnivariateFeature))


@test_nowarn parsecondition(C, "max[V15] <= 723"; featvaltype = Float64, featuretype = AbstractUnivariateFeature)
@test_nowarn parsecondition(C, "mean[V16] == 54.2"; featvaltype = Float64, featuretype = AbstractUnivariateFeature)

@test_throws ValueError parsecondition(C, "5345.4 < avg [V13]    < 32.2 < 12.2"; featuretype = AbstractUnivariateFeature)
@test_throws ValueError parsecondition(C, "avg [V14] < 12.2 <= 6127.2"; featuretype = AbstractUnivariateFeature)
@test_throws ValueError parsecondition(C, "mean189]    > 113.2"; featuretype = AbstractUnivariateFeature)
@test_throws ValueError parsecondition(C, "123.4 < avg [V12]    > 777.2  "; featuretype = AbstractUnivariateFeature)
@test_throws ValueError parsecondition(C, "mimimum [V17] < 23.2 <= 156.2"; featuretype = AbstractUnivariateFeature)
@test_throws ValueError parsecondition(C, "max[V3} <= 12"; opening_parenthesis="{", featuretype = AbstractUnivariateFeature)
@test_throws ValueError parsecondition(C, "max{18] <= 12"; opening_parenthesis="}", variable_name_prefix = "", featuretype = AbstractUnivariateFeature)
