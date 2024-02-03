
abstract type CanonicalCondition end

# ⪴ and ⪳, that is, "*all* of the values on this world are at least, or at most ..."
struct CanonicalConditionGeq <: CanonicalCondition end; const canonical_geq  = CanonicalConditionGeq();
struct CanonicalConditionLeq <: CanonicalCondition end; const canonical_leq  = CanonicalConditionLeq();

# ⪴_α and ⪳_α, that is, "*at least α⋅100 percent* of the values on this world are at least, or at most ..."

struct CanonicalConditionGeqSoft  <: CanonicalCondition
    alpha :: AbstractFloat
    function CanonicalConditionGeqSoft(a::T) where {T<:Real}
        if ! (a > 0 && a < 1)
            error("Invalid instantiation of feature: CanonicalConditionGeqSoft($(a))")
        end
        new(a)
    end
end;
struct CanonicalConditionLeqSoft  <: CanonicalCondition
    alpha :: AbstractFloat
    function CanonicalConditionLeqSoft(a::T) where {T<:Real}
        if ! (a > 0 && a < 1)
            error("Invalid instantiation of feature: CanonicalConditionLeqSoft($(a))")
        end
        new(a)
    end
end;

const canonical_geq_95  = CanonicalConditionGeqSoft((Rational(95,100)));
const canonical_geq_90  = CanonicalConditionGeqSoft((Rational(90,100)));
const canonical_geq_85  = CanonicalConditionGeqSoft((Rational(85,100)));
const canonical_geq_80  = CanonicalConditionGeqSoft((Rational(80,100)));
const canonical_geq_75  = CanonicalConditionGeqSoft((Rational(75,100)));
const canonical_geq_70  = CanonicalConditionGeqSoft((Rational(70,100)));
const canonical_geq_60  = CanonicalConditionGeqSoft((Rational(60,100)));

const canonical_leq_95  = CanonicalConditionLeqSoft((Rational(95,100)));
const canonical_leq_90  = CanonicalConditionLeqSoft((Rational(90,100)));
const canonical_leq_85  = CanonicalConditionLeqSoft((Rational(85,100)));
const canonical_leq_80  = CanonicalConditionLeqSoft((Rational(80,100)));
const canonical_leq_75  = CanonicalConditionLeqSoft((Rational(75,100)));
const canonical_leq_70  = CanonicalConditionLeqSoft((Rational(70,100)));
const canonical_leq_60  = CanonicalConditionLeqSoft((Rational(60,100)));
