
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

function _read_example_metadata(datasetdir::AbstractString, example_id::Integer)
    @assert isfile(joinpath(
        datasetdir,
        "$(_ds_inst_prefix)$(string(example_id))",
        _ds_metadata
    )) "Missing $(_ds_metadata) in dataset `$(_ds_inst_prefix)$(string(example_id))` in " *
        "`$(datasetdir)`"

    file = open(joinpath(datasetdir, "$(_ds_inst_prefix)$(string(example_id))", _ds_metadata))

    dict = Dict{String,Any}()
    for (k, v) in split.(filter(x -> length(x) > 0, strip.(readlines(file))), '=')
        k = strip(k)
        v = strip(v)
        if startswith(k, "dim") == "name"
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

Show dataset size on disk and return the size in bytes.
"""
function datasetinfo(
    datasetpath::AbstractString;
    onlywithlables::AbstractVector{Pair{String,Any}} = Pair{String,Any}[]
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

"""
TODO: docs
"""
function loaddataset(datasetpath::AbstractString)
    # TODO: add kwargs to load a subset of the dataset
    @assert isdir(datasetpath) "Dataset at path $(datasetpath) does not exist"

    # Get n_column from Metadata.txt
    # TODO: generalize this 'magic number'
    df = DataFrame([Vector{Float64}[] for i in 1:1624], :auto)

    # For each directory (in alphabetic order) in datasetpath
    for i in sort(filter(i -> isdir(joinpath(datasetpath, i)), readdir(datasetpath, sort=true)), by = x -> parse(Int, chop(x, head=8, tail=0)))
        # Go in every Example and search for Frame.csv
        current_dir = joinpath(datasetpath, i)
        for file in readdir(current_dir)
            if startswith(file, "Frame")
                # TODO: this can be done in a more efficent way
                # Frame.csv to Dictionary
                d = CSV.File(joinpath(current_dir, file)) |> Tables.columntable |> pairs |> Dict
                # Push into DataFrame
                # TODO: do not assume attribute names to be of type `:Integer`
                push!(df, [d[Symbol(i)] for i in 0:(length(keys(d))-1)])
            end
        end
    end

    return MultiFrameDataset([collect(1:nattributes(df))], df)

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
