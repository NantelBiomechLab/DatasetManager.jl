module DatasetManager

using Glob

export DataSubset, TrialConditions, Trial, DuplicateSourceError, Segment, SegmentResult,
    AbstractSource

export findtrials, readsource, readsegment, path

include("sources/source.jl")
include("trial.jl")
include("segment.jl")


end
