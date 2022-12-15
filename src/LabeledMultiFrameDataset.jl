

# -------------------------------------------------------------
# LabeledMultiFrameDataset

"""
    LabeledMultiFrameDataset(labels_descriptor, mfd)

Create a `LabeledMultiFrameDataset` from an `AbstractMultiFrameDataset`, `mfd`, setting as
labels attributes at indices contained in `labels_descriptor`.

## PARAMETERS

* `labels_descriptor` is an `AbstractVector` of Integers indicating the indices of the
    attributes that will be set as labels;
* `mfd` is the original `AbstractMultiFrameDataset`.

## EXAMPLES

```jldoctest
julia> lmfd = LabeledMultiFrameDataset([1, 3], MultiFrameDataset([[2],[4]], DataFrame(
           :id => [1, 2],
           :age => [30, 9],
           :name => ["Python", "Julia"],
           :stat => [[sin(i) for i in 1:50000], [cos(i) for i in 1:50000]]
       )))
● LabeledMultiFrameDataset
   ├─ labels
   │   ├─ id: Set([2, 1])
   │   └─ name: Set(["Julia", "Python"])
   └─ dimensions: (0, 1)
- Frame 1 / 2
   └─ dimension: 0
2×1 SubDataFrame
 Row │ age
     │ Int64
─────┼───────
   1 │    30
   2 │     9
- Frame 2 / 2
   └─ dimension: 1
2×1 SubDataFrame
 Row │ stat
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…
   2 │ [0.540302, -0.416147, -0.989992,…

```
"""
struct LabeledMultiFrameDataset <: AbstractLabeledMultiFrameDataset
    labels_descriptor::Vector{Int}
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
            frame_descriptor(lmfd)[i][i_lbl] = lbl - 1
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
