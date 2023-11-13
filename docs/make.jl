using SoleData
using Documenter

DocMeta.setdocmeta!(SoleData, :DocTestSetup, :(using SoleData); recursive=true)

makedocs(;
    modules=[SoleData],
    authors="Lorenzo Balboni, Federico Manzella, Giovanni Pagliarini, Eduard I. Stan",
    repo=Documenter.Remotes.GitHub("aclai-lab", "SoleData.jl"),
    sitename="SoleData.jl",
    format=Documenter.HTML(;
        size_threshold = 4000000,
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://aclai-lab.github.io/SoleData.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Datasets" => "datasets.md",
        "Manipulation" => "manipulation.md",
        "Description" => "description.md",
        "Utils" => "utils.md",
    ],
)

deploydocs(;
    repo = "github.com/aclai-lab/SoleData.jl",
    target = "build",
    branch = "gh-pages",
    versions = ["main" => "main", "stable" => "v^", "v#.#", "dev" => "dev"],
)
