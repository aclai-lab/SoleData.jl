
# -------------------------------------------------------------
# Variables manipulation

"""
    nvariables(md)
    nvariables(md, i)

Return the number of variables of a multimodal dataset.

If an index is passed as second argument then the number of variables of the modality at
index `i` is returned.

Alternatively `nvariables` can be called on a single modality.

## PARAMETERS

* `md` is a MultiModalDataset;
* `i` (optional) is a Integer and indicating the modality of the multimodal dataset whose
    number of variables you want to know.

## EXAMPLES

```julia-repl
julia> md = MultiModalDataset([[1],[2]], DataFrame(:age => [25, 26], :sex => ['M', 'F']))
● MultiModalDataset
   └─ dimensions: (0, 0)
- Modality 1 / 2
   └─ dimension: 0
2×1 SubDataFrame
 Row │ age
     │ Int64
─────┼───────
   1 │    25
   2 │    26
- Modality 2 / 2
   └─ dimension: 0
2×1 SubDataFrame
 Row │ sex
     │ Char
─────┼──────
   1 │ M
   2 │ F


julia> nvariables(md)
2

julia> nvariables(md, 2)
1

julia> mod2 = modality(md, 2)
2×1 SubDataFrame
 Row │ sex
     │ Char
─────┼──────
   1 │ M
   2 │ F

julia> nvariables(mod2)
1

julia> md = MultiModalDataset([[1, 2],[3, 4, 5]], DataFrame(:name => ["Python", "Julia"], :age => [25, 26], :sex => ['M', 'F'], :height => [180, 175], :weight => [80, 60]))
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
2×3 SubDataFrame
 Row │ sex   height  weight
     │ Char  Int64   Int64
─────┼──────────────────────
   1 │ M        180      80
   2 │ F        175      60

julia> nvariables(md)
5

julia> nvariables(md, 2)
3

julia> mod2 = modality(md,2)
2×3 SubDataFrame
 Row │ sex   height  weight
     │ Char  Int64   Int64
─────┼──────────────────────
   1 │ M        180      80
   2 │ F        175      60

julia> nvariables(mod2)
3
```
"""
nvariables(df::AbstractDataFrame) = ncol(df)
nvariables(md::AbstractMultiModalDataset) = nvariables(data(md))
function nvariables(md::AbstractMultiModalDataset, i::Integer)
    @assert 1 ≤ i ≤ nmodalities(md) "Index ($i) must be a valid modality number " *
        "(1:$(nmodalities(md)))"

    return nvariables(modality(md, i))
end

"""
    insertvariables!(md, col, var_id, values)
    insertvariables!(md, var_id, values)
    insertvariables!(md, col, var_id, value)
    insertvariables!(md, var_id, value)

Insert an attibute in a multimodal dataset with id `var_id`.

!!! note
    Each variable inserted will be added in the md as a spare variables.

## PARAMETERS

* `md` is an AbstractMultiModalDataset;
* `col` is an Integer and indicates in which position to insert the new variable.
    If col isn't passed as a parameter to the function the new variable will be placed
    last in the md's relative dataframe;
* `var_id` is a Symbol and denote the name of the variable to insert.
    Duplicated variable names will be renamed to avoid conflicts: see `makeunique` parameter
    of [`insertcols!`](https://dataframes.juliadata.org/stable/lib/functions/#DataFrames.insertcols!)
    in DataFrames documentation;
* `values` is an AbstractVector that indicates the values ​​of the new variable inserted.
    The length of `values` should match `ninstances(md)` or an exception is thrown;
* `value` is a single value for the new variable. If a single `value` is passed as last
    parameter this will be copied and used for each instance in the dataset.

## EXAMPLES

```julia-repl
julia> md = MultiModalDataset([[1, 2],[3]], DataFrame(:name => ["Python", "Julia"], :age => [25, 26], :sex => ['M', 'F']))
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

julia> insertvariables!(md, :weight, [80, 75])
2×4 DataFrame
 Row │ name    age    sex   weight
     │ String  Int64  Char  Int64
─────┼─────────────────────────────
   1 │ Python     25  M         80
   2 │ Julia      26  F         75

julia> md
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
2×1 SubDataFrame
 Row │ weight
     │ Int64
─────┼────────
   1 │     80
   2 │     75

julia> insertvariables!(md, 2, :height, 180)
2×5 DataFrame
 Row │ name    height  age    sex   weight
     │ String  Int64   Int64  Char  Int64
─────┼─────────────────────────────────────
   1 │ Python     180     25  M         80
   2 │ Julia      180     26  F         75

julia> insertvariables!(md, :hair, ["brown", "blonde"])
2×6 DataFrame
 Row │ name    height  age    sex   weight  hair
     │ String  Int64   Int64  Char  Int64   String
─────┼─────────────────────────────────────────────
   1 │ Python     180     25  M         80  brown
   2 │ Julia      180     26  F         75  blonde

julia> md
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
2×3 SubDataFrame
 Row │ height  weight  hair
     │ Int64   Int64   String
─────┼────────────────────────
   1 │    180      80  brown
   2 │    180      75  blonde
```
"""
function insertvariables!(
    md::AbstractMultiModalDataset,
    col::Integer,
    var_id::Symbol,
    values::AbstractVector
)
    @assert length(values) == ninstances(md) "value not specified for each instance " *
    "{length(values) != ninstances(md)}:{$(length(values)) != $(ninstances(md))}"

    if col != nvariables(md)+1
        insertcols!(data(md), col, var_id => values, makeunique = true)

        for (i_modality, desc) in enumerate(grouped_variables(md))
            for (i_var, var) in enumerate(desc)
                if var >= col
                    grouped_variables(md)[i_modality][i_var] = var + 1
                end
            end
        end

        return md
    else
        insertcols!(data(md), col, var_id => values, makeunique = true)
    end

    return md
end
function insertvariables!(
    md::AbstractMultiModalDataset,
    var_id::Symbol,
    values::AbstractVector
)
    return insertvariables!(md, nvariables(md)+1, var_id, values)
end
function insertvariables!(
    md::AbstractMultiModalDataset,
    col::Integer,
    var_id::Symbol,
    value
)
    return insertvariables!(md, col, var_id, [deepcopy(value) for i in 1:ninstances(md)])
end
function insertvariables!(md::AbstractMultiModalDataset, var_id::Symbol, value)
    return insertvariables!(md, nvariables(md)+1, var_id, value)
end

"""
    hasvariables(df, variable_name)
    hasvariables(md, i_modality, variable_name)
    hasvariables(md, variable_name)
    hasvariables(df, variable_names)
    hasvariables(md, i_modality, variable_names)
    hasvariables(md, variable_names)

Check whether a multimodal dataset contains an variable named `variable_name`.

Instead of a single variable name a Vector of names can be passed. It this is the case
this function will return `true` only if `md` contains all the variable listed.

## PARAMETERS

* `df` is an AbstractDataFrame, which is one of the two structure in which you want to check
    the presence of the variable;
* `md` is an AbstractMultiModalDataset, which is one of the two structure in which you want
    to check the presence of the variable;
* `variable_name` is a Symbol and indicates the variable, whose existence I want to
    verify;
* `i_modality` is and Integer and indicates in which modality to look for the variable.

## EXAMPLES

```julia-repl
julia> md = MultiModalDataset([[1, 2],[3]], DataFrame(:name => ["Python", "Julia"], :age => [25, 26], :sex => ['M', 'F']))
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

julia> hasvariables(md, :age)
true

julia> hasvariables(md.data, :name)
true

julia> hasvariables(md, :height)
false

julia> hasvariables(md, 1, :sex)
false

julia> hasvariables(md, 2, :sex)
true
```

```julia-repl
julia> md = MultiModalDataset([[1, 2],[3]], DataFrame(:name => ["Python", "Julia"], :age => [25, 26], :sex => ['M', 'F']))
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

julia> hasvariables(md, [:sex, :age])
true

julia> hasvariables(md, 1, [:sex])
false

julia> hasvariables(md, 2, [:sex])
true

julia> hasvariables(md.data, [:name, :sex])
true
```
"""
function hasvariables(df::AbstractDataFrame, variable_name::Symbol)
    return _name2index(df, variable_name) > 0
end
function hasvariables(
    md::AbstractMultiModalDataset,
    i_modality::Integer,
    variable_name::Symbol
)
    return _name2index(modality(md, i_modality), variable_name) > 0
end
function hasvariables(md::AbstractMultiModalDataset, variable_name::Symbol)
    return _name2index(md, variable_name) > 0
end
function hasvariables(df::AbstractDataFrame, variable_names::AbstractVector{Symbol})
    return !(0 in _name2index(df, variable_names))
end
function hasvariables(
    md::AbstractMultiModalDataset,
    i_modality::Integer,
    variable_names::AbstractVector{Symbol}
)
    return !(0 in _name2index(modality(md, i_modality), variable_names))
end
function hasvariables(
    md::AbstractMultiModalDataset,
    variable_names::AbstractVector{Symbol}
)
    return !(0 in _name2index(md, variable_names))
end

"""
    variableindex(df, variable_name)
    variableindex(md, i_modality, variable_name)
    variableindex(md, variable_name)

Return the index of the variable passed as a parameter to the function.
When `i_modality` is given it return the index of the variable in the subdataframe of the
modality specified by `i_modality`.
It returns 0 when the variable isn't in the modality specified by `i_modality`.

## PARAMETERS

* `df` is an AbstractDataFrame;
* `md` is an AbstractMultiModalDataset;
* `variable_name` is a Symbol and indicates the variable whose index you want to know;
* `i_modality` is and Integer and indicates of which modality you want to know the index of
    the variable.

## EXAMPLES

```julia-repl
julia> md = MultiModalDataset([[1, 2],[3]], DataFrame(:name => ["Python", "Julia"], :age => [25, 26], :sex => ['M', 'F']))
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

julia> md.data
2×3 DataFrame
 Row │ name    age    sex
     │ String  Int64  Char
─────┼─────────────────────
   1 │ Python     25  M
   2 │ Julia      26  F

julia> variableindex(md, :age)
2

julia> variableindex(md, :sex)
3

julia> variableindex(md, 1, :name)
1

julia> variableindex(md, 2, :name)
0

julia> variableindex(md, 2, :sex)
1

julia> variableindex(md.data, :age)
2
```
"""
function variableindex(df::AbstractDataFrame, variable_name::Symbol)
    return _name2index(df, variable_name)
end
function variableindex(
    md::AbstractMultiModalDataset,
    i_modality::Integer,
    variable_name::Symbol
)
    return _name2index(modality(md, i_modality), variable_name)
end
function variableindex(md::AbstractMultiModalDataset, variable_name::Symbol)
    return _name2index(md, variable_name)
end

"""
    sparevariables(md)

Return the indices of all the variables currently not present in any of the modalities of a
multimodal dataset.

## PARAMETERS

* `md` is a MultiModalDataset, which is the structure whose indices of the sparevariables
    are to be known.

## EXAMPLES

```julia-repl
julia> md = MultiModalDataset([[1],[3]], DataFrame(:name => ["Python", "Julia"], :age => [25, 26], :sex => ['M', 'F']))
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
2×1 SubDataFrame
 Row │ sex
     │ Char
─────┼──────
   1 │ M
   2 │ F
- Spare variables
   └─ dimension: 0
2×1 SubDataFrame
 Row │ age
     │ Int64
─────┼───────
   1 │    25
   2 │    26

julia> md.data
2×3 DataFrame
 Row │ name    age    sex
     │ String  Int64  Char
─────┼─────────────────────
   1 │ Python     25  M
   2 │ Julia      26  F

julia> sparevariables(md)
1-element Vector{Int64}:
 2
```
"""
function sparevariables(md::AbstractMultiModalDataset)::AbstractVector{<:Integer}
    return Int.(setdiff(1:nvariables(md), unique(cat(grouped_variables(md)..., dims = 1))))
end

"""
    variables(md, i)

Return the names as `Symbol`s of the variables of a multimodal dataset.

When called on a object of type `MultiModalDataset` a `Dict` is returned which will map the
modality index to an `AbstractVector` of `Symbol`s.

Note: the order of the variable names is granted to match the order of the variables
inside the modality.

If an index is passed as second argument then the names of the variables of the modality at
index `i` is returned in an `AbstractVector`.

Alternatively `nvariables` can be called on a single modality.

## PARAMETERS

* `md` is an MultiModalDataset;
* `i` is an Integer and indicates from which modality of the multimodal dataset to get the
    names of the variables.

## EXAMPLES

```julia-repl
julia> md = MultiModalDataset([[2],[3]], DataFrame(:name => ["Python", "Julia"], :age => [25, 26], :sex => ['M', 'F']))
● MultiModalDataset
   └─ dimensions: (0, 0)
- Modality 1 / 2
   └─ dimension: 0
2×1 SubDataFrame
 Row │ age
     │ Int64
─────┼───────
   1 │    25
   2 │    26
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
2×1 SubDataFrame
 Row │ name
     │ String
─────┼────────
   1 │ Python
   2 │ Julia

julia> variables(md)
Dict{Integer, AbstractVector{Symbol}} with 2 entries:
  2 => [:sex]
  1 => [:age]

julia> variables(md, 2)
1-element Vector{Symbol}:
 :sex

julia> variables(md, 1)
1-element Vector{Symbol}:
 :age

julia> mod2 = modality(md, 2)
2×1 SubDataFrame
 Row │ sex
     │ Char
─────┼──────
   1 │ M
   2 │ F

julia> variables(mod2)
1-element Vector{Symbol}:
 :sex
```
"""
variables(df::AbstractDataFrame) = Symbol.(names(df))
function variables(md::AbstractMultiModalDataset, i::Integer)
    @assert 1 ≤ i ≤ nmodalities(md) "Index ($i) must be a valid modality number " *
        "(1:$(nmodalities(md)))"

    return variables(modality(md, i))
end
function variables(md::AbstractMultiModalDataset)
    d = Dict{Integer,AbstractVector{Symbol}}()

    for i in 1:nmodalities(md)
        d[i] = variables(md, i)
    end

    return d
end

"""
    dropvariables!(md, i)
    dropvariables!(md, variable_name)
    dropvariables!(md, indices)
    dropvariables!(md, variable_names)
    dropvariables!(md, i_modality, indices)
    dropvariables!(md, i_modality, variable_names)

Drop the `i`-th variable from a multimodal dataset and return the multimodal dataset
without that variable.

## PARAMETERS

* `md` is an MultiModalDataset;
* `i` is an Integer that indicates the index of the variable to drop;
* `variable_name` is a Symbol that idicates the variable to drop;
* `indices` is an AbstractVector{Integer} that indicates the indices of the variable to
    drop;
* `variable_names` is an AbstractVector{Symbol} that indicates the variables to drop.
* `i_modality`: index of the modality; if this parameter is specified `indcies` are relative to the
    `i_modality`-th modality

## EXAMPLES

```julia-repl
julia> md = MultiModalDataset([[1, 2],[3, 4, 5]], DataFrame(:name => ["Python", "Julia"], :age => [25, 26], :sex => ['M', 'F'], :height => [180, 175], :weight => [80, 60]))
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
2×3 SubDataFrame
 Row │ sex   height  weight
     │ Char  Int64   Int64
─────┼──────────────────────
   1 │ M        180      80
   2 │ F        175      60

julia> dropvariables!(md, 4)
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
2×2 SubDataFrame
 Row │ sex   weight
     │ Char  Int64
─────┼──────────────
   1 │ M         80
   2 │ F         60

julia> dropvariables!(md, :name)
● MultiModalDataset
   └─ dimensions: (0, 0)
- Modality 1 / 2
   └─ dimension: 0
2×1 SubDataFrame
 Row │ age
     │ Int64
─────┼───────
   1 │    25
   2 │    26
- Modality 2 / 2
   └─ dimension: 0
2×2 SubDataFrame
 Row │ sex   weight
     │ Char  Int64
─────┼──────────────
   1 │ M         80
   2 │ F         60

julia> dropvariables!(md, [1,3])
[ Info: Variable 1 was last variable of modality 1: removing modality
● MultiModalDataset
   └─ dimensions: (0,)
- Modality 1 / 1
   └─ dimension: 0
2×1 SubDataFrame
 Row │ sex
     │ Char
─────┼──────
   1 │ M
   2 │ F
```
TODO: To be reviewed
"""
function dropvariables!(md::AbstractMultiModalDataset, i::Integer)
    @assert 1 ≤ i ≤ nvariables(md) "Variable $(i) is not a valid attibute index " *
        "(1:$(nvariables(md)))"

    j = 1
    while j ≤ nmodalities(md)
        desc = grouped_variables(md)[j]
        if i in desc
            removevariable_frommodality!(md, j, i)
        else
            j += 1
        end
    end

    select!(data(md), setdiff(collect(1:nvariables(md)), i))

    for (i_modality, desc) in enumerate(grouped_variables(md))
        for (i_var, var) in enumerate(desc)
            if var > i
                grouped_variables(md)[i_modality][i_var] = var - 1
            end
        end
    end

    return md
end
function dropvariables!(md::AbstractMultiModalDataset, variable_name::Symbol)
    @assert hasvariables(md, variable_name) "MultiModalDataset does not contain " *
        "variable $(variable_name)"

    return dropvariables!(md, _name2index(md, variable_name))
end
function dropvariables!(md::AbstractMultiModalDataset, indices::AbstractVector{<:Integer})
    for i in indices
        @assert 1 ≤ i ≤ nvariables(md) "Index $(i) does not correspond to an " *
            "variable (1:$(nvariables(md)))"
    end

    var_names = Symbol.(names(data(md)))

    for i_var in sort!(deepcopy(indices), rev = true)
        dropvariables!(md, i_var)
    end

    return md
end
function dropvariables!(
    md::AbstractMultiModalDataset,
    variable_names::AbstractVector{Symbol}
)
    for var_name in variable_names
        @assert hasvariables(md, var_name) "MultiModalDataset does not contain " *
            "variable $(var_name)"
    end

    return dropvariables!(md, _name2index(md, variable_names))
end
function dropvariables!(
    md::AbstractMultiModalDataset,
    i_modality::Integer,
    indices::Union{Integer, AbstractVector{<:Integer}}
)
    var_ids = [ indices... ]
    !(1 <= i_modality <= nmodalities(md)) &&
        throw(DimensionMismatch("Index $(i_modality) does not correspond to a modality"))
    varidx = grouped_variables(md)[i_modality][var_ids]
    return dropvariables!(md, varidx)
end
function dropvariables!(
    md::AbstractMultiModalDataset,
    i_modality::Integer,
    variable_names::Union{Symbol, AbstractVector{<:Symbol}}
)
    variable_names = [ variable_names... ]
    !(1 <= i_modality <= nmodalities(md)) &&
        throw(DimensionMismatch("Index $(i_modality) does not correspond to a modality"))
    !issubset(variable_names, variables(md, i_modality)) &&
        throw(DomainError(variable_names, "One or more variables in `var_names` are not in variables modality"))
    varidx = _name2index(md, variable_names)
    return dropvariables!(md, varidx)
end

"""
    keeponlyvariables!(md, indices)
    keeponlyvariables!(md, variable_names)

Drop all variables that do not correspond to the indices present in `indices` from a
multimodal dataset.

Note: if the dropped variables are present in some modality they will also be removed from
them. This can lead to the removal of modalities as side effect.

## PARAMETERS

* `md` is a MultiModalDataset;
* `indices` is and AbstractVector{Integer} that indicates which indices to keep in the
    multimodal dataset;
* `variable_names` is a AbstractVector{Symbol} that indicates which variables to keep in
    the multimodal dataset.

## EXAMPLES

```julia-repl
julia> md = MultiModalDataset([[1, 2],[3, 4, 5],[5]], DataFrame(:name => ["Python", "Julia"], :age => [25, 26], :sex => ['M', 'F'], :height => [180, 175], :weight => [80, 60]))
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
2×3 SubDataFrame
 Row │ sex   height  weight
     │ Char  Int64   Int64
─────┼──────────────────────
   1 │ M        180      80
   2 │ F        175      60
- Modality 3 / 3
   └─ dimension: 0
2×1 SubDataFrame
 Row │ weight
     │ Int64
─────┼────────
   1 │     80
   2 │     60

julia> keeponlyvariables!(md, [1,3,4])
[ Info: Variable 5 was last variable of modality 3: removing modality
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
 Row │ sex   height
     │ Char  Int64
─────┼──────────────
   1 │ M        180
   2 │ F        175

julia> keeponlyvariables!(md, [:name, :sex])
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
2×1 SubDataFrame
 Row │ sex
     │ Char
─────┼──────
   1 │ M
   2 │ F
```
TODO: review
"""
function keeponlyvariables!(
    md::AbstractMultiModalDataset,
    indices::AbstractVector{<:Integer}
)
    return dropvariables!(md, setdiff(collect(1:nvariables(md)), indices))
end
function keeponlyvariables!(
    md::AbstractMultiModalDataset,
    variable_names::AbstractVector{Symbol}
)
    for var_name in variable_names
        @assert hasvariables(md, var_name) "MultiModalDataset does not contain " *
            "variable $(var_name)"
    end

    return dropvariables!(
        md, setdiff(collect(1:nvariables(md)), _name2index(md, variable_names)))
end
function keeponlyvariables!(
    md::AbstractMultiModalDataset,
    variable_names::AbstractVector{<:AbstractVector{Symbol}}
)
    for var_name in variable_names
        @assert hasvariables(md, var_name) "MultiModalDataset does not contain " *
            "variable $(var_name)"
    end

    return dropvariables!(
        md, setdiff(collect(1:nvariables(md)), _name2index(md, variable_names)))
end

"""
    dropsparevariables!(md)

Drop all variables that are not present in any of the modalities in a multimodal dataset.

## PARAMETERS

* `md` is a MultiModalDataset, that is the structure at which sparevariables will be
    dropped.

## EXAMPLES

```julia-repl
julia> md = MultiModalDataset([[1]], DataFrame(:age => [30, 9], :name => ["Python", "Julia"]))
● MultiModalDataset
   └─ dimensions: (0,)
- Modality 1 / 1
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


julia> dropsparevariables!(md)
2×1 DataFrame
 Row │ name
     │ String
─────┼────────
   1 │ Python
   2 │ Julia
```
"""
function dropsparevariables!(md::AbstractMultiModalDataset)
    spare = sort!(sparevariables(md), rev = true)

    var_names = Symbol.(names(data(md)))
    result = DataFrame([(var_names[i] => data(md)[:,i]) for i in reverse(spare)]...)

    for i_var in spare
        dropvariables!(md, i_var)
    end

    return result
end
