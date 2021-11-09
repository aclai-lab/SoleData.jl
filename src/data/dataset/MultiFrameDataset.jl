
# -------------------------------------------------------------
# MultiFrameDataset

"""
    MultiFrameDataset(frames_descriptor, df)

Create a `MultiFrameDataset` from a `DataFrame`, `df`, initializing frames accordingly to
`frames_descriptor` parameter.

`frames_descriptor` is an `AbstractVector` of frame descriptor which are `AbstractVector`s
of `Integer`s representing the index of the attributes selected for that frame.

The order matters for both the frames indices and the attributes in them.

```jldoctest
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

julia> mfd = MultiFrameDataset([[2]], df)
● MultiFrameDataset
   └─ dimensions: (0,)
- Frame 1 / 1
   └─ dimension: 0
2×1 SubDataFrame
 Row │ name
     │ String
─────┼────────
   1 │ Python
   2 │ Julia
- Spare attributes
   └─ dimension: mixed
2×3 SubDataFrame
 Row │ age    stat1                              stat2
     │ Int64  Array…                             Array…
─────┼─────────────────────────────────────────────────────────────────────────────
   1 │    30  [0.841471, 0.909297, 0.14112, -0…  [0.540302, -0.416147, -0.989992,…
   2 │     9  [0.540302, -0.416147, -0.989992,…  [0.841471, 0.909297, 0.14112, -0…
```

    MultiFrameDataset(df; group = :none)

Create a `MultiFrameDataset` from a `DataFrame`, `df`, automatically selecting frames.

Selection of frames can be controlled by the parameter `group` which can be:

- `:none` (default): no frame will be created
- `:all`: all attributes will be grouped by their [`dimension`](@ref)
- a list of dimensions which will be grouped.

Note: `:all` and `:none` are the only `Symbol`s accepted by `group`.

# TODO group should be [0] by default?
# Examples
```jldoctest
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

julia> mfd = MultiFrameDataset(df)
● MultiFrameDataset
   └─ dimensions: ()
- Spare attributes
   └─ dimension: mixed
2×4 SubDataFrame
 Row │ age    name    stat1                              stat2                             ⋯
     │ Int64  String  Array…                             Array…                            ⋯
─────┼──────────────────────────────────────────────────────────────────────────────────────
   1 │    30  Python  [0.841471, 0.909297, 0.14112, -0…  [0.540302, -0.416147, -0.989992,… ⋯
   2 │     9  Julia   [0.540302, -0.416147, -0.989992,…  [0.841471, 0.909297, 0.14112, -0…


julia> mfd = MultiFrameDataset(df; group = :all)
● MultiFrameDataset
   └─ dimensions: (0, 1)
- Frame 1 / 2
   └─ dimension: 0
2×2 SubDataFrame
 Row │ age    name
     │ Int64  String
─────┼───────────────
   1 │    30  Python
   2 │     9  Julia
- Frame 2 / 2
   └─ dimension: 1
2×2 SubDataFrame
 Row │ stat1                              stat2
     │ Array…                             Array…
─────┼──────────────────────────────────────────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…  [0.540302, -0.416147, -0.989992,…
   2 │ [0.540302, -0.416147, -0.989992,…  [0.841471, 0.909297, 0.14112, -0…


julia> mfd = MultiFrameDataset(df; group = [0])
● MultiFrameDataset
   └─ dimensions: (0, 1, 1)
- Frame 1 / 3
   └─ dimension: 0
2×2 SubDataFrame
 Row │ age    name
     │ Int64  String
─────┼───────────────
   1 │    30  Python
   2 │     9  Julia
- Frame 2 / 3
   └─ dimension: 1
2×1 SubDataFrame
 Row │ stat1
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…
   2 │ [0.540302, -0.416147, -0.989992,…
- Frame 3 / 3
   └─ dimension: 1
2×1 SubDataFrame
 Row │ stat2
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.540302, -0.416147, -0.989992,…
   2 │ [0.841471, 0.909297, 0.14112, -0…
```
"""
struct MultiFrameDataset <: AbstractMultiFrameDataset
    frame_descriptor::AbstractVector{AbstractVector{Integer}}
    data::AbstractDataFrame

    function MultiFrameDataset(
        frames_descriptor::AbstractVector{<:AbstractVector{<:Integer}},
        df::AbstractDataFrame
    )
        return new(frames_descriptor, df)
    end

    function MultiFrameDataset(
        df::AbstractDataFrame;
        group::Union{Symbol,AbstractVector{<:Integer}} = :none
    )
        @assert isa(group, AbstractVector) || group in [:all, :none] "group can be " *
            "`:all`, `:none` or an AbstractVector of dimensions"

        if group == :none
            return new([], df)
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

        return new(append!(map(x -> x[2], desc), spare), df)
    end
end

# -------------------------------------------------------------
# MultiFrameDataset - accessors

descriptor(mfd::MultiFrameDataset) = mfd.frame_descriptor
frame_descriptor(mfd::MultiFrameDataset) = mfd.frame_descriptor
data(mfd::MultiFrameDataset) = mfd.data

# -------------------------------------------------------------
# MultiFrameDataset - informations

function show(io::IO, mfd::MultiFrameDataset)
    println(io, "● MultiFrameDataset")
    println(io, "   └─ dimensions: $(dimension(mfd))")
    for (i, frame) in enumerate(mfd)
        println(io, "- Frame $(i) / $(nframes(mfd))")
        println(io, "   └─ dimension: $(dimension(frame))")
        println(io, frame)
    end
    spare_attrs = spareattributes(mfd)
    if length(spare_attrs) > 0
        spare_df = @view data(mfd)[:,spare_attrs]
        println(io, "- Spare attributes")
        println(io, "   └─ dimension: $(dimension(spare_df))")
        println(io, spare_df)
    end
end

# -------------------------------------------------------------
# MultiFrameDataset - utils

"""
    _empty(mfd)

Get a copy of `mfd` multiframe dataset with no instances.

Note: since the returned AbstractMultiFrameDataset will be empty its columns types will be
`Any`.
"""
function _empty(mfd::MultiFrameDataset)
    return MultiFrameDataset(
        deepcopy(descriptor(mfd)),
        df = DataFrame([attr_name => [] for attr_name in Symbol.(names(data(mfd)))])
    )
end
