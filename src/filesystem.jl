
# -------------------------------------------------------------
# AbstractMultiFrameDataset - filesystem operations

const _ds_inst_prefix = "Example_"
const _ds_frame_prefix = "Frame_"
const _ds_metadata = "Metadata.txt"
const _ds_labels = "Labels.csv"

function _parse_dim_tuple(t::AbstractString)
    t = strip(t, ['(', ')', '\n', ',', ' '])
    div = contains(t, ",") ? "," : " "
    return Tuple(parse.(Int64, split(t, div; keepempty = false)))
end

function _read_dataset_metadata(datasetdir::AbstractString)
    @assert isfile(joinpath(datasetdir, _ds_metadata)) "Missing $(_ds_metadata) in dataset " *
        "$(datasetdir)"

    file = open(joinpath(datasetdir, _ds_metadata))

    dict = Dict{String,Any}()
    for (k, v) in split.(filter(x -> length(x) > 0, strip.(readlines(file))), '=')
        k = strip(k)
        v = strip(v)
        if k == "name"
            dict[k] = v
        elseif k == "supervised"
            dict[k] = parse(Bool, v)
        elseif k == "num_frames" ||
            !isnothing(match(r"frame[[:digit:]]+", string(k))) ||
            k == "num_classes"
                dict[k] = parse(Int64, v)
        else
            @warn "Unknown key-value pair found in " *
                "$(joinpath(datasetdir, _ds_metadata)): $(k)=$(v)"
        end
    end

    if dict["supervised"] && haskey(dict, "num_classes") && dict["num_classes"] < 1
        @warn "Dataset $(dict["name"]) is marked as `supervised` but has `num_classes` = 0"
    end

    close(file)

    return dict
end

function _read_example_metadata(datasetdir::AbstractString, inst_id::Integer)
    @assert isfile(joinpath(
        datasetdir,
        "$(_ds_inst_prefix)$(string(inst_id))",
        _ds_metadata
    )) "Missing $(_ds_metadata) in dataset `$(_ds_inst_prefix)$(string(inst_id))` in " *
        "`$(datasetdir)`"

    file = open(joinpath(datasetdir, "$(_ds_inst_prefix)$(string(inst_id))", _ds_metadata))

    dict = Dict{String,Any}()
    for (k, v) in split.(filter(x -> length(x) > 0, strip.(readlines(file))), '=')
        k = strip(k)
        v = strip(v)
        if startswith(k, "dim")
            dict[k] = _parse_dim_tuple(v)
        else
            dict[k] = v
        end
    end

    close(file)

    return dict
end

function _read_labels(
    datasetdir::AbstractString;
    shufflelabels::AbstractVector{Symbol} = Symbol[], # TODO: add tests for labels shuffling
    rng::Union{<:AbstractRNG,<:Integer} = Random.GLOBAL_RNG
)
    @assert isfile(joinpath(datasetdir, _ds_labels)) "Missing $(_ds_labels) in dataset " *
        "$(datasetdir)"

    df = CSV.read(joinpath(datasetdir, _ds_labels), DataFrame; types = String)

    df[!,:id] = parse.(Int64, replace.(df[!,:id], _ds_inst_prefix => ""))

    rng = isa(rng, Integer) ? MersenneTwister(rng) : rng
    for l in shufflelabels
        @assert l in Symbol.(names(df)[2:end]) "`$l` is not a label of the dataset"
        df[!,l] = shuffle(rng, df[:,l])
    end

    return df
end

"""
    datasetinfo(datasetpath; onlywithlabels = [], shufflelabels = [], rng = Random.GLOBAL_RNG)

Show dataset size on disk and return a Touple with first element a Vector of selected IDs,
second element the labels DataFrame or nothing and third element the total size in bytes.

## PARAMETERS

* `onlywithlabels`, it's used to select which portion of the Dataset to load, by specifying
    labels and their values to use as filters. See [`loaddataset`](@ref) for more info.
* `shufflelabels` is an AbstractVector of names of labels to shuffle (default = [], means
    no shuffle).
* `rng` the RandomNumberGenerator to be used when shuffling (for reproducibility); can be
    either a Integer (used as seed for MersenneTwister) or an AbstractRNG.

"""
function datasetinfo(
    datasetpath::AbstractString;
    onlywithlabels::AbstractVector{<:AbstractVector{<:Pair{<:AbstractString,<:AbstractVector{<:Any}}}} =
        AbstractVector{Pair{AbstractString,AbstractVector{Any}}}[],
    kwargs...
)
    @assert isdir(datasetpath) "Dataset at path $(datasetpath) does not exist"

    ds_metadata = _read_dataset_metadata(datasetpath)

    if ds_metadata["supervised"] && !isfile(joinpath(datasetpath, _ds_labels))
        @warn "Dataset $(ds_metadata["name"]) is marked as `supervised` but has no " *
            "file `$(_ds_labels)`"
    end

    function isexdir(name::AbstractString)
        return isdir(joinpath(datasetpath, name)) && startswith(name, _ds_inst_prefix)
    end

    examples_ids = sort!(parse.(Int64, replace.(
        filter(isexdir, readdir(datasetpath)),
        _ds_inst_prefix => ""
    )))

    labels = nothing
    if ds_metadata["supervised"] ||
            (haskey(ds_metadata, "num_classes") && ds_metadata["num_classes"] > 0)
        labels = _read_labels(datasetpath; kwargs...)
        missing_in_labels = setdiff(labels[:,:id], examples_ids)
        there_are_missing = false
        if length(missing_in_labels) > 0
            there_are_missing = true
            @warn "Following exmaples IDs are present in $(_ds_labels) but there isn't a " *
                "directory for them: $(missing_in_labels)"
        end
        missing_in_dirs = setdiff(examples_ids, labels[:,:id])
        if length(missing_in_dirs) > 0
            there_are_missing = true
            @warn "Following exmaples IDs are present on filsystem but arn't referenced by " *
                "$(_ds_labels): $(missing_in_dirs)"
        end
        if there_are_missing
            examples_ids = sort!(collect(intersect(examples_ids, labels[:,:id])))
            @warn "Will be considered only instances with IDs: $(examples_ids)"
        end
    end

    if length(onlywithlabels) > 0
        if isnothing(labels)
            @warn "A filter was passed but no $(_ds_labels) was found in this dataset: all " *
                "instances will be used"
        else
            # CHECKS
            keys_not_found = String[]
            labels_cols = names(labels)[2:end]
            for i in 1:length(onlywithlabels)
                for k in [pair[1] for pair in onlywithlabels[i]]
                    if !(k in labels_cols)
                        push!(keys_not_found, k)
                    end
                end
            end
            if length(keys_not_found) > 0
                throw(ErrorException("Key(s) provided as filters not found: " *
                    "$(unique(keys_not_found)); availabels are $(labels_cols)"))
            end

            # ACTUAL FILTERING
            filtered_ids = Integer[]
            for i in 1:length(onlywithlabels)
                for filters in [Base.product([Base.product((key,), value)
                        for (key, value) in onlywithlabels[i]]...)...]

                    nt = NamedTuple([Symbol(fs[1]) => string(fs[2]) for fs in filters])
                    grouped_by_keys = groupby(labels, collect(keys(nt)))

                    if haskey(grouped_by_keys, nt)
                        push!(filtered_ids, grouped_by_keys[nt][:,1]...)
                    else
                        @warn "No example found for combination of labels $(nt): check " *
                            "if the proper Type was used"
                    end
                end
            end
            examples_ids = sort(collect(intersect(examples_ids, unique(filtered_ids))))
        end
    end

    totalsize = 0
    for id in examples_ids
        ex_metadata = _read_example_metadata(datasetpath, id)
        # TODO: perform some checks on metadata
        for frame in 1:ds_metadata["num_frames"]
            totalsize += filesize(joinpath(
                datasetpath,
                "$(_ds_inst_prefix)$(string(id))",
                "$(_ds_frame_prefix)$(frame).csv"
            ))
        end
    end

    if !isnothing(labels)
        labels = labels[findall(id -> id in examples_ids, labels[:,:id]),:]
    end

    return examples_ids, labels, totalsize
end

function _load_instance(
    datasetpath::AbstractString,
    inst_id::Integer;
    types::Union{DataType,Nothing} = nothing
)
    inst_metadata = _read_example_metadata(datasetpath, inst_id)
    instancedir = joinpath(datasetpath, "$(_ds_inst_prefix)$(inst_id)")

    type_info = isnothing(types) ? NamedTuple() : (types = types,)

    frame_reg = Regex("^$(_ds_frame_prefix)([[:digit:]]+).csv\$")
    function isframefile(path::AbstractString)
        return isfile(joinpath(instancedir, path)) && !isnothing(match(frame_reg, path))
    end

    function unlinearize_attr(p::Pair{Symbol,<:Any}, dims::Tuple)
        return p[1] => unlinearize_data(p[2], dims)
    end
    function unlinearize_frame(ps::AbstractVector{<:Pair{Symbol,<:Any}}, dims::Tuple)
        return [unlinearize_attr(p, dims) for p in ps]
    end
    function load_frame(path::AbstractString, dims::Tuple)
        return OrderedDict(unlinearize_frame(
            collect(CSV.read(path, pairs; type_info...)),
            dims
        ))
    end

    frames = filter(isframefile, readdir(instancedir))
    frames_num = sort!([match(frame_reg, f).captures[1] for f in frames])

    result = Vector{OrderedDict}(undef, length(frames_num))
    # TODO: address problem with Threads.@threads
    # (`@threads :static` cannot be used concurrently or nested)
    for (i, f) in collect(enumerate(frames_num))
        result[i] = load_frame(
            joinpath(instancedir, "$(_ds_frame_prefix)$(f).csv"),
            inst_metadata[string("dim_frame_", i)]
        )
    end

    return result
end

"""
    loaddataset(datasetpath; onlywithlabels = [], shufflelabels = [], rng = Random.GLOBAL_RNG)

Create a MultiFrameDataset or a LabeledMultiFrameDataset from a Dataset, based on the
presence of file Labels.csv.

## PARAMETERS

* `datasetpath` is an AbstractString that denote the Dataset's position;
* `onlywithlabels` is an AbstractVector{AbstractVector{Pair{AbstractString,AbstractVector{Any}}}}
    and it's used to select which portion of the Dataset to load, by specifying labels and
    their values.
    Beginning from the center, each Pair{AbstractString,AbstractVector{Any}} must contain,
    as AbstractString the label's name, and, as AbstractVector{Any} the values of that label.
    Each Pair in one Vector must refer to a different label, so if the Dataset has in total
    n labels, this Vector of Pair can contain maximun n element. That's because the elements
    will combine with each other.
    Every Vector of Pair act as a filter.
    Note that the same label can be used in different Vector of Pair as they don't combine
    with each other.
    If `onlywithlabels` is an empty Vector (default) the function will load the entire
    Dataset.
* `shufflelabels` is an AbstractVector of names of labels to shuffle (default = [], means
    no shuffle).
* `rng` the RandomNumberGenerator to be used when shuffling (for reproducibility); can be
    either a Integer (used as seed for MersenneTwister) or an AbstractRNG.

## EXAMPLES

```jldoctest
julia> df_data = DataFrame(
           :id => [1, 2, 3, 4, 5],
           :age => [30, 9, 30, 40, 9],
           :name => ["Python", "Julia", "C", "Java", "R"],
           :stat => [deepcopy(ts_sin), deepcopy(ts_cos), deepcopy(ts_sin), deepcopy(ts_cos), deepcopy(ts_sin)]
       )
5×4 DataFrame
 Row │ id     age    name    stat
     │ Int64  Int64  String  Array…
─────┼─────────────────────────────────────────────────────────
   1 │     1     30  Python  [0.841471, 0.909297, 0.14112, -0…
   2 │     2      9  Julia   [0.540302, -0.416147, -0.989992,…
   3 │     3     30  C       [0.841471, 0.909297, 0.14112, -0…
   4 │     4     40  Java    [0.540302, -0.416147, -0.989992,…
   5 │     5      9  R       [0.841471, 0.909297, 0.14112, -0…

julia> lmfd =LabeledMultiFrameDataset(
    [2,3],
    MultiFrameDataset([[4]], deepcopy(df_data))
)
● LabeledMultiFrameDataset
   ├─ labels
   │   ├─ age: Set([9, 30, 40])
   │   └─ name: Set(["C", "Julia", "Python", "Java", "R"])
   └─ dimensions: (1,)
- Frame 1 / 1
   └─ dimension: 1
5×1 SubDataFrame
 Row │ stat
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.841471, 0.909297, 0.14112, -0…
   2 │ [0.540302, -0.416147, -0.989992,…
   3 │ [0.841471, 0.909297, 0.14112, -0…
   4 │ [0.540302, -0.416147, -0.989992,…
   5 │ [0.841471, 0.909297, 0.14112, -0…
- Spare attributes
   └─ dimension: 0
5×1 SubDataFrame
 Row │ id
     │ Int64
─────┼───────
   1 │     1
   2 │     2
   3 │     3
   4 │     4
   5 │     5

julia> savedataset("langs", lmfd, force = true)

julia> loaddataset("langs", onlywithlabels = [ ["name" => ["Julia"], "age" => ["9"]] ] )
Instances count: 1
Total size: 981670 bytes
● LabeledMultiFrameDataset
   ├─ labels
   │   ├─ age: Set(["9"])
   │   └─ name: Set(["Julia"])
   └─ dimensions: (1,)
- Frame 1 / 1
   └─ dimension: 1
1×1 SubDataFrame
 Row │ stat
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.540302, -0.416147, -0.989992,…
- Spare attributes
   └─ dimension: 0
1×1 SubDataFrame
 Row │ id
     │ Int64
─────┼───────
   1 │     2

julia> loaddataset("langs", onlywithlabels = [ ["name" => ["Julia"], "age" => ["30"]] ] )
Instances count: 0
Total size: 0 bytes
ERROR: AssertionError: No instance found

julia> loaddataset("langs", onlywithlabels = [ ["name" => ["Julia"]] , ["age" => ["9"]] ] )
Instances count: 2
Total size: 1963537 bytes
● LabeledMultiFrameDataset
   ├─ labels
   │   ├─ age: Set(["9"])
   │   └─ name: Set(["Julia", "R"])
   └─ dimensions: (1,)
- Frame 1 / 1
   └─ dimension: 1
2×1 SubDataFrame
 Row │ stat
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.540302, -0.416147, -0.989992,…
   2 │ [0.841471, 0.909297, 0.14112, -0…
- Spare attributes
   └─ dimension: 0
2×1 SubDataFrame
 Row │ id
     │ Int64
─────┼───────
   1 │     2
   2 │     5

julia> loaddataset("langs", onlywithlabels = [ ["name" => ["Julia"]], ["name" => ["C"], "age" => ["30"]] ] )
Instances count: 2
Total size: 1963537 bytes
● LabeledMultiFrameDataset
    ├─ labels
    │   ├─ age: Set(["9", "30"])
    │   └─ name: Set(["C", "Julia"])
    └─ dimensions: (1,)
- Frame 1 / 1
    └─ dimension: 1
2×1 SubDataFrame
 Row │ stat
     │ Array…
─────┼───────────────────────────────────
   1 │ [0.540302, -0.416147, -0.989992,…
   2 │ [0.841471, 0.909297, 0.14112, -0…
- Spare attributes
    └─ dimension: 0
2×1 SubDataFrame
 Row │ id
     │ Int64
─────┼───────
   1 │     2
   2 │     3
```
"""
function loaddataset(
    datasetpath::AbstractString;
    types::Union{DataType,Nothing} = nothing,
    kwargs...
)
    selected_ids, labels, datasetsize = datasetinfo(datasetpath; kwargs...)

    @assert length(selected_ids) > 0 "No instance found"

    instance_frames = _load_instance(datasetpath, selected_ids[1]; types = types)
    frames_cols = [Symbol.(attr_name) for attr_name in keys.(instance_frames)]

    df = DataFrame(
        :id => [selected_ids[1]],
        [Symbol(k) => [v] for frame in instance_frames for (k, v) in frame]...;
        makeunique = true
    )

    for id in selected_ids[2:end]
        curr_row = Any[id]
        for (i, frame) in enumerate(_load_instance(datasetpath, id; types = types))
            for attr_name in frames_cols[i]
                push!(curr_row, frame[attr_name])
            end
        end
        push!(df, curr_row)
    end

    frame_descriptor = Vector{Integer}[]
    df_names = Symbol.(names(df))
    for frame in frames_cols
        push!(frame_descriptor, [findfirst(x -> x == k, df_names) for k in frame])
    end

    mfd = MultiFrameDataset(frame_descriptor, df)

    if !isnothing(labels)
        orig_length = nattributes(mfd)

        for l in names(labels)[2:end]
            insertattributes!(mfd, Symbol(l), labels[:,l])
        end

        return LabeledMultiFrameDataset(collect((orig_length+1):nattributes(mfd)), mfd)
    else
        return mfd
    end
end

"""
    savedataset(datasetpath, mfd; instance_ids, name, force = false)

Save `mfd` AbstractMultiFrameDataset on disk at path `datasetpath` in the following format:

datasetpath
    ├─ Example_1
    │     └─ Frame_1.csv
    │     └─ Frame_2.csv
    │     └─ ...
    │     └─ Frame_n.csv
    │     └─ Metadata.txt
    ├─ Example_2
    │     └─ Frame_1.csv
    │     └─ Frame_2.csv
    │     └─ ...
    │     └─ Frame_n.csv
    │     └─ Metadata.txt
    ├─ ...
    ├─ Example_n
    ├─ Metadata.txt
    └─ Labels.csv

## PARAMETERS

* `instance_ids` is a AbstractVector{Integer} that denote the identifier of the instances,
* `name` is an AbstractString and denote the name of the Dataset, that will be saved in the
    Metadata of the Dataset,
* `force` is a Bool, if it's set to `true`, then in case `datasetpath` already exists, it will
    be overwritten otherwise the operation will be aborted. (default = `false`)
* `labels_indices` is a AbstractVector{Integer} and contains the indices of the labels'
    column (allowed only when passing a MultiFrameDataset)

Alternatively to an AbstractMultiFrameDataset a DataFrame can be passed as second argument.
If this is the case a third positional argument is required representing the
`frame_descriptor` of the dataset. See [`MultiFrameDataset`](@ref) for syntax of
`frame_descriptor`.
"""
function savedataset(
    datasetpath::AbstractString, lmfd::AbstractLabeledMultiFrameDataset;
    kwargs...
)
    return savedataset(
        datasetpath, dataset(lmfd);
        labels_indices = labels_descriptor(lmfd),
        kwargs...
    )
end

function savedataset(
    datasetpath::AbstractString, mfd::AbstractMultiFrameDataset;
    kwargs...
)
    return savedataset(
        datasetpath, data(mfd),
        frame_descriptor(mfd);
        kwargs...
    )
end

function savedataset(
    datasetpath::AbstractString,
    df::AbstractDataFrame,
    frame_descriptor::AbstractVector{<:AbstractVector{<:Integer}} = [collect(1:ncol(df))];
    instance_ids::AbstractVector{<:Integer} = 1:nrow(df),
    labels_indices::AbstractVector{<:Integer} = Int[],
    name::AbstractString = basename(replace(datasetpath, r"/$" => "")),
    force::Bool = false
)
    @assert force || !isdir(datasetpath) "Directory $(datasetpath) already present: set " *
        "`force` to `true` to overwrite existing dataset"

    @assert length(instance_ids) == nrow(df) "Mismatching `length(instance_ids)` " *
        "($(length(instance_ids))) and `nrow(df)` ($(nrow(df)))"

    mkpath(datasetpath)

    # NOTE: maybe this can be done in `savedataset` accepting a labeled MFD
    df_labels = nothing
    if length(labels_indices) > 0
        df_labels = DataFrame(
            :id => [string(_ds_inst_prefix, i) for i in instance_ids],
            [l => df[:,l] for l in Symbol.(names(df)[labels_indices])]...
        )
    end

    for (i_inst, (id, inst)) in enumerate(zip(instance_ids, eachrow(df)))
        inst_metadata_path = joinpath(datasetpath, string(_ds_inst_prefix, id), _ds_metadata)

        curr_inst_path = mkpath(dirname(inst_metadata_path))
        inst_metadata_file = open(inst_metadata_path, "w+")

        for (i_frame, curr_frame_idices) in enumerate(frame_descriptor)
            curr_frame_inst = inst[curr_frame_idices]

            # TODO: maybe assert all instances have same size or fill with missing
            println(inst_metadata_file,
                "dim_frame_", i_frame, "=", size(first(curr_frame_inst))
            )

            CSV.write(
                joinpath(curr_inst_path, string(_ds_frame_prefix, i_frame, ".csv")),
                DataFrame(
                    [a => linearize_data(curr_frame_inst[a])
                        for a in Symbol.(names(curr_frame_inst))]
                )
            )
        end

        # NOTE: this is not part of the `Data Input Format` specification pdf and it is a
        # duplicated info from Labels.csv
        if !isnothing(df_labels)
            example_labels = select(df_labels, Not("id"))[i_inst,:]
            for col in 1:length(names(example_labels))
                println(inst_metadata_file,
                    names(example_labels)[col], "=",
                    string(select(df_labels, Not("id"))[i_inst, col])
                )
            end
        end

        close(inst_metadata_file)
    end


    ds_metadata_file = open(joinpath(datasetpath, _ds_metadata), "w+")

    println(ds_metadata_file, "name=", name)

    if !isnothing(df_labels)
        CSV.write(joinpath(datasetpath, _ds_labels), df_labels)
        println(ds_metadata_file, "supervised=true")
        println(ds_metadata_file, "num_classes=", (ncol(df_labels)-1))
    else
        println(ds_metadata_file, "supervised=false")
    end

    println(ds_metadata_file, "num_frames=", length(frame_descriptor))

    for (i_frame, curr_frame_idices) in enumerate(frame_descriptor)
        println(ds_metadata_file, "frame", i_frame, "=", dimension(df[:,curr_frame_idices]))
    end

    close(ds_metadata_file)
end
