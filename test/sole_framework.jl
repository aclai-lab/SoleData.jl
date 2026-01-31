using Pkg

# get the path of the current package
project_root = (@__DIR__) |> dirname

# store the current active project to restore it in case of error
previous_env = Base.active_project()

try
    # activate a temporary environment
    # in root/tmp
    Pkg.activate(; temp=true)

    Pkg.add("Test")

    # install all sole framework packages
    # no need to skip the package under test,
    # it will be updated with a dev version in the next step
    sole_framework = [
        "SoleModels",
        "SoleLogics",
        "SoleData",
        # "SoleModels",
        "ModalDecisionTrees",
        # "ModalDecisionLists",  # too old, must be revamped
        "ModalAssociationRules",
        # "SoleFeatures",        # yet to be published
        # "SolePostHoc",         # doesnt compile
        # "SoleXplorer"          # yet to be published
    ]
    for package in sole_framework
        Pkg.add(package)
    end

    # develop the current package (the one being tested)
    Pkg.develop(path=project_root)

    # install all packages needed for test the whole sole framework
    # test_dependencies = [
    #     "DataFrames",
    #     "Discretizers",
    #     "Graphs",
    #     "Logging",
    #     "MLJ",
    #     "Random",
    #     "StatsBase",
    #     "Tables",
    #     "ThreadSafeDicts"
    # ]
    # for package in test_dependencies
    #     Pkg.add(package)
    # end

    # test the whole sole ecosystem
    for package in sole_framework
        println("\n" * "="^80)
        println("Testing package: $package")
        println("="^80)

        # pkg_module = Base.require(Main, Symbol(package))
        # package_path = Base.pkgdir(pkg_module)
        # test_file = joinpath(package_path, "test", "runtests.jl")
        
        Pkg.test(package)
    end

catch e
    # tmp folder won't be deleted automatically in case of error
    temp_env_dir = dirname(Base.active_project())
    isdir(temp_env_dir) && rm(temp_env_dir; recursive=true, force=true)
    
    # reactivate the previous environment
    # and re-throw the error with message
    Pkg.activate(previous_env)
    rethrow(e)
end