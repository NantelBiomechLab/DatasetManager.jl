"""
    Segment(trial, source::Union{AbstractSource,String}; [start, finish, conditions])

Describes a portion of a source in `trial` from time `start` to `finish` with segment
specific `conditions`, if applicable.

If `source isa String`, it must refer to a source that exists in `trial`.
If the `start` is omitted, the segment will start at the beginning of the source/trial.
If the `finish` is omitted, the segment will be from time `start` to the end of the
source/trial.

Any conditions present in `trial` will be merged into the conditions for the segment.

# Example:

```julia
t = Trial(1, "intervention")

struct MySource <: AbstractSource
    path::String
end

seg = Segment(t, MySource; start=0.0, finish=10.0, conditions=Dict(:group => "control"))

# Use a source that already exists in the trial
seg5 = Segment(t, "main")
```
"""
struct Segment{S<:AbstractSource,ID}
    trial::Trial{ID}
    source::S
    start::Union{Nothing,Float64} # Start time
    finish::Union{Nothing,Float64} # End time
    conditions::Dict{Symbol}

    function Segment{S,ID}(
        trial::Trial{ID}, source::S, start, finish, conditions
    ) where {ID,S<:AbstractSource}
        if !isnothing(finish)
            start ≤ finish || throw(DomainError(finish,
                "finish time must be ≥ start time; got $finish"))
        end

        return new(trial, source, start, finish, merge(trial.conditions, conditions))
    end
end

function Segment(
    trial::Trial{ID},
    source::S;
    start::Union{Nothing,Float64}=nothing,
    finish::Union{Nothing,Float64}=nothing,
    conditions::Dict{Symbol}=Dict{Symbol,Any}()
) where {ID, S <: AbstractSource}
    return Segment{S,ID}(trial, source, start, finish, conditions)
end

function Segment(
    trial::Trial{ID},
    sourcename::String;
    kwargs...
) where ID
    haskey(trial.sources, sourcename) || throw(DomainError("source $sourcename not found in trial"))
    source = trial.sources[sourcename]
    S = typeof(source)

    return Segment(trial, source; kwargs...)
end

function Base.show(io::IO, s::Segment{S,ID}) where {S,ID}
    print(io, "Segment{$S,$ID}(", s.trial, ", ", typeof(s.source), "(…), ")
    print(io, isnothing(s.start) ? "begin" : s.start, ":")
    print(io, isnothing(s.finish) ? "end" : s.finish, ", ", s.conditions, ")")
end

function Base.show(io::IO, mimet::MIME"text/plain", s::Segment{S,ID}) where {S,ID}
    println(io, "Segment{$S,$ID}")
    show(io, s.trial)
    println(io)
    print(io, s.source)
    println(io, " from $(s.start) to $(isnothing(s.finish) ? "the end" : s.finish)")
    show(io, mimet, s.conditions)
end

function readsegment end

"""
    readsegment(seg::Segment; kwargs...)

Return the portion of `seg.source` from `seg.start` to `seg.finish`.

# Extended help

Subtypes of `AbstractSource` must implement this function to enable reading
`Segment{MySource}` with this function.
"""
function readsegment end

"""
    trial(seg::Union{Segment,SegmentResults}) -> Trial

Return the parent `Trial` for the given `Segment` or `SegmentResult`
"""
trial(seg::Segment) = seg.trial

"""
    subject(seg::Union{Segment,SegmentResults})

Return the subject reference for the parent `Trial` of the given `Segment` or
`SegmentResult`
"""
subject(seg::Segment) = seg.trial.subject

"""
    conditions(seg::Union{Segment,SegmentResults}) -> Dict{Symbol}

Return the conditions for the given `Segment` or `SegmentResult`
"""
conditions(seg::Segment) = seg.conditions

"""
    SegmentResult(segment::Segment, results::Dict{Symbol)

Contains the results of any analysis/analyses performed on the trial segment in a `Dict`.

# Example:

```julia
segresult = SegmentResult(seg, Dict(:avg => 3.5))
```
"""
struct SegmentResult{S,ID}
    segment::Segment{S,ID}
    results::Dict{String}
end

function SegmentResult(segment::Segment{S,ID}, results) where {S,ID}
    SegmentResult{S,ID}(segment, results)
end

trial(sr::SegmentResult) = trial(sr.segment)
subject(sr::SegmentResult) = subject(sr.segment)
conditions(sr::SegmentResult) = conditions(sr.segment)

Base.show(io::IO, sr::SegmentResult) = print(io, "SegmentResult(",sr.segment,",", sr.results,")")

function Base.show(io::IO, ::MIME"text/plain", sr::SegmentResult{S,ID}) where {S,ID}
    println(io, "SegmentResult{$S,$ID}")
    show(io, sr.segment)
    println(io)
    show(io, MIME("text/plain"), sr.results)
end

