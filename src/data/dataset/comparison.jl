
# -------------------------------------------------------------
# AbstractMultiFrameDataset - comparison

"""
    ==(mfd1, mfd2)
    isequal(mfd1, mfd2)

Determine whether two AbstractMultiFrameDatasets are equal.

Note: the check is also performed on the instances. This means that if the two datasets are
the same but they differ by instance order this will return `false`.

If the intent is to check if two AbstractMultiFrameDatasets have same instances regardless
of the order use [`isapproxeq`](@ref) instead.
If the intent is to check if two AbstractMultiFrameDatasets have same frame descriptors and
attributes use [`isapprox`](@ref) instead.
"""
function isequal(mfd1::AbstractMultiFrameDataset, mfd2::AbstractMultiFrameDataset)
    return (data(mfd1) == data(mfd2) && descriptor(mfd1) == descriptor(mfd2)) ||
        _same_multiframedataset(mfd1, mfd2)
end
function ==(mfd1::AbstractMultiFrameDataset, mfd2::AbstractMultiFrameDataset)
    return isequal(mfd1, mfd2)
end

"""
    ≊(mfd1, mfd2)
    isapproxeq(mfd1, mfd2)

Determine whether two AbstractMultiFrameDatasets are "approximately" equivalent.

Two AbstractMultiFrameDatasets are considered "approximately" equivalent if they have
same frame descriptors, attributes and instances.

Note: this means that the order of the instance in the datasets does not matter.

If the intent is to check if two AbstractMultiFrameDatasets have same instances in the
same order use [`isequal`](@ref) instead.
If the intent is to check if two AbstractMultiFrameDatasets have same frame descriptors and
attributes use [`isapprox`](@ref) instead.

TODO review
"""
function isapproxeq(mfd1::AbstractMultiFrameDataset, mfd2::AbstractMultiFrameDataset)
    return isequal(mfd1, mfd2) && _same_instances(mfd1, mfd2)
end
function ≊(mfd1::AbstractMultiFrameDataset, mfd2::AbstractMultiFrameDataset)
    return isapproxeq(mfd1, mfd2)
end

"""
    ≈(mfd1, mfd2)
    isapprox(mfd1, mfd2)

Determine whether two AbstractMultiFrameDatasets are similar.

Two AbstractMultiFrameDatasets are considered similar if they have same frame descriptors
and attributes. Note that this means no check over instances is performed.

If the intent is to check if two AbstractMultiFrameDatasets have same instances in the same
order use [`isequal`](@ref) instead.
If the intent is to check if two AbstractMultiFrameDatasets have same instances regardless
of the order use [`isapproxeq`](@ref) instead.
"""
function isapprox(mfd1::AbstractMultiFrameDataset, mfd2::AbstractMultiFrameDataset)
    # note: _same_descriptor already includes attributes checking
    return _same_descriptor(mfd1, mfd2)
end
