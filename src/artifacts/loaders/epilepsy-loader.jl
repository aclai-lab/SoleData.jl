struct EpilepsyLoader <: AbstractLoaderDataset
    name::String
    url::String
    path::String

    EpilepsyLoader() = new(
        "epilepsy",
        "",
        ARTIFACTS_PATH
    )
end

function load(l::EpilepsyLoader)
    artifact_path = ensure_artifact_installed(name(l), path(l))

    tarfile = joinpath(artifact_path, "$(name(l)).tar.gz")

    dirpath = begin
        extraction_path = artifact_path

        if isfile(tarfile)
            extraction_path = extract_artifact(artifact_path, name(l))
        end

        return joinpath(extraction_path, "$(name(l))")
    end

    dirpath = joinpath(artifact_path, "$(name(l))")

    (X_train, y_train), (X_test, y_test) =
        (
            read("$(dirpath)/Epilepsy_TEST.arff", String) |> Datasets.parseARFF,
            read("$(dirpath)/Epilepsy_TRAIN.arff", String) |> Datasets.parseARFF,
        )

    X_train  = SoleData.fix_dataframe(X_train, variablenames)
    X_test   = SoleData.fix_dataframe(X_test, variablenames)

    y_train = categorical(y_train)
    y_test = categorical(y_test)

    vcat(X_train, X_test), vcat(y_train, y_test)
end
