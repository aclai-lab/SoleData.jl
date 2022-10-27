
# -------------------------------------------------------------
# Attributes manipulation

"""
    nattributes(mfd)
    nattributes(mfd, i)

Get the number of attributes of `mfd` multiframe dataset.

If an index is passed as second argument then the number of attributes of the frame at
index `i` is returned.

Alternatively `nattributes` can be called on a single frame.

## PARAMETERS

* `mfd` is a MultiFrameDataset;
* `i` (optional) is a Integer and indicating the frame of the multiframe dataset whose
    number of attributes you want to know.

## EXAMPLES

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

Insert an attibute in `mfd` multiframe dataset with id `attr_id`.

!!! note
    Each attribute inserted will be added in the mfd as a spare attributes.

## PARAMETERS

* `mfd` is an AbstractMultiFrameDataset;
* `col` is an Integer and indicates in which position to insert the new attribute.
    If col isn't passed as a parameter to the function the new attribute will be placed
    last in the mfd's relative dataframe;
* `attr_id` is a Symbol and denote the name of the attribute to insert.
    Duplicated attribute names will be renamed to avoid conflicts: see `makeunique` parameter
    of [`insertcols!`](@ref) in DataFrames documentation;
* `values` is an AbstractVector that indicates the values ​​of the new attribute inserted.
    The length of `values` should match `ninstances(mfd)` or an exception is thrown;
* `value` is a single value for the new attribute. If a single `value` is passed as last
    parameter this will be copied and used for each instance in the dataset.

## EXAMPLES

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

        for (i_frame, desc) in enumerate(frame_descriptor(mfd))
            for (i_attr, attr) in enumerate(desc)
                if attr >= col
                    frame_descriptor(mfd)[i_frame][i_attr] = attr + 1
                end
            end
        end

        return mfd
    else
        insertcols!(data(mfd), col, attr_id => values, makeunique = true)
    end

    return mfd
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
    hasattributes(df, attribute_names)
    hasattributes(mfd, frame_index, attribute_names)
    hasattributes(mfd, attribute_names)

Check whether `mfd` multiframe dataset contains an attribute named `attribute_name`.

Instead of a single attribute name a Vector of names can be passed. It this is the case
this function will return `true` only if `mfd` contains all the attribute listed.

## PARAMETERS

* `df` is an AbstractDataFrame, which is one of the two structure in which you want to check
    the presence of the attribute;
* `mfd` is an AbstractMultiFrameDataset, which is one of the two structure in which you want
    to check the presence of the attribute;
* `attribute_name` is a Symbol and indicates the attribute, whose existence I want to
    verify;
* `frame_index` is and Integer and indicates in which frame to look for the attribute.

## EXAMPLES

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

julia> hasattributes(mfd, [:sex, :age])
true

julia> hasattributes(mfd, 1, [:sex])
false

julia> hasattributes(mfd, 2, [:sex])
true

julia> hasattributes(mfd.data, [:name, :sex])
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
    attributeindex(df, attribute_name)
    attributeindex(mfd, frame_index, attribute_name)
    attributeindex(mfd, attribute_name)

Return the index of the attribute passed as a parameter to the function.
When `frame_index` is given it return the index of the attribute in the subdataframe of the
frame specified by `frame_index`.
It returns 0 when the attribute isn't in the frame specified by `frame_index`.

## PARAMETERS

* `df` is an AbstractDataFrame;
* `mfd` is an AbstractMultiFrameDataset;
* `attribute_name` is a Symbol and indicates the attribute whose index you want to know;
* `frame_index` is and Integer and indicates of which frame you want to know the index of
    the attribute.

## EXAMPLES

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

julia> mfd.data
2×3 DataFrame
 Row │ name    age    sex
     │ String  Int64  Char
─────┼─────────────────────
   1 │ Python     25  M
   2 │ Julia      26  F

julia> attributeindex(mfd, :age)
2

julia> attributeindex(mfd, :sex)
3

julia> attributeindex(mfd, 1, :name)
1

julia> attributeindex(mfd, 2, :name)
0

julia> attributeindex(mfd, 2, :sex)
1

julia> attributeindex(mfd.data, :age)
2
```
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

## PARAMETERS

* `mfd` is a MultiFrameDataset, which is the structure whose indices of the spareattributes
    are to be known.

## EXAMPLES

```jldoctest
julia> mfd = MultiFrameDataset([[1],[3]], DataFrame(:name => ["Python", "Julia"], :age => [25, 26], :sex => ['M', 'F']))
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
2×1 SubDataFrame
 Row │ sex
     │ Char
─────┼──────
   1 │ M
   2 │ F
- Spare attributes
   └─ dimension: 0
2×1 SubDataFrame
 Row │ age
     │ Int64
─────┼───────
   1 │    25
   2 │    26

julia> mfd.data
2×3 DataFrame
 Row │ name    age    sex
     │ String  Int64  Char
─────┼─────────────────────
   1 │ Python     25  M
   2 │ Julia      26  F

julia> spareattributes(mfd)
1-element Vector{Int64}:
 2
```
"""
function spareattributes(mfd::AbstractMultiFrameDataset)::AbstractVector{<:Integer}
    return setdiff(1:nattributes(mfd), unique(cat(frame_descriptor(mfd)..., dims = 1)))
end

"""
    attributes(mfd, i)

Get the names as `Symbol`s of the attributes of `mfd` multiframe dataset.

When called on a object of type `MultiFrameDataset` a `Dict` is returned which will map the
frame index to an `AbstractVector` of `Symbol`s.

Note: the order of the attribute names is granted to match the order of the attributes
inside the frame.

If an index is passed as second argument then the names of the attributes of the frame at
index `i` is returned in an `AbstractVector`.

Alternatively `nattributes` can be called on a single frame.

## PARAMETERS

* `mfd` is an MultiFrameDataset;
* `i` is an Integer and indicates from which frame of the multiframe dataset to get the
    names of the attributes.

## EXAMPLES

```jldoctest
julia> mfd = MultiFrameDataset([[2],[3]], DataFrame(:name => ["Python", "Julia"], :age => [25, 26], :sex => ['M', 'F']))
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
- Spare attributes
   └─ dimension: 0
2×1 SubDataFrame
 Row │ name
     │ String
─────┼────────
   1 │ Python
   2 │ Julia

julia> attributes(mfd)
Dict{Integer, AbstractVector{Symbol}} with 2 entries:
  2 => [:sex]
  1 => [:age]

julia> attributes(mfd, 2)
1-element Vector{Symbol}:
 :sex

julia> attributes(mfd, 1)
1-element Vector{Symbol}:
 :age

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
"""
attributes(df::AbstractDataFrame) = Symbol.(names(df))
function attributes(mfd::AbstractMultiFrameDataset, i::Integer)
    @assert 1 ≤ i ≤ nframes(mfd) "Index ($i) must be a valid frame number " *
        "(1:$(nframes(mfd)))"

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
    dropattributes!(mfd, attribute_name)
    dropattributes!(mfd, indices)
    dropattributes!(mfd, attribute_names)
    dropattributes!(mfd, frame_index, indices)
    dropattributes!(mfd, frame_index, attribute_names)

Drop the `i`-th attribute from `mfd` multiframe dataset and return the multiframe dataset
without that attribute.

## PARAMETERS

* `mfd` is an MultiFrameDataset;
* `i` is an Integer that indicates the index of the attribute to drop;
* `attribute_name` is a Symbol that idicates the attribute to drop;
* `indices` is an AbstractVector{Integer} that indicates the indices of the attribute to
    drop;
* `attribute_names` is an AbstractVector{Symbol} that indicates the attributes to drop.
* `frame_index`: index of the frame; if this parameter is specified `indcies` are relative to the
    `frame_index`-th frame

## EXAMPLES

```jldoctest
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

julia> dropattributes!(mfd, 4)
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
2×2 SubDataFrame
 Row │ sex   weight
     │ Char  Int64
─────┼──────────────
   1 │ M         80
   2 │ F         60

julia> dropattributes!(mfd, :name)
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
2×2 SubDataFrame
 Row │ sex   weight
     │ Char  Int64
─────┼──────────────
   1 │ M         80
   2 │ F         60

julia> dropattributes!(mfd, [1,3])
[ Info: Attribute 1 was last attribute of frame 1: removing frame
● MultiFrameDataset
   └─ dimensions: (0,)
- Frame 1 / 1
   └─ dimension: 0
2×1 SubDataFrame
 Row │ sex
     │ Char
─────┼──────
   1 │ M
   2 │ F
```
TODO: To be reviewed
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
function dropattributes!(
    mfd::AbstractMultiFrameDataset,
    frame_index::Integer,
    indices::Union{Integer, AbstractVector{<:Integer}}
)
    attr_idxes = [ indices... ]
    !(1 <= frame_index <= nframes(mfd)) &&
        throw(DimensionMismatch("Index $(frame_index) does not correspond to a frame"))
    attridx = SoleBase.SoleDataset.frame_descriptor(mfd)[frame_index][attr_idxes]
    return SoleBase.dropattributes!(mfd, attridx)
end
function dropattributes!(
    mfd::AbstractMultiFrameDataset,
    frame_index::Integer,
    attribute_names::Union{Symbol, AbstractVector{<:Symbol}}
)
    attribute_names = [ attribute_names... ]
    !(1 <= frame_index <= nframes(mfd)) &&
        throw(DimensionMismatch("Index $(frame_index) does not correspond to a frame"))
    !issubset(attribute_names, attributes(mfd, frame_index)) &&
        throw(DomainError(attribute_names, "One or more attributes in `attr_names` are not in attributes frame"))
    attridx = SoleBase.SoleDataset._name2index(mfd, attribute_names)
    return SoleBase.dropattributes!(mfd, attridx)
end

"""
    keeponlyattributes!(mfd, indices)
    keeponlyattributes!(mfd, attribute_names)

Drop all attributes that do not correspond to the indices present in `indices` from `mfd`
multiframe dataset.

Note: if the dropped attributes are present in some frame they will also be removed from
them. This can lead to the removal of frames as side effect.

## PARAMETERS

* `mfd` is a MultiFrameDataset;
* `indices` is and AbstractVector{Integer} that indicates which indices to keep in the
    multiframe dataset;
* `attribute_names` is a AbstractVector{Symbol} that indicates which attributes to keep in
    the multiframe dataset.

## EXAMPLES

```jldoctest
julia> mfd = MultiFrameDataset([[1, 2],[3, 4, 5],[5]], DataFrame(:name => ["Python", "Julia"], :age => [25, 26], :sex => ['M', 'F'], :height => [180, 175], :weight => [80, 60]))
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
2×3 SubDataFrame
 Row │ sex   height  weight
     │ Char  Int64   Int64
─────┼──────────────────────
   1 │ M        180      80
   2 │ F        175      60
- Frame 3 / 3
   └─ dimension: 0
2×1 SubDataFrame
 Row │ weight
     │ Int64
─────┼────────
   1 │     80
   2 │     60

julia> keeponlyattributes!(mfd, [1,3,4])
[ Info: Attribute 5 was last attribute of frame 3: removing frame
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
 Row │ sex   height
     │ Char  Int64
─────┼──────────────
   1 │ M        180
   2 │ F        175

julia> keeponlyattributes!(mfd, [:name, :sex])
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
2×1 SubDataFrame
 Row │ sex
     │ Char
─────┼──────
   1 │ M
   2 │ F
```
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

## PARAMETERS

* `mfd` is a MultiFrameDataset, that is the structure at which spareattributes will be
    dropped.

## EXAMPLES

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
