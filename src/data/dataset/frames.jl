
# -------------------------------------------------------------
# AbstractMultiFrameDataset - frames

"""
    frame(mfd, i)

Get the `i`-th frame of `mfd` multiframe dataset.

    frame(mfd, indices)

Get a Vector of frames at `indices` of `mfd` multiframe dataset.
"""
function frame(mfd::AbstractMultiFrameDataset, i::Integer)
    @assert 1 ≤ i ≤ nframes(mfd) "Index ($i) must be a valid frame number " *
        "(1:$(nframes(mfd)))"

    return @view data(mfd)[:,descriptor(mfd)[i]]
end
function frame(mfd::AbstractMultiFrameDataset, indices::AbstractVector{<:Integer})
    return [frame(mfd, i) for i in indices]
end

"""
    nframes(mfd)

Get the number of frames of `mfd` multiframe dataset.
"""
nframes(mfd::AbstractMultiFrameDataset) = length(descriptor(mfd))

"""
    addframe!(mfd, indices)
    addframe!(mfd, attribute_names)

Create a new frame in `mfd` multiframe dataset using attributes at `indices` and return
`mfd`.

Alternatively to the `indices` the attribute names can be used.

Note: to add a new frame with new attributes see [`insertframe!`](@ref).

# Examples
```jldoctest
julia> df = DataFrame(
           :age => [30, 9],
           :name => ["Python", "Julia"],
           :stat1 => [[sin(i) for i in 1:50000], [cos(i) for i in 1:50000]]
       )
2×3 DataFrame
 Row │ age    name    stat1
     │ Int64  String  Array…
─────┼──────────────────────────────────────────────────
   1 │    30  Python  [0.841471, 0.909297, 0.14112, -0…
   2 │     9  Julia   [0.540302, -0.416147, -0.989992,…

julia> mfd = MultiFrameDataset([[1,2]], df)
● MultiFrameDataset
   └─ dimensions: (0,)
- Frame 1 / 1
   └─ dimension: 0
2×2 SubDataFrame
 Row │ age    name
     │ Int64  String
─────┼───────────────
   1 │    30  Python
   2 │     9  Julia
- Spare attributes
   └─ dimension: 1
2×1 SubDataFrame
 Row │ stat1
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…
   2 │ [0.540302, -0.416147, -0.989992,…


julia> addframe!(mfd, [3])
● MultiFrameDataset
   └─ dimensions: (0, 1)
- Frame 1 / 2
   └─ dimension: 0
2×2 SubDataFrame
 Row │ age    name
     │ Int64  String
─────┼───────────────
   1 │    30  Python
   2 │     9  Julia
- Frame 2 / 2
   └─ dimension: 1
2×1 SubDataFrame
 Row │ stat1
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…
   2 │ [0.540302, -0.416147, -0.989992,…
```
"""
function addframe!(mfd::AbstractMultiFrameDataset, indices::AbstractVector{<:Integer})
    @assert length(indices) > 0 "Can't add an empty frame to dataset"

    for i in indices
        @assert i in 1:nattributes(mfd) "Index $(i) is out of range 1:nattributes " *
            "(1:$(nattributes(mfd)))"
    end

    push!(descriptor(mfd), indices)

    return mfd
end
# TODO: addframe! with Integer
function addframe!(mfd::AbstractMultiFrameDataset, attribute_names::AbstractVector{Symbol})
    for attr_name in attribute_names
        @assert hasattributes(mfd, attr_name) "MultiFrameDataset does not contain " *
            "attribute $(attr_name)"
    end

    return addframe!(mfd, _name2index(mfd, attribute_names))
end
# TODO: addframe! with Symbol

"""
    removeframe!(mfd, i)

Remove `i`-th frame from `mfd` multiframe dataset and return `mfd`.

Note: to completely remove a frame and all attributes in it use [`dropframe!`](@ref)
instead.

# Examples
```jldoctest
julia> df = DataFrame(
           :age => [30, 9],
           :name => ["Python", "Julia"],
           :stat1 => [[sin(i) for i in 1:50000], [cos(i) for i in 1:50000]]
       )
2×3 DataFrame
 Row │ age    name    stat1
     │ Int64  String  Array…
─────┼──────────────────────────────────────────────────
   1 │    30  Python  [0.841471, 0.909297, 0.14112, -0…
   2 │     9  Julia   [0.540302, -0.416147, -0.989992,…

julia> mfd = MultiFrameDataset([[1,2], [3]], df)
● MultiFrameDataset
   └─ dimensions: (0, 1)
- Frame 1 / 2
   └─ dimension: 0
2×2 SubDataFrame
 Row │ age    name
     │ Int64  String
─────┼───────────────
   1 │    30  Python
   2 │     9  Julia
- Frame 2 / 2
   └─ dimension: 1
2×1 SubDataFrame
 Row │ stat1
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…
   2 │ [0.540302, -0.416147, -0.989992,…


julia> removeframe!(mfd, 2)
● MultiFrameDataset
   └─ dimensions: (0,)
- Frame 1 / 1
   └─ dimension: 0
2×2 SubDataFrame
 Row │ age    name
     │ Int64  String
─────┼───────────────
   1 │    30  Python
   2 │     9  Julia
- Spare attributes
   └─ dimension: 1
2×1 SubDataFrame
 Row │ stat1
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…
   2 │ [0.540302, -0.416147, -0.989992,…
```
"""
# TODO: add removeframe! with AbstractVector{<:Integer}
function removeframe!(mfd::AbstractMultiFrameDataset, i::Integer)
    @assert 1 ≤ i ≤ nframes(mfd) "Index $(i) does not correspond to a frame " *
        "(1:$(nframes(mfd)))"

    deleteat!(descriptor(mfd), i)

    return mfd
end

"""
    addattribute_toframe!(mfd, frame_index, attr_index)
    addattribute_toframe!(mfd, frame_index, attr_name)

Add attribute at index `attr_index` to the frame at index `frame_index` in `mfd` multiframe
dataset and return `mfd`.

Alternatively to `attr_index` the attribute name can be used.

TODO: examples & review
"""
# TODO: add addattribute_toframe! with AbstractVector{<:Integer}
function addattribute_toframe!(
    mfd::AbstractMultiFrameDataset, frame_index::Integer, attr_index::Integer
)
    @assert 1 ≤ frame_index ≤ nframes(mfd) "Index $(frame_index) does not correspond " *
        "to a frame (1:$(nframes(mfd)))"
    @assert 1 ≤ attr_index ≤ nattributes(mfd) "Index $(attr_index) does not correspond " *
        "to an attribute (1:$(nattributes(mfd)))"

    if attr_index in descriptor(mfd)[frame_index]
        @info "Attribute $(attr_index) is already part of frame $(frame_index)"
    else
        push!(descriptor(mfd)[frame_index], attr_index)
    end

    return mfd
end
# TODO: add addattribute_toframe! with AbstractVector{Symbol}
function addattribute_toframe!(
    mfd::AbstractMultiFrameDataset, frame_index::Integer, attr_name::Symbol
)
    @assert hasattributes(mfd, attr_name) "MultiFrameDataset does not contain attribute " *
        "$(attr_name)"

    return addattribute_toframe!(mfd, frame_index, _name2index(mfd, attr_name))
end

"""
    removeattribute_fromframe!(mfd, farme_index, attr_index)
    removeattribute_fromframe!(mfd, farme_index, attr_name)

Remove attribute at index `attr_index` from the frame at index `frame_index` in `mfd`
multiframe dataset and return `mfd`.

Alternatively to `attr_index` the attribute name can be used.

TODO: examples & review
"""
# TODO: should be dropattribute_fromframe!
# TODO: add dropattribute_toframe! with AbstractVector{<:Integer}
function removeattribute_fromframe!(
    mfd::AbstractMultiFrameDataset, frame_index::Integer, attr_index::Integer
)
    @assert 1 ≤ frame_index ≤ nframes(mfd) "Index $(frame_index) does not correspond " *
        "to a frame (1:$(nframes(mfd)))"
    @assert 1 ≤ attr_index ≤ nattributes(mfd) "Index $(attr_index) does not correspond " *
        "to an attribute (1:$(nattributes(mfd)))"

    if !(attr_index in descriptor(mfd)[frame_index])
        @info "Attribute $(attr_index) is not part of frame $(frame_index)"
    elseif nattributes(mfd, frame_index) == 1
        @info "Attribute $(attr_index) was last attribute of frame $(frame_index): " *
            "removing frame"
        removeframe!(mfd, frame_index)
    else
        deleteat!(
            descriptor(mfd)[frame_index],
            indexin(attr_index, descriptor(mfd)[frame_index])[1]
        )
    end

    return mfd
end
# TODO: add dropattribute_toframe! with AbstractVector{Symbol}
function removeattribute_fromframe!(
    mfd::AbstractMultiFrameDataset, frame_index::Integer, attr_name::Symbol
)
    @assert hasattributes(mfd, attr_name) "MultiFrameDataset does not contain attribute " *
        "$(attr_name)"

    return removeattribute_fromframe!(mfd, frame_index, _name2index(mfd, attr_name))
end

"""
    insertframe!(mfd[, col], new_frame)

Insert `new_frame` as new frame to `mfd` multiframe dataset and return `mfd`.

`new_frame` has to be an `AbstractDataFrame`.

Existing attributes can be added to the new frame while adding it to the dataset passing
the corresponding inidices by `existing_attributes`.

If `col` is specified then the the attributes will be inserted starting at index `col`.

TODO: To be reviewed.

# Examples
```jldoctest
julia> df = DataFrame(
           :name => ["Python", "Julia"],
           :stat1 => [[sin(i) for i in 1:50000], [cos(i) for i in 1:50000]]
       )
2×2 DataFrame
 Row │ name    stat1
     │ String  Array…
─────┼───────────────────────────────────────────
   1 │ Python  [0.841471, 0.909297, 0.14112, -0…
   2 │ Julia   [0.540302, -0.416147, -0.989992,…

julia> mfd = MultiFrameDataset(df; group = :all)
● MultiFrameDataset
   └─ dimensions: (0, 1)
- Frame 1 / 2
   └─ dimension: 0
2×1 SubDataFrame
 Row │ name
     │ String
─────┼────────
   1 │ Python
   2 │ Julia
- Frame 2 / 2
   └─ dimension: 1
2×1 SubDataFrame
 Row │ stat1
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…
   2 │ [0.540302, -0.416147, -0.989992,…


julia> insertframe!(mfd, DataFrame(:age => [30, 9]))
● MultiFrameDataset
   └─ dimensions: (0, 1, 0)
- Frame 1 / 3
   └─ dimension: 0
2×1 SubDataFrame
 Row │ name
     │ String
─────┼────────
   1 │ Python
   2 │ Julia
- Frame 2 / 3
   └─ dimension: 1
2×1 SubDataFrame
 Row │ stat1
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…
   2 │ [0.540302, -0.416147, -0.989992,…
- Frame 3 / 3
   └─ dimension: 0
2×1 SubDataFrame
 Row │ age
     │ Int64
─────┼───────
   1 │    30
   2 │     9
```

or, adding an existing attribute:

```jldoctest
julia> df = DataFrame(
           :name => ["Python", "Julia"],
           :stat1 => [[sin(i) for i in 1:50000], [cos(i) for i in 1:50000]]
       )
2×2 DataFrame
 Row │ name    stat1
     │ String  Array…
─────┼───────────────────────────────────────────
   1 │ Python  [0.841471, 0.909297, 0.14112, -0…
   2 │ Julia   [0.540302, -0.416147, -0.989992,…

julia> mfd = MultiFrameDataset([[2]], df)
● MultiFrameDataset
   └─ dimensions: (1,)
- Frame 1 / 1
   └─ dimension: 1
2×1 SubDataFrame
 Row │ stat1
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…
   2 │ [0.540302, -0.416147, -0.989992,…
- Spare attributes
   └─ dimension: 0
2×1 SubDataFrame
 Row │ name
     │ String
─────┼────────
   1 │ Python
   2 │ Julia


julia> insertframe!(mfd, DataFrame(:age => [30, 9]); existing_attributes = [1])
● MultiFrameDataset
  └─ dimensions: (1, 0)
- Frame 1 / 2
  └─ dimension: 1
2×1 SubDataFrame
 Row │ stat1
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…
   2 │ [0.540302, -0.416147, -0.989992,…
- Frame 2 / 2
  └─ dimension: 0
2×2 SubDataFrame
 Row │ age    name
     │ Int64  String
─────┼───────────────
   1 │    30  Python
   2 │     9  Julia
```
"""
function insertframe!(
    mfd::AbstractMultiFrameDataset,
    col::Integer,
    new_frame::AbstractDataFrame,
    existing_attributes::AbstractVector{<:Integer} = Integer[]
)
    if col != nattributes(mfd)+1
        # TODO: implement `col` parameter
        throw(Exception("Still not implemented with `col` != nattributes + 1"))
    end

    new_indices = (nattributes(mfd)+1):(nattributes(mfd)+ncol(new_frame))

    for (k, c) in collect(zip(keys(eachcol(new_frame)), collect(eachcol(new_frame))))
        insertattributes!(mfd, k, c)
    end
    addframe!(mfd, new_indices)

    for i in existing_attributes
        addattribute_toframe!(mfd, nframes(mfd), i)
    end

    return mfd
end
function insertframe!(
    mfd::AbstractMultiFrameDataset,
    col::Integer,
    new_frame::AbstractDataFrame,
    existing_attributes::AbstractVector{Symbol}
)
    for attr_name in existing_attributes
        @assert hasattributes(mfd, attr_name) "MultiFrameDataset does not contain " *
            "attribute $(attr_name)"
    end

    return insertframe!(mfd, col, new_frame, _name2index(mfd, existing_attributes))
end
function insertframe!(
    mfd::AbstractMultiFrameDataset,
    new_frame::AbstractDataFrame,
    existing_attributes::AbstractVector{<:Integer} = Integer[]
)
    insertframe!(mfd, nattributes(mfd)+1, new_frame, existing_attributes)
end
function insertframe!(
    mfd::AbstractMultiFrameDataset,
    new_frame::AbstractDataFrame,
    existing_attributes::AbstractVector{Symbol}
)
    for attr_name in existing_attributes
        @assert hasattributes(mfd, attr_name) "MultiFrameDataset does not contain " *
            "attribute $(attr_name)"
    end

    return insertframe!(mfd, nattributes(mfd)+1, new_frame, _name2index(mfd, existing_attributes))
end

"""
    dropframe!(mfd, i)

Remove `i`-th frame from `mfd` multiframe dataset while dropping all attributes in it and
return the `mfd` without the dropped frames.

Note: if the dropped attributes are present in other frames they will also be removed from
them. This can lead to the removal of additional frames other than the `i`-th.

If the intection is to remove a frame without releasing the attributes use
[`removeframe!`](@ref) instead.

TODO: review

# Examples
```jldoctest
julia> df = DataFrame(
           :age => [30, 9],
           :name => ["Python", "Julia"],
           :stat1 => [[sin(i) for i in 1:50000], [cos(i) for i in 1:50000]]
       )
2×3 DataFrame
 Row │ age    name    stat1
     │ Int64  String  Array…
─────┼──────────────────────────────────────────────────
   1 │    30  Python  [0.841471, 0.909297, 0.14112, -0…
   2 │     9  Julia   [0.540302, -0.416147, -0.989992,…

julia> mfd = MultiFrameDataset([[1,2], [3]], df)
● MultiFrameDataset
  └─ dimensions: (0, 1)
- Frame 1 / 2
  └─ dimension: 0
2×2 SubDataFrame
 Row │ age    name
     │ Int64  String
─────┼───────────────
   1 │    30  Python
   2 │     9  Julia
- Frame 2 / 2
  └─ dimension: 1
2×1 SubDataFrame
 Row │ stat1
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…
   2 │ [0.540302, -0.416147, -0.989992,…


julia> dropframe!(mfd, 1)
[ Info: Attribute 1 was last attribute of frame 1: removing frame
2×2 DataFrame
 Row │ name    age
     │ String  Int64
─────┼───────────────
   1 │ Python     30
   2 │ Julia       9

julia> mfd
● MultiFrameDataset
  └─ dimensions: (1,)
- Frame 1 / 1
  └─ dimension: 1
2×1 SubDataFrame
 Row │ stat1
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…
   2 │ [0.540302, -0.416147, -0.989992,…
```
"""
# TODO: add dropframe! with AbstractVector{<:Integer}
function dropframe!(mfd::AbstractMultiFrameDataset, i::Integer)
    @assert 1 ≤ i ≤ nframes(mfd) "Index $(i) does not correspond to a frame " *
        "(1:$(nframes(mfd)))"

    return dropattributes!(mfd, descriptor(mfd)[i])
end
