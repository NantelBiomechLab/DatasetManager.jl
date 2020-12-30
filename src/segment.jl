"""
    Segment(
            trial::Trial,
            source::S,
            start::Union{Nothing,Float64},
            finish::Union{Nothing,Float64}=nothing,
            conds::Dict{Symbol}=Dict{Symbol,Any}()
    ) where {S<:AbstractSource}
    Segment(trial, source, start::Union{Nothing,Float64}, conds::Dict{Symbol})

A `Segment` describes a portion of a Source from a given Trial, with start and finish times, and segment specific conditions, if applicable.

If the finish time is omitted, the Segment will be from the given start time to the end of the Source/Trial.

Any conditions present in the parent Trial will be merged into the conditions for the segment. If there are no relevant specific conditions to add for the segment, the conditions may be omitted.

# Example:

```julia
t = Trial(1) # TODO: Finish this example trial constructor

struct MySource <: AbstractSource
    path::String
end

seg = Segment(t,MySource, 0.0, 10.0, Dict(:group => "control"))

# No conditions for these segments
seg2 = Segment(t, MySource, 0.0, 10.0)
seg3 = Segment(t, MySource, 25.0)

# Include the entire time of this Trial/Source
seg4 = Segment(t, MySource, 0.0, Dict(:group => "control"))
```
"""
struct Segment{S<:AbstractSource,ID}
    trial::Trial{ID}
    source::S
    start::Union{Nothing,Float64} # Start time
    finish::Union{Nothing,Float64} # End time
    conds::Dict{Symbol}

    function Segment{S,ID}(trial::Trial{ID}, source::S, start, finish, conds) where {ID,S<:AbstractSource}
        start ≥ 0.0 || throw(DomainError("start time must be positive; got $start"))
        if !isnothing(finish)
            start ≤ finish || throw(DomainError(finish,
                "finish time must be ≥ start time; got $finish"))
        end

        return new(trial, source, start, finish, merge(conds, trial.conds))
    end
end

function Segment(
        trial::Trial{ID},
        source::S,
        start::Union{Nothing,Float64},
        finish::Union{Nothing,Float64}=nothing,
        conds::Dict{Symbol}=Dict{Symbol,Any}()
) where {ID,S}
    return Segment{S,ID}(trial, source, start, finish, conds)
end

function Segment(trial, source, start::Union{Nothing,Float64}, conds::Dict{Symbol})
    Segment(trial, source, start, nothing, conds)
end

function Base.show(io::IO, s::Segment{S,ID}) where {S,ID}
    print(io, "Segment{$S,$ID}(", s.trial, ", ", typeof(s.source), "(…), ", s.start, ":",
        isnothing(s.finish) ? "end" : s.finish, ", ", s.conds, ")")
end

function Base.show(io::IO, mimet::MIME"text/plain", s::Segment{S,ID}) where {S,ID}
    println(io, "Segment{$S,$ID}")
    show(io, s.trial)
    println(io)
    print(io, s.source)
    println(io, " from $(s.start) to $(isnothing(s.finish) ? "the end" : s.finish)")
    show(io, mimet, s.conds)
end

"""
    readsegment(seg::Segment; kwargs...)

Read the source from time `start` (in `seg`) to time `finish` (in `seg`).

# Note:

Custom subtypes e.g. `MySource <: AbstractSource` must implement this function to enable reading `Segment{MySource}` with this function.
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
conditions(seg::Segment) = seg.conds

"""
    SegmentResult(segment::Segment, results::Dict{Symbol)

Contains the results of any analysis/analyses performed on the trial segment in a Dictionary.

# Example:

```julia
segresult = SegmentResult(seg, Dict(:avg => 3.5))
```

"""
struct SegmentResult{S,ID}
    segment::Segment{S,ID}
    results::Dict{Symbol}
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

