Sparse notes:

- Rename: islogiseed->istransformable
- expand MultiDataset to such that it has named modalities, instead of Integer names.
- There's a warning in MultiDataset->DataFrame conversion?
- TODO: hide dimensionality of the instances: `const AbstractDimensionalDataset{T<:Number,D} = AbstractVector{<:AbstractArray{T,D}}`
- enforce class (and regressor) variables not be part any modality
- Integration with ScientificTypes.jl
- Export as .h5mu, .h5ad
- checkout https://github.com/joshday/OnlineStats.jl
