
# -------------------------------------------------------------
# LabeledMultiFrameDataset - utils

"""
    nlabels(lmfd)

Get the number of labels in `lmfd` LabeledMultiFrameDataset.
"""
function nlabels(lmfd::AbstractLabeledMultiFrameDataset)
    return length(labels_descriptor(lmfd))
end

"""
    labels(lmfd, instance)
    labels(lmfd)

Get the labels of instance at index `instance` in `lmfd` LabeledMultiFrameDataset. Will
be returned a Dict of type `labelname => value`.

If only the first argument is passed then the names of all labels are returned.
"""
function labels(lmfd::AbstractLabeledMultiFrameDataset)
    return Symbol.(names(data(lmfd)))[labels_descriptor(lmfd)]
end
function labels(lmfd::AbstractLabeledMultiFrameDataset, instance::Integer)
    return Dict{Symbol,Any}([attr => data(lmfd)[instance,attr] for attr in labels(lmfd)]...)
end

"""
    label(lmfd, instance, label_index)

Get the label at `label_index` of instance at index `instance` in `lmfd`
LabeledMultiFrameDataset.
"""
function label(
    lmfd::AbstractLabeledMultiFrameDataset,
    instance::Integer,
    label_index::Integer
)
    return labels(lmfd, instance)labels(lmfd)[label_index]
end

"""
    labeldomain(lmfd, i)

Get the domain of `i`-th label of `lmfd` LabeledMultiFrameDataset.
"""
function labeldomain(lmfd::AbstractLabeledMultiFrameDataset, i::Integer)
    @assert 1 ≤ i ≤ nlabels(lmfd) "Index ($i) must be a valid label number " *
        "(1:$(nlabels(lmfd)))"

    if eltype(scitype(data(lmfd)[:,labels_descriptor(lmfd)[i]])) <: Continuous
        return extrema(data(lmfd)[:,labels_descriptor(lmfd)[i]])
    else
        return Set(data(lmfd)[:,labels_descriptor(lmfd)[i]])
    end
end

"""
    setaslabel!(lmfd, i)
    setaslabel!(lmfd, attr_name)

Set `i`-th attribute as label.

The attribute name can be passed as second argument instead of its index.
"""
function setaslabel!(lmfd::AbstractLabeledMultiFrameDataset, i::Integer)
    @assert 1 ≤ i ≤ nattributes(lmfd) "Index ($i) must be a valid attribute number " *
        "(1:$(nattributes(lmfd)))"

    @assert !(i in labels_descriptor(lmfd)) "Attribute at index $(i) is already a label."

    push!(labels_descriptor(lmfd), i)

    return lmfd
end
function setaslabel!(lmfd::AbstractLabeledMultiFrameDataset, attr_name::Symbol)
    @assert hasattributes(lmfd, attr_name) "LabeldMultiFrameDataset does not contain " *
        "attribute $(attr_name)"

    return setaslabel!(lmfd, _name2index(lmfd, attr_name))
end

"""
    removefromlabels!(lmfd, i)
    removefromlabels!(lmfd, attr_name)

Remove `i`-th attribute from labels list.

The attribute name can be passed as second argument instead of its index.
"""
function removefromlabels!(lmfd::AbstractLabeledMultiFrameDataset, i::Integer)
    @assert 1 ≤ i ≤ nattributes(lmfd) "Index ($i) must be a valid attribute number " *
        "(1:$(nattributes(lmfd)))"

    @assert i in labels_descriptor(lmfd) "Attribute at index $(i) is not a label."

    deleteat!(labels_descriptor(lmfd), indexin(i, labels_descriptor(lmfd))[1])

    return lmfd
end
function removefromlabels!(lmfd::AbstractLabeledMultiFrameDataset, attr_name::Symbol)
    @assert hasattributes(lmfd, attr_name) "LabeledMultiFrameDataset does not contain " *
        "attribute $(attr_name)"

    return removefromlabels!(lmfd, _name2index(lmfd, attr_name))
end

# TODO: this function could recall the spareattributes on AbstractMultiFrameDataset?
function spareattributes(lmfd::AbstractLabeledMultiFrameDataset)
    filter!(attr -> !(attr in labels_descriptor(lmfd)), spareattributes(dataset(lmfd)))
end
