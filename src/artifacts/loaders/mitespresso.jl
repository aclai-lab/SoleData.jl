struct MITESPRESSOLoaderBinary <: AbstractLoaderBinary
    artifactname::String    # Name of the artifact in Artifacts.toml
    path::String           # Fallback download URL
    artifactpath::String   # Path to the Artifacts.toml file


    # Internal constructor with default values
    MITESPRESSOLoaderBinary() = new(
        "mitespresso",
        "https://jackhack96.github.io/logic-synthesis/espresso.html",
        ARTIFACTS_PATH
    )
end

function artifact_loader(al::MITESPRESSOLoaderBinary)
    artifact_path = ensure_artifact_installed(al.artifactname, al.artifactpath)

    # Check if tar.gz file needs extraction
    tarfile = joinpath(artifact_path, "$(al.artifactname).tar.gz")
    if isfile(tarfile)
        extracted_path = extract_artifact_safe(artifact_path, al.artifactname)
        return  joinpath(extracted_path, "$(al.artifactname)")
    end

    return joinpath(artifact_path, "$(al.artifactname)")
end
