using SoleLogics: AbstractRelation

import SoleLogics: atom

using SoleData: AbstractFeature, TestOperator, ScalarCondition

"""
Abstract type for templated formulas on scalar conditions.
"""
abstract type ScalarFormula <: SoleLogics.Formula end

# """
# Templated formula for f ⋈ t.
# """
# struct ScalarPropositionFormula{V} <: ScalarFormula
#     p :: V
# end

# atom(f::ScalarPropositionFormula) = Atom(f.p)
# feature(f::ScalarPropositionFormula) = feature(atom(f))
# test_operator(f::ScalarPropositionFormula) = test_operator(atom(f))
# threshold(f::ScalarPropositionFormula) = threshold(atom(f))

# tree(f::ScalarPropositionFormula) = SyntaxTree(f.p)
# hasdual(f::ScalarPropositionFormula) = true
# dual(f::ScalarPropositionFormula{V}) where {V} =
#     ScalarPropositionFormula{V}(dual(p))

############################################################################################

abstract type ScalarOneStepFormula{V} <: ScalarFormula end

relation(f::ScalarOneStepFormula) = f.relation
atom(f::ScalarOneStepFormula) = Atom(f.p)
metacond(f::ScalarOneStepFormula{<:ScalarCondition}) = metacond(value(atom(f)))
feature(f::ScalarOneStepFormula{<:ScalarCondition}) = feature(value(atom(f)))
test_operator(f::ScalarOneStepFormula{<:ScalarCondition}) = test_operator(value(atom(f)))
threshold(f::ScalarOneStepFormula{<:ScalarCondition}) = threshold(value(atom(f)))

"""
Templated formula for ⟨R⟩ f ⋈ t.
"""
struct ScalarExistentialFormula{V,R<:AbstractRelation} <: ScalarOneStepFormula{V}

    # Relation, interpreted as an existential modal connective
    relation  :: R

    # Atom value
    p         :: V

    function ScalarExistentialFormula{V,R}(relation::R, p::V) where {V,R<:AbstractRelation}
        @assert !(V <: SoleLogics.Formula) "Cannot instantiate ScalarExistentialFormula " *
            "with atom value $V."
        new{V,R}(relation, p)
    end

    function ScalarExistentialFormula{V}(
        relation      :: R,
        p             :: V
    ) where {V,R<:AbstractRelation}
        ScalarExistentialFormula{V,R}(relation, p)
    end

    function ScalarExistentialFormula(
        relation      :: AbstractRelation,
        p             :: V
    ) where {V}
        ScalarExistentialFormula{V}(relation, p)
    end

    function ScalarExistentialFormula{V}(
        relation      :: AbstractRelation,
        feature       :: AbstractFeature,
        test_operator :: TestOperator,
        threshold     :: U,
    ) where {V,U}
        p = ScalarCondition(feature, test_operator, threshold)
        ScalarExistentialFormula(relation, p)
    end

    function ScalarExistentialFormula(
        relation      :: AbstractRelation,
        feature       :: AbstractFeature,
        test_operator :: TestOperator,
        threshold     :: U,
    ) where {U}
        p = ScalarCondition(feature, test_operator, threshold)
        ScalarExistentialFormula(relation, p)
    end

    function ScalarExistentialFormula(
        formula       :: ScalarExistentialFormula{V},
        threshold_f   :: Function
    ) where {V<:ScalarCondition}
        q = ScalarCondition(formula.p, threshold_f(threshold(formula.p)))
        ScalarExistentialFormula(relation(formula), q)
    end
end

tree(f::ScalarExistentialFormula) = DiamondRelationalConnective(f.relation)(Atom(f.p))

"""
Templated formula for [R] f ⋈ t.
"""
struct ScalarUniversalFormula{V,R<:AbstractRelation} <: ScalarOneStepFormula{V}
    relation  :: R
    p         :: V
end

tree(f::ScalarUniversalFormula) = BoxRelationalConnective(f.relation)(Atom(f.p))

hasdual(f::ScalarExistentialFormula) = true
function dual(formula::ScalarExistentialFormula)
    return ScalarUniversalFormula(
        relation(formula),
        dual(atom(formula))
    )
end
hasdual(f::ScalarUniversalFormula) = true
function dual(formula::ScalarUniversalFormula)
    return ScalarExistentialFormula(
        relation(formula),
        dual(atom(formula))
    )
end
