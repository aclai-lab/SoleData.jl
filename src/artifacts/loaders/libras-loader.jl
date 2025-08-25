struct LibrasLoader <: AbstractLoaderDataset
    name::String
    url::String
    path::String

    classes::Vector{String}

    LibrasLoader() = new(
        "libras",
        "",
        ARTIFACTS_PATH,

        # class names
        [
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
    )
end

"""
    classes(l::LibrasLoader) = l.classes

Retrieve the classes of Libras dataset.
"""
classes(l::LibrasLoader) = l.classes


"""
    function load(l::LibrasLoader)

Load Libras dataset as specified by the [`LibrasLoader`](@ref).
"""
function load(l::LibrasLoader)
    artifact_path = ensure_artifact_installed(name(l), path(l))

    tarfile = joinpath(artifact_path, "$(name(l)).tar.gz")

    dirpath = begin
        tarfile = joinpath(artifact_path, "$(name(al)).tar.gz")
        if isfile(tarfile)
            extracted_path = extract_artifact(artifact_path, name(al))
            return joinpath(extracted_path, "$(name(al))")
        else
            return joinpath(artifact_path, "$(name(al))")
        end
    end

    (X_train, y_train), (X_test, y_test) =
        (
            read("$(dirpath)/libras_TEST.arff", String) |> Datasets.parseARFF,
            read("$(dirpath)/libras_TRAIN.arff", String) |> Datasets.parseARFF,
        )

    # convert from .arff class codes to string
    fix_class_names(y) = classes(l)[round(Int, parse(Float64, y))]

    y_train = map(fix_class_names, y_train)
    y_test = map(fix_class_names, y_test)

    y_train = categorical(y_train)
    y_test = categorical(y_test)

    return vcat(X_train, X_test), vcat(y_train, y_test)
end
