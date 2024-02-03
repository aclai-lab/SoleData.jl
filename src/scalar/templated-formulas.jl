using SoleLogics: AbstractRelation

import SoleLogics: atom

using SoleData: AbstractFeature, TestOperator, ScalarCondition

"""
Abstract type for templated formulas on scalar conditions.
"""
abstract type ScalarFormula{U} <: SoleLogics.Formula end

"""
Templated formula for f ⋈ t.
"""
struct ScalarPropositionFormula{U} <: ScalarFormula{U}
    p :: ScalarCondition{U}
end

atom(f::ScalarPropositionFormula) = Atom(f.p)
feature(f::ScalarPropositionFormula) = feature(atom(f))
test_operator(f::ScalarPropositionFormula) = test_operator(atom(f))
threshold(f::ScalarPropositionFormula) = threshold(atom(f))

tree(f::ScalarPropositionFormula) = SyntaxTree(f.p)
hasdual(f::ScalarPropositionFormula) = true
dual(f::ScalarPropositionFormula{U}) where {U} =
    ScalarPropositionFormula{U}(dual(p))

############################################################################################

abstract type ScalarOneStepFormula{U} <: ScalarFormula{U} end

relation(f::ScalarOneStepFormula) = f.relation
atom(f::ScalarOneStepFormula) = Atom(f.p)
metacond(f::ScalarOneStepFormula) = metacond(value(atom(f)))
feature(f::ScalarOneStepFormula) = feature(value(atom(f)))
test_operator(f::ScalarOneStepFormula) = test_operator(value(atom(f)))
threshold(f::ScalarOneStepFormula) = threshold(value(atom(f)))

"""
Templated formula for ⟨R⟩ f ⋈ t.
"""
struct ScalarExistentialFormula{U} <: ScalarOneStepFormula{U}

    # Relation, interpreted as an existential modal connective
    relation  :: AbstractRelation

    p         :: ScalarCondition{U}

    function ScalarExistentialFormula{U}() where {U}
        new{U}()
    end

    function ScalarExistentialFormula{U}(
        relation      :: AbstractRelation,
        p             :: ScalarCondition{U}
    ) where {U}
        new{U}(relation, p)
    end

    function ScalarExistentialFormula(
        relation      :: AbstractRelation,
        p             :: ScalarCondition{U}
    ) where {U}
        ScalarExistentialFormula{U}(relation, p)
    end

    function ScalarExistentialFormula{U}(
        relation      :: AbstractRelation,
        feature       :: AbstractFeature,
        test_operator :: TestOperator,
        threshold     :: U
    ) where {U}
        p = ScalarCondition(feature, test_operator, threshold)
        ScalarExistentialFormula{U}(relation, p)
    end

    function ScalarExistentialFormula(
        relation      :: AbstractRelation,
        feature       :: AbstractFeature,
        test_operator :: TestOperator,
        threshold     :: U
    ) where {U}
        ScalarExistentialFormula{U}(relation, feature, test_operator, threshold)
    end

    function ScalarExistentialFormula(
        formula       :: ScalarExistentialFormula{U},
        threshold_f   :: Function
    ) where {U}
        q = ScalarCondition(formula.p, threshold_f(threshold(formula.p)))
        ScalarExistentialFormula{U}(relation(formula), q)
    end
end

tree(f::ScalarExistentialFormula) = DiamondRelationalConnective(f.relation)(Atom(f.p))

"""
Templated formula for [R] f ⋈ t.
"""
struct ScalarUniversalFormula{U} <: ScalarOneStepFormula{U}
    relation  :: AbstractRelation
    p         :: ScalarCondition{U}
end

tree(f::ScalarUniversalFormula) = BoxRelationalConnective(f.relation)(Atom(f.p))

hasdual(f::ScalarExistentialFormula) = true
function dual(formula::ScalarExistentialFormula{U}) where {U}
    ScalarUniversalFormula{U}(
        relation(formula),
        dual(atom(formula))
    )
end
hasdual(f::ScalarUniversalFormula) = true
function dual(formula::ScalarUniversalFormula{U}) where {U}
    ScalarExistentialFormula{U}(
        relation(formula),
        dual(atom(formula))
    )
end
