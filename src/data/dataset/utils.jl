
# -------------------------------------------------------------
# AbstractMultiFrameDataset - utils

"""
    _empty(mfd)

Get a copy of `mfd` multiframe dataset with no instances.

Note: since the returned AbstractMultiFrameDataset will be empty its columns types will be
`Any`.
"""
function _empty(mfd::AbstractMultiFrameDataset)
    warn("This function is extremly not efficent expecally for large datasets: " *
        "consider creating a dispatch for type " * string(typeof(mfd)))
    return _empty!(deepcopy(mfd))
end
"""
    _empty!(mfd)

Remove all instances from `mfd` multiframe dataset.

Note: since the AbstractMultiFrameDataset will be empty its columns types will become of
type `Any`.
"""
function _empty!(mfd::AbstractMultiFrameDataset)
    return removeinstances!(mfd, 1:nisnstances(mfd))
end

"""
    _same_attributes(mfd1, mfd2)

Determine whether two AbstractMultiFrameDatasets have the same attributes.
"""
function _same_attributes(mfd1::AbstractMultiFrameDataset, mfd2::AbstractMultiFrameDataset)
    return isequal(
        Dict{Symbol,DataType}(Symbol.(names(data(mfd1))) .=> eltype.(eachcol(data(mfd1)))),
        Dict{Symbol,DataType}(Symbol.(names(data(mfd2))) .=> eltype.(eachcol(data(mfd2))))
    )
end

"""
    _same_dataframe(mfd1, mfd2)

Determine whether two AbstractMultiFrameDatasets have the same inner DataFrame regardless of
the positioning of their columns.

Note: the check will performed against the instances too; if the intent is to just check
the presence of the same attributes use [`_same_attributes`](@ref) instead.
"""
function _same_dataframe(mfd1::AbstractMultiFrameDataset, mfd2::AbstractMultiFrameDataset)
    if !_same_attributes(mfd1, mfd2) || ninstances(mfd1) != ninstances(mfd2)
        return false
    end

    mfd1_attrs = Symbol.(names(data(mfd1)))
    mfd2_attrs = Symbol.(names(data(mfd2)))
    unmixed_indices = [findfirst(x -> isequal(x, name), mfd2_attrs) for name in mfd1_attrs]

    data(mfd1) == data(mfd2)[:,unmixed_indices]
end

"""
    _same_descriptor(mfd1, mfd2)

Determine whether two AbstractMultiFrameDatasets have the same frames regardless of the
positioning of their columns.

Note: the check will performed against the instances too; if the intent is to just check
the presence of the same attributes use [`_same_attributes`](@ref) instead.
"""
function _same_descriptor(mfd1::AbstractMultiFrameDataset, mfd2::AbstractMultiFrameDataset)
    if !_same_attributes(mfd1, mfd2)
        return false
    end

    if nframes(mfd1) != nframes(mfd2) ||
            [nattributes(f) for f in mfd1] != [nattributes(f) for f in mfd2]
        return false
    end

    mfd1_attrs = Symbol.(names(data(mfd1)))
    mfd2_attrs = Symbol.(names(data(mfd2)))
    unmixed_indices = [findfirst(x -> isequal(x, name), mfd2_attrs) for name in mfd1_attrs]

    for i in 1:nframes(mfd1)
        if descriptor(mfd1)[i] != Integer[unmixed_indices[j] for j in descriptor(mfd2)[i]]
            return false
        end
    end

    return true
end

"""
    _same_instances(mfd1, mfd2)

Determine whether two AbstractMultiFrameDatasets have the same instances regardless of their
order.
"""
function _same_instances(mfd1::AbstractMultiFrameDataset, mfd2::AbstractMultiFrameDataset)
    if !_same_attributes(mfd1, mfd2) || ninstances(mfd1) != ninstances(mfd2)
        return false
    end

    return mfd1 ⊆ mfd2 && mfd2 ⊆ mfd1
end

"""
    _same_multiframedataset(mfd1, mfd2)

Determine whether two AbstractMultiFrameDatasets have the same inner DataFrame and frames
regardless of the positioning of their columns.

Note: the check will performed against the instances too; if the intent is to just check
the presence of the same attributes use [`_same_attributes`](@ref) instead.

TODO perhaps could be done better? E.g. using the aforedefined functions.
"""
function _same_multiframedataset(mfd1::AbstractMultiFrameDataset, mfd2::AbstractMultiFrameDataset)
    if !_same_attributes(mfd1, mfd2) || ninstances(mfd1) != ninstances(mfd2)
        return false
    end

    if nframes(mfd1) != nframes(mfd2) ||
            [nattributes(f) for f in mfd1] != [nattributes(f) for f in mfd2]
        return false
    end

    mfd1_attrs = Symbol.(names(data(mfd1)))
    mfd2_attrs = Symbol.(names(data(mfd2)))
    unmixed_indices = [findfirst(x -> isequal(x, name), mfd2_attrs) for name in mfd1_attrs]

    if data(mfd1) != data(mfd2)[:,unmixed_indices]
        return false
    end

    for i in 1:nframes(mfd1)
        if descriptor(mfd1)[i] != Integer[unmixed_indices[j] for j in descriptor(mfd2)[i]]
            return false
        end
    end

    return true
end

"""
    _name2index(df, attribute_name)

Get the index of the attribute named `attribute_name`.

If the attribute does not exist `0` will be returned.


    _name2index(df, attribute_names)

Get the indices of the attributes named `attribute_names`.

If an attribute does not exist the returned Vector will contain `0`(-es).
"""
function _name2index(df::AbstractDataFrame, attribute_name::Symbol)
    columnindex(df, attribute_name)
end
function _name2index(mfd::AbstractMultiFrameDataset, attribute_name::Symbol)
    columnindex(data(mfd), attribute_name)
end
function _name2index(df::AbstractDataFrame, attribute_names::AbstractVector{Symbol})
    [_name2index(df, attr_name) for attr_name in attribute_names]
end
function _name2index(mfd::AbstractMultiFrameDataset, attribute_names::AbstractVector{Symbol})
    [_name2index(mfd, attr_name) for attr_name in attribute_names]
end
