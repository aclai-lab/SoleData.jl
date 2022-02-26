
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

    df = CSV.read(joinpath(datasetdir, _ds_labels), DataFrame; types=String)
    
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
    onlywithlabels::AbstractVector{<:AbstractVector{<:Pair{<:AbstractString,<:AbstractVector{<:Any}}}} =
        AbstractVector{Pair{AbstractString,AbstractVector{Any}}}[]
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

                    nt = NamedTuple([Symbol(fs[1]) => fs[2] for fs in filters])
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

    println("Instances count: $(length(examples_ids))")
    println("Total size: $(totalsize) bytes")

    return examples_ids, totalsize
end

function _load_instance(datasetpath::AbstractString, inst_id::Integer)
    inst_metadata = _read_example_metadata(datasetpath, inst_id)
        
    dataset_metadata = _read_dataset_metadata(datasetpath)
    
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
        
        # TODO: use dim_frame_[[:digit:]] to properly load all frames
        dim_curr_frame = dataset_metadata["frame" * f]
        if dim_curr_frame == 0
            frame = (CSV.File(frame_path) |> Tables.rowtable)[1] |> pairs |> Dict
        else
            frame = CSV.File(frame_path) |> Tables.columntable |> pairs |> Dict
        end
        result[i] = frame
    end
    return result
end

"""
TODO: docs
"""
function loaddataset(
    datasetpath::AbstractString;
    onlywithlabels::AbstractVector{<:AbstractVector{<:Pair{<:AbstractString,<:AbstractVector{<:Any}}}} =
        AbstractVector{Pair{AbstractString,AbstractVector{Any}}}[]
    )
    selected_ids, datasetsize = datasetinfo(datasetpath, onlywithlabels = onlywithlabels)

    @assert length(selected_ids) > 0 "No instance found"

    instance_frames = _load_instance(datasetpath, selected_ids[1])
    frames_cols = [Symbol.(attr_name) for attr_name in keys.(instance_frames)]

    df = DataFrame(
        :id => [selected_ids[1]],
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
    
    if isfile(joinpath(datasetpath, _ds_labels))
        df_with_labels = innerjoin(df, rename!(_read_labels(datasetpath), :id => :id), on = :id)
        labels_index =  collect((ncol(df)+1) : ncol(df_with_labels))
        return LabeledMultiFrameDataset(labels_index, MultiFrameDataset(frame_descriptor, df_with_labels))
    else
        return MultiFrameDataset(frame_descriptor, df)
    end
end

"""
TODO: docs
"""
function savedataset(
    datasetpath::AbstractString, 
    lmfd::AbstractLabeledMultiFrameDataset;
    name::AbstractString = "saved_dataset",
    force::Bool = false
    )

    if !force
        @assert all(!, dir == splitdir(datasetpath)[2] for dir in filter(x -> isdir(joinpath(dirname(pwd() * "/" * datasetpath), x)), readdir(dirname(pwd() * "/" * datasetpath)))) "Directory $(datasetpath) already present: set `force` to `true` to " *
        "overwrite existing dataset"
    end

    mfd = lmfd.mfd
    labels_index = lmfd.labels_descriptor

    savedataset(datasetpath, mfd, labels_index = labels_index, name = name, force = force)
end

function savedataset(
    datasetpath::AbstractString, 
    mfd::AbstractMultiFrameDataset;
    labels_index::Union{AbstractVector{<:Integer},Nothing} = nothing,
    name::AbstractString = "saved_dataset",
    force::Bool = false
    )

    if !force
        @assert all(!, dir == splitdir(datasetpath)[2] for dir in filter(x -> isdir(joinpath(dirname(pwd() * "/" * datasetpath), x)), readdir(dirname(pwd() * "/" * datasetpath)))) "Directory $(datasetpath) already present: set `force` to `true` to " *
        "overwrite existing dataset"
    end    
    
    df = mfd.data
    frames = Vector{String}[]
    for i_frame in 1:nframes(mfd)
        push!(frames, names(mfd[i_frame]))
    end

    dim_frames = dimension(mfd)

    savedataset(datasetpath, df, frames, dim_frames, labels_index = labels_index, name = name, force = force)
end

function savedataset(
    datasetpath::AbstractString, 
    df::AbstractDataFrame, 
    frames::AbstractVector{<:AbstractVector{<:AbstractString}},
    dim_frames = Tuple{<:Integer,<:Integer};
    labels_index::Union{AbstractVector{<:Integer},Nothing} = nothing,
    name::AbstractString = "saved_dataset",
    force::Bool = false,
    )

    if !force
        @assert all(!, dir == splitdir(datasetpath)[2] for dir in filter(x -> isdir(joinpath(dirname(pwd() * "/" * datasetpath), x)), readdir(dirname(pwd() * "/" * datasetpath)))) "Directory $(datasetpath) already present: set `force` to `true` to " *
        "overwrite existing dataset"
    end 
    
    mkpath(datasetpath)

    write = true

    if labels_index !== nothing
        x = String[]
        for i in 1:nrow(df)
            push!(x, _ds_inst_prefix * string(i))
        end
    
        df_labels = insertcols!(df[:, labels_index], 1, :id => x)
    end

    for i_row in 1:nrow(df)
        write = true
        mkpath(datasetpath * "/" * _ds_inst_prefix * string(i_row))
        file = open(datasetpath * "/" * _ds_inst_prefix * string(i_row) * "/" * _ds_metadata, "w+")
        for i_frame in 1:length(frames)
            temp_df = DataFrame()
            push!(temp_df, df[i_row,frames[i_frame]])

            println(file, "dim_frame_" * string(i_frame) * "=(" * string(length(temp_df[1,1])) * ",0)")

            if write
                if labels_index !== nothing
                    example_labels = select(df_labels, Not("id"))[i_row,:]
                    for col in 1:length(names(example_labels)) 
                        println(file, names(example_labels)[col] * "=" * string(select(df_labels, Not("id"))[i_row,col]))
                    end
                end
                write = false
            end

            temp_df_2 = DataFrame()
            for i_col in 1:length(names(temp_df))  
                insertcols!(temp_df_2, i_col, Symbol.(names(temp_df)[i_col]) => df[i_row,frames[i_frame][i_col]])
            end
            
            CSV.write(datasetpath * "/" * _ds_inst_prefix * string(i_row) * "/" * _ds_frame_prefix * string(i_frame) * ".csv", temp_df_2)
        end
        close(file)
    end

    file = open(datasetpath * "/" * _ds_metadata, "w+")
    
    println(file, "name=",name)
    
    if labels_index !== nothing
        CSV.write(datasetpath * "/" * _ds_labels, df_labels)
        println(file, "supervised=true")
        println(file, "num_classes=" * string(ncol(df_labels)-1))
    else
        println(file, "supervised=false")
    end

    println(file, "num_frames=", length(frames))

    for i_frame in 1:length(frames)
        println(file, "frame" * string(i_frame) * "=" * string(dim_frames[i_frame]))
    end

    close(file)    
end
