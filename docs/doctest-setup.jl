using DatasetManager, DataFrames, CSV
include(joinpath(pkgdir(DatasetManager), "test", "makedata.jl"))
gensimpledata()
datadir = relpath(joinpath(pkgdir(DatasetManager), "test/data/simple"))
struct GaitEvents; end
subsets = [ DataSubset("events", Source{GaitEvents}, datadir, "*.csv") ]
conds = TrialConditions((:session,:stim), Dict(:session => r"\d", :stim => ["stim", "placebo"]);
    subject_fmt=r"ID(?<subject>\d+)", types=Dict(:session => Int, :stim => String))
ENV["LINES"] = 17

trials = findtrials(subsets, conds;
    ignorefiles=[joinpath(datadir, "ID4_3_stim-02.csv")]);