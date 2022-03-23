
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

    return @view data(mfd)[:,frame_descriptor(mfd)[i]]
end
function frame(mfd::AbstractMultiFrameDataset, indices::AbstractVector{<:Integer})
    return [frame(mfd, i) for i in indices]
end

"""
    nframes(mfd)

Get the number of frames of `mfd` multiframe dataset.
"""
nframes(mfd::AbstractMultiFrameDataset) = length(frame_descriptor(mfd))

"""
    addframe!(mfd, indices)
    addframe!(mfd, index)
    addframe!(mfd, attribute_names)
    addframe!(mfd, attribute_name)

Create a new frame in `mfd` multiframe dataset using attributes at `indices`
or `index` and return`mfd`.

Alternatively to the `indices` and the `index`, can be used respectively the attribute_names and the attribute_name.

Note: to add a new frame with new attributes see [`insertfframe!`](@ref).

#PARAMETERS
*`mfd` is a MultiFrameDataset;
*`indices` is an AbstractVector{Integer} that indicates which indices of the multiframe dataset's corresponding dataframe to add to the new frame;
*`index` is a Integer that indicates the index of the multiframe dataset's corresponding dataframe to add to the new frame;
*`attribute_names` is an AbstractVector{Symbol} that indicates which attributes of the multiframe dataset's corresponding dataframe to add to the new frame;
*`attribute_name` is a Symbol that indicates the attribute of the multiframe dataset's corresponding dataframe to add to the new frame;

```jldoctest
julia> df = DataFrame(:name => ["Python", "Julia"], :age => [25, 26], :sex => ['M', 'F'], :height => [180, 175], :weight => [80, 60])
2×5 DataFrame
 Row │ name    age    sex   height  weight
     │ String  Int64  Char  Int64   Int64
─────┼─────────────────────────────────────
   1 │ Python     25  M        180      80
   2 │ Julia      26  F        175      60

julia> mfd = MultiFrameDataset([[1]], df)
● MultiFrameDataset
   └─ dimensions: (0,)
- Frame 1 / 1
   └─ dimension: 0
2×1 SubDataFrame
 Row │ name
     │ String
─────┼────────
   1 │ Python
   2 │ Julia
- Spare attributes
   └─ dimension: 0
2×4 SubDataFrame
 Row │ age    sex   height  weight
     │ Int64  Char  Int64   Int64
─────┼─────────────────────────────
   1 │    25  M        180      80
   2 │    26  F        175      60


julia> addframe!(mfd, [:age, :sex])
● MultiFrameDataset
   └─ dimensions: (0, 0)
- Frame 1 / 2
   └─ dimension: 0
2×1 SubDataFrame
 Row │ name
     │ String
─────┼────────
   1 │ Python
   2 │ Julia
- Frame 2 / 2
   └─ dimension: 0
2×2 SubDataFrame
 Row │ age    sex
     │ Int64  Char
─────┼─────────────
   1 │    25  M
   2 │    26  F
- Spare attributes
   └─ dimension: 0
2×2 SubDataFrame
 Row │ height  weight
     │ Int64   Int64
─────┼────────────────
   1 │    180      80
   2 │    175      60


julia> addframe!(mfd, 5)
● MultiFrameDataset
   └─ dimensions: (0, 0, 0)
- Frame 1 / 3
   └─ dimension: 0
2×1 SubDataFrame
 Row │ name
     │ String
─────┼────────
   1 │ Python
   2 │ Julia
- Frame 2 / 3
   └─ dimension: 0
2×2 SubDataFrame
 Row │ age    sex
     │ Int64  Char
─────┼─────────────
   1 │    25  M
   2 │    26  F
- Frame 3 / 3
   └─ dimension: 0
2×1 SubDataFrame
 Row │ weight
     │ Int64
─────┼────────
   1 │     80
   2 │     60
- Spare attributes
   └─ dimension: 0
2×1 SubDataFrame
 Row │ height
     │ Int64
─────┼────────
   1 │    180
   2 │    175
"""
function addframe!(mfd::AbstractMultiFrameDataset, indices::AbstractVector{<:Integer})
    @assert length(indices) > 0 "Can't add an empty frame to dataset"

    for i in indices
        @assert i in 1:nattributes(mfd) "Index $(i) is out of range 1:nattributes " *
            "(1:$(nattributes(mfd)))"
    end

    push!(frame_descriptor(mfd), indices)

    return mfd
end
addframe!(mfd::AbstractMultiFrameDataset, index::Integer) = addframe!(mfd, [index])
function addframe!(mfd::AbstractMultiFrameDataset, attribute_names::AbstractVector{Symbol})
    for attr_name in attribute_names
        @assert hasattributes(mfd, attr_name) "MultiFrameDataset does not contain " *
            "attribute $(attr_name)"
    end

    return addframe!(mfd, _name2index(mfd, attribute_names))
end
function addframe!(mfd::AbstractMultiFrameDataset, attribute_name::Symbol)
    return addframe!(mfd, [attribute_name])
end

"""

    removeframe!(mfd, indices)
    removeframe!(mfd, index)

Remove `i`-th frame from `mfd` multiframe dataset and return `mfd`.

Note: to completely remove a frame and all attributes in it use [`dropframe!`](@ref)
instead.

#PARAMETERS
*`mfd` is a MultiFrameDataset;
*`index` is a Integer that indicates which frame to remove from the multiframe dataset;
*`indices` is a AbstractVector{Integer} that indicates the frames to remove from the multiframe dataset;

```jldoctest
julia> df = DataFrame(:name => ["Python", "Julia"],
                      :age => [25, 26],
                      :sex => ['M', 'F'],
                      :height => [180, 175],
                      :weight => [80, 60])
                     )
2×5 DataFrame
Row │ name    age    sex   height  weight
    │ String  Int64  Char  Int64   Int64
─────┼─────────────────────────────────────
    1 │ Python     25  M        180      80
    2 │ Julia      26  F        175      60

julia> mfd = MultiFrameDataset([[1, 2],[3],[4],[5]], df)
● MultiFrameDataset
   └─ dimensions: (0, 0, 0, 0)
- Frame 1 / 4
   └─ dimension: 0
2×2 SubDataFrame
 Row │ name    age
     │ String  Int64
─────┼───────────────
   1 │ Python     25
   2 │ Julia      26
- Frame 2 / 4
   └─ dimension: 0
2×1 SubDataFrame
 Row │ sex
     │ Char
─────┼──────
   1 │ M
   2 │ F
- Frame 3 / 4
   └─ dimension: 0
2×1 SubDataFrame
 Row │ height
     │ Int64
─────┼────────
   1 │    180
   2 │    175
- Frame 4 / 4
   └─ dimension: 0
2×1 SubDataFrame
 Row │ weight
     │ Int64
─────┼────────
   1 │     80
   2 │     60

julia> removeframe!(mfd, [3])
● MultiFrameDataset
   └─ dimensions: (0, 0, 0)
- Frame 1 / 3
   └─ dimension: 0
2×2 SubDataFrame
 Row │ name    age
     │ String  Int64
─────┼───────────────
   1 │ Python     25
   2 │ Julia      26
- Frame 2 / 3
   └─ dimension: 0
2×1 SubDataFrame
 Row │ sex
     │ Char
─────┼──────
   1 │ M
   2 │ F
- Frame 3 / 3
   └─ dimension: 0
2×1 SubDataFrame
 Row │ weight
     │ Int64
─────┼────────
   1 │     80
   2 │     60
- Spare attributes
   └─ dimension: 0
2×1 SubDataFrame
 Row │ height
     │ Int64
─────┼────────
   1 │    180
   2 │    175

julia> removeframe!(mfd, [1,2])
● MultiFrameDataset
   └─ dimensions: (0,)
- Frame 1 / 1
   └─ dimension: 0
2×1 SubDataFrame
 Row │ weight
     │ Int64
─────┼────────
   1 │     80
   2 │     60
- Spare attributes
   └─ dimension: 0
2×4 SubDataFrame
 Row │ name    age    sex   height
     │ String  Int64  Char  Int64
─────┼─────────────────────────────
   1 │ Python     25  M        180
   2 │ Julia      26  F        175

```
"""
function removeframe!(mfd::AbstractMultiFrameDataset, i::Integer)
    @assert 1 ≤ i ≤ nframes(mfd) "Index $(i) does not correspond to a frame " *
        "(1:$(nframes(mfd)))"

    deleteat!(frame_descriptor(mfd), i)

    return mfd
end
function removeframe!(mfd::AbstractMultiFrameDataset, indices::AbstractVector{Integer})
    for i in sort(unique(indices))
        removeframe!(mfd, i)
    end

    return mfd
end

"""
    addattribute_toframe!(mfd, frame_index, attr_index)
    addattribute_toframe!(mfd, frame_index, attr_indices)
    addattribute_toframe!(mfd, frame_index, attr_name)
    addattribute_toframe!(mfd, frame_index, attr_names)

Add attribute at index `attr_index` to the frame at index `frame_index` in `mfd` multiframe
dataset and return `mfd`.
Alternatively to `attr_index` the attribute name can be used.
Multiple attributes can be inserted into the multiframe dataset at once using `attr_indices` or
`attr_inames`.

Note: The function does not allow you to add an attribute to a new frame, but only to add it
to an existing frame in the mfd. To add a new frame use [`addframe!`](@ref) instead.

#PARAMETERS
*`mfd` is a MultiFrameDataset;
*`frame_index` is a Integer which indicates the frame in which the attribute or attributes will be added;
*`attr_index` is a Integer that indicates the index of the attribute to add to a specific frame of the multiframe dataset;
*`attr_indices` is a AbstractVector{Integer} which indicates the indices of the attributes to add to a specific frame of the multiframe dataset;
*`attr_name` is a Symbol which indicates the name of the attribute to add to a specific frame of the multiframe dataset;
*`attr_names` is a AbstractVector{Symbol} which indicates the name of the attributes to add to a specific frame of the multiframe dataset;

```jldoctest
julia> df = DataFrame(:name => ["Python", "Julia"],
                      :age => [25, 26],
                      :sex => ['M', 'F'],
                      :height => [180, 175],
                      :weight => [80, 60])
                     )
2×5 DataFrame
Row │ name    age    sex   height  weight
    │ String  Int64  Char  Int64   Int64
─────┼─────────────────────────────────────
    1 │ Python     25  M        180      80
    2 │ Julia      26  F        175      60

julia> mfd = MultiFrameDataset([[1, 2],[3]], df)
● MultiFrameDataset
   └─ dimensions: (0, 0)
- Frame 1 / 2
   └─ dimension: 0
2×2 SubDataFrame
 Row │ name    age
     │ String  Int64
─────┼───────────────
   1 │ Python     25
   2 │ Julia      26
- Frame 2 / 2
   └─ dimension: 0
2×1 SubDataFrame
 Row │ sex
     │ Char
─────┼──────
   1 │ M
   2 │ F
- Spare attributes
   └─ dimension: 0
2×2 SubDataFrame
 Row │ height  weight
     │ Int64   Int64
─────┼────────────────
   1 │    180      80
   2 │    175      60

julia> addattribute_toframe!(mfd, 1, [4,5])
● MultiFrameDataset
   └─ dimensions: (0, 0)
- Frame 1 / 2
   └─ dimension: 0
2×4 SubDataFrame
 Row │ name    age    height  weight
     │ String  Int64  Int64   Int64
─────┼───────────────────────────────
   1 │ Python     25     180      80
   2 │ Julia      26     175      60
- Frame 2 / 2
   └─ dimension: 0
2×1 SubDataFrame
 Row │ sex
     │ Char
─────┼──────
   1 │ M
   2 │ F

julia> addattribute_toframe!(mfd, 2, [:name,:weight])
● MultiFrameDataset
   └─ dimensions: (0, 0)
- Frame 1 / 2
   └─ dimension: 0
2×4 SubDataFrame
 Row │ name    age    height  weight
     │ String  Int64  Int64   Int64
─────┼───────────────────────────────
   1 │ Python     25     180      80
   2 │ Julia      26     175      60
- Frame 2 / 2
   └─ dimension: 0
2×3 SubDataFrame
 Row │ sex   name    weight
     │ Char  String  Int64
─────┼──────────────────────
   1 │ M     Python      80
   2 │ F     Julia       60
```
"""
function addattribute_toframe!(
    mfd::AbstractMultiFrameDataset, frame_index::Integer, attr_index::Integer
)
    @assert 1 ≤ frame_index ≤ nframes(mfd) "Index $(frame_index) does not correspond " *
        "to a frame (1:$(nframes(mfd)))"
    @assert 1 ≤ attr_index ≤ nattributes(mfd) "Index $(attr_index) does not correspond " *
        "to an attribute (1:$(nattributes(mfd)))"

    if attr_index in frame_descriptor(mfd)[frame_index]
        @info "Attribute $(attr_index) is already part of frame $(frame_index)"
    else
        push!(frame_descriptor(mfd)[frame_index], attr_index)
    end

    return mfd
end
function addattribute_toframe!(
    mfd::AbstractMultiFrameDataset, frame_index::Integer, attr_indeices::AbstractVector{<:Integer}
)
    for attr_index in attr_indeices
        addattribute_toframe!(mfd, frame_index, attr_index)
    end

    return mfd
end
function addattribute_toframe!(
    mfd::AbstractMultiFrameDataset, frame_index::Integer, attr_name::Symbol
)
    @assert hasattributes(mfd, attr_name) "MultiFrameDataset does not contain attribute " *
        "$(attr_name)"

    return addattribute_toframe!(mfd, frame_index, _name2index(mfd, attr_name))
end
function addattribute_toframe!(
    mfd::AbstractMultiFrameDataset, frame_index::Integer, attr_names::AbstractVector{Symbol}
)
    for attr_name in attr_names
        addattribute_toframe!(mfd, frame_index, attr_name)
    end

    return mfd
end

"""
    removeattribute_fromframe!(mfd, farme_index, attr_indices)
    removeattribute_fromframe!(mfd, farme_index, attr_index)
    removeattribute_fromframe!(mfd, farme_index, attr_name)
    removeattribute_fromframe!(mfd, farme_index, attr_names)

Remove attribute at index `attr_index` from the frame at index `frame_index` in `mfd`
multiframe dataset and return `mfd`.
Alternatively to `attr_index` the attribute name can be used.
Multiple attributes can be dropped from the multiframe dataset at once using `attr_indices` or
`attr_inames`.

Note: when all attributes are dropped to a frame, it will be removed.

#PARAMETERS
*`mfd` is a MultiFrameDataset;
*`frame_index` is a Integer which indicates the frame in which the attribute or attributes will be dropped;
*`attr_index` is a Integer that indicates the index of the attribute to drop from a specific frame of the multiframe dataset;
*`attr_indices` is a AbstractVector{Integer} which indicates the indices of the attributes to drop from a specific frame of the multiframe dataset;
*`attr_name` is a Symbol which indicates the name of the attribute to drop from a specific frame of the multiframe dataset;
*`attr_names` is a AbstractVector{Symbol} which indicates the name of the attributes to drop from a specific frame of the multiframe dataset;

```jldoctest
julia> df = DataFrame(:name => ["Python", "Julia"],
                      :age => [25, 26],
                      :sex => ['M', 'F'],
                      :height => [180, 175],
                      :weight => [80, 60])
                     )
2×5 DataFrame
Row │ name    age    sex   height  weight
    │ String  Int64  Char  Int64   Int64
─────┼─────────────────────────────────────
    1 │ Python     25  M        180      80
    2 │ Julia      26  F        175      60

julia> mfd = MultiFrameDataset([[1,2,4],[2,3,4],[5]], df)
● MultiFrameDataset
    └─ dimensions: (0, 0, 0)
- Frame 1 / 3
    └─ dimension: 0
2×3 SubDataFrame
    Row │ name    age    height
        │ String  Int64  Int64
─────┼───────────────────────
    1 │ Python     25     180
    2 │ Julia      26     175
- Frame 2 / 3
    └─ dimension: 0
2×3 SubDataFrame
    Row │ age    sex   height
        │ Int64  Char  Int64
─────┼─────────────────────
    1 │    25  M        180
    2 │    26  F        175
- Frame 3 / 3
    └─ dimension: 0
2×1 SubDataFrame
    Row │ weight
        │ Int64
─────┼────────
    1 │     80
    2 │     60

julia> removeattribute_fromframe!(mfd, 3, 5)
[ Info: Attribute 5 was last attribute of frame 3: removing frame
● MultiFrameDataset
    └─ dimensions: (0, 0)
- Frame 1 / 2
    └─ dimension: 0
2×3 SubDataFrame
    Row │ name    age    height
        │ String  Int64  Int64
─────┼───────────────────────
    1 │ Python     25     180
    2 │ Julia      26     175
- Frame 2 / 2
    └─ dimension: 0
2×3 SubDataFrame
    Row │ age    sex   height
        │ Int64  Char  Int64
─────┼─────────────────────
    1 │    25  M        180
    2 │    26  F        175
- Spare attributes
    └─ dimension: 0
2×1 SubDataFrame
    Row │ weight
        │ Int64
─────┼────────
    1 │     80
    2 │     60

julia> removeattribute_fromframe!(mfd, 1, :age)
● MultiFrameDataset
    └─ dimensions: (0, 0)
- Frame 1 / 2
    └─ dimension: 0
2×2 SubDataFrame
    Row │ name    height
        │ String  Int64
─────┼────────────────
    1 │ Python     180
    2 │ Julia      175
- Frame 2 / 2
    └─ dimension: 0
2×3 SubDataFrame
    Row │ age    sex   height
        │ Int64  Char  Int64
─────┼─────────────────────
    1 │    25  M        180
    2 │    26  F        175
- Spare attributes
    └─ dimension: 0
2×1 SubDataFrame
    Row │ weight
        │ Int64
─────┼────────
    1 │     80
    2 │     60

julia> removeattribute_fromframe!(mfd, 2, [3,4])
● MultiFrameDataset
    └─ dimensions: (0, 0)
- Frame 1 / 2
    └─ dimension: 0
2×2 SubDataFrame
    Row │ name    height
        │ String  Int64
─────┼────────────────
    1 │ Python     180
    2 │ Julia      175
- Frame 2 / 2
    └─ dimension: 0
2×1 SubDataFrame
    Row │ age
        │ Int64
─────┼───────
    1 │    25
    2 │    26
- Spare attributes
    └─ dimension: 0
2×2 SubDataFrame
    Row │ sex   weight
        │ Char  Int64
─────┼──────────────
    1 │ M         80
    2 │ F         60

julia> removeattribute_fromframe!(mfd, 1, [:name,:height])
[ Info: Attribute 4 was last attribute of frame 1: removing frame
● MultiFrameDataset
    └─ dimensions: (0,)
- Frame 1 / 1
    └─ dimension: 0
2×1 SubDataFrame
    Row │ age
        │ Int64
─────┼───────
    1 │    25
    2 │    26
- Spare attributes
    └─ dimension: 0
2×4 SubDataFrame
    Row │ name    sex   height  weight
        │ String  Char  Int64   Int64
─────┼──────────────────────────────
    1 │ Python  M        180      80
    2 │ Julia   F        175      60
"""
function removeattribute_fromframe!(
    mfd::AbstractMultiFrameDataset, frame_index::Integer, attr_index::Integer
)
    @assert 1 ≤ frame_index ≤ nframes(mfd) "Index $(frame_index) does not correspond " *
        "to a frame (1:$(nframes(mfd)))"
    @assert 1 ≤ attr_index ≤ nattributes(mfd) "Index $(attr_index) does not correspond " *
        "to an attribute (1:$(nattributes(mfd)))"

    if !(attr_index in frame_descriptor(mfd)[frame_index])
        @info "Attribute $(attr_index) is not part of frame $(frame_index)"
    elseif nattributes(mfd, frame_index) == 1
        @info "Attribute $(attr_index) was last attribute of frame $(frame_index): " *
            "removing frame"
        removeframe!(mfd, frame_index)
    else
        deleteat!(
            frame_descriptor(mfd)[frame_index],
            indexin(attr_index, frame_descriptor(mfd)[frame_index])[1]
        )
    end

    return mfd
end
function removeattribute_fromframe!(
    mfd::AbstractMultiFrameDataset,
    frame_index::Integer,
    attr_indices::AbstractVector{<:Integer}
)
    for i in attr_indices
        removeattribute_fromframe!(mfd, frame_index, i)
    end

    return mfd
end
function removeattribute_fromframe!(
    mfd::AbstractMultiFrameDataset, frame_index::Integer, attr_name::Symbol
)
    @assert hasattributes(mfd, attr_name) "MultiFrameDataset does not contain attribute " *
        "$(attr_name)"

    return removeattribute_fromframe!(mfd, frame_index, _name2index(mfd, attr_name))
end
function removeattribute_fromframe!(
    mfd::AbstractMultiFrameDataset, frame_index::Integer, attr_names::AbstractVector{Symbol}
)
    for attr_name in attr_names
        removeattribute_fromframe!(mfd, frame_index, attr_name)
    end

    return mfd
end

"""
    insertframe!(mfd, col, new_frame, existing_attributes)
    insertframe!(mfd, new_frame, existing_attributes)

Insert `new_frame` as new frame to `mfd` multiframe dataset and return `mfd`.
Existing attributes can be added to the new frame while adding it to the dataset passing
the corresponding inidices by `existing_attributes`.
If `col` is specified then the attributes will be inserted starting at index `col`.

#PARAMETERS
*`mfd` is a MultiFrameDataset;
*`col` is a Integer which indicates the column in which to insert the columns of the new frame `new_frame`;
*`new_frame` is a AbstractDataFrame which will be added to the multiframe dataset as a subdataframe of a new frame;
*`existing_attributes` is AbstractVector{Integer} and a AbstractVector{Symbol} also. It indicates which attributes
of the multiframe dataset relative's dataframe to insert in the new frame `new_frame`.

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

julia> mfd.data
2×3 DataFrame
Row │ name    stat1                              age
    │ String  Array…                             Int64
─────┼──────────────────────────────────────────────────
    1 │ Python  [0.841471, 0.909297, 0.14112, -0…     30
    2 │ Julia   [0.540302, -0.416147, -0.989992,…      9
```
or, selecting the column

jldoctest```
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

julia> insertframe!(mfd, 2, DataFrame(:age => [30, 9]))
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
2×1 SubDataFrame
Row │ age
    │ Int64
─────┼───────
    1 │    30
    2 │     9
- Spare attributes
    └─ dimension: 0
2×1 SubDataFrame
Row │ name
    │ String
─────┼────────
    1 │ Python
    2 │ Julia

julia> mfd.data
2×3 DataFrame
Row │ name    age    stat1
    │ String  Int64  Array…
─────┼──────────────────────────────────────────────────
    1 │ Python     30  [0.841471, 0.909297, 0.14112, -0…
    2 │ Julia       9  [0.540302, -0.416147, -0.989992,…
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
        new_indices = col:col+ncol(new_frame)-1

        for (k, c) in collect(zip(keys(eachcol(new_frame)), collect(eachcol(new_frame))))
            insertattributes!(mfd, col, k, c)
            col = col + 1
        end
    else
        new_indices = (nattributes(mfd)+1):(nattributes(mfd)+ncol(new_frame))

        for (k, c) in collect(zip(keys(eachcol(new_frame)), collect(eachcol(new_frame))))
            insertattributes!(mfd, k, c)
        end
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
    dropframe!(mfd, indices)
    dropframe!(mfd, index)

Remove `i`-th frame from `mfd` multiframe dataset while dropping all attributes in it and
return the `mfd` without the dropped frames.

Note: if the dropped attributes are present in other frames they will also be removed from
them. This can lead to the removal of additional frames other than the `i`-th.

If the intection is to remove a frame without releasing the attributes use
[`removeframe!`](@ref) instead.

#PARAMETERS
* `mfd` is a MultiFrameDataset;
* `index` is a Integer which indicates the index of the frame to drop;
* `indices` is an AbstractVector{Integer} which indicates the indices of the frames to drop.

```jldoctest
julia> df = DataFrame(:name => ["Python", "Julia"], :age => [25, 26], :sex => ['M', 'F'], :height => [180, 175], :weight => [80, 60])
2×5 DataFrame
 Row │ name    age    sex   height  weight
     │ String  Int64  Char  Int64   Int64
─────┼─────────────────────────────────────
   1 │ Python     25  M        180      80
   2 │ Julia      26  F        175      60

julia> mfd = MultiFrameDataset([[1, 2],[3,4],[5],[2,3]], df)
● MultiFrameDataset
   └─ dimensions: (0, 0, 0, 0)
- Frame 1 / 4
   └─ dimension: 0
2×2 SubDataFrame
 Row │ name    age
     │ String  Int64
─────┼───────────────
   1 │ Python     25
   2 │ Julia      26
- Frame 2 / 4
   └─ dimension: 0
2×2 SubDataFrame
 Row │ sex   height
     │ Char  Int64
─────┼──────────────
   1 │ M        180
   2 │ F        175
- Frame 3 / 4
   └─ dimension: 0
2×1 SubDataFrame
 Row │ weight
     │ Int64
─────┼────────
   1 │     80
   2 │     60
- Frame 4 / 4
   └─ dimension: 0
2×2 SubDataFrame
 Row │ age    sex
     │ Int64  Char
─────┼─────────────
   1 │    25  M
   2 │    26  F

julia> dropframe!(mfd, [2,3])
[ Info: Attribute 3 was last attribute of frame 2: removing frame
[ Info: Attribute 3 was last attribute of frame 2: removing frame
● MultiFrameDataset
   └─ dimensions: (0, 0)
- Frame 1 / 2
   └─ dimension: 0
2×2 SubDataFrame
 Row │ name    age
     │ String  Int64
─────┼───────────────
   1 │ Python     25
   2 │ Julia      26
- Frame 2 / 2
   └─ dimension: 0
2×1 SubDataFrame
 Row │ age
     │ Int64
─────┼───────
   1 │    25
   2 │    26

julia> dropframe!(mfd, 2)
[ Info: Attribute 2 was last attribute of frame 2: removing frame
● MultiFrameDataset
   └─ dimensions: (0,)
- Frame 1 / 1
   └─ dimension: 0
2×1 SubDataFrame
 Row │ name
     │ String
─────┼────────
   1 │ Python
   2 │ Julia
```
"""
function dropframe!(mfd::AbstractMultiFrameDataset, index::Integer)
    @assert 1 ≤ index ≤ nframes(mfd) "Index $(index) does not correspond to a frame " *
        "(1:$(nframes(mfd)))"

    return dropattributes!(mfd, frame_descriptor(mfd)[index])
end
function dropframe!(mfd::AbstractMultiFrameDataset, indices::AbstractVector{<:Integer})
    for i in indices
        @assert 1 ≤ i ≤ nframes(mfd) "Index $(i) does not correspond to a frame " *
            "(1:$(nframes(mfd)))"
    end

    return dropattributes!(mfd, sort!(
        unique(vcat(frame_descriptor(mfd)[indices])); rev = true
    ))
end
