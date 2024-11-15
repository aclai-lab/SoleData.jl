import Base: isequal, hash, show
import SoleLogics: syntaxstring

"""
    abstract type AbstractFeature end

Abstract type for features of worlds of
[Kripke structures](https://en.wikipedia.org/wiki/Kripke_structure_(model_checking).

See also [`VarFeature`](@ref), [`featvaltype`](@ref), [`SoleLogics.AbstractWorld`](@ref).
"""
abstract type AbstractFeature end

function syntaxstring(f::AbstractFeature; kwargs...)
    return error("Please, provide method syntaxstring(::$(typeof(f)); kwargs...)."
        # * " Note that this value must be unique."
    )
end

function Base.show(io::IO, f::AbstractFeature)
    # print(io, "Feature of type $(typeof(f))\n\t-> $(syntaxstring(f))")
    print(io, "$(typeof(f)): $(syntaxstring(f))")
    # print(io, "$(syntaxstring(f))")
end

# Note this is necessary when wrapping lambda functions or closures:
# f = [UnivariateFeature(1, x->[1.,2.,3.][i]) for i in 1:3] |> unique
# map(x->SoleData.computefeature(x, rand(1,2)), f)
Base.isequal(a::AbstractFeature, b::AbstractFeature) = Base.isequal(map(x->getfield(a, x), fieldnames(typeof(a))), map(x->getfield(b, x), fieldnames(typeof(b))))
Base.hash(a::AbstractFeature) = Base.hash(map(x->getfield(a, x), fieldnames(typeof(a))), Base.hash(typeof(a)))

# Base.isequal(a::AbstractFeature, b::AbstractFeature) = syntaxstring(a) == syntaxstring(b)
# Base.hash(a::AbstractFeature) = Base.hash(syntaxstring(a))


"""
    parsefeature(FT::Type{<:AbstractFeature}, expr::String; kwargs...)

Parse a feature of type `FT` from its [`syntaxstring`](@ref) representation.
Depending on `FT`, specifying
keyword arguments such as `featvaltype::Type` may be required or recommended.

See also [`parsecondition`](@ref).
"""
function parsefeature(
    FT::Type{<:AbstractFeature},
    expr::String;
    kwargs...
)
    return error("Please, provide method parsefeature(::$(FT), " *
        "expr::$(typeof(expr)); kwargs...).")
end
