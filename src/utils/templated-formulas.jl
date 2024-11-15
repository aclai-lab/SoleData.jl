import Base: show
import SoleLogics: tree, dual

"""
Templated formula for ⟨R⟩⊤.
"""
struct ExistentialTopFormula{R<:AbstractRelation} <: SoleLogics.Formula
    rel::R
end
relation(φ::ExistentialTopFormula) = φ.rel
tree(φ::ExistentialTopFormula) = (SoleLogics.diamond(φ.rel))(⊤)
hasdual(::ExistentialTopFormula) = true
dual(φ::ExistentialTopFormula) = UniversalBotFormula(φ.rel)

"""
Templated formula for [R]⊥.
"""
struct UniversalBotFormula{R<:AbstractRelation} <: SoleLogics.Formula
    rel::R
end
relation(φ::UniversalBotFormula) = φ.rel
tree(φ::UniversalBotFormula) = (SoleLogics.box(φ.rel))(⊥)
hasdual(::UniversalBotFormula) = true
dual(φ::UniversalBotFormula) = ExistentialTopFormula(φ.rel)
