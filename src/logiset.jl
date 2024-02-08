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
    W<:SoleLogics.AbstractWorld,
    U,
    FT<:AbstractFeature,
    FR<:AbstractFrame{W},
} <: AbstractModalLogiset{AbstractKripkeStructure} end

function featchannel(
    X::AbstractModalLogiset{W},
    i_instance::Integer,
    feature::AbstractFeature,
) where {W<:AbstractWorld}
    return error("Please, provide method featchannel(::$(typeof(X)), i_instance::$(typeof(i_instance)), feature::$(typeof(feature))).")
end

function readfeature(
    X::AbstractModalLogiset{W},
    featchannel::Any,
    w::W,
    feature::AbstractFeature,
) where {W<:AbstractWorld}
    return error("Please, provide method readfeature(::$(typeof(X)), featchannel::$(typeof(featchannel)), w::$(typeof(w)), feature::$(typeof(feature))).")
end

# TODO docstring
function featvalue(
    X::AbstractModalLogiset{W},
    i_instance::Integer,
    w::W,
    feature::AbstractFeature,
) where {W<:AbstractWorld}
    readfeature(X, featchannel(X, i_instance, feature), w, feature)
end

function featvalue!(
    X::AbstractModalLogiset{W},
    featval,
    i_instance::Integer,
    w::W,
    feature::AbstractFeature,
) where {W<:AbstractWorld}
    return error("Please, provide method featvalue!(::$(typeof(X)), featval::$(typeof(featval)), i_instance::$(typeof(i_instance)), w::$(typeof(w)), feature::$(typeof(feature))).")
end

function featvalues!(
    X::AbstractModalLogiset{W},
    featslice,
    feature::AbstractFeature,
) where {W<:AbstractWorld}
    return error("Please, provide method featvalues!(::$(typeof(X)), featslice::$(typeof(featslice)), feature::$(typeof(feature))).")
end

function frame(X::AbstractModalLogiset, i_instance::Integer)
    return error("Please, provide method frame(::$(typeof(X)), i_instance::$(typeof(i_instance))).")
end

function ninstances(X::AbstractModalLogiset)
    return error("Please, provide method ninstances(::$(typeof(X))).")
end

function allfeatvalues(
    X::AbstractModalLogiset,
    i_instance,
)
    return error("Please, provide method allfeatvalues(::$(typeof(X)), i_instance::$(typeof(i_instance))).")
end

function allfeatvalues(
    X::AbstractModalLogiset,
    i_instance,
    feature,
)
    return error("Please, provide method allfeatvalues(::$(typeof(X)), i_instance::$(typeof(i_instance)), feature::$(typeof(feature))).")
end

function instances(
    X::AbstractModalLogiset,
    inds::AbstractVector{<:Integer},
    return_view::Union{Val{true},Val{false}} = Val(false);
    kwargs...
)
    return error("Please, provide method instances(::$(typeof(X)), ::$(typeof(inds)), ::$(typeof(return_view))).")
end

function concatdatasets(Xs::AbstractModalLogiset...)
    return error("Please, provide method concatdatasets(X...::$(typeof(Xs))).")
end

function displaystructure(X::AbstractModalLogiset; kwargs...)::String
    return error("Please, provide method displaystructure(X::$(typeof(X)); kwargs...)::String.")
end

isminifiable(::AbstractModalLogiset) = false

usesfullmemo(::AbstractModalLogiset) = false

function allfeatvalues(X::AbstractModalLogiset)
    unique(collect(Iterators.flatten([allfeatvalues(X, i_instance) for i_instance in 1:ninstances(X)])))
end

hasnans(X::AbstractModalLogiset) = any(isnan, allfeatvalues(X))

############################################################################################

function Base.show(io::IO, X::AbstractModalLogiset; kwargs...)
    println(io, displaystructure(X; kwargs...))
end

worldtype(::Type{<:AbstractModalLogiset{W}}) where {W<:AbstractWorld} = W
worldtype(X::AbstractModalLogiset) = worldtype(typeof(X))

featvaltype(::Type{<:AbstractModalLogiset{W,U}}) where {W<:AbstractWorld,U} = U
featvaltype(X::AbstractModalLogiset) = featvaltype(typeof(X))

featuretype(::Type{<:AbstractModalLogiset{W,U,FT}}) where {W<:AbstractWorld,U,FT<:AbstractFeature} = FT
featuretype(X::AbstractModalLogiset) = featuretype(typeof(X))

frametype(::Type{<:AbstractModalLogiset{W,U,FT,FR}}) where {W<:AbstractWorld,U,FT<:AbstractFeature,FR<:AbstractFrame} = FR
frametype(X::AbstractModalLogiset) = frametype(typeof(X))

representatives(X::AbstractModalLogiset, i_instance::Integer, args...) = representatives(frame(X, i_instance), args...)

############################################################################################
# Non mandatory

function features(X::AbstractModalLogiset)
    return error("Please, provide method features(::$(typeof(X))).")
end

function nfeatures(X::AbstractModalLogiset)
    return error("Please, provide method nfeatures(::$(typeof(X))).")
end

############################################################################################


# """
#     abstract type AbstractBaseLogiset{
#         W<:AbstractWorld,
#         U,
#         FT<:AbstractFeature,
#         FR<:AbstractFrame{W},
#     } <: AbstractModalLogiset{W,U,FT,FR} end

# (Base) logisets can be associated to support logisets that perform memoization in order
# to speed up model checking times.

# See also
# [`SupportedLogiset`](@ref),
# [`AbstractModalLogiset`](@ref).
# """
# abstract type AbstractBaseLogiset{
#     W<:AbstractWorld,
#     U,
#     FT<:AbstractFeature,
#     FR<:AbstractFrame{W},
# } <: AbstractModalLogiset{W,U,FT,FR} end


"""
    struct ExplicitBooleanLogiset{
        W<:AbstractWorld,
        FT<:AbstractFeature,
        FR<:AbstractFrame{W},
    } <: AbstractModalLogiset{W,Bool,FT,FR}

        d :: Vector{Tuple{Dict{W,Vector{FT}},FR}}

    end

A logiset where the features are boolean, and where each instance associates to each world
the set of features with `true`.

See also
[`AbstractModalLogiset`](@ref).
"""
struct ExplicitBooleanLogiset{
    W<:AbstractWorld,
    FT<:AbstractFeature,
    FR<:AbstractFrame{W},
    D<:AbstractVector{<:Tuple{<:Dict{<:W,<:Vector{<:FT}},<:FR}}
} <: AbstractModalLogiset{W,Bool,FT,FR}

    d :: D

end

ninstances(X::ExplicitBooleanLogiset) = length(X.d)

function featchannel(
    X::ExplicitBooleanLogiset{W},
    i_instance::Integer,
    feature::AbstractFeature,
) where {W<:AbstractWorld}
    X.d[i_instance][1]
end

function readfeature(
    X::ExplicitBooleanLogiset{W},
    featchannel::Any,
    w::W,
    feature::AbstractFeature,
) where {W<:AbstractWorld}
    Base.in(feature, featchannel[w])
end

function featvalue!(
    X::ExplicitBooleanLogiset{W},
    featval::Bool,
    i_instance::Integer,
    w::W,
    feature::AbstractFeature,
    i_feature   :: Union{Nothing,Integer} = nothing,
) where {W<:AbstractWorld}
    cur_featval = featvalue(X, featval, i_instance, w, feature)
    if featval && !cur_featval
        push!(X.d[i_instance][1][w], feature)
    elseif !featval && cur_featval
        filter!(_f->_f != feature, X.d[i_instance][1][w])
    end
end

function frame(
    X::ExplicitBooleanLogiset{W},
    i_instance::Integer,
) where {W<:AbstractWorld}
    X.d[i_instance][2]
end

function instances(
    X::ExplicitBooleanLogiset,
    inds::AbstractVector{<:Integer},
    return_view::Union{Val{true},Val{false}} = Val(false);
    kwargs...
)
    ExplicitBooleanLogiset(if return_view == Val(true) @views X.d[inds] else X.d[inds] end)
end

function concatdatasets(Xs::ExplicitBooleanLogiset...)
    ExplicitBooleanLogiset(vcat([X.d for X in Xs]...))
end

function displaystructure(
    X::ExplicitBooleanLogiset;
    indent_str = "",
    include_ninstances = true,
    include_worldtype = missing,
    include_featvaltype = missing,
    include_featuretype = missing,
    include_frametype = missing,
)
    padattribute(l,r) = string(l) * lpad(r,32+length(string(r))-(length(indent_str)+2+length(l)))
    out = "ExplicitBooleanLogiset ($(humansize(X)))\n"
    if ismissing(include_worldtype) || include_worldtype != worldtype(X)
        out *= indent_str * "├ " * padattribute("worldtype:", worldtype(X)) * "\n"
    end
    if ismissing(include_featvaltype) || include_featvaltype != featvaltype(X)
        out *= indent_str * "├ " * padattribute("featvaltype:", featvaltype(X)) * "\n"
    end
    if ismissing(include_featuretype) || include_featuretype != featuretype(X)
        out *= indent_str * "├ " * padattribute("featuretype:", featuretype(X)) * "\n"
    end
    if ismissing(include_frametype) || include_frametype != frametype(X)
        out *= indent_str * "├ " * padattribute("frametype:", frametype(X)) * "\n"
    end
    if include_ninstances
        out *= indent_str * "├ " * padattribute("# instances:", ninstances(X)) * "\n"
    end
    out *= indent_str * "└ " * padattribute("# world density (countmap):", "$(countmap([nworlds(X, i_instance) for i_instance in 1:ninstances(X)]))")
    out
end

function allfeatvalues(X::ExplicitBooleanLogiset)
    [true, false]
end

function allfeatvalues(
    X::ExplicitBooleanLogiset,
    i_instance
)
    [true, false]
end

function allfeatvalues(
    X::ExplicitBooleanLogiset,
    i_instance,
    feature,
)
    [true, false]
end

hasnans(X::ExplicitBooleanLogiset) = false

# TODO "show plot" method


"""
    struct ExplicitLogiset{
        W<:AbstractWorld,
        U,
        FT<:AbstractFeature,
        FR<:AbstractFrame{W},
    } <: AbstractModalLogiset{W,U,FT,FR}

        d :: Vector{Tuple{Dict{W,Dict{FT,U}},FR}}

    end

A logiset where the features are boolean, and where each instance associates to each world
the set of features with `true`.

See also
[`AbstractModalLogiset`](@ref).
"""
struct ExplicitLogiset{
    W<:AbstractWorld,
    U,
    FT<:AbstractFeature,
    FR<:AbstractFrame{W},
    D<:AbstractVector{<:Tuple{<:Dict{<:W,<:Dict{<:FT,<:U}},<:FR}}
} <: AbstractModalLogiset{W,U,FT,FR}

    d :: D

end

ninstances(X::ExplicitLogiset) = length(X.d)

# TODO what to do here? save an index?
# nfeatures(X::ExplicitLogiset) = length(features(X))
# features(X::ExplicitLogiset) = unique(collect(Iterators.flatten(map(i->Iterators.flatten(map(d->collect(keys(d)), values(first(i)))), X.d))))

function featchannel(
    X::ExplicitLogiset{W},
    i_instance::Integer,
    feature::AbstractFeature,
) where {W<:AbstractWorld}
    X.d[i_instance][1]
end

function readfeature(
    X::ExplicitLogiset{W},
    featchannel::Any,
    w::W,
    feature::AbstractFeature,
) where {W<:AbstractWorld}
    featchannel[w][feature]
end

function featvalue!(
    X::ExplicitLogiset{W},
    featval,
    i_instance::Integer,
    w::W,
    feature::AbstractFeature,
    i_feature   :: Union{Nothing,Integer} = nothing,
) where {W<:AbstractWorld}
    X.d[i_instance][1][w][feature] = featval
end

function frame(
    X::ExplicitLogiset{W},
    i_instance::Integer,
) where {W<:AbstractWorld}
    X.d[i_instance][2]
end

function instances(
    X::ExplicitLogiset,
    inds::AbstractVector{<:Integer},
    return_view::Union{Val{true},Val{false}} = Val(false);
    kwargs...
)
    ExplicitLogiset(if return_view == Val(true) @views X.d[inds] else X.d[inds] end)
end

function concatdatasets(Xs::ExplicitLogiset...)
    ExplicitLogiset(vcat([X.d for X in Xs]...))
end

function displaystructure(
    X::ExplicitLogiset;
    indent_str = "",
    include_ninstances = true,
    include_worldtype = missing,
    include_featvaltype = missing,
    include_featuretype = missing,
    include_frametype = missing,
)
    padattribute(l,r) = string(l) * lpad(r,32+length(string(r))-(length(indent_str)+2+length(l)))
    out = "ExplicitLogiset ($(humansize(X)))\n"
    if ismissing(include_worldtype) || include_worldtype != worldtype(X)
        out *= indent_str * "├ " * padattribute("worldtype:", worldtype(X)) * "\n"
    end
    if ismissing(include_featvaltype) || include_featvaltype != featvaltype(X)
        out *= indent_str * "├ " * padattribute("featvaltype:", featvaltype(X)) * "\n"
    end
    if ismissing(include_featuretype) || include_featuretype != featuretype(X)
        out *= indent_str * "├ " * padattribute("featuretype:", featuretype(X)) * "\n"
    end
    if ismissing(include_frametype) || include_frametype != frametype(X)
        out *= indent_str * "├ " * padattribute("frametype:", frametype(X)) * "\n"
    end
    if include_ninstances
        out *= indent_str * "├ " * padattribute("# instances:", "$(ninstances(X))") * "\n"
    end
    out *= indent_str * "└ " * padattribute("# world density (countmap):", "$(countmap([nworlds(X, i_instance) for i_instance in 1:ninstances(X)]))")
    out
end


# TODO "show plot" method


function allfeatvalues(
    X::ExplicitLogiset{W},
    i_instance,
) where {W<:AbstractWorld}
    unique(collect(Iterators.flatten(values.(values(X.d[i_instance][1])))))
end

function allfeatvalues(
    X::ExplicitLogiset{W},
    i_instance,
    feature,
) where {W<:AbstractWorld}
    unique([ch[feature] for ch in values(X.d[i_instance][1])])
end
