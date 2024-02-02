
__precompile__()

module SoleData

using Reexport
using SoleBase
using SoleBase: AbstractDataset, slicedataset

@reexport using DataFrames
@reexport using MultiData

# -------------------------------------------------------------
# exports

# -------------------------------------------------------------
# Abbreviations
const DF = DataFrames

end # module
