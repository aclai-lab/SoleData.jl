using Lazy
using Tables
using Tables: DataAPI
using SoleLogics: LogicalInstance
using CategoricalArrays: CategoricalValue
import SoleLogics: interpret
import SoleData: UnivariateSymbolValue, UnivariateValue, featvalue


include("discretization.jl")

############################################################################################

using SoleLogics: AbstractAssignment
abstract type AbstractPropositionalLogiset <: AbstractLogiset{AbstractAssignment} end

############################################################################################

# TODO Add NaN checks.
# TODOO @Edo Add examples to docstring, showing different ways of slicing it.
"""
    PropositionalLogiset(table)
A logiset of propositional interpretations, wrapping a [Tables](https://github.com/JuliaData/Tables.jl)'
table of real/string/categorical values.

# Examples

This structure can be used to check propositional formulas:
```julia
using SoleData, MLJBase

X = PropositionalLogiset(MLJBase.load_iris())

φ = parseformula(
    "sepal_length > 5.8 ∧ sepal_width < 3.0 ∨ target == \"setosa\"";
    atom_parser = a->Atom(parsecondition(SoleData.ScalarCondition, a; featuretype = SoleData.UnivariateSymbolValue))
)

check(φ, X) # Check the formula on the whole dataset

check(φ, X, 10) # Check the formula on a single instance
```

See also
[`AbstractLogiset`](@ref),
[`AbstractAssignment`](@ref).
"""
struct PropositionalLogiset{T} <: AbstractPropositionalLogiset
    tabulardataset::T

    function PropositionalLogiset(tabulardataset::T; allow_no_instances = true) where {T}
        if Tables.istable(tabulardataset)
            # @assert !allow_no_instances && DataAPI.nrow(tabulardataset)>0 "Could not initialize "*
            #     "PropositionalLogiset with a table with no rows."
            @assert all(t->t<:Union{Real,AbstractString,CategoricalValue}, eltype.(collect(Tables.columns(tabulardataset)))) "" *
                "Unexpected eltypes for some columns. `Union{Real,AbstractString,CategoricalValue}` is expected, but " *
                "`$(Union{eltype.(collect(Tables.columns(tabulardataset)))...})`" *
                "encountered."
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

# Helpers
@forward PropositionalLogiset.tabulardataset (Base.setindex!)
@forward PropositionalLogiset.tabulardataset (Tables.rows, Tables.columns, Tables.subset, Tables.schema, DataAPI.nrow, DataAPI.ncol)
@forward PropositionalLogiset.tabulardataset (Tables.getcolumns,)

ninstances(X::PropositionalLogiset) = DataAPI.nrow(gettable(X))
nfeatures(X::PropositionalLogiset) = DataAPI.ncol(gettable(X))
nvariables(X::PropositionalLogiset) = nfeatures(X)

function features(X::PropositionalLogiset)
    colnames = Tables.columnnames(gettable(X))
    return UnivariateSymbolValue.(Symbol.(colnames))
end

function featvalue(
    f::UnivariateSymbolValue,
    X::PropositionalLogiset,
    i_instance::Integer,
    args...
)
    X[i_instance, varname(f)]
end

function featvalue(
    f::UnivariateValue,
    X::PropositionalLogiset,
    i_instance::Integer,
    args...
)
    X[i_instance, f.i_variable]
end

function Base.show(io::IO, X::PropositionalLogiset; kwargs...)
    println(io, displaystructure(X; kwargs...))
end

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
#     # return Tables.getcolumn(gettable(X), col)[row]
# end

function instances(
    X::PropositionalLogiset,
    inds::AbstractVector{<:Integer},
    return_view::Union{Val{true},Val{false}} = Val(false)
)
    return PropositionalLogiset(if return_view == Val(true)
        Tables.subset(gettable(X), inds; viewhint = true)
    else
        Tables.subset(gettable(X), inds; viewhint = false)
    end)
end

function Base.getindex(X::PropositionalLogiset, rows::Union{Colon}, cols::Union{Colon})
    __getindex(X, rows, cols)
end
function Base.getindex(X::PropositionalLogiset, rows::Union{Colon}, cols::Union{AbstractVector})
    __getindex(X, rows, cols)
end
function Base.getindex(X::PropositionalLogiset, rows::Union{AbstractVector}, cols::Union{Colon})
    __getindex(X, rows, cols)
end
function Base.getindex(X::PropositionalLogiset, rows::Union{AbstractVector}, cols::Union{AbstractVector})
    __getindex(X, rows, cols)
end
function __getindex(X::PropositionalLogiset, rows::Union{Colon,AbstractVector}, cols::Union{Colon,AbstractVector})
    if Tables.columnaccess(X)
        coliter = Tables.columns(gettable(X))[cols]
        return (Tables.rows(coliter)[rows] |> PropositionalLogiset)
    else
        rowiter = Tables.rows(gettable(X))[rows]
        return (Tables.columns(rowiter)[cols] |> PropositionalLogiset)
    end
end

function Base.getindex(X::PropositionalLogiset, args...)
    Base.getindex(gettable(X), args...)
end

function Base.getindex(X::PropositionalLogiset, row::Integer, col::Union{Integer,Symbol})
    return Tables.getcolumn(gettable(X), col)[row]
end

# TODO @Edo: add thorough description of this function
# TODO: @test_nowarn alphabet(X, false)
# TODO: @test_broken alphabet(X, false; skipextremes = true)
# TODO skipextremes: note that for non-strict operators, the first atom has no entropy; for strict operators, the last has undefined entropy. Add parameter that skips those.
function alphabet(
    X::PropositionalLogiset,
    sorted = true;
    test_operators::Union{Nothing,AbstractVector{<:TestOperator},Base.Callable} = nothing,
    truerfirst::Bool = false,
    skipextremes::Bool = true,
    discretizedomain::Bool = false,
    y::Union{Nothing, AbstractVector} = nothing,
)::UnionAlphabet{ScalarCondition,UnivariateScalarAlphabet}
    get_test_operators(::Nothing, ::Type{<:Any}) = [(==), (≠)]
    get_test_operators(::Nothing, ::Type{<:Number}) = [≤, ≥]
    get_test_operators(v::AbstractVector, ::Type{<:Any}) = v
    get_test_operators(f::Base.Callable, t::Type{<:Any}) = f(t)

    coltypes = eltype.(collect(Tables.columns(gettable(X))))
    colnames = Tables.columnnames(gettable(X)) # features(X)
    feats = UnivariateSymbolValue.(Symbol.(colnames))
    # scalarmetaconds = map(((feat, test_op),) -> ScalarMetaCondition(feat, test_op), Iterators.product(feats, test_operators))
    scalarmetaconds = (ScalarMetaCondition(feat, test_op) for (feat,coltype) in zip(feats,coltypes) for test_op in get_test_operators(test_operators, coltype))

    # TODO @Edo. Optimization opportunity, since for ≤ and ≥ the same thresholds are computed!
    sas = map(mc ->begin
            feat = feature(mc)
            Xcol_values = Tables.getcolumn(gettable(X), varname(feat))
            if isordered(test_operator(mc))
                if discretizedomain
                    @assert !isnothing(y) "Please, provide `y` keyword argument to apply Fayyad's discretization algorithm."
                    thresholds = discretize(Xcol_values, y)
                else
                    thresholds = unique(Xcol_values)
                    sorted && (thresholds = sort(thresholds,
                                rev=(truerfirst & (polarity(test_operator(mc)) == false))
                        ))
                end
            # Categorical values
            else
                thresholds = unique(Xcol_values)
            end
            UnivariateScalarAlphabet((mc, thresholds))
        end, scalarmetaconds)
    return UnionAlphabet(sas)

end

# Note that this method is important and very fast!
function check(
    φ::Atom{<:ScalarCondition},
    X::PropositionalLogiset;
    _fastmath = Val(true), # TODO warning!!!
    kwargs...,
)::BitVector

    cond = SoleLogics.value(φ)

    cond_threshold = threshold(cond)
    cond_operator = test_operator(cond)
    cond_feature = feature(cond)

    col = varname(cond_feature)
    if _fastmath == Val(true)
        return @fastmath cond_operator.(Tables.getcolumn(gettable(X), col), cond_threshold)
    else
        return cond_operator.(Tables.getcolumn(gettable(X), col), cond_threshold)
    end
end

function check(
    φ::Atom{<:ScalarCondition},
    i::LogicalInstance{<:PropositionalLogiset},
    args...;
    kwargs...,
)::Bool
    @warn "Attempting single-instance check. This is not optimal."
    X, i_instance = SoleLogics.splat(i)
    cond = SoleLogics.value(φ)

    cond_threshold = threshold(cond)
    cond_operator = test_operator(cond)
    cond_feature = feature(cond)

    col = varname(cond_feature)
    return cond_operator(X[i_instance, col], cond_threshold)
end

# Note that this method is important and very fast!
function check(
    φ::Atom{<:ObliqueScalarCondition},
    X::PropositionalLogiset;
    _fastmath = Val(true), # TODO warning!!!
    kwargs...
)::BitVector

    cond = SoleLogics.value(φ)

    testop = test_operator(cond)
    # TODO: features
    p, n = cond.b, cond.u
    return testop.(((Tables.matrix(gettable(X)) .- p') * n), 0)
end

function check(
    φ::Atom{<:ObliqueScalarCondition},
    i::LogicalInstance{<:PropositionalLogiset},
    args...;
    kwargs...
)::Bool
    @warn "Attempting single-instance check. This is not optimal."
    X, i_instance = SoleLogics.splat(i)
    cond = SoleLogics.value(φ)
    
    testop = test_operator(cond)
    # TODO: features
    p, n = cond.b, cond.u
    return testop(dot(([col[i_instance] for col in Tables.columns(X)] .- p), n), 0)
end


# function check(
#     φ::Atom{<:AbstractCondition},
#     i::LogicalInstance{<:PropositionalLogiset},
#     args...;
#     kwargs...
# )
#     return checkcondition(SoleLogics.value(φ), i, args...; kwargs...)
# end

# Note: differently from other parts of the framework, where the opposite is true,
#  here `interpret` depends on `check`,
function interpret(
    φ::Atom{<:Union{ScalarCondition,ObliqueScalarCondition}},
    i::LogicalInstance{<:PropositionalLogiset},
    args...;
    kwargs...,
)::Formula
    return check(φ, i, args...; kwargs...) ? ⊤ : ⊥
end
