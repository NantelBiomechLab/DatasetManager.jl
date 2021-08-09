module DatasetManager

using Glob, DataFrames, CategoricalArrays, PrettyTables, StatsBase, Printf, ThreadPools,
    ProgressMeter, Crayons

export DataSubset, TrialConditions, Trial, DuplicateSourceError, Segment, SegmentResult,
    AbstractSource

export findtrials, analyzedataset, readsource, readsegment, sourcepath, trial, segment,
    subject, sources, hassource, conditions, results, summarize


include("source.jl")
include("trial.jl")
include("segment.jl")
include("stack.jl")
include("summary.jl")

end
