"""
    Segment(trial, src::Union{S,Type{S},String}; [start, finish, conditions])

Describes a portion of a source in `trial` from time `start` to `finish` with segment
specific `conditions`, if applicable.

If `src` is a String or AbstractSource, it must refer to a source that exists in `trial`.
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

        return new(trial, source, convert(Union{Nothing,Float64}, start), convert(Union{Nothing,Float64}, finish), merge(trial.conditions, conditions))
    end
end

function Segment(
    trial::Trial{ID},
    source::S;
    start=nothing,
    finish=nothing,
    conditions::Dict{Symbol}=Dict{Symbol,Any}()
) where {ID, S <: AbstractSource}
    return Segment{S,ID}(trial, source, start, finish, conditions)
end

function Segment(
    trial::Trial{ID},
    sourcename::String;
    kwargs...
) where ID
    hassource(trial, sourcename) ||
        throw(ArgumentError("source \"$sourcename\" not found in trial"))
    source = sources(trial)[sourcename]

    if (start = get(kwargs, :start, nothing)) isa Function
        start = start(trial)
    end
    if (finish = get(kwargs, :finish, nothing)) isa Function
        finish = finish(trial)
    end

    return Segment(trial, source; kwargs..., start, finish)
end

function Segment(trial, src::Type{<:AbstractSource}; kwargs...)
    Segment(trial, getsource(trial, src); kwargs...)
end

function Base.show(io::IO, s::Segment{S,ID}) where {S,ID}
    print(IOContext(io, :limit=>true), "Segment{$S,$ID}($(s.trial), ", typeof(s.source), "(…), ")
    print(io, isnothing(s.start) ? "begin" : s.start, ":")
    print(io, isnothing(s.finish) ? "end" : s.finish)
    if s.conditions == conditions(trial(s))
        print(io, ")")
    else
        print(io, ", (")
        _io = IOContext(io, :typeinfo=>eltype(s.conditions))
        first = true
        for p in pairs(s.conditions)
            first || print(_io, ", ")
            first = false
            print(_io, p)
        end
        print(io, "))")
    end
end

function Base.show(io::IO, _::MIME"text/plain", s::Segment{S,ID}) where {S,ID}
    println(IOContext(io, :limit=>true), "Segment{$S,$ID}\n Trial: $(s.trial)")
    println(io, " Source: ", s.source)
    print(io, " Time: ", isnothing(s.start) ? "beginning" : s.start)
    println(io, " to ", isnothing(s.finish) ? "end" : s.finish)
    print(io, " Conditions: ")
    if s.conditions == conditions(trial(s))
        print(io, "(same as parent trial)")
    end
    for c in s.conditions
        print(io, "\n    ")
        print(io, repr(c.first), " => ", repr(c.second))
    end
end

"""
    readsegment(seg::Segment{S}; warn=true, kwargs...) where S <: AbstractSource

If defined for `S`, returns the portion of `seg.source` from `seg.start` to `seg.finish`.
Otherwise, equivalent to `readsource` (i.e. no trimming of time-series occurs). Warns by
default if the main method is called.
"""
function readsegment(seg::Segment; warn=true, kwargs...)
    if warn
        @warn "A method of `readsegment` has not been defined for `$(typeof(source(seg)))`;"*
            "this means that `seg.start` and `seg.finish` will be ignored" maxlog=1
    end
    readsource(source(seg); kwargs...)
end

"""
    trial(seg::Union{Segment,SegmentResult}) -> Trial

Return the parent `Trial` for the given `Segment` or `SegmentResult`
"""
trial(seg::Segment) = seg.trial

subject(seg::Segment) = subject(seg.trial)

"""
    source(seg::Union{Segment,SegmentResult}) -> AbstractSource

Return the source for the parent `Trial` of the given `Segment` or
`SegmentResult`
"""
source(seg::Segment) = seg.source

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
SegmentResult(seg::Segment) = SegmentResult(seg, Dict{String,Any}())

trial(sr::SegmentResult) = trial(sr.segment)
subject(sr::SegmentResult) = subject(sr.segment)
source(sr::SegmentResult) = source(sr.segment)

"Get the segment of a `SegmentResult`"
segment(sr::SegmentResult) = sr.segment
conditions(sr::SegmentResult) = conditions(sr.segment)

"Get the results of a `SegmentResult`"
results(sr::SegmentResult) = sr.results

"""
    resultsvariables(sr::Union{SegmentResult,Vector{SegmentResult}})

Get the unique variables for `SegmentResult`s.
"""
resultsvariables(sr::SegmentResult) = collect(keys(results(sr)))
function resultsvariables(srs::Vector{<:SegmentResult})
    ks = reduce(vcat, collect.(unique(keys.(results.(srs)))))
    sort!(ks)
    unique!(ks)
end

function Base.show(io::IO, sr::SegmentResult)
    print(IOContext(io, :compact=>true, :limit=>true), "SegmentResult(",sr.segment,", ")
    if isempty(results(sr))
        print(io, "No results)")
    else
        nresults = length(keys(sr.results))
        if nresults > 4
            print(io, nresults, " results", ')')
        else
            print(IOContext(io, :limit=>true), "Results keys: ", keys(sr.results), ')')
        end
    end
end

function Base.show(io::IO, _::MIME"text/plain", sr::SegmentResult{S,ID}) where {S,ID}
    println(io, "SegmentResult{$S,$ID}")
    print(io, ' ', sr.segment)
    println(io)
    show(io, MIME("text/plain"), sr.results)
end

