
using SoleLogics: AbstractAlphabet
using SoleLogics: AbstractInterpretationSet, LogicalInstance
using Random
import SoleLogics: hasdual, dual, atoms
import SoleLogics: check, interpret

import Base: in, isfinite, length

"""
    abstract type AbstractCondition{FT<:AbstractFeature} end

Abstract type for representing conditions that can be interpreted and evaluated
on worlds of instances of a logical dataset. In logical contexts,
these are wrapped into `Atom`s.

See also
[`Atom`](@ref),
[`syntaxstring`](@ref),
[`ScalarMetaCondition`](@ref),
[`ScalarCondition`](@ref).
"""
abstract type AbstractCondition{FT<:AbstractFeature} end

"""
    checkcondition(c::AbstractCondition, args...; kwargs...)

Check a condition (e.g., on a world of a logiset instance).

This function must be implemented for each subtype of `AbstractCondition`.

# Examples

```julia
# Checking a condition on a logiset created from a DataFrame
using SoleData, DataFrames

# Load the iris dataset
iris_df = DataFrame(load_iris());

# Convert the DataFrame to a logiset
iris_logiset = scalarlogiset(iris_df);

# Create a ScalarCondition
condition = ScalarCondition(:sepal_length, >, 5.0);

# Check the condition on the logiset
@assert checkcondition(condition, iris_logiset, 1) == true
```
"""
function checkcondition(c::AbstractCondition, args...; kwargs...)::Bool
    return error("Please, provide method checkcondition(::$(typeof(c)), " *
        join(map(t->"::$(t)", typeof.(args)), ", ") * "; kwargs...). " *
        "Note that this value must be unique.")
end

function syntaxstring(c::AbstractCondition; kwargs...)
    return error("Please, provide method syntaxstring(::$(typeof(c)); kwargs...). " *
        "Note that this value must be unique.")
end

function Base.show(io::IO, c::AbstractCondition)
    # print(io, "Feature of type $(typeof(c))\n\t-> $(syntaxstring(c))")
    print(io, "$(typeof(c)): $(syntaxstring(c))")
    # print(io, "$(syntaxstring(c))")
end

# # This makes sure that, say, a Float64 min[V1] is equal to a Float32 min[V1]
# # Useful, but not exactly correct
# Base.isequal(a::AbstractCondition, b::AbstractCondition) = syntaxstring(a) == syntaxstring(b) # nameof(x) == nameof(feature)
# Base.hash(a::AbstractCondition) = Base.hash(syntaxstring(a))
# TODO remove
Base.isequal(a::AbstractCondition, b::AbstractCondition) = Base.isequal(map(x->getfield(a, x), fieldnames(typeof(a))), map(x->getfield(b, x), fieldnames(typeof(b))))
Base.hash(a::AbstractCondition) = Base.hash(map(x->getfield(a, x), fieldnames(typeof(a))), Base.hash(typeof(a)))

"""
    parsecondition(C::Type{<:AbstractCondition}, expr::AbstractString; kwargs...)

Parse a condition of type `C` from its [`syntaxstring`](@ref) representation.
Depending on `C`, specifying
keyword arguments such as `featuretype::Type{<:AbstractFeature}`,
and `featvaltype::Type` may be required or recommended.

See also [`parsefeature`](@ref).
"""
function parsecondition(
    C::Type{<:AbstractCondition},
    expr::AbstractString;
    kwargs...
)
    return error("Please, provide method parsecondition(::$(Type{C}), expr::$(typeof(expr)); kwargs...).")
end

function check(
    φ::Atom{<:AbstractCondition},
    X::AbstractInterpretationSet;
    kwargs...
)::BitVector
    cond = SoleLogics.value(φ)
    return checkcondition(cond, X; kwargs...)
end

function check(
    φ::Atom{<:AbstractCondition},
    i::LogicalInstance{<:AbstractInterpretationSet},
    args...;
    kwargs...
)::Bool
    # @warn "Attempting single-instance check. This is not optimal."
    X, i_instance = SoleLogics.splat(i)
    cond = SoleLogics.value(φ)
    return checkcondition(cond, X, i_instance, args...; kwargs...)
end

# Note: differently from other parts of the Sole.jl framework, where the opposite is true,
#  here `interpret` depends on `check`,
function interpret(
    φ::Atom{<:AbstractCondition},
    i::LogicalInstance{<:AbstractInterpretationSet},
    args...;
    kwargs...
)::Formula
    # @warn "Please use `check` instead of `interpret` for crisp formulas."
    cond = SoleLogics.value(φ)
    return checkcondition(cond, i, args...; kwargs...) ? ⊤ : ⊥
end