using DatasetManager
using Documenter

DocMeta.setdocmeta!(DatasetManager, :DocTestSetup, :(using DatasetManager); recursive=true)
makedocs(;
    modules=[DatasetManager],
    authors="Allen Hill <allenofthehills@gmail.com> and contributors",
    repo="https://github.com/NantelBiomechLab/DatasetManager.jl/blob/{commit}{path}#L{line}",
    sitename="DatasetManager.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://NantelBiomechLab.github.io/DatasetManager.jl",
        assets=String[
            "assets/css/custom.css"
        ],
        highlights=["matlab"],
    ),
    pages=[
        "Home" => "index.md",
        "Examples" => [
            "Describing datasets" => "examples/datasets-examples.md",
            "Defining `AbstractSource` subtypes" => "examples/abstractsource-subtypes.md"
        ],
        "Julia Reference" => "julia-reference.md",
        "MATLAB Reference" => "matlab-reference.md"
    ],
)

deploydocs(;
    repo="github.com/NantelBiomechLab/DatasetManager.jl",
)
