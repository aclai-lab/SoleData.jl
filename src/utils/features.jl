
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
    expr::String;
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
