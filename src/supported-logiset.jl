# # Examples
# TODO add example showing that checking is faster when using this structure.
"""
A logiset, associated to a number of cascading full or one-step
memoization structures, that are used for optimizing the checking of formulas.

See also
[`SupportedLogiset`](@ref),
[`AbstractFullMemoset`](@ref),
[`AbstractOneStepMemoset`](@ref),
[`AbstractModalLogiset`](@ref).
"""
struct SupportedLogiset{
    W<:AbstractWorld,
    U,
    FT<:AbstractFeature,
    FR<:AbstractFrame{W},
    L<:AbstractModalLogiset{W,U,FT,FR},
    N,
    MS<:NTuple{N,Union{AbstractOneStepMemoset,AbstractFullMemoset}},
} <: AbstractModalLogiset{W,U,FT,FR}

    # Core dataset
    base                 :: L
    # Support structures
    supports             :: MS

    function SupportedLogiset(
        base::L,
        supports::_MS
    ) where {W,U,FT,FR,L<:AbstractModalLogiset{W,U,FT,FR},_MS<:Tuple}

        wrong_supports = filter(supp->!(supp isa Union{<:AbstractVector{<:AbstractDict{<:Formula,<:Worlds}},<:Union{AbstractOneStepMemoset,AbstractFullMemoset},<:SupportedLogiset}), supports)

        @assert length(wrong_supports) == 0 "Cannot instantiate SupportedLogiset " *
            "with wrong support type(s): $(join(typeof.(wrong_supports), ", ")). " *
            "Only full and one-step memosets are allowed."
        @assert !(base isa SupportedLogiset) "Cannot instantiate SupportedLogiset " *
            "with a SupportedLogiset base."
        if length(supports) == 0
            full_memoset_type = default_full_memoset_type(base)
            supports = (full_memoset_type(base),)
        end
        supports = Tuple(vcat(map(supp->begin
            if supp isa AbstractVector{<:AbstractDict{<:Formula,<:Worlds}}
                [FullMemoset(supp)]
            elseif supp isa SupportedLogiset
                @assert base == SoleData.base(supp) "Cannot inherit supports from " *
                    "SupportedLogiset with different base."
                collect(SoleData.supports(supp))
            else
                [supp]
            end
        end, supports)...))

        wrong_supports = filter(supp->!(supp isa Union{AbstractOneStepMemoset,AbstractFullMemoset}), supports)

        @assert length(wrong_supports) == 0 "Cannot instantiate SupportedLogiset " *
            "with wrong support type(s): $(join(typeof.(wrong_supports), ", ")). " *
            "Only full and one-step memosets are allowed."

        @assert !(any(isa.(supports, SupportedLogiset))) "Cannot instantiate " *
            "SupportedLogiset with a SupportedLogiset support."
        for (i_supp,supp) in enumerate(supports)
            @assert worldtype(base) <: worldtype(supp) "Cannot instantiate " *
                "SupportedLogiset with unsupported worldtypes for $(i_supp)-th support: " *
                "$(worldtype(base)) <: $(worldtype(supp)) should hold."
            @assert featvaltype(base) <: featvaltype(supp) "Cannot instantiate " *
                "SupportedLogiset with unsupported featvaltypes for $(i_supp)-th support: " *
                "$(featvaltype(base)) <: $(featvaltype(supp)) should hold."
            @assert featuretype(base) <: featuretype(supp) "Cannot instantiate " *
                "SupportedLogiset with unsupported featuretypes for $(i_supp)-th support: " *
                "$(featuretype(base)) <: $(featuretype(supp)) should hold."
            @assert frametype(base) <: frametype(supp) "Cannot instantiate " *
                "SupportedLogiset with unsupported frametypes for $(i_supp)-th support: " *
                "$(frametype(base)) <: $(frametype(supp)) should hold."
        end
        _fullmemo = usesfullmemo.(supports)
        @assert sum(_fullmemo) <= 1 "Cannot instantiate SupportedLogiset with " *
            "more than one full memoization set. $(sum(_fullmemo)) were provided." *
            "support types: $(join(typeof.(supports), ", "))"

        if sum(_fullmemo) == 1
            # @assert all((!).(_fullmemo)) || (last(_fullmemo) && all((!).(_fullmemo[1:end-1]))) "" *
            #     "Please, provide cascading supports so that the full memoization set appears " *
            #     "last. $(@show typeof.(supports))"
            nonfullsupports = filter(!usesfullmemo, supports)
            fullsupport = first(filter(usesfullmemo, supports))
            supports = Tuple([nonfullsupports..., fullsupport])
        end

        @assert allequal([ninstances(base), ninstances.(supports)...]) "Consistency " *
            "check failed! Mismatching ninstances for " *
            "base and memoset(s): $(ninstances(base)) and $(ninstances.(supports))"

        N = length(supports)
        MS = typeof(supports)
        new{W,U,FT,FR,L,N,MS}(base, supports)
    end

    function SupportedLogiset(
        base::AbstractModalLogiset,
        supports::AbstractVector
    )
        SupportedLogiset(base, Tuple(supports))
    end

    # Helper (avoids ambiguities)
    function SupportedLogiset(
        base::AbstractModalLogiset,
        firstsupport::Union{<:AbstractVector{<:AbstractDict{<:Formula,<:Worlds}},<:Union{AbstractOneStepMemoset,AbstractFullMemoset},<:SupportedLogiset},
        supports::Union{<:AbstractVector{<:AbstractDict{<:Formula,<:Worlds}},<:Union{AbstractOneStepMemoset,AbstractFullMemoset},<:SupportedLogiset}...
    )
        SupportedLogiset(base, Union{<:AbstractVector{<:AbstractDict{<:Formula,<:Worlds}},<:Union{AbstractOneStepMemoset,AbstractFullMemoset},<:SupportedLogiset}[firstsupport, supports...])
    end

    function SupportedLogiset(
        base                             :: AbstractModalLogiset;
        use_full_memoization             :: Union{Bool,Type{<:Union{AbstractOneStepMemoset,AbstractFullMemoset}}} = true,
        #
        conditions                       :: Union{Nothing,AbstractVector{<:AbstractCondition}} = nothing,
        relations                        :: Union{Nothing,AbstractVector{<:AbstractRelation}} = nothing,
        use_onestep_memoization          :: Union{Bool,Type{<:AbstractOneStepMemoset}} = !isnothing(conditions) && !isnothing(relations),
        onestep_precompute_globmemoset   :: Bool = (use_onestep_memoization != false),
        onestep_precompute_relmemoset    :: Bool = false,
    )
        supports = Union{AbstractOneStepMemoset,AbstractFullMemoset}[]

        @assert !xor(isnothing(conditions), isnothing(relations)) "Please, provide " *
            "both conditions and relations in order to use a one-step memoset."

        isnothing(conditions) || (conditions = unique(conditions))
        isnothing(relations) || (relations  = unique(relations))

        if use_onestep_memoization != false
            @assert !isnothing(conditions) && !isnothing(relations) "Please, provide " *
                "both conditions and relations in order to use a one-step memoset."
            onestep_memoset_type = (use_onestep_memoization isa Bool ? default_onestep_memoset_type(base) : use_onestep_memoization)
            push!(supports,
                onestep_memoset_type(
                    base,
                    conditions,
                    relations;
                    precompute_globmemoset = onestep_precompute_globmemoset,
                    precompute_relmemoset = onestep_precompute_relmemoset
                )
            )
        else
            @assert isnothing(conditions) && isnothing(relations) "Conditions and/or " *
                "relations were passed; provide use_onestep_memoization = true " *
                "to use a one-step memoset."
        end

        if use_full_memoization != false
            full_memoset_type = (use_full_memoization isa Bool ? default_full_memoset_type(base) : use_full_memoization)
            push!(supports, full_memoset_type(base, conditions))
        end

        @assert length(supports) > 0 "Cannot instantiate SupportedLogiset with no supports. " *
            "Please, specify use_full_memoization = true and/or " *
            "use_onestep_memoization = true."

        SupportedLogiset(base, supports)
    end
end

base(X::SupportedLogiset)     = X.base
supports(X::SupportedLogiset) = X.supports

# Helper
base(X::AbstractModalLogiset)      = X

basetype(X::SupportedLogiset{W,U,FT,FR,L,N,MS}) where {W,U,FT,FR,L,N,MS} = L
supporttypes(X::SupportedLogiset{W,U,FT,FR,L,N,MS}) where {W,U,FT,FR,L,N,MS} = MS

nsupports(X::SupportedLogiset) = length(X.supports)

capacity(X::SupportedLogiset) = sum(capacity.(supports(X)))
nmemoizedvalues(X::SupportedLogiset) = sum(nmemoizedvalues.(supports(X)))


function featchannel(
    X::SupportedLogiset{W},
    i_instance::Integer,
    feature::AbstractFeature,
) where {W<:AbstractWorld}
    featchannel(base(X), i_instance, feature)
end

function readfeature(
    X::SupportedLogiset{W},
    featchannel::Any,
    w::W,
    feature::AbstractFeature,
) where {W<:AbstractWorld}
    featchannel(base(X), featchannel, w, feature)
end

function featvalue(
    feature::AbstractFeature,
    X::SupportedLogiset,
    i_instance::Integer,
    args...;
    kwargs...
)
    featvalue(feature, base(X), i_instance, args...; kwargs...)
end

frame(X::SupportedLogiset, i_instance::Integer) = frame(base(X), i_instance)

ninstances(X::SupportedLogiset) = ninstances(base(X))

function allfeatvalues(
    X::SupportedLogiset,
)
    allfeatvalues(base(X))
end

function allfeatvalues(
    X::SupportedLogiset,
    i_instance::Integer,
)
    allfeatvalues(base(X), i_instance)
end

function allfeatvalues(
    X::SupportedLogiset,
    i_instance::Integer,
    feature::AbstractFeature,
)
    allfeatvalues(base(X), i_instance, feature)
end

usesfullmemo(X::SupportedLogiset) = usesfullmemo(last(supports(X)))
fullmemo(X::SupportedLogiset) = usesfullmemo(X) ? last(supports(X)) : error("This " *
    "dataset does not have a full memoization set.")

isminifiable(X::SupportedLogiset) = isminifiable(base(X)) && all(isminifiable.(supports(X)))

function minify(X::SupportedLogiset)
    (new_sl, new_supports...), backmap =
        minify([
            base(X),
            supports(X)...,
        ])

    X = SupportedLogiset(
        new_sl,
        new_supports,
    )
    X, backmap
end

hasnans(X::SupportedLogiset) = hasnans(base(X)) || any(hasnans.(supports(X)))

function instances(
    X::SupportedLogiset,
    inds::AbstractVector,
    return_view::Union{Val{true},Val{false}} = Val(false);
    kwargs...
)
    _instances = (_X)->instances(_X, inds, return_view; kwargs...)
    SupportedLogiset(
        _instances(base(X)),
        (_instances.(supports(X)))...,
    )
end

function concatdatasets(Xs::SupportedLogiset...)
    @assert allequal(nsupports.(Xs)) "Cannot concatenate " *
        "SupportedLogiset's with different nsupports: " *
        "$(@show nsupports.(Xs))"
    SupportedLogiset(
        concatdatasets([base(X) for X in Xs]...),
        [concatdatasets([supports(X)[i_supp] for X in Xs]...) for i_supp in 1:nsupports(first(Xs))]...,
    )
end

function displaystructure(
    X::SupportedLogiset;
    indent_str = "",
    include_ninstances = true,
    include_worldtype = missing,
    include_featvaltype = missing,
    include_featuretype = missing,
    include_frametype = missing,
)
    padattribute(l,r) = string(l) * lpad(r,32+length(string(r))-(length(indent_str)+2+length(l))-1)
    pieces = []
    push!(pieces, "SupportedLogiset with $(nsupports(X)) $(nsupports(X) == 1 ? "support" : "supports") ($(humansize(X)))")
    if ismissing(include_worldtype) || include_worldtype != worldtype(X)
        push!(pieces, " " * padattribute("worldtype:", worldtype(X)))
    end
    if ismissing(include_featvaltype) || include_featvaltype != featvaltype(X)
        push!(pieces, " " * padattribute("featvaltype:", featvaltype(X)))
    end
    if ismissing(include_featuretype) || include_featuretype != featuretype(X)
        push!(pieces, " " * padattribute("featuretype:", featuretype(X)))
    end
    if ismissing(include_frametype) || include_frametype != frametype(X)
        push!(pieces, " " * padattribute("frametype:", frametype(X)))
    end
    if include_ninstances
        push!(pieces, " " * padattribute("# instances:", "$(ninstances(X))"))
    end
    # push!(pieces, " " * padattribute("# supports:", "$(nsupports(X))"))
    push!(pieces, " " * padattribute("usesfullmemo:", "$(usesfullmemo(X))"))
    push!(pieces, "[BASE] " * displaystructure(base(X);
        indent_str = "$(indent_str)│ ",
        include_ninstances = false,
        include_worldtype = worldtype(X),
        include_featvaltype = featvaltype(X),
        include_featuretype = featuretype(X),
        include_frametype = frametype(X),
    ))

    for (i_supp,supp) in enumerate(supports(X))
        push!(pieces, "[SUPPORT $(i_supp)] " * displaystructure(supp;
            indent_str = (i_supp == nsupports(X) ? "$(indent_str)  " : "$(indent_str)│ "),
            include_ninstances = false,
            include_worldtype = worldtype(X),
            include_featvaltype = featvaltype(X),
            include_featuretype = featuretype(X),
            include_frametype = frametype(X),
        ) * ")")
    end
    return join(pieces, "\n$(indent_str)├", "\n$(indent_str)└")
end

# ############################################################################################

# Base.getindex(X::SupportedLogiset, args...)     = Base.getindex(base(X), args...)::featvaltype(X)
# Base.size(X::SupportedLogiset)                  = (size(base(X)), size(support(X)))
# features(X::SupportedLogiset)                   = features(base(X))
# grouped_featsaggrsnops(X::SupportedLogiset)     = grouped_featsaggrsnops(base(X))
# grouped_featsnaggrs(X::SupportedLogiset)        = grouped_featsnaggrs(base(X))
# nfeatures(X::SupportedLogiset)                  = nfeatures(base(X))
# nrelations(X::SupportedLogiset)                 = nrelations(base(X))
# relations(X::SupportedLogiset)                  = relations(base(X))
# worldtype(X::SupportedLogiset{V,W}) where {V,W} = W

# TODO remove:
support(X::SupportedLogiset) = first(supports(X))

features(X::SupportedLogiset) = features(base(X))
nfeatures(X::SupportedLogiset) = nfeatures(base(X))
