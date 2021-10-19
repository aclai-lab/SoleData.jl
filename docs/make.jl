using SoleBase
using Documenter

DocMeta.setdocmeta!(SoleBase, :DocTestSetup, :(using SoleBase); recursive=true)

makedocs(;
    modules=[SoleBase],
    authors="Eduard I. STAN, Giovanni PAGLIARINI",
    repo="https://github.com/aclai-lab/SoleBase.jl/blob/{commit}{path}#{line}",
    sitename="SoleBase.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://aclai-lab.github.io/SoleBase.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/aclai-lab/SoleBase.jl",
)
