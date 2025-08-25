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

export MITESPRESSOLoaderBinary

include("loaders/mitespresso.jl")

export MITESPRESSOLoaderBinary


## Datasets

include("utils/dataset-utils.jl")

export load_arff_dataset, parseARFF, fix_dataframe

include("epilepsy-loader.jl")
export load_epilepsy

include("hugadb-loader.jl")
export load_hugadb

include("libras-loader.jl")
export load_libras

include("natops-loader.jl")
export load_NATOPS

include("example-datasets.jl")
export load_arff_dataset

end
