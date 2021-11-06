"""
GENERAL TODOs:
* find a unique template to return, for example, AssertionError messages.
* control that `add`/`remove` and `insert`/`drop` are coherent.
* use `return` at the end of the functions
* consider to add names to frames
* add Logger; in particular, it should be nice to have a module SoleLogger(s)
"""

# -------------------------------------------------------------
# Abstract types

"""
Abstract supertype for all Datasets.
"""
abstract type AbstractDataset end

# -------------------------------------------------------------
# MultiFrameDataset

"""
    MultiFrameDataset(frames_descriptor, df)

Create a MultiFrameDataset from a DataFrame `df` initializing frames accordingly to
`frames_descriptor` parameter.

`frames_descriptor` is an AbstractVector of frame descriptor which are AbstractVectors of
Integers representing the index of the attributes selected for that frame.

The order matters for both the frames indices and the attributes in them.

# TODO check this
# Examples
```jldoctest
julia> df = DataFrame(
           :age => [30, 9],
           :name => ["Python", "Julia"],
           :stat1 => [[sin(i) for i in 1:50000], [cos(i) for i in 1:50000]],
           :stat2 => [[cos(i) for i in 1:50000], [sin(i) for i in 1:50000]]
       )
2×4 DataFrame
 Row │ age    name    stat1
     │ Int64  String  Array…
─────┼─────────────────────────────────────────────────────
   1 │    30  Python  [0.841471, 0.909297, 0.14112, -0…
   2 │     9  Julia   [0.540302, -0.416147, -0.989992,…
                                           1 column omitted

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
```

    MultiFrameDataset(df; group = :none)

Create a MultiFrameDataset from a DataFrame `df` automatically selecting frames.

Selection of frames can be controlled by the parameter `group` which can be:

- `:none` (default): no frame will be created
- `:all`: all attributes will be grouped by their [`dimension`](@ref)
- a list of dimensions which will be grouped.

Note: `:all` and `:none` are the only Symbols accepted by `group`.

# TODO group should be [0] by default?
# Examples
```jldoctest
julia> df = DataFrame(
           :age => [30, 9],
           :name => ["Python", "Julia"],
           :stat1 => [[sin(i) for i in 1:50000], [cos(i) for i in 1:50000]],
           :stat2 => [[cos(i) for i in 1:50000], [sin(i) for i in 1:50000]]
       )
2×4 DataFrame
 Row │ age    name    stat1
     │ Int64  String  Array…
─────┼─────────────────────────────────────────────────────
   1 │    30  Python  [0.841471, 0.909297, 0.14112, -0…
   2 │     9  Julia   [0.540302, -0.416147, -0.989992,…
                                           1 column omitted

julia> mfd = MultiFrameDataset(df)
● MultiFrameDataset
   └─ dimensions: ()
- Spare attributes
   └─ dimension: mixed
2×4 SubDataFrame
 Row │ age    name    stat1
     │ Int64  String  Array…
─────┼─────────────────────────────────────────────────────
   1 │    30  Python  [0.841471, 0.909297, 0.14112, -0…
   2 │     9  Julia   [0.540302, -0.416147, -0.989992,…
                                           1 column omitted


julia> mfd = MultiFrameDataset(df; group = :all)
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
2×2 SubDataFrame
 Row │ stat1
     │ Array…
─────┼──────────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…
   2 │ [0.540302, -0.416147, -0.989992,…
                            1 column omitted


julia> mfd = MultiFrameDataset(df; group = [0])
● MultiFrameDataset
   └─ dimensions: (0, 1, 1)
- Frame 1 / 3
   └─ dimension: 0
2×2 SubDataFrame
 Row │ age    name
     │ Int64  String
─────┼───────────────
   1 │    30  Python
   2 │     9  Julia
- Frame 2 / 3
   └─ dimension: 1
2×1 SubDataFrame
 Row │ stat1
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…
   2 │ [0.540302, -0.416147, -0.989992,…
- Frame 3 / 3
   └─ dimension: 1
2×1 SubDataFrame
 Row │ stat2
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.540302, -0.416147, -0.989992,…
   2 │ [0.841471, 0.909297, 0.14112, -0…
```
"""
struct MultiFrameDataset <: AbstractDataset
    descriptor :: AbstractVector{AbstractVector{Integer}}
    data       :: AbstractDataFrame

    function MultiFrameDataset(
        frames_descriptor::AbstractVector{<:AbstractVector{<:Integer}}, df::AbstractDataFrame
    )
        return new(frames_descriptor, df)
    end

    function MultiFrameDataset(
        df::AbstractDataFrame;
        group::Union{Symbol,AbstractVector{<:Integer}} = :none
    )
        @assert isa(group, AbstractVector) || group in [:all, :none] "group can be `:all`, " *
            "`:none` or an AbstractVector of dimensions"

        if group == :none
            return new([], df)
        end

        dimdict = Dict{Integer,AbstractVector{<:Integer}}()
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

        return new(append!(map(x -> x[2], desc), spare), df)
    end
end

# -------------------------------------------------------------
# MultiFrameDataset - iterable interface

getindex(mfd::MultiFrameDataset, i::Integer) = frame(mfd, i)
getindex(mfd::MultiFrameDataset, indices::AbstractVector{<:Integer}) = [frame(mfd, i) for i in indices]

length(mfd::MultiFrameDataset) = length(mfd.descriptor)
ndims(mfd::MultiFrameDataset) = length(mfd)
isempty(mfd::MultiFrameDataset) = length(mfd) == 0
firstindex(mfd::MultiFrameDataset) = 1
lastindex(mfd::MultiFrameDataset) = length(mfd)
eltype(::Type{MultiFrameDataset}) = SubDataFrame

Base.@propagate_inbounds function iterate(mfd::MultiFrameDataset, i::Integer = 1)
    (i ≤ 0 || i > length(mfd)) && return nothing
    (@inbounds frame(mfd, i), i+1)
end

# -------------------------------------------------------------
# MultiFrameDataset - comparison

"""
    _empty(mfd)

Get a copy of `mfd` multiframe dataset with no instances.

Note: since the returned MultiFrameDataset will be empty its columns types will be `Any`.
"""
function _empty(mfd::MultiFrameDataset)
    return MultiFrameDataset(
        deepcopy(mfd.descriptor),
        df = DataFrame([attr_name => [] for attr_name in Symbol.(names(mfd.data))])
    )
end
"""
    _empty!(mfd)

Remove all instances from `mfd` multiframe dataset.

Note: since the MultiFrameDataset will be empty its columns types will become `Any`.
"""
function _empty!(mfd::MultiFrameDataset)
    return removeinstances!(mfd, 1:nisnstances(mfd))
end

"""
    _same_attributes(mfd1, mfd2)

Determine whether two MultiFrameDatasets have the same attributes.
# TODO this probably should also check the types of the attributes.
"""
function _same_attributes(mfd1::MultiFrameDataset, mfd2::MultiFrameDataset)
    return Set(Symbol.(names(mfd1.data))) == Set(Symbol.(names(mfd2.data)))
end

"""
    _same_dataframe(mfd1, mfd2)

Determine whether two MultiFrameDatasets have the same inner DataFrame regardless of the
positioning of their columns.

Note: the check will performed against the instances too; if the intent is to just check
the presence of the same attributes use [`_same_attributes`](@ref) instead.
"""
function _same_dataframe(mfd1::MultiFrameDataset, mfd2::MultiFrameDataset)
    if !_same_attributes(mfd1, mfd2) || ninstances(mfd1) != ninstances(mfd2)
        return false
    end

    mfd1_attrs = Symbol.(names(mfd1.data))
    mfd2_attrs = Symbol.(names(mfd2.data))
    unmixed_indices = [findfirst(x -> isequal(x, name), mfd2_attrs) for name in mfd1_attrs]

    mfd1.data == mfd2.data[:,unmixed_indices]
end

"""
    _same_descriptor(mfd1, mfd2)

Determine whether two MultiFrameDatasets have the same frames regardless of the positioning
of their columns.

Note: the check will performed against the instances too; if the intent is to just check
the presence of the same attributes use [`_same_attributes`](@ref) instead.
"""
function _same_descriptor(mfd1::MultiFrameDataset, mfd2::MultiFrameDataset)
    if !_same_attributes(mfd1, mfd2)
        return false
    end

    if nframes(mfd1) != nframes(mfd2) ||
            [nattributes(f) for f in mfd1] != [nattributes(f) for f in mfd2]
        return false
    end

    mfd1_attrs = Symbol.(names(mfd1.data))
    mfd2_attrs = Symbol.(names(mfd2.data))
    unmixed_indices = [findfirst(x -> isequal(x, name), mfd2_attrs) for name in mfd1_attrs]

    for i in 1:nframes(mfd1)
        if mfd1.descriptor[i] != Integer[unmixed_indices[j] for j in mfd2.descriptor[i]]
            return false
        end
    end

    return true
end

"""
    _same_instances(mfd1, mfd2)

Determine whether two MultiFrameDatasets have the same instances regardless of their order.
"""
function _same_instances(mfd1::MultiFrameDataset, mfd2::MultiFrameDataset)
    if !_same_attributes(mfd1, mfd2) || ninstances(mfd1) != ninstances(mfd2)
        return false
    end

    return mfd1 ⊆ mfd2 && mfd2 ⊆ mfd1
end

"""
    _same_multiframedataset(mfd1, mfd2)

Determine whether two MultiFrameDatasets have the same inner DataFrame and frames regardless
of the positioning of their columns.

Note: the check will performed against the instances too; if the intent is to just check
the presence of the same attributes use [`_same_attributes`](@ref) instead.

TODO perhaps could be done better? E.g. using the aforedefined functions.
"""
function _same_multiframedataset(mfd1::MultiFrameDataset, mfd2::MultiFrameDataset)
    if !_same_attributes(mfd1, mfd2) || ninstances(mfd1) != ninstances(mfd2)
        return false
    end

    if nframes(mfd1) != nframes(mfd2) ||
            [nattributes(f) for f in mfd1] != [nattributes(f) for f in mfd2]
        return false
    end

    mfd1_attrs = Symbol.(names(mfd1.data))
    mfd2_attrs = Symbol.(names(mfd2.data))
    unmixed_indices = [findfirst(x -> isequal(x, name), mfd2_attrs) for name in mfd1_attrs]

    if mfd1.data != mfd2.data[:,unmixed_indices]
        return false
    end

    for i in 1:nframes(mfd1)
        if mfd1.descriptor[i] != Integer[unmixed_indices[j] for j in mfd2.descriptor[i]]
            return false
        end
    end

    return true
end

"""
    ==(mfd1, mfd2)
    isequal(mfd1, mfd2)

Determine whether two MultiFrameDatasets are equal.

Note: the check is also performed on the instances. This means that if the two datasets are
the same but they differ by instance oreder this will return `false`.

If the intent is to check if two MultiFrameDatasets have same instances regardless of the
order use [`≊`](@ref) instead.
If the intent is to check if two MultiFrameDatasets have same frame descriptors and
attributes use [`isapprox`](@ref) instead.

TODO change documentation
"""
function isequal(mfd1::MultiFrameDataset, mfd2::MultiFrameDataset)
    return (mfd1.data == mfd2.data && mfd1.descriptor == mfd2.descriptor) ||
        _same_multiframedataset(mfd1, mfd2)
end
function ==(mfd1::MultiFrameDataset, mfd2::MultiFrameDataset)
    isequal(mfd1, mfd2)
end

"""
    ≊(mfd1, mfd2)
    isapproxeq(mfd1, mfd2)

Determine whether two MultiFrameDatasets are "approximately" equivalent.

Two MultiFrameDatasets are considered "approximately" equivalent if they have same frame
descriptors, attributes and instances.

Note: this means that the order of the instance in the datasets does not matter.

If the intent is to check if two MultiFrameDatasets have same instances in the same order
use [`isequal`](@ref) instead.
If the intent is to check if two MultiFrameDatasets have same frame descriptors and
attributes use [`isapprox`](@ref) instead.

TODO review
"""
function isapproxeq(mfd1::MultiFrameDataset, mfd2::MultiFrameDataset)
    return isequal(mfd1, mfd2) && _same_instances(mfd1, mfd2)
end
function ≊(mfd1::MultiFrameDataset, mfd2::MultiFrameDataset)
    isapproxeq(mfd1, mfd2)
end

"""
    ≈(mfd1, mfd2)
    isapprox(mfd1, mfd2)

Determine whether two MultiFrameDatasets are similar.

Two MultiFrameDatasets are considered similar if they have same frame descriptors and
attributes. Note that this means no check over instances is performed.

If the intent is to check if two MultiFrameDatasets have same instances in the same order
use [`isequal`](@ref) instead.
If the intent is to check if two MultiFrameDatasets have same instances regardless of the
order use [`≊`](@ref) instead.
"""
function isapprox(mfd1::MultiFrameDataset, mfd2::MultiFrameDataset)
    # note: _same_descriptor already includes attributes checking
    return _same_descriptor(mfd1, mfd2)
end

# -------------------------------------------------------------
# Set operations

function in(instance::DataFrameRow, mfd::MultiFrameDataset)
    return instance in eachrow(mfd.data)
end
function in(instance::AbstractVector, mfd::MultiFrameDataset)
    if nattributes(mfd) != length(instance)
        return false
    end

    dfr = eachrow(DataFrame([attr_name => instance[i]
        for (i, attr_name) in Symbol.(names(mfd.data))]))[1]

    return dfr in eachrow(mfd.data)
end

function issubset(instances::AbstractDataFrame, mfd::MultiFrameDataset)
    for dfr in eachrow(instances)
        if !(dfr in mfd)
            return false
        end
    end

    return true
end
function issubset(mfd1::MultiFrameDataset, mfd2::MultiFrameDataset)
    return mfd1 ≈ mfd2 && mfd1.data ⊆ mfd2
end

function setdiff(mfd1::MultiFrameDataset, mfd2::MultiFrameDataset)
    # TODO: implement setdiff!
    throw(Exception("Not implemented"))
end
function setdiff!(mfd1::MultiFrameDataset, mfd2::MultiFrameDataset)
    # TODO: implement setdiff!
    throw(Exception("Not implemented"))
end
function intersect(mfd1::MultiFrameDataset, mfd2::MultiFrameDataset)
    # TODO: implement intersect
    throw(Exception("Not implemented"))
end
function intersect!(mfd1::MultiFrameDataset, mfd2::MultiFrameDataset)
    # TODO: implement intersect!
    throw(Exception("Not implemented"))
end
function union(mfd1::MultiFrameDataset, mfd2::MultiFrameDataset)
    # TODO: implement union
    throw(Exception("Not implemented"))
end
function union!(mfd1::MultiFrameDataset, mfd2::MultiFrameDataset)
    # TODO: implement union!
    throw(Exception("Not implemented"))
end

# -------------------------------------------------------------
# MultiFrameDataset - informations

function show(io::IO, mfd::MultiFrameDataset)
    println(io, "● MultiFrameDataset")
    println(io, "   └─ dimensions: $(dimension(mfd))")
    for (i, frame) in enumerate(mfd)
        println(io, "- Frame $(i) / $(nframes(mfd))")
        println(io, "   └─ dimension: $(dimension(frame))")
        println(io, frame)
    end
    spare_attrs = spareattributes(mfd)
    if length(spare) > 0
        spare_df = @view mfd.data[:,spare_attrs]
        println(io, "- Spare attributes")
        println(io, "   └─ dimension: $(dimension(spare_df))")
        println(io, spare_df)
    end
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

"""
TODO documentation
"""
function _name2index(df::AbstractDataFrame, attribute_name::Symbol)
    columnindex(df, attribute_name)
end
function _name2index(mfd::MultiFrameDataset, attribute_name::Symbol)
    columnindex(mfd.data, attribute_name)
end
function _name2index(df::AbstractDataFrame, attribute_names::AbstractVector{Symbol})
    [_name2index(df, attr_name) for attr_name in attribute_names]
end
function _name2index(mfd::MultiFrameDataset, attribute_names::AbstractVector{Symbol})
    [_name2index(mfd, attr_name) for attr_name in attribute_names]
end

"""
    frame(mfd, i)

Get the `i`-th frame of `mfd` multiframe dataset.
"""
function frame(mfd::MultiFrameDataset, i::Integer)
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
    @assert 1 ≤ i ≤ nframes(mfd) "Index ($i) must be a valid frame number (1:$(nframes(mfd)))"

    return nattributes(frame(mfd, i))
end

"""
    insertattribute!(mfd, [col, ]attr_id, values)
    insertattribute!(mfd, [col, ]attr_id, value)

Insert an attibute in the dataset `mfd` with id `attr_id`.

The length of `values` should match `ninstances(mfd)` or an exception is thrown.

If a single `value` is passed as last parameter this will be copied and used for each
instance in the dataset.

Note: duplicated attribute names will be renamed to avoid conflicts: see `makeunique`
parameter of [`insertcols!`](@ref) in DataFrames documentation.

# Examples
TODO: examples
"""
function insertattribute!(
    mfd::MultiFrameDataset, col::Integer, attr_id::Symbol, values::AbstractVector
)
    if col != nattributes(mfd)+1
        # TODO: implement `col` parameter
        throw(Exception("Still not implemented with `col` != nattributes + 1"))
    end

    @assert length(values) == ninstances(mfd) "value not specified for each instance " *
        "{length(values) != ninstances(mfd)}:{$(length(values)) != $(ninstances(mfd))}"

    insertcols!(mfd.data, col, attr_id => values, makeunique = true)
end
function insertattribute!(mfd::MultiFrameDataset, attr_id::Symbol, values::AbstractVector)
    insertattribute!(mfd, nattributes(mfd)+1, attr_id, values)
end
function insertattribute!(mfd::MultiFrameDataset, col::Integer, attr_id::Symbol, value)
    insertattribute!(mfd, col, attr_id, [deepcopy(value) for i in 1:ninstances(mfd)])
end
function insertattribute!(mfd::MultiFrameDataset, attr_id::Symbol, value)
    insertattribute!(mfd, nattributes(mfd)+1, attr_id, value)
end

"""
TODO: docs
"""
function hasattribute(df::AbstractDataFrame, attribute_name::Symbol)
    _name2index(df, attribute_name) > 0
end
function hasattribute(mfd::MultiFrameDataset, frame_index::Integer, attribute_name::Symbol)
    _name2index(frame(mfd, frame_index), attribute_name) > 0
end
function hasattribute(mfd::MultiFrameDataset, attribute_name::Symbol)
    _name2index(mfd, attribute_name) > 0
end

"""
TODO: docs
"""
function hasattributes(df::AbstractDataFrame, attribute_names::AbstractVector{Symbol})
    !(0 in _name2index(df, attribute_names))
end
function hasattributes(
    mfd::MultiFrameDataset,
    frame_index::Integer,
    attribute_names::AbstractVector{Symbol}
)
    !(0 in _name2index(frame(mfd, frame_index), attribute_names))
end
function hasattributes(mfd::MultiFrameDataset, attribute_names::AbstractVector{Symbol})
    !(0 in _name2index(mfd, attribute_names))
end

"""
TODO: docs
"""
function attributeindex(df::AbstractDataFrame, attribute_name::Symbol)
    _name2index(df, attribute_name)
end
function attributeindex(mfd::MultiFrameDataset, frame_index::Integer, attribute_name::Symbol)
    _name2index(frame(mfd, frame_index), attribute_name)
end
function attributeindex(mfd::MultiFrameDataset, attribute_name::Symbol)
    _name2index(mfd, attribute_name)
end

"""
    spareattributes(mfd)

Get the indices of all the attributes currently not present in any of the frames of `mfd`
multiframe dataset.
"""
function spareattributes(mfd::MultiFrameDataset)::AbstractVector{<:Integer}
    setdiff(1:nattributes(mfd), unique(cat(mfd.descriptor..., dims = 1)))
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
    @assert 1 ≤ i ≤ nframes(mfd) "Index ($i) must be a valid frame number (1:$(nframes(mfd)))"

    attributes(frame(mfd, i))
end
function attributes(mfd::MultiFrameDataset)
    d = Dict{Integer,AbstractVector{Symbol}}()

    for i in 1:nframes(mfd)
        d[i] = attributes(mfd, i)
    end

    return d
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

Add `instance` to `mfd` multiframe dataset and return `mfd`.

The instance can be a `DataFrameRow` or an `AbstractVector` but in both cases the number and
type of attributes should match the dataset ones.

# TODO perhaps insertinstance! ?
"""
function addinstance!(mfd::MultiFrameDataset, instance::DataFrameRow)
    @assert length(instance) == nattributes(mfd) "Mismatching number of attributes " *
        "between dataset ($(nattributes(mfd))) and instance ($(length(instance)))"

    push!(mfd.data, instance)

    return mfd
end
function addinstance!(mfd::MultiFrameDataset, instance::AbstractVector)
    @assert length(instance) == nattributes(mfd) "Mismatching number of attributes " *
        "between dataset ($(nattributes(mfd))) and instance ($(length(instance)))"

    push!(mfd.data, instance)

    return mfd
end

"""
    removeinstances!(mfd, indices)

Remove the instances at `indices` in `mfd` multiframe dataset and return `mfd`.

The `MultiFrameDataset` is returned.

# TODO rename from `remove` to `delete` and from `add` to `push`.
"""
function removeinstances!(mfd::MultiFrameDataset, indices::AbstractVector{<:Integer})
    for i in indices
        @assert 1 ≤ i ≤ ninstances(mfd) "Index $(i) no in range 1:ninstances " *
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
TODO: add new dispatch docs
"""
function instance(df::AbstractDataFrame, i::Integer)
    @assert 1 ≤ i ≤ ninstances(df) "Index ($i) must be a valid instance number " *
        "(1:$(ninstances(mfd))"

    @view df[i,:]
end
function instance(mfd::MultiFrameDataset, i::Integer)
    @assert 1 ≤ i ≤ ninstances(mfd) "Index ($i) must be a valid instance number " *
        "(1:$(ninstances(mfd))"

    instance(mfd.data, i)
end
function instance(mfd::MultiFrameDataset, i_frame::Integer, i_instance::Integer)
    @assert 1 ≤ i_frame ≤ nframes(mfd) "Index ($i_frame) must be a valid " *
        "frame number (1:$(nframes(mfd))"

    instance(frame(mfd, i_frame), i_instance)
end

"""
    instances(mfd, indices)

Get instances at `indices` in `mfd` multiframe dataset.
TODO: add new dispatch docs
"""
function instances(df::AbstractDataFrame, indices::AbstractVector{<:Integer})
    for i in indices
        @assert 1 ≤ i ≤ ninstances(df) "Index ($i) must be a valid instance number " *
            "(1:$(ninstances(mfd))"
    end

    @view df[indices,:]
end
function instances(mfd::MultiFrameDataset, indices::AbstractVector{<:Integer})
    instances(mfd.data, indices)
end
function instances(
    mfd::MultiFrameDataset,
    i_frame::Integer,
    inst_indices::AbstractVector{<:Integer}
)
    @assert 1 ≤ i_frame ≤ nframes(mfd) "Index ($i_frame) must be a valid " *
        "frame number (1:$(nframes(mfd))"

    instances(frame(mfd, i_frame), inst_indices)
end

# -------------------------------------------------------------
# Dataset manipulation

"""
    addframe!(mfd, indices)
    addframe!(mfd, attribute_names)

Create a new frame in `mfd` multiframe dataset using attributes at `indices` and return
`mfd`.

Alternatively to the `indices` the attribute names can be used.

Note: to add a new frame with new attributes see [`newframe!`](@ref).

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
function addframe!(mfd::MultiFrameDataset, indices::AbstractVector{<:Integer})
    @assert length(indices) > 0 "Can't add an empty frame to dataset"

    for i in indices
        @assert i in 1:nattributes(mfd) "Index $(i) is out of range 1:nattributes " *
            "(1:$(nattributes(mfd)))"
    end

    push!(mfd.descriptor, indices)

    return mfd
end
function addframe!(mfd::MultiFrameDataset, attribute_names::AbstractVector{Symbol})
    for attr_name in attribute_names
        @assert hasattribute(mfd, attr_name) "MultiFrameDataset does not contain " *
            "attribute $(attr_name)"
    end

    addframe!(mfd, _name2index(mfd, attribute_names))
end

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
function removeframe!(mfd::MultiFrameDataset, i::Integer)
    @assert 1 ≤ i ≤ nframes(mfd) "Index $(i) does not correspond to a frame " *
        "(1:$(nframes(mfd)))"

    deleteat!(mfd.descriptor, i)

    return mfd
end

"""
    addattribute_toframe!(mfd, farme_index, attr_index)
    addattribute_toframe!(mfd, farme_index, attr_name)

Add attribute at index `attr_index` to the frame at index `frame_index` in `mfd` multiframe
dataset and return `mfd`.

Alternatively to `attr_index` the attribute name can be used.
"""
function addattribute_toframe!(
    mfd::MultiFrameDataset, frame_index::Integer, attr_index::Integer
)
    @assert 1 ≤ frame_index ≤ nframes(mfd) "Index $(frame_index) does not correspond to " *
        "a frame (1:$(nframes(mfd)))"
    @assert 1 ≤ attr_index ≤ nattributes(mfd) "Index $(attr_index) does not correspond to " *
        "an attribute (1:$(nattributes(mfd)))"

    if attr_index in mfd.descriptor[frame_index]
        @info "Attribute $(attr_index) is already part of frame $(frame_index)"
    else
        push!(mfd.descriptor[frame_index], attr_index)
    end

    return mfd
end
function addattribute_toframe!(
    mfd::MultiFrameDataset, frame_index::Integer, attr_name::Symbol
)
    @assert hasattribute(mfd, attr_name) "MultiFrameDataset does not contain attribute " *
        "$(attr_name)"

    addattribute_toframe!(mfd, frame_index, _name2index(mfd, attr_name))
end

"""
    removeattribute_fromframe!(mfd, farme_index, attr_index)
    removeattribute_fromframe!(mfd, farme_index, attr_name)

Remove attribute at index `attr_index` from the frame at index `frame_index` in `mfd`
multiframe dataset and return `mfd`.

Alternatively to `attr_index` the attribute name can be used.
"""
function removeattribute_fromframe!(
    mfd::MultiFrameDataset, frame_index::Integer, attr_index::Integer
)
    @assert 1 ≤ frame_index ≤ nframes(mfd) "Index $(frame_index) does not correspond to " *
        "a frame (1:$(nframes(mfd)))"
    @assert 1 ≤ attr_index ≤ nattributes(mfd) "Index $(attr_index) does not correspond to " *
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

    return mfd
end
function removeattribute_fromframe!(
    mfd::MultiFrameDataset, frame_index::Integer, attr_name::Symbol
)
    @assert hasattribute(mfd, attr_name) "MultiFrameDataset does not contain attribute " *
        "$(attr_name)"

    removeattribute_fromframe!(mfd, frame_index, _name2index(mfd, attr_name))
end

"""
    newframe!(mfd[, col], new_frame)

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


julia> newframe!(mfd, DataFrame(:age => [30, 9]))
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


julia> newframe!(mfd, DataFrame(:age => [30, 9]); existing_attributes = [1])
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

TODO change name
"""
function newframe!(
    mfd::MultiFrameDataset,
    col::Integer,
    new_frame::AbstractDataFrame,
    existing_attributes::AbstractVector{<:Integer} = Integer[]
)
    if col != nattributes(mfd)+1
        # TODO: implement `col` parameter
        throw(Exception("Still not implemented with `col` != nattributes + 1"))
    end

    # TODO: consider adding the possibility to pass names instead of indices to `existing_attributes`
    new_indices = (nattributes(mfd)+1):(nattributes(mfd)+ncol(new_frame))

    for (k, c) in collect(zip(keys(eachcol(new_frame)), collect(eachcol(new_frame))))
        insertattribute!(mfd, k, c)
    end
    addframe!(mfd, new_indices)

    for i in existing_attributes
        addattribute_toframe!(mfd, nframes(mfd), i)
    end

    return mfd
end
function newframe!(
    mfd::MultiFrameDataset,
    col::Integer,
    new_frame::AbstractDataFrame,
    existing_attributes::AbstractVector{Symbol}
)
    for attr_name in existing_attributes
        @assert hasattribute(mfd, attr_name) "MultiFrameDataset does not contain " *
            "attribute $(attr_name)"
    end

    newframe!(mfd, col, new_frame, _name2index(mfd, existing_attributes))
end
function newframe!(
    mfd::MultiFrameDataset,
    new_frame::AbstractDataFrame,
    existing_attributes::AbstractVector{<:Integer} = Integer[]
)
    newframe!(mfd, nattributes(mfd)+1, new_frame, existing_attributes)
end
function newframe!(
    mfd::MultiFrameDataset,
    new_frame::AbstractDataFrame,
    existing_attributes::AbstractVector{Symbol}
)
    for attr_name in existing_attributes
        @assert hasattribute(mfd, attr_name) "MultiFrameDataset does not contain " *
            "attribute $(attr_name)"
    end

    println(existing_attributes)
    println(_name2index(mfd, existing_attributes))

    newframe!(mfd, nattributes(mfd)+1, new_frame, _name2index(mfd, existing_attributes))
end

"""
    dropattribute!(mfd, i)

Drop the `i`-th attribute from `mfd` multiframe dataset and return a DataFrame composed by
the dopped column.

TODO: To be reviewed.
"""
function dropattribute!(mfd::MultiFrameDataset, i::Integer)
    @assert 1 ≤ i ≤ nattributes(mfd) "Attribute $(i) is not a valid attibute index " *
        "(1:$(nattributes(mfd)))"

    j = 1
    while j ≤ nframes(mfd)
        desc = mfd.descriptor[j]
        if i in desc
            removeattribute_fromframe!(mfd, j, i)
        else
            j += 1
        end
    end

    result = DataFrame(Symbol(names(mfd.data)[i]) => mfd.data[:,i])

    select!(mfd.data, setdiff(collect(1:nattributes(mfd)), i))

    for (i_frame, desc) in enumerate(mfd.descriptor)
        for (i_attr, attr) in enumerate(desc)
            if attr > i
                mfd.descriptor[i_frame][i_attr] = attr - 1
            end
        end
    end

    return result
end
function dropattribute!(mfd::MultiFrameDataset, attribute_name::Symbol)
    @assert hasattribute(mfd, attribute_name) "MultiFrameDataset does not contain " *
        "attribute $(attribute_name)"

    dropattribute!(mfd, _name2index(mfd, attribute_name))
end

"""
"""
function dropattributes!(mfd::MultiFrameDataset, indices::AbstractVector{<:Integer})
    for i in indices
        @assert 1 ≤ i ≤ nattributes(mfd) "Index $(i) does not correspond to an " *
            "attribute (1:$(nattributes(mfd)))"
    end

    attr_names = Symbol.(names(mfd.data))
    result = DataFrame([(attr_names[i] => mfd.data[:,i]) for i in indices]...)

    for i_attr in sort!(deepcopy(indices), rev = true)
        dropattribute!(mfd, i_attr)
    end

    return result
end
function dropattributes!(mfd::MultiFrameDataset, attribute_names::AbstractVector{Symbol})
    for attr_name in attribute_names
        @assert hasattribute(mfd, attr_name) "MultiFrameDataset does not contain " *
            "attribute $(attr_name)"
    end

    dropattributes!(mfd, _name2index(mfd, attribute_names))
end

"""
    keeponlyattributes!(mfd, indices)

Drop all attributes that do not correspond to the indices present in `indices` from `mfd`
multiframe dataset.

Note: if the dropped attributes are present in some frame they will also be removed from
them. This can lead to the removal of frames as side effect.
"""
function keeponlyattributes!(mfd::MultiFrameDataset, indices::AbstractVector{<:Integer})
    dropattributes!(mfd, setdiff(collect(1:nattributes(mfd)), indices))
end
function keeponlyattributes!(mfd::MultiFrameDataset, attribute_names::AbstractVector{Symbol})
    for attr_name in attribute_names
        @assert hasattribute(mfd, attr_name) "MultiFrameDataset does not contain " *
            "attribute $(attr_name)"
    end

    dropattributes!(mfd, setdiff(collect(1:nattributes(mfd)), _name2index(mfd, attribute_names)))
end
# TODO check parameters
function keeponlyattributes!(
    mfd::MultiFrameDataset,
    attribute_names::AbstractVector{<:AbstractVector{Symbol}}
)
    for attr_name in attribute_names
        @assert hasattribute(mfd, attr_name) "MultiFrameDataset does not contain " *
            "attribute $(attr_name)"
    end

    dropattributes!(mfd, setdiff(collect(1:nattributes(mfd)), _name2index(mfd, attribute_names)))
end

"""
    dropframe!(mfd, i)

Remove `i`-th frame from `mfd` multiframe dataset while dropping all attributes in it and
return a DatFrame composed by all removed attributes columns.

Note: if the dropped attributes are present in other frames they will also be removed from
them. This can lead to the removal of additional frames other than the `i`-th.

If the intection is to remove a frame without releasing the attributes use
[`removeframe!`](@ref) instead.

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
function dropframe!(mfd::MultiFrameDataset, i::Integer)
    @assert 1 ≤ i ≤ nframes(mfd) "Index $(i) does not correspond to a frame " *
        "(1:$(nframes(mfd)))"

    dropattributes!(mfd, mfd.descriptor[i])
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
function dropspareattributes!(mfd::MultiFrameDataset)
    spare = sort!(spareattributes(mfd), rev = true)

    attr_names = Symbol.(names(mfd.data))
    result = DataFrame([(attr_names[i] => mfd.data[:,i]) for i in reverse(spare)]...)

    for i_attr in spare
        dropattribute!(mfd, i_attr)
    end

    return result
end

# -------------------------------------------------------------
# schema

function ST.schema(mfd::MultiFrameDataset; kwargs...)
    results = ST.Schema[]
    for frame in mfd
        push!(results, ST.schema(frame, kwargs...))
    end

    return results
end
function ST.schema(mfd::MultiFrameDataset, i::Integer; kwargs...)
    ST.schema(frame(mfd, i); kwargs...)
end

# -------------------------------------------------------------
# describe

function _describeonm(df::AbstractDataFrame; cols::AbstractVector{<:Integer} = 1:ncol(df), descfunction::Function)
    results = Vector{Float64}[]
    for j in cols
        push!(results, descfunction.(df[:,j]))
    end
    return results
end

function describeonm(df::AbstractDataFrame; desc::AbstractVector{Symbol} = Symbol[], kwargs...)
    cols = findall([eltype(c) <: AbstractVector{<:Number} for c in eachcol(df)])
    df_final = describe(df)
    for d in desc
        df_final = insertcols!(df_final, ncol(df_final)+1, d => _describeonm(df; descfunction = desc_dict[d]))
    end
    return df_final
end

desc_dict = Dict{Symbol,Function}(
    :mean_m => mean,
    :min_m => minimum,
    :max_m => maximum
    #:n_f => catch22[:f1]
    )

function DF.describe(mfd::MultiFrameDataset; desc::AbstractVector{Symbol} = Symbol[], kwargs...)
    results = DataFrame[]
    for f in desc
        @assert haskey(desc_dict, f) "Func not found"
    end

    for frame in mfd
        push!(results, describeonm(frame; desc, kwargs...))
    end
    return results
end

function DF.describe(mfd::MultiFrameDataset, i::Integer; kwargs...)
    DF.describe(frame(mfd, i), kwargs...)
end




