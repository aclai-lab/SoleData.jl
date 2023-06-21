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

    @testset "MultiModalDataset" begin
        include("MultiModalDataset.jl")
    end

    @testset "LabeledMultiModalDataset" begin
        include("LabeledMultiModalDataset.jl")
    end

    @testset "Filesystem operations" begin
        include("filesystem.jl")
    end

    @testset "Dimensional data" begin
        include("dimensional-data.jl")
    end

end
