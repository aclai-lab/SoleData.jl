
"""
    const TestOperator = Function

A test operator is a binary Julia `Function` used for comparing a feature value and
a threshold. In a crisp (i.e., boolean, non-fuzzy) setting, the test operator returns
a Boolean value, and `<`, `>`, `≥`, `≤`, `!=`, and `==` are typically used.

See also
[`Aggregator`](@ref),
[`ScalarCondition`](@ref).
"""
const TestOperator = Function

"""
Apply a test operator by simply passing the feature value and threshold to
the (binary) test operator function.
"""
@inline function apply_test_operator(
    operator::TestOperator,
    featval::T1,
    threshold::T2
) where {T1,T2}
    operator(featval, threshold)
end

"""
    const Aggregator = Function

A test operator is a binary Julia `Function` used for comparing a feature value and
a threshold. In a crisp (i.e., boolean, non-fuzzy) setting, the test operator returns
a Boolean value, and `<`, `>`, `≥`, `≤`, `!=`, and `==` are typically used.

See also
[`ScalarCondition`](@ref),
[`ScalarOneStepMemoset`](@ref),
[`TestOperator`](@ref).
"""
const Aggregator = Function

############################################################################################
# Crisp operators
############################################################################################

inverse_test_operator(::typeof(≥))  = <
inverse_test_operator(::typeof(≤))  = >
inverse_test_operator(::typeof(<))  = ≥
inverse_test_operator(::typeof(>))  = ≤
inverse_test_operator(::typeof(==)) = !=
inverse_test_operator(::typeof(!=)) = ==

isordered(op::TestOperator) = op in [≥, ≤, <, >]
polarity(::typeof(≥)) = true
polarity(::typeof(≤)) = false
polarity(::typeof(<)) = false
polarity(::typeof(>)) = true


dual_test_operator(::typeof(≥)) = ≤
dual_test_operator(::typeof(≤)) = ≥

existential_aggregator(::typeof(>))  = maximum
existential_aggregator(::typeof(<))  = minimum
existential_aggregator(::typeof(≥))  = maximum
existential_aggregator(::typeof(≤))  = minimum
existential_aggregator(::typeof(==)) = ∪

universal_aggregator(::typeof(>))  = minimum
universal_aggregator(::typeof(<))  = maximum
universal_aggregator(::typeof(≥))  = minimum
universal_aggregator(::typeof(≤))  = maximum
universal_aggregator(::typeof(==)) = ∩

aggregator_bottom(::typeof(maximum), T::Type) = typemin(T)
aggregator_bottom(::typeof(minimum), T::Type) = typemax(T)

# Helpers
aggregator_bottom(::typeof(maximum), T::Type{Real}) = typemin(Float64)
aggregator_bottom(::typeof(minimum), T::Type{Real}) = typemax(Float64)

aggregator_to_binary(::typeof(maximum)) = max
aggregator_to_binary(::typeof(minimum)) = min

############################################################################################
# Fuzzy
############################################################################################

# # =ₕ
# function get_fuzzy_linear_eq(h::T, fuzzy_type::Type{<:Real} = Float64) where {T}
#   fun = function (x::S, y::S) where {S}
#     Δ = y-x
#     if abs(Δ) ≥ h
#       zero(fuzzy_type)
#     else
#       fuzzy_type(1-(abs(Δ)/h))
#     end
#   end
#   @eval global existential_aggregator(::typeof($fun)) = ∪
#   fun
# end


# # >ₕ
# function get_fuzzy_linear_gt(h::T, fuzzy_type::Type{<:Real} = Float64) where {T}
#   fun = function (x::S, y::S) where {S}
#     Δ = y-x
#     if Δ ≥ 0
#       zero(fuzzy_type)
#     elseif Δ ≤ -h
#       one(fuzzy_type)
#     else
#       fuzzy_type(Δ/h)
#     end
#   end
#   @eval global existential_aggregator(::typeof($fun)) = maximum
#   fun
# end

# # <ₕ
# function get_fuzzy_linear_lt(h::T, fuzzy_type::Type{<:Real} = Float64) where {T}
#   fun = function (x::S, y::S) where {S}
#     Δ = y-x
#     if Δ ≥ h
#       one(fuzzy_type)
#     elseif Δ ≤ 0
#       zero(fuzzy_type)
#     else
#       fuzzy_type(Δ/h)
#     end
#   end
#   @eval global existential_aggregator(::typeof($fun)) = minimum
#   fun
# end


# # ≧ₕ
# function get_fuzzy_linear_geq(h::T, fuzzy_type::Type{<:Real} = Float64) where {T}
#   fun = function (x::S, y::S) where {S}
#     Δ = y-x
#     if Δ ≤ 0
#       one(fuzzy_type)
#     elseif Δ ≥ h
#       zero(fuzzy_type)
#     else
#       fuzzy_type(1-Δ/h)
#     end
#   end
#   @eval global existential_aggregator(::typeof($fun)) = maximum
#   fun
# end


# # ≦ₕ
# function get_fuzzy_linear_leq(h::T, fuzzy_type::Type{<:Real} = Float64) where {T}
#   fun = function (x::S, y::S) where {S}
#     Δ = x-y
#     if Δ ≤ 0
#       one(fuzzy_type)
#     elseif Δ ≥ h
#       zero(fuzzy_type)
#     else
#       fuzzy_type(1-Δ/h)
#     end
#   end
#   @eval global existential_aggregator(::typeof($fun)) = minimum
#   fun
# end

# # ≥ₕ
# function get_fuzzy_linear_geqt(h::T, fuzzy_type::Type{<:Real} = Float64) where {T}
#   h_2 = h/2
#   fun = function (x::S, y::S) where {S}
#     Δ = y-x
#     if Δ ≥ h_2
#       zero(fuzzy_type)
#     elseif Δ ≤ -h_2
#       one(fuzzy_type)
#     else
#       fuzzy_type((h_2-Δ)/h)
#     end
#   end
#   @eval global existential_aggregator(::typeof($fun)) = maximum
#   fun
# end

# # ≤ₕ
# function get_fuzzy_linear_leqt(h::T, fuzzy_type::Type{<:Real} = Float64) where {T}
#   h_2 = h/2
#   fun = function (x::S, y::S) where {S}
#     Δ = y-x
#     if Δ ≥ h_2
#       one(fuzzy_type)
#     elseif Δ ≤ -h_2
#       zero(fuzzy_type)
#     else
#       fuzzy_type((Δ+h_2)/h)
#     end
#   end
#   @eval global existential_aggregator(::typeof($fun)) = minimum
#   fun
# end

# h = 4
# v1 = 0
# v2 = -4:4

# op_fuzzy_eq = get_fuzzy_linear_eq(h)
# op_fuzzy_gt = get_fuzzy_linear_gt(h)
# op_fuzzy_lt = get_fuzzy_linear_lt(h)
# op_fuzzy_geqt = get_fuzzy_linear_geqt(h)
# op_fuzzy_leqt = get_fuzzy_linear_leqt(h)
# op_fuzzy_geq = get_fuzzy_linear_geq(h)
# op_fuzzy_leq = get_fuzzy_linear_leq(h)

# zip(v2, eq.(v1, v2)) |> collect
# zip(v2, gt.(v1, v2)) |> collect
# zip(v2, lt.(v1, v2)) |> collect
# zip(v2, geq.(v1, v2)) |> collect
# zip(v2, leq.(v1, v2)) |> collect
# zip(v2, op_fuzzy_eq.(v1, v2)) |> collect
# zip(v2, op_fuzzy_gt.(v1, v2)) |> collect
# zip(v2, op_fuzzy_lt.(v1, v2)) |> collect
# zip(v2, op_fuzzy_geqt.(v1, v2)) |> collect
# zip(v2, op_fuzzy_leqt.(v1, v2)) |> collect
# zip(v2, op_fuzzy_geq.(v1, v2)) |> collect
# zip(v2, op_fuzzy_leq.(v1, v2)) |> collect

# const all_lowlevel_test_operators = [
#     canonical_geq, canonical_leq,
#     SoftenedOperators...
#   ]

# const all_ordered_test_operators = [
#     canonical_geq, canonical_leq,
#     SoftenedOperators...
#   ]
# const all_test_operators_order = [
#     canonical_geq, canonical_leq,
#     SoftenedOperators...
#   ]
# sort_test_operators!(x::Vector{TO}) where {TO<:TestOperator} = begin
#   intersect(all_test_operators_order, x)
# end
