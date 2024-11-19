
############################################################################################

"""
    struct ValueCondition{FT<:AbstractFeature} <: AbstractCondition{FT}
        feature::FT
    end

A condition which yields a truth value equal to the value of a feature.

See also [`AbstractFeature`](@ref).
"""
struct ValueCondition{FT<:AbstractFeature} <: AbstractCondition{FT}
    feature::FT
end

checkcondition(c::ValueCondition, args...; kwargs...) = featvalue(c.feature, args...; kwargs...)

syntaxstring(c::ValueCondition; kwargs...) = syntaxstring(c.feature)

function parsecondition(
    ::Type{ValueCondition},
    expr::AbstractString;
    featuretype = Feature,
    kwargs...
)
    ValueCondition(featuretype(expr))
end

############################################################################################

"""
    struct FunctionalCondition{FT<:AbstractFeature} <: AbstractCondition{FT}
        feature::FT
        f::FT
    end

A condition which yields a truth value equal to the value of a function.

See also [`AbstractFeature`](@ref).
"""
struct FunctionalCondition{FT<:AbstractFeature} <: AbstractCondition{FT}
    feature::FT
    f::Function
end

checkcondition(c::FunctionalCondition, args...; kwargs...) = (c.f)(featvalue(c.feature, args...; kwargs...))

syntaxstring(c::FunctionalCondition; kwargs...) = string(c.f, "(", syntaxstring(c.feature), ")")

function parsecondition(
    ::Type{FunctionalCondition},
    expr::AbstractString;
    featuretype = Feature,
    kwargs...
)
    r = Regex("^\\s*(\\w+)\\(\\s*(\\w+)\\s*\\)\\s*\$")
    slices = match(r, expr)

    @assert !isnothing(slices) && length(slices) == 2 "Could not parse FunctionalCondition from " *
        "expression $(repr(expr))."

    slices = string.(slices)

    feature = featuretype(slices[1])
    f = eval(Meta.parse(slices[2]))

    FunctionalCondition(feature, f)
end