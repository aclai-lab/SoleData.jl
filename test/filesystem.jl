lmd = LabeledMultiModalDataset(
    MultiModalDataset([[2], [4]], deepcopy(df_data)),
    [3],
)

path = relpath(joinpath(testing_savedataset))
savedataset(path, lmd, force = true)

# Labels.csv
@test isfile(joinpath(path, _ds_labels))
@test length(split(readline(joinpath(path, _ds_labels)), ","))-1 == 1
df_labels = CSV.read(joinpath(path, _ds_labels), DataFrame; types = String)
df_labels[!,:id] = parse.(Int64, replace.(df_labels[!,:id], _ds_inst_prefix => ""))
@test df_labels == lmd.md.data[:,sparevariables(lmd.md)]

# Dataset Metadata.txt
@test isfile(joinpath(path, _ds_metadata))
@test "supervised=true" in readlines(joinpath(path, _ds_metadata))
@test length(
        filter(
            x -> startswith(x, _ds_modality_prefix),
            readdir(joinpath(path, _ds_inst_prefix * "1"))
        )) == 2
@test parse.(Int64,
        split(filter(
            (row) -> startswith(row, "num_modalities"),
            readlines(joinpath(path, _ds_metadata))
        )[1], "=")[2]
    ) == 2
@test length(
        filter(
            row -> startswith(row, "modality"),
            readlines(joinpath(path, _ds_metadata))
        )) == 2
modalities = filter(
        row -> startswith(row, "modality"),
        readlines(joinpath(path, _ds_metadata))
    )
@test all([parse.(Int64, split(string(modality), "=")[2]) ==
    dimensionality(lmd[i_modality]) for (i_modality, modality) in enumerate(modalities)])
@test parse(Int64, split(
    filter(
            row -> startswith(row, "num_classes"),
            readlines(joinpath(path, _ds_metadata))
        )[1], "=")[2]) == 1
@test length(
    filter(
        x -> startswith(x, _ds_inst_prefix),
        readdir(joinpath(path))
    )) == 2

# instances Metadata.txt
@test all([isfile(joinpath(path, _ds_inst_prefix * string(i), _ds_metadata))
    for i in 1:nrow(lmd[1])])
for i_inst in 1:ninstances(lmd)
    dim_modality_rows = filter(
            row -> startswith(row, "dim_modality"),
            readlines(joinpath(path, string(_ds_inst_prefix, i_inst), _ds_metadata))
        )
    # for each modality check the proper dimensionality was saved
    for (i_modality, dim_modality) in enumerate(dim_modality_rows)
        @test strip(split(dim_modality, "=")[2]) == string(
                size(first(first(lmd[i_modality])))
            )
    end
end
@test length([filter(
        row -> occursin(string(labels), row),
        readlines(joinpath(path, string(_ds_inst_prefix, modality), _ds_metadata))
    ) for labels in labels(lmd) for modality in 1:nmodalities(lmd)]) == 2
@test [filter(
        row -> occursin(string(labels), row),
        readlines(joinpath(path, string(_ds_inst_prefix, modality), _ds_metadata))
    ) for labels in labels(lmd) for modality in 1:nmodalities(lmd)] == [
            ["name=Python"],
            ["name=Julia"]
        ]

# Example
@test all([isdir(joinpath(path, string(_ds_inst_prefix, instance)))
    for instance in 1:nrow(lmd[1])])
@test all([isfile(joinpath(
        path,
        string(_ds_inst_prefix, instance),
        string(_ds_modality_prefix, i_modality, ".csv")
    )) for i_modality in 1:length(lmd) for instance in 1:nrow(lmd[1])])

saved_lmd = loaddataset(path)
@test saved_lmd == lmd

# load MD (a dataset without Labels.csv isa an MD)
rm(joinpath(path, _ds_labels))
ds_metadata_lines = readlines(joinpath(path, _ds_metadata))
rm(joinpath(path, _ds_metadata))

file = open(joinpath(path, _ds_metadata), "w+")
for line in ds_metadata_lines
    if occursin("supervised", line)
        println(file, "supervised=false")
    elseif occursin("num_classes", line)
    else
        println(file, line)
    end
end
close(file)

md = loaddataset(path)
@test md isa MultiModalDataset

# saving an MD should not generate a Labels.csv
savedataset(path, md, force = true)
@test !isfile(joinpath(path, _ds_labels))
