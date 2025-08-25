struct ABCLoaderBinary <: AbstractLoaderBinary
    name::String    # Name of the artifact in Artifacts.toml
    url::String     # Fallback download URL
    path::String    # Path to the Artifacts.toml file

    # Internal constructor with default values
    ABCLoaderBinary() = new(
        "abc",
        "https://github.com/berkeley-abc/abc/archive/refs/heads/master.tar.gz",
        ARTIFACTS_PATH
    )
end

function load(al::ABCLoaderBinary)
    artifact_path = ensure_artifact_installed(name(al), path(al))

    # Check if tar.gz file needs extraction
    tarfile = joinpath(artifact_path, "$(name(al)).tar.gz")
    if isfile(tarfile)
        extracted_path = extract_artifact(artifact_path, name(al))
        return  joinpath(extracted_path, "$(name(al))")
    end

    return joinpath(artifact_path, "$(name(al))")
end
