using DatasetManager
using DatasetManager: unique_subjects, unique_sources, unique_conditions, observed_levels

using Test

@testset "DatasetManager.jl" begin
    if isdir(joinpath(@__DIR__, "private"))
        include(joinpath(@__DIR__, "private", "runtests.jl"))
    end
end
