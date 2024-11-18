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
    parsefeature(FT::Type{<:AbstractFeature}, expr::AbstractString; kwargs...)

Parse a feature of type `FT` from its [`syntaxstring`](@ref) representation.
Depending on `FT`, specifying
keyword arguments such as `featvaltype::Type` may be required or recommended.

See also [`parsecondition`](@ref).
"""
function parsefeature(
    FT::Type{<:AbstractFeature},
    expr::AbstractString;
    kwargs...
)
    return error("Please, provide method parsefeature(::$(FT), " *
        "expr::$(typeof(expr)); kwargs...).")
end

############################################################################################

import SoleLogics: valuetype

"""
    struct Feature{A} <: AbstractFeature
        atom::A
    end

A feature solely identified by an atom (e.g., a string with its name,
a tuple of strings, etc.)

See also [`AbstractFeature`](@ref).
"""
struct Feature{A} <: AbstractFeature
    atom::A
end

valuetype(::Type{<:Feature{A}}) where {A} = A
valuetype(::Feature{A}) where {A} = A

syntaxstring(f::Feature; kwargs...) = string(f.atom)

function parsefeature(
    ::Type{FT},
    expr::AbstractString;
    kwargs...
) where {FT<:Feature}
    if FT == Feature
        FT(expr)
    else
        FT(parse(valuetype(FT), expr))
    end
end

############################################################################################

"""
    struct ExplicitFeature{T} <: AbstractFeature
        name::String
        featstruct
    end

A feature encoded explicitly, for example, as a slice of
[`DimensionalDatasets.UniformFullDimensionalLogiset`](@ref)'s feature structure.

See also [`AbstractFeature`](@ref).
"""
struct ExplicitFeature{T} <: AbstractFeature
    name::String
    featstruct::T
end
syntaxstring(f::ExplicitFeature; kwargs...) = f.name

############################################################################################
