
# -------------------------------------------------------------
# AbstractMultiModalDataset - instances manipulation

"""
    ninstances(md[, i])

Return the number of instances present in a multimodal dataset.

Note: for consistency with other methods interface `ninstances` can be called specifying
a modality index `i` even if `ninstances(md) != ninstances(md, i)` can't be `true`.

This method can be called on a single modality directly.

## EXAMPLES

```julia-repl
julia> md = MultiModalDataset([[1],[2]],DataFrame(:age => [25, 26], :sex => ['M', 'F']))
● MultiModalDataset
   └─ dimensions: (0, 0)
- Modality 1 / 2
   └─ dimension: 0
2×1 SubDataFrame
 Row │ age
     │ Int64
─────┼───────
   1 │    25
   2 │    26
- Modality 2 / 2
   └─ dimension: 0
2×1 SubDataFrame
 Row │ sex
     │ Char
─────┼──────
   1 │ M
   2 │ F

julia> mod2 = modality(md, 2)
2×1 SubDataFrame
 Row │ sex
     │ Char
─────┼──────
   1 │ M
   2 │ F

julia> ninstances(md) == ninstances(md, 2) == ninstances(mod2) == 2
true
```
"""
ninstances(df::AbstractDataFrame) = nrow(df)
ninstances(md::AbstractMultiModalDataset) = nrow(data(md))
ninstances(md::AbstractMultiModalDataset, i::Integer) = nrow(modality(md, i))

"""
    pushinstances!(md, instance)

Add `instance` to a multimodal dataset and return `md`.

The instance can be a `DataFrameRow` or an `AbstractVector` but in both cases the number and
type of variables should match the dataset ones.
"""
function pushinstances!(md::AbstractMultiModalDataset, instance::DataFrameRow)
    @assert length(instance) == nvariables(md) "Mismatching number of variables " *
        "between dataset ($(nvariables(md))) and instance ($(length(instance)))"

    push!(data(md), instance)

    return md
end
function pushinstances!(md::AbstractMultiModalDataset, instance::AbstractVector)
    @assert length(instance) == nvariables(md) "Mismatching number of variables " *
        "between dataset ($(nvariables(md))) and instance ($(length(instance)))"

    push!(data(md), instance)

    return md
end
function pushinstances!(md::AbstractMultiModalDataset, instances::AbstractDataFrame)
    for inst in eachrow(instances)
        pushinstances!(md, inst)
    end

    return md
end

"""
    deleteinstances!(md, i)

Remove the `i`-th instance in a multimodal dataset.

The `AbstractMultiModalDataset` is returned.

    deleteinstances!(md, indices)

Remove the instances at `indices` in a multimodal dataset and return `md`.

The `AbstractMultiModalDataset` is returned.
"""
function deleteinstances!(md::AbstractMultiModalDataset, indices::AbstractVector{<:Integer})
    for i in indices
        @assert 1 ≤ i ≤ ninstances(md) "Index $(i) no in range 1:ninstances " *
            "(1:$(ninstances(md)))"
    end

    deleteat!(data(md), unique(indices))

    return md
end
deleteinstances!(md::AbstractMultiModalDataset, i::Integer) = deleteinstances!(md, [i])

"""
    keeponlyinstances!(md, indices)

Removes all instances that do not correspond to the indices present in `indices` from a
multimodal dataset.
"""
function keeponlyinstances!(
    md::AbstractMultiModalDataset,
    indices::AbstractVector{<:Integer}
)
    return deleteinstances!(md, setdiff(collect(1:ninstances(md)), indices))
end

"""
    instance(md, i)

Return `i`-th instance in a multimodal dataset.

    instance(md, i_modality, i_instance)

Return `i_instance`-th instance in a multimodal dataset with only variables present in
the `i_modality`-th modality.

    instance(md, indices)

Return instances at `indices` in a multimodal dataset.

    instance(md, i_modality, inst_indices)

Return indices at `inst_indices` in a multimodal dataset with only variables present in
the `i_modality`-th modality.
"""
function instance(df::AbstractDataFrame, i::Integer)
    @assert 1 ≤ i ≤ ninstances(df) "Index ($i) must be a valid instance number " *
        "(1:$(ninstances(md))"

    return @view df[i,:]
end
function instance(md::AbstractMultiModalDataset, i::Integer)
    @assert 1 ≤ i ≤ ninstances(md) "Index ($i) must be a valid instance number " *
        "(1:$(ninstances(md))"

    return instance(data(md), i)
end
function instance(md::AbstractMultiModalDataset, i_modality::Integer, i_instance::Integer)
    @assert 1 ≤ i_modality ≤ nmodalities(md) "Index ($i_modality) must be a valid " *
        "modality number (1:$(nmodalities(md))"

    return instance(modality(md, i_modality), i_instance)
end
function instance(df::AbstractDataFrame, indices::AbstractVector{<:Integer})
    for i in indices
        @assert 1 ≤ i ≤ ninstances(df) "Index ($i) must be a valid instance number " *
            "(1:$(ninstances(md))"
    end

    return @view df[indices,:]
end
function instance(md::AbstractMultiModalDataset, indices::AbstractVector{<:Integer})
    return instance(data(md), indices)
end
function instance(
    md::AbstractMultiModalDataset,
    i_modality::Integer,
    inst_indices::AbstractVector{<:Integer}
)
    @assert 1 ≤ i_modality ≤ nmodalities(md) "Index ($i_modality) must be a valid " *
        "modality number (1:$(nmodalities(md))"

    return instance(modality(md, i_modality), inst_indices)
end
