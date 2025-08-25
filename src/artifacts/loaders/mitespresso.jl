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
