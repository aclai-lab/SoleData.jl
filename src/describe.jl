
# -------------------------------------------------------------
# AbstractMultiModalDataset - describe

const desc_dict = Dict{Symbol,Function}(
    :mean => mean,
    :min => minimum,
    :max => maximum,
    :median => median,
    :quantile_1 => (q_1 = x -> quantile(x, 0.25)),
    :quantile_3 =>(q_3 = x -> quantile(x, 0.75)),
    # allow catch22 desc
    (getnames(catch22) .=> catch22)...
)

const auto_desc_by_dim = Dict{Integer,Vector{Symbol}}(
    1 => [:mean, :min, :max, :quantile_1, :median, :quantile_3]
)

function _describeonm(
    df::AbstractDataFrame;
    descfunction::Function,
    cols::AbstractVector{<:Integer} = 1:ncol(df),
    t::AbstractVector{<:NTuple{3,Integer}} = [(1, 0, 0)]
)
    modality_dim = dimensionality(df)
    @assert length(t) == 1 || length(t) == modality_dim "`t` length has to be `1` or the " *
        "dimensionality of the modality ($(modality_dim))"

    if modality_dim > 1 && length(t) == 1
        # if dimensionality is > 1 but only 1 triple is passed use it for all dimensionalities
        t = fill(t, modality_dim)
    end

    x = Matrix{AbstractFloat}[]

    for j in cols
		# TODO: not a good habit using abstract type as elements of Arrays
        y = Matrix{AbstractFloat}(undef, nrow(df), t[1][1])
		# TODO: maybe
		Threads.@threads for (i, paa_result) in collect(enumerate(paa.(df[:,j]; f = descfunction, t = t)))
            y[i,:] = paa_result
        end
        push!(x, y)
    end

    return x
end

# TODO: describeonm should have the same interface as the `describe` function from DataFrames
# describe(df::AbstractDataFrame; cols=:)
# describe(df::AbstractDataFrame, stats::Union{Symbol,Pair}...; cols=:)
function describeonm(
    df::AbstractDataFrame;
    desc::AbstractVector{Symbol} = Symbol[],
    t::AbstractVector{<:NTuple{3,Integer}} = [(1, 0, 0)],
)
    for d in desc
        @assert d in keys(desc_dict) "`$(d)` is not a valid descriptor Symbol; available " *
            "descriptors are $(keys(desc_dict))"
    end

    return DataFrame(
        :Variables => Symbol.(propertynames(df)),
        [d => _describeonm(df; descfunction = desc_dict[d], t) for d in desc]...
    )
end

# TODO: same as above
"""
	describe(md; t = fill([(1, 0, 0)], nmodalities(md)), kwargs...)

Return descriptive statistics for an `AbstractMultiModalDataset` as a `Vector` of new
`DataFrame`s where each row represents a variable and each column a summary statistic.

# Arguments

* `md`: the `AbstractMultiModalDataset`;
* `t`: is a vector of `nmodalities` elements,
    where each element is a vector as long as the dimensionality of
	the i-th modality. Each element of the innermost vector is a tuple
	of arguments for [`paa`](@ref).

For other see the documentation of [`DataFrames.describe`](@ref) function.

# Examples
TODO: examples
"""
function DF.describe(
	md::AbstractMultiModalDataset;
	t::AbstractVector{<:AbstractVector{<:NTuple{3,Integer}}} = fill([(1, 0, 0)], nmodalities(md)),
	kwargs...
)
    return [DF.describe(md, i; t = t[i], kwargs...) for i in 1:nmodalities(md)]
end

# TODO: implement this
# function DF.describe(md::MultiModalDataset, stats::Union{Symbol,Pair}...; cols=:)
#     # TODO: select proper defaults stats based on `dimensionality` of each modality
# end

function DF.describe(md::AbstractMultiModalDataset, i::Integer; kwargs...)
    modality_dim = dimensionality(modality(md, i))
    if modality_dim == :mixed || modality_dim == :empty
        # TODO: implement for mixed???
        throw(ErrorException("Description for `:$(modality_dim)` dimensionality modality not implemented"))
    elseif modality_dim == 0
        return DF.describe(modality(md, i))
    else
        desc = haskey(kwargs, :desc) ? kwargs[:desc] : auto_desc_by_dim[modality_dim]
        return describeonm(modality(md, i); desc = desc, kwargs...)
    end
end

function _stat_description(
	df::AbstractDataFrame;
	functions::AbstractVector{Function} = [var, std],
	cols::AbstractVector{<:Integer} = collect(2:ncol(df))
)
	for col in eachcol(df)[cols]
		@assert eltype(col) <: AbstractArray "`df` is not a description DataFrame"
	end

	function apply_func_2_col(func::Function)
		return cat(
			[Symbol(names(df)[c] * "_" * string(nameof(func))) =>
			[[func(r[:,chunk]) for chunk in 1:size(r, 2)] for r in df[:,c]] for c in cols]...;
			dims = 1
		)
	end

	total_cols = length(functions)*length(cols)
	order = cat([collect(i:length(cols):total_cols) for i in 1:length(cols)]...; dims = 1)
	gen_cols = cat([apply_func_2_col(f) for f in functions]...; dims = 1)

	return DataFrame(:VARIABLE => df[:,1], gen_cols[order]...)
end
