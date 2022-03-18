
# -------------------------------------------------------------
# Attributes manipulation

"""
    nattributes(mfd[, i])

Get the number of attributes of `mfd` multiframe dataset.

If an index is passed as second argument then the number of attributes of the frame at
index `i` is returned.

Alternatively `nattributes` can be called on a single frame.

# Examples
```jldoctest
julia> mfd = MultiFrameDataset([[1],[2]], DataFrame(:age => [25, 26], :sex => ['M', 'F']))
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


julia> nattributes(mfd)
2

julia> nattributes(mfd, 2)
1

julia> frame2 = frame(mfd, 2)
2×1 SubDataFrame
 Row │ sex
     │ Char
─────┼──────
   1 │ M
   2 │ F

julia> nattributes(frame2)
1

julia> mfd = MultiFrameDataset([[1, 2],[3, 4, 5]], DataFrame(:name => ["Python", "Julia"], :age => [25, 26], :sex => ['M', 'F'], :height => [180, 175], :weight => [80, 60]))
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
2×3 SubDataFrame
 Row │ sex   height  weight
     │ Char  Int64   Int64
─────┼──────────────────────
   1 │ M        180      80
   2 │ F        175      60

julia> nattributes(mfd)
5

julia> nattributes(mfd, 2)
3

julia> frame2 = frame(mfd,2)
2×3 SubDataFrame
Row │ sex   height  weight
    │ Char  Int64   Int64
─────┼──────────────────────
    1 │ M        180      80
    2 │ F        175      60

julia> nattributes(frame2)
3
```
"""
nattributes(df::AbstractDataFrame) = ncol(df)
nattributes(mfd::AbstractMultiFrameDataset) = nattributes(data(mfd))
function nattributes(mfd::AbstractMultiFrameDataset, i::Integer)
    @assert 1 ≤ i ≤ nframes(mfd) "Index ($i) must be a valid frame number " *
        "(1:$(nframes(mfd)))"

    return nattributes(frame(mfd, i))
end

"""
    insertattributes!(mfd, col, attr_id, values)
    insertattributes!(mfd, attr_id, values)
    insertattributes!(mfd, col, attr_id, value)
    insertattributes!(mfd, attr_id, value)

Insert an attibute in the dataset `mfd` with id `attr_id`.
Note: Each attribute inserted will be added in the mfd as a spare attributes

#PARAMETERS
*`mfd` is an AbstractMultiFrameDataset;
*`col` is an Integer and indicates in which position to insert the new attribute.
    If col isn't passed as a parameter to the function the new attribute will be placed
    last in the mfd's relative dataframe;
*`attr_id` is a Symbol and denote the name of the attribute to insert.
    Duplicated attribute names will be renamed to avoid conflicts: see `makeunique` parameter
    of [`insertcols!`](@ref) in DataFrames documentation;
*`values` is an AbstractVector that indicates the values ​​of the new attribute inserted.
    The length of `values` should match `ninstances(mfd)` or an exception is thrown;
*`value` is a single value for the new attribute. If a single `value` is passed as last
    parameter this will be copied and used for each instance in the dataset.

```jldoctest
julia> mfd = MultiFrameDataset([[1, 2],[3]], DataFrame(:name => ["Python", "Julia"], :age => [25, 26], :sex => ['M', 'F']))
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

julia> insertattributes!(mfd, :weight, [80, 75])
2×4 DataFrame
 Row │ name    age    sex   weight
     │ String  Int64  Char  Int64
─────┼─────────────────────────────
   1 │ Python     25  M         80
   2 │ Julia      26  F         75

julia> mfd
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
2×1 SubDataFrame
 Row │ weight
     │ Int64
─────┼────────
   1 │     80
   2 │     75

julia> insertattributes!(mfd, 2, :height, 180)
2×5 DataFrame
 Row │ name    height  age    sex   weight
     │ String  Int64   Int64  Char  Int64
─────┼─────────────────────────────────────
   1 │ Python     180     25  M         80
   2 │ Julia      180     26  F         75

julia> insertattributes!(mfd, :hair, ["brown", "blonde"])
2×6 DataFrame
Row │ name    height  age    sex   weight  hair
    │ String  Int64   Int64  Char  Int64   String
─────┼─────────────────────────────────────────────
    1 │ Python     180     25  M         80  brown
    2 │ Julia      180     26  F         75  blonde

julia> mfd
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
2×3 SubDataFrame
    Row │ height  weight  hair
        │ Int64   Int64   String
─────┼────────────────────────
    1 │    180      80  brown
    2 │    180      75  blonde
```
"""
function insertattributes!(
    mfd::AbstractMultiFrameDataset,
    col::Integer,
    attr_id::Symbol,
    values::AbstractVector
)

    @assert length(values) == ninstances(mfd) "value not specified for each instance " *
    "{length(values) != ninstances(mfd)}:{$(length(values)) != $(ninstances(mfd))}"

    if col != nattributes(mfd)+1
        insertcols!(data(mfd), col, attr_id => values, makeunique = true)
        new_frame_descriptor = mfd.frame_descriptor

        for (i_frame, descriptors) in enumerate(mfd.frame_descriptor)
            if findall(descriptors.>=col) != 0
                indexes_descriptors_to_change = findall(descriptors.>=col) # indici dei valori da cambiare (+1)
                changed_descriptors = descriptors[indexes_descriptors_to_change] .+ 1
                new_frame_descriptor[i_frame][indexes_descriptors_to_change] = changed_descriptors
            else
                new_frame_descriptor[i_frame] = descriptors
            end
        end

        mfd = MultiFrameDataset(new_frame_descriptor, data(mfd))

        return data(mfd)
    end

    return insertcols!(data(mfd), col, attr_id => values, makeunique = true)
end
function insertattributes!(
    mfd::AbstractMultiFrameDataset,
    attr_id::Symbol,
    values::AbstractVector
)
    return insertattributes!(mfd, nattributes(mfd)+1, attr_id, values)
end
function insertattributes!(
    mfd::AbstractMultiFrameDataset,
    col::Integer,
    attr_id::Symbol,
    value
)
    return insertattributes!(mfd, col, attr_id, [deepcopy(value) for i in 1:ninstances(mfd)])
end
function insertattributes!(mfd::AbstractMultiFrameDataset, attr_id::Symbol, value)
    return insertattributes!(mfd, nattributes(mfd)+1, attr_id, value)
end

"""
    hasattributes(df, attribute_name)
    hasattributes(mfd, frame_index, attribute_name)
    hasattributes(mfd, attribute_name)

Lets you check if a mfd or a df has a certain attribute.
When given an mfd as a parameter, it is possible to choose which frame to check for the existence of the attribute.

## PARAMETERS
*`df` is an AbstractDataFrame, which is one of the two structure in which you want to check the presence of the attribute;
*`mfd` is an AbstractMultiFrameDataset, which is one of the two structure in which you want to check the presence of the attribute;
*`attribute_name` is a Symbol and indicates the attribute, whose existence I want to verify;
*`frame_index` is and Integer and indicates in which frame to look for the attribute.

```jldoctest
julia> mfd = MultiFrameDataset([[1, 2],[3]], DataFrame(:name => ["Python", "Julia"], :age => [25, 26], :sex => ['M', 'F']))
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

julia> hasattributes(mfd, :age)
true

julia> hasattributes(mfd.data, :name)
true

julia> hasattributes(mfd, :height)
false

julia> hasattributes(mfd, 1, :sex)
false

julia> hasattributes(mfd, 2, :sex)
true
```
"""
function hasattributes(df::AbstractDataFrame, attribute_name::Symbol)
    return _name2index(df, attribute_name) > 0
end
function hasattributes(
    mfd::AbstractMultiFrameDataset,
    frame_index::Integer,
    attribute_name::Symbol
)
    return _name2index(frame(mfd, frame_index), attribute_name) > 0
end
function hasattributes(mfd::AbstractMultiFrameDataset, attribute_name::Symbol)
    return _name2index(mfd, attribute_name) > 0
end

"""
TODO: docs
"""
function hasattributes(df::AbstractDataFrame, attribute_names::AbstractVector{Symbol})
    return !(0 in _name2index(df, attribute_names))
end
function hasattributes(
    mfd::AbstractMultiFrameDataset,
    frame_index::Integer,
    attribute_names::AbstractVector{Symbol}
)
    return !(0 in _name2index(frame(mfd, frame_index), attribute_names))
end
function hasattributes(
    mfd::AbstractMultiFrameDataset,
    attribute_names::AbstractVector{Symbol}
)
    return !(0 in _name2index(mfd, attribute_names))
end

"""
TODO: docs
"""
function attributeindex(df::AbstractDataFrame, attribute_name::Symbol)
    return _name2index(df, attribute_name)
end
function attributeindex(
    mfd::AbstractMultiFrameDataset,
    frame_index::Integer,
    attribute_name::Symbol
)
    return _name2index(frame(mfd, frame_index), attribute_name)
end
function attributeindex(mfd::AbstractMultiFrameDataset, attribute_name::Symbol)
    return _name2index(mfd, attribute_name)
end

"""
    spareattributes(mfd)

Get the indices of all the attributes currently not present in any of the frames of `mfd`
multiframe dataset.
"""
function spareattributes(mfd::AbstractMultiFrameDataset)::AbstractVector{<:Integer}
    return setdiff(1:nattributes(mfd), unique(cat(frame_descriptor(mfd)..., dims = 1)))
end

"""
    attributes(mfd[, i])

Get the names as `Symbol`s of the attributes of `mfd` multiframe dataset.

When called on a object of type `MultiFrameDataset` a `Dict` is returned which will map the
frame index to an `AbstractVector` of `Symbol`s.

Note: the order of the attribute names is granted to match the order of the attributes
inside the frame.

If an index is passed as second argument then the names of the attributes of the frame at
index `i` is returned in an `AbstractVector`.

Alternatively `nattributes` can be called on a single frame.

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

julia> attributes(mfd)
Dict{Integer, AbstractVector{Symbol}} with 2 entries:
 2 => [:sex]
 1 => [:age]

julia> attributes(mfd, 2)
1-element Vector{Symbol}:
:sex

julia> frame2 = frame(mfd, 2)
2×1 SubDataFrame
 Row │ sex
     │ Char
─────┼──────
   1 │ M
   2 │ F

julia> attributes(frame2)
1-element Vector{Symbol}:
 :sex
```
TODO: change doc as before; that is, use a more interesting example.
"""
attributes(df::AbstractDataFrame) = Symbol.(names(df))
function attributes(mfd::AbstractMultiFrameDataset, i::Integer)
    @assert 1 ≤ i ≤ nframes(mfd) "Index ($i) must be a valid frame number (1:$(nframes(mfd)))"

    return attributes(frame(mfd, i))
end
function attributes(mfd::AbstractMultiFrameDataset)
    d = Dict{Integer,AbstractVector{Symbol}}()

    for i in 1:nframes(mfd)
        d[i] = attributes(mfd, i)
    end

    return d
end

"""
    dropattributes!(mfd, i)

Drop the `i`-th attribute from `mfd` multiframe dataset and return the multiframe dataset
without that attribute.

TODO: To be reviewed
TODO: Need to implement dropattributes!(lmfd, i) for labeledMFD
"""
function dropattributes!(mfd::AbstractMultiFrameDataset, i::Integer)
    @assert 1 ≤ i ≤ nattributes(mfd) "Attribute $(i) is not a valid attibute index " *
        "(1:$(nattributes(mfd)))"

    j = 1
    while j ≤ nframes(mfd)
        desc = frame_descriptor(mfd)[j]
        if i in desc
            removeattribute_fromframe!(mfd, j, i)
        else
            j += 1
        end
    end

    select!(data(mfd), setdiff(collect(1:nattributes(mfd)), i))

    for (i_frame, desc) in enumerate(frame_descriptor(mfd))
        for (i_attr, attr) in enumerate(desc)
            if attr > i
                frame_descriptor(mfd)[i_frame][i_attr] = attr - 1
            end
        end
    end

    return mfd
end
function dropattributes!(mfd::AbstractMultiFrameDataset, attribute_name::Symbol)
    @assert hasattributes(mfd, attribute_name) "MultiFrameDataset does not contain " *
        "attribute $(attribute_name)"

    return dropattributes!(mfd, _name2index(mfd, attribute_name))
end
function dropattributes!(mfd::AbstractMultiFrameDataset, indices::AbstractVector{<:Integer})
    for i in indices
        @assert 1 ≤ i ≤ nattributes(mfd) "Index $(i) does not correspond to an " *
            "attribute (1:$(nattributes(mfd)))"
    end

    attr_names = Symbol.(names(data(mfd)))

    for i_attr in sort!(deepcopy(indices), rev = true)
        dropattributes!(mfd, i_attr)
    end

    return mfd
end
function dropattributes!(
    mfd::AbstractMultiFrameDataset,
    attribute_names::AbstractVector{Symbol}
)
    for attr_name in attribute_names
        @assert hasattributes(mfd, attr_name) "MultiFrameDataset does not contain " *
            "attribute $(attr_name)"
    end

    return dropattributes!(mfd, _name2index(mfd, attribute_names))
end

"""
    keeponlyattributes!(mfd, indices)

Drop all attributes that do not correspond to the indices present in `indices` from `mfd`
multiframe dataset.

Note: if the dropped attributes are present in some frame they will also be removed from
them. This can lead to the removal of frames as side effect.

TODO: review
"""
function keeponlyattributes!(
    mfd::AbstractMultiFrameDataset,
    indices::AbstractVector{<:Integer}
)
    return dropattributes!(mfd, setdiff(collect(1:nattributes(mfd)), indices))
end
function keeponlyattributes!(
    mfd::AbstractMultiFrameDataset,
    attribute_names::AbstractVector{Symbol}
)
    for attr_name in attribute_names
        @assert hasattributes(mfd, attr_name) "MultiFrameDataset does not contain " *
            "attribute $(attr_name)"
    end

    return dropattributes!(
        mfd, setdiff(collect(1:nattributes(mfd)), _name2index(mfd, attribute_names)))
end
function keeponlyattributes!(
    mfd::AbstractMultiFrameDataset,
    attribute_names::AbstractVector{<:AbstractVector{Symbol}}
)
    for attr_name in attribute_names
        @assert hasattributes(mfd, attr_name) "MultiFrameDataset does not contain " *
            "attribute $(attr_name)"
    end

    return dropattributes!(
        mfd, setdiff(collect(1:nattributes(mfd)), _name2index(mfd, attribute_names)))
end

"""
    dropspareattributes!(mfd)

Drop all attributes that are not present in any of the frames in `mfd` multiframe dataset.

# Examples
```jldoctest
julia> mfd = MultiFrameDataset([[1]], DataFrame(:age => [30, 9], :name => ["Python", "Julia"]))
● MultiFrameDataset
   └─ dimensions: (0,)
- Frame 1 / 1
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


julia> dropspareattributes!(mfd)
2×1 DataFrame
 Row │ name
     │ String
─────┼────────
   1 │ Python
   2 │ Julia
```
"""
function dropspareattributes!(mfd::AbstractMultiFrameDataset)
    spare = sort!(spareattributes(mfd), rev = true)

    attr_names = Symbol.(names(data(mfd)))
    result = DataFrame([(attr_names[i] => data(mfd)[:,i]) for i in reverse(spare)]...)

    for i_attr in spare
        dropattributes!(mfd, i_attr)
    end

    return result
end
