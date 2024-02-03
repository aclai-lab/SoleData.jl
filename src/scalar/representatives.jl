using SoleLogics: AbstractUniModalFrame, AbstractFrame, AbstractRelation, GlobalRel, IdentityRel, accessibles

# TODO: AbstractFrame -> AbstractMultiModalFrame, and provide the same for AbstractUniModalFrame

function representatives( # Dispatch on feature/aggregator pairs
    fr::AbstractFrame{W},
    w::W,
    r::AbstractRelation,
    metacond::ScalarMetaCondition
) where {W<:AbstractWorld}
    representatives(fr, w, r, feature(metacond), existential_aggregator(test_operator(metacond)))
end

function representatives(
    fr::AbstractUniModalFrame{W},
    w::W,
    metacond::ScalarMetaCondition
) where {W<:AbstractWorld}
    representatives(fr, w, feature(metacond), existential_aggregator(test_operator(metacond)))
end

# Fallbacks to `accessibles`
function representatives(
    fr::AbstractFrame{W},
    w::W,
    r::AbstractRelation,
    ::AbstractFeature,
    ::Aggregator
) where {W<:AbstractWorld}
    accessibles(fr, w, r)
end

# Global relation: dispatch on feature/aggregator pairs
function representatives(
    fr::AbstractFrame{W},
    w::W,
    r::GlobalRel,
    f::AbstractFeature,
    a::Aggregator
) where {W<:AbstractWorld}
    representatives(fr, r, f, a)
end

# Global relation: fallbacks to `accessibles`
function representatives(
    fr::AbstractFrame{W},
    r::GlobalRel,
    f::AbstractFeature,
    a::Aggregator
) where {W<:AbstractWorld}
    accessibles(fr, r)
end

# # TODO remove but probably we need this to stay because of ambiguities!
# representatives(fr::AbstractFrame{W}, w::W, r::IdentityRel, ::AbstractFeature, ::Aggregator) where {W<:AbstractWorld} = accessibles(fr, w, r)
# TODO need this?
# `representatives(fr::AbstractFrame{W}, S::AbstractWorlds{W}, ::GlobalRel, ::ScalarMetaCondition)`
