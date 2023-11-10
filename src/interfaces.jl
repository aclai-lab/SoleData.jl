using ScientificTypes

function ScientificTypes.schema(md::AbstractMultiModalDataset, i::Integer; kwargs...)
    ScientificTypes.schema(modality(md, i); kwargs...)
end


using Tables

Tables.istable(X::AbstractMultiModalDataset) = true
Tables.rowaccess(X::AbstractMultiModalDataset) = true

function Tables.rows(X::AbstractMultiModalDataset)
    eachinstance(X)
end

function Tables.subset(X::AbstractMultiModalDataset, inds; viewhint = nothing)
    slicedataset(X, inds; return_view = (isnothing(viewhint) || viewhint == true))
end

function _columntruenames(row::Tuple{AbstractMultiModalDataset,Integer})
    multilogiset, i_row = row
    return [(i_mod, i_feature) for i_mod in 1:nmodalities(multilogiset) for i_feature in Tables.columnnames((modality(multilogiset, i_mod), i_row),)]
end

function Tables.getcolumn(row::Tuple{AbstractMultiModalDataset,Integer}, i::Int)
    multilogiset, i_row = row
    (i_mod, i_feature) = _columntruenames(row)[i] # Ugly and not optimal. Perhaps AbstractMultiModalDataset should have an index attached to speed this up
    m = modality(multilogiset, i_mod)
    feats, featchs = Tables.getcolumn((m, i_row), i_feature)
    featchs
end

function Tables.columnnames(row::Tuple{AbstractMultiModalDataset,Integer})
    # [(i_mod, i_feature) for i_mod in 1:nmodalities(multilogiset) for i_feature in Tables.columnnames((modality(multilogiset, i_mod), i_row),)]
    1:length(_columntruenames(row))
end


using MLJModelInterface: Table
import MLJModelInterface: selectrows, nrows

function nrows(X::AbstractMultiModalDataset)
    collect(Tables.rows(X))
end

function selectrows(X::AbstractMultiModalDataset, r)
    r = r isa Integer ? (r:r) : r
    return Tables.subset(X, r)
end

# function scitype(X::AbstractMultiModalDataset)
#     Table{
#         if featvaltype(X) <: AbstractFloat
#             scitype(1.0)
#         elseif featvaltype(X) <: Integer
#             scitype(1)
#         elseif featvaltype(X) <: Bool
#             scitype(true)
#         else
#             @warn "Unexpected featvaltype: $(featvaltype(X)). SoleModels may need adjustments."
#             typejoin(scitype(1.0), scitype(1), scitype(true))
#         end
#     }
# end
