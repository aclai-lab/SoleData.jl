
# -------------------------------------------------------------
# AbstractMultiFrameDataset - schema

function ST.schema(mfd::AbstractMultiFrameDataset; kwargs...)
    results = ST.Schema[]
    for frame in mfd
        push!(results, ST.schema(frame, kwargs...))
    end

    return results
end
function ST.schema(mfd::AbstractMultiFrameDataset, i::Integer; kwargs...)
    ST.schema(frame(mfd, i); kwargs...)
end
