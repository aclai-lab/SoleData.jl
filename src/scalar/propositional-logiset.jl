using Lazy
using Tables
using Tables: DataAPI
using SoleLogics: LogicalInstance
using CategoricalArrays: CategoricalValue
import SoleLogics: interpret
import SoleData: VariableValue, featvalue
using SoleLogics: AbstractAssignment

include("discretization/fayyad.jl")

############################################################################################

"""
    PropositionalLogiset(table) <: AbstractPropositionalLogiset

A logiset of propositional interpretations, wrapping a [Tables](https://github.com/JuliaData/Tables.jl)'
table of real/string/categorical values.

# Examples

This structure can be used to check propositional formulas:
```julia
using SoleData, MLJBase

X = PropositionalLogiset(MLJBase.load_iris())

φ = parseformula(
    "sepal_length > 5.8 ∧ sepal_width < 3.0 ∨ target == \"setosa\"";
    atom_parser = a->Atom(parsecondition(SoleData.ScalarCondition, a; featuretype = SoleData.VariableValue))
)

check(φ, X, 10) # Check the formula on a single instance

satmask = check(φ, X) # Check the formula on the whole dataset

slicedataset(X, satmask)
slicedataset(X, (!).(satmask))
```

See also
[`AbstractLogiset`](@ref),
[`AbstractAssignment`](@ref).
"""
struct PropositionalLogiset{T} <: AbstractPropositionalLogiset
    tabulardataset::T

    function PropositionalLogiset(tabulardataset::T) where {T}
        if Tables.istable(tabulardataset)
            @assert all(
                t->t<:Union{Real,AbstractString,CategoricalValue},
                eltype.(collect(Tables.columns(tabulardataset))),
            ) "" *
                "Unexpected eltypes for some columns. `Union{Real,AbstractString,CategoricalValue}` is expected, but " *
                "`$(Union{eltype.(collect(Tables.columns(tabulardataset)))...})` " *
                "encountered."
            new{T}(tabulardataset)
        else
            error("Table interface not implemented for $(typeof(tabulardataset)) type")
        end
    end

    function PropositionalLogiset(l::PropositionalLogiset)
        return l
    end
end

gettable(M::PropositionalLogiset) = M.tabulardataset

Tables.istable(::Type{<:PropositionalLogiset}) = true
Tables.rowaccess(::Type{PropositionalLogiset{T}}) where {T} = Tables.rowaccess(T)
Tables.columnaccess(::Type{PropositionalLogiset{T}}) where {T} = Tables.columnaccess(T)
Tables.materializer(::Type{PropositionalLogiset{T}}) where {T} = Tables.materializer(T)

# Helpers
@forward PropositionalLogiset.tabulardataset (Base.setindex!)
@forward PropositionalLogiset.tabulardataset (
    Tables.rows, Tables.columns, Tables.subset, Tables.schema, DataAPI.nrow, DataAPI.ncol
)
@forward PropositionalLogiset.tabulardataset (Tables.getcolumns,)

ninstances(X::PropositionalLogiset) = DataAPI.nrow(gettable(X))
nfeatures(X::PropositionalLogiset) = DataAPI.ncol(gettable(X))
nvariables(X::PropositionalLogiset) = nfeatures(X)

function features(X::PropositionalLogiset; force_i_variables::Bool=false)
    if force_i_variables
        return VariableValue.(1:nfeatures(X))
    else
        colnames = Tables.columnnames(gettable(X))
        return VariableValue.(Symbol.(colnames))
    end
end

function featvalue(f::VariableValue, X::PropositionalLogiset, i_instance::Integer, args...)
    X[i_instance, i_variable(f)]
end

function Base.show(io::IO, X::PropositionalLogiset; kwargs...)
    println(io, displaystructure(X; kwargs...))
end

function displaystructure(
    X::PropositionalLogiset;
    indent_str="",
    include_ninstances=true,
    include_nfeatures=true,
    include_features=false,
    include_worldtype=missing,
    include_featvaltype=missing,
    include_featuretype=missing,
    include_frametype=missing,
)
    padattribute(l, r) =
        string(l) * lpad(r, 32+length(string(r))-(length(indent_str)+2+length(l)))
    pieces = []
    push!(pieces, "")

    if include_ninstances
        push!(pieces, "$(padattribute("# instances:", ninstances(X)))")
    end
    if !include_features && include_nfeatures
        push!(pieces, "$(padattribute("# features:", nfeatures(X)))")
    end
    if include_features
        push!(
            pieces,
            "$(padattribute("features:", "$(nfeatures(X)) -> $(SoleLogics.displaysyntaxvector(features(X); quotes = false))"))",
        )
    end
    push!(pieces, "Table: $(gettable(X))")
    return "$(nameof(typeof(X))) ($(humansize(X)))" *
           join(pieces, "\n$(indent_str)├ ", "\n$(indent_str)└ ")
end

# Patch getindex so that vector-based slicings return PropositionalLogisets ;)
# function Base.getindex(X::PropositionalLogiset, rows::Union{Colon,AbstractVector}, cols::Union{Colon,AbstractVector})
#     return (Base.getindex(gettable(X), rows, cols) |> PropositionalLogiset)
#     # return Tables.getcolumn(gettable(X), col)[row]
# end

function instances(
    X::PropositionalLogiset,
    inds::AbstractVector,
    return_view::Union{Val{true},Val{false}}=Val(false),
)
    return PropositionalLogiset(
        if return_view == Val(true)
            Tables.subset(gettable(X), inds; viewhint=true)
        else
            Tables.subset(gettable(X), inds; viewhint=false)
        end,
    )
end

function Base.getindex(X::PropositionalLogiset, rows::Union{Colon}, cols::Union{Colon})
    __getindex(X, rows, cols)
end
function Base.getindex(
    X::PropositionalLogiset, rows::Union{Colon}, cols::Union{AbstractVector}
)
    __getindex(X, rows, cols)
end
function Base.getindex(
    X::PropositionalLogiset, rows::Union{AbstractVector}, cols::Union{Colon}
)
    __getindex(X, rows, cols)
end
function Base.getindex(
    X::PropositionalLogiset, rows::Union{AbstractVector}, cols::Union{AbstractVector}
)
    __getindex(X, rows, cols)
end
function __getindex(
    X::PropositionalLogiset,
    rows::Union{Colon,AbstractVector},
    cols::Union{Colon,AbstractVector},
)
    if Tables.columnaccess(X)
        coliter = Tables.columns(gettable(X))[cols]
        return (PropositionalLogiset(Tables.rows(coliter)[rows]))
    else
        rowiter = Tables.rows(gettable(X))[rows]
        return (PropositionalLogiset(Tables.columns(rowiter)[cols]))
    end
end

function Base.getindex(X::PropositionalLogiset, args...)
    Base.getindex(gettable(X), args...)
end

function Base.getindex(X::PropositionalLogiset, row::Integer, col::Union{Integer,Symbol})
    return Tables.getcolumn(gettable(X), col)[row]
end

function frame(dataset::PropositionalLogiset, i_instance::Integer)
    return OneWorld()
end

# TODO: @test_broken alphabet(X, false; skipextremes = true)
# TODO skipextremes: note that for non-strict operators, the first atom has no entropy; for strict operators, the last has undefined entropy. Add parameter that skips those.
# TODO join discretize and y parameter into a single parameter.

"""
    alphabet(
        X::PropositionalLogiset,
        sorted=true;
        test_operators::Union{Nothing,AbstractVector{<:TestOperator},Base.Callable}=nothing,
        discretizedomain=false,
        y::Union{Nothing, AbstractVector}=nothing,
    )::MultivariateScalarAlphabet

Constructs an alphabet based on the provided `PropositionalLogiset` `X`, with optional parameters:
- `sorted`: whether to sort the atoms in the sub-alphabets (i.e., the threshold domains),
    by a truer-first policy (default: true)
- `test_operators`: test operators to use (defaulted to `[≤, ≥]` for real-valued features, and `[(==), (≠)]` for other features, e.g., categorical)
- `discretizedomain`: whether to discretize the domain (default: false)
- `y`: vector used for discretization (required if `discretizedomain` is true)

Returns a `UnionAlphabet` containing `ScalarCondition` and `UnivariateScalarAlphabet`.
"""
function alphabet(
    X::PropositionalLogiset,
    sorted=true;
    force_i_variables::Bool=false,
    test_operators::Union{Nothing,AbstractVector{<:TestOperator},Base.Callable}=nothing,
    discretizedomain::Bool=false,
    unique::Bool=false,
    kwargs...,
)::MultivariateScalarAlphabet
    feats = collect(features(X; force_i_variables=force_i_variables))
    coltypes = eltype.(collect(Tables.columns(gettable(X)))) # TODO could this be inferred from the features
    # scalarmetaconds = map(((feat, test_op),) -> ScalarMetaCondition(feat, test_op), Iterators.product(feats, test_operators))

    domains = [
        begin
            domain = Tables.getcolumn(gettable(X), i_variable(feat))
            if unique && !discretizedomain
                domain = unique(domain)
            end
            domain
        end for feat in feats
    ]

    get_test_operators(to, t::Type{<:Any}) = _get_test_operators(Val(to), t)
    get_test_operators(v::AbstractVector, ::Type{<:Any}) = v
    get_test_operators(f::Base.Callable, t::Type{<:Any}) = f(t)
    _get_test_operators(::Val{nothing}, ::Type{<:Number}) = [≤, ≥]
    _get_test_operators(::Val{nothing}, ::Type{<:Any}) = [(==), (≠)]
    _get_test_operators(::Val{:single}, ::Type{<:Number}) = [≤]
    _get_test_operators(::Val{:double}, ::Type{<:Any}) = [(==)]

    testopss = [
        begin
            get_test_operators(test_operators, coltype)
        end for coltype in coltypes
    ]

    _multivariate_scalar_alphabet(
        feats, testopss, domains; sorted, discretizedomain, kwargs...
    )
end

# Note that this method is important and very fast!
function checkcondition(
    cond::ScalarCondition,
    X::PropositionalLogiset;
    _fastmath=Val(true), # TODO warning!!!
    kwargs...,
)::BitVector
    cond_threshold = threshold(cond)
    cond_operator = test_operator(cond)
    cond_feature = feature(cond)

    col = i_variable(cond_feature)
    if _fastmath == Val(true)
        return @fastmath cond_operator.(Tables.getcolumn(gettable(X), col), cond_threshold)
    else
        return cond_operator.(Tables.getcolumn(gettable(X), col), cond_threshold)
    end
end

function checkcondition(
    cond::ScalarCondition, i::LogicalInstance{<:PropositionalLogiset}, args...; kwargs...
)::Bool
    # @warn "Attempting single-instance check. This is not optimal."
    X, i_instance = SoleLogics.splat(i)

    cond_threshold = threshold(cond)
    cond_operator = test_operator(cond)
    cond_feature = feature(cond)

    col = i_variable(cond_feature)
    return cond_operator(X[i_instance, col], cond_threshold)
end

# Note that this method is important and very fast!
function checkcondition(
    cond::ObliqueScalarCondition,
    X::PropositionalLogiset;
    _fastmath=Val(true), # TODO warning!!!
    kwargs...,
)::BitVector
    testop = test_operator(cond)
    # TODO: use features
    p, n = cond.b, cond.u
    return testop.(((Tables.matrix(gettable(X)) .- p') * n), 0)
end

using LinearAlgebra: dot

function checkcondition(
    cond::ObliqueScalarCondition,
    i::LogicalInstance{<:PropositionalLogiset},
    args...;
    kwargs...,
)::Bool
    # @warn "Attempting single-instance check. This is not optimal."
    X, i_instance = SoleLogics.splat(i)

    testop = test_operator(cond)
    # TODO: use features
    p, n = cond.b, cond.u
    return testop(dot(([col[i_instance] for col in Tables.columns(X)] .- p), n), 0)
end
