using DatasetManager
using Documenter

DocMeta.setdocmeta!(DatasetManager, :DocTestSetup, :(include(joinpath(@__DIR__, "doctest-setup.jl"))); recursive=true)
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
        highlightjs=joinpath(@__DIR__, "src/assets/js/highlight.min.js"),
        prerender=true,
        ansicolor=true,
    ),
    pages=[
        "Home" => "index.md",
        "Concepts" => [
            "Sources" => "concepts/sources.md",
            "Data Subsets" => "concepts/subsets.md",
        ],
        # "Examples" => [
        #     "Describing datasets" => "examples/datasets-examples.md",
        #     "Working with sources" => "examples/sources.md"
        # ],
        "Julia Reference" => "julia-reference.md",
        "MATLAB Reference" => "matlab-reference.md"
    ],
)

deploydocs(;
    repo="github.com/NantelBiomechLab/DatasetManager.jl",
    push_preview=true
)
