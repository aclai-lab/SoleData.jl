
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
    struct ExplicitBooleanModalLogiset{
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
struct ExplicitBooleanModalLogiset{
    W<:AbstractWorld,
    FT<:AbstractFeature,
    FR<:AbstractFrame{W},
    D<:AbstractVector{<:Tuple{<:Dict{<:W,<:Vector{<:FT}},<:FR}}
} <: AbstractModalLogiset{W,Bool,FT,FR}

    d :: D

end

ninstances(X::ExplicitBooleanModalLogiset) = length(X.d)

function featchannel(
    X::ExplicitBooleanModalLogiset{W},
    i_instance::Integer,
    feature::AbstractFeature,
) where {W<:AbstractWorld}
    X.d[i_instance][1]
end

function readfeature(
    X::ExplicitBooleanModalLogiset{W},
    featchannel::Any,
    w::W,
    feature::AbstractFeature;
    kwargs...
) where {W<:AbstractWorld}
    Base.in(feature, featchannel[w])
end

function featvalue!(
    X::ExplicitBooleanModalLogiset{W},
    featval::Bool,
    i_instance::Integer,
    w::W,
    feature::AbstractFeature,
    i_feature   :: Union{Nothing,Integer} = nothing,
) where {W<:AbstractWorld}
    cur_featval = featvalue(feature, X, featval, i_instance, w)
    if featval && !cur_featval
        push!(X.d[i_instance][1][w], feature)
    elseif !featval && cur_featval
        filter!(_f->_f != feature, X.d[i_instance][1][w])
    end
end

function frame(
    X::ExplicitBooleanModalLogiset{W},
    i_instance::Integer,
) where {W<:AbstractWorld}
    X.d[i_instance][2]
end

function instances(
    X::ExplicitBooleanModalLogiset,
    inds::AbstractVector,
    return_view::Union{Val{true},Val{false}} = Val(false);
    kwargs...
)
    ExplicitBooleanModalLogiset(if return_view == Val(true) @views X.d[inds] else X.d[inds] end)
end

function concatdatasets(Xs::ExplicitBooleanModalLogiset...)
    ExplicitBooleanModalLogiset(vcat([X.d for X in Xs]...))
end

function displaystructure(
    X::ExplicitBooleanModalLogiset;
    indent_str = "",
    include_ninstances = true,
    include_worldtype = missing,
    include_featvaltype = missing,
    include_featuretype = missing,
    include_frametype = missing,
)
    padattribute(l,r) = string(l) * lpad(r,32+length(string(r))-(length(indent_str)+2+length(l)))
    out = "ExplicitBooleanModalLogiset ($(humansize(X)))\n"
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

function allfeatvalues(X::ExplicitBooleanModalLogiset)
    [true, false]
end

function allfeatvalues(
    X::ExplicitBooleanModalLogiset,
    i_instance
)
    [true, false]
end

function allfeatvalues(
    X::ExplicitBooleanModalLogiset,
    i_instance,
    feature,
)
    [true, false]
end

hasnans(X::ExplicitBooleanModalLogiset) = false

# TODO "show plot" method


"""
    struct ExplicitModalLogiset{
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
struct ExplicitModalLogiset{
    W<:AbstractWorld,
    U,
    FT<:AbstractFeature,
    FR<:AbstractFrame{W},
    D<:AbstractVector{<:Tuple{<:Dict{<:W,<:Dict{<:FT,<:U}},<:FR}}
} <: AbstractModalLogiset{W,U,FT,FR}

    d :: D

end

ninstances(X::ExplicitModalLogiset) = length(X.d)

# TODO what to do here? save an index?
# nfeatures(X::ExplicitModalLogiset) = length(features(X))
# features(X::ExplicitModalLogiset) = unique(collect(Iterators.flatten(map(i->Iterators.flatten(map(d->collect(keys(d)), values(first(i)))), X.d))))

function featchannel(
    X::ExplicitModalLogiset{W},
    i_instance::Integer,
    feature::AbstractFeature,
) where {W<:AbstractWorld}
    X.d[i_instance][1]
end

function readfeature(
    X::ExplicitModalLogiset{W},
    featchannel::Any,
    w::W,
    feature::AbstractFeature,
) where {W<:AbstractWorld}
    featchannel[w][feature]
end

function featvalue!(
    feature::AbstractFeature,
    X::ExplicitModalLogiset{W},
    featval,
    i_instance::Integer,
    w::W,
    i_feature   :: Union{Nothing,Integer} = nothing,
) where {W<:AbstractWorld}
    X.d[i_instance][1][w][feature] = featval
end

function frame(
    X::ExplicitModalLogiset{W},
    i_instance::Integer,
) where {W<:AbstractWorld}
    X.d[i_instance][2]
end

function instances(
    X::ExplicitModalLogiset,
    inds::AbstractVector,
    return_view::Union{Val{true},Val{false}} = Val(false);
    kwargs...
)
    ExplicitModalLogiset(if return_view == Val(true) @views X.d[inds] else X.d[inds] end)
end

function concatdatasets(Xs::ExplicitModalLogiset...)
    ExplicitModalLogiset(vcat([X.d for X in Xs]...))
end

function displaystructure(
    X::ExplicitModalLogiset;
    indent_str = "",
    include_ninstances = true,
    include_worldtype = missing,
    include_featvaltype = missing,
    include_featuretype = missing,
    include_frametype = missing,
)
    padattribute(l,r) = string(l) * lpad(r,32+length(string(r))-(length(indent_str)+2+length(l)))
    out = "ExplicitModalLogiset ($(humansize(X)))\n"
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
    X::ExplicitModalLogiset{W},
    i_instance,
) where {W<:AbstractWorld}
    unique(collect(Iterators.flatten(values.(values(X.d[i_instance][1])))))
end

function allfeatvalues(
    X::ExplicitModalLogiset{W},
    i_instance,
    feature,
) where {W<:AbstractWorld}
    unique([ch[feature] for ch in values(X.d[i_instance][1])])
end
