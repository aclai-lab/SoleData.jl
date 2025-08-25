# Define the abstract type hierarchy for different loader types
abstract type AbstractLoader end
abstract type AbstractLoaderDataset <: AbstractLoader end
abstract type AbstractLoaderBinary <: AbstractLoader end

artifact_loader(::T) where {T} = throw(ArgumentError("Invalid method for type $T"))


# Extract tar.gz file in the artifact directory (cross-platform);
# see extract_artifact.
function _extract_artifact(artifact_path::String, artifact_name::String)
    tarfile = joinpath(artifact_path, "$(artifact_name).tar.gz")

    if !isfile(tarfile)
        error("Artifact file $(tarfile) not found")
    end

    # Create a temporary directory for extraction
    extract_dir = joinpath(artifact_path, "extracted")

    # Remove existing extraction directory if it exists
    if isdir(extract_dir)
        rm(extract_dir; recursive=true)
    end

    # Create the extraction directory
    mkpath(extract_dir)

    # Extract the tar.gz file using Julia's cross-platform libraries
    try
        open(tarfile, "r") do tar_gz
            tar_stream = GzipDecompressorStream(tar_gz)
            Tar.extract(tar_stream, extract_dir)
        end
        @info "Successfully extracted $(artifact_name).tar.gz to $(extract_dir)"

        # Remove the original tar.gz file to save space (optional)
        # rm(tarfile)

    catch e
        # Clean up on error
        if isdir(extract_dir)
            rm(extract_dir; recursive=true)
        end
        error("Failed to extract $(tarfile): $(e)")
    end

    return extract_dir
end

"""
    extract_artifact(artifact_path::String, artifact_name::String)

Given the path from where to download an artifact resource and an identifier name,
download and extract it (if necessary).

!!! warn
    This method expects the resource to be saved as a .tar.gz archive.

TODO: what happens if the directory already exists, it is not empty, but the file
    is not extracted because someone did a mess?
    We need to test the if clause here.

See also (the implementation of) [`artifact_loader(al::ABCLoaderBinary)`](@ref) or
[`artifact_loader(al::MITESPRESSOLoaderBinary)`](@ref).
"""
function extract_artifact(artifact_path::String, artifact_name::String)
    tarfile = joinpath(artifact_path, "$(artifact_name).tar.gz")
    extract_dir = joinpath(artifact_path, "extracted")

    # If the extraction directory already exists and is not empty, assume extraction is done
    if isdir(extract_dir) && !isempty(readdir(extract_dir))
        @info "Artifact $(artifact_name) already extracted at $(extract_dir)"
        return extract_dir
    else
        # Otherwise, proceed with extraction
        return _extract_artifact(artifact_path, artifact_name)
    end
end
