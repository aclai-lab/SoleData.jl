import SoleData: AbstractFeature

using MultiData: instance_channel

import Base: show
import SoleLogics: syntaxstring

# Feature parentheses (e.g., for parsing/showing "main[V2]")
const UVF_OPENING_PARENTHESIS = "["
const UVF_CLOSING_PARENTHESIS = "]"
# Default prefix for variables
const UVF_VARPREFIX = "V"

"""
    abstract type VarFeature <: AbstractFeature end

Abstract type for feature functions that can be computed on (multi)variate data.
Instances of multivariate datasets have values for a number of *variables*,
which can be used to define logical features.

For example, with dimensional data (e.g., multivariate time series, digital images
and videos), features can be computed as the minimum value for a given variable
on a specific interval/rectangle/cuboid (in general, a [`SoleLogics.GeometricalWorld`](@ref)).

As an example of a dimensional feature, consider *min[V1]*,
which computes the minimum for variable 1 for a given world.
`ScalarCondition`s such as *min[V1] >= 10* can be, then, evaluated on worlds.

See also
[`scalarlogiset`](@ref),
[`featvaltype`](@ref),
[`computefeature`](@ref),
[`SoleLogics.Interval`](@ref).
"""
abstract type VarFeature <: AbstractFeature end

const VariableId = Union{Integer,Symbol}
const VariableName = Union{String,Symbol}

DEFAULT_VARFEATVALTYPE = Real

"""
    featvaltype(dataset, f::VarFeature)

Return the type of the values returned by feature `f` on logiseed `dataset`.

See also [`VarFeature`](@ref).
"""
function featvaltype(dataset, f::VarFeature)
    return error("Please, provide method featvaltype(::$(typeof(dataset)), ::$(typeof(f))).")
end

"""
    computefeature(f::VarFeature, featchannel; kwargs...)

Compute a feature on a featchannel (i.e., world reading) of an instance.

See also [`VarFeature`](@ref).
"""
function computefeature(f::VarFeature, featchannel; kwargs...)
    return error("Please, provide method computefeature(::$(typeof(f)), featchannel::$(typeof(featchannel)); kwargs...).")
end


@inline (f::AbstractFeature)(args...) = computefeature(f, args...)

############################################################################################

"""
    struct MultivariateFeature{U} <: VarFeature
        f::Function
    end

A dimensional feature represented by the application of a function to a dimensional channel.
For example, it can wrap a scalar function computing
how much a `Interval2D` world, when interpreted on an image, resembles a horse.
Note that the image has a number of spatial variables (3, for the case of RGB),
and "resembling a horse" may require a computation involving all variables.

See also [`SoleLogics.Interval`](@ref),
[`SoleLogics.Interval2D`](@ref),
[`AbstractUnivariateFeature`](@ref),
[`VarFeature`](@ref), [`AbstractFeature`](@ref).
"""
struct MultivariateFeature{U} <: VarFeature
    f::Function
end
syntaxstring(f::MultivariateFeature, args...; kwargs...) = "$(f.f)"

function featvaltype(dataset, f::MultivariateFeature{U}) where {U}
    return U
end

############################################################################################

"""
    abstract type AbstractUnivariateFeature <: VarFeature end

A dimensional feature represented by the application of a function to a single variable of a
dimensional channel.
For example, it can wrap a scalar function computing
how much red a `Interval2D` world, when interpreted on an image, contains.

See also [`SoleLogics.Interval`](@ref),
[`SoleLogics.Interval2D`](@ref),
[`UnivariateFeature`](@ref),
[`VarFeature`](@ref), [`AbstractFeature`](@ref).
"""
abstract type AbstractUnivariateFeature <: VarFeature end

"""
    computeunivariatefeature(f::AbstractUnivariateFeature, varchannel; kwargs...)

Compute a feature on a variable channel (i.e., world reading) of an instance.

See also [`AbstractUnivariateFeature`](@ref).
"""
function computeunivariatefeature(f::AbstractUnivariateFeature, varchannel::Any; kwargs...)
    return error("Please, provide method computeunivariatefeature(::$(typeof(f)), varchannel::$(typeof(varchannel)); kwargs...).")
end

i_variable(f::AbstractUnivariateFeature) = f.i_variable

function computefeature(f::AbstractUnivariateFeature, featchannel::Any)
    computeunivariatefeature(f, instance_channel(featchannel, i_variable(f)))
end

"""
    variable_name(
        f::AbstractUnivariateFeature;
        variable_names_map::Union{Nothing,AbstractDict,AbstractVector} = nothing,
        variable_name_prefix::Union{Nothing,String} = $(repr(UVF_VARPREFIX)),
    )::String

Return the name of the variable targeted by a univariate feature.
By default, an variable name is a number prefixed by $(repr(UVF_VARPREFIX));
however, `variable_names_map` or `variable_name_prefix` can be used to
customize variable names.
The prefix can be customized by specifying `variable_name_prefix`.
Alternatively, a mapping from string to integer (either via a Dictionary or a Vector)
can be passed as `variable_names_map`.
Note that only one in `variable_names_map` and `variable_name_prefix` should be provided.


See also
[`parsecondition`](@ref),
[`ScalarCondition`](@ref),
[`syntaxstring`](@ref).
"""
function variable_name(
    f::AbstractUnivariateFeature;
    variable_names_map::Union{Nothing,AbstractDict,AbstractVector} = nothing,
    variable_name_prefix::Union{Nothing,String} = nothing,
    kwargs..., # TODO remove this.
)
    i_var = i_variable(f)
    if isnothing(variable_names_map)
        variable_name_prefix = isnothing(variable_name_prefix) ? UVF_VARPREFIX : variable_name_prefix
        i_var isa Integer ? "$(variable_name_prefix)$(i_var)" : "$(i_var)"
    else
        if i_var isa Integer
            i_var =i_var
        elseif i_var isa Symbol
            i_var = findfirst(v->occursin(string(i_var), string(v)), variable_names_map)
        end
        if !(i_var in keys(variable_names_map))
            @warn "Could not find variable $i_var in `variable_names_map`. ($(@show variable_names_map))"
            variable_name_prefix = isnothing(variable_name_prefix) ? UVF_VARPREFIX : variable_name_prefix
            i_var isa Integer ? "?$(variable_name_prefix)$(i_var)?" : "?$(i_var)?"
        else
            "$(variable_names_map[i_var])"
        end
    end
end

function featurename(f::AbstractFeature; kwargs...)
    return error("Please, provide method featurename(::$(typeof(f)); kwargs...).")
end

function syntaxstring(
    f::AbstractUnivariateFeature;
    opening_parenthesis::String = UVF_OPENING_PARENTHESIS,
    closing_parenthesis::String = UVF_CLOSING_PARENTHESIS,
    kwargs...
)
    n = variable_name(f; kwargs...)
    "$(featurename(f))$opening_parenthesis$n$closing_parenthesis"
end

############################################################################################

"""
    struct UnivariateFeature{U,I<:VariableId} <: AbstractUnivariateFeature
        i_variable::I
        f::Function
        fname::Union{Nothing,String}
    end

A dimensional feature represented by the application of a generic function `f`
to a single variable of a dimensional channel.
For example, it can wrap a scalar function computing
how much red a `Interval2D` world, when interpreted on an image, contains.
Optionally, a feature name `fname` can be attached to the function,
which can be useful for inspection (e.g., if `f` is an anonymous function, this avoids
names such s "#47" or "#49".

See also [`SoleLogics.Interval`](@ref),
[`SoleLogics.Interval2D`](@ref),
[`AbstractUnivariateFeature`](@ref),
[`VarFeature`](@ref), [`AbstractFeature`](@ref).
"""
struct UnivariateFeature{U,I<:VariableId} <: AbstractUnivariateFeature
    i_variable::I
    f::Function
    fname::Union{Nothing,String}
    function UnivariateFeature{U}(feat::UnivariateFeature) where {U<:Real}
        return UnivariateFeature{U}(i_variable(f), feat.f, feat.fname)
    end
    function UnivariateFeature{U}(i_variable::I, f::Function, fname::Union{Nothing,String} = nothing) where {U<:Real,I<:VariableId}
        return new{U,I}(i_variable, f, fname)
    end
    function UnivariateFeature(i_variable::I, f::Function, fname::Union{Nothing,String} = nothing) where {I<:VariableId}
        return new{DEFAULT_VARFEATVALTYPE,I}(i_variable, f, fname)
    end
end
featurename(f::UnivariateFeature) = (!isnothing(f.fname) ? f.fname : string(f.f))

function featvaltype(dataset, f::UnivariateFeature{U}) where {U}
    return U
end

"""
    struct UnivariateNamedFeature{U<:Real,I<:VariableId} <: AbstractUnivariateFeature
        i_variable::I
        name::VariableName
    end

A univariate feature solely identified by its name and reference variable.

See also [`SoleLogics.Interval`](@ref),
[`SoleLogics.Interval2D`](@ref),
[`AbstractUnivariateFeature`](@ref),
[`VarFeature`](@ref), [`AbstractFeature`](@ref).
"""
struct UnivariateNamedFeature{U,I<:VariableId} <: AbstractUnivariateFeature
    i_variable::I
    name::VariableName
    function UnivariateNamedFeature{U}(f::UnivariateNamedFeature) where {U<:Real}
        return UnivariateNamedFeature{U}(i_variable(f), f.name)
    end
    function UnivariateNamedFeature{U}(i_variable::I, name::VariableName) where {U<:Real,I<:VariableId}
        return new{U,I}(i_variable, name)
    end
    function UnivariateNamedFeature(i_variable::I, name::VariableName) where {I<:VariableId}
        return new{DEFAULT_VARFEATVALTYPE,I}(i_variable, name)
    end
end
featurename(f::UnivariateNamedFeature) = f.name

function syntaxstring(
    f::UnivariateNamedFeature;
    opening_parenthesis::String = UVF_OPENING_PARENTHESIS,
    closing_parenthesis::String = UVF_CLOSING_PARENTHESIS,
    kwargs...
)
    n = f.name
    "$opening_parenthesis$n$closing_parenthesis"
end

function featvaltype(dataset, f::UnivariateNamedFeature{U}) where {U}
    return U
end

############################################################################################

"""
    struct VariableValue{I<:VariableId, N<:Union{VariableName, Nothing}} <: AbstractUnivariateFeature
        i_variable::I
        i_name::N
    end

A simple feature, equal the value of a scalar variable and, optionally, its name.

See also [`SoleLogics.Interval`](@ref),
[`SoleLogics.Interval2D`](@ref),
[`AbstractUnivariateFeature`](@ref),
[`VarFeature`](@ref), [`AbstractFeature`](@ref).
"""
struct VariableValue{I<:VariableId, N<:Union{VariableName, Nothing}} <: AbstractUnivariateFeature
    i_variable::I
    i_name::N
    function VariableValue(f::VariableValue)
        return VariableValue(i_variable(f))
    end
    function VariableValue(i_variable::I) where {I<:VariableId}
        return new{I, Nothing}(i_variable, nothing)
    end
    function VariableValue(i_variable::I, i_name::N) where {I<:VariableId, N<:VariableName}
        return new{I,N}(i_variable, i_name)
    end
end
featurename(f::VariableValue) = !isnothing(f.i_name) ? f.i_name : "V$(f.i_variable)"

function syntaxstring(f::VariableValue; variable_names_map = nothing, show_colon = false, kwargs...)
    if !isnothing(f.i_name)
        opening_parenthesis = UVF_OPENING_PARENTHESIS
        closing_parenthesis = UVF_CLOSING_PARENTHESIS
        n = f.i_name
        return "$opening_parenthesis$n$closing_parenthesis"
    end

    if i_variable(f) isa Integer || !isnothing(variable_names_map)
        variable_name(f; variable_names_map = variable_names_map, kwargs...)
    else
        show_colon ? repr(i_variable(f)) : string(i_variable(f))
    end
end

function featvaltype(dataset, f::VariableValue)
    return vareltype(dataset, f.i_variable)
end

############################################################################################

"""
    struct VariableMin{I<:VariableId} <: AbstractUnivariateFeature
        i_variable::I
    end

Notable univariate feature computing the minimum value for a given variable.

See also [`SoleLogics.Interval`](@ref),
[`SoleLogics.Interval2D`](@ref),
[`AbstractUnivariateFeature`](@ref),
[`VariableMax`](@ref),
[`VarFeature`](@ref), [`AbstractFeature`](@ref).
"""
struct VariableMin{I<:VariableId} <: AbstractUnivariateFeature
    i_variable::I
    function VariableMin(f::VariableMin)
        return VariableMin(i_variable(f))
    end
    function VariableMin(i_variable::I) where {I<:VariableId}
        return new{I}(i_variable)
    end
end
featurename(f::VariableMin) = "min"

function featvaltype(dataset, f::VariableMin)
    return vareltype(dataset, f.i_variable)
end

"""
    struct VariableMax{I<:VariableId} <: AbstractUnivariateFeature
        i_variable::I
    end

Notable univariate feature computing the maximum value for a given variable.

See also [`SoleLogics.Interval`](@ref),
[`SoleLogics.Interval2D`](@ref),
[`AbstractUnivariateFeature`](@ref),
[`VariableMin`](@ref),
[`VarFeature`](@ref), [`AbstractFeature`](@ref).
"""
struct VariableMax{I<:VariableId} <: AbstractUnivariateFeature
    i_variable::I
    function VariableMax(f::VariableMax)
        return VariableMax(i_variable(f))
    end
    function VariableMax(i_variable::I) where {I<:VariableId}
        return new{I}(i_variable)
    end
end
featurename(f::VariableMax) = "max"

function featvaltype(dataset, f::VariableMax)
    return vareltype(dataset, f.i_variable)
end

############################################################################################

"""
    struct VariableSoftMin{T<:AbstractFloat,I<:VariableId} <: AbstractUnivariateFeature
        i_variable::I
        alpha::T
    end

Univariate feature computing a "softened" version of the minimum value for a given variable.

See also [`SoleLogics.Interval`](@ref),
[`SoleLogics.Interval2D`](@ref),
[`AbstractUnivariateFeature`](@ref),
[`VariableMin`](@ref),
[`VarFeature`](@ref), [`AbstractFeature`](@ref).
"""
struct VariableSoftMin{T<:AbstractFloat,I<:VariableId} <: AbstractUnivariateFeature
    i_variable::I
    alpha::T
    function VariableSoftMin(f::VariableSoftMin)
        return VariableSoftMin(i_variable(f), alpha(f))
    end
    function VariableSoftMin(i_variable::I, alpha::T) where {T,I<:VariableId}
        @assert !(alpha > 1.0 || alpha < 0.0) "Cannot instantiate VariableSoftMin with alpha = $(alpha)"
        @assert !isone(alpha) "Cannot instantiate VariableSoftMin with alpha = $(alpha). Use VariableMin instead!"
        new{T,I}(i_variable, alpha)
    end
end
alpha(f::VariableSoftMin) = f.alpha
featurename(f::VariableSoftMin) = "min" * SoleBase.subscriptnumber(rstrip(rstrip(string(alpha(f)*100), '0'), '.'))

function featvaltype(dataset, f::VariableSoftMin)
    return vareltype(dataset, f.i_variable)
end

"""
    struct VariableSoftMax{T<:AbstractFloat,I<:VariableId} <: AbstractUnivariateFeature
        i_variable::I
        alpha::T
    end

Univariate feature computing a "softened" version of the maximum value for a given variable.

See also [`SoleLogics.Interval`](@ref),
[`SoleLogics.Interval2D`](@ref),
[`AbstractUnivariateFeature`](@ref),
[`VariableMax`](@ref),
[`VarFeature`](@ref), [`AbstractFeature`](@ref).
"""
struct VariableSoftMax{T<:AbstractFloat,I<:VariableId} <: AbstractUnivariateFeature
    i_variable::I
    alpha::T
    function VariableSoftMax(f::VariableSoftMax)
        return VariableSoftMax(i_variable(f), alpha(f))
    end
    function VariableSoftMax(i_variable::I, alpha::T) where {T,I<:VariableId}
        @assert !(alpha > 1.0 || alpha < 0.0) "Cannot instantiate VariableSoftMax with alpha = $(alpha)"
        @assert !isone(alpha) "Cannot instantiate VariableSoftMax with alpha = $(alpha). Use VariableMax instead!"
        new{T,I}(i_variable, alpha)
    end
end
alpha(f::VariableSoftMax) = f.alpha
featurename(f::VariableSoftMax) = "max" * SoleBase.subscriptnumber(rstrip(rstrip(string(alpha(f)*100), '0'), '.'))

function featvaltype(dataset, f::VariableSoftMax)
    return vareltype(dataset, f.i_variable)
end

############################################################################################

"""
    struct VariableAvg{I<:VariableId} <: AbstractUnivariateFeature
        i_variable::I
    end

Univariate feature computing the average value for a given variable.

See also [`SoleLogics.Interval`](@ref),
[`SoleLogics.Interval2D`](@ref),
[`AbstractUnivariateFeature`](@ref),
[`VariableMax`](@ref), [`VariableMin`](@ref),
[`VarFeature`](@ref), [`AbstractFeature`](@ref).
"""
struct VariableAvg{I<:VariableId} <: AbstractUnivariateFeature
    i_variable::I
    function VariableAvg(f::VariableAvg)
        return VariableAvg(i_variable(f))
    end
    function VariableAvg(i_variable::I) where {I<:VariableId}
        return new{I}(i_variable)
    end
end
featurename(f::VariableAvg) = "avg"

function featvaltype(dataset, f::VariableAvg)
    return vareltype(dataset, f.i_variable)
end

############################################################################################

"""
    struct VariableDistance{I<:VariableId,T} <: AbstractUnivariateFeature
        i_variable::I
        references::Vector{<:T}
        distance::Function
        featurename::VariableName
    end

Univariate feature computing a distance function for a given variable, with respect to all

By default, `distance` is set to be Euclidean distance and the lowest result is considered.

# Examples
```julia
# we only want to perform comparisons with one important representative signal;
# we call such signal a reference, and encapsulate it within an array.
julia> vd = VariableDistance(1, [[1,2,3,4]]; featurename="StrictMonotonicAscending");

julia> syntaxstring(vd)
"StrictMonotonicAscending[V1]"

# compute the distance (euclidean by default) with the given signal
julia> computeunivariatefeature(vd, [1,2,3,4])
0.0

julia> computeunivariatefeature(vd, [2,3,4,5])
2.0

# now we consider multiple references
julia> vd = VariableDistance(1, [
        [0.1,1.8,3.0,3.2],
        [1.1,1.3,2.3,3.8],
        [0.8,1.4,2.5,4.1]
    ];
    featurename="StrictMonotonicAscending"
);

# return only the minimum distance w.r.t. all the references wrapped within vd
julia> computeunivariatefeature(vd, [1,2,3,4])
0.812403840463596

# we ask for the size of a generic reference
julia> refsize(vd)
(4,)

```

See also [`SoleLogics.Interval`](@ref),
[`SoleLogics.Interval2D`](@ref),
[`AbstractUnivariateFeature`](@ref),
[`VariableMax`](@ref), [`VariableMin`](@ref),
[`VarFeature`](@ref), [`AbstractFeature`](@ref).
"""
struct VariableDistance{I<:VariableId,T} <: AbstractUnivariateFeature
    i_variable::I
    references::AbstractArray{T}
    distance::Function
    featurename::VariableName

    function VariableDistance(
        i_variable::I,
        references::AbstractArray{T};
        # euclidean distance, but with no Distances.jl dependency
        distance::Function=(x,y) -> sqrt(sum([(x - y)^2 for (x, y) in zip(x,y)])),
        featurename = "Δ"
    ) where {I<:VariableId,T}
        if any(r -> size(r) != size(references |> first), references)
            throw(DimensionMismatch("References' sizes are not unique."))
        end

        return new{I,T}(i_variable, references, distance, featurename)
    end
end
featurename(f::VariableDistance) = string(f.featurename)

references(f::VariableDistance) = f.references

refsize(f::VariableDistance) = references(f) |> first |> size

distance(f::VariableDistance) = f.distance

function featvaltype(dataset, f::VariableDistance)
    return vareltype(dataset, f.i_variable)
end

############################################################################################

# These features collapse to a single value; it can be useful to know this
is_collapsing_univariate_feature(f::Union{VariableMin,VariableMax,VariableSoftMin,VariableSoftMax,VariableDistance}) = true
is_collapsing_univariate_feature(f::UnivariateFeature) = (f.f in [minimum, maximum, mean])


_st_featop_abbr(f::VariableMin,     ::typeof(≥); kwargs...) = "$(variable_name(f; kwargs...)) ⪰"
_st_featop_abbr(f::VariableMax,     ::typeof(≤); kwargs...) = "$(variable_name(f; kwargs...)) ⪯"
_st_featop_abbr(f::VariableSoftMin, ::typeof(≥); kwargs...) = "$(variable_name(f; kwargs...)) $("⪰" * SoleBase.subscriptnumber(rstrip(rstrip(string(alpha(f)*100), '0'), '.')))"
_st_featop_abbr(f::VariableSoftMax, ::typeof(≤); kwargs...) = "$(variable_name(f; kwargs...)) $("⪯" * SoleBase.subscriptnumber(rstrip(rstrip(string(alpha(f)*100), '0'), '.')))"

_st_featop_abbr(f::VariableMin,     ::typeof(<); kwargs...) = "$(variable_name(f; kwargs...)) ↓"
_st_featop_abbr(f::VariableMax,     ::typeof(>); kwargs...) = "$(variable_name(f; kwargs...)) ↑"
_st_featop_abbr(f::VariableSoftMin, ::typeof(<); kwargs...) = "$(variable_name(f; kwargs...)) $("↓" * SoleBase.subscriptnumber(rstrip(rstrip(string(alpha(f)*100), '0'), '.')))"
_st_featop_abbr(f::VariableSoftMax, ::typeof(>); kwargs...) = "$(variable_name(f; kwargs...)) $("↑" * SoleBase.subscriptnumber(rstrip(rstrip(string(alpha(f)*100), '0'), '.')))"

_st_featop_abbr(f::VariableMin,     ::typeof(≤); kwargs...) = "$(variable_name(f; kwargs...)) ⤓"
_st_featop_abbr(f::VariableMax,     ::typeof(≥); kwargs...) = "$(variable_name(f; kwargs...)) ⤒"
_st_featop_abbr(f::VariableSoftMin, ::typeof(≤); kwargs...) = "$(variable_name(f; kwargs...)) $("⤓" * SoleBase.subscriptnumber(rstrip(rstrip(string(alpha(f)*100), '0'), '.')))"
_st_featop_abbr(f::VariableSoftMax, ::typeof(≥); kwargs...) = "$(variable_name(f; kwargs...)) $("⤒" * SoleBase.subscriptnumber(rstrip(rstrip(string(alpha(f)*100), '0'), '.')))"

_st_featop_abbr(f::VariableMin,     ::typeof(>); kwargs...) = "$(variable_name(f; kwargs...)) ≻"
_st_featop_abbr(f::VariableMax,     ::typeof(<); kwargs...) = "$(variable_name(f; kwargs...)) ≺"
_st_featop_abbr(f::VariableSoftMin, ::typeof(>); kwargs...) = "$(variable_name(f; kwargs...)) $("≻" * SoleBase.subscriptnumber(rstrip(rstrip(string(alpha(f)*100), '0'), '.')))"
_st_featop_abbr(f::VariableSoftMax, ::typeof(<); kwargs...) = "$(variable_name(f; kwargs...)) $("≺" * SoleBase.subscriptnumber(rstrip(rstrip(string(alpha(f)*100), '0'), '.')))"

############################################################################################

import SoleData: parsefeature

using StatsBase

"""
Syntaxstring aliases for standard features, such as "min", "max", "avg".
"""
const BASE_FEATURE_FUNCTIONS_ALIASES = Dict{String,Base.Callable}(
    #
    "minimum" => VariableMin,
    "min"     => VariableMin,
    "maximum" => VariableMax,
    "max"     => VariableMax,
    #
    "avg"     => VariableAvg,
    "mean"    => VariableAvg,
)

"""
    parsefeature(FT::Type{<:VarFeature}, expr::AbstractString; kwargs...)

Parse a [`VarFeature`](@ref) of type `FT` from its [`syntaxstring`](@ref) representation.

# Keyword Arguments
- `featvaltype::Union{Nothing,Type} = nothing`: the feature's featvaltype
    (recommended for some features, e.g., [`UnivariateFeature`](@ref));
- `opening_parenthesis::String = $(repr(UVF_OPENING_PARENTHESIS))`:
    the string signaling the opening of an expression block (e.g., `"min[V2]"`);
- `closing_parenthesis::String = $(repr(UVF_CLOSING_PARENTHESIS))`:
    the string signaling the closing of an expression block (e.g., `"min[V2]"`);
- `additional_feature_aliases = Dict{String,Base.Callable}()`: A dictionary mapping strings to
    callables, useful when parsing custom-made, non-standard features.
    By default, features such as "avg" or "min" are provided for
    (see `SoleData.BASE_FEATURE_FUNCTIONS_ALIASES`);
    note that, in case of clashing `string`s,
    the provided additional aliases will override the standard ones;
- `variable_names_map::Union{Nothing,AbstractDict,AbstractVector} = nothing`:
    mapping from variable name to variable index, useful when parsing from
    `syntaxstring`s with variable names (e.g., `"min[Heart rate]"`);
- `variable_name_prefix::String = $(repr(UVF_VARPREFIX))`:
    prefix used with variable indices (e.g., "$(UVF_VARPREFIX)10").

Note that at most one argument in `variable_names_map` and `variable_name_prefix`
should be provided.

!!! note
    The default parentheses, here, differ from those of [`SoleLogics.parseformula`](@ref),
    since features are typically wrapped into `Atom`s, and `parseformula` does not
    allow parenthesis characters in atoms' `syntaxstring`s.

See also [`VarFeature`](@ref), [`featvaltype`](@ref), [`parsecondition`](@ref).
"""
function parsefeature(
    ::Type{FT},
    expr::AbstractString;
    featvaltype::Union{Nothing,Type} = nothing,
    opening_parenthesis::String = UVF_OPENING_PARENTHESIS,
    closing_parenthesis::String = UVF_CLOSING_PARENTHESIS,
    additional_feature_aliases = Dict{String,Base.Callable}(),
    variable_names_map::Union{Nothing,AbstractDict,AbstractVector} = nothing,
    variable_name_prefix::Union{Nothing,String} = nothing,
    kwargs...
) where {FT<:VarFeature}
    @assert isnothing(variable_names_map) || isnothing(variable_name_prefix) "" *
        "Cannot parse variable with both variable_names_map and variable_name_prefix. " *
        "(expr = $(repr(expr)))"

    @assert length(opening_parenthesis) == 1 || length(closing_parenthesis)
        "Parentheses must be single-character strings! " *
        "$(repr(opening_parenthesis)) and $(repr(closing_parenthesis)) encountered."

    if FT <: VariableValue
        i_variable = tryparse(Int, expr)
        isnothing(i_variable) && (i_variable = Symbol(expr))
        return VariableValue(i_variable)
    elseif FT <: UnivariateNamedFeature
        r = Regex("^(\\d+):(.*)\$")
        slices = match(r, expr)

        # Assert for malformed strings (e.g. "123.4<avg[V189]>250.2")
        @assert !isnothing(slices) && length(slices) == 2 "Could not parse UnivariateNamedFeature " *
            "from expression $(repr(expr))."

        return UnivariateNamedFeature(parse(Int, string(slices[1])), string(slices[2]))
    else

        featdict = merge(BASE_FEATURE_FUNCTIONS_ALIASES, additional_feature_aliases)

        variable_name_prefix = isnothing(variable_name_prefix) &&
            isnothing(variable_names_map) ? UVF_VARPREFIX : variable_name_prefix
        variable_name_prefix = isnothing(variable_name_prefix) ? "" : variable_name_prefix

        r = Regex("^\\s*(\\w+)\\s*\\$(opening_parenthesis)\\s*$(variable_name_prefix)(\\S+)\\s*\\$(closing_parenthesis)\\s*\$")
        slices = match(r, expr)

        # Assert for malformed strings (e.g. "123.4<avg[V189]>250.2")
        if !isnothing(slices) && length(slices) == 2
            slices = string.(slices)
            (_feature, _variable) = (slices[1], slices[2])

            feature = begin
                i_var = begin
                    if isnothing(variable_names_map)
                        parse(Int, _variable)
                    elseif variable_names_map isa Union{AbstractDict,AbstractVector}
                        i_var = findfirst(variable_names_map, variable)
                        @assert !isnothing(i_var) "Could not find variable $variable in the " *
                            "specified map. ($(@show variable_names_map))"
                    else
                        error("Unexpected variable_names_map of type $(typeof(variable_names_map)) " *
                            "encountered.")
                    end
                end
                if haskey(featdict, _feature)
                    # If it is a known feature get it as
                    #  a type (e.g., `VariableMin`), or Julia function (e.g., `minimum`).
                    feat_or_fun = featdict[_feature]
                    # If it is a function, wrap it into a UnivariateFeature
                    #  otherwise, it is a feature, and it is used as a constructor.
                    if feat_or_fun isa Function
                        if isnothing(featvaltype)
                            featvaltype = DEFAULT_VARFEATVALTYPE
                            @warn "Please, specify a type for the feature values (featvaltype = ...). " *
                                "$(featvaltype) will be used, but note that this may raise type errors. " *
                                "(expression = $(repr(expr)))"
                        end

                        UnivariateFeature{featvaltype}(i_var, feat_or_fun)
                    else
                        feat_or_fun(i_var) # TODO do this
                        # feat_or_fun{featvaltype}(i_var)
                    end
                else
                    # If it is not a known feature, interpret it as a Julia function,
                    #  and wrap it into a UnivariateFeature.
                    f = eval(Meta.parse(_feature))
                    if isnothing(featvaltype)
                        featvaltype = DEFAULT_VARFEATVALTYPE
                        @warn "Please, specify a type for the feature values (featvaltype = ...). " *
                            "$(featvaltype) will be used, but note that this may raise type errors. " *
                            "(expression = $(repr(expr)))"
                    end

                    UnivariateFeature{featvaltype}(i_var, f)
                end
            end
            return feature
        end

        r = Regex("^\\s*$(variable_name_prefix)(\\S+)\\s*\$")
        slices = match(r, expr)

        # Assert for malformed strings (e.g. "V189")
        if !isnothing(slices) && length(slices) == 1
            i_variable = slices[1]
            # if isnothing(featvaltype)
            #     featvaltype = DEFAULT_VARFEATVALTYPE
            #     @warn "Please, specify a type for the feature values (featvaltype = ...). " *
            #         "$(featvaltype) will be used, but note that this may raise type errors. " *
            #         "(expression = $(repr(expr)))"
            # end
            # @show VariableValue{featvaltype}
            # @show (parse(Int64, i_variable))
            # return VariableValue{featvaltype}(parse(Int64, i_variable))
            return VariableValue(parse(Int64, i_variable))
        end

        throw(ArgumentError("Could not parse variable feature from expression $(repr(expr))."))

        # if !(feature isa FT)
        #     @warn "Could not parse expression $(repr(expr)) as feature of type $(FT); " *
        #         " $(typeof(feature)) was used."
        # end

        # return feature
    end
end
