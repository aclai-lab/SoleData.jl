struct EpilepsyLoader <: AbstractLoaderDataset
    name::String
    url::String

    EpilepsyLoader() = new(
        "epilepsy",
        ""
    )
end

"""
    function load(l::EpilepsyLoader)

Load Epilepsy dataset as specified by the [`EpilepsyLoader`](@ref).
"""
function load(l::EpilepsyLoader)
    artifact_path = ensure_artifact_installed(name(l), ARTIFACTS_PATH)

    tarfile = joinpath(artifact_path, "$(name(l)).tar.gz")

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
            read("$(dirpath)/epilepsy_TEST.arff", String) |> parseARFF,
            read("$(dirpath)/epilepsy_TRAIN.arff", String) |> parseARFF,
        )

    X_train  = fix_dataframe(X_train, variablenames)
    X_test   = fix_dataframe(X_test, variablenames)

    y_train = categorical(y_train)
    y_test = categorical(y_test)

    return vcat(X_train, X_test), vcat(y_train, y_test)
end
