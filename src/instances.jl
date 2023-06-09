
# -------------------------------------------------------------
# AbstractMultiModalDataset - instances manipulation

"""
    ninstances(md)

Return the number of instances in a multimodal dataset.

## EXAMPLES

```julia-repl
julia> md = MultiModalDataset([[1],[2]],DataFrame(:age => [25, 26], :sex => ['M', 'F']))
● MultiModalDataset
   └─ dimensionalities: (0, 0)
- Modality 1 / 2
   └─ dimensionality: 0
2×1 SubDataFrame
 Row │ age
     │ Int64
─────┼───────
   1 │    25
   2 │    26
- Modality 2 / 2
   └─ dimensionality: 0
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

julia> ninstances(md) == ninstances(mod2) == 2
true
```
"""
ninstances(df::AbstractDataFrame) = nrow(df)
ninstances(md::AbstractMultiModalDataset) = nrow(data(md))
# ninstances(md::AbstractMultiModalDataset, i::Integer) = nrow(modality(md, i))

"""
    pushinstances!(md, instance)

Add an instance to a multimodal dataset, and return the dataset itself.

The instance can be a `DataFrameRow` or an `AbstractVector` but in both cases the number and
type of variables should match those of the dataset.
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

Remove the `i`-th instance in a multimodal dataset, and return the dataset itself.


    deleteinstances!(md, i_instances)

Remove the instances at `i_instances` in a multimodal dataset, and return the dataset itself.

"""
function deleteinstances!(md::AbstractMultiModalDataset, i_instances::AbstractVector{<:Integer})
    for i in i_instances
        @assert 1 ≤ i ≤ ninstances(md) "Index $(i) no in range 1:ninstances " *
            "(1:$(ninstances(md)))"
    end

    deleteat!(data(md), unique(i_instances))

    return md
end
deleteinstances!(md::AbstractMultiModalDataset, i::Integer) = deleteinstances!(md, [i])

"""
    keeponlyinstances!(md, i_instances)

Remove all instances from a multimodal dataset, which index does not appear in `i_instances`.
"""
function keeponlyinstances!(
    md::AbstractMultiModalDataset,
    i_instances::AbstractVector{<:Integer}
)
    return deleteinstances!(md, setdiff(collect(1:ninstances(md)), i_instances))
end

"""
    instance(md, i)

Return the `i`-th instance in a multimodal dataset.


    instance(md, i_modality, i_instance)

Return the `i_instance`-th instance in a multimodal dataset with only variables from the
the `i_modality`-th modality.


    instance(md, i_instances)

Return instances at `i_instances` in a multimodal dataset.


    instance(md, i_modality, i_instances)

Return i_instances at `i_instances` in a multimodal dataset with only variables from the
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
function instance(df::AbstractDataFrame, i_instances::AbstractVector{<:Integer})
    for i in i_instances
        @assert 1 ≤ i ≤ ninstances(df) "Index ($i) must be a valid instance number " *
            "(1:$(ninstances(md))"
    end

    return @view df[i_instances,:]
end
function instance(md::AbstractMultiModalDataset, i_instances::AbstractVector{<:Integer})
    return instance(data(md), i_instances)
end
function instance(
    md::AbstractMultiModalDataset,
    i_modality::Integer,
    i_instances::AbstractVector{<:Integer}
)
    @assert 1 ≤ i_modality ≤ nmodalities(md) "Index ($i_modality) must be a valid " *
        "modality number (1:$(nmodalities(md))"

    return instance(modality(md, i_modality), i_instances)
end

function eachinstance(md::AbstractMultiModalDataset)
    df = data(md)
    Iterators.map(i->(@view df[i,:]), 1:ninstances(md))
end
