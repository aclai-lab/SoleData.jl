module SoleBase

using Reexport
# using ScientificTypes

include("utils.jl")

include("data/SoleData.jl")

@reexport using .SoleData
@reexport using DataFrames

# include("init.jl")

end # module
