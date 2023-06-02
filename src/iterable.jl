
# -------------------------------------------------------------
# AbstractMultiModalDataset - iterable interface

getindex(md::AbstractMultiModalDataset, i::Integer) = modality(md, i)
function getindex(md::AbstractMultiModalDataset, indices::AbstractVector{<:Integer})
    return [modality(md, i) for i in indices]
end

length(md::AbstractMultiModalDataset) = length(grouped_variables(md))
ndims(md::AbstractMultiModalDataset) = length(md)
isempty(md::AbstractMultiModalDataset) = length(md) == 0
firstindex(md::AbstractMultiModalDataset) = 1
lastindex(md::AbstractMultiModalDataset) = length(md)
eltype(::Type{AbstractMultiModalDataset}) = SubDataFrame
eltype(::AbstractMultiModalDataset) = SubDataFrame

Base.@propagate_inbounds function iterate(md::AbstractMultiModalDataset, i::Integer = 1)
    (i ≤ 0 || i > length(md)) && return nothing
    return (@inbounds modality(md, i), i+1)
end

# TODO: consider adding the following interfaces to access the inner dataframe
function getindex(
    md::AbstractMultiModalDataset,
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
    return getindex(data(md), i, j)
end
