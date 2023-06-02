
# -------------------------------------------------------------
# AbstractMultiModalDataset - comparison

"""
    ==(md1, md2)
    isequal(md1, md2)

Determine whether two AbstractMultiModalDatasets are equal.

Note: the check is also performed on the instances. This means that if the two datasets are
the same but they differ by instance order this will return `false`.

If the intent is to check if two AbstractMultiModalDatasets have same instances regardless
of the order use [`isapproxeq`](@ref) instead.
If the intent is to check if two AbstractMultiModalDatasets have same modality descriptors and
variables use [`isapprox`](@ref) instead.
"""
function isequal(md1::AbstractMultiModalDataset, md2::AbstractMultiModalDataset)
    return (data(md1) == data(md2) && grouped_variables(md1) == grouped_variables(md2)) ||
        (_same_md(md1, md2) && _same_label_descriptor(md1, md2))
end
function ==(md1::AbstractMultiModalDataset, md2::AbstractMultiModalDataset)
    return isequal(md1, md2)
end

"""
    ≊(md1, md2)
    isapproxeq(md1, md2)

Determine whether two AbstractMultiModalDatasets are "approximately" equivalent.

Two AbstractMultiModalDatasets are considered "approximately" equivalent if they have
same modality descriptors, variables and instances.

Note: this means that the order of the instance in the datasets does not matter.

If the intent is to check if two AbstractMultiModalDatasets have same instances in the
same order use [`isequal`](@ref) instead.
If the intent is to check if two AbstractMultiModalDatasets have same modality descriptors and
variables use [`isapprox`](@ref) instead.

TODO review
"""
function isapproxeq(md1::AbstractMultiModalDataset, md2::AbstractMultiModalDataset)
    return isequal(md1, md2) && _same_instances(md1, md2)
end
function ≊(md1::AbstractMultiModalDataset, md2::AbstractMultiModalDataset)
    return isapproxeq(md1, md2)
end

"""
    ≈(md1, md2)
    isapprox(md1, md2)

Determine whether two AbstractMultiModalDatasets are similar.

Two AbstractMultiModalDatasets are considered similar if they have same modality descriptors
and variables. Note that this means no check over instances is performed.

If the intent is to check if two AbstractMultiModalDatasets have same instances in the same
order use [`isequal`](@ref) instead.
If the intent is to check if two AbstractMultiModalDatasets have same instances regardless
of the order use [`isapproxeq`](@ref) instead.
"""
function isapprox(md1::AbstractMultiModalDataset, md2::AbstractMultiModalDataset)
    # NOTE: _same_grouped_variables already includes variables checking
    return _same_grouped_variables(md1, md2)
end
