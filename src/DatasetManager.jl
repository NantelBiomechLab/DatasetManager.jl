module DatasetManager

using Glob, DataFrames, CategoricalArrays, PrettyTables, StatsBase, Printf

export DataSubset, TrialConditions, Trial, DuplicateSourceError, Segment, SegmentResult,
    AbstractSource

export findtrials, readsource, readsegment, sourcepath, trial, subject, conditions, results,
    summarize


include("source.jl")
include("trial.jl")
include("segment.jl")
include("stack.jl")
include("summary.jl")

end
