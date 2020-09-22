using DatasetManager
using Documenter

makedocs(;
    modules=[DatasetManager],
    authors="Allen Hill <allenofthehills@gmail.com> and contributors",
    repo="https://github.com/halleysfifthinc/DatasetManager.jl/blob/{commit}{path}#L{line}",
    sitename="DatasetManager.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://halleysfifthinc.github.io/DatasetManager.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/halleysfifthinc/DatasetManager.jl",
)
