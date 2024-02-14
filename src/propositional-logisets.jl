using SoleLogics: AbstractAssignment, LogicalInstance
import SoleLogics: interpret

############################################################################################

abstract type AbstractPropositionalLogiset <: AbstractLogiset{AbstractAssignment} end

struct PropositionalLogiset{T} <: AbstractPropositionalLogiset
    dataset::T

    function PropositionalLogiset(dataset::T) where {T}
        if istable(dataset)
            # TODO: eltype(dataset)<:Real
            new{T}(dataset)
        else
            error("Table interface not implemented for $(typeof(dataset)) type")
        end
    end
end

ninstances(X::PropositionalLogiset) = nrow(X.dataset)
nvariables(X::PropositionalLogiset) = ncol(X.dataset)
gettable(M::PropositionalLogiset) = M.dataset

function getfeatures(X::PropositionalLogiset)
    colnames = columnnames(gettable(X))
    return UnivariateSymbolFeature.(Symbol.(colnames))
end

function displaystructure(X::PropositionalLogiset)
    X.dataset
end

# TODO correct ? 
function Base.getindex(X::PropositionalLogiset, ::Colon, col::Symbol)
    return getcolumn(X.dataset, col)
end
function Base.getindex(X::PropositionalLogiset, row::Int64, col::Symbol)
    return X[:, col][row]
end

# TODO correct? 
function alphabet( 
    pl::PropositionalLogiset, 
    test_operators
)::BoundedScalarConditions

    scalarmetaconds = []
    features = getfeatures(pl)
    map(test_op -> append!(scalarmetaconds, ScalarMetaCondition.(features,  test_op)),   test_operators) 
    boundedscalarconds = BoundedScalarConditions{ScalarCondition}(
        map( i -> ( scalarmetaconds[i], pl[:, varname(feature(scalarmetaconds[i]))] ), 1:length(scalarmetaconds))
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