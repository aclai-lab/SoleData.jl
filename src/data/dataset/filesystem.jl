
# -------------------------------------------------------------
# AbstractMultiFrameDataset - filesystem operations

"""
    datasetinfo(datasetpath)

Show dataset size on disk and return the size in bytes.
"""
function datasetinfo(datasetpath::AbstractString)
    # TODO: add kwargs to get the size of a subset of the dataset
    @assert isdir(datasetpath) "Dataset at path $(datasetpath) does not exist"

    throw(ErrorException("`datasetinfo` still not implemented"))

    # TODO: implement datasetinfo
    # useful function may be:
    # - filesize
    # - walkdir
    # - isdir
    # - isfile
end

"""
TODO: docs
"""
function loaddataset(datasetpath::AbstractString)
    # TODO: add kwargs to load a subset of the dataset
    @assert isdir(datasetpath) "Dataset at path $(datasetpath) does not exist"

    # Get n_column from Metadata.txt
    # TODO: generalize this 'magic number'
    df = DataFrame([Vector{Float64}[] for i in 1:3], :auto)

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
