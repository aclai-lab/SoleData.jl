
# -------------------------------------------------------------
# ClassificationMultiFrameDataset

"""
TODO: docs
"""
struct ClassificationMultiFrameDataset <: AbstractClassificationMultiFrameDataset
    class_descriptor::AbstractVector{Integer}
    mfd::AbstractMultiFrameDataset

    function ClassificationMultiFrameDataset(
        classes_descriptor::AbstractVector{<:Integer},
        mfd::AbstractMultiFrameDataset
    )
        for i in classes_descriptor
            if _is_attribute_in_frames(mfd, i)
                # TODO: consider enforcing this instead of just warning
                @warn "Setting as class an attribute used in a frame: this is discouraged " *
                    "and probably will not allowed in future versions"
            end
        end

        return new(classes_descriptor, mfd)
    end
end

# -------------------------------------------------------------
# ClassificationMultiFrameDataset - accessors

descriptor(cmfd::ClassificationMultiFrameDataset) = descriptor(cmfd.mfd)
frame_descriptor(cmfd::ClassificationMultiFrameDataset) = descriptor(cmfd)
data(cmfd::ClassificationMultiFrameDataset) = data(cmfd.mfd)
classes_descriptor(cmfd::ClassificationMultiFrameDataset) = cmfd.class_descriptor
dataset(cmfd::ClassificationMultiFrameDataset) = cmfd.mfd

# -------------------------------------------------------------
# ClassificationMultiFrameDataset - informations

function show(io::IO, cmfd::ClassificationMultiFrameDataset)
    println(io, "● ClassificationMultiFrameDataset")
    println(io, "   ├─ classes")

    if nclasses(cmfd) > 0
        for i in 1:(nclasses(cmfd)-1)
            println(io, "   │   ├─ $(class(cmfd, i)): $(_print_class_domain(classdomain(cmfd, i)))")
        end
        println(io, "   │   └─ $(class(cmfd, nclasses(cmfd))): " *
            "$(_print_class_domain(classdomain(cmfd, nclasses(cmfd))))")
    else
        println(io, "   │   └─ no class selected")
    end
    println(io, "   └─ dimensions: $(dimension(cmfd))")

    # TODO: perhaps show(dataset(cmfd))?
    for (i, frame) in enumerate(cmfd)
        println(io, "- Frame $(i) / $(nframes(cmfd))")
        println(io, "   └─ dimension: $(dimension(frame))")
        println(io, frame)
    end

    spare_attrs = spareattributes(cmfd)
    if length(spare_attrs) > 0
        spare_df = @view data(cmfd)[:,spare_attrs]
        println(io, "- Spare attributes")
        println(io, "   └─ dimension: $(dimension(spare_df))")
        println(io, spare_df)
    end
end

# -------------------------------------------------------------
# ClassificationMultiFrameDataset - utils

function _empty(cmfd::ClassificationMultiFrameDataset)
    return ClassificationMultiFrameDataset(
        deepcopy(descriptor(cmfd)),
        df = DataFrame([attr_name => [] for attr_name in Symbol.(names(data(cmfd)))])
    )
end
