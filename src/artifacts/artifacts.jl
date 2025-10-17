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
#using InteractiveUtils

using DataStructures: OrderedDict

# Global variables related to the packages

# Path to the Artifacts.toml configuration file
const ARTIFACTS_PATH = joinpath(@__DIR__, "Artifacts.toml")

# URLS from which to download the deafult artifacts of SoleData
ARTIFACT_URLS = [
    # binaries
    "https://github.com/aclai-lab/Artifacts/raw/main/sole/binaries/generic/abc.tar.gz",
    "https://github.com/aclai-lab/Artifacts/raw/main/sole/binaries/minimizers/mitespresso.tar.gz",

    # datasets
    "https://github.com/aclai-lab/Artifacts/raw/main/sole/datasets/epilepsy.tar.gz",
    "https://github.com/aclai-lab/Artifacts/raw/main/sole/datasets/hugadb.tar.gz",
    "https://github.com/aclai-lab/Artifacts/raw/main/sole/datasets/libras.tar.gz",
    "https://github.com/aclai-lab/Artifacts/raw/main/sole/datasets/natops.tar.gz",
]

include("utils/artifact-utils.jl")

export fillartifacts

export AbstractLoader, AbstractLoaderDataset, AbstractLoaderBinary
export name, url
export load
export extract_artifact

export classes, variablenames

# general loading logic, common to any AbstractLoader
include("loaders/loaders.jl")


# Binaries

export ABCLoader
include("loaders/abc-loader.jl")

export MITESPRESSOLoader
include("loaders/mitespresso-loader.jl")


# Datasets

export load_arff_dataset, parseARFF, fix_dataframe, available_datasets, load_dataset
include("utils/dataset-utils.jl")

export EpilepsyLoader
include("loaders/epilepsy-loader.jl")

export HuGaDBLoader
include("loaders/hugadb-loader.jl")

export LibrasLoader
include("loaders/libras-loader.jl")

export NatopsLoader
include("loaders/natops-loader.jl")


end
