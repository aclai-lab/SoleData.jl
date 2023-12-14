

# -------------------------------------------------------------
# LabeledMultiModalDataset

"""
    LabeledMultiModalDataset(md, labeling_variables)

Create a `LabeledMultiModalDataset` by associating an `AbstractMultiModalDataset` with
some labeling variables, specified as a column index (`Int`)
or a vector of column indices (`Vector{Int}`).

# Arguments

* `md` is the original `AbstractMultiModalDataset`;
* `labeling_variables` is an `AbstractVector` of integers indicating the indices of the
    variables that will be set as labels.

# Examples

```julia-repl
julia> lmd = LabeledMultiModalDataset(MultiModalDataset([[2],[4]], DataFrame(
           :id => [1, 2],
           :age => [30, 9],
           :name => ["Python", "Julia"],
           :stat => [[sin(i) for i in 1:50000], [cos(i) for i in 1:50000]]
       )), [1, 3])
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

```
"""
struct LabeledMultiModalDataset{MD} <: AbstractLabeledMultiModalDataset
    md::MD
    labeling_variables::Vector{Int}

    function LabeledMultiModalDataset{MD}(
        md::MD,
        labeling_variables::Union{Int,AbstractVector},
    ) where {MD<:AbstractMultiModalDataset}
        labeling_variables = Vector{Int}(vec(collect(labeling_variables)))
        for i in labeling_variables
            if _is_variable_in_modalities(md, i)
                # TODO: consider enforcing this instead of just warning
                @warn "Setting as label a variable used in a modality: this is " *
                    "discouraged and probably will not be allowed in future versions"
            end
        end

        return new{MD}(md, labeling_variables)
    end

    function LabeledMultiModalDataset(
        md::MD,
        labeling_variables::Union{Int,AbstractVector},
    ) where {MD<:AbstractMultiModalDataset}
        return LabeledMultiModalDataset{MD}(md, labeling_variables)
    end

    # TODO
    # function LabeledMultiModalDataset(
    #     labeling_variables::AbstractVector{L},
    #     dfs::Union{AbstractVector{DF},Tuple{DF}}
    # ) where {DF<:AbstractDataFrame,L}

    #     return LabeledMultiModalDataset(labeling_variables, MultiModalDataset(dfs))
    # end

    # # Helper
    # function LabeledMultiModalDataset(
    #     labeling_variables::AbstractVector{L},
    #     dfs::AbstractDataFrame...
    # ) where {L}
    #     return LabeledMultiModalDataset(labeling_variables, collect(dfs))
    # end

end

# -------------------------------------------------------------
# LabeledMultiModalDataset - accessors

unlabeleddataset(lmd::LabeledMultiModalDataset) = lmd.md
grouped_variables(lmd::LabeledMultiModalDataset) = grouped_variables(unlabeleddataset(lmd))
data(lmd::LabeledMultiModalDataset) = data(unlabeleddataset(lmd))

labeling_variables(lmd::LabeledMultiModalDataset) = lmd.labeling_variables

# -------------------------------------------------------------
# LabeledMultiModalDataset - informations

function show(io::IO, lmd::LabeledMultiModalDataset)
    println(io, "● LabeledMultiModalDataset")
    _prettyprint_labels(io, lmd)
    _prettyprint_modalities(io, lmd)
    _prettyprint_sparevariables(io, lmd)
end

# -------------------------------------------------------------
# LabeledMultiModalDataset - variables

function sparevariables(lmd::LabeledMultiModalDataset)
    filter!(var -> !(var in labeling_variables(lmd)), sparevariables(unlabeleddataset(lmd)))
end

function dropvariables!(lmd::LabeledMultiModalDataset, i::Integer)
    dropvariables!(unlabeleddataset(lmd), i)

    for (i_lbl, lbl) in enumerate(labeling_variables(lmd))
        if lbl > i
            labeling_variables(lmd)[i_lbl] = lbl - 1
        end
    end

    return lmd
end

# -------------------------------------------------------------
# LabeledMultiModalDataset - utils

function SoleBase.instances(
    lmd::LabeledMultiModalDataset,
    inds::AbstractVector{<:Integer},
    return_view::Union{Val{true},Val{false}} = Val(false)
)
    LabeledMultiModalDataset(
        SoleBase.instances(unlabeleddataset(lmd), inds, return_view),
        labeling_variables(lmd)
    )
end

function vcat(lmds::LabeledMultiModalDataset...)
    LabeledMultiModalDataset(
        vcat(unlabeleddataset.(lmds)...),
        labeling_variables(first(lmds))
    )
end

function _empty(lmd::LabeledMultiModalDataset)
    return LabeledMultiModalDataset(
        _empty(unlabeleddataset(lmd)),
        deepcopy(grouped_variables(lmd)),
    )
end
