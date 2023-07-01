```@meta
CurrentModule = SoleData
```

# SoleData

The aim of this package is to provide a simple and comfortable interface for managing
multimodal data.
It is built
 on top of
[DataFrames.jl](https://github.com/JuliaData/DataFrames.jl/)
with Machine learning applications in mind.

```@contents
```

## Installation

Currently this packages is still not registered so you need to run the following
commands in a Julia REPL to install it:

```julia
import Pkg
Pkg.add("SoleData")
```

To install the developement version, run:

```julia
import Pkg
Pkg.add("https://aclai-lab.github.io/SoleData.jl#dev")
```


## Usage

To instantiate a multimodal dataset, use the [`MultiModalDataset`](@ref)
constructor by providing: *a)* a
`DataFrame` containing all variables from different modalities, and 
*b)* a
`Vector{Vector{Union{Symbol,String,Int64}}}` object representing a
grouping of some of the variables (identified by column index or name)
into different modalities.

```julia-repl
julia> using SoleData

julia> ts_cos = [cos(i) for i in 1:50000];

julia> ts_sin = [sin(i) for i in 1:50000];

julia> df_data = DataFrame(
                  :id => [1, 2],
                  :age => [30, 9],
                  :name => ["Python", "Julia"],
                  :stat => [deepcopy(ts_sin), deepcopy(ts_cos)]
              )
2×4 DataFrame
 Row │ id     age    name    stat                              
     │ Int64  Int64  String  Array…                            
─────┼─────────────────────────────────────────────────────────
   1 │     1     30  Python  [0.841471, 0.909297, 0.14112, -0…
   2 │     2      9  Julia   [0.540302, -0.416147, -0.989992,…

julia> grouped_variables = [[2,3], [4]]; # group 2nd and 3rd variables in the first modality
                                         # the 4th variable in the second modality and
                                         # leave the first variable as a "spare variable"

julia> md = MultiModalDataset(df_data, grouped_variables)
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
2×1 SubDataFrame
 Row │ stat                              
     │ Array…                            
─────┼───────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…
   2 │ [0.540302, -0.416147, -0.989992,…
- Spare variables
  └─ dimensionality: 0
2×1 SubDataFrame
 Row │ id    
     │ Int64
─────┼───────
   1 │     1
   2 │     2

```

Now `md` holds a `MultiModalDataset` and all of its modalities can be
conveniently iterated as elements of a `Vector`:

```julia-repl
julia> for (i, f) in enumerate(md)
           println("Modality: ", i)
           println(f)
           println()
       end
Modality: 1
2×2 SubDataFrame
 Row │ age    name   
     │ Int64  String
─────┼───────────────
   1 │    30  Python
   2 │     9  Julia

Modality: 2
2×1 SubDataFrame
 Row │ stat                              
     │ Array…                            
─────┼───────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…
   2 │ [0.540302, -0.416147, -0.989992,…
```

Note that each element of a `MultiModalDataset` is a `SubDataFrame`:

```julia-repl
julia> eltype(md)
SubDataFrame

```

!!! note "Spare variables"
    Spare variables will never be seen when accessing a `MultiModalDataset` through its
    iterator interface. To access them see [`sparevariables`](@ref).
