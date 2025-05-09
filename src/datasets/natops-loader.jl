NATOPS_VARIABLENAMES = [
        "X[Hand tip l]", "Y[Hand tip l]", "Z[Hand tip l]",
        "X[Hand tip r]", "Y[Hand tip r]", "Z[Hand tip r]",
        "X[Elbow l]", "Y[Elbow l]", "Z[Elbow l]",
        "X[Elbow r]","Y[Elbow r]","Z[Elbow r]",
        "X[Wrist l]", "Y[Wrist l]", "Z[Wrist l]",
        "X[Wrist r]", "Y[Wrist r]", "Z[Wrist r]",
        "X[Thumb l]", "Y[Thumb l]", "Z[Thumb l]",
        "X[Thumb r]", "Y[Thumb r]", "Z[Thumb r]",
    ]

"""
    function load_NATOPS(
        dirpath::S;
        fileprefix::S="Epilepsy",
        variablenames::Vector{S}=["x", "y", "z"]
    ) where {S<:AbstractString}

Loader for `Epilepsy` dataset, available [here](https://timeseriesclassification.com/description.php?Dataset=NATOPS).

# Arguments
- `dirpath::S`: the directory in which all the .arff files are stored.

# Keyword Arguments
- `fileprefix::S="Epilepsy"`: the prefix shared by both test and train parts of the dataset;
    the default name for such files is NATOPS_TEST.arff and NATOPS_TRAIN.arff;
- `variablenames::Vector{S}=NATOPS_VARIABLENAMES`: the names of the columns.
"""
function load_NATOPS(
    dirpath::S;
    fileprefix::S="NATOPS",
    variablenames::Vector{S}=NATOPS_VARIABLENAMES
)
    # A previous implementation of this loader was very kind with the user, and tried
    # to download NATOPS by internet if an error occurred locally:
    # try
    #     _load_NATOPS(dirpath, fileprefix)
    # catch error
    #     if error isa SystemError
    #         SoleData.load_arff_dataset("NATOPS")
    #     else
    #         rethrow(error)
    #     end
    # end

    _load_NATOPS(dirpath, fileprefix)
end

function _load_NATOPS(dirpath::String, fileprefix::String)
    (X_train, y_train), (X_test, y_test) =
        (
            read("$(dirpath)/$(fileprefix)_TEST.arff", String) |> SoleData.parseARFF,
            read("$(dirpath)/$(fileprefix)_TRAIN.arff", String) |> SoleData.parseARFF,
        )

    X_train  = SoleData.fix_dataframe(X_train, variablenames)
    X_test   = SoleData.fix_dataframe(X_test, variablenames)

    class_names = [
        "I have command",
        "All clear",
        "Not clear",
        "Spread wings",
        "Fold wings",
        "Lock wings",
    ]

    fix_class_names(y) = class_names[round(Int, parse(Float64, y))]

    y_train = map(fix_class_names, y_train)
    y_test  = map(fix_class_names, y_test)

    y_train = categorical(y_train)
    y_test = categorical(y_test)
    vcat(X_train, X_test), vcat(y_train, y_test)
end
