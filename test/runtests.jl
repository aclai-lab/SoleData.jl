using Test
using SoleData.Artifacts
# fill your Artifacts.toml file;
Artifacts.fillartifacts()

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
    #
    ("MLJ", [ "MLJ.jl", ]),
    ("PLA", [ "pla.jl", ]),
    ("Minify", ["minify.jl"]),
    ("Parse", ["parse.jl"]),
    #
    ("Simplification", [ "simplification.jl", ]),
    ("Artifacts", ["artifacts.jl"]),
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
