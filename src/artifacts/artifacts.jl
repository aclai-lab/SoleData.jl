module Artifacts

using CategoricalArrays
using CodecZlib
using DataFrames
using Downloads
using Pkg.Artifacts
using SHA
using Tar
using TOML
using ZipFile

using DataStructures: OrderedDict

# Global variables related to the packages

# Path to the Artifacts.toml configuration file
const ARTIFACTS_PATH = joinpath(@__DIR__, "Artifacts.toml")

# URLS from which to download the deafult artifacts of SoleData
ARTIFACT_URLS = [
    "https://github.com/aclai-lab/Artifacts/raw/main/sole/datasets/NATOPS.tar.gz",
    "https://github.com/aclai-lab/Artifacts/raw/main/sole/datasets/Libras.tar.gz",
    "https://github.com/aclai-lab/Artifacts/raw/main/sole/binaries/minimizers/mitespresso.tar.gz"
]

include("utils/artifact-utils.jl")

export fill_artifacts

include("loaders.jl")

export AbstractLoader, AbstractLoaderDataset, AbstractLoaderBinary
export extract_artifact


# Binaries

include("loaders/abc.jl")
include("loaders/mitespresso.jl")

export ABCLoaderBinary, MITESPRESSOLoaderBinary


## Datasets

include("utils/dataset-utils.jl")

export load_arff_dataset, parseARFF, fix_dataframe

include("loaders/epilepsy-loader.jl")

include("loaders/hugadb-loader.jl")
include("loaders/libras-loader.jl")

include("loaders/natops-loader.jl")

export load_epilepsy
export load_hugadb
export load_libras
export load_NATOPS

end
