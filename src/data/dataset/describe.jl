
# -------------------------------------------------------------
# AbstractMultiFrameDataset - describe

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
    frame_dim = dimension(df)
    @assert length(t) == 1 || length(t) == frame_dim "`t` length has to be `1` or the " *
        "dimension of the frame ($(frame_dim))"

    if frame_dim > 1 && length(t) == 1
        # if dimension is > 1 but only 1 triple is passed use it for all dimensions
        t = fill(t, frame_dim)
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
# describe(df::AbstractDataFrame, stats::Union{Symbol, Pair}...; cols=:)
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
        :Attributes => Symbol.(propertynames(df)),
        [d => _describeonm(df; descfunction = desc_dict[d], t) for d in desc]...
    )
end

# TODO: same as above
function DF.describe(
	mfd::AbstractMultiFrameDataset;
	t::AbstractVector{<:AbstractVector{<:NTuple{3,Integer}}} = fill([(1, 0, 0)], nframes(mfd)),
	kwargs...
)
    return [DF.describe(mfd, i; t = t[i], kwargs...) for i in 1:nframes(mfd)]
end

# TODO: implement this
# function DF.describe(mfd::MultiFrameDataset, stats::Union{Symbol, Pair}...; cols=:)
#     # TODO: select proper defaults stats based on `dimension` of each frame
# end

function DF.describe(mfd::AbstractMultiFrameDataset, i::Integer; kwargs...)
    frame_dim = dimension(frame(mfd, i))
    if frame_dim == :mixed || frame_dim == :empty
        # TODO: implement for mixed???
        throw(ErrorException("Description for `:$(frame_dim)` dimension frame not implemented"))
    elseif frame_dim == 0
        return DF.describe(frame(mfd, i))
    else
        desc = haskey(kwargs, :desc) ? kwargs[:desc] : auto_desc_by_dim[frame_dim]
        return describeonm(frame(mfd, i); desc = desc, kwargs...)
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

	return DataFrame(:ATTRIBUTE => df[:,1], gen_cols[order]...)
end
