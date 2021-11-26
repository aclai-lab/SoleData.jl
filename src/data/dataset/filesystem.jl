
# -------------------------------------------------------------
# AbstractMultiFrameDataset - filesystem operations

const _ds_inst_prefix = "Example_"
const _ds_frame_prefix = "Frame_"
const _ds_metadata = "Metadata.txt"
const _ds_labels = "Labels.csv"

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
            div = contains(v, ",") ? "," : " "
            dict[k] = Tuple(parse.(Int64, split(replace(replace(v, "(" => ""), ")" => ""), div)))
        else
            dict[k] = v
        end
    end

    close(file)

    return dict
end

function _read_labels(datasetdir::AbstractString)
    @assert isfile(joinpath(datasetdir, _ds_labels)) "Missing $(_ds_labels) in dataset " *
        "$(datasetdir)"

    df = CSV.read(joinpath(datasetdir, _ds_labels), DataFrame)

    df[!,:id] = parse.(Int64, replace.(df[!,:id], _ds_inst_prefix => ""))

    return df
end

"""
    datasetinfo(datasetpath)

Show dataset size on disk and return a Touple with first element a Vector of selected IDs
and second element the total size in bytes.
"""
function datasetinfo(
    datasetpath::AbstractString;
    onlywithlables::AbstractVector{<:AbstractVector{<:Pair{<:AbstractString,<:AbstractVector{<:Any}}}} = AbstractVector{Pair{AbstractString,AbstractVector{Any}}}[]
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

    examples_ids = parse.(Int64, replace.(
        filter(isexdir, readdir(datasetpath)),
        _ds_inst_prefix => ""
    ))

    labels = nothing
    if ds_metadata["supervised"] ||
            (haskey(ds_metadata, "num_classes") && ds_metadata["num_classes"] > 0)
        labels = _read_labels(datasetpath)
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
            @warn "Following exmaples IDs are present on filsystem but a referenced by " *
                "$(_ds_labels): $(missing_in_dirs)"
        end
        if there_are_missing
            examples_ids = sort!(collect(intersect(examples_ids, labels[:,:id])))
            @warn "Will be used only instances with IDs: $(examples_ids)"
        end
    end

    totalsize = 0

    # TODO: add exmple filtering by labels
    filtered_ids = Integer[]
    if length(onlywithlables) != 0
        nt = Tuple{}()
        for i in 1:length(onlywithlables)
            for filters in [collect(Base.product([collect(Base.product((key,), value)) for (key, value) in onlywithlables[i]]...))...]
                nt = NamedTuple([Symbol(fs[1]) => fs[2] for fs in filters])
                push!(filtered_ids,(groupby(labels, collect(keys(nt)))[nt])[:,1]...)
            end 
        end
        examples_ids = filtered_ids
    end

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

    println("Total size: $(totalsize) bytes")

    return examples_ids, totalsize
end

function _load_instance(datasetpath::AbstractString, inst_id::Integer)
    inst_metadata = _read_example_metadata(datasetpath, inst_id)

    instancedir = joinpath(datasetpath, "$(_ds_inst_prefix)$(inst_id)")

    frame_reg = Regex("$(_ds_frame_prefix)([[:digit:]]+).csv")
    function isframefile(path::AbstractString)
        return isfile(joinpath(instancedir, path)) && !isnothing(match(frame_reg, path))
    end

    frames = filter(isframefile, readdir(instancedir))
    frames_num = sort!([match(frame_reg, f).captures[1] for f in frames])

    result = Vector{Dict}(undef, length(frames_num))
    #Threads.@threads
    for (i, f) in collect(enumerate(frames_num))
        frame_path = joinpath(instancedir, "$(_ds_frame_prefix)$(f).csv")
        frame = CSV.File(frame_path) |> Tables.columntable |> pairs |> Dict
        # TODO: use dim_frame_[[:digit:]] to properly load frames
        result[i] = frame
    end

    return result
end

"""
TODO: docs
"""
function loaddataset(
    datasetpath::AbstractString;
    onlywithlables::AbstractVector{<:AbstractVector{<:Pair{<:AbstractString,<:AbstractVector{<:Any}}}} = AbstractVector{Pair{AbstractString,AbstractVector{Any}}}[]
)
    selected_ids, datasetsize = datasetinfo(datasetpath, onlywithlables = onlywithlables)

    @assert length(selected_ids) > 0 "No instance found"

    instance_frames = _load_instance(datasetpath, selected_ids[1])
    frames_cols = [Symbol.(attr_name) for attr_name in keys.(instance_frames)]

    df = DataFrame(
        :ID => [selected_ids[1]],
        [Symbol(k) => [v] for frame in instance_frames for (k, v) in frame]...
    )

    for id in selected_ids[2:end]
        curr_row = Any[id]
        for (i, frame) in enumerate(_load_instance(datasetpath, id))
            for attr_name in frames_cols[i]
                push!(curr_row, frame[attr_name])
            end
        end
        push!(df, curr_row)
    end

    frame_descriptor = Vector{Integer}[]
    df_names = Symbol.(names(df))
    for (i, frame) in enumerate(frames_cols)
        push!(frame_descriptor, [findfirst(x -> x == k, df_names) for k in frame])
    end

    return MultiFrameDataset(frame_descriptor, df)
end

"""
TODO: docs
"""
function savedataset(
    datasetpath::AbstractString, mfd::AbstractMultiFrameDataset;
    force::Bool = false
)
    if !force
        @assert "Directory $(datasetpath) already present: set `force` to `true` to " *
            "overwrite existing dataset"
    end

    throw(ErrorException("`datasetinfo` still not implemented"))

    # TODO: implement savedataset
    # useful function may be:
    # - mkpath
    # - write
end
