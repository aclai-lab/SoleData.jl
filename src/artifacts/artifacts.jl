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
    # binaries
    "https://github.com/aclai-lab/Artifacts/raw/main/sole/binaries/minimizers/mitespresso.tar.gz",

    # datasets
    "https://github.com/aclai-lab/Artifacts/blob/main/sole/datasets/epilepsy.tar.gz",
    "https://github.com/aclai-lab/Artifacts/blob/main/sole/datasets/hugadb.tar.gz",
    "https://github.com/aclai-lab/Artifacts/raw/main/sole/datasets/libras.tar.gz",
    "https://github.com/aclai-lab/Artifacts/raw/main/sole/datasets/natops.tar.gz",
]

include("utils/artifact-utils.jl")

export fillartifacts

# general loading logic, common to any AbstractLoader
include("loaders/loaders.jl")

export AbstractLoader, AbstractLoaderDataset, AbstractLoaderBinary
export name, url, path
export load
export extract_artifact


# Binaries

include("loaders/abc.jl")
include("loaders/mitespresso.jl")

export ABCLoaderBinary, MITESPRESSOLoaderBinary


# Datasets

include("utils/dataset-utils.jl")

export load_arff_dataset, parseARFF, fix_dataframe

include("loaders/epilepsy-loader.jl")
include("loaders/hugadb-loader.jl")
include("loaders/libras-loader.jl")
include("loaders/natops-loader.jl")

export EpilepsyLoader
export HuGaDBLoader
export LibrasLoader
export NatopsLoader

end
