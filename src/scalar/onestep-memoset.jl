
@inline function onestep_aggregation(
    X::AbstractModalLogiset{W},
    i_instance::Integer,
    w::W,
    r::AbstractRelation,
    f::VarFeature,
    aggr::Aggregator,
    args...
) where {W<:AbstractWorld}
    vs = [featvalue(f, X, i_instance, w2) for w2 in representatives(X, i_instance, w, r, f, aggr)]
    U = featvaltype(X)
    return (length(vs) == 0 ? aggregator_bottom(aggr, U) : aggr(vs))
end

function featchannel_onestep_aggregation(X::SupportedLogiset, args...)
    onestep_supps = filter(supp->supp isa AbstractOneStepMemoset, supports(X))
    if length(onestep_supps) > 0
        @assert length(onestep_supps) == 1 "Currently, using more " *
            "than one AbstractOneStepMemoset is not allowed."
        featchannel_onestep_aggregation(base(X), onestep_supps[1], args...)
    else
        featchannel_onestep_aggregation(base(X), args...)
    end
end

function featchannel_onestep_aggregation(
    X::AbstractModalLogiset,
    featchannel,
    i_instance,
    r::GlobalRel,
    f::AbstractFeature,
    aggregator::Aggregator
)
    # accessible_worlds = allworlds(X, i_instance)
    accessible_worlds = representatives(X, i_instance, r, f, aggregator)
    gamma = apply_aggregator(X, featchannel, accessible_worlds, f, aggregator)
end

function featchannel_onestep_aggregation(
    X::AbstractModalLogiset,
    featchannel,
    i_instance,
    w,
    r::AbstractRelation,
    f::AbstractFeature,
    aggregator::Aggregator
)
    # accessible_worlds = accessibles(X, i_instance, w, r)
    accessible_worlds = representatives(X, i_instance, w, r, f, aggregator)
    gamma = apply_aggregator(X, featchannel, accessible_worlds, f, aggregator)
end

function apply_aggregator(
    X::AbstractModalLogiset{W,U},
    featchannel,
    worlds, # ::AbstractWorlds but iterators are also accepted.
    f::AbstractFeature,
    aggregator::Aggregator
) where {W<:AbstractWorld,U}

    # TODO try reduce(aggregator, worlds; init=bottom(aggregator, U))
    # TODO remove this SoleData.aggregator_to_binary...

    if length(worlds |> collect) == 0
        aggregator_bottom(aggregator, U)
    else
        aggregator((w)->readfeature(X, featchannel, w, f), worlds)
    end

    # opt = SoleData.aggregator_to_binary(aggregator)
    # gamma = bottom(aggregator, U)
    # for w in worlds
    #   e = readfeature(X, featchannel, w, f)
    #   gamma = opt(gamma,e)
    # end
    # gamma
end

############################################################################################
############################################################################################
############################################################################################

"""
Abstract type for one-step memoization structures for checking formulas of type `⟨R⟩ (f ⋈ t)`,
for a generic relation `R` that is not the global relation ([`SoleLogics.globalrel`](@ref)).
We refer to these structures as *relational memosets*.
"""
abstract type AbstractScalarOneStepRelationalMemoset{W<:AbstractWorld,U,FR<:AbstractFrame{W}} <: AbstractMemoset{W,U,FT where FT<:AbstractFeature,FR}     end

@inline function Base.getindex(
    Xm           :: AbstractScalarOneStepRelationalMemoset{W},
    i_instance   :: Integer,
    w            :: W,
    i_metacond   :: Integer,
    i_relation   :: Integer
) where {W}
    return error("Please, provide method Base.getindex(" *
        "Xm::$(typeof(Xm)), " *
        "i_instance::$(typeof(i_instance)), " *
        "w::$(typeof(w)), " *
        "i_metacond::$(typeof(i_metacond)), " *
        "i_relation::$(typeof(i_relation))" *
    ").")
end

@inline function Base.setindex!(
    Xm           :: AbstractScalarOneStepRelationalMemoset{W},
    gamma,
    i_instance   :: Integer,
    w            :: W,
    i_metacond   :: Integer,
    i_relation   :: Integer,
) where {W<:AbstractWorld}
    return error("Please, provide method Base.setindex!(" *
        "Xm::$(typeof(Xm)), " *
        "gamma, " *
        "i_instance::$(typeof(i_instance)), " *
        "w::$(typeof(w)), " *
        "i_metacond::$(typeof(i_metacond)), " *
        "i_relation::$(typeof(i_relation))" *
    ").")
end

"""
Abstract type for one-step memoization structure for checking "global" formulas
of type `⟨G⟩ (f ⋈ t)`.
    We refer to these structures as *global memosets*.
"""
abstract type AbstractScalarOneStepGlobalMemoset{W<:AbstractWorld,U} <: AbstractMemoset{W,U,FT where FT<:AbstractFeature,FR where FR<:AbstractFrame{W}} end

@inline function Base.getindex(
    Xm           :: AbstractScalarOneStepGlobalMemoset{W},
    i_instance   :: Integer,
    i_metacond   :: Integer,
) where {W}
    return error("Please, provide method Base.getindex(" *
        "Xm::$(typeof(Xm)), " *
        "i_instance::$(typeof(i_instance)), " *
        "i_metacond::$(typeof(i_metacond))" *
    ").")
end

@inline function Base.setindex!(
    Xm           :: AbstractScalarOneStepGlobalMemoset{W},
    gamma,
    i_instance   :: Integer,
    i_metacond   :: Integer,
) where {W<:AbstractWorld}
    return error("Please, provide method Base.getindex(" *
        "Xm::$(typeof(Xm)), " *
        "gamma, " *
        "i_instance::$(typeof(i_instance)), " *
        "i_metacond::$(typeof(i_metacond))" *
    ").")
end

# Access inner structure
function innerstruct(Xm::Union{AbstractScalarOneStepRelationalMemoset,AbstractScalarOneStepGlobalMemoset})
    return error("Please, provide method innerstruct(::$(typeof(Xm))).")
end

isminifiable(::Union{AbstractScalarOneStepRelationalMemoset,AbstractScalarOneStepGlobalMemoset}) = true

function minify(Xm::Union{AbstractScalarOneStepRelationalMemoset,AbstractScalarOneStepGlobalMemoset})
    minify(innerstruct(Xm))
end

usesfullmemo(::Union{AbstractScalarOneStepRelationalMemoset,AbstractScalarOneStepGlobalMemoset}) = false

############################################################################################
############################################################################################
############################################################################################

# Compute modal dataset atoms and 1-modal decisions
"""
One-step memoization structures for optimized check of formulas of type `⟨R⟩p`,
where `p` wraps a scalar condition, such as `MyFeature ≥ 10`. With such formulas,
scalar one-step optimization can be performed.

For example, checking `⟨R⟩(MyFeature ≥ 10)` on a world `w` of a Kripke structure
involves comparing the *maximum* MyFeature across `w`s accessible worlds with 10;
but the same *maximum* value can be reused to check *sibling formulas*
such as `⟨R⟩(MyFeature ≥ 100)`. This sparks the idea of storing and reusing
scalar aggregations (e.g., minimum/maximum) over the feature values.
Each value refers to a specific world, and an object of type `⟨R⟩(f ⋈ ?)`,
called a "scalar *metacondition*".

Similar cases arise depending on the relation and the test operator (or, better, its *aggregator*),
and further optimizations can be applied for specific feature types (see [`representatives`](@ref)).

An immediate special case, however, arises when `R` is the global relation `G` since,
in such case,
a single aggregate value is enough for all worlds within the Kripke structure.
Therefore, we differentiate between generic, *relational* memosets
(see [`AbstractScalarOneStepRelationalMemoset`](@ref)), and *global* memosets
(see [`AbstractScalarOneStepGlobalMemoset`](@ref)),
which are usually much smaller.

Given a logiset `X`, a `ScalarOneStepMemoset` covers a set of `relations` and `metaconditions`,
and it holds both a *relational* and a *global* memoset. It can be instantiated via:

```julia
ScalarOneStepMemoset(
    X                       :: AbstractModalLogiset{W,U},
    metaconditions          :: AbstractVector{<:ScalarMetaCondition},
    relations               :: AbstractVector{<:AbstractRelation};
    precompute_globmemoset  :: Bool = true,
    precompute_relmemoset   :: Bool = false,
    print_progress          :: Bool = false,
)
```

If `precompute_relmemoset` is `false`, then the relational memoset is simply initialized as an
empty structure, and memoization is performed on it upon checking formulas.
`precompute_globmemoset` works similarly.

See [`SupportedLogiset`](@ref), [`ScalarMetaCondition`](@ref), [`AbstractOneStepMemoset`](@ref).
"""
struct ScalarOneStepMemoset{
    U<:Number,
    W<:AbstractWorld,
    FR<:AbstractFrame{W},
    UU<:Union{U,Nothing},
    RM<:AbstractScalarOneStepRelationalMemoset{W,UU,FR},
    GM<:Union{AbstractScalarOneStepGlobalMemoset{W,U},Nothing},
} <: AbstractOneStepMemoset{W,U,FT where FT<:AbstractFeature,FR}

    # Relational memoset
    relmemoset              :: RM

    # Global memoset
    globmemoset             :: GM

    metaconditions          :: UniqueVector{<:ScalarMetaCondition}
    relations               :: UniqueVector{<:AbstractRelation}

    function ScalarOneStepMemoset{U}(
        relmemoset::RM,
        globmemoset::GM,
        metaconditions::AbstractVector{<:ScalarMetaCondition},
        relations::AbstractVector{<:AbstractRelation};
        silent = false
    ) where {
        U<:Number,
        W<:AbstractWorld,
        FR<:AbstractFrame{W},
        UU<:Union{U,Nothing},
        RM<:AbstractScalarOneStepRelationalMemoset{W,UU,FR},
        GM<:Union{AbstractScalarOneStepGlobalMemoset{W,U},Nothing},
    }
        ty = "ScalarOneStepMemoset"
        metaconditions = UniqueVector(metaconditions)
        relations = UniqueVector(relations)

        if identityrel in relations && !silent
            @warn "Using identity relation in a relational memoset. This is not optimal."
        end

        if globalrel in relations && isnothing(globmemoset) && !silent
            @warn "Using global relation in a relational memoset. This is not optimal."
        end

        @assert nmetaconditions(relmemoset) == length(metaconditions)  "Cannot instantiate " *
            "$(ty) with mismatching nmetaconditions for relmemoset and " *
            "provided metaconditions: $(nmetaconditions(relmemoset)) and $(length(metaconditions))"
        # Global relation breaks this:
        # @assert nrelations(relmemoset) == length(relations)            "Cannot instantiate " *
        #     "$(ty) with mismatching nrelations for relmemoset and " *
        #     "provided relations: $(nrelations(relmemoset)) and $(length(relations))"

        if !isnothing(globmemoset)
            @assert nmetaconditions(globmemoset) == length(metaconditions) "Cannot " *
                "instantiate $(ty) with mismatching nmetaconditions for " *
                "globmemoset and provided metaconditions: " *
                "$(nmetaconditions(globmemoset)) and $(length(metaconditions))"
            @assert ninstances(globmemoset) == ninstances(relmemoset)      "Cannot " *
                "instantiate $(ty) with mismatching ninstances for " *
                "global and relational memosets: " *
                "$(ninstances(globmemoset)) and $(ninstances(relmemoset))"
        end

        new{U,W,FR,UU,RM,GM}(relmemoset, globmemoset, metaconditions, relations)
    end

    Base.@propagate_inbounds function ScalarOneStepMemoset(
        X                       :: AbstractModalLogiset{W,U},
        metaconditions          :: AbstractVector{<:ScalarMetaCondition},
        relations               :: AbstractVector{<:AbstractRelation},
        # relational_memoset_type :: Type{<:AbstractScalarOneStepRelationalMemoset} = default_relmemoset_type(X);
        relational_memoset_type :: Type = default_relmemoset_type(X);
        features = nothing,
        precompute_globmemoset  :: Bool = true,
        precompute_relmemoset   :: Bool = false,
        print_progress          :: Bool = false,
        silent                  :: Bool = false,
    ) where {W<:AbstractWorld,U}

        # Only compute global memoset if the global relation is in the relation set.
        compute_globmemoset = begin
            if globalrel in relations
                relations = filter(l->l≠globalrel, relations)
                if W == OneWorld || all(i_instance->nworlds(frame(X, i_instance)) == 1, 1:ninstances(X))
                    @warn "ScalarOneStepMemoset: " *
                        "Found globalrel in relations in a single-world case."
                    false
                else
                    true
                end
            else
                false
            end
        end

        # Prepare relmemoset
        perform_initialization = true # !precompute_relmemoset
        relmemoset = relational_memoset_type(X, metaconditions, relations, perform_initialization)

        # Prepare globmemoset
        globmemoset = begin
            if compute_globmemoset
                ScalarOneStepGlobalMemoset(X, metaconditions, perform_initialization)
            else
                nothing
            end
        end

        if (compute_globmemoset && precompute_globmemoset) || precompute_relmemoset

            metaconditions = UniqueVector(metaconditions)
            relations = UniqueVector(relations)

            n_instances = ninstances(X)
            nrelations = length(relations)
            nmetaconditions = length(metaconditions)

            _grouped_metaconditions = grouped_metaconditions(metaconditions, features)

            if print_progress
                p = Progress(n_instances; dt = 1, desc = "Computing supports...")
            end
            Threads.@threads for i_instance in 1:n_instances

                for (_feature, these_metaconditions) in _grouped_metaconditions

                    _featchannel = featchannel(X, i_instance, _feature)

                    # Global relation (independent of the current world)
                    if compute_globmemoset && precompute_globmemoset

                        for (i_metacond, aggregator, _metacond) in these_metaconditions

                            gamma = featchannel_onestep_aggregation(X, _featchannel, i_instance, globalrel, _feature, aggregator)

                            globmemoset[i_instance, i_metacond] = gamma
                        end
                    end

                    # Other, generic relations
                    if precompute_relmemoset
                        for (i_relation, relation) in enumerate(relations)

                            for w in allworlds(X, i_instance)

                                for (i_metacond, aggregator, _metacond) in these_metaconditions

                                    gamma = featchannel_onestep_aggregation(X, _featchannel, i_instance, w, relation, _feature, aggregator)

                                    relmemoset[i_instance, w, i_metacond, i_relation] = gamma
                                end
                            end
                        end
                    end
                end
                if print_progress
                    next!(p)
                end
            end
        end
        ScalarOneStepMemoset{U}(relmemoset, globmemoset, metaconditions, relations; silent = silent)
    end
end

metaconditions(Xm::ScalarOneStepMemoset) = Xm.metaconditions
relations(Xm::ScalarOneStepMemoset) = Xm.relations
nmetaconditions(Xm::ScalarOneStepMemoset) = length(Xm.metaconditions)
nrelations(Xm::ScalarOneStepMemoset) = length(Xm.relations)

relmemoset(Xm::ScalarOneStepMemoset) = Xm.relmemoset
globmemoset(Xm::ScalarOneStepMemoset) = Xm.globmemoset

capacity(Xm::ScalarOneStepMemoset)        = sum(capacity, [relmemoset(Xm), globmemoset(Xm)])
nmemoizedvalues(Xm::ScalarOneStepMemoset) = sum(nmemoizedvalues, [relmemoset(Xm), globmemoset(Xm)])

ninstances(Xm::ScalarOneStepMemoset) = ninstances(relmemoset(Xm))

function grouped_metaconditions(
    metaconditions::AbstractVector{<:ScalarMetaCondition},
    features::Union{Nothing,AbstractVector{<:AbstractFeature}} = nothing,
)
    if isnothing(features)
        features = unique(feature.(metaconditions))
    end
    return map(((feature,these_metaconditions),)->begin
        these_metaconditions = map(_metacond->begin
            i_metacond = _findfirst(isequal(_metacond), metaconditions)
            aggregator = existential_aggregator(test_operator(_metacond))
            (i_metacond, aggregator, _metacond)
        end, these_metaconditions)
        (feature,these_metaconditions)
    end, groupbyfeature(metaconditions, features))
end

function featchannel_onestep_aggregation(
    X::AbstractModalLogiset{W,U},
    Xm::ScalarOneStepMemoset,
    featchannel,
    i_instance::Integer,
    w::W,
    rel::AbstractRelation,
    metacond::ScalarMetaCondition,
    i_metacond::Union{Nothing,Integer} = nothing,
    i_relation::Union{Nothing,Integer} = nothing
)::U where {U,W<:AbstractWorld}

    if isnothing(i_metacond)
        i_metacond = _findfirst(isequal(metacond), metaconditions(Xm))
    end

    if isnothing(i_metacond)
        # Find metacond with same aggregator
        i_metacond = findfirst((m)->feature(m) == feature(metacond) && existential_aggregator(test_operator(m)) == existential_aggregator(test_operator(metacond)), metaconditions(Xm))
        if isnothing(i_metacond)
            i_neg_metacond = _findfirst(isequal(dual(metacond)), metaconditions(Xm))
            error("Could not find metacondition $(metacond) in memoset of type $(typeof(Xm)) " *
                "($(!isnothing(i_neg_metacond) ? "but dual was found " *
                "with i_metacond = $(i_neg_metacond)!" : "")).")
        end
    end

    _feature = feature(metacond)
    _test_operator = test_operator(metacond)
    aggregator = existential_aggregator(_test_operator)

    gamma = begin
        if rel == globalrel
            _globmemoset = globmemoset(Xm)
            if isnothing(_globmemoset)
                error("Could not compute one-step aggregation with no global memoset.")
            else
                if isnothing(_globmemoset[i_instance, i_metacond])
                    gamma = featchannel_onestep_aggregation(X, featchannel, i_instance, rel, _feature, aggregator)
                    _globmemoset[i_instance, i_metacond] = gamma
                end
                _globmemoset[i_instance, i_metacond]
            end
        else
            i_relation = isnothing(i_relation) ? _findfirst(isequal(rel), Xm.relations) : i_relation
            if isnothing(i_relation)
                error("Could not find relation $(rel) in memoset of type $(typeof(Xm)).")
            end
            _relmemoset = relmemoset(Xm)
            if isnothing(_relmemoset[i_instance, w, i_metacond, i_relation])
                gamma = featchannel_onestep_aggregation(X, featchannel, i_instance, w, rel, _feature, aggregator)
                _relmemoset[i_instance, w, i_metacond, i_relation] = gamma
            end
            _relmemoset[i_instance, w, i_metacond, i_relation]
        end
    end
end

function check(
    f::ScalarExistentialFormula,
    i::SoleLogics.LogicalInstance{<:ScalarOneStepMemoset{W}},
    w::W,
    rel,
    metacond,
) where {W<:AbstractWorld}
    Xm, i_instance = SoleLogics.splat(i)
    rel = relation(f)
    metacond = metacond(f)

    i_metacond = _findfirst(isequal(metacond), metaconditions(Xm))
    if isnothing(i_metacond)
        i_metacond = findfirst((m)->feature(m) == feature(metacond) && existential_aggregator(test_operator(m)) == existential_aggregator(test_operator(metacond)), metaconditions(Xm))
        if isnothing(i_metacond)
            i_neg_metacond = _findfirst(isequal(dual(metacond)), metaconditions(Xm))
            error("Could not find metacondition $(metacond) in memoset of type $(typeof(Xm)) " *
                "($(!isnothing(i_neg_metacond) ? "but dual was found " *
                "with i_metacond = $(i_neg_metacond)!" : "")).")
        end
    end

    gamma = begin
        if rel
            Base.getindex(globmemoset(Xm), i_instance, i_metacond)
        else
            i_rel = _findfirst(isequal(rel), Xm.relations)
            if isnothing(i_rel)
                error("Could not find relation $(rel) in memoset of type $(typeof(Xm)).")
            end
            Base.getindex(relmemoset(Xm), i_instance, w, i_metacond, i_rel)
        end
    end
    if !isnothing(gamma)
        return apply_test_operator(test_operator(metacond), gamma, threshold(f))
    else
        return nothing
    end
end

function instances(Xm::ScalarOneStepMemoset{U}, inds::AbstractVector{<:Integer}, return_view::Union{Val{true},Val{false}} = Val(false)) where {U}
    ScalarOneStepMemoset{U}(
        instances(relmemoset(Xm), inds, return_view),
        (isnothing(globmemoset(Xm)) ? nothing : instances(globmemoset(Xm), inds, return_view)),
        metaconditions(Xm),
        relations(Xm);
        silent = true
    )
end

function concatdatasets(Xms::ScalarOneStepMemoset{U}...) where {U}
    @assert allequal(metaconditions.(Xms)) "Cannot concatenate " *
        "ScalarOneStepMemoset's with different metaconditions: " *
        "$(@show metaconditions.(Xms))"
    @assert allequal(relations.(Xms)) "Cannot concatenate " *
        "ScalarOneStepMemoset's with different relations: " *
        "$(@show relations.(Xms))"
    ScalarOneStepMemoset{U}(
        concatdatasets(relmemoset.(Xms)...),
        (any(isnothing.(globmemoset.(Xms))) ? nothing : concatdatasets(globmemoset.(Xms)...)),
        metaconditions(first(Xms)),
        relations(first(Xms));
        silent = true
    )
end

function hasnans(Xm::ScalarOneStepMemoset)
    hasnans(relmemoset(Xm)) || (!isnothing(globmemoset(Xm)) && hasnans(globmemoset(Xm)))
end

isminifiable(Xm::ScalarOneStepMemoset) = isminifiable(relmemoset(Xm)) && (isnothing(globmemoset(Xm)) || isminifiable(globmemoset(Xm)))

function minify(Xm::OSSD) where {OSSD<:ScalarOneStepMemoset}
    (new_relmemoset, new_globmemoset), backmap =
        minify([
            relmemoset(Xm),
            globmemoset(Xm),
        ])

    Xm = OSSD(
        new_relmemoset,
        new_globmemoset,
        featsnaggrs(Xm),
    )
    Xm, backmap
end

function displaystructure(
    Xm::ScalarOneStepMemoset;
    indent_str = "",
    include_ninstances = true,
    kwargs...
    # include_worldtype = missing,
    # include_featvaltype = missing,
    # include_featuretype = missing,
    # include_frametype = missing,
)
    padattribute(l,r,off=0) = string(l) * lpad(string(r),32+off+length(string(r))-(length(indent_str)+2+length(string(l)))-1)
    pieces = []
    push!(pieces, "ScalarOneStepMemoset ($(humansize(Xm)))")

    if include_ninstances
        push!(pieces, " $(padattribute("# instances:", ninstances(Xm), 1))")
    end

    # push!(pieces, " $(padattribute("# metaconditions:", nmetaconditions(Xm), 1))")
    # push!(pieces, " $(padattribute("# relations:", nrelations(Xm), 1))")

    push!(pieces, " $(padattribute("metaconditions:", "$(nmetaconditions(Xm)) -> $(SoleLogics.displaysyntaxvector(metaconditions(Xm)))", 1))")
    push!(pieces, " $(padattribute("relations:", "$(nrelations(Xm)) -> $(SoleLogics.displaysyntaxvector(relations(Xm)))"))")

    push!(pieces, "[R] " * displaystructure(relmemoset(Xm); indent_str = "$(indent_str)│ ", include_ninstances = false, include_nmetaconditions = false, include_nrelations = false, kwargs...))
    if !isnothing(globmemoset(Xm))
        push!(pieces, "[G] " * displaystructure(globmemoset(Xm); indent_str = "$(indent_str)  ", include_ninstances = false, include_nmetaconditions = false, kwargs...))
    else
        push!(pieces, "[G] −")
    end

    return join(pieces, "\n$(indent_str)├", "\n$(indent_str)└")
end

############################################################################################

# TODO explain
"""
A generic, one-step memoization structure used for checking specific formulas
of scalar conditions on
datasets with scalar features. The formulas are of type ⟨R⟩ (f ⋈ t)

See also
[`AbstractScalarOneStepRelationalMemoset`](@ref),
[`FullMemoset`](@ref),
[`SupportedLogiset`](@ref).
"""
struct ScalarOneStepRelationalMemoset{
    W<:AbstractWorld,
    U,
    FR<:AbstractFrame{W},
    D<:AbstractArray{<:AbstractDict{W,U}, 3},
} <: AbstractScalarOneStepRelationalMemoset{W,U,FR}

    d :: D

    function ScalarOneStepRelationalMemoset{W,U,FR}(
        d::D,
    ) where {W<:AbstractWorld,U,FR<:AbstractFrame{W},D<:AbstractArray{<:AbstractDict{W,U}, 3}}
        new{W,U,FR,D}(d)
    end

    function ScalarOneStepRelationalMemoset(
        X::AbstractModalLogiset{W,U,FT,FR},
        metaconditions::AbstractVector{<:ScalarMetaCondition},
        relations::AbstractVector{<:AbstractRelation},
        perform_initialization::Bool = true
    ) where {W,U,FT<:AbstractFeature,FR<:AbstractFrame{W}}
        nmetaconditions = length(metaconditions)
        nrelations = length(relations)
        d = begin
            d = Array{Dict{W,U}, 3}(undef, ninstances(X), nmetaconditions, nrelations)
            if perform_initialization
                for idx in eachindex(d)
                    d[idx] = ThreadSafeDict{W,U}()
                end
            end
            d
        end
        ScalarOneStepRelationalMemoset{W,U,FR}(d)
    end
end

innerstruct(Xm::ScalarOneStepRelationalMemoset)     = Xm.d

ninstances(Xm::ScalarOneStepRelationalMemoset)      = size(Xm.d, 1)
nmetaconditions(Xm::ScalarOneStepRelationalMemoset) = size(Xm.d, 2)
nrelations(Xm::ScalarOneStepRelationalMemoset)      = size(Xm.d, 3)

capacity(Xm::ScalarOneStepRelationalMemoset)        = Inf
nmemoizedvalues(Xm::ScalarOneStepRelationalMemoset) = sum(length.(Xm.d))

@inline function Base.getindex(
    Xm           :: ScalarOneStepRelationalMemoset{W},
    i_instance   :: Integer,
    w            :: W,
    i_metacond   :: Integer,
    i_relation   :: Integer
) where {W<:AbstractWorld}
    get(Xm.d[i_instance, i_metacond, i_relation], w, nothing)
end

@inline function Base.setindex!(
    Xm           :: ScalarOneStepRelationalMemoset{W},
    gamma,
    i_instance   :: Integer,
    w            :: W,
    i_metacond   :: Integer,
    i_relation   :: Integer,
) where {W<:AbstractWorld}
    Xm.d[i_instance, i_metacond, i_relation][w] = gamma
end

function hasnans(Xm::ScalarOneStepRelationalMemoset)
    any(map(d->(any(_isnan.(collect(values(d))))), Xm.d))
end

function instances(Xm::ScalarOneStepRelationalMemoset{W,U,FR}, inds::AbstractVector{<:Integer}, return_view::Union{Val{true},Val{false}} = Val(false)) where {W,U,FR}
    ScalarOneStepRelationalMemoset{W,U,FR}(if return_view == Val(true) @view Xm.d[inds,:,:] else Xm.d[inds,:,:] end)
end

function concatdatasets(Xms::ScalarOneStepRelationalMemoset{W,U,FR}...) where {W,U,FR}
    ScalarOneStepRelationalMemoset{W,U,FR}(cat([Xm.d for Xm in Xms]...; dims=1))
end


function displaystructure(
    Xm::ScalarOneStepRelationalMemoset;
    indent_str = "",
    include_ninstances = true,
    include_nmetaconditions = true,
    include_nrelations = true,
    include_worldtype = missing,
    include_featvaltype = missing,
    include_featuretype = missing,
    include_frametype = missing,
)
    padattribute(l,r) = string(l) * lpad(r,32+length(string(r))-(length(indent_str)+2+length(l)))
    pieces = []
    push!(pieces, "ScalarOneStepRelationalMemoset ($(memoizationinfo(Xm)), $(humansize(Xm)))")
    if ismissing(include_worldtype) || include_worldtype != worldtype(Xm)
        push!(pieces, "$(padattribute("worldtype:", worldtype(Xm)))")
    end
    if ismissing(include_featvaltype) || include_featvaltype != featvaltype(Xm)
        push!(pieces, "$(padattribute("featvaltype:", featvaltype(Xm)))")
    end
    # if ismissing(include_featuretype) || include_featuretype != featuretype(Xm)
    #     push!(pieces, "$(padattribute("featuretype:", featuretype(Xm)))")
    # end
    if ismissing(include_frametype) || include_frametype != frametype(Xm)
        push!(pieces, "$(padattribute("frametype:", frametype(Xm)))")
    end
    if include_ninstances
        push!(pieces, "$(padattribute("# instances:", ninstances(Xm)))")
    end
    if include_nmetaconditions
        push!(pieces, "$(padattribute("# metaconditions:", nmetaconditions(Xm)))")
    end
    if include_nrelations
        push!(pieces, "$(padattribute("# relations:", nrelations(Xm)))")
    end
    push!(pieces, "$(padattribute("size × eltype:", "$(size(Xm.d)) × $(eltype(Xm.d))"))")
    # push!(pieces, "$(padattribute("# memoized values:", nmemoizedvalues(Xm)))")

    return join(pieces, "\n$(indent_str)├ ", "\n$(indent_str)└ ")
end

# @inline function Base.setindex!(Xm::ScalarOneStepRelationalMemoset{W,U}, threshold::U, i_instance::Integer, w::AbstractWorld, i_metacond::Integer, i_relation::Integer) where {W,U}
#     Xm.d[i_instance, i_metacond, i_relation][w] = threshold
# end

############################################################################################

# Note: the global Xm is world-agnostic
struct ScalarOneStepGlobalMemoset{
    W<:AbstractWorld,
    U,
    D<:AbstractArray{UU,2} where {UU<:Union{U,Nothing}}
} <: AbstractScalarOneStepGlobalMemoset{W,U}

    d :: D

    function ScalarOneStepGlobalMemoset{W,U}(
        d::D
    ) where {W<:AbstractWorld,U,D<:AbstractArray{UU,2} where {UU<:Union{U,Nothing}}}
        new{W,U,D}(d)
    end

    function ScalarOneStepGlobalMemoset(
        X::AbstractModalLogiset{W,U},
        metaconditions::AbstractVector{<:ScalarMetaCondition},
        perform_initialization::Bool = true
    ) where {W<:AbstractWorld,U}
        nmetaconditions = length(metaconditions)
        d = Array{Union{U,Nothing},2}(undef, ninstances(X), length(metaconditions))
        if perform_initialization
            fill!(d, nothing)
        end
        ScalarOneStepGlobalMemoset{W,U}(d)
    end
end

innerstruct(Xm::ScalarOneStepGlobalMemoset)     = Xm.d

ninstances(Xm::ScalarOneStepGlobalMemoset)      = size(Xm.d, 1)
nmetaconditions(Xm::ScalarOneStepGlobalMemoset) = size(Xm.d, 2)

capacity(Xm::ScalarOneStepGlobalMemoset)        = prod(size(Xm.d))
nmemoizedvalues(Xm::ScalarOneStepGlobalMemoset) = count(!isnothing, Xm.d)

@inline function Base.getindex(
    Xm           :: ScalarOneStepGlobalMemoset{W},
    i_instance   :: Integer,
    i_metacond   :: Integer,
) where {W<:AbstractWorld}
    Xm.d[i_instance, i_metacond]
end


@inline function Base.setindex!(
    Xm           :: ScalarOneStepGlobalMemoset{W},
    gamma,
    i_instance   :: Integer,
    i_metacond   :: Integer,
) where {W<:AbstractWorld}
    Xm.d[i_instance, i_metacond] = gamma
end

function hasnans(Xm::ScalarOneStepGlobalMemoset)
    # @show any(_isnan.(Xm.d))
    any(_isnan.(Xm.d))
end

function instances(
    Xm::ScalarOneStepGlobalMemoset{W,U},
    inds::AbstractVector{<:Integer},
    return_view::Union{Val{true},Val{false}} = Val(false)
) where {W,U}
    ScalarOneStepGlobalMemoset{W,U}(if return_view == Val(true) @view Xm.d[inds,:] else Xm.d[inds,:] end)
end

function concatdatasets(Xms::ScalarOneStepGlobalMemoset{W,U}...) where {W,U}
    ScalarOneStepGlobalMemoset{W,U}(cat([Xm.d for Xm in Xms]...; dims=1))
end


function displaystructure(
    Xm::ScalarOneStepGlobalMemoset;
    indent_str = "",
    include_ninstances = true,
    include_nmetaconditions = true,
    include_worldtype = missing,
    include_featvaltype = missing,
    include_featuretype = missing,
    include_frametype = missing,
)
    padattribute(l,r) = string(l) * lpad(r,32+length(string(r))-(length(indent_str)+2+length(l)))
    pieces = []
    push!(pieces, "ScalarOneStepGlobalMemoset ($(memoizationinfo(Xm)), $(humansize(Xm)))")
    if ismissing(include_worldtype) || include_worldtype != worldtype(Xm)
        push!(pieces, "$(padattribute("worldtype:", worldtype(Xm)))")
    end
    if ismissing(include_featvaltype) || include_featvaltype != featvaltype(Xm)
        push!(pieces, "$(padattribute("featvaltype:", featvaltype(Xm)))")
    end
    # if ismissing(include_featuretype) || include_featuretype != featuretype(Xm)
    #     push!(pieces, "$(padattribute("featuretype:", featuretype(Xm)))")
    # end
    # if ismissing(include_frametype) || include_frametype != frametype(Xm)
    #     push!(pieces, "$(padattribute("frametype:", frametype(Xm)))")
    # end
    if include_ninstances
        push!(pieces, "$(padattribute("# instances:", ninstances(Xm)))")
    end
    if include_nmetaconditions
        push!(pieces, "$(padattribute("# metaconditions:", nmetaconditions(Xm)))")
    end
    push!(pieces, "$(padattribute("size × eltype:", "$(size(innerstruct(Xm))) × $(eltype(innerstruct(Xm)))"))")

    return join(pieces, "\n$(indent_str)├ ", "\n$(indent_str)└ ")
end

