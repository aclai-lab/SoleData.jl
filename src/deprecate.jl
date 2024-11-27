const BoundedScalarConditions = MultivariateScalarAlphabet{ScalarCondition} 

function BoundedScalarConditions(
    metaconditions::Vector{<:ScalarMetaCondition},
    thresholds::Vector{<:Vector}
)
    @warn "This function is deprecating."
    length(metaconditions) != length(thresholds) &&
        error("Cannot instantiate UnionAlphabet with mismatching " *
              "number of `metaconditions` and `thresholds` " *
              "($(metaconditions) != $(thresholds)).")
    alphabets = UnivariateScalarAlphabet.(zip(metaconditions, thresholds))
    UnionAlphabet(alphabets)
end

function BoundedScalarConditions(
    features::AbstractVector,
    test_operators::AbstractVector,
    thresholds::Vector
)
    @warn "This function is deprecating."
    metaconditions = [ScalarMetaCondition(f, t) for f in features for t in test_operators]
    UnionAlphabet(metaconditions, thresholds)
end

const UnivariateSymbolValue = VariableValue
const UnivariateValue = VariableValue

# # https://github.com/garrison/UniqueVectors.jl/issues/24
# function Base.in(item, uv::UniqueVector)
#     @warn "Base.in(::$(typeof(item)), ::$(typeof(uv))) is defined by type piracy from UniqueVectors.jl. This method is deprecating."
#     haskey(uv.lookup, item)
# end
# function Base.findfirst(p::UniqueVectors.EqualTo, uv::UniqueVector)
#     @warn "Base.findfirst(::$(typeof(p)), ::$(typeof(uv))) is defined by type piracy from UniqueVectors.jl. This method is deprecating."
#     get(uv.lookup, p.x, nothing)
# end
