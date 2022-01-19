module DatasetManager

using Glob, DataFrames, CategoricalArrays, PrettyTables, StatsBase, Printf, ThreadPools,
    ProgressMeter, Crayons
using Crayons.Box

export DataSubset, TrialConditions, Trial, DuplicateSourceError, Segment, SegmentResult,
    AbstractSource, Source, MissingSourceError, UnknownDeps

export findtrials, summarize, analyzedataset, export_trials, subject, conditions, sources, hassource,
    getsource, sourcepath, readsource, requiresource!, generatesource, dependencies,
    segment, source, readsegment, trial, results, resultsvariables

include("source.jl")
include("trial.jl")
include("segment.jl")
include("stack.jl")
include("summary.jl")

end
