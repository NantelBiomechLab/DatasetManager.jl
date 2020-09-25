"""
    Segment

A `Segment` is a container which includes all of, or a part of the data from a particular `Trial`.
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

function Segment(trial::Trial{ID}, source::S, start, finish, conds) where {ID,S}
    return Segment{S,ID}(trial, source, start, finish, conds)
end

function Segment(trial, source, start::Union{Nothing,Float64}, conds::Dict{Symbol})
    Segment(trial, source, start, nothing, conds)
end

function Segment(trial, source, start::Union{Nothing,Float64}, finish::Union{Nothing,Float64})
    Segment(trial, source, start, finish, Dict{Symbol,Any}())
end

function Segment(trial, source, start::Union{Nothing,Float64})
    Segment(trial, source, start, nothing)
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
    SegmentResult

Contains the results of any analysis/analyses performed on the trial segment.
"""
struct SegmentResult{S,ID}
    segment::Segment{S,ID}
    results::Dict{Symbol}
end

Trial(sr::SegmentResult) = sr.segment.trial

Base.show(io::IO, sr::SegmentResult) = print(io, "SegmentResult(",sr.segment,",", sr.results,")")

function Base.show(io::IO, ::MIME"text/plain", sr::SegmentResult{S,ID}) where {S,ID}
    println(io, "SegmentResult{$S,$ID}")
    show(io, sr.segment)
    println(io)
    show(io, MIME("text/plain"), sr.results)
end

