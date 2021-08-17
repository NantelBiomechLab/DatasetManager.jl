module DatasetManager

using Glob, DataFrames, CategoricalArrays, PrettyTables, StatsBase, Printf, ThreadPools,
    ProgressMeter, Crayons

export DataSubset, TrialConditions, Trial, DuplicateSourceError, Segment, SegmentResult,
    AbstractSource, Source, MissingSourceError, UnknownDeps

export findtrials, summarize, analyzedataset, subject, conditions, sources, hassource,
    getsource, sourcepath, readsource, requiresource!, generatesource, dependencies,
    segment, source, readsegment, trial, results, resultsvariables

include("source.jl")
include("trial.jl")
include("segment.jl")
include("stack.jl")
include("summary.jl")

end
