struct ABCLoaderBinary <: AbstractLoaderBinary
    artifactname::String    # Name of the artifact in Artifacts.toml
    path::String           # Fallback download URL
    artifactpath::String   # Path to the Artifacts.toml file

    # Internal constructor with default values
    ABCLoaderBinary() = new(
        "abc",
        "https://github.com/berkeley-abc/abc/archive/refs/heads/master.tar.gz",
        ARTIFACTS_PATH
    )
end
