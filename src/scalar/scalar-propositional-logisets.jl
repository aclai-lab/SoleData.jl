using Lazy
using Tables
using Tables: DataAPI
using SoleLogics: LogicalInstance
import SoleLogics: interpret
############################################################################################

struct PropositionalLogiset{T} <: AbstractPropositionalLogiset
    dataset::T

    function PropositionalLogiset(dataset::T) where {T}
        if Tables.istable(dataset)
            # TODO: eltype(dataset)<:Real
            # eltype.(eachcol(SoleData.gettable(X)))
            @assert all(t->t<:Real, eltype.(Tables.columns(dataset))) "Could not " *
                "initialize PropositionalLogiset with non-real values: " *
                "$(Union{eltype.(Tables.columns(dataset))...})"
            new{T}(dataset)
        else
            error("Table interface not implemented for $(typeof(dataset)) type")
        end
    end
end

gettable(M::PropositionalLogiset) = M.dataset

Tables.istable(::Type{<:PropositionalLogiset}) = true
Tables.rowaccess(::Type{PropositionalLogiset{T}}) where {T} = Tables.rowaccess(T)
Tables.columnaccess(::Type{PropositionalLogiset{T}}) where {T} = Tables.columnaccess(T)
Tables.materializer(::Type{PropositionalLogiset{T}}) where {T} = Tables.materializer(T)
# Tables.rows(X::PropositionalLogiset{T}) where {T} = Tables.rows(gettable(X))
# Tables.columns(X::PropositionalLogiset{T}) where {T} = Tables.columns(gettable(X))

# Helpers
@forward PropositionalLogiset.dataset (Base.getindex, Base.setindex!)
@forward PropositionalLogiset.dataset (Tables.rows, Tables.columns, Tables.subset, Tables.schema, DataAPI.nrow, DataAPI.ncol)

ninstances(X::PropositionalLogiset) = DataAPI.nrow(gettable(X))
nfeatures(X::PropositionalLogiset) = DataAPI.ncol(gettable(X))
nvariables(X::PropositionalLogiset) = nfeatures(X)

# TODO rename to `features` to adhere to interface (see src/logiset.jl)
function getfeatures(X::PropositionalLogiset)
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
    if include_nfeatures
        push!(pieces, "$(padattribute("# features:", nfeatures(X)))")
    end
    push!(pieces, "Table: $(gettable(X))")
    return "$(nameof(typeof(X))) ($(humansize(X)))" *
        join(pieces, "\n$(indent_str)├ ", "\n$(indent_str)└ ")
end

# Patch getindex so that vector-based slicings return PropositionalLogisets ;)
function Base.getindex(X::PropositionalLogiset, rows::Union{Colon,AbstractVector}, cols::Union{Colon,AbstractVector})
    return (Base.getindex(gettable(X), rows, cols) |> PropositionalLogiset)
    # return X[:, col][row]
end

# TODO optimize...?
function alphabet( 
    X::PropositionalLogiset,
    test_operators::AbstractVector{<:T} # TODO is it okay to receive test_operators as second argument? What's the interface for this `alphabet` function?
)::BoundedScalarConditions where {T<:TestOperator}

    scalarmetaconds = ScalarMetaCondition[]
    features = getfeatures(X)
    map(test_op -> append!(scalarmetaconds, ScalarMetaCondition.(features,  test_op)), test_operators)
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

    colname = varname(cond_feature)
    return cond_operator(i.s[i.i_instance,colname], cond_threshold) ? ⊤ : ⊥   
     
end
