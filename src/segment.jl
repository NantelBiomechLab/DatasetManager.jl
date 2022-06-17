"""
    Segment(trial, src::Union{S,Type{S},String}; [start, finish, conditions])

Describes a portion of a source in `trial` from time `start` to `finish` with segment
specific `conditions`, if applicable.

If `src` is a String or AbstractSource, it must refer to a source that exists in `trial`.
`start` and `finish` are used in `readsegment` to trim time from the beginning and/or end of
the data read from `src`. `start` and `finish` default to the beginning and end,
respectively, of the source/trial. `start` must be before `finish`, but they are otherwise
only validated during `readsegment`.

Any conditions present in `trial` will be merged into the conditions for the segment.
Note: if `src` is a `<:AbstractSource` instance, it will not be added to the trial's sources.

# Example:

```jldoctest; setup=:(struct Events; end)
julia> t = Trial(1, "intervention", Dict(:group => "control"), Dict("events" => Source{Events}("/path/to/file")));

julia> seg = Segment(t, "events")
Segment{Source{Events},Int64}
 Trial: Trial(1, "intervention", 1 conditions, 1 source)
 Source: Source{Events}("/path/to/file")
 Time: beginning to end
 Conditions: (same as parent trial)
    :group => "control"

julia> seg = Segment(t, Source{Events}("/new/events/file"); start=0.0, finish=10.0, conditions=Dict(:stimulus => "sham"))
Segment{Source{Events},Int64}
 Trial: Trial(1, "intervention", 1 conditions, 1 source)
 Source: Source{Events}("/new/events/file")
 Time: 0.0 to 10.0
 Conditions:
    :stimulus => "sham"
    :group => "control"
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

subject(seg::Segment) = subject(trial(seg))

"""
    source(seg::Union{Segment,SegmentResult}) -> AbstractSource

Return the source for the parent `Trial` of the given `Segment` or
`SegmentResult`
"""
source(seg::Segment) = seg.source

conditions(seg::Segment) = seg.conditions

"""
    SegmentResult(segment::Segment, results::Dict{Symbol)

Contains the results of any analyses performed on the trial segment in a `Dict`.

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

"Get the segment of a `SegmentResult`"
segment(sr::SegmentResult) = sr.segment

"Get the results of a `SegmentResult`"
results(sr::SegmentResult) = sr.results

trial(sr::SegmentResult) = trial(segment(sr))
subject(sr::SegmentResult) = subject(segment(sr))
source(sr::SegmentResult) = source(segment(sr))
conditions(sr::SegmentResult) = conditions(segment(sr))

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
    print(IOContext(io, :compact=>true, :limit=>true), "SegmentResult(",segment(sr),", ")
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
    print(io, ' ', segment(sr))
    println(io)
    show(io, MIME("text/plain"), sr.results)
end

