const TrialLike = Union{Trial,Segment,SegmentResult}
"""
    hassubject(trial, sub) -> Bool

Test if the subject ID for `trial` is equal to `sub`
"""
hassubject(trial::TrialLike, sub) = subject(trial) == sub

"""
    hassubject(sub) -> Bool

Create a function that tests if the subject ID of a trial is equal to `sub`, i.e. a function
equivalent to `t -> hassubject(t, sub)`.

See also: [`hascondition`](@ref), [`hassource`](@ref), [`∨` (\\vee)](@ref ∨), [`∧` (\\wedge)](@ref ∧),
"""
hassubject(sub) = Base.Fix2(hassubject, sub)

"""
    hascondition(trial, (condition [=> value])...) -> Bool

Test if `trial` has `condition`, or that `condition` matches `value`. Specifying `value` is
optional. Multiple conditions and/or condition pairs can be given which all must be true to
match. `value` can be a single level, multiple acceptable levels, or a predicate function.

# Examples

```jldoctest
julia> trial = Trial(1, "baseline", Dict(:group => "control", :session => 2));

julia> hascondition(trial, :group)
true

julia> hascondition(trial, :group => "A")
false

julia> hascondition(trial, :group => ["control", "A"])
true

julia> hascondition(trial, :group => "A", :session => 1)
false

julia> hascondition(trial, :group => ["control", "A"], :session => >=(2))
true

```
"""
hascondition(trial::TrialLike, cond::Symbol...) = all(c -> haskey(conditions(trial), c), cond)
function hascondition(trial::TrialLike, cond::Pair{Symbol,T}) where {T}
    return haskey(conditions(trial), cond.first) && conditions(trial)[cond.first] == cond.second
end
function hascondition(trial::TrialLike, cond::Pair{Symbol,T}) where {T<:Union{AbstractVector,Tuple}}
    return haskey(conditions(trial), cond.first) && conditions(trial)[cond.first] ∈ cond.second
end
function hascondition(trial::TrialLike, cond::Pair{Symbol,T}) where {T<:Function}
    return haskey(conditions(trial), cond.first) && cond.second(conditions(trial)[cond.first])
end

hascondition(trial::TrialLike, conds::Vararg{Pair{Symbol,T} where T<:Any}) = mapreduce(Base.Fix1(hascondition, trial), &, conds)
hascondition(trial::TrialLike, conds::NTuple{N,Pair{Symbol,T} where T<:Any}) where {N} = hascondition(trial, conds...)

"""
    hascondition((condition => value)...) -> Bool

Create a function that tests if a trial has the given `condition`(s)/`value`(s), i.e. a
function equivalent to `t -> hascondition(t, conditions...)`.

See also: [`hassubject`](@ref), [`hassource`](@ref), [`∨` (\\vee)](@ref ∨), [`∧` (\\wedge)](@ref ∧),

# Examples
```jldoctest
julia> trial1 = Trial(1, "baseline", Dict(:group => "control", :session => 2));

julia> trial2 = Trial(2, "baseline", Dict(:group => "A", :session => 1));

julia> filter(hascondition(:group => "A"), [trial1, trial2])
1-element Vector{Trial{Int64}}:
 Trial(2, "baseline", 2 conditions, 0 sources)

```
"""
hascondition(cond::Symbol) = Base.Fix2(hascondition, cond)
hascondition(cond::Pair{Symbol}) = Base.Fix2(hascondition, cond)
hascondition(conds::Vararg{Pair{Symbol,T} where T<:Any}) = Base.Fix2(hascondition, conds)

"""
    hassource(trial, src::String) -> Bool
    hassource(trial, srctype::S) where {S<:AbstractSource} -> Bool
    hassource(trial, src::Regex) -> Bool

Check if `trial` has a source with key or type matching `src`.

# Examples
```jldoctest
julia> trial1 = Trial(1, "baseline", Dict(), Dict("model" => Source{Nothing}()));

julia> hassource(trial1, "model")
true

julia> hassource(trial1, Source{Nothing})
true

julia> hassource(trial1, r"test*")
false
```
"""
hassource(trial::TrialLike, src::String) = haskey(sources(trial), src)
hassource(trial::TrialLike, src::Regex) = any(contains(src), keys(sources(trial)))
hassource(trial::TrialLike, src::S) where {S<:AbstractSource} = src ∈ values(sources(trial))
hassource(trial::TrialLike, ::Type{S}) where {S<:AbstractSource} = S ∈ typeof.(values(sources(trial)))

"""
    hassource(src) -> Bool

Create a function that tests if a trial has the source `src`, i.e. a function equivalent
to `t -> hassource(t, src)`.

See also: [`hassubject`](@ref), [`hascondition`](@ref), [`∨` (\\vee)](@ref ∨), [`∧` (\\wedge)](@ref ∧),

# Examples
```jldoctest
julia> trial1 = Trial(1, "baseline", Dict(), Dict("model" => Source{Nothing}()));

julia> trial2 = Trial(2, "baseline");

julia> filter(hassource("model"), [trial1, trial2])
1-element Vector{Trial{Int64}}:
 Trial(1, "baseline", 0 conditions, 1 source)
```
"""
hassource(s) = Base.Fix2(hassource, s)


"""
    f(x...) ∨ g(y...)

Returns a functor with equivalent behavior to `t -> f(t, x...) || g(t, y...)`. `f` and `g`
must be predicate functions (i.e. return a boolean) which take a single argument (e.g. a
`Trial`, etc).

See also: [`hassubject`](@ref), [`hascondition`](@ref), [`hassource`](@ref),
[`∧` (\\wedge)](@ref ∧)
"""
function ∨ end

"""
    f(x...) ∧ g(y...)

Returns a functor with equivalent behavior to `t -> f(t, x...) && g(t, y...)`. `f` and `g`
must be predicate functions (i.e. return a boolean) which take a single argument (e.g. a
`Trial`, etc).

See also: [`hassubject`](@ref), [`hascondition`](@ref), [`hassource`](@ref),
[`∨` (\\vee)](@ref ∨)
"""
function ∧ end

struct PredicateChain{Op<:Union{typeof(∧),typeof(∨)},F,G}
    f::F
    g::G
end

PredicateChain{Op}(f::F, g::G) where {Op,F,G} = PredicateChain{Op,F,G}(f,g)

function Base.show(io::IO, ::MIME"text/plain", p::PredicateChain{Op}) where {Op}
    preface = get(io, :anonymous_preface, false)

    !preface && print(io, "t -> ")

    f_str = if p.f isa Base.Fix2
        _io = IOBuffer()
        print(_io, p.f.f, "(t, ")
        if p.f.x isa Pair{Symbol, <:Base.Fix2}
            print(_io, repr(p.f.x.first), " => ", p.f.x.second.f, "(", repr(p.f.x.second.x), ")")
        elseif p.f.x isa Tuple
            for (i, tpl) in enumerate(p.f.x)
                if tpl isa Pair{Symbol, <:Base.Fix2}
                    print(_io, repr(tpl.first), " => ", tpl.second.f, "(", repr(tpl.second.x), ")",
                        i == lastindex(p.f.x) ? "" : ", ")
                else
                    print(_io, repr(tpl), i == lastindex(p.g.x) ? "" : ", ")
                end
            end
        else
            print(_io, repr(p.f.x))
        end
        print(_io, ")")
        String(take!(_io))
    else
        _io = IOBuffer()
        _ioc = IOContext(_io, IOContext(io, :anonymous_preface => true))
        print(_ioc, "(")
        show(_ioc, MIME"text/plain"(), p.f)
        print(_ioc, ")")
        String(take!(_io))
    end
    g_str = if p.g isa Base.Fix2
        _io = IOBuffer()
        print(_io, p.g.f, "(t, ")
        if p.g.x isa Pair{Symbol, <:Base.Fix2}
            print(_io, repr(p.g.x.first), " => ", p.g.x.second.f, "(", repr(p.g.x.second.x), ")")
        elseif p.g.x isa Tuple
            for (i, tpl) in enumerate(p.g.x)
                if tpl isa Pair{Symbol, <:Base.Fix2}
                    print(_io, repr(tpl.first), " => ", tpl.second.f, "(", repr(tpl.second.x), ")",
                        i == lastindex(p.g.x) ? "" : ", ")
                else
                    print(_io, repr(tpl), i == lastindex(p.g.x) ? "" : ", ")
                end
            end
        else
            print(_io, repr(p.g.x))
        end
        print(_io, ")")
        String(take!(_io))
    else
        _io = IOBuffer()
        _ioc = IOContext(_io, IOContext(io, :anonymous_preface => true))
        print(_ioc, "(")
        show(_ioc, MIME"text/plain"(), p.g)
        print(_ioc, ")")
        String(take!(_io))
    end
    op_str = if Op <: typeof(∧)
        " && "
    elseif Op <: typeof(∨)
        " || "
    end

    print(io, f_str, op_str, g_str)
end

const HasThingPred = Union{Base.Fix2{typeof(hassubject)},Base.Fix2{typeof(hascondition)},Base.Fix2{typeof(hassource)},PredicateChain}

# OR
function (∨)(f::HasThingPred, g::HasThingPred)
    return PredicateChain{typeof(∨)}(f, g)
end

# AND
function (∧)(f::HasThingPred, g::HasThingPred)
    return PredicateChain{typeof(∧)}(f, g)
end

function (p::PredicateChain{Op})(t) where {Op}
    if Op <: typeof(∧)
        return p.f(t) && p.g(t)
    elseif Op <: typeof(∨)
        return p.f(t) || p.g(t)
    end
end

