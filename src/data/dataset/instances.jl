
# -------------------------------------------------------------
# AbstractMultiFrameDataset - instances manipulation

"""
    ninstances(mfd[, i])

Get the number of instances present in `mfd` multiframe dataset.

Note: for consistency with other methods interface `ninstances` can be called specifying
a frame index `i` even if `ninstances(mfd) != ninstances(mfd, i)` can't be `true`.

This method can be called on a single frame directly.

# Examples
```jldoctest
julia> mfd = MultiFrameDataset([[1],[2]],DataFrame(:age => [25, 26], :sex => ['M', 'F']))
● MultiFrameDataset
   └─ dimensions: (0, 0)
- Frame 1 / 2
   └─ dimension: 0
2×1 SubDataFrame
 Row │ age
     │ Int64
─────┼───────
   1 │    25
   2 │    26
- Frame 2 / 2
   └─ dimension: 0
2×1 SubDataFrame
 Row │ sex
     │ Char
─────┼──────
   1 │ M
   2 │ F

julia> frame2 = frame(mfd, 2)
2×1 SubDataFrame
 Row │ sex
     │ Char
─────┼──────
   1 │ M
   2 │ F

julia> ninstances(mfd) == ninstances(mfd, 2) == ninstances(frame2) == 2
true
```
"""
ninstances(df::AbstractDataFrame) = nrow(df)
ninstances(mfd::AbstractMultiFrameDataset) = nrow(data(mfd))
ninstances(mfd::AbstractMultiFrameDataset, i::Integer) = nrow(frame(mfd, i))

"""
    pushinstances!(mfd, instance)

Add `instance` to `mfd` multiframe dataset and return `mfd`.

The instance can be a `DataFrameRow` or an `AbstractVector` but in both cases the number and
type of attributes should match the dataset ones.

TODO: add assertion on types?
push! already throws an Exception for mismatching types in columns
"""
function pushinstances!(mfd::AbstractMultiFrameDataset, instance::DataFrameRow)
    @assert length(instance) == nattributes(mfd) "Mismatching number of attributes " *
        "between dataset ($(nattributes(mfd))) and instance ($(length(instance)))"

    push!(data(mfd), instance)

    return mfd
end
function pushinstances!(mfd::AbstractMultiFrameDataset, instance::AbstractVector)
    @assert length(instance) == nattributes(mfd) "Mismatching number of attributes " *
        "between dataset ($(nattributes(mfd))) and instance ($(length(instance)))"

    push!(data(mfd), instance)

    return mfd
end
function pushinstances!(mfd::AbstractMultiFrameDataset, instances::AbstractDataFrame)
    for inst in eachrow(instances)
        pushinstances!(mfd, inst)
    end

    return mfd
end

"""
    deleteinstances!(mfd, i)

Remove the `i`-th instance in `mfd` multiframe dataset.

The `AbstractMultiFrameDataset` is returned.

    deleteinstances!(mfd, indices)

Remove the instances at `indices` in `mfd` multiframe dataset and return `mfd`.

The `AbstractMultiFrameDataset` is returned.
"""
function deleteinstances!(mfd::AbstractMultiFrameDataset, indices::AbstractVector{<:Integer})
    for i in indices
        @assert 1 ≤ i ≤ ninstances(mfd) "Index $(i) no in range 1:ninstances " *
            "(1:$(ninstances(mfd)))"
    end

    delete!(data(mfd), unique(indices))

    return mfd
end
deleteinstances!(mfd::AbstractMultiFrameDataset, i::Integer) = deleteinstances!(mfd, [i])

"""
    keeponlyinstances!(mfd, indices)

Removes all instances that do not correspond to the indices present in `indices` from `mfd`
multiframe dataset.
"""
function keeponlyinstances!(
    mfd::AbstractMultiFrameDataset,
    indices::AbstractVector{<:Integer}
)
    return deleteinstances!(mfd, setdiff(collect(1:ninstances(mfd)), indices))
end

"""
    instance(mfd, i)

Get `i`-th instance in `mfd` multiframe dataset.

    instance(mfd, i_frame, i_instance)

Get `i_instance`-th instance in `mfd` multiframe dataset with only attributes present in
the `i_frame`-th frame.

    instance(mfd, indices)

Get instances at `indices` in `mfd` multiframe dataset.

    instance(mfd, i_frame, inst_indices)

Get indices at `inst_indices` in `mfd` multiframe dataset with only attributes present in
the `i_frame`-th frame.
"""
function instance(df::AbstractDataFrame, i::Integer)
    @assert 1 ≤ i ≤ ninstances(df) "Index ($i) must be a valid instance number " *
        "(1:$(ninstances(mfd))"

    return @view df[i,:]
end
function instance(mfd::AbstractMultiFrameDataset, i::Integer)
    @assert 1 ≤ i ≤ ninstances(mfd) "Index ($i) must be a valid instance number " *
        "(1:$(ninstances(mfd))"

    return instance(data(mfd), i)
end
function instance(mfd::AbstractMultiFrameDataset, i_frame::Integer, i_instance::Integer)
    @assert 1 ≤ i_frame ≤ nframes(mfd) "Index ($i_frame) must be a valid " *
        "frame number (1:$(nframes(mfd))"

    return instance(frame(mfd, i_frame), i_instance)
end
function instance(df::AbstractDataFrame, indices::AbstractVector{<:Integer})
    for i in indices
        @assert 1 ≤ i ≤ ninstances(df) "Index ($i) must be a valid instance number " *
            "(1:$(ninstances(mfd))"
    end

    return @view df[indices,:]
end
function instance(mfd::AbstractMultiFrameDataset, indices::AbstractVector{<:Integer})
    return instance(data(mfd), indices)
end
function instance(
    mfd::AbstractMultiFrameDataset,
    i_frame::Integer,
    inst_indices::AbstractVector{<:Integer}
)
    @assert 1 ≤ i_frame ≤ nframes(mfd) "Index ($i_frame) must be a valid " *
        "frame number (1:$(nframes(mfd))"

    return instance(frame(mfd, i_frame), inst_indices)
end
