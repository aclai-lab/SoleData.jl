"""
Abstract type representing a generic configuration for loading an artifact resource.

# Interface
Every structure subtyping `AbstractLoader` must implement the following interface.
- `name(obj::DummyConcreteLoader)::String`
- `url(obj::DummyConcreteLoader)::String`
- `path(obj::DummyConcreteLoader)::String`

By default, the three methods above returns the fields `.name`, ``.url` and `.path`,
respectively.

See [`AbstractLoaderBinary`](@ref) and [`AbstractLoaderDataset`](@ref).
"""
abstract type AbstractLoader end

"""
    name(al::AbstractLoader) = al.name

Return the identifier name of the artifact associated with `al`.
"""
name(al::AbstractLoader) = al.name

"""
    url(al::AbstractLoader) = al.url

Return a fallback url that could be used to download the artifact identified by `al`.
"""
url(al::AbstractLoader) = al.url

"""
    abstract type AbstractLoaderBinary <: AbstractLoader end

Specific [`AbstractLoader`](@ref) for binaries.
"""
abstract type AbstractLoaderBinary <: AbstractLoader end

"""
    abstract type AbstractLoaderDataset <: AbstractLoader end

Specific [`AbstractLoader`](@ref) for datasets.
"""
abstract type AbstractLoaderDataset <: AbstractLoader end

"""
    Artifacts.load(::T) where {T}

Method to implementing the loading logic for your custom artifact.

!!! warning
    When implementing this method for an [`AbstractLoader`](@ref), be sure that the
    [`name`](@ref) getter for that particular loader has the same name of the resource you
    want to load.

See [`AbstractLoader`](@ref).

See also the implementations of [`load(al::ABCLoader)`](@ref) and
[`load(al::MITESPRESSOLoader)`](@ref).
"""
load(::T) where {T} = throw(ArgumentError("Invalid method for type $T"))


# Extract tar.gz file in the artifact directory (cross-platform);
# see extract_artifact.
function _extract_artifact(path::String, name::String; silent::Bool = true)
    tarfile = joinpath(path, "$(name).tar.gz")

    if !isfile(tarfile)
        error("Artifact file $(tarfile) not found")
    end

    # Create a temporary directory for extraction
    extract_dir = joinpath(path, "extracted")

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
        silent || println("Successfully extracted $(name).tar.gz to $(extract_dir)")

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
    extract_artifact(loader::AbstractLoader)
    extract_artifact(path::String, name::String)

Given an [`AbstractLoader`](@ref), download and extract it (if necessary).

!!! warn
    This method expects the resource to be saved as a .tar.gz archive.

See [`AbstractLoader`](@ref).

See also (the implementation of) [`load(al::ABCLoader)`](@ref) or
[`load(al::MITESPRESSOLoader)`](@ref).
"""
function extract_artifact(loader::AbstractLoader)
    extract_artifact(path(loader), name(loader))
end
function extract_artifact(path::String, name::String; silent::Bool = true)
    extract_dir = joinpath(path, "extracted")

    # If the extraction directory already exists and is not empty, assume extraction is done
    if isdir(extract_dir) && !isempty(readdir(extract_dir))
        silent || println("Artifact $(name) already extracted at $(extract_dir)")
        return extract_dir
    else
        # Otherwise, proceed with extraction
        return _extract_artifact(path, name)
    end
end
