module SoleData

using Reexport

include("dataset/SoleDataset.jl")
# include("types/SoleType.jl")

@reexport using .SoleDataset
# @reexport using .SoleType

end # module
