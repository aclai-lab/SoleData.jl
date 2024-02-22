using Tables

function eachinstance(X::AbstractModalLogiset)
    map(i_instance->(X,i_instance), 1:ninstances(X))
end

function eachinstance(X::MultiLogiset)
    map(i_instance->(X,i_instance), 1:ninstances(X))
end



function featchannel(
    X::AbstractModalLogiset{W},
    i_instance::Integer,
    i_feature::Integer,
) where {W<:AbstractWorld}
    featchannel(X, i_instance, features(X)[i_feature])
end

function readfeature(
    X::AbstractModalLogiset{W},
    featchannel::Any,
    w::W,
    i_feature::Integer,
) where {W<:AbstractWorld}
    readfeature(X, featchannel, w, features(X)[i_feature])
end


function featvalue(
    X::AbstractModalLogiset{W},
    i_instance::Integer,
    w::W,
    i_feature::Integer,
) where {W<:AbstractWorld}
    featvalue(X, i_instance, w, features(X)[i_feature])
end

function featvalue!(
    X::AbstractModalLogiset{W},
    featval,
    i_instance::Integer,
    w::W,
    i_feature::Integer,
) where {W<:AbstractWorld}
    featvalue(X, featval, i_instance, w, features(X)[i_feature])
end

function featvalues!(
    X::AbstractModalLogiset{W},
    featslice,
    i_feature::Integer,
) where {W<:AbstractWorld}
    featvalues(X, featslice, features(X)[i_feature])
end

Tables.istable(X::AbstractModalLogiset) = true
Tables.istable(X::MultiLogiset) = true

Tables.rowaccess(X::AbstractModalLogiset) = true
Tables.rowaccess(X::MultiLogiset) = true

Tables.rows(X::AbstractModalLogiset) = eachinstance(X)
Tables.rows(X::MultiLogiset) = eachinstance(X)

function Tables.subset(X::AbstractModalLogiset, inds; viewhint = nothing)
    slicedataset(X, inds; return_view = (isnothing(viewhint) || viewhint == true))
end

function Tables.subset(X::MultiLogiset, inds; viewhint = nothing)
    slicedataset(X, inds; return_view = (isnothing(viewhint) || viewhint == true))
end

function Tables.getcolumn(row::Tuple{AbstractModalLogiset,Integer}, i::Int)
    (features(row[1])[i],featchannel(row[1], row[2], i))
end

function Tables.columnnames(row::Tuple{AbstractModalLogiset,Integer})
    1:nfeatures(row[1])
end

function _columntruenames(row::Tuple{MultiLogiset,Integer})
    multilogiset, i_row = row
    return [(i_mod, i_feature) for i_mod in 1:nmodalities(multilogiset) for i_feature in Tables.columnnames((modality(multilogiset, i_mod), i_row),)]
end

function Tables.getcolumn(row::Tuple{MultiLogiset,Integer}, i::Int)
    multilogiset, i_row = row
    (i_mod, i_feature) = _columntruenames(row)[i] # Ugly and not optimal. Perhaps MultiLogiset should have an index attached to speed this up
    m = modality(multilogiset, i_mod)
    feats, featchs = Tables.getcolumn((m, i_row), i_feature)
    featchs
end

function Tables.columnnames(row::Tuple{MultiLogiset,Integer})
    # [(i_mod, i_feature) for i_mod in 1:nmodalities(multilogiset) for i_feature in Tables.columnnames((modality(multilogiset, i_mod), i_row),)]
    1:length(_columntruenames(row))
end

using MLJModelInterface: Table
import MLJModelInterface: selectrows, scitype

function selectrows(X::Union{AbstractModalLogiset,MultiLogiset}, r)
    r = r isa Integer ? (r:r) : r
    # return slicedataset(X, r; return_view = true)
    return Tables.subset(X, r)
end

function scitype(X::Union{AbstractModalLogiset,MultiLogiset})
    Table{
        if featvaltype(X) <: AbstractFloat
            scitype(1.0)
        elseif featvaltype(X) <: Integer
            scitype(1)
        elseif featvaltype(X) <: Bool
            scitype(true)
        else
            @warn "Unexpected featvaltype: $(featvaltype(X)). SoleData may need adjustments."
            typejoin(scitype(1.0), scitype(1), scitype(true))
        end
    }
end

import Base: vcat

Base.vcat(Xs::AbstractModalLogiset...) = concatdatasets(Xs...)
Base.vcat(Xs::MultiLogiset...) = concatdatasets(Xs...)

