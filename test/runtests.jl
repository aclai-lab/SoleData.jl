using SoleData
using Test
using CSV

const testing_savedataset = mktempdir(prefix = "saved_dataset")

const _ds_inst_prefix = SoleData._ds_inst_prefix
const _ds_modality_prefix = SoleData._ds_modality_prefix
const _ds_metadata = SoleData._ds_metadata
const _ds_labels = SoleData._ds_labels

const ts_sin = [sin(i) for i in 1:50000]
const ts_cos = [cos(i) for i in 1:50000]

const df = DataFrame(
    :sex => ["F", "F", "M"],
    :h => [deepcopy(ts_sin), deepcopy(ts_cos), deepcopy(ts_sin)]
)

const df_langs = DataFrame(
    :age => [30, 9],
    :name => ["Python", "Julia"],
    :stat => [deepcopy(ts_sin), deepcopy(ts_cos)]
)

const df_data = DataFrame(
    :id => [1, 2],
    :age => [30, 9],
    :name => ["Python", "Julia"],
    :stat => [deepcopy(ts_sin), deepcopy(ts_cos)]
)

const ages = DataFrame(:age => [35, 38, 37])

@testset "SoleData.jl" begin

    @testset "dataset" begin

        a = MultiModalDataset([deepcopy(df_langs), DataFrame(:id => [1, 2])])
        b = MultiModalDataset([[2,3,4], [1]], df_data)

        c = MultiModalDataset([[:age,:name,:stat], [:id]], df_data)
        @test b == c
        d = MultiModalDataset([[:age,:name,:stat], :id], df_data)
        @test c == d

        @test_throws AssertionError MultiModalDataset([[:age,:name,4], :id], df_data)

        @test SoleData.data(a) != SoleData.data(b)
        @test collect(eachmodality(a)) == collect(eachmodality(b))

        md = MultiModalDataset([[1],[2]], deepcopy(df))
        original_md = deepcopy(md)

        @test isa(md, MultiModalDataset)

        @test isa(first(eachmodality(md)), SubDataFrame)
        @test length(eachmodality(md)) == nmodalities(md)

        @test modality(md, [1,2]) == [modality(md, 1), modality(md, 2)]

        @test isa(modality(md, 1), SubDataFrame)
        @test isa(modality(md, 2), SubDataFrame)

        @test nmodalities(md) == 2

        @test nvariables(md) == 2
        @test nvariables(md, 1) == 1
        @test nvariables(md, 2) == 1

        @test ninstances(md) == length(eachinstance(md)) == 3

        @test_throws AssertionError slicedataset(md, [])
        @test_nowarn slicedataset(md, :)
        @test_nowarn slicedataset(md, 1)
        @test_nowarn slicedataset(md, [1])

        @test ninstances(slicedataset(md, :)) == 3
        @test ninstances(slicedataset(md, 1)) == 1
        @test ninstances(slicedataset(md, [1])) == 1

        @test_nowarn concatdatasets(md, md, md)
        @test_nowarn vcat(md, md, md)

        @test dimension(md) == (0, 1)
        @test dimension(md, 1) == 0
        @test dimension(md, 2) == 1

        # test auto selection of modalities
        auto_md = MultiModalDataset(deepcopy(df))
        @test nmodalities(auto_md) == 0
        @test length(sparevariables(auto_md)) == nvariables(auto_md)

        auto_md_all = MultiModalDataset(deepcopy(df); group = :all)
        @test auto_md_all == md
        @test !(:mixed in dimension(auto_md_all))

        lang_md1 = MultiModalDataset(df_langs; group = :all)
        @test nmodalities(lang_md1) == 2
        @test !(:mixed in dimension(lang_md1))

        lang_md2 = MultiModalDataset(df_langs; group = [1])
        @test nmodalities(lang_md2) == 3
        dims_md2 = dimension(lang_md2)
        @test length(filter(x -> isequal(x, 0), dims_md2)) == 2
        @test length(filter(x -> isequal(x, 1), dims_md2)) == 1
        @test !(:mixed in dimension(lang_md2))

        # test equality between mixed-columns datasets
        md1_sim = MultiModalDataset([[1,2]], DataFrame(:b => [3,4], :a => [1,2]))
        md2_sim = MultiModalDataset([[2,1]], DataFrame(:a => [1,2], :b => [3,4]))
        @test md1_sim ≈ md2_sim
        @test md1_sim == md2_sim

        # addmodality!
        @test addmodality!(md, [1, 2]) == md # test return
        @test nmodalities(md) == 3
        @test nvariables(md) == 2
        @test nvariables(md, 3) == 2

        @test dimension(md) == (0, 1, :mixed)
        @test dimension(md, 3) == :mixed
        @test dimension(md, 3; force = :min) == 0
        @test dimension(md, 3; force = :max) == 1

        # removemodality!
        @test removemodality!(md, 3) == md # test return
        @test nmodalities(md) == 2
        @test nvariables(md) == 2
        @test_throws Exception nvariables(md, 3) == 2

        # sparevariables
        @test length(sparevariables(md)) == 0
        removemodality!(md, 2)
        @test length(sparevariables(md)) == 1
        addmodality!(md, [2])
        @test length(sparevariables(md)) == 0

        # pushinstances!
        new_inst = DataFrame(:sex => ["F"], :h => [deepcopy(ts_cos)])[1,:]
        @test pushinstances!(md, new_inst) == md # test return
        @test ninstances(md) == 4
        pushinstances!(md, ["M", deepcopy(ts_cos)])
        @test ninstances(md) == 5

        # deleteinstances!
        @test deleteinstances!(md, ninstances(md)) == md # test return
        @test ninstances(md) == 4
        deleteinstances!(md, ninstances(md))
        @test ninstances(md) == 3

        # keeponlyinstances!
        pushinstances!(md, ["F", deepcopy(ts_cos)])
        pushinstances!(md, ["F", deepcopy(ts_cos)])
        pushinstances!(md, ["F", deepcopy(ts_cos)])
        @test keeponlyinstances!(md, [1, 2, 3]) == md # test return
        @test ninstances(md) == 3
        for i in 1:ninstances(md)
            @test instance(md, i) == instance(original_md, i)
        end

        # modality manipulation
        @test addvariable_tomodality!(md, 1, 2) === md # test return
        @test nvariables(md, 1) == 2
        @test dimension(md, 1) == :mixed

        @test removevariable_frommodality!(md, 1, 2) === md # test return
        @test nvariables(md, 1) == 1
        @test dimension(md, 1) == 0

        # variables manipulation
        @test insertmodality!(md, deepcopy(ages)) == md # test return
        @test nmodalities(md) == 3
        @test nvariables(md, 3) == 1

        @test dropmodalities!(md, 3) == md # test return
        @test nmodalities(md) == 2

        insertmodality!(md, deepcopy(ages), [1])
        @test nmodalities(md) == 3
        @test nvariables(md, 3) == 2
        @test dimension(md, 3) == 0

        @test_nowarn md[:,:]
        @test_nowarn md[1,:]
        @test_nowarn md[:,1]
        @test_nowarn md[:,1:2]
        @test_nowarn md[[1,2],:]
        @test_nowarn md[1,1]
        @test_nowarn md[[1,2],[1,2]]
        @test_nowarn md[1,[1,2]]
        @test_nowarn md[[1,2],1]

        # drop "inner" modality and multiple modalities in one operation
        insertmodality!(md, DataFrame(:t2 => [deepcopy(ts_sin), deepcopy(ts_cos), deepcopy(ts_sin)]))
        @test nmodalities(md) == 4
        @test nvariables(md) == 4
        @test nvariables(md, nmodalities(md)) == 1

        # dropping the modality 3 should result in dropping the first too
        # because the variable at index 1 is shared between them and will be
        # dropped but modality 1 has just the variable at index 1 in it, this
        # should result in dropping that modality too
        dropmodalities!(md, 3)
        @test nmodalities(md) == 2
        @test nvariables(md) == 2
        @test nvariables(md, nmodalities(md)) == 1

        dropmodalities!(md, 2)
        @test nmodalities(md) == 1
        @test nvariables(md) == 1

        # RESET
        md = deepcopy(original_md)

        # dropsparevariables!
        removemodality!(md, 2)
        @test dropsparevariables!(md) == DataFrame(names(df)[2] => df[:,2])

        # keeponlyvariables!
        md_var_manipulation = MultiModalDataset([[1], [2], [3, 4]],
            DataFrame(
                :age => [30, 9],
                :name => ["Python", "Julia"],
                :stat1 => [deepcopy(ts_sin), deepcopy(ts_cos)],
                :stat2 => [deepcopy(ts_cos), deepcopy(ts_sin)]
            )
        )
        md_var_manipulation_original = deepcopy(md_var_manipulation)

        @test keeponlyvariables!(md_var_manipulation, [1, 3]) == md_var_manipulation
        @test md_var_manipulation == MultiModalDataset([[1], [2]],
            DataFrame(
                :age => [30, 9],
                :stat1 => [deepcopy(ts_sin), deepcopy(ts_cos)]
            )
        )

        # addressing variables by name
        md1 = MultiModalDataset([[1],[2]],
            DataFrame(
                :age => [30, 9],
                :name => ["Python", "Julia"],
            )
        )
        md_var_names_original = deepcopy(md1)
        md2 = deepcopy(md1)

        @test hasvariables(md1, :age) == true
        @test hasvariables(md1, :name) == true
        @test hasvariables(md1, :missing_variable) == false
        @test hasvariables(md1, [:age, :name]) == true
        @test hasvariables(md1, [:age, :missing_variable]) == false

        @test hasvariables(md1, 1, :age) == true
        @test hasvariables(md1, 1, :name) == false
        @test hasvariables(md1, 1, [:age, :name]) == false

        @test hasvariables(md1, 2, :name) == true
        @test hasvariables(md1, 2, [:name]) == true

        @test variableindex(md1, :age) == 1
        @test variableindex(md1, :missing_variable) == 0
        @test variableindex(md1, 1, :age) == 1
        @test variableindex(md1, 2, :age) == 0
        @test variableindex(md1, 2, :name) == 1

        # addressing variables by name - insertmodality!
        md1 = deepcopy(md_var_names_original)
        md2 = deepcopy(md_var_names_original)
        @test addmodality!(md1, [1]) == addmodality!(md2, [:age])

        # addressing variables by name - addvariable_tomodality!
        md1 = deepcopy(md_var_names_original)
        md2 = deepcopy(md_var_names_original)
        @test addvariable_tomodality!(md1, 2, 1) == addvariable_tomodality!(md2, 2, :age)

        # addressing variables by name - removevariable_frommodality!
        @test removevariable_frommodality!(md1, 2, 1) ==
            removevariable_frommodality!(md2, 2, :age)

        # addressing variables by name - dropvariables!
        md1 = deepcopy(md_var_names_original)
        md2 = deepcopy(md_var_names_original)
        @test dropvariables!(md1, 1) ==
            dropvariables!(md2, :age)
        @test md1 == md2

        # addressing variables by name - insertmodality!
        md1 = deepcopy(md_var_names_original)
        md2 = deepcopy(md_var_names_original)
        @test insertmodality!(
            md1,
            DataFrame(:stat1 => [deepcopy(ts_sin), deepcopy(ts_cos)]),
            [1]
        ) == insertmodality!(
            md2,
            DataFrame(:stat1 => [deepcopy(ts_sin), deepcopy(ts_cos)]),
            [:age]
        )

        # addressing variables by name - dropvariables!
        @test dropvariables!(md1, [1, 2]) ==
            dropvariables!(md2, [:age, :name])
        @test md1 == md2

        @test nmodalities(md1) == nmodalities(md2) == 1
        @test nvariables(md1) == nvariables(md2) == 1
        @test nvariables(md1, 1) == nvariables(md2, 1) == 1

        # addressing variables by name - keeponlyvariables!
        md1 = deepcopy(md_var_names_original)
        md2 = deepcopy(md_var_names_original)
        @test keeponlyvariables!(md1, [1]) == keeponlyvariables!(md2, [:age])
        @test md1 == md2
    end

    @testset "labeled-dataset" begin
        lmd = LabeledMultiModalDataset(
            MultiModalDataset([[1], [3]], deepcopy(df_langs)),
            [2],
        )

        @test isa(lmd, LabeledMultiModalDataset)

        @test isa(modality(lmd, 1), SubDataFrame)
        @test isa(modality(lmd, 2), SubDataFrame)

        @test modality(lmd, [1,2]) == [modality(lmd, 1), modality(lmd, 2)]

        @test isa(first(eachmodality(lmd)), SubDataFrame)
        @test length(eachmodality(lmd)) == nmodalities(lmd)

        @test nmodalities(lmd) == 2

        @test nvariables(lmd) == 3
        @test nvariables(lmd, 1) == 1
        @test nvariables(lmd, 2) == 1

        @test ninstances(lmd) == length(eachinstance(lmd)) == 2

        @test_throws AssertionError slicedataset(lmd, [])
        @test_nowarn slicedataset(lmd, :)
        @test_nowarn slicedataset(lmd, 1)
        @test_nowarn slicedataset(lmd, [1])

        @test ninstances(slicedataset(lmd, :)) == 2
        @test ninstances(slicedataset(lmd, 1)) == 1
        @test ninstances(slicedataset(lmd, [1])) == 1

        @test_nowarn concatdatasets(lmd, lmd, lmd)
        @test_nowarn vcat(lmd, lmd, lmd)

        @test dimension(lmd) == (0, 1)
        @test dimension(lmd, 1) == 0
        @test dimension(lmd, 2) == 1

        # labels
        @test nlabelingvariables(lmd) == 1
        @test labels(lmd) == [Symbol(names(df_langs)[2])]
        @test labels(lmd, 1) == Dict(Symbol(names(df_langs)[2]) => df_langs[1, 2])
        @test labels(lmd, 2) == Dict(Symbol(names(df_langs)[2]) => df_langs[2, 2])

        @test labeldomain(lmd, 1) == Set(df_langs[:,2])

        # remove label
        removefromlabels!(lmd, 2)
        @test nlabelingvariables(lmd) == 0

        setaslabelinging!(lmd, 2)
        @test nlabelingvariables(lmd) == 1

        # label
        @test label(lmd, 1, 1) == "Python"
        @test label(lmd, 2, 1) == "Julia"

        # joinlabels!
        lmd = LabeledMultiModalDataset(
            MultiModalDataset([[1], [4]], deepcopy(df_data)),
            [2, 3],
        )

        joinlabels!(lmd)

        @test labels(lmd) == [Symbol(join([:age, :name], '_'))]
        @test label(lmd, 1, 1) == string(30, '_', "Python")
        @test label(lmd, 2, 1) == string(9, '_', "Julia")

        # dropvariables!
        lmd = LabeledMultiModalDataset(
            MultiModalDataset([[2], [4]], deepcopy(df_data)),
            [3],
        )
        @test nmodalities(lmd) == 2
        @test nvariables(lmd) == 4

        dropvariables!(lmd, 2)

        @test SoleData.labeling_variables(lmd) == [2]
        @test nvariables(lmd) == 3
        @test nmodalities(lmd) == 1
        @test nlabelingvariables(lmd) == 1
        @test labels(lmd) == [Symbol(names(df_data)[3])]
    end

    @testset "dataset filesystem operations" begin
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
            dimension(lmd[i_modality]) for (i_modality, modality) in enumerate(modalities)])
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
            # for each modality check the proper dimension was saved
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
    end
end
