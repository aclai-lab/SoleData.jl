struct ABCLoader <: AbstractLoaderBinary
    name::String    # Name of the artifact in Artifacts.toml
    url::String     # Fallback download URL

    # Internal constructor with default values
    function ABCLoader()
        new("abc", "https://github.com/berkeley-abc/abc/archive/refs/heads/master.tar.gz")
    end
end

function load(al::ABCLoader)
    artifact_path = ensure_artifact_installed(name(al), ARTIFACTS_PATH)

    # Check if tar.gz file needs extraction
    tarfile = joinpath(artifact_path, "$(name(al)).tar.gz")
    if isfile(tarfile)
        extracted_path = extract_artifact(artifact_path, name(al))
        return joinpath(extracted_path, "$(name(al))")
    else
        return joinpath(artifact_path, "$(name(al))")
    end
end
