
# -------------------------------------------------------------
# AbstractMultiFrameDataset - describe

const desc_dict = Dict{Symbol,Function}(
    :mean_m => mean,
    :min_m => minimum,
    :max_m => maximum,
    # allow catch22 desc
    (getnames(catch22) .=> catch22)...
)

function _describeonm(
    df::AbstractDataFrame;
    descfunction::Function,
    cols::AbstractVector{<:Integer} = 1:ncol(df),
    t::AbstractVector{<:Tuple{Integer,Integer,Integer}},
    kwargs...
)
    x = Matrix{AbstractFloat}[]

    for j in cols
        y = Matrix{AbstractFloat}(undef, nrow(df), t[1][1])
        for (i, paa_result) in enumerate(paa.(df[:,j]; f=descfunction ,decdigits=4, t=t))
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
    t::AbstractVector{<:Tuple{Integer,Integer,Integer}},
    kwargs...
)

    data = DataFrame()
    data.variable = propertynames(df)

    for d in desc
        data = insertcols!(data, ncol(data)+1, d => _describeonm(df; descfunction = desc_dict[d], t))
    end

    return data
end

# TODO: same as above
function DF.describe(
    mfd::AbstractMultiFrameDataset;
    desc::AbstractVector{Symbol} = Symbol[],
    t::AbstractVector{<:Tuple{Integer,Integer,Integer}} = [(1,0,0)],
    kwargs...
)
    # TODO: make this assertions support Symbols from original `describe`
    # for f in desc
    #     @assert haskey(desc_dict, f) "Func not found"
    # end

    results = DataFrame[]

    for frame in mfd
        push!(results, describeonm(frame; desc, t, kwargs...))
    end

    return results
end

# TODO: implement this
# function DF.describe(mfd::MultiFrameDataset, stats::Union{Synbol, Pair}...; cols=:)
#     # TODO: select proper defaults stats based on `dimension` of each frame
# end

function DF.describe(mfd::AbstractMultiFrameDataset, i::Integer; kwargs...)
    DF.describe(frame(mfd, i), kwargs...)
end
