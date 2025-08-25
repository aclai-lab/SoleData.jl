using Pkg.Artifacts
using Tar, CodecZlib  

const ARTIFACTS_TOML = joinpath(dirname(@__DIR__), "Artifacts.toml")

# Define the abstract type hierarchy for different loader types
abstract type AbstractLoader end
abstract type AbstractLoaderDataset <: AbstractLoader end
abstract type AbstractLoaderBinary <: AbstractLoader end

struct ABCLoaderBinary <: AbstractLoaderBinary
    artifactname::String    # Name of the artifact in Artifacts.toml
    path::String           # Fallback download URL
    artifactpath::String   # Path to the Artifacts.toml file
    
    # Internal constructor with default values
    ABCLoaderBinary() = new(
        "abc", 
        "https://github.com/berkeley-abc/abc/archive/refs/heads/master.tar.gz",
        ARTIFACTS_TOML
    )
end

struct MITESPRESSOLoaderBinary <: AbstractLoaderBinary
    artifactname::String    # Name of the artifact in Artifacts.toml
    path::String           # Fallback download URL
    artifactpath::String   # Path to the Artifacts.toml file

    
    # Internal constructor with default values
    MITESPRESSOLoaderBinary() = new(
        "mitespresso", 
        "https://jackhack96.github.io/logic-synthesis/espresso.html",
        ARTIFACTS_TOML
    )
end

# FALLBACK METHODS - These provide error messages when no specific implementation exists
artifact_loader(::Any) = @error "No artifact_loader method written for generic type"
artifact_loader(::AbstractLoader) = @error "No artifact_loader method written for generic AbstractLoader type"
artifact_loader(::AbstractLoaderDataset) = @error "No artifact_loader method written for generic AbstractLoaderDataset type"  
artifact_loader(::AbstractLoaderBinary) = @error "No artifact_loader method written for generic AbstractLoaderBinary type"

################# CONCRETE LOADER IMPLEMENTATIONS #################

# Extract tar.gz file in the artifact directory (cross-platform)
function extract_artifact(artifact_path::String, artifact_name::String)
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


function extract_artifact_safe(artifact_path::String, artifact_name::String)
    tarfile = joinpath(artifact_path, "$(artifact_name).tar.gz")
    extract_dir = joinpath(artifact_path, "extracted")
    
    # If extraction directory already exists and is not empty, assume extraction is done
    if isdir(extract_dir) && !isempty(readdir(extract_dir))
        @info "Artifact $(artifact_name) already extracted at $(extract_dir)"
        return extract_dir
    end
    
    # Otherwise, proceed with extraction
    return extract_artifact(artifact_path, artifact_name)
end

# Load ABC binary artifact
function artifact_loader(al::ABCLoaderBinary)
    artifact_path = ensure_artifact_installed(al.artifactname, al.artifactpath)
    
    # Check if tar.gz file needs extraction
    tarfile = joinpath(artifact_path, "$(al.artifactname).tar.gz")
    if isfile(tarfile)
        extracted_path = extract_artifact_safe(artifact_path, al.artifactname)
        return  joinpath(extracted_path, "$(al.artifactname)")
    end
    
    return joinpath(artifact_path, "$(al.artifactname)")
end

# Load MITESPRESSO binary artifact  
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