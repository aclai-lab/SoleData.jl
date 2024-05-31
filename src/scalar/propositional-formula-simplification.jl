# # Author @edo-007
# # This is a first idea of an attempt at simplifying specific scalar, propositional formulas.

# using SoleLogics: Atom
# using SoleData:  AbstractFeature, ScalarCondition, UnivariateSymbolValue, LeftmostConjunctiveForm
# using SoleData: feature, value, test_operator, threshold, polarity

# const SatMask = BitVector
# TEST_OPS = [≤, ≥]

# x_u1 =  Atom{ScalarCondition}(ScalarCondition(UnivariateSymbolValue(:x), ≤, 10))
# x_u2 =  Atom{ScalarCondition}(ScalarCondition(UnivariateSymbolValue(:x), ≤, 9))
# x_u3 =  Atom{ScalarCondition}(ScalarCondition(UnivariateSymbolValue(:x), ≤, 7))
# x_u4 =  Atom{ScalarCondition}(ScalarCondition(UnivariateSymbolValue(:x), ≤, 6))
# x_l1 =  Atom{ScalarCondition}(ScalarCondition(UnivariateSymbolValue(:x), ≥, 1))
# x_l2 =  Atom{ScalarCondition}(ScalarCondition(UnivariateSymbolValue(:x), ≥, 3))

# y_u1 =  Atom{ScalarCondition}(ScalarCondition(UnivariateSymbolValue(:y), ≤, 10))
# y_u2 =  Atom{ScalarCondition}(ScalarCondition(UnivariateSymbolValue(:y), ≤, 9))
# y_u3 =  Atom{ScalarCondition}(ScalarCondition(UnivariateSymbolValue(:y), ≤, 7))
# y_u4 =  Atom{ScalarCondition}(ScalarCondition(UnivariateSymbolValue(:y), ≤, 6))



# atomslist = Atom{ScalarCondition}[x_u1, x_u2, x_u3, x_u4, x_l1, x_l2, y_u1, y_u2, y_u3, y_u4]

# # Start function

# scalar_conditions = SoleLogics.value.(atomslist)
# feats = feature.(scalar_conditions)


# coverages = [(f,  map(x->x==f, feats)) for f in unique(feats)]


# mostspecific(cs::AbstractVector{<:Real}, ::typeof(<=)) = findmin(cs)[1]
# mostspecific(cs::AbstractVector{<:Real}, ::typeof(>=)) = findmax(cs)[1]

# # total reduced conditions
# reduced_conditions = ScalarCondition[]
# for (usv, bitmask) in coverages
#     # reduced univariate conditions
#     reduceduni_conditions = ScalarCondition[]
#     univariate_conditions = scalar_conditions[bitmask]

#     # thresholds for operator
#     ths_foroperator = Dict{Function,Real}([])
#     for to in TEST_OPS

#         compatible_sc = [sc for sc in univariate_conditions if test_operator(sc)==to]
#         ths = Float64.(threshold.(compatible_sc))
#         isempty(ths) && break


#         push!(reduced_conditions, ScalarCondition(usv, to, mostspecific(ths, to)))
#     end
#     if length(reduced_conditions) > 1
#         (c1, c2) = reduced_conditions
#         if test_operator(c1)(threshold.(reduceduni_conditions))
#             push!(reducered_conditions, reduceduni_conditions)
#         else
#             return BOT
#         end
#     else
#         push!(reducered_conditions, reduceduni_conditions)
#     end
#     # Adesso ho solo il numero minimo di atomi che mi servono a descrivere l' intervallo
#     # per una USC. Devo capire se tale intervallo è ⊤, ⊥, o corrisponde ad un solo valore.
# end
