import Base: show
import SoleLogics: tree, dual

"""
Templated formula for ⟨R⟩⊤.
"""
struct ExistentialTopFormula{R<:AbstractRelation} <: SoleLogics.Formula end
tree(::ExistentialTopFormula{R}) where {R<:AbstractRelation} = DiamondRelationalConnective{R}(⊤)
hasdual(::ExistentialTopFormula) = true
dual(::ExistentialTopFormula{R}) where {R<:AbstractRelation} = UniversalBotFormula{R}()

"""
Templated formula for [R]⊥.
"""
struct UniversalBotFormula{R<:AbstractRelation} <: SoleLogics.Formula end
tree(::UniversalBotFormula{R}) where {R<:AbstractRelation} = BoxRelationalConnective{R}(⊥)
hasdual(::UniversalBotFormula) = true
dual(::UniversalBotFormula{R}) where {R<:AbstractRelation} = ExistentialTopFormula{R}()
