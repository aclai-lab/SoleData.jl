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

@test dimensionality(lmd) == (0, 1)
@test dimensionality(lmd, 1) == 0
@test dimensionality(lmd, 2) == 1

# labels
@test nlabelingvariables(lmd) == 1
@test labels(lmd) == [Symbol(names(df_langs)[2])]
@test labels(lmd, 1) == Dict(Symbol(names(df_langs)[2]) => df_langs[1, 2])
@test labels(lmd, 2) == Dict(Symbol(names(df_langs)[2]) => df_langs[2, 2])

@test labeldomain(lmd, 1) == Set(df_langs[:,2])

# remove label
unsetaslabeling!(lmd, 2)
@test nlabelingvariables(lmd) == 0

setaslabeling!(lmd, 2)
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
