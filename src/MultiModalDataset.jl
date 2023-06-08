
# -------------------------------------------------------------
# MultiModalDataset

"""
    MultiModalDataset(grouped_variables, df)

Create a `MultiModalDataset` from a `DataFrame`, `df`, initializing modalities accordingly to
`grouped_variables` parameter.

`grouped_variables` is an `AbstractVector` of modality descriptor which are `AbstractVector`s
of integers representing the index of the variables selected for that modality.

The order matters for both the indices and the variables in them.

```julia-repl
julia> df = DataFrame(
                  :age => [30, 9],
                  :name => ["Python", "Julia"],
                  :stat1 => [[sin(i) for i in 1:50000], [cos(i) for i in 1:50000]],
                  :stat2 => [[cos(i) for i in 1:50000], [sin(i) for i in 1:50000]]
              )
2×4 DataFrame
 Row │ age    name    stat1                              stat2                             ⋯
     │ Int64  String  Array…                             Array…                            ⋯
─────┼──────────────────────────────────────────────────────────────────────────────────────
   1 │    30  Python  [0.841471, 0.909297, 0.14112, -0…  [0.540302, -0.416147, -0.989992,… ⋯
   2 │     9  Julia   [0.540302, -0.416147, -0.989992,…  [0.841471, 0.909297, 0.14112, -0…

julia> md = MultiModalDataset([[2]], df)
● MultiModalDataset
   └─ dimensions: (0,)
- Modality 1 / 1
   └─ dimension: 0
2×1 SubDataFrame
 Row │ name
     │ String
─────┼────────
   1 │ Python
   2 │ Julia
- Spare variables
   └─ dimension: mixed
2×3 SubDataFrame
 Row │ age    stat1                              stat2
     │ Int64  Array…                             Array…
─────┼─────────────────────────────────────────────────────────────────────────────
   1 │    30  [0.841471, 0.909297, 0.14112, -0…  [0.540302, -0.416147, -0.989992,…
   2 │     9  [0.540302, -0.416147, -0.989992,…  [0.841471, 0.909297, 0.14112, -0…
```

    MultiModalDataset(df; group = :none)

Create a `MultiModalDataset` from a `DataFrame`, `df`, automatically selecting modalities.

Selection of modalities can be controlled by the parameter `group` which can be:

- `:none` (default): no modality will be created
- `:all`: all variables will be grouped by their [`dimension`](@ref)
- a list of dimensions which will be grouped.

Note: `:all` and `:none` are the only `Symbol`s accepted by `group`.

# TODO: `:all` should be default parameter value for `group`
# TODO: fix passing a vector of Integer to `group` parameter
# TODO: rewrite examples
## EXAMPLES
```julia-repl
julia> df = DataFrame(
                  :age => [30, 9],
                  :name => ["Python", "Julia"],
                  :stat1 => [[sin(i) for i in 1:50000], [cos(i) for i in 1:50000]],
                  :stat2 => [[cos(i) for i in 1:50000], [sin(i) for i in 1:50000]]
              )
2×4 DataFrame
 Row │ age    name    stat1                              stat2                             ⋯
     │ Int64  String  Array…                             Array…                            ⋯
─────┼──────────────────────────────────────────────────────────────────────────────────────
   1 │    30  Python  [0.841471, 0.909297, 0.14112, -0…  [0.540302, -0.416147, -0.989992,… ⋯
   2 │     9  Julia   [0.540302, -0.416147, -0.989992,…  [0.841471, 0.909297, 0.14112, -0…

julia> md = MultiModalDataset(df)
● MultiModalDataset
   └─ dimensions: ()
- Spare variables
   └─ dimension: mixed
2×4 SubDataFrame
 Row │ age    name    stat1                              stat2                             ⋯
     │ Int64  String  Array…                             Array…                            ⋯
─────┼──────────────────────────────────────────────────────────────────────────────────────
   1 │    30  Python  [0.841471, 0.909297, 0.14112, -0…  [0.540302, -0.416147, -0.989992,… ⋯
   2 │     9  Julia   [0.540302, -0.416147, -0.989992,…  [0.841471, 0.909297, 0.14112, -0…


julia> md = MultiModalDataset(df; group = :all)
● MultiModalDataset
   └─ dimensions: (0, 1)
- Modality 1 / 2
   └─ dimension: 0
2×2 SubDataFrame
 Row │ age    name
     │ Int64  String
─────┼───────────────
   1 │    30  Python
   2 │     9  Julia
- Modality 2 / 2
   └─ dimension: 1
2×2 SubDataFrame
 Row │ stat1                              stat2
     │ Array…                             Array…
─────┼──────────────────────────────────────────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…  [0.540302, -0.416147, -0.989992,…
   2 │ [0.540302, -0.416147, -0.989992,…  [0.841471, 0.909297, 0.14112, -0…


julia> md = MultiModalDataset(df; group = [0])
● MultiModalDataset
   └─ dimensions: (0, 1, 1)
- Modality 1 / 3
   └─ dimension: 0
2×2 SubDataFrame
 Row │ age    name
     │ Int64  String
─────┼───────────────
   1 │    30  Python
   2 │     9  Julia
- Modality 2 / 3
   └─ dimension: 1
2×1 SubDataFrame
 Row │ stat1
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…
   2 │ [0.540302, -0.416147, -0.989992,…
- Modality 3 / 3
   └─ dimension: 1
2×1 SubDataFrame
 Row │ stat2
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.540302, -0.416147, -0.989992,…
   2 │ [0.841471, 0.909297, 0.14112, -0…
```
"""
struct MultiModalDataset{DF<:AbstractDataFrame} <: AbstractMultiModalDataset
    grouped_variables::Vector{Vector{Int}}
    data::DF

    function MultiModalDataset(
        grouped_variables::AbstractVector,
        df::DF,
    ) where {DF<:AbstractDataFrame}
        grouped_variables = collect(Vector{Int}.(collect.(grouped_variables)))
        grouped_variables = Vector{Vector{Int}}(grouped_variables)
        return new{DF}(grouped_variables, df)
    end

    # Helper
    function MultiModalDataset(
        df::DF,
        grouped_variables::AbstractVector,
    ) where {DF<:AbstractDataFrame}
        return MultiModalDataset(grouped_variables, df)
    end

    function MultiModalDataset(
        df::DF;
        group::Union{Symbol,AbstractVector{<:Integer}} = :none
    ) where {DF<:AbstractDataFrame}
        @assert isa(group, AbstractVector) || group in [:all, :none] "group can be " *
            "`:all`, `:none` or an AbstractVector of dimensions"

        if group == :none
            return MultiModalDataset([], df)
        end

        dimdict = Dict{Integer,AbstractVector{<:Integer}}()
        spare = AbstractVector{Integer}[]

        for (i, c) in enumerate(eachcol(df))
            dim = dimension(DataFrame(:curr => c))
            if isa(group, AbstractVector) && !(dim in group)
                push!(spare, [i])
            elseif haskey(dimdict, dim)
                push!(dimdict[dim], i)
            else
                dimdict[dim] = Integer[i]
            end
        end

        desc = sort(collect(zip(keys(dimdict), values(dimdict))), by = x -> x[1])

        return MultiModalDataset(append!(map(x -> x[2], desc), spare), df)
    end
end

# -------------------------------------------------------------
# MultiModalDataset - accessors

grouped_variables(md::MultiModalDataset) = md.grouped_variables
data(md::MultiModalDataset) = md.data

# -------------------------------------------------------------
# MultiModalDataset - informations

function show(io::IO, md::MultiModalDataset)
    _prettyprint_header(io, md)
    _prettyprint_modalities(io, md)
    _prettyprint_sparevariables(io, md)
end

# -------------------------------------------------------------
# MultiModalDataset - utils

function SoleBase.instances(
    md::MultiModalDataset,
    inds::AbstractVector{<:Integer},
    return_view::Union{Val{true},Val{false}} = Val(false),
)
    @assert return_view == Val(false)
    MultiModalDataset(grouped_variables(md), data(md)[inds,:])
end

function vcat(mds::MultiModalDataset...)
    MultiModalDataset(grouped_variables(first(mds)), vcat((data.(mds)...)))
end

"""
    _empty(md)

Return a copy of a multimodal dataset with no instances.

Note: since the returned AbstractMultiModalDataset will be empty its columns types will be
`Any`.
"""
function _empty(md::MultiModalDataset)
    return MultiModalDataset(
        deepcopy(grouped_variables(md)),
        DataFrame([var_name => [] for var_name in Symbol.(names(data(md)))])
    )
end
