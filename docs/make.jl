using SoleData
using Documenter

DocMeta.setdocmeta!(SoleData, :DocTestSetup, :(using SoleData); recursive=true)

makedocs(;
    modules=[SoleData],
    authors="Eduard I. STAN, Giovanni PAGLIARINI",
    repo="https://github.com/aclai-lab/SoleData.jl/blob/{commit}{path}#{line}",
    sitename="SoleData.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://aclai-lab.github.io/SoleData.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/aclai-lab/SoleData.jl",
)
