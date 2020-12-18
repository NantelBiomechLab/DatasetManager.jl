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
        assets=String[
            "../assets/css/custom.css"
        ],
    ),
    pages=[
        "Home" => "index.md",
        "Examples" => [
            "Datasets" => "examples/datasets-examples.md"
        ],
        "Reference" => "reference.md"
    ],
)

deploydocs(;
    repo="github.com/halleysfifthinc/DatasetManager.jl",
)
