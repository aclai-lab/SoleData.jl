

# -------------------------------------------------------------
# LabeledMultiFrameDataset

"""
TODO: docs
"""
struct LabeledMultiFrameDataset <: AbstractLabeledMultiFrameDataset
    labels_descriptor::AbstractVector{Integer}
    mfd::AbstractMultiFrameDataset

    function LabeledMultiFrameDataset(
        labels_descriptor::AbstractVector{<:Integer},
        mfd::AbstractMultiFrameDataset
    )
        for i in labels_descriptor
            if _is_attribute_in_frames(mfd, i)
                # TODO: consider enforcing this instead of just warning
                @warn "Setting as label an attribute used in a frame: this is discouraged " *
                    "and probably will not allowed in future versions"
            end
        end

        return new(labels_descriptor, mfd)
    end
end

# -------------------------------------------------------------
# LabeledMultiFrameDataset - accessors

descriptor(lmfd::AbstractLabeledMultiFrameDataset) = descriptor(lmfd.mfd)
frame_descriptor(lmfd::AbstractLabeledMultiFrameDataset) = descriptor(lmfd)
data(lmfd::AbstractLabeledMultiFrameDataset) = data(lmfd.mfd)
labels_descriptor(lmfd::LabeledMultiFrameDataset) = lmfd.labels_descriptor
dataset(lmfd::LabeledMultiFrameDataset) = lmfd.mfd

# -------------------------------------------------------------
# LabeledMultiFrameDataset - informations

function show(io::IO, lmfd::AbstractLabeledMultiFrameDataset)
    println(io, "● LabeledMultiFrameDataset")
    println(io, "   ├─ labels")

    if nlabels(lmfd) > 0
        lbls = labels(lmfd)
        for i in 1:(length(lbls)-1)
            println(io, "   │   ├─ $(lbls[i]): " *
                "$(labeldomain(lmfd, i))")
        end
        println(io, "   │   └─ $(lbls[end]): " *
            "$(labeldomain(lmfd, length(lbls)))")
    else
        println(io, "   │   └─ no label selected")
    end
    println(io, "   └─ dimensions: $(dimension(lmfd))")

    _prettyprint_frames(io, lmfd)
    _prettyprint_spareattributes(io, lmfd)
end

# -------------------------------------------------------------
# LabeledMultiFrameDataset - utils

function _empty(lmfd::AbstractLabeledMultiFrameDataset)
    return LabeledMultiFrameDataset(
        deepcopy(descriptor(lmfd)),
        df = DataFrame([attr_name => [] for attr_name in Symbol.(names(data(lmfd)))])
    )
end
