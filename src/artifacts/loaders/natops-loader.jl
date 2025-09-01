struct NatopsLoader <: AbstractLoaderDataset
    name::String
    url::String

    variablenames::Vector{String}
    classes::Vector{String}

    NatopsLoader() = new(
        "natops",
        "",

        # variablenames
        [
            "X[Hand tip l]", "Y[Hand tip l]", "Z[Hand tip l]",
            "X[Hand tip r]", "Y[Hand tip r]", "Z[Hand tip r]",
            "X[Elbow l]", "Y[Elbow l]", "Z[Elbow l]",
            "X[Elbow r]","Y[Elbow r]","Z[Elbow r]",
            "X[Wrist l]", "Y[Wrist l]", "Z[Wrist l]",
            "X[Wrist r]", "Y[Wrist r]", "Z[Wrist r]",
            "X[Thumb l]", "Y[Thumb l]", "Z[Thumb l]",
            "X[Thumb r]", "Y[Thumb r]", "Z[Thumb r]",
        ],

        # classes
        [
            "I have command",
            "All clear",
            "Not clear",
            "Spread wings",
            "Fold wings",
            "Lock wings",
        ]
    )
end


"""
    function load(l::NatopsLoader)

Load NATOPS dataset as specified by the [`NatopsLoader`](@ref).
"""
function load(l::NatopsLoader)
    artifact_path = ensure_artifact_installed(name(l), ARTIFACTS_PATH)

    dirpath = begin
        tarfile = joinpath(artifact_path, "$(name(l)).tar.gz")

        if isfile(tarfile)
            extracted_path = extract_artifact(artifact_path, name(l))
            joinpath(extracted_path, "$(name(l))")
        else
            joinpath(artifact_path, "$(name(l))")
        end
    end

    (X_train, y_train), (X_test, y_test) =
        (
            read("$(dirpath)/natops_TEST.arff", String) |> Datasets.parseARFF,
            read("$(dirpath)/natops_TRAIN.arff", String) |> Datasets.parseARFF,
        )

    fix_class_names(y) = classes(l)[round(Int, parse(Float64, y))]

    y_train = map(fix_class_names, y_train)
    y_test  = map(fix_class_names, y_test)

    y_train = categorical(y_train)
    y_test = categorical(y_test)

    return vcat(X_train, X_test), vcat(y_train, y_test)
end
