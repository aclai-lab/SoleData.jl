using SoleLogics: AbstractKripkeStructure, AbstractAssignment, AbstractInterpretationSet, AbstractFrame, AbstractWorld
using SoleLogics: Truth, LogicalInstance
import SoleLogics: alphabet, frame, check
import SoleLogics: accessibles, allworlds, nworlds
import SoleLogics: worldtype, frametype
import SoleLogics: interpret
import Tables: columnnames, rows, getcolumn, columns


abstract type AbstractLogiset{M} <: AbstractInterpretationSet{M} end
abstract type AbstractPropositionalLogiset <: AbstractLogiset{AbstractAssignment} end

# TODO change from DataFrame to Table
struct PropositionalLogiset <: AbstractPropositionalLogiset
    dataset

    function PropositionalLogiset(dataset)
        if istable(dataset)
            new(dataset)
        else
            error("Table interface not implemented for $(typeof(dataset)) type")
        end
    end
end

ninstances(X::PropositionalLogiset) = nrow(X.dataset)
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
    i::LogicalInstance{<:PropositionalLogiset},
    args...;
    kwargs...

    )::Formula

    cond = value(φ)

    cond_threshold = threshold(cond)
    cond_operator = test_operator(cond)
    cond_feature = feature(cond)

    colname = varname(cond_feature)
    return cond_operator(i.s[i.i_instance,colname], cond_threshold) ? ⊤ : ⊥   
     
end

############################################################################################

"""
    abstract type AbstractModalLogiset{
        W<:AbstractWorld,
        U,
        FT<:AbstractFeature,
        FR<:AbstractFrame{W},
    } <: AbstractModalLogiset{AbstractKripkeStructure} end

Abstract type for logisets, that is, logical datasets for
symbolic learning where each instance is a
[Kripke structure](https://en.wikipedia.org/wiki/Kripke_structure_(model_checking))
associating feature values to each world.
Conditions (see [`AbstractCondition`](@ref)), and logical formulas
with conditional letters can be checked on worlds of instances of the dataset.

See also
[`AbstractCondition`](@ref),
[`AbstractFeature`](@ref),
[`SoleLogics.AbstractKripkeStructure`](@ref),
[`SoleLogics.AbstractInterpretationSet`](@ref).
"""
abstract type AbstractModalLogiset{
    W<:AbstractWorld,
    U,
    FT<:AbstractFeature,
    FR<:AbstractFrame{W},
} <: AbstractModalLogiset{AbstractKripkeStructure} end

function ninstances(X::AbstractLogiset)
    return error("Please, provide method ninstances(::$(typeof(X))).")
end

function allfeatvalues(
    X::AbstractLogiset,
    i_instance,
)
    return error("Please, provide method allfeatvalues(::$(typeof(X)), i_instance::$(typeof(i_instance))).")
end

function allfeatvalues(
    X::AbstractLogiset,
    i_instance,
    feature,
)
    return error("Please, provide method allfeatvalues(::$(typeof(X)), i_instance::$(typeof(i_instance)), feature::$(typeof(feature))).")
end

function instances(
    X::AbstractLogiset,
    inds::AbstractVector{<:Integer},
    return_view::Union{Val{true},Val{false}} = Val(false);
    kwargs...
)
    return error("Please, provide method instances(::$(typeof(X)), ::$(typeof(inds)), ::$(typeof(return_view))).")
end

function concatdatasets(Xs::AbstractLogiset...)
    return error("Please, provide method concatdatasets(X...::$(typeof(Xs))).")
end

function displaystructure(X::AbstractLogiset; kwargs...)::String
    return error("Please, provide method displaystructure(X::$(typeof(X)); kwargs...)::String.")
end

isminifiable(::AbstractLogiset) = false

usesfullmemo(::AbstractLogiset) = false

function allfeatvalues(X::AbstractLogiset)
    unique(collect(Iterators.flatten([allfeatvalues(X, i_instance) for i_instance in 1:ninstances(X)])))
end

hasnans(X::AbstractLogiset) = any(isnan, allfeatvalues(X))



function Base.show(io::IO, X::AbstractLogiset; kwargs...)
    println(io, displaystructure(X; kwargs...))
end


############################################################################################
# Non mandatory

function features(X::AbstractLogiset)
    return error("Please, provide method features(::$(typeof(X))).")
end

function nfeatures(X::AbstractLogiset)
    return error("Please, provide method nfeatures(::$(typeof(X))).")
end
