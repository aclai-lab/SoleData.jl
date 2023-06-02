
# -------------------------------------------------------------
# AbstractMultiModalDataset - set operations

function in(instance::DataFrameRow, md::AbstractMultiModalDataset)
    return instance in eachrow(data(md))
end
function in(instance::AbstractVector, md::AbstractMultiModalDataset)
    if nvariables(md) != length(instance)
        return false
    end

    dfr = eachrow(DataFrame([var_name => instance[i]
        for (i, var_name) in Symbol.(names(data(md)))]))[1]

    return dfr in eachrow(data(md))
end

function issubset(instances::AbstractDataFrame, md::AbstractMultiModalDataset)
    for dfr in eachrow(instances)
        if !(dfr in md)
            return false
        end
    end

    return true
end
function issubset(md1::AbstractMultiModalDataset, md2::AbstractMultiModalDataset)
    return md1 ≈ md2 && data(md1) ⊆ md2
end

function setdiff(md1::AbstractMultiModalDataset, md2::AbstractMultiModalDataset)
    # TODO: implement setdiff
    throw(Exception("Not implemented"))
end
function setdiff!(md1::AbstractMultiModalDataset, md2::AbstractMultiModalDataset)
    # TODO: implement setdiff!
    throw(Exception("Not implemented"))
end
function intersect(md1::AbstractMultiModalDataset, md2::AbstractMultiModalDataset)
    # TODO: implement intersect
    throw(Exception("Not implemented"))
end
function intersect!(md1::AbstractMultiModalDataset, md2::AbstractMultiModalDataset)
    # TODO: implement intersect!
    throw(Exception("Not implemented"))
end
function union(md1::AbstractMultiModalDataset, md2::AbstractMultiModalDataset)
    # TODO: implement union
    throw(Exception("Not implemented"))
end
function union!(md1::AbstractMultiModalDataset, md2::AbstractMultiModalDataset)
    # TODO: implement union!
    throw(Exception("Not implemented"))
end
