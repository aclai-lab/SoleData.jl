"""
    function load_epilepsy(
        dirpath::S;
        fileprefix::S="Epilepsy",
        variablenames::Vector{S}=["x", "y", "z"]
    ) where {S<:AbstractString}

Loader for `Epilepsy` dataset, available [here](https://timeseriesclassification.com/description.php?Dataset=Epilepsy).

# Arguments
- `dirpath::S`: the directory in which all the .arff files are stored.

# Keyword Arguments
- `fileprefix::S="Epilepsy"`: the prefix shared by both test and train parts of the dataset;
    the default name for such files is Epilepsy_TEST.arff and Epilepsy_TRAIN.arff;
- `variablenames::Vector{S}=["x", "y", "z"]`: the names of the columns.
"""
function load_epilepsy(
    dirpath::S;
    fileprefix::S="Epilepsy",
    variablenames::Vector{S}=["x", "y", "z"]
) where {S<:AbstractString}
    (X_train, y_train), (X_test, y_test) =
        (
            read("$(dirpath)/$(fileprefix)_TEST.arff", String) |> Datasets.parseARFF,
            read("$(dirpath)/$(fileprefix)_TRAIN.arff", String) |> Datasets.parseARFF,
        )

    X_train  = SoleData.fix_dataframe(X_train, variablenames)
    X_test   = SoleData.fix_dataframe(X_test, variablenames)

    y_train = categorical(y_train)
    y_test = categorical(y_test)

    vcat(X_train, X_test), vcat(y_train, y_test)
end
