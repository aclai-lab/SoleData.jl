using Test
using SoleData

@test_nowarn Xdf, y = SoleData.load_arff_dataset("NATOPS");
