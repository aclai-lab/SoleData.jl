using Lazy
using Tables
using Tables: DataAPI
using SoleLogics: LogicalInstance
import SoleLogics: interpret
############################################################################################

# TODO aggiungere controllo Nan
"""
TODO add docstring.
- Si comporta come la table che ha dentro,
- e se accedi a più valori, ritorni PropositionalLogiset
"""
struct PropositionalLogiset{T} <: AbstractPropositionalLogiset
    tabulardataset::T

    function PropositionalLogiset(tabulardataset::T) where {T}
        if Tables.istable(tabulardataset)
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
        push!(pieces, "$(padattribute("features:", "$(nfeatures(X)) -> $(SoleLogics.displaysyntaxvector(features(X); quotes = false))"))")
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

function instances(
    X::PropositionalLogiset,
    inds::AbstractVector{<:Integer},
    return_view::Union{Val{true},Val{false}} = Val(false)
)
    return PropositionalLogiset(if return_view == Val(true) @view X.tabulardataset[inds, :] else X.tabulardataset[inds, :] end)
end

function Base.getindex(X::PropositionalLogiset, rows::Union{Colon,AbstractVector}, cols::Union{Colon,AbstractVector})
    if Tables.columnaccess(X)
        coliter = Tables.columns(gettable(X))[cols]
        return (Tables.rows(coliter)[rows] |> PropositionalLogiset)
    else
        rowiter = Tables.rows(gettable(X))[rows]
        return (Tables.columns(rowiter)[cols] |> PropositionalLogiset)
    end
end

function Base.getindex(X::PropositionalLogiset, row::Integer, col::Union{Integer,Symbol})
    return Tables.getcolumn(Tables.columns(gettable(X)), col)[row]
end


# TODO optimize...?
function alphabet(
    X::PropositionalLogiset;
    # TODO is it okay to receive test_operators as second argument? What's the interface for this `alphabet` function?
    test_operators::Union{Nothing,AbstractVector{<:T},Base.Callable} = nothing
)::BoundedScalarConditions where {T<:TestOperator}
    get_test_operators(::Nothing, ::Type{<:Any}) = [(==), (≠)]
    get_test_operators(::Nothing, ::Type{<:Number}) = [≤, ≥]
    get_test_operators(v::AbstractVector, ::Type{<:Any}) = v
    get_test_operators(f::Base.Callable, t::Type{<:Any}) = f(t)

    coltypes = eltype.(Tables.columns(gettable(X)))
    colnames = Tables.columnnames(gettable(X)) # features(X)
    feats = UnivariateSymbolValue.(Symbol.(colnames))
    # scalarmetaconds = map(((feat, test_op),) -> ScalarMetaCondition(feat, test_op), Iterators.product(feats, test_operators))
    scalarmetaconds = (ScalarMetaCondition(feat, test_op) for (feat,coltype) in zip(feats,coltypes) for test_op in get_test_operators(test_operators, coltype))
    boundedscalarconds = BoundedScalarConditions{ScalarCondition}(
         map( mc -> ( mc, sort(unique(X[:, varname(feature(mc))]))), scalarmetaconds)
        )
    return boundedscalarconds
end

function check(
    φ::Atom{<:ScalarCondition},
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
    return cond_operator(X[i_instance, col], cond_threshold)
end

function interpret(
    φ::Atom{<:ScalarCondition},
    i::LogicalInstance{<:PropositionalLogiset},
    args...;
    kwargs...,
)::Formula
    return check(φ, i, args...; kwargs...) ? ⊤ : ⊥
end