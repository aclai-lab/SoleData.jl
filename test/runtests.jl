using Distributed
addprocs(2)

@everywhere begin
    using SoleData
    using Test
    using Random
    using StatsBase
    using SoleData
    using SoleLogics
    using MLJ
    using Tables
    using DataFrames
    using Graphs
    using Logging
    using ThreadSafeDicts
    # using StableRNGs
end

function run_tests(list)
    println("\n" * ("#"^50))
    for test in list
        println("TEST: $test")
        include(test)
    end
end

println("Julia version: ", VERSION)

test_suites = [
    ("Logisets", [ "logisets.jl", ]),
    ("Propositional Logisets", [ "propositional-logisets.jl", ]),
    ("Memosets", [ "memosets.jl", ]),
    #
    ("Cube to Logiset", [ "cube2logiset.jl", ]),
    ("DataFrame to Logiset", [ "dataframe2logiset.jl", ]),
    ("MultiLogisets", [ "multilogisets.jl", ]),
    #
    ("Conditions", [ "range-scalar-condition.jl", ]),
    ("Alphabets", [ "scalar-alphabet.jl", "discretization.jl"]),
    ("Features", [ "var-features.jl", "patchedfeatures.jl" ]),
    ("Visualizations", [ "visualizations.jl", ]),
    # 
    ("MLJ", [ "MLJ.jl", ]),
    ("PLA", [ "pla.jl", ]),
    ("Minify", ["minify.jl"]),
    ("Parse", ["parse.jl"]),
    ("Example Datasets", [ "example-datasets.jl", ]),
    ("Variable Named Features", [ "var-features.jl", ]),
    #
    ("Artifacts", ["artifacts.jl"]),
    ("Simplification", [ "simplification.jl", ]),
]

@testset "SoleData.jl" begin
    for ts in eachindex(test_suites)
        name = test_suites[ts][1]
        list = test_suites[ts][2]
        let
            @testset "$name" begin
                run_tests(list)
            end
        end
    end
    println()
end
