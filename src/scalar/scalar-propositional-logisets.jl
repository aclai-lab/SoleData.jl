using Lazy
using Tables
using Tables: DataAPI
using SoleLogics: LogicalInstance
import SoleLogics: interpret
############################################################################################

# TODO aggiungere controllo Nan
struct PropositionalLogiset{T} <: AbstractPropositionalLogiset
    tabulardataset::T

    function PropositionalLogiset(tabulardataset::T) where {T}
        if Tables.istable(tabulardataset)
            # TODO: eltype(tabulardataset)<:Real
            # eltype.(eachcol(SoleData.gettable(X)))
            @assert all(t->t<:Real, eltype.(Tables.columns(tabulardataset))) "Could not " *
                "initialize PropositionalLogiset with non-real values: " *
                "$(Union{eltype.(Tables.columns(tabulardataset))...})"
            new{T}(tabulardataset)
        else
            error("Table interface not implemented for $(typeof(tabulardataset)) type")
        end
    end
end


gettable(M::PropositionalLogiset) = M.tabulardataset

Tables.istable(::Type{<:PropositionalLogiset}) = true
Tables.rowaccess(::Type{PropositionalLogiset{T}}) where {T} = Tables.rowaccess(T)
Tables.columnaccess(::Type{PropositionalLogiset{T}}) where {T} = Tables.columnaccess(T)
Tables.materializer(::Type{PropositionalLogiset{T}}) where {T} = Tables.materializer(T)
# Tables.rows(X::PropositionalLogiset{T}) where {T} = Tables.rows(gettable(X))
# Tables.columns(X::PropositionalLogiset{T}) where {T} = Tables.columns(gettable(X))

# Helpers
@forward PropositionalLogiset.tabulardataset (Base.getindex, Base.setindex!)
@forward PropositionalLogiset.tabulardataset (Tables.rows, Tables.columns, Tables.subset, Tables.schema, DataAPI.nrow, DataAPI.ncol)

ninstances(X::PropositionalLogiset) = DataAPI.nrow(gettable(X))
nfeatures(X::PropositionalLogiset) = DataAPI.ncol(gettable(X))
nvariables(X::PropositionalLogiset) = nfeatures(X)

function features(X::PropositionalLogiset)
    colnames = Tables.columnnames(gettable(X))
    return UnivariateSymbolValue.(Symbol.(colnames))
end


# function Base.show(io::IO, X::PropositionalLogiset; kwargs...)
#     println(io, displaystructure(X; kwargs...))
#     println(io, "Table:")
#     println(io, gettable(X))
# end

function displaystructure(X::PropositionalLogiset;
    indent_str = "",
    include_ninstances = true,
    include_nfeatures = true,
    include_features = false,
    include_worldtype = missing,
    include_featvaltype = missing,
    include_featuretype = missing,
    include_frametype = missing,
)
    padattribute(l,r) = string(l) * lpad(r,32+length(string(r))-(length(indent_str)+2+length(l)))
    pieces = []
    push!(pieces, "")

    if include_ninstances
        push!(pieces, "$(padattribute("# instances:", ninstances(X)))")
    end
    if !include_features && include_nfeatures
        push!(pieces, "$(padattribute("# features:", nfeatures(X)))")
    end
    if include_features
        push!(pieces, "$(padattribute("features:", "$(nfeatures(X)) -> $(SoleLogics.displaysyntaxvector(features(X)))"))")
    end
    push!(pieces, "Table: $(gettable(X))")
    return "$(nameof(typeof(X))) ($(humansize(X)))" *
        join(pieces, "\n$(indent_str)├ ", "\n$(indent_str)└ ")
end

# Patch getindex so that vector-based slicings return PropositionalLogisets ;)
# function Base.getindex(X::PropositionalLogiset, rows::Union{Colon,AbstractVector}, cols::Union{Colon,AbstractVector})
#     return (Base.getindex(gettable(X), rows, cols) |> PropositionalLogiset)
#     # return X[:, col][row]
# end

function Base.getindex(X::PropositionalLogiset, i_rows::Union{Colon,AbstractVector}, i_cols::Union{Colon,AbstractVector})
    cols = Tables.columns(gettable(X))[i_cols]
    return (cols[i_rows] |> PropositionalLogiset)
end

function alphabet( 
    X::PropositionalLogiset,
    test_operators::AbstractVector{<:T} # TODO is it okay to receive test_operators as second argument? What's the interface for this `alphabet` function?
)::BoundedScalarConditions where {T<:TestOperator}
    feats = features(X)
    # scalarmetaconds = map(((feat, test_op),) -> ScalarMetaCondition(feat, test_op), Iterators.product(feats, test_operators))
    scalarmetaconds = (ScalarMetaCondition(feat, test_op) for feat in feats for test_op in test_operators)
    boundedscalarconds = BoundedScalarConditions{ScalarCondition}(
        map( mc -> ( mc, X[:, varname(feature(mc))] ), scalarmetaconds)
    )
    return boundedscalarconds
end


function interpret(
    φ::Atom,
    i::LogicalInstance{<:PropositionalLogiset},
    args...;
    kwargs...,
)::Formula

    cond = value(φ)

    cond_threshold = threshold(cond)
    cond_operator = test_operator(cond)
    cond_feature = feature(cond)

    col = varname(cond_feature)
    X, i_instance = SoleLogics.splat(i)
    return cond_operator(X[i_instance ,col],  cond_threshold) ? ⊤ : ⊥   
     
end