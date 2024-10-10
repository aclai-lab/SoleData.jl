using SoleLogics: AbstractKripkeStructure, AbstractAssignment, AbstractInterpretation, AbstractInterpretationSet, AbstractFrame, AbstractWorld
using SoleLogics: Truth, LogicalInstance
import SoleLogics: alphabet, frame, check
import SoleLogics: accessibles, allworlds, nworlds
import SoleLogics: worldtype, frametype
import SoleLogics: interpret
import Tables: columnnames, rows, getcolumn, columns
import MultiData: nvariables

############################################################################################
#
abstract type AbstractLogiset <: AbstractInterpretationSet end

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
    inds::AbstractVector,
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


############################################################################################

abstract type AbstractPropositionalLogiset <: AbstractLogiset end
