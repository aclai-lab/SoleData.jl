
# -------------------------------------------------------------
# AbstractMultiModalDataset - infos

"""
    dimensionality(df)

Return the dimensionality of a dataframe `df`.

If the dataframe has variables of various dimensionalities `:mixed` is returned.

If the dataframe is empty (no instances) `:empty` is returned.
This behavior can be controlled by setting the keyword argument `force`:

- `:no` (default): return `:mixed` in case of mixed dimensionality
- `:max`: return the greatest dimensionality
- `:min`: return the lowest dimensionality
"""
function dimensionality(df::AbstractDataFrame; force::Symbol = :no)::Union{Symbol,Integer}
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
function dimensionality(md::AbstractMultiModalDataset, i::Integer; kwargs...)
    return dimensionality(modality(md, i); kwargs...)
end
function dimensionality(md::AbstractMultiModalDataset; kwargs...)
    return Tuple([dimensionality(modality; kwargs...) for modality in md])
end
dimensionality(dfc::DF.DataFrameColumns; kwargs...) = dimensionality(DataFrame(dfc); kwargs...)
