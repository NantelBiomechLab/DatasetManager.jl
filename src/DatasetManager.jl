module DatasetManager

using DataFrames, CategoricalArrays, PrettyTables, StatsBase, Printf, ThreadPools,
    ProgressMeter, Crayons, NaturalSort, CSV
using Crayons.Box
using Glob: glob

export DataSubset, TrialConditions, Trial, DuplicateSourceError, Segment, SegmentResult,
    AbstractSource, Source, MissingSourceError, UnknownDeps

export findtrials, findtrials!, summarize, analyzedataset, write_results, export_trials,
    subject, conditions, addcondition!, renamecondition!, recodecondition!, hassubject,
    hascondition, hassource, ∨, ∧, sources, getsource, sourcepath, readsource,
    requiresource!, generatesource, dependencies, segment, source, readsegment, trial,
    results, resultsvariables

public stack

"""
    AbstractSource

The abstract supertype for custom sources. Implement a subtype of `AbstractSource` if
`Source{S}` is not sufficient for your source requirements (e.g. your source has additional
information besides the path, such as encoding parameters, compression indicator, etc, that
needs to be associated with each instance).

# Extended help

### `AbstractSource` interface requirements

All subtypes of `AbstractSource` **must**:

- have a `path` field or extend the [`sourcepath`](@ref) function.
- have at least these two constructor methods:
    - empty constructor
    - single argument constructor accepting a string of an absolute path

`AbstractSource` subtypes **should**:

- have a [`readsource`](@ref) method

`AbstractSource` subtypes **may** implement these additional methods to improve user
experience and/or enable additional functionality:

- [`readsegment`](@ref)
- [`generatesource`](@ref) (if enabling `requiresource!` generation)
- [`dependencies`](@ref) (if defining a `generatesource` method)
- [`srcext`](@ref)
- [`srcname_default`](@ref)
"""
abstract type AbstractSource end

"""
    Trial{ID}(subject::ID, name::String, [conditions::Dict{Symbol}, sources::Dict{String}])

Characterizes a single instance of data collected from a specific `subject`. The Trial has a
`name`, and may have one or more `conditions` which describe experimental conditions and/or
subject specific characteristics which are relevant to subsequent analyses. A Trial may have
one or more complementary `sources` of data (e.g. simultaneous recordings from separate
equipment stored in separate files, supplementary data for a primary data source, etc).

# Examples
```jldoctest
julia> trial1 = Trial(1, "baseline", Dict(:group => "control", :session => 2))
Trial{Int64}
  Subject: 1
  Name: baseline
  Conditions:
    :group => "control"
    :session => 2
  No sources
```
"""
mutable struct Trial{I}
    subject::I
    name::String
    const conditions::Dict{Symbol,Any}
    const sources::Dict{String,AbstractSource}
end

include("source.jl")
include("trial.jl")
include("predicates.jl")
include("segment.jl")
include("stack.jl")
include("print.jl")
include("summary.jl")

end
