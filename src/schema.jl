
# -------------------------------------------------------------
# AbstractMultiModalDataset - schema

function ScientificTypes.schema(md::AbstractMultiModalDataset; kwargs...)
    results = ScientificTypes.Schema[]
    for modality in md
        push!(results, ScientificTypes.schema(modality, kwargs...))
    end

    return results
end
function ScientificTypes.schema(md::AbstractMultiModalDataset, i::Integer; kwargs...)
    ScientificTypes.schema(modality(md, i); kwargs...)
end
