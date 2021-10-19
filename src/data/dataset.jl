
# -------------------------------------------------------------
# Abstract types

abstract type AbstractDataset end

# -------------------------------------------------------------
# MultiFrameDataset

"""
"""
struct MultiFrameDataset <: AbstractDataset
    descriptor :: AbstractVector{AbstractVector{Integer}}
    data       :: AbstractDataFrame
end

MultiFrameDataset(df::AbstractDataFrame) = MultiFrameDataset(AbstractVector{Integer}[], df)

"""
    multiframedataset(df; group = :all)

Create a [`MultiFrameDataset`](@ref) from a dataset `df` automatically selecting frames.

Selection of frames can be controlled by the parameter `group` which can be:

- `:all` (default): all attributes will be grouped by their [`dimension`](@ref)
- a list of dimensions which will be grouped.

Note: `:all` is the only Symbol accepted by `group`.

# Examples
```jldoctest
julia> df = DataFrame(
    :age => [30, 9],
    :name => ["Python", "Julia"],
    :stat => [[sin(i) for i in 1:50000], [cos(i) for i in 1:50000]]
)
2×3 DataFrame
 Row │ age    name    stat
     │ Int64  String  Array…
─────┼──────────────────────────────────────────────────
   1 │    30  Python  [0.841471, 0.909297, 0.14112, -0…
   2 │     9  Julia   [0.540302, -0.416147, -0.989992,…

julia> multiframedataset(df)
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
 Row │ stat
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…
   2 │ [0.540302, -0.416147, -0.989992,…
```

but setting `group = [1]` will cause only the attibute of dimension `1` to grouped:

```jldoctest
julia> multiframedataset(df; group = [1])
● MultiFrameDataset
   └─ dimensions: (1, 0, 0)
- Frame 1 / 3
   └─ dimension: 1
2×1 SubDataFrame
 Row │ stat
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…
   2 │ [0.540302, -0.416147, -0.989992,…
- Frame 2 / 3
   └─ dimension: 0
2×1 SubDataFrame
 Row │ age
     │ Int64
─────┼───────
   1 │    30
   2 │     9
- Frame 3 / 3
   └─ dimension: 0
2×1 SubDataFrame
 Row │ name
     │ String
─────┼────────
   1 │ Python
   2 │ Julia
```
"""
function multiframedataset(
    df::AbstractDataFrame;
    group::Union{Symbol,AbstractVector{<:Integer}} = :all
)
    @assert isa(group, AbstractVector) || group == :all "group can be `:all` or an " *
        "AbstractVector of dimensions"

    dimdict = Dict{Integer, AbstractVector{<:Integer}}()
    spare = AbstractVector{Integer}[]

    for (i, c) in enumerate(eachcol(df))
        dim = dimension(DataFrame(:curr => c))
        if isa(group, AbstractVector) && !(dim in group)
            push!(spare, [i])
        elseif haskey(dimdict, dim)
            push!(dimdict[dim], i)
        else
            dimdict[dim] = Integer[i]
        end
    end

    desc = sort(collect(zip(keys(dimdict), values(dimdict))), by = x -> x[1])

    MultiFrameDataset(append!(map(x -> x[2], desc), spare), df)
end

getindex(mfd::MultiFrameDataset, i::Integer) = frame(mfd, i)
getindex(mfd::MultiFrameDataset, indices::AbstractVector{<:Integer}) = [frame(mfd, i) for i in indices]

length(mfd::MultiFrameDataset) = length(mfd.descriptor)
ndims(mfd::MultiFrameDataset) = length(mfd)
isempty(mfd::MultiFrameDataset) = length(mfd) == 0
firstindex(mfd::MultiFrameDataset) = 1
lastindex(mfd::MultiFrameDataset) = length(mfd)
eltype(::Type{MultiFrameDataset}) = SubDataFrame

# TODO: consider to kill this function
map(f, mfd::MultiFrameDataset) = Any[f(frame(mfd, i)) for i in 1:length(mfd)]

Base.@propagate_inbounds function iterate(mfd::MultiFrameDataset, i::Integer = 1)
    (i ≤ 0 || i > length(mfd)) && return nothing
    (@inbounds frame(mfd, i), i+1)
end

function ==(mfd1::MultiFrameDataset, mfd2::MultiFrameDataset)
    return mfd1.data == mfd2.data && mfd1.descriptor == mfd2.descriptor
end

"""
TODO: doc
Discuss
"""
function ≈(mfd1::MultiFrameDataset, mfd2::MultiFrameDataset)
    return mfd1.data == mfd2.data
end

"""
TODO: doc
Discuss
"""
function ≊(mfd1::MultiFrameDataset, mfd2::MultiFrameDataset)
    return mfd1 ≈ mfd2 && Set(Set.(mfd1.descriptor)) == Set(Set.(mfd2.descriptor))
end


"""
"""
function show(io::IO, mfd::MultiFrameDataset)
    println(io, "● MultiFrameDataset")
    println(io, "   └─ dimensions: $(dimension(mfd))")
    for (i, frame) in enumerate(mfd)
        println(io, "- Frame $(i) / $(nframes(mfd))")
        println(io, "   └─ dimension: $(dimension(frame))")
        println(io, frame)
    end
end

"""
    frame(mfd, index)

Get the `index`-th frame of `mfd` multiframe dataset.
"""
function frame(mfd::MultiFrameDataset, i::Integer)
    """
    TODO: find a unique template to return, for example, AssertionError messages.
    The following has been added, but it does not follow the current template.
    """
    @assert 1 ≤ i ≤ nframes(mfd) "Index ($i) must be a valid frame number (1:$(nframes(mfd)))"

    @view mfd.data[:,mfd.descriptor[i]]
end

"""
    nframes(mfd)

Get the number of frames of `mfd` multiframe dataset.
"""
nframes(mfd::MultiFrameDataset) = length(mfd.descriptor)

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
```
"""
nattributes(df::AbstractDataFrame) = ncol(df)
nattributes(mfd::MultiFrameDataset) = nattributes(mfd.data)
function nattributes(mfd::MultiFrameDataset, i::Integer)
    """
    TODO: find a unique template to return, for example, AssertionError messages.
    The following has been added, but it does not follow the current template.
    """
    @assert 1 ≤ i ≤ nframes(mfd) "Index ($i) must be a valid frame number (1:$(nframes(mfd)))"

    return nattributes(frame(mfd, i))
end

"""
    addattribute!(mfd, [col, ]attr_id, values)
    addattribute!(mfd, [col, ]attr_id, value)

Add an attibute to the dataset `mfd` with id `attr_id`.

The length of `values` should match `ninstances(mfd)` or an exception is thrown.

If a single `value` is passed as last parameter this will be copied and used for each
instance in the dataset.

Note: duplicated attribute names will result be renamed to avoid conflicts: see `makeunique`
parameter of [`insertcols!`](@ref).

# Examples
TODO: examples
"""
function addattribute!(
    mfd::MultiFrameDataset, col::Integer, attr_id::Symbol, values::AbstractVector
)
    if col != nattributes(mfd)+1
        """
        TODO: implement `col` parameter
        """
        throw(Exception("Still not implemented with `col` != nattributes + 1"))
    end

    @assert length(values) == ninstances(mfd) "value not specified for each instance " *
        "{length(values) != ninstances(mfd)}:{$(length(values)) != $(ninstances(mfd))}"

    insertcols!(mfd.data, col, attr_id => values, makeunique = true)
end
function addattribute!(mfd::MultiFrameDataset, attr_id::Symbol, values::AbstractVector)
    addattribute!(mfd, nattributes(mfd)+1, attr_id, values)
end
function addattribute!(mfd::MultiFrameDataset, col::Integer, attr_id::Symbol, value)
    addattribute!(mfd, col, attr_id, [deepcopy(value) for i in 1:ninstances(mfd)])
end
function addattribute!(mfd::MultiFrameDataset, attr_id::Symbol, value)
    addattribute!(mfd, nattributes(mfd)+1, attr_id, value)
end

"""
    spareattributes(mfd)

Get the indices of all the attributes currently not present in any of the frames of `mfd`
multiframe dataset.
"""
function spareattributes(mfd::MultiFrameDataset)::AbstractVector{<:Integer}
    filter(x -> !(x in unique(cat(mfd.descriptor..., dims = 1))), 1:nattributes(mfd))
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
"""
attributes(df::AbstractDataFrame) = Symbol.(names(df))
function attributes(mfd::MultiFrameDataset, i::Integer)
    """
    TODO: find a unique template to return, for example, AssertionError messages.
    The following has been added, but it does not follow the current template.
    """
    @assert 1 ≤ i ≤ nframes(mfd) "Index ($i) must be a valid frame number (1:$(nframes(mfd)))"

    attributes(frame(mfd, i))
end
function attributes(mfd::MultiFrameDataset)
    d = Dict{Integer,AbstractVector{Symbol}}()
    for i in 1:nframes(mfd)
        d[i] = attributes(mfd, i)
    end
    d
end

# -------------------------------------------------------------
# Instances manipulation

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
ninstances(mfd::MultiFrameDataset) = nrow(mfd.data)
ninstances(mfd::MultiFrameDataset, i::Integer) = nrow(frame(mfd, i))

"""
    addinstance!(mfd, instance)

Add `instance` to `mfd` multiframe dataset.

The instance can be a `DataFrameRow` or an `AbstractVector` but in both cases the number and
type of attributes should match the dataset ones.
"""
function addinstance!(mfd::MultiFrameDataset, instance::DataFrameRow)
    @assert length(instance) == nattributes(mfd) "Mismatching number of attributes " *
        "between dataset ($(nattributes(mfd))) and instance ($(length(instance)))"

    push!(mfd.data, instance)
end
function addinstance!(mfd::MultiFrameDataset, instance::AbstractVector)
    @assert length(instance) == nattributes(mfd) "Mismatching number of attributes " *
        "between dataset ($(nattributes(mfd))) and instance ($(length(instance)))"

    push!(mfd.data, instance)
end

"""
    removeinstances!(mfd, indices)

Remove the instances at `indices` in `mfd` multiframe dataset.

The `MultiFrameDataset` is returned.
"""
function removeinstances!(mfd::MultiFrameDataset, indices::AbstractVector{<:Integer})
    for i in indices
        @assert 1 <= i <= ninstances(mfd) "Index $(i) no in range 1:ninstances " *
            "(1:$(ninstances(mfd)))"
    end

    delete!(mfd.data, unique(indices))

    return mfd
end

"""
    removeinstance!(mfd, i)

Remove the `i`-th instance in `mfd` multiframe dataset.

The `MultiFrameDataset` is returned.
"""
removeinstance!(mfd::MultiFrameDataset, i::Integer) = removeinstances!(mfd, [i])

"""
    keeponlyinstances!(mfd, indices)

Removes all instances that do not correspond to the indices present in `indices` from `mfd`
multiframe dataset.
"""
function keeponlyinstances!(mfd::MultiFrameDataset, indices::AbstractVector{<:Integer})
    removeinstances!(mfd, setdiff(collect(1:ninstances(mfd)), indices))
end

"""
    instance(mfd, i)

Get `i`-th instance in `mfd` multiframe dataset.
"""
function instance(mfd::MultiFrameDataset, i::Integer)
    """
    TODO: find a unique template to return, for example, AssertionError messages.
    The following has been added, but it does not follow the current template.
    """
    @assert 1 ≤ i ≤ ninstances(mfd) "Index ($i) must be a valid instance number " *
        "(1:$(ninstances(mfd))"

    @view mfd.data[i,:]
end

# -------------------------------------------------------------
# Dataset manipulation

"""
    addframe!(mfd, indices)

Create a new frame in `mfd` multiframe dataset using attributes at `indices`.

Note: to add a new frame with new attributes see [`newframe!`](@ref).

# Examples
TODO: examples
"""
function addframe!(mfd::MultiFrameDataset, indices::AbstractVector{<:Integer})
    @assert length(indices) > 0 "Can't add an empty frame to dataset"

    for i in indices
        @assert i in 1:nattributes(mfd) "Index $(i) is out of range 1:nattributes " *
            "(1:$(nattributes(mfd)))"
    end

    push!(mfd.descriptor, indices)
end

"""
    removeframe!(mfd, i)

Remove `i`-th frame from `mfd` multiframe dataset

Note: to completely remove a frame and all attributes in it use [`dropframe!`](@ref)
instead.

# Examples
TODO: examples
"""
function removeframe!(mfd::MultiFrameDataset, i::Integer)
    @assert 1 <= i <= nframes(mfd) "Index $(i) does not correspond to a frame " *
        "(1:$(nframes(mfd)))"

    deleteat!(mfd.descriptor, i)
end

"""
    addattribute_toframe!(mfd, farme_index, attr_index)

Add attribute at index `attr_index` to the frame at index `frame_index` in `mfd` multiframe
dataset.
"""
function addattribute_toframe!(
    mfd::MultiFrameDataset, frame_index::Integer, attr_index::Integer
)
    @assert 1 <= frame_index <= nframes(mfd) "Index $(frame_index) does not correspond to " *
        "a frame (1:$(nframes(mfd)))"
    @assert 1 <= attr_index <= nattributes(mfd) "Index $(attr_index) does not correspond to " *
        "an attribute (1:$(nattributes(mfd)))"

    if attr_index in mfd.descriptor[frame_index]
        @info "Attribute $(attr_index) is already part of frame $(frame_index)"
    else
        push!(mfd.descriptor[frame_index], attr_index)
    end
end

"""
    removeattribute_fromframe!(mfd, farme_index, attr_index)

Remove attribute at index `attr_index` from the frame at index `frame_index` in `mfd`
multiframe dataset.
"""
function removeattribute_fromframe!(
    mfd::MultiFrameDataset, frame_index::Integer, attr_index::Integer
)
    @assert 1 <= frame_index <= nframes(mfd) "Index $(frame_index) does not correspond to " *
        "a frame (1:$(nframes(mfd)))"
    @assert 1 <= attr_index <= nattributes(mfd) "Index $(attr_index) does not correspond to " *
        "an attribute (1:$(nattributes(mfd)))"

    if !(attr_index in mfd.descriptor[frame_index])
        @info "Attribute $(attr_index) is not part of frame $(frame_index)"
    elseif nattributes(mfd, frame_index) == 1
        @info "Attribute $(attr_index) was last attribute of frame $(frame_index): " *
            "removing frame"
        removeframe!(mfd, frame_index)
    else
        deleteat!(
            mfd.descriptor[frame_index], indexin(attr_index, mfd.descriptor[frame_index])[1]
        )
    end
end

"""
    newframe!(mfd, new_frame)

Add `new_frame` as new frame to `mfd` multiframe dataset.

`new_frame` has to be an `AbstractDataFrame`.

Existing attributes can be added to the new frame while adding it to the dataset passing
the corresponding inidices by `existing_attributes`.

TODO: To be reviewed.
"""
function newframe!(
    mfd::MultiFrameDataset, new_frame::AbstractDataFrame;
    existing_attributes::AbstractVector{<:Integer} = Integer[]
)
    # TODO: consider adding the possibility to specify the position as col index
    # TODO: consider adding the possibility to pass names instead of indices to `existing_attributes`
    new_indices = (nattributes(mfd)+1):(nattributes(mfd)+ncol(new_frame))

    for (k, c) in collect(zip(keys(eachcol(new_frame)), collect(eachcol(new_frame))))
        addattribute!(mfd, k, c)
    end
    addframe!(mfd, new_indices)

    for i in existing_attributes
        addattribute_toframe!(mfd, nframes(mfd), i)
    end
end

"""
    dropattribute!(mfd, i)

Drop the `i`-th attribute from `mfd` multiframe dataset.

TODO: To be reviewed.
"""
function dropattribute!(mfd::MultiFrameDataset, i::Integer)
    @assert 1 <= i <= nattributes(mfd) "Attribute $(i) is not a valid attibute index " *
    "(1:$(nattributes(mfd)))"

    j = 1
    while j <= nframes(mfd)
        desc = mfd.descriptor[j]
        if i in desc
            removeattribute_fromframe!(mfd, j, i)
        else
            j += 1
        end
    end

    select!(mfd.data, setdiff(collect(1:nattributes(mfd)), i))

    for (i_frame, desc) in enumerate(mfd.descriptor)
        for (i_attr, attr) in enumerate(desc)
            if attr > i
                mfd.descriptor[i_frame][i_attr] = attr - 1
            end
        end
    end
end

"""
    dropframe!(mfd, i)

Remove `i`-th frame from `mfd` multiframe dataset while dropping all attributes in it.

Note: if the dropped attributes are present in other frames they will also be removed from
them. This can lead to the removal of additional frames other than the `i`-th.

If the intection is to remove a frame without releasing the attributes use
[`removeframe!`](@ref) instead.

# Examples
TODO: examples
"""
function dropframe!(mfd::MultiFrameDataset, i::Integer)
    @assert 1 <= i <= nframes(mfd) "Index $(i) does not correspond to a frame " *
    "(1:$(nframes(mfd)))"

    for i_attr in sort!(deepcopy(mfd.descriptor[i]), rev = true)
        dropattribute!(mfd, i_attr)
    end
    # TODO: consider returning a dataframe composed by exactly the removed attributes
end

"""
    dropspareattributes!(mfd)

Drop all attributes that are not present in any of the frames in `mfd` multiframe dataset.
"""
function dropspareattributes!(mfd::MultiFrameDataset)
    spare = sort!(spareattributes(mfd), rev = true)

    attr_names = attributes(mfd)
    result = DataFrame([(attr_names[i] => mfd.data[:,i]) for i in reverse(spare)]...)

    for i_attr in spare
        dropattribute!(mfd, i_attr)
    end

    return result
end

"""
    dimension(df)

Get the dimension of a dataframe `df`.

If the dataframe has attributes of various dimensions `:mixed` is returned.

If the dataframe is empty (no instances) `:empty` is returned.
This behavior can be changed by setting the keyword argument `force`:

- `:no` (default): return `:mixed` in case of mixed dimension
- `:max`: return the greatest dimension
- `:min`: return the lowest dimension
"""
function dimension(df::AbstractDataFrame; force::Symbol = :no)::Union{Symbol,Integer}
    @assert force in [:no, :max, :min] "`force` can be either :no, :max or :min"

    if nrow(df) == 0
        return :empty
    end

    dims = [maximum(x -> isa(x, AbstractVector) ? ndims(x) : 0, [inst for inst in c])
        for c in eachcol(df)]

    if all(y -> y == dims[1], dims)
        return dims[1]
    elseif force == :max
        return max(dims...)
    elseif force == :min
        return min(dims...)
    else
        return :mixed
    end
end
function dimension(mfd::MultiFrameDataset, i::Integer; kwargs...)
    dimension(frame(mfd, i); kwargs...)
end
function dimension(mfd::MultiFrameDataset; kwargs...)
    Tuple([dimension(frame; kwargs...) for frame in mfd])
end
dimension(dfc::DF.DataFrameColumns; kwargs...) = dimension(DataFrame(dfc); kwargs...)

# -------------------------------------------------------------
# schema

function ST.schema(mfd::MultiFrameDataset; kw...)
    results = ST.Schema[]
    for frame in mfd
        push!(results, ST.schema(frame))
    end

    return results
end
function ST.schema(mfd::MultiFrameDataset, i::Integer; kw...)
    ST.schema(frame(mfd, i))
end

# -------------------------------------------------------------
# describe

function DF.describe(mfd::MultiFrameDataset)
    results = DataFrame[]
    for frame in mfd
        push!(results, DF.describe(frame))
    end
    return results
end
function DF.describe(mfd::MultiFrameDataset, i::Integer; kw...)
    DF.describe(frame(mfd, i))
end
