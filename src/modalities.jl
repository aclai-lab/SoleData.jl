
# -------------------------------------------------------------
# AbstractMultiModalDataset - modalities

"""
    modality(md, i)

Return the `i`-th modality of a multimodal dataset.

    modality(md, indices)

Return a Vector of modalities at `indices` of a multimodal dataset.
"""
function modality(md::AbstractMultiModalDataset, i::Integer)
    @assert 1 ≤ i ≤ nmodalities(md) "Index ($i) must be a valid modality number " *
        "(1:$(nmodalities(md)))"

    return @view data(md)[:,grouped_variables(md)[i]]
end
function modality(md::AbstractMultiModalDataset, indices::AbstractVector{<:Integer})
    return [modality(md, i) for i in indices]
end

"""
    modality(md)

Return a (lazy) iterator of the modalities of a multimodal dataset.
"""
function eachmodality(md::AbstractMultiModalDataset)
    df = data(md)
    Iterators.map(group->(@view df[:,group]), grouped_variables(md))
end

"""
    nmodalities(md)

Return the number of modalities of a multimodal dataset.
"""
nmodalities(md::AbstractMultiModalDataset) = length(grouped_variables(md))

"""
    addmodality!(md, indices)
    addmodality!(md, index)
    addmodality!(md, variable_names)
    addmodality!(md, variable_name)

Create a new modality in a multimodal dataset using variables at `indices`
or `index`, and return`md`.

Alternatively to the `indices` and the `index`, can be used respectively the variable_names
and the variable_name.

Note: to add a new modality with new variables see [`insertmodality!`](@ref).

## PARAMETERS

* `md` is a MultiModalDataset;
* `indices` is an AbstractVector{Integer} that indicates which indices of the multimodal
    dataset's corresponding dataframe to add to the new modality;
* `index` is a Integer that indicates the index of the multimodal dataset's corresponding
    dataframe to add to the new modality;
* `variable_names` is an AbstractVector{Symbol} that indicates which variables of the
    multimodal dataset's corresponding dataframe to add to the new modality;
* `variable_name` is a Symbol that indicates the variable of the multimodal dataset's
    corresponding dataframe to add to the new modality;

## EXAMPLES

```julia-repl
julia> df = DataFrame(:name => ["Python", "Julia"], :age => [25, 26], :sex => ['M', 'F'], :height => [180, 175], :weight => [80, 60])
2×5 DataFrame
 Row │ name    age    sex   height  weight
     │ String  Int64  Char  Int64   Int64
─────┼─────────────────────────────────────
   1 │ Python     25  M        180      80
   2 │ Julia      26  F        175      60

julia> md = MultiModalDataset([[1]], df)
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
   └─ dimension: 0
2×4 SubDataFrame
 Row │ age    sex   height  weight
     │ Int64  Char  Int64   Int64
─────┼─────────────────────────────
   1 │    25  M        180      80
   2 │    26  F        175      60


julia> addmodality!(md, [:age, :sex])
● MultiModalDataset
   └─ dimensions: (0, 0)
- Modality 1 / 2
   └─ dimension: 0
2×1 SubDataFrame
 Row │ name
     │ String
─────┼────────
   1 │ Python
   2 │ Julia
- Modality 2 / 2
   └─ dimension: 0
2×2 SubDataFrame
 Row │ age    sex
     │ Int64  Char
─────┼─────────────
   1 │    25  M
   2 │    26  F
- Spare variables
   └─ dimension: 0
2×2 SubDataFrame
 Row │ height  weight
     │ Int64   Int64
─────┼────────────────
   1 │    180      80
   2 │    175      60


julia> addmodality!(md, 5)
● MultiModalDataset
   └─ dimensions: (0, 0, 0)
- Modality 1 / 3
   └─ dimension: 0
2×1 SubDataFrame
 Row │ name
     │ String
─────┼────────
   1 │ Python
   2 │ Julia
- Modality 2 / 3
   └─ dimension: 0
2×2 SubDataFrame
 Row │ age    sex
     │ Int64  Char
─────┼─────────────
   1 │    25  M
   2 │    26  F
- Modality 3 / 3
   └─ dimension: 0
2×1 SubDataFrame
 Row │ weight
     │ Int64
─────┼────────
   1 │     80
   2 │     60
- Spare variables
   └─ dimension: 0
2×1 SubDataFrame
 Row │ height
     │ Int64
─────┼────────
   1 │    180
   2 │    175
```
"""
function addmodality!(md::AbstractMultiModalDataset, indices::AbstractVector{<:Integer})
    @assert length(indices) > 0 "Can't add an empty modality to dataset"

    for i in indices
        @assert i in 1:nvariables(md) "Index $(i) is out of range 1:nvariables " *
            "(1:$(nvariables(md)))"
    end

    push!(grouped_variables(md), indices)

    return md
end
addmodality!(md::AbstractMultiModalDataset, index::Integer) = addmodality!(md, [index])
function addmodality!(md::AbstractMultiModalDataset, variable_names::AbstractVector{Symbol})
    for var_name in variable_names
        @assert hasvariables(md, var_name) "MultiModalDataset does not contain " *
            "variable $(var_name)"
    end

    return addmodality!(md, _name2index(md, variable_names))
end
function addmodality!(md::AbstractMultiModalDataset, variable_name::Symbol)
    return addmodality!(md, [variable_name])
end

"""

    removemodality!(md, indices)
    removemodality!(md, index)

Remove `i`-th modality from a multimodal dataset, and return the dataset.

Note: to completely remove a modality and all variables in it use [`dropmodalities!`](@ref)
instead.

## PARAMETERS

* `md` is a MultiModalDataset;
* `index` is a Integer that indicates which modality to remove from the multimodal dataset;
* `indices` is a AbstractVector{Integer} that indicates the modalities to remove from the
    multimodal dataset;

## EXAMPLES

```julia-repl
julia> df = DataFrame(:name => ["Python", "Julia"],
                      :age => [25, 26],
                      :sex => ['M', 'F'],
                      :height => [180, 175],
                      :weight => [80, 60])
                     )
2×5 DataFrame
 Row │ name    age    sex   height  weight
     │ String  Int64  Char  Int64   Int64
─────┼─────────────────────────────────────
   1 │ Python     25  M        180      80
   2 │ Julia      26  F        175      60

julia> md = MultiModalDataset([[1, 2],[3],[4],[5]], df)
● MultiModalDataset
   └─ dimensions: (0, 0, 0, 0)
- Modality 1 / 4
   └─ dimension: 0
2×2 SubDataFrame
 Row │ name    age
     │ String  Int64
─────┼───────────────
   1 │ Python     25
   2 │ Julia      26
- Modality 2 / 4
   └─ dimension: 0
2×1 SubDataFrame
 Row │ sex
     │ Char
─────┼──────
   1 │ M
   2 │ F
- Modality 3 / 4
   └─ dimension: 0
2×1 SubDataFrame
 Row │ height
     │ Int64
─────┼────────
   1 │    180
   2 │    175
- Modality 4 / 4
   └─ dimension: 0
2×1 SubDataFrame
 Row │ weight
     │ Int64
─────┼────────
   1 │     80
   2 │     60

julia> removemodality!(md, [3])
● MultiModalDataset
   └─ dimensions: (0, 0, 0)
- Modality 1 / 3
   └─ dimension: 0
2×2 SubDataFrame
 Row │ name    age
     │ String  Int64
─────┼───────────────
   1 │ Python     25
   2 │ Julia      26
- Modality 2 / 3
   └─ dimension: 0
2×1 SubDataFrame
 Row │ sex
     │ Char
─────┼──────
   1 │ M
   2 │ F
- Modality 3 / 3
   └─ dimension: 0
2×1 SubDataFrame
 Row │ weight
     │ Int64
─────┼────────
   1 │     80
   2 │     60
- Spare variables
   └─ dimension: 0
2×1 SubDataFrame
 Row │ height
     │ Int64
─────┼────────
   1 │    180
   2 │    175

julia> removemodality!(md, [1,2])
● MultiModalDataset
   └─ dimensions: (0,)
- Modality 1 / 1
   └─ dimension: 0
2×1 SubDataFrame
 Row │ weight
     │ Int64
─────┼────────
   1 │     80
   2 │     60
- Spare variables
   └─ dimension: 0
2×4 SubDataFrame
 Row │ name    age    sex   height
     │ String  Int64  Char  Int64
─────┼─────────────────────────────
   1 │ Python     25  M        180
   2 │ Julia      26  F        175

```
"""
function removemodality!(md::AbstractMultiModalDataset, i::Integer)
    @assert 1 ≤ i ≤ nmodalities(md) "Index $(i) does not correspond to a modality " *
        "(1:$(nmodalities(md)))"

    deleteat!(grouped_variables(md), i)

    return md
end
function removemodality!(md::AbstractMultiModalDataset, indices::AbstractVector{Integer})
    for i in sort(unique(indices))
        removemodality!(md, i)
    end

    return md
end

"""
    addvariable_tomodality!(md, i_modality, var_index)
    addvariable_tomodality!(md, i_modality, var_indices)
    addvariable_tomodality!(md, i_modality, var_name)
    addvariable_tomodality!(md, i_modality, var_names)

Add variable at index `var_index` to the modality at index `i_modality` in a
multimodal dataset, and return the dataset.
Alternatively to `var_index` the variable name can be used.
Multiple variables can be inserted into the multimodal dataset at once using `var_indices`
or `var_inames`.

Note: The function does not allow you to add an variable to a new modality, but only to add it
to an existing modality in the md. To add a new modality use [`addmodality!`](@ref) instead.

## PARAMETERS

* `md` is a MultiModalDataset;
* `i_modality` is a Integer which indicates the modality in which the variable(s)
    will be added;
* `var_index` is a Integer that indicates the index of the variable to add to a specific
    modality of the multimodal dataset;
* `var_indices` is a AbstractVector{Integer} which indicates the indices of the variables
    to add to a specific modality of the multimodal dataset;
* `var_name` is a Symbol which indicates the name of the variable to add to a specific
    modality of the multimodal dataset;
* `var_names` is a AbstractVector{Symbol} which indicates the name of the variables to
    add to a specific modality of the multimodal dataset;

## EXAMPLES

```julia-repl
julia> df = DataFrame(:name => ["Python", "Julia"],
                      :age => [25, 26],
                      :sex => ['M', 'F'],
                      :height => [180, 175],
                      :weight => [80, 60])
                     )
2×5 DataFrame
 Row │ name    age    sex   height  weight
     │ String  Int64  Char  Int64   Int64
─────┼─────────────────────────────────────
   1 │ Python     25  M        180      80
   2 │ Julia      26  F        175      60

julia> md = MultiModalDataset([[1, 2],[3]], df)
● MultiModalDataset
   └─ dimensions: (0, 0)
- Modality 1 / 2
   └─ dimension: 0
2×2 SubDataFrame
 Row │ name    age
     │ String  Int64
─────┼───────────────
   1 │ Python     25
   2 │ Julia      26
- Modality 2 / 2
   └─ dimension: 0
2×1 SubDataFrame
 Row │ sex
     │ Char
─────┼──────
   1 │ M
   2 │ F
- Spare variables
   └─ dimension: 0
2×2 SubDataFrame
 Row │ height  weight
     │ Int64   Int64
─────┼────────────────
   1 │    180      80
   2 │    175      60

julia> addvariable_tomodality!(md, 1, [4,5])
● MultiModalDataset
   └─ dimensions: (0, 0)
- Modality 1 / 2
   └─ dimension: 0
2×4 SubDataFrame
 Row │ name    age    height  weight
     │ String  Int64  Int64   Int64
─────┼───────────────────────────────
   1 │ Python     25     180      80
   2 │ Julia      26     175      60
- Modality 2 / 2
   └─ dimension: 0
2×1 SubDataFrame
 Row │ sex
     │ Char
─────┼──────
   1 │ M
   2 │ F

julia> addvariable_tomodality!(md, 2, [:name,:weight])
● MultiModalDataset
   └─ dimensions: (0, 0)
- Modality 1 / 2
   └─ dimension: 0
2×4 SubDataFrame
 Row │ name    age    height  weight
     │ String  Int64  Int64   Int64
─────┼───────────────────────────────
   1 │ Python     25     180      80
   2 │ Julia      26     175      60
- Modality 2 / 2
   └─ dimension: 0
2×3 SubDataFrame
 Row │ sex   name    weight
     │ Char  String  Int64
─────┼──────────────────────
   1 │ M     Python      80
   2 │ F     Julia       60
```
"""
function addvariable_tomodality!(
    md::AbstractMultiModalDataset, i_modality::Integer, var_index::Integer
)
    @assert 1 ≤ i_modality ≤ nmodalities(md) "Index $(i_modality) does not correspond " *
        "to a modality (1:$(nmodalities(md)))"
    @assert 1 ≤ var_index ≤ nvariables(md) "Index $(var_index) does not correspond " *
        "to an variable (1:$(nvariables(md)))"

    if var_index in grouped_variables(md)[i_modality]
        @info "Variable $(var_index) is already part of modality $(i_modality)"
    else
        push!(grouped_variables(md)[i_modality], var_index)
    end

    return md
end
function addvariable_tomodality!(
    md::AbstractMultiModalDataset, i_modality::Integer, var_indices::AbstractVector{<:Integer}
)
    for var_index in var_indices
        addvariable_tomodality!(md, i_modality, var_index)
    end

    return md
end
function addvariable_tomodality!(
    md::AbstractMultiModalDataset, i_modality::Integer, var_name::Symbol
)
    @assert hasvariables(md, var_name) "MultiModalDataset does not contain variable " *
        "$(var_name)"

    return addvariable_tomodality!(md, i_modality, _name2index(md, var_name))
end
function addvariable_tomodality!(
    md::AbstractMultiModalDataset, i_modality::Integer, var_names::AbstractVector{Symbol}
)
    for var_name in var_names
        addvariable_tomodality!(md, i_modality, var_name)
    end

    return md
end

"""
    removevariable_frommodality!(md, i_modality, var_indices)
    removevariable_frommodality!(md, i_modality, var_index)
    removevariable_frommodality!(md, i_modality, var_name)
    removevariable_frommodality!(md, i_modality, var_names)

Remove variable at index `var_index` from the modality at index `i_modality` in a
multimodal dataset, and return `md`.

Alternatively to `var_index` the variable name can be used.
Multiple variables can be dropped from the multimodal dataset at once passing a Vector of
Symbols (for names) or a Vector of Integers (for indices) as last parameter.

Note: when all variables are dropped to a modality, it will be removed.

## PARAMETERS

* `md` is a MultiModalDataset;
* `i_modality` is a Integer which indicates the modality in which the variable(s)
    will be dropped;
* `var_index` is a Integer that indicates the index of the variable to drop from a
    specific modality of the multimodal dataset;
* `var_indices` is a AbstractVector{Integer} which indicates the indices of the variables
    to drop from a specific modality of the multimodal dataset;
* `var_name` is a Symbol which indicates the name of the variable to drop from a specific
    modality of the multimodal dataset;
* `var_names` is a AbstractVector{Symbol} which indicates the name of the variables to
    drop from a specific modality of the multimodal dataset;

## EXAMPLES

```julia-repl
julia> df = DataFrame(:name => ["Python", "Julia"],
                      :age => [25, 26],
                      :sex => ['M', 'F'],
                      :height => [180, 175],
                      :weight => [80, 60])
                     )
2×5 DataFrame
 Row │ name    age    sex   height  weight
     │ String  Int64  Char  Int64   Int64
─────┼─────────────────────────────────────
   1 │ Python     25  M        180      80
   2 │ Julia      26  F        175      60

julia> md = MultiModalDataset([[1,2,4],[2,3,4],[5]], df)
● MultiModalDataset
   └─ dimensions: (0, 0, 0)
- Modality 1 / 3
   └─ dimension: 0
2×3 SubDataFrame
 Row │ name    age    height
     │ String  Int64  Int64
─────┼───────────────────────
   1 │ Python     25     180
   2 │ Julia      26     175
- Modality 2 / 3
   └─ dimension: 0
2×3 SubDataFrame
 Row │ age    sex   height
     │ Int64  Char  Int64
─────┼─────────────────────
   1 │    25  M        180
   2 │    26  F        175
- Modality 3 / 3
   └─ dimension: 0
2×1 SubDataFrame
 Row │ weight
     │ Int64
─────┼────────
   1 │     80
   2 │     60

julia> removevariable_frommodality!(md, 3, 5)
[ Info: Variable 5 was last variable of modality 3: removing modality
● MultiModalDataset
   └─ dimensions: (0, 0)
- Modality 1 / 2
   └─ dimension: 0
2×3 SubDataFrame
 Row │ name    age    height
     │ String  Int64  Int64
─────┼───────────────────────
   1 │ Python     25     180
   2 │ Julia      26     175
- Modality 2 / 2
   └─ dimension: 0
2×3 SubDataFrame
 Row │ age    sex   height
     │ Int64  Char  Int64
─────┼─────────────────────
   1 │    25  M        180
   2 │    26  F        175
- Spare variables
   └─ dimension: 0
2×1 SubDataFrame
 Row │ weight
     │ Int64
─────┼────────
   1 │     80
   2 │     60

julia> removevariable_frommodality!(md, 1, :age)
● MultiModalDataset
   └─ dimensions: (0, 0)
- Modality 1 / 2
   └─ dimension: 0
2×2 SubDataFrame
 Row │ name    height
     │ String  Int64
─────┼────────────────
   1 │ Python     180
   2 │ Julia      175
- Modality 2 / 2
   └─ dimension: 0
2×3 SubDataFrame
 Row │ age    sex   height
     │ Int64  Char  Int64
─────┼─────────────────────
   1 │    25  M        180
   2 │    26  F        175
- Spare variables
   └─ dimension: 0
2×1 SubDataFrame
 Row │ weight
     │ Int64
─────┼────────
   1 │     80
   2 │     60

julia> removevariable_frommodality!(md, 2, [3,4])
● MultiModalDataset
   └─ dimensions: (0, 0)
- Modality 1 / 2
   └─ dimension: 0
2×2 SubDataFrame
 Row │ name    height
     │ String  Int64
─────┼────────────────
   1 │ Python     180
   2 │ Julia      175
- Modality 2 / 2
   └─ dimension: 0
2×1 SubDataFrame
 Row │ age
     │ Int64
─────┼───────
   1 │    25
   2 │    26
- Spare variables
   └─ dimension: 0
2×2 SubDataFrame
 Row │ sex   weight
     │ Char  Int64
─────┼──────────────
   1 │ M         80
   2 │ F         60

julia> removevariable_frommodality!(md, 1, [:name,:height])
[ Info: Variable 4 was last variable of modality 1: removing modality
● MultiModalDataset
   └─ dimensions: (0,)
- Modality 1 / 1
   └─ dimension: 0
2×1 SubDataFrame
 Row │ age
     │ Int64
─────┼───────
   1 │    25
   2 │    26
- Spare variables
   └─ dimension: 0
2×4 SubDataFrame
 Row │ name    sex   height  weight
     │ String  Char  Int64   Int64
─────┼──────────────────────────────
   1 │ Python  M        180      80
   2 │ Julia   F        175      60
```
"""
function removevariable_frommodality!(
    md::AbstractMultiModalDataset,
    i_modality::Integer,
    var_index::Integer;
    silent = false,
)
    @assert 1 ≤ i_modality ≤ nmodalities(md) "Index $(i_modality) does not correspond " *
        "to a modality (1:$(nmodalities(md)))"
    @assert 1 ≤ var_index ≤ nvariables(md) "Index $(var_index) does not correspond " *
        "to an variable (1:$(nvariables(md)))"

    if !(var_index in grouped_variables(md)[i_modality])
        if !silent
            @info "Variable $(var_index) is not part of modality $(i_modality)"
        end
    elseif nvariables(md, i_modality) == 1
        if !silent
            @info "Variable $(var_index) was last variable of modality $(i_modality): " *
                "removing modality"
        end
        removemodality!(md, i_modality)
    else
        deleteat!(
            grouped_variables(md)[i_modality],
            indexin(var_index, grouped_variables(md)[i_modality])[1]
        )
    end

    return md
end
function removevariable_frommodality!(
    md::AbstractMultiModalDataset,
    i_modality::Integer,
    var_indices::AbstractVector{<:Integer};
    kwargs...
)
    for i in var_indices
        removevariable_frommodality!(md, i_modality, i; kwargs...)
    end

    return md
end
function removevariable_frommodality!(
    md::AbstractMultiModalDataset,
    i_modality::Integer,
    var_name::Symbol;
    kwargs...
)
    @assert hasvariables(md, var_name) "MultiModalDataset does not contain variable " *
        "$(var_name)"

    return removevariable_frommodality!(md, i_modality, _name2index(md, var_name); kwargs...)
end
function removevariable_frommodality!(
    md::AbstractMultiModalDataset,
    i_modality::Integer,
    var_names::AbstractVector{Symbol};
    kwargs...
)
    for var_name in var_names
        removevariable_frommodality!(md, i_modality, var_name; kwargs...)
    end

    return md
end

"""
    insertmodality!(md, col, new_modality, existing_variables)
    insertmodality!(md, new_modality, existing_variables)

Insert `new_modality` as new modality to multimodal dataset, and return the dataset.
Existing variables can be added to the new modality while adding it to the dataset passing
the corresponding inidices by `existing_variables`.
If `col` is specified then the variables will be inserted starting at index `col`.

## PARAMETERS
* `md` is a MultiModalDataset;
* `col` is a Integer which indicates the column in which to insert the columns of the new
    modality `new_modality`;
* `new_modality` is a AbstractDataFrame which will be added to the multimodal dataset as a
    subdataframe of a new modality;
* `existing_variables` is AbstractVector{Integer} and a AbstractVector{Symbol} also. It
    indicates which variables of the multimodal dataset relative's dataframe to insert
    in the new modality `new_modality`.

## EXAMPLES

```julia-repl
julia> df = DataFrame(
           :name => ["Python", "Julia"],
           :stat1 => [[sin(i) for i in 1:50000], [cos(i) for i in 1:50000]]
       )
2×2 DataFrame
 Row │ name    stat1
     │ String  Array…
─────┼───────────────────────────────────────────
   1 │ Python  [0.841471, 0.909297, 0.14112, -0…
   2 │ Julia   [0.540302, -0.416147, -0.989992,…

julia> md = MultiModalDataset(df; group = :all)
● MultiModalDataset
   └─ dimensions: (0, 1)
- Modality 1 / 2
   └─ dimension: 0
2×1 SubDataFrame
 Row │ name
     │ String
─────┼────────
   1 │ Python
   2 │ Julia
- Modality 2 / 2
   └─ dimension: 1
2×1 SubDataFrame
 Row │ stat1
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…
   2 │ [0.540302, -0.416147, -0.989992,…

julia> insertmodality!(md, DataFrame(:age => [30, 9]))
● MultiModalDataset
   └─ dimensions: (0, 1, 0)
- Modality 1 / 3
   └─ dimension: 0
2×1 SubDataFrame
 Row │ name
     │ String
─────┼────────
   1 │ Python
   2 │ Julia
- Modality 2 / 3
   └─ dimension: 1
2×1 SubDataFrame
 Row │ stat1
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…
   2 │ [0.540302, -0.416147, -0.989992,…
- Modality 3 / 3
   └─ dimension: 0
2×1 SubDataFrame
 Row │ age
     │ Int64
─────┼───────
   1 │    30
   2 │     9

julia> md.data
2×3 DataFrame
 Row │ name    stat1                              age
     │ String  Array…                             Int64
─────┼──────────────────────────────────────────────────
   1 │ Python  [0.841471, 0.909297, 0.14112, -0…     30
   2 │ Julia   [0.540302, -0.416147, -0.989992,…      9
```
or, selecting the column

```julia-repl
julia> df = DataFrame(
           :name => ["Python", "Julia"],
           :stat1 => [[sin(i) for i in 1:50000], [cos(i) for i in 1:50000]]
       )
2×2 DataFrame
 Row │ name    stat1
     │ String  Array…
─────┼───────────────────────────────────────────
   1 │ Python  [0.841471, 0.909297, 0.14112, -0…
   2 │ Julia   [0.540302, -0.416147, -0.989992,…

julia> md = MultiModalDataset(df; group = :all)
● MultiModalDataset
   └─ dimensions: (0, 1)
- Modality 1 / 2
   └─ dimension: 0
2×1 SubDataFrame
 Row │ name
     │ String
─────┼────────
   1 │ Python
   2 │ Julia
- Modality 2 / 2
   └─ dimension: 1
2×1 SubDataFrame
 Row │ stat1
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…
   2 │ [0.540302, -0.416147, -0.989992,…

julia> insertmodality!(md, 2, DataFrame(:age => [30, 9]))
● MultiModalDataset
   └─ dimensions: (1, 0)
- Modality 1 / 2
   └─ dimension: 1
2×1 SubDataFrame
 Row │ stat1
     │ Array…
─────┼───────────────────────────────────
    1 │ [0.841471, 0.909297, 0.14112, -0…
    2 │ [0.540302, -0.416147, -0.989992,…
- Modality 2 / 2
   └─ dimension: 0
2×1 SubDataFrame
 Row │ age
     │ Int64
─────┼───────
   1 │    30
   2 │     9
- Spare variables
   └─ dimension: 0
2×1 SubDataFrame
 Row │ name
     │ String
─────┼────────
   1 │ Python
   2 │ Julia

julia> md.data
2×3 DataFrame
 Row │ name    age    stat1
     │ String  Int64  Array…
─────┼──────────────────────────────────────────────────
   1 │ Python     30  [0.841471, 0.909297, 0.14112, -0…
   2 │ Julia       9  [0.540302, -0.416147, -0.989992,…
```
or, adding an existing variable:

```julia-repl
julia> df = DataFrame(
           :name => ["Python", "Julia"],
           :stat1 => [[sin(i) for i in 1:50000], [cos(i) for i in 1:50000]]
       )
2×2 DataFrame
 Row │ name    stat1
     │ String  Array…
─────┼───────────────────────────────────────────
   1 │ Python  [0.841471, 0.909297, 0.14112, -0…
   2 │ Julia   [0.540302, -0.416147, -0.989992,…

julia> md = MultiModalDataset([[2]], df)
● MultiModalDataset
   └─ dimensions: (1,)
- Modality 1 / 1
   └─ dimension: 1
2×1 SubDataFrame
 Row │ stat1
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…
   2 │ [0.540302, -0.416147, -0.989992,…
- Spare variables
   └─ dimension: 0
2×1 SubDataFrame
 Row │ name
     │ String
─────┼────────
   1 │ Python
   2 │ Julia


julia> insertmodality!(md, DataFrame(:age => [30, 9]); existing_variables = [1])
● MultiModalDataset
   └─ dimensions: (1, 0)
- Modality 1 / 2
   └─ dimension: 1
2×1 SubDataFrame
 Row │ stat1
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…
   2 │ [0.540302, -0.416147, -0.989992,…
- Modality 2 / 2
   └─ dimension: 0
2×2 SubDataFrame
 Row │ age    name
     │ Int64  String
─────┼───────────────
   1 │    30  Python
   2 │     9  Julia
```
"""
function insertmodality!(
    md::AbstractMultiModalDataset,
    col::Integer,
    new_modality::AbstractDataFrame,
    existing_variables::AbstractVector{<:Integer} = Integer[]
)
    if col != nvariables(md)+1
        new_indices = col:col+ncol(new_modality)-1

        for (k, c) in collect(zip(keys(eachcol(new_modality)), collect(eachcol(new_modality))))
            insertvariables!(md, col, k, c)
            col = col + 1
        end
    else
        new_indices = (nvariables(md)+1):(nvariables(md)+ncol(new_modality))

        for (k, c) in collect(zip(keys(eachcol(new_modality)), collect(eachcol(new_modality))))
            insertvariables!(md, k, c)
        end
    end

    addmodality!(md, new_indices)

    for i in existing_variables
        addvariable_tomodality!(md, nmodalities(md), i)
    end

    return md
end
function insertmodality!(
    md::AbstractMultiModalDataset,
    col::Integer,
    new_modality::AbstractDataFrame,
    existing_variables::AbstractVector{Symbol}
)
    for var_name in existing_variables
        @assert hasvariables(md, var_name) "MultiModalDataset does not contain " *
            "variable $(var_name)"
    end

    return insertmodality!(md, col, new_modality, _name2index(md, existing_variables))
end
function insertmodality!(
    md::AbstractMultiModalDataset,
    new_modality::AbstractDataFrame,
    existing_variables::AbstractVector{<:Integer} = Integer[]
)
    insertmodality!(md, nvariables(md)+1, new_modality, existing_variables)
end
function insertmodality!(
    md::AbstractMultiModalDataset,
    new_modality::AbstractDataFrame,
    existing_variables::AbstractVector{Symbol}
)
    for var_name in existing_variables
        @assert hasvariables(md, var_name) "MultiModalDataset does not contain " *
            "variable $(var_name)"
    end

    return insertmodality!(md, nvariables(md)+1, new_modality, _name2index(md, existing_variables))
end

"""
    dropmodalities!(md, indices)
    dropmodalities!(md, index)

Remove the `i`-th modality from a multimodal dataset while dropping all variables in it and
return `md` without the dropped modalities.

Note: if the dropped variables are present in other modalities they will also be removed from
them. This can lead to the removal of additional modalities other than the `i`-th.

If the intection is to remove a modality without releasing the variables use
[`removemodality!`](@ref) instead.

## PARAMETERS

* `md` is a MultiModalDataset;
* `index` is a Integer which indicates the index of the modality to drop;
* `indices` is an AbstractVector{Integer} which indicates the indices of the modalities to drop.

## EXAMPLES

```julia-repl
julia> df = DataFrame(:name => ["Python", "Julia"], :age => [25, 26], :sex => ['M', 'F'], :height => [180, 175], :weight => [80, 60])
2×5 DataFrame
 Row │ name    age    sex   height  weight
     │ String  Int64  Char  Int64   Int64
─────┼─────────────────────────────────────
   1 │ Python     25  M        180      80
   2 │ Julia      26  F        175      60

julia> md = MultiModalDataset([[1, 2],[3,4],[5],[2,3]], df)
● MultiModalDataset
   └─ dimensions: (0, 0, 0, 0)
- Modality 1 / 4
   └─ dimension: 0
2×2 SubDataFrame
 Row │ name    age
     │ String  Int64
─────┼───────────────
   1 │ Python     25
   2 │ Julia      26
- Modality 2 / 4
   └─ dimension: 0
2×2 SubDataFrame
 Row │ sex   height
     │ Char  Int64
─────┼──────────────
   1 │ M        180
   2 │ F        175
- Modality 3 / 4
   └─ dimension: 0
2×1 SubDataFrame
 Row │ weight
     │ Int64
─────┼────────
   1 │     80
   2 │     60
- Modality 4 / 4
   └─ dimension: 0
2×2 SubDataFrame
 Row │ age    sex
     │ Int64  Char
─────┼─────────────
   1 │    25  M
   2 │    26  F

julia> dropmodalities!(md, [2,3])
[ Info: Variable 3 was last variable of modality 2: removing modality
[ Info: Variable 3 was last variable of modality 2: removing modality
● MultiModalDataset
   └─ dimensions: (0, 0)
- Modality 1 / 2
   └─ dimension: 0
2×2 SubDataFrame
 Row │ name    age
     │ String  Int64
─────┼───────────────
   1 │ Python     25
   2 │ Julia      26
- Modality 2 / 2
   └─ dimension: 0
2×1 SubDataFrame
 Row │ age
     │ Int64
─────┼───────
   1 │    25
   2 │    26

julia> dropmodalities!(md, 2)
[ Info: Variable 2 was last variable of modality 2: removing modality
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
```
"""
function dropmodalities!(md::AbstractMultiModalDataset, index::Integer)
    @assert 1 ≤ index ≤ nmodalities(md) "Index $(index) does not correspond to a modality " *
        "(1:$(nmodalities(md)))"

    return dropvariables!(md, grouped_variables(md)[index]; silent = true)
end

function dropmodalities!(md::AbstractMultiModalDataset, indices::AbstractVector{<:Integer})
    for i in indices
        @assert 1 ≤ i ≤ nmodalities(md) "Index $(i) does not correspond to a modality " *
            "(1:$(nmodalities(md)))"
    end

    return dropvariables!(md, sort!(
        unique(vcat(grouped_variables(md)[indices]...)); rev = true
    ); silent = true)
end

"""
TODO
"""
function keeponlymodalities!(
    md::AbstractMultiModalDataset,
    indices::AbstractVector{<:Integer}
)
    return dropmodalities!(md, setdiff(collect(1:nmodalities(md)), indices))
end
