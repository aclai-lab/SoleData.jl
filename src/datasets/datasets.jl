module Datasets

using ZipFile
using DataFrames
using CategoricalArrays

using DataStructures: OrderedDict

include("epilepsy-loader.jl")
export load_epilepsy

include("hugadb-loader.jl")
export load_hugadb

include("libras-loader.jl")
export load_libras

include("natops-loader.jl")
export load_NATOPS

end
