

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
labels_descriptor(lmfd::AbstractLabeledMultiFrameDataset) = lmfd.labels_descriptor
dataset(lmfd::AbstractLabeledMultiFrameDataset) = lmfd.mfd

# -------------------------------------------------------------
# LabeledMultiFrameDataset - informations

function show(io::IO, lmfd::AbstractLabeledMultiFrameDataset)
    println(io, "● LabeledMultiFrameDataset")
    println(io, "   ├─ labels")

    if nlabels(lmfd) > 0
        for i in 1:(nlabels(lmfd)-1)
            println(io, "   │   ├─ $(label(lmfd, i)): $(_print_label_domain(labeldomain(lmfd, i)))")
        end
        println(io, "   │   └─ $(label(lmfd, nlabels(lmfd))): " *
            "$(_print_label_domain(labeldomain(lmfd, nlabels(lmfd))))")
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
