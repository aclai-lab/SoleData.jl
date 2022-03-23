

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
                @warn "Setting as label an attribute used in a frame: this is " *
                    "discouraged and probably will not allowed in future versions"
            end
        end

        return new(labels_descriptor, mfd)
    end
end

# -------------------------------------------------------------
# LabeledMultiFrameDataset - accessors

frame_descriptor(lmfd::AbstractLabeledMultiFrameDataset) = frame_descriptor(lmfd.mfd)
data(lmfd::AbstractLabeledMultiFrameDataset) = data(lmfd.mfd)
labels_descriptor(lmfd::LabeledMultiFrameDataset) = lmfd.labels_descriptor
dataset(lmfd::LabeledMultiFrameDataset) = lmfd.mfd

# -------------------------------------------------------------
# LabeledMultiFrameDataset - informations

function show(io::IO, lmfd::AbstractLabeledMultiFrameDataset)
    println(io, "● LabeledMultiFrameDataset")
    _prettyprint_labels(io, lmfd)
    _prettyprint_frames(io, lmfd)
    _prettyprint_spareattributes(io, lmfd)
end

# -------------------------------------------------------------
# LabeledMultiFrameDataset - attributes

function spareattributes(lmfd::AbstractLabeledMultiFrameDataset)
    filter!(attr -> !(attr in labels_descriptor(lmfd)), spareattributes(dataset(lmfd)))
end

function dropattributes!(lmfd::AbstractLabeledMultiFrameDataset, i::Integer)
    dropattributes!(dataset(lmfd), i)

    for (i_lbl, lbl) in enumerate(labels_descriptor(lmfd))
        if lbl > i
            frame_descriptor(lmfd)[i_frame][i_lbl] = lbl - 1
        end
    end

    return lmfd
end

# -------------------------------------------------------------
# LabeledMultiFrameDataset - utils

function _empty(lmfd::AbstractLabeledMultiFrameDataset)
    return LabeledMultiFrameDataset(
        deepcopy(frame_descriptor(lmfd)),
        df = DataFrame([attr_name => [] for attr_name in Symbol.(names(data(lmfd)))])
    )
end
