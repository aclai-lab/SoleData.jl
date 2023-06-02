```@meta
CurrentModule = SoleData
```

# [Description](@id man-description)

Just like `DataFrame`s, `MultiModalDataset`s can be described using the method
[`describe`](@ref):

```julia-repl
julia> ts_cos = [cos(i) for i in 1:50000];

julia> ts_sin = [sin(i) for i in 1:50000];

julia> df_data = DataFrame(
                         :id => [1, 2],
                         :age => [30, 9],
                         :name => ["Python", "Julia"],
                         :stat => [deepcopy(ts_sin), deepcopy(ts_cos)]
                     );

julia> md = MultiModalDataset([[2,3], [4]], df_data);

julia> description = describe(md)
2-element Vector{DataFrame}:
 2×7 DataFrame
 Row │ variable  mean    min    median  max     nmissing  eltype   
     │ Symbol    Union…  Any    Union…  Any     Int64     DataType
─────┼─────────────────────────────────────────────────────────────
   1 │ age       19.5    9      19.5    30             0  Int64
   2 │ name              Julia          Python         0  String
 1×7 DataFrame
 Row │ Variables  mean                               min                      ⋯
     │ Symbol      Array…                             Array…                   ⋯
─────┼──────────────────────────────────────────────────────────────────────────
   1 │ stat        AbstractFloat[8.63372e-6; -2.848…  AbstractFloat[-1.0; -1.0 ⋯
                                                               5 columns omitted

```

the `describe` implementation for `MultiModalDataset`s will try to find the best
_statistical measures_ that can be used to the type of data the modality contains.

In the example the 2nd modality, which contains variables (just one in the example) of data
of type `Vector{Float64}`, was described by applying the well known 22 features from
the package [Catch22.jl](https://github.com/brendanjohnharris/Catch22.jl) plus `maximum`,
`minimum` and `mean` as the vectors were time series.

```@docs
describe
```
