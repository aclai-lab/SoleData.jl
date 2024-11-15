using SoleLogics: AbstractFrame, AbstractMultiModalFrame, AbstractRelation, accessibles

# TODO: AbstractFrame -> AbstractMultiModalFrame, and provide the same for AbstractUniModalFrame

"""
    representatives(
        fr::AbstractFrame{W},
        S::W,
        ::AbstractRelation,
        ::AbstractCondition
    ) where {W<:AbstractWorld}

Return an iterator to the (few) *representative* accessible worlds that are
necessary for computing and propagating truth values
through existential modal connectives.
When this optimization is possible
(e.g., when checking specific formulas on scalar conditions),
it allows to further boost "one-step" optimizations (see [`AbstractOneStepMemoset`](@ref)).

For example, consider a Kripke structure with a
1-dimensional `FullDimensionalFrame` of length 100,
and the problem of checking a formula "⟨L⟩(max[V1] ≥ 10)"
on a [`SoleLogics.Interval`](@ref) `$(repr(Interval(1,2)))`
(with `L` being Allen's "Later" relation, see [`SoleLogics.IA_L`](@ref)).
Comparing 10 with the (maximum) "max[V1]" computed on all worlds
is the naïve strategy to check the formula.
However, in this case, comparing 10 to the "max[V1]" computed on the single `Interval`
$(repr(Interval(2,101))) suffice to establish whether the structure satisfies the formula.
Similar cases arise depending on the relation, feature and test
operator (or, better, its *aggregator*).

Note that this method fallsback to `accessibles`.

See also
[`SoleLogics.accessibles`](@ref),
[`ScalarCondition`](@ref),
[`SoleLogics.AbstractFrame`](@ref).
"""
function representatives( # Dispatch on feature/aggregator pairs
    fr::AbstractFrame{W},
    w::W,
    r::AbstractRelation,
    ::AbstractCondition
) where {W<:AbstractWorld}
    accessibles(fr, w, r)
end

function representatives(
    fr::AbstractFrame{W},
    w::W,
    ::AbstractCondition
) where {W<:AbstractWorld}
    accessibles(fr, w)
end
