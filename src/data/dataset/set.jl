
# -------------------------------------------------------------
# AbstractMultiFrameDataset - set operations

function in(instance::DataFrameRow, mfd::AbstractMultiFrameDataset)
    return instance in eachrow(data(mfd))
end
function in(instance::AbstractVector, mfd::AbstractMultiFrameDataset)
    if nattributes(mfd) != length(instance)
        return false
    end

    dfr = eachrow(DataFrame([attr_name => instance[i]
        for (i, attr_name) in Symbol.(names(data(mfd)))]))[1]

    return dfr in eachrow(data(mfd))
end

function issubset(instances::AbstractDataFrame, mfd::AbstractMultiFrameDataset)
    for dfr in eachrow(instances)
        if !(dfr in mfd)
            return false
        end
    end

    return true
end
function issubset(mfd1::AbstractMultiFrameDataset, mfd2::AbstractMultiFrameDataset)
    return mfd1 ≈ mfd2 && data(mfd1) ⊆ mfd2
end

function setdiff(mfd1::AbstractMultiFrameDataset, mfd2::AbstractMultiFrameDataset)
    # TODO: implement setdiff
    throw(Exception("Not implemented"))
end
function setdiff!(mfd1::AbstractMultiFrameDataset, mfd2::AbstractMultiFrameDataset)
    # TODO: implement setdiff!
    throw(Exception("Not implemented"))
end
function intersect(mfd1::AbstractMultiFrameDataset, mfd2::AbstractMultiFrameDataset)
    # TODO: implement intersect
    throw(Exception("Not implemented"))
end
function intersect!(mfd1::AbstractMultiFrameDataset, mfd2::AbstractMultiFrameDataset)
    # TODO: implement intersect!
    throw(Exception("Not implemented"))
end
function union(mfd1::AbstractMultiFrameDataset, mfd2::AbstractMultiFrameDataset)
    # TODO: implement union
    throw(Exception("Not implemented"))
end
function union!(mfd1::AbstractMultiFrameDataset, mfd2::AbstractMultiFrameDataset)
    # TODO: implement union!
    throw(Exception("Not implemented"))
end
