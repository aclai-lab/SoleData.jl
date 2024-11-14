# This script is a temporary file written by @mauro-milella to test new functionalities,
# needed to setup his thesis' experiments.
#
# When this will be finished, everything will be moved to more appropriate test files.

using Test
using CategoricalArrays
using DataFrames
using SoleData
using ZipFile

using DataStructures: OrderedDict

function _load_NATOPS(
    dirpath::String=joinpath(dirname(pathof(ModalAssociationRules)), "../test/data/NATOPS"),
    fileprefix::String="NATOPS"
)
    (X_train, y_train), (X_test, y_test) =
        (
            read("$(dirpath)/$(fileprefix)_TEST.arff", String) |> SoleData.parseARFF,
            read("$(dirpath)/$(fileprefix)_TRAIN.arff", String) |> SoleData.parseARFF,
        )

    variablenames = ["X[Hand tip l]", "Y[Hand tip l]", "Z[Hand tip l]", "X[Hand tip r]", "Y[Hand tip r]", "Z[Hand tip r]", "X[Elbow l]", "Y[Elbow l]", "Z[Elbow l]", "X[Elbow r]", "Y[Elbow r]", "Z[Elbow r]", "X[Wrist l]", "Y[Wrist l]", "Z[Wrist l]", "X[Wrist r]", "Y[Wrist r]", "Z[Wrist r]", "X[Thumb l]", "Y[Thumb l]", "Z[Thumb l]", "X[Thumb r]", "Y[Thumb r]", "Z[Thumb r]"]
    variablenames_latex = ["\\text{hand tip l}_X", "\\text{hand tip l}_Y", "\\text{hand tip l}_Z", "\\text{hand tip r}_X", "\\text{hand tip r}_Y", "\\text{hand tip r}_Z", "\\text{elbow l}_X", "\\text{elbow l}_Y", "\\text{elbow l}_Z", "\\text{elbow r}_X", "\\text{elbow r}_Y", "\\text{elbow r}_Z", "\\text{wrist l}_X", "\\text{wrist l}_Y", "\\text{wrist l}_Z", "\\text{wrist r}_X", "\\text{wrist r}_Y", "\\text{wrist r}_Z", "\\text{thumb l}_X", "\\text{thumb l}_Y", "\\text{thumb l}_Z", "\\text{thumb r}_X", "\\text{thumb r}_Y", "\\text{thumb r}_Z"]

    X_train  = SoleData.fix_dataframe(X_train, variablenames)
    X_test   = SoleData.fix_dataframe(X_test, variablenames)

    class_names = ["I have command", "All clear", "Not clear", "Spread wings", "Fold wings", "Lock wings"]

    fix_class_names(y) = class_names[round(Int, parse(Float64, y))]

    y_train = map(fix_class_names, y_train)
    y_test  = map(fix_class_names, y_test)

    y_train = categorical(y_train)
    y_test = categorical(y_test)
    vcat(X_train, X_test), vcat(y_train, y_test)
end

X_df, y = _load_NATOPS(joinpath(dirname(pathof(SoleData)), "../test/data/NATOPS"))

pointlogiset = scalarlogiset(
    X_df;
    worldtype_by_dim=Dict(
        1 => SoleLogics.Point1D{Int})
)

at = Atom(ScalarCondition(VariableValue(1), >, 0))
i_instance = 1
id_point = 3
X_df[i_instance,1][id_point]
@test size(pointlogiset.base.featstruct) == (51, 360, 24)
@test_nowarn check(globaldiamond(at), pointlogiset, i_instance)
@test_nowarn check((at), pointlogiset, 1, SoleLogics.Point(id_point))

intervallogiset = scalarlogiset(
    X_df;
    worldtype_by_dim=Dict(
        1 => SoleLogics.Interval{Int})
)

@test size(intervallogiset.base.featstruct) == (51, 51, 360, 48)
@test_nowarn check(globaldiamond(Atom(ScalarCondition(VariableMax(1), >, 0))), intervallogiset, 1)

@test_broken @scalarformula V1 > 0 ∧ V2 < 0




interval2dlogiset = scalarlogiset(
    DataFrame(
        x=[rand(3,3) for i_instance in 1:100],
    );
)

point2dlogiset = scalarlogiset(
    DataFrame(
        x=[rand(3,3) for i_instance in 1:100],
    );
    worldtype_by_dim=Dict(
        2 => SoleLogics.Interval2D{Int})
)
