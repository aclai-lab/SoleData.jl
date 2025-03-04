Sparse notes:

- expand MultiDataset to such that it has named modalities, instead of Integer names.
- There's a warning in MultiDataset->DataFrame conversion?
- TODO: hide dimensionality of the instances: `const AbstractDimensionalDataset{T<:Number,D} = AbstractVector{<:AbstractArray{T,D}}`
- enforce class (and regressor) variables not be part any modality
- Integration with ScientificTypes.jl
- Export as .h5mu, .h5ad
- checkout https://github.com/joshday/OnlineStats.jl

- Add parameter skipextremes etc.
- Fix allfeatvalues
- Uniform discretaization interface

Add parameters to listrules:
- max_natoms
- max_consequent_natoms
- max_antecedent_natoms
- max_nconjuncts
- max_consequent_nconjuncts
- max_antecedent_nconjuncts

