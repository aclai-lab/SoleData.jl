function loaddataset(Dataset)

    # Get n_column from Metadata.txt

    df = DataFrame([Vector{Float64}[] for i in 1:1624], :auto)

    # For each directory (in alphabetic order) in Dataset
    for i in sort(filter(i -> isdir(joinpath(Dataset, i)), readdir(Dataset, sort=true)), by = x -> parse(Int, chop(x, head=8, tail=0)))
        # Go in every Example and search for Frame.csv
        current_dir = joinpath(Dataset, i)
        for file in readdir(current_dir)
            if startswith(file, "Frame")
                # Frame.csv to Dictionary
                d = CSV.File(joinpath(current_dir, file)) |> Tables.columntable |> pairs |> Dict
                # Push into DataFrame
                push!(df, [d[Symbol(i)] for i in 0:(length(keys(d))-1)])
            end
        end
    end

    return MultiFrameDataset([collect(1:nattributes(df))], df)

end
