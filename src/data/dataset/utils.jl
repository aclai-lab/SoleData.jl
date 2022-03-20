
const __note_about_utils = "
!!! note

    It is important to consider that this function is intended for internal use only.

    It assumes that any check is performed prior its call (e.g., check if the index of an
    attribute is valid or not).
"

# -------------------------------------------------------------
# AbstractMultiFrameDataset - utils

"""
    _empty(mfd)

Get a copy of `mfd` multiframe dataset with no instances.

Note: since the returned AbstractMultiFrameDataset will be empty its columns types will be
`Any`.

$(__note_about_utils)
"""
function _empty(mfd::AbstractMultiFrameDataset)
    warn("This function is extremely not efficent especially for large datasets: " *
        "consider creating a dispatch for type " * string(typeof(mfd)))
    return _empty!(deepcopy(mfd))
end
"""
    _empty!(mfd)

Remove all instances from `mfd` multiframe dataset.

Note: since the AbstractMultiFrameDataset will be empty its columns types will become of
type `Any`.

$(__note_about_utils)
"""
function _empty!(mfd::AbstractMultiFrameDataset)
    return removeinstances!(mfd, 1:nisnstances(mfd))
end

"""
    _same_attributes(mfd1, mfd2)

Determine whether two AbstractMultiFrameDatasets have the same attributes.

$(__note_about_utils)
"""
function _same_attributes(mfd1::AbstractMultiFrameDataset, mfd2::AbstractMultiFrameDataset)
    return isequal(
        Dict{Symbol,DataType}(Symbol.(names(data(mfd1))) .=> eltype.(eachcol(data(mfd1)))),
        Dict{Symbol,DataType}(Symbol.(names(data(mfd2))) .=> eltype.(eachcol(data(mfd2))))
    )
end

"""
    _same_dataframe(mfd1, mfd2)

Determine whether two AbstractMultiFrameDatasets have the same inner DataFrame regardless of
the positioning of their columns.

Note: the check will be performed against the instances too; if the intent is to just check
the presence of the same attributes use [`_same_attributes`](@ref) instead.

$(__note_about_utils)
"""
function _same_dataframe(mfd1::AbstractMultiFrameDataset, mfd2::AbstractMultiFrameDataset)
    if !_same_attributes(mfd1, mfd2) || ninstances(mfd1) != ninstances(mfd2)
        return false
    end

    mfd1_attrs = Symbol.(names(data(mfd1)))
    mfd2_attrs = Symbol.(names(data(mfd2)))
    unmixed_indices = [findfirst(x -> isequal(x, name), mfd2_attrs) for name in mfd1_attrs]

    return data(mfd1) == data(mfd2)[:,unmixed_indices]
end

"""
    _same_descriptor(mfd1, mfd2)

Determine whether two AbstractMultiFrameDatasets have the same frames regardless of the
positioning of their columns.

Note: the check will be performed against the instances too; if the intent is to just check
the presence of the same attributes use [`_same_attributes`](@ref) instead.

$(__note_about_utils)
"""
function _same_descriptor(mfd1::AbstractMultiFrameDataset, mfd2::AbstractMultiFrameDataset)
    if !_same_attributes(mfd1, mfd2)
        return false
    end

    if nframes(mfd1) != nframes(mfd2) ||
            [nattributes(f) for f in mfd1] != [nattributes(f) for f in mfd2]
        return false
    end

    mfd1_attrs = Symbol.(names(data(mfd1)))
    mfd2_attrs = Symbol.(names(data(mfd2)))
    unmixed_indices = [findfirst(x -> isequal(x, name), mfd2_attrs) for name in mfd1_attrs]

    for i in 1:nframes(mfd1)
        if frame_descriptor(mfd1)[i] != Integer[unmixed_indices[j]
                for j in frame_descriptor(mfd2)[i]]
            return false
        end
    end

    return data(mfd1) == data(mfd2)[:,unmixed_indices]
end

"""
    _same_instances(mfd1, mfd2)

Determine whether two AbstractMultiFrameDatasets have the same instances regardless of their
order.

$(__note_about_utils)
"""
function _same_instances(mfd1::AbstractMultiFrameDataset, mfd2::AbstractMultiFrameDataset)
    if !_same_attributes(mfd1, mfd2) || ninstances(mfd1) != ninstances(mfd2)
        return false
    end

    return mfd1 ⊆ mfd2 && mfd2 ⊆ mfd1
end

"""
    _same_multiframedataset(mfd1, mfd2)

Determine whether two AbstractMultiFrameDatasets have the same inner DataFrame and frames,
regardless of the ordering of the columns of their DataFrames.

Note: the check will be performed against the instances too; if the intent is to just check
the presence of the same attributes use [`_same_attributes`](@ref) instead.

TODO: perhaps could be done better? E.g. using the aforedefined functions.

$(__note_about_utils)
"""
function _same_multiframedataset(mfd1::AbstractMultiFrameDataset, mfd2::AbstractMultiFrameDataset)
    if !_same_attributes(mfd1, mfd2) || ninstances(mfd1) != ninstances(mfd2)
        return false
    end

    if nframes(mfd1) != nframes(mfd2) ||
            [nattributes(f) for f in mfd1] != [nattributes(f) for f in mfd2]
        return false
    end

    mfd1_attrs = Symbol.(names(data(mfd1)))
    mfd2_attrs = Symbol.(names(data(mfd2)))
    unmixed_indices = [findfirst(x -> isequal(x, name), mfd2_attrs) for name in mfd1_attrs]

    if data(mfd1) != data(mfd2)[:,unmixed_indices]
        return false
    end

    for i in 1:nframes(mfd1)
        if frame_descriptor(mfd1)[i] != Integer[unmixed_indices[j]
                for j in frame_descriptor(mfd2)[i]]
            return false
        end
    end

    return true
end

"""
    _name2index(df, attribute_name)

Get the index of the attribute named `attribute_name`.

If the attribute does not exist `0` will be returned.


    _name2index(df, attribute_names)

Get the indices of the attributes named `attribute_names`.

If an attribute does not exist the returned Vector will contain `0`(-es).

$(__note_about_utils)
"""
function _name2index(df::AbstractDataFrame, attribute_name::Symbol)
    return columnindex(df, attribute_name)
end
function _name2index(mfd::AbstractMultiFrameDataset, attribute_name::Symbol)
    return columnindex(data(mfd), attribute_name)
end
function _name2index(df::AbstractDataFrame, attribute_names::AbstractVector{Symbol})
    return [_name2index(df, attr_name) for attr_name in attribute_names]
end
function _name2index(
    mfd::AbstractMultiFrameDataset,
    attribute_names::AbstractVector{Symbol}
)
    return [_name2index(mfd, attr_name) for attr_name in attribute_names]
end

"""
    _is_attribute_in_frames(mfd, i)

Check if `i`-th attribute is used in any frame or not.

Alternatively to the index the `attribute_name` can be passed as second argument.

$(__note_about_utils)
"""
function _is_attribute_in_frames(mfd::AbstractMultiFrameDataset, i::Integer)
    return i in cat(frame_descriptor(mfd)...; dims = 1)
end
function _is_attribute_in_frames(mfd::AbstractMultiFrameDataset, attribute_name::Symbol)
    return _is_attribute_in_frames(mfd, _name2index(mfd, attribute_name))
end

function _prettyprint_header(io::IO, mfd::AbstractMultiFrameDataset)
    println(io, "● $(typeof(mfd))")
    println(io, "   └─ dimensions: $(dimension(mfd))")
end

function _prettyprint_frames(io::IO, mfd::AbstractMultiFrameDataset)
    for (i, frame) in enumerate(mfd)
        println(io, "- Frame $(i) / $(nframes(mfd))")
        println(io, "   └─ dimension: $(dimension(frame))")
        println(io, frame)
    end
end

function _prettyprint_spareattributes(io::IO, mfd::AbstractMultiFrameDataset)
    spare_attrs = spareattributes(mfd)
    if length(spare_attrs) > 0
        spare_df = @view data(mfd)[:,spare_attrs]
        println(io, "- Spare attributes")
        println(io, "   └─ dimension: $(dimension(spare_df))")
        println(io, spare_df)
    end
end

function _prettyprint_domain(set::AbstractSet)
    vec = collect(set)
    result = "{ "

    for i in 1:length(vec)
        result *= string(vec[i])
        if i != length(vec)
            result *= ","
        end
        result *= " "
    end

    result *= "}"
end
_prettyprint_domain(dom::Tuple) = "($(dom[1]) - $(dom[end]))"

"""
Piecewise Aggregate Approximation
TODO: add docs
"""
function paa(x::AbstractArray{T} where T <: Real; f::Function=identity, decdigits::Int=4, t::Vector{Tuple{Int64,Int64,Int64}}, kwargs...)
    @assert ndims(x) == length(t) "Mismatching dims $(ndims(x)) != $(length(t)), dims must be the same"
    N = length(x)
    n_chunks = t[1][1]

    @assert 1 ≤ n_chunks && n_chunks ≤ N "The number of chunks must be in [1,$(N)]"
    @assert 0 ≤ t[1][2] ≤ floor(N/n_chunks) && 0 ≤ t[1][3] ≤ floor(N/n_chunks)

    z = Array{Float64}(undef, n_chunks) # TODO Float64? solve this?
    for i in 1:n_chunks
        l = Int(ceil((N*(i-1)/n_chunks) + 1))
        h = Int(ceil(N*i/n_chunks))
        if i == 1
            h = h + t[1][3]
        elseif i == n_chunks
            l = l - t[1][2]
        else
            h = h + t[1][3]
            l = l - t[1][2]
        end

        z[i] = round(f(x[l:h]; kwargs...), digits=decdigits)
    end
    return z
end

"""
TODO: docs
"""
linearize_data(d::Any) = d
linearize_data(d::AbstractVector) = d
linearize_data(d::AbstractMatrix) = reshape(m', 1, :)[:]
function linearize_data(d::AbstractArray)
    return throw(ErrorExcpetion("Still can't linearize data of dimension > 2"))
end
# TODO: more linearizations

"""
TODO: docs
"""
unlinearize_data(d::Any, dims::Tuple{}) where {N<:Integer} = d
function unlinearize_data(d::AbstractVector, dims::Tuple{}) where {N<:Integer}
    return length(d) ≤ 1 ? d[1] : collect(d)
end
function unlinearize_data(d::AbstractVector, dims::NTuple{1,<:Integer}) where {N<:Integer}
    return collect(d)
end
function unlinearize_data(d::AbstractVector, dims::NTuple{2,<:Integer}) where {N<:Integer}
    return collect(reshape(d, dims)')
end
function unlinearize_data(d::AbstractVector, dims::NTuple{N,<:Integer}) where {N<:Integer}
    # TODO: implement generic way to unlinearize data
    throw(ErrorException("Unlinearization of data to $(dims) still not implemented"))
end
