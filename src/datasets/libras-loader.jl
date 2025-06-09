# Differently from other datasets, here there is no need to specify a variablenames vector
# of strings, since each variable is named "x_frame_1", "x_frame_2", ..., by default.
"""
    function load_libras(
        dirpath::S;
        fileprefix::S="Epilepsy",
        variablenames::Vector{S}=["x", "y", "z"]
    ) where {S<:AbstractString}

Loader for `Libras` dataset, available [here](https://timeseriesclassification.com/description.php?Dataset=Libras).

# Arguments
- `dirpath::S`: the directory in which all the .arff files are stored.

# Keyword Arguments
- `fileprefix::S="Libras"`: the prefix shared by both test and train parts of the dataset;
    the default name for such files is Libras_TEST.arff and Libras_TRAIN.arff;
"""
function load_libras(
    dirpath::S;
    fileprefix::S="Libras"
) where {S<:AbstractString}
    _load_libras(dirpath, fileprefix)
end

function _load_libras(dirpath::String, fileprefix::String)
    (X_train, y_train), (X_test, y_test) =
        (
            read("$(dirpath)/$(fileprefix)_TEST.arff", String) |> SoleData.parseARFF,
            read("$(dirpath)/$(fileprefix)_TRAIN.arff", String) |> SoleData.parseARFF,
        )

    class_names = [
        "curved_swing",
        "horizontal_swing",
        "vertical_swing",
        "anti_clockwise_arc",
        "clokcwise_arc",
        "circle",
        "horizontal_straight_line",
        "vertical_straight_line",
        "horizontal_zigzag",
        "vertical_zigzag",
        "horizontal_wavy",
        "vertical_wavy",
        "face_up_curve",
        "face_down_curve",
        "tremble"
    ]

    # convert from .arff class codes to string
    fix_class_names(y) = class_names[round(Int, parse(Float64, y))]

    y_train = map(fix_class_names, y_train)
    y_test = map(fix_class_names, y_test)

    y_train = categorical(y_train)
    y_test = categorical(y_test)

    vcat(X_train, X_test), vcat(y_train, y_test)
end
