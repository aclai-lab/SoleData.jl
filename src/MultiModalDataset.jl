
# -------------------------------------------------------------
# MultiModalDataset

"""
    MultiModalDataset(df, grouped_variables)

Create a `MultiModalDataset` from an `AbstractDataFrame` `df`,
initializing its modalities according to the grouping in `grouped_variables`.

`grouped_variables` is an `AbstractVector` of variable grouping which are `AbstractVector`s
of integers representing the index of the variables selected for that modality.

Note that the order matters for both the modalities and the variables.

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
   └─ dimensionalities: (0,)
- Modality 1 / 1
   └─ dimensionality: 0
2×1 SubDataFrame
 Row │ name
     │ String
─────┼────────
   1 │ Python
   2 │ Julia
- Spare variables
   └─ dimensionality: mixed
2×3 SubDataFrame
 Row │ age    stat1                              stat2
     │ Int64  Array…                             Array…
─────┼─────────────────────────────────────────────────────────────────────────────
   1 │    30  [0.841471, 0.909297, 0.14112, -0…  [0.540302, -0.416147, -0.989992,…
   2 │     9  [0.540302, -0.416147, -0.989992,…  [0.841471, 0.909297, 0.14112, -0…
```

    MultiModalDataset(df; group = :none)

Create a `MultiModalDataset` from an `AbstractDataFrame` `df`,
automatically selecting modalities.

The selection of modalities can be controlled by the `group` argument which can be:

- `:none` (default): no modality will be created
- `:all`: all variables will be grouped by their [`dimensionality`](@ref)
- a list of dimensionalities which will be grouped.

Note: `:all` and `:none` are the only `Symbol`s accepted by `group`.

# TODO: `:all` should be default argument value for `group`
# TODO: fix passing a vector of Integer to `group`
# TODO: rewrite examples
# Examples
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
   └─ dimensionalities: ()
- Spare variables
   └─ dimensionality: mixed
2×4 SubDataFrame
 Row │ age    name    stat1                              stat2                             ⋯
     │ Int64  String  Array…                             Array…                            ⋯
─────┼──────────────────────────────────────────────────────────────────────────────────────
   1 │    30  Python  [0.841471, 0.909297, 0.14112, -0…  [0.540302, -0.416147, -0.989992,… ⋯
   2 │     9  Julia   [0.540302, -0.416147, -0.989992,…  [0.841471, 0.909297, 0.14112, -0…


julia> md = MultiModalDataset(df; group = :all)
● MultiModalDataset
   └─ dimensionalities: (0, 1)
- Modality 1 / 2
   └─ dimensionality: 0
2×2 SubDataFrame
 Row │ age    name
     │ Int64  String
─────┼───────────────
   1 │    30  Python
   2 │     9  Julia
- Modality 2 / 2
   └─ dimensionality: 1
2×2 SubDataFrame
 Row │ stat1                              stat2
     │ Array…                             Array…
─────┼──────────────────────────────────────────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…  [0.540302, -0.416147, -0.989992,…
   2 │ [0.540302, -0.416147, -0.989992,…  [0.841471, 0.909297, 0.14112, -0…


julia> md = MultiModalDataset(df; group = [0])
● MultiModalDataset
   └─ dimensionalities: (0, 1, 1)
- Modality 1 / 3
   └─ dimensionality: 0
2×2 SubDataFrame
 Row │ age    name
     │ Int64  String
─────┼───────────────
   1 │    30  Python
   2 │     9  Julia
- Modality 2 / 3
   └─ dimensionality: 1
2×1 SubDataFrame
 Row │ stat1
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…
   2 │ [0.540302, -0.416147, -0.989992,…
- Modality 3 / 3
   └─ dimensionality: 1
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
        df::DF,
        grouped_variables::AbstractVector,
    ) where {DF<:AbstractDataFrame}
        grouped_variables = map(group->begin
            if !(group isa AbstractVector)
                group = [group]
            end
            group = collect(group)
            if any(var_name->var_name isa Symbol, group) &&
               any(var_name->var_name isa Integer, group)
                return error("Cannot mix different types of " *
                    "column identifiers; please, only use column indices (integers) or " *
                    "Symbols. Encountered: $(group), $(join(unique(typeof.(group)), ", ")).")
            end
            group = [var_name isa Symbol ? _name2index(df, var_name) : var_name for var_name in group]
            @assert group isa Vector{<:Integer}
            group
        end, grouped_variables)
        grouped_variables = collect(Vector{Int}.(collect.(grouped_variables)))
        grouped_variables = Vector{Vector{Int}}(grouped_variables)
        return new{DF}(grouped_variables, df)
    end

    # Helper
    function MultiModalDataset(
        grouped_variables::AbstractVector,
        df::DF,
    ) where {DF<:AbstractDataFrame}
        return MultiModalDataset(df, grouped_variables)
    end

    function MultiModalDataset(
        df::AbstractDataFrame;
        group::Union{Symbol,AbstractVector{<:Integer}} = :none
    )
        @assert isa(group, AbstractVector) || group in [:all, :none] "group can be " *
            "`:all`, `:none` or an `AbstractVector` of dimensionalities"

        if group == :none
            @warn "Creating MultiModalDataset with no modalities"
            return MultiModalDataset([], df)
        end

        dimdict = Dict{Integer,AbstractVector{<:Integer}}()
        spare = AbstractVector{Integer}[]

        for (i, c) in enumerate(eachcol(df))
            dim = dimensionality(DataFrame(:curr => c))
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

    function MultiModalDataset(
        dfs::Union{AbstractVector{DF},Tuple{DF}}
    ) where {DF<:AbstractDataFrame}
        for (i, j) in Iterators.product(1:length(dfs), 1:length(dfs))
            if i == j continue end
            df1 = dfs[i]
            df2 = dfs[j]
            @assert length(
                    intersect(names(df1), names(df2))
                ) == 0 "Cannot build MultiModalDataset with clashing " *
                "variable names across modalities: $(intersect(names(df1), names(df2)))"
        end
        grouped_variables = []
        i = 1
        for nvars in ncol.(dfs)
            push!(grouped_variables, i:(nvars+i-1))
            i += nvars
        end
        df = hcat(dfs...)
        return MultiModalDataset(df, grouped_variables)
    end

    # Helper
    MultiModalDataset(dfs::AbstractDataFrame...) = MultiModalDataset(dfs)

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
    MultiModalDataset(data(md)[inds,:], grouped_variables(md))
end

function vcat(mds::MultiModalDataset...)
    MultiModalDataset(vcat((data.(mds)...)), grouped_variables(first(mds)))
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
