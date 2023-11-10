
# -------------------------------------------------------------
# LabeledMultiModalDataset - utils

"""
    nlabelingvariables(lmd)

Return the number of labeling variables of a labeled multimodal dataset.
"""
function nlabelingvariables(lmd::AbstractLabeledMultiModalDataset)
    return length(labeling_variables(lmd))
end

"""
    labels(lmd, i_instance)
    labels(lmd)

Return the labels of instance at index `i_instance` in a labeled multimodal dataset.
A dictionary of type `labelname => value` is returned.

If only the first argument is passed then the labels for all instances are returned.
"""
function labels(lmd::AbstractLabeledMultiModalDataset)
    return Symbol.(names(data(lmd)))[labeling_variables(lmd)]
end
function labels(lmd::AbstractLabeledMultiModalDataset, i_instance::Integer)
    return Dict{Symbol,Any}([var => data(lmd)[i_instance,var] for var in labels(lmd)]...)
end

"""
    label(lmd, j, i)

Return the value of the `i`-th labeling variable for instance
at index `i_instance` in a labeled multimodal dataset.
"""
function label(
    lmd::AbstractLabeledMultiModalDataset,
    i_instance::Integer,
    i::Integer
)
    return labels(lmd, i_instance)[
        variables(data(lmd))[labeling_variables(lmd)[i]]
    ]
end

"""
    labeldomain(lmd, i)

Return the domain of `i`-th label of a labeled multimodal dataset.
"""
function labeldomain(lmd::AbstractLabeledMultiModalDataset, i::Integer)
    @assert 1 ≤ i ≤ nlabelingvariables(lmd) "Index ($i) must be a valid label number " *
        "(1:$(nlabelingvariables(lmd)))"

    if eltype(ScientificTypes.scitype(data(lmd)[:,labeling_variables(lmd)[i]])) <: Continuous
        return extrema(data(lmd)[:,labeling_variables(lmd)[i]])
    else
        return Set(data(lmd)[:,labeling_variables(lmd)[i]])
    end
end

"""
    setaslabeling!(lmd, i)
    setaslabeling!(lmd, var_name)

Set `i`-th variable as label.

The variable name can be passed as second argument instead of its index.
"""
function setaslabeling!(lmd::AbstractLabeledMultiModalDataset, i::Integer)
    @assert 1 ≤ i ≤ nvariables(lmd) "Index ($i) must be a valid variable number " *
        "(1:$(nvariables(lmd)))"

    @assert !(i in labeling_variables(lmd)) "Variable at index $(i) is already a label."

    push!(labeling_variables(lmd), i)

    return lmd
end
function setaslabeling!(lmd::AbstractLabeledMultiModalDataset, var_name::Symbol)
    @assert hasvariables(lmd, var_name) "LabeldMultiModalDataset does not contain " *
        "variable $(var_name)"

    return setaslabeling!(lmd, _name2index(lmd, var_name))
end

"""
    unsetaslabeling!(lmd, i)
    unsetaslabeling!(lmd, var_name)

Remove `i`-th labeling variable from labels list.

The variable name can be passed as second argument instead of its index.
"""
function unsetaslabeling!(lmd::AbstractLabeledMultiModalDataset, i::Integer)
    @assert 1 ≤ i ≤ nvariables(lmd) "Index ($i) must be a valid variable number " *
        "(1:$(nvariables(lmd)))"

    @assert i in labeling_variables(lmd) "Variable at index $(i) is not a label."

    deleteat!(labeling_variables(lmd), indexin(i, labeling_variables(lmd))[1])

    return lmd
end
function unsetaslabeling!(lmd::AbstractLabeledMultiModalDataset, var_name::Symbol)
    @assert hasvariables(lmd, var_name) "LabeledMultiModalDataset does not contain " *
        "variable $(var_name)"

    return unsetaslabeling!(lmd, _name2index(lmd, var_name))
end

"""
    joinlabels!(lmd, [lbls...]; delim = "_")

On a labeled multimodal dataset, collapse the labeling variables identified by `lbls`
into a single labeling variable of type `String`, by means of a `join` that uses `delim`
for string delimiter.

If not specified differently this function will join all labels.

`lbls` can be an `Integer` indicating the index of the label, or a `Symbol`
indicating the name of the labeling variable.

# !!! note
#     The resulting labels will always be of type `String`.

!!! note
    The resulting labeling variable will always be added as last column in the underlying `DataFrame`.

# Examples

```julia-repl
julia> lmd = LabeledMultiModalDataset(
           MultiModalDataset(
               [[2],[4]],
               DataFrame(
                   :id => [1, 2],
                   :age => [30, 9],
                   :name => ["Python", "Julia"],
                   :stat => [[sin(i) for i in 1:50000], [cos(i) for i in 1:50000]]
               )
           ),
           [1, 3],
       )
● LabeledMultiModalDataset
   ├─ labels
   │   ├─ id: Set([2, 1])
   │   └─ name: Set(["Julia", "Python"])
   └─ dimensionalities: (0, 1)
- Modality 1 / 2
   └─ dimensionality: 0
2×1 SubDataFrame
 Row │ age
     │ Int64
─────┼───────
   1 │    30
   2 │     9
- Modality 2 / 2
   └─ dimensionality: 1
2×1 SubDataFrame
 Row │ stat
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…
   2 │ [0.540302, -0.416147, -0.989992,…


julia> joinlabels!(lmd)
● LabeledMultiModalDataset
   ├─ labels
   │   └─ id_name: Set(["1_Python", "2_Julia"])
   └─ dimensionalities: (0, 1)
- Modality 1 / 2
   └─ dimensionality: 0
2×1 SubDataFrame
 Row │ age
     │ Int64
─────┼───────
   1 │    30
   2 │     9
- Modality 2 / 2
   └─ dimensionality: 1
2×1 SubDataFrame
 Row │ stat
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…
   2 │ [0.540302, -0.416147, -0.989992,…
```
"""
function joinlabels!(
    lmd::AbstractLabeledMultiModalDataset,
    lbls::Symbol... = labels(lmd)...;
    delim::Union{<:AbstractString,<:AbstractChar} = '_'
)
    for l in lbls
        unsetaslabeling!(lmd, l)
    end

    new_col_name = Symbol(join(lbls, delim))
    new_vals = [join(data(lmd)[i,collect(lbls)], delim) for i in 1:ninstances(lmd)]

    dropvariables!(lmd, collect(lbls))
    insertvariables!(lmd, new_col_name, new_vals)
    setaslabeling!(lmd, nvariables(lmd))

    return lmd
end
function joinlabels!(
    lmd::AbstractLabeledMultiModalDataset,
    labels::Integer...;
    kwargs...
)
    return joinlabels!(lmd, labels(lmd)[[labels...]]; kwargs...)
end
