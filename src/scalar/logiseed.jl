using SoleData: AbstractMultiDataset
import SoleData: ninstances, nvariables, nmodalities, eachmodality, displaystructure
import SoleData: instances, concatdatasets

"""
    islogiseed(dataset)::Bool

A logiseed is a dataset that can be converted to a logiset (e.g., via [`scalarlogiset`](@ref)).
If the `dataset` is a unimodal logiseed, the following methods should be defined:

```julia
    islogiseed(::typeof(dataset)) = true
    initlogiset(dataset, features; kwargs...)
    ninstances(dataset)
    nvariables(dataset)
    frame(dataset, i_instance::Integer)
    featvalue(feature::VarFeature, dataset, i_instance::Integer, w::AbstractWorld)
    varnames(dataset)::Union{Nothing,Vector{<:$(VariableId)}}
    vareltype(dataset, i_variable::$(VariableId))
```

If `dataset` is a multimodal logiseed, the following methods should be defined,
while its modalities (iterated via `eachmodality`) should provide the methods above:

```julia
    ismultilogiseed(::typeof(dataset)) = true
    nmodalities(logiseed)
    eachmodality(logiseed)
```

# Examples
## A DataFrame
```julia
julia> using DataFrames; df = DataFrame(rand(150, 4), :auto);


julia> SoleData.islogiseed(df)
true

julia> ninstances(df), nvariables(df)
(150, 4)

julia> SoleData.varnames(df)
4-element Vector{String}:
 "x1"
 "x2"
 "x3"
 "x4"

```

## A `Vector` of multidimensional instances (i.e., instances that are `Array{Number,N}` with `N` ≥ 1, where the last dimension is that of variables)
```julia
julia> X = [rand(4) for i in 1:150];


julia> SoleData.islogiseed(X)
true

julia> ninstances(X), nvariables(X)
(150, 4)

julia> SoleData.varnames(X)
nothing

```

See also [`AbstractLogiset`](@ref), [`scalarlogiset`](@ref).
"""
function islogiseed(dataset)
    false
end
function initlogiset(logiseed, features; kwargs...)
    return error("Please, provide method initlogiset(logiseed::$(typeof(logiseed)), features::$(typeof(features)); kwargs...::$(typeof(kwargs))).")
end
function ninstances(logiseed)
    return error("Please, provide method ninstances(logiseed::$(typeof(logiseed))).")
end
function nvariables(logiseed)
    return error("Please, provide method nvariables(logiseed::$(typeof(logiseed))).")
end
function frame(logiseed, i_instance::Integer)
    return error("Please, provide method frame(logiseed::$(typeof(logiseed)), i_instance::Integer).")
end
function featvalue(feature::AbstractFeature, logiseed, i_instance::Integer, w)
    return error("Please, provide method featvalue(feature::$(typeof(feature)), logiseed::$(typeof(logiseed)), i_instance::Integer, w::$(typeof(w))).")
end
function vareltype(logiseed, i_variable::VariableId)
    return error("Please, provide method vareltype(logiseed::$(typeof(logiseed)), i_variable::VariableId).")
end
function varnames(logiseed)
    return error("Please, provide method varnames(logiseed::$(typeof(logiseed))).")
end

# Helper
function allworlds(
    dataset,
    i_instance::Integer,
    args...;
    kwargs...
)
    @warn "Please, use allworlds(frame(...)) instead of allworlds(...). This sholtcut is deprecating."
    return allworlds(frame(dataset, i_instance, args...; kwargs...))
end

# Multimodal dataset interface

"""
    ismultilogiseed(dataset)::Bool

See [`islogiseed`](@ref).
"""
function ismultilogiseed(dataset)
    false
end
function nmodalities(logiseed)
    return error("Please, provide method nmodalities(logiseed::$(typeof(logiseed))).")
end
function eachmodality(logiseed)
    return error("Please, provide method eachmodality(logiseed::$(typeof(logiseed))).")
end

# Helper
modality(dataset, i_modality) = eachmodality(dataset)[i_modality]

function ismultilogiseed(dataset::MultiLogiset)
    true
end
function ismultilogiseed(dataset::AbstractMultiDataset)
    true
end

function ismultilogiseed(dataset::Union{AbstractVector,Tuple})
    length(dataset) > 0 && all(islogiseed, dataset) # && allequal(ninstances, eachmodality(dataset))
end
function nmodalities(dataset::Union{AbstractVector,Tuple})
    @assert ismultilogiseed(dataset) "$(typeof(dataset))"
    length(dataset)
end
function eachmodality(dataset::Union{AbstractVector,Tuple})
    # @assert ismultilogiseed(dataset) "$(typeof(dataset))"
    dataset
end
function ninstances(dataset::Union{AbstractVector,Tuple})
    @assert ismultilogiseed(dataset) "$(typeof(dataset))"
    ninstances(first(dataset))
end

function instances(
    dataset::Union{AbstractVector,Tuple},
    inds::AbstractVector,
    return_view::Union{Val{true},Val{false}} = Val(false);
    kwargs...
)
    @assert ismultilogiseed(dataset) "$(typeof(dataset))"
    map(modality->instances(modality, inds, return_view; kwargs...), eachmodality(dataset))
end

function concatdatasets(datasets::Union{AbstractVector,Tuple}...)
    @assert all(ismultilogiseed.(datasets)) "$(typeof.(datasets))"
    @assert allequal(nmodalities.(datasets)) "Cannot concatenate multilogiseed's of type ($(typeof.(datasets))) with mismatching " *
        "number of modalities: $(nmodalities.(datasets))"
    out = [concatdatasets([modality(dataset, i_mod) for dataset in datasets]...) for i_mod in 1:nmodalities(first(datasets))]
    if eltype(datasets) <: Tuple
        out = Tuple(out)
    end
    out
end

function displaystructure(dataset; indent_str = "", include_ninstances = true, kwargs...)
    if ismultilogiseed(dataset)
        pieces = []
        push!(pieces, "multilogiseed with $(nmodalities(dataset)) modalities ($(humansize(dataset)))")
        # push!(pieces, indent_str * "├ # modalities:\t$(nmodalities(dataset))")
        if include_ninstances
            push!(pieces, indent_str * "├ # instances:\t$(ninstances(dataset))")
        end
        # push!(pieces, indent_str * "├ modalitytype:\t$(modalitytype(dataset))")
        for (i_modality, mod) in enumerate(eachmodality(dataset))
            out = ""
            if i_modality == nmodalities(dataset)
                out *= "$(indent_str)└"
            else
                out *= "$(indent_str)├"
            end
            out *= "{$i_modality} "
            # \t\t\t$(humansize(mod))\t(worldtype: $(worldtype(mod)))"
            out *= displaystructure(mod; indent_str = indent_str * (i_modality == nmodalities(dataset) ? "  " : "│ "), include_ninstances = false, kwargs...)
            push!(pieces, out)
        end
        return join(pieces, "\n")
    elseif islogiseed(dataset)
        return "logiseed ($(humansize(dataset)))\n$(dataset)" |> x->"$(replace(x, "\n"=>"$(indent_str)\n"))\n"
    else
        return "?? dataset of type $(typeof(dataset)) ($(humansize(dataset))) ??\n$(dataset)\n" |> x->"$(replace(x, "\n"=>"$(indent_str)\n"))\n"
    end
end
