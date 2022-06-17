module DatasetManager

using Glob, DataFrames, CategoricalArrays, PrettyTables, StatsBase, Printf, ThreadPools,
    ProgressMeter, Crayons, NaturalSort, CSV
using Crayons.Box

export DataSubset, TrialConditions, Trial, DuplicateSourceError, Segment, SegmentResult,
    AbstractSource, Source, MissingSourceError, UnknownDeps

export findtrials, findtrials!, summarize, analyzedataset, write_results, export_trials,
    subject, hassubject, conditions, hascondition, addcondition!, renamecondition!,
    recodecondition!, sources, hassource, getsource, sourcepath, readsource, requiresource!,
    generatesource, dependencies, segment, source, readsegment, trial, results,
    resultsvariables

include("source.jl")
include("trial.jl")
include("segment.jl")
include("stack.jl")
include("print.jl")
include("summary.jl")

end
