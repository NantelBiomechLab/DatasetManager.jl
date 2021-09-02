using DatasetManager, DelimitedFiles

datadir = joinpath(@__DIR__, "data")
mkpath(datadir)

# Simple data
# Naming scheme "ID$id_$session_$stimcondition"
# 10 subjects, 2 sessions, 2 levels in :stim
# Duplicate at "ID4_3_stim-02.csv"
function gensimpledata(;force=false)
    simplepath = joinpath(datadir, "simple")
    !force && isdir(simplepath) && !isempty(readdir(simplepath)) && return nothing

    mkpath(simplepath)
    for id in 1:10, sesh in 1:2, stim in (:stim, :placebo)
        writedlm(joinpath(simplepath, "ID$(id)_$(sesh)_$(stim).csv"),
            ["RHS" "LHS";
             cumsum(1 .+ round.(randn((25,2)) .* (stim === :stim ? .1 : .2), digits=3), dims=1) ], ',')
    end

    writedlm(joinpath(simplepath, "ID4_3_stim-02.csv"),
        ["RHS" "LHS"; cumsum(1 .+ round.(randn((25,2)) .* .1, digits=3), dims=1) ], ',')

    return nothing
end

