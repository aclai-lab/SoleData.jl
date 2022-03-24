
# -------------------------------------------------------------
# AbstractMultiFrameDataset - iterable interface

getindex(mfd::AbstractMultiFrameDataset, i::Integer) = frame(mfd, i)
function getindex(mfd::AbstractMultiFrameDataset, indices::AbstractVector{<:Integer})
    return [frame(mfd, i) for i in indices]
end

length(mfd::AbstractMultiFrameDataset) = length(frame_descriptor(mfd))
ndims(mfd::AbstractMultiFrameDataset) = length(mfd)
isempty(mfd::AbstractMultiFrameDataset) = length(mfd) == 0
firstindex(mfd::AbstractMultiFrameDataset) = 1
lastindex(mfd::AbstractMultiFrameDataset) = length(mfd)
eltype(::Type{AbstractMultiFrameDataset}) = SubDataFrame

Base.@propagate_inbounds function iterate(mfd::AbstractMultiFrameDataset, i::Integer = 1)
    (i ≤ 0 || i > length(mfd)) && return nothing
    return (@inbounds frame(mfd, i), i+1)
end

# TODO: consider adding the following interfaces to access the inner dataframe
function getindex(
    mfd::AbstractMultiFrameDataset,
    i::Union{Colon,<:Integer,<:AbstractVector{<:Integer},<:Tuple{<:Integer}},
    j::Union{
        Colon,
        <:Integer,
        <:AbstractVector{<:Integer},
        <:Tuple{<:Integer},
        Symbol,
        <:AbstractVector{Symbol}
    },
)
    # NOTE: typeof(!) is left-out to avoid problems but consider adding it
    return getindex(data(mfd), i, j)
end
