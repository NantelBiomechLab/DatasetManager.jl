module DatasetManager

using Glob, DataFrames

export DataSubset, TrialConditions, Trial, DuplicateSourceError, Segment, SegmentResult,
    AbstractSource

export findtrials, readsource, readsegment, sourcepath, trial, subject, conditions


include("source.jl")
include("trial.jl")
include("segment.jl")
include("stack.jl")

end
