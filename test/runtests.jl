using SoleData
using SoleLogics
using Test
using Random

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
    ("Example Datasets", [ "example-datasets.jl", ]),
    ("Propositional Logisets", [ "propositional-logisets.jl", ]),
    ("Memosets", [ "memosets.jl", ]),
    ("Cube to Logiset", [ "cube2logiset.jl", ]),
    ("DataFrame to Logiset", [ "dataframe2logiset.jl", ]),
    ("MultiLogisets", [ "multilogisets.jl", ]),
    ("MLJ", [ "MLJ.jl", ]),
    ("Minify", ["minify.jl"]),
    ("Discretization", ["discretization.jl"]),
    ("Parse", ["parse.jl"]),
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
