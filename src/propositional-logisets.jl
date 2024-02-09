using SoleLogics: AbstractAssignment
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

function getfeatures(M::PropositionalLogiset)
    colnames = columnnames(gettable(M))
    return UnivariateSymbolFeature.(Symbol.(colnames))
end


# A retrieved column is a 1-based indexable object that has a known
# length, i.e. supports length(col) and col[i].
# Note that if x is an object in which columns are stored as vectors, the 
# check that these vectors use 1-based indexing is not performed (it 
# should be ensured when x is constructed).
# function Base.getindex(X::PropositionalLogiset, ::Colon, col::Symbol)
#     return columns(X.dataset)[col]
# end
# function Base.getindex(X::PropositionalLogiset, row::Int64, col::Symbol)
#     return X.dataset[row,col]
# end



# TODO ok ? 
function alphabetlogiset(P::PropositionalLogiset)
    conditions = getconditionset(P, [≤, ≥])
    return atoms.(conditions)
end

function interpret(
    φ::Atom,
    i::SoleLogics.LogicalInstance{<:PropositionalLogiset},
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
