"""
    DataSubset(name, source::Type{<:AbstractSource}, dir, pattern)

Describes a subset of data, where files found within `dir`, with (absolute) paths which
match `pattern` (using [glob syntax](https://en.wikipedia.org/wiki/Glob_(programming))), are
all of the same `AbstractSource` subtype.

# Examples

```jldoctest; setup = :(struct Events; end)
julia> DataSubset("events", Source{Events}, "path/to/subset", "Subject [0-9]*/events/*.tsv")
DataSubset("events", Source{Events}, "path/to/subset", "Subject [0-9]*/events/*.tsv")
```
"""
struct DataSubset
    name::String
    source::Function
    dir::String
    pattern::String
end

function DataSubset(name, source::Type{S}, dir, pattern) where S <: AbstractSource
    return DataSubset(name, (s) -> source(s), dir, pattern)
end

"""
    TrialConditions(conditions, labels; <keyword arguments>)

Describes the experimental conditions and the labels for levels within each condition.

# Arguments

- `conditions` is a collection of condition names (eg `(:medication, :strength)`)
- `labels` is a `Dict` with keys for each condition name (eg `haskey(labels, :medication)`).
Each key gets a collection of the labels for all levels and any transformation desired for
that condition.

# Keyword arguments

- `required=conditions`: The conditions which every trial must have (in the case of some
trials having optional/additional conditions).
- `types=fill(String, length(conditions)`: The (Julia) types for each condition (eg
`[String, Int]`)
- `sep="[_-]"`: The character separating condition labels
"""
struct TrialConditions
    condnames::Vector{Symbol}
    required::Vector{Symbol}
    labels_rg::Regex
    subst::Vector{Pair{Regex,String}}
    types::Vector{Type}
end

function TrialConditions(
    conditions,
    labels;
    required=conditions,
    types=fill(String, length(conditions)),
    sep="[_-]?"
)
    labels_rg = ""
    subst = Vector{Pair{Regex,String}}(undef, 0)

    for (i, cond) in enumerate(conditions)
        labels_rg *= "(?<$cond>"
        if labels[cond] isa Regex
            labels_rg *= labels[cond].pattern

            optchar = cond in required ? "" : "?"
            labels_rg *= string(')', optchar)
            i < length(conditions) && (labels_rg *= sep)
        else
            labels_rg *= join((x isa Pair ? x.second : x for x in labels[cond]), '|')

            optchar = cond in required ? "" : "?"
            labels_rg *= string(')', optchar)
            i < length(conditions) && (labels_rg *= sep)
            foreach(labels[cond]) do condlabel
                if condlabel isa Pair
                    altlabels = condlabel.first isa Union{Symbol,String} ? [condlabel.first] :
                        condlabel.first
                    filter!(label -> label != condlabel.second, altlabels)
                    push!(subst, Regex("("*join(altlabels, '|')*")") => condlabel.second)
                end
            end
        end
    end

    return TrialConditions(collect(conditions), collect(required), Regex(labels_rg), subst, types)
end

"""
    Trial(subject, name, [conditions[, sources]])

Describes a single trial, including a reference to the subject, trial name, trial
conditions, and relevant sources of data.
"""
struct Trial{I}
    subject::I
    name::String
    conditions::Dict{Symbol,Any}
    sources::Dict{String,AbstractSource}
end

function Trial(
    subject::I,
    name,
    conditions=Dict{Symbol,Any}(),
    sources=Dict{String,AbstractSource}()
) where I
    return Trial{I}(subject, String(name), conditions, sources)
end

function Base.show(io::IO, t::Trial)
    print(io, "Trial(", repr(t.subject), ", ", repr(t.name), ", ")
    if get(io, :limit, false)
        print(io, '(')
        _io = IOContext(io, :typeinfo=>eltype(t.conditions))
        first = true
        for p in pairs(t.conditions)
            first || print(_io, ", ")
            first = false
            print(_io, p)
        end
        print(io, "), ")
    else
        print(io, length(t.conditions), " conditions, ")
    end
    numsources = length(t.sources)
    if numsources == 1
        print(io, numsources, " source", ')')
    else
        print(io, numsources, " sources", ')')
    end
end

function Base.show(io::IO, ::MIME"text/plain", t::Trial{I}) where I
    println(io, "Trial{", I, "}")
    println(io, "  Subject: ", t.subject)
    println(io, "  Name: ", t.name)
    print(io, "  Conditions:")
    for c in t.conditions
        print(io, "\n    ")
        print(io, repr(c.first), " => ", repr(c.second))
    end
    print(io, "\n  Sources:")
    for p in t.sources
        print(io, "\n    ")
        print(io, repr(p.first), " => ", repr(p.second))
    end
    println(io)
end

Base.isequal(x::Trial{I}, y::Trial{T}) where {I,T} = false

function Base.isequal(x::Trial{I}, y::Trial{I}) where I
    return x.subject == y.subject && x.name == y.name && x.conditions == y.conditions
end

function Base.hash(x::Trial{I}, h::UInt) where I
    h = hash(x.subject, h)
    h = hash(x.name, h)
    h = hash(x.conditions, h)
    return h
end

Base.copy(x::Trial) = deepcopy(x)

struct DuplicateSourceError <: Exception
    trial
    datasubset
    original::String
    dup::String

    function DuplicateSourceError(
        @nospecialize(trial),
        @nospecialize(datasubset),
        original,
        dup
    )
        Base.@_noinline_meta
        new(trial, datasubset, original, dup)
    end
end

function Base.showerror(io::IO, e::DuplicateSourceError)
    numfolders = count(r"[/\\]", string(e.datasubset.pattern))
    _original = joinpath("…", splitpath(e.original)[(end-numfolders):end]...)
    _dup = joinpath("…", splitpath(e.dup)[(end-numfolders):end]...)

    duplicatesourceerror_show(io, e.trial, e.datasubset, _original, _dup)
end

function duplicatesourceerror_show(io, trial, datasubset, original, dup)
    print(io, "DuplicateSourceError: ")
    print(io, "Found $(repr(datasubset.name)) source file ", dup, " for ")
    show(io, trial)
    print(io, " which already has a $(repr(datasubset.name)) source at ", repr(original))
end

"""
    subject(trial::Trial{ID}) -> subject::ID

Get the subject identifier for `trial`
"""
subject(trial::Trial{ID}) where {ID} = trial.subject

"""
    conditions(trial::Trial{ID}) -> Dict{Symbol,Any}

Get the conditions for `trial`
"""
conditions(trial::Trial) = trial.conditions

"""
    sources(trial::Trial{ID}) -> Dict{String,AbstractSource}

Get the sources for `trial`
"""
sources(trial::Trial) = trial.sources

"""
    hassource(trial, src::Union{String,S<:AbstractSource}) -> Bool

Check if `trial` has a source with key or type `src`.

# Examples
```julia
julia> hassource(trial, "model")
false

julia> hassource(trial, Source{Events})
true
```
"""
hassource(trial::Trial, src::String) = haskey(sources(trial), src)
hassource(trial::Trial, src::S) where S <: AbstractSource = src ∈ values(sources(trial))
hassource(trial::Trial, ::Type{S}) where S <: AbstractSource = S ∈ typeof.(values(sources(trial)))

"""
    getsource(trial, src::Union{String,Type{<:AbstractSource}}) -> <:AbstractSource
    getsource(trial, name::String => src::Type{<:AbstractSource}) -> <:AbstractSource

Return a source from `trial` with key or type `src`. When the second argument is a pair, a
source with key `name` will returned, or of type `src` if no source `name` is present.

If multiple sources of type `src` are present, the desired source must be accessed by name/key only or an error will be thrown.
"""
getsource(trial::Trial, src::String) = sources(trial)[src]
function getsource(trial::Trial, ::Type{S}) where S <: AbstractSource
    only(filter(v -> v isa S, collect(values(sources(trial)))))
end
function getsource(trial::Trial, srcpair::Pair{String,Type{S}}) where S <: AbstractSource
    name, src = srcpair
    return get(sources(trial), name, getsource(trial, src))
end

function readsource(trial::Trial, src; kwargs...)
    readsource(getsource(trial, src); kwargs...)
end

const red = Crayon(foreground=:black, background=(234, 121, 113))
const green = Crayon(foreground=:black, background=(131, 177, 129))
const lgry = Crayon(foreground=:light_gray, background=:nothing)
const rst = Crayon(reset=true)

"""
    findtrials(subsets::AbstractVector{DataSubset}, conditions::TrialConditions;
        <keyword arguments>) -> Vector{Trial}

Find all the trials matching `conditions` which can be found in `subsets`.

# Keyword arguments:

- `subject_fmt=r"(?<=Subject )(?<subject>\\d+)"`: The format that the subject identifier
   will appear in file paths.
- `ignorefiles::Union{Nothing, Vector{String}}=nothing`: A list of files, given in the form
   of an absolute path, that are in any of the `subsets` folders which are to be ignored.
- `defaultconds::Union{Nothing, Dict{Symbol}}=nothing`: Any conditions which have a default
   level if the condition is not found in the file path.
- `debug=false`: Show Regex and files that did not match for each subset. Use to debug
   `TrialConditions` definitions or issues with `subject_fmt` failing to match subject ID's.
"""
function findtrials(
    subsets::AbstractVector{DataSubset},
    conditions::TrialConditions;
    I::Type=Int,
    subject_fmt=r"Subject (?<subject>\d+)",
    debug=false,
    ignorefiles::Union{Nothing, Vector{String}}=nothing,
    defaultconds::Union{Nothing, Dict{Symbol}}=nothing
)
    trials = Vector{Trial{I}}()
    rg = Regex(subject_fmt.pattern*".*?"*conditions.labels_rg.pattern)
    debug && println(stderr, "Searching using regex: ", rg)
    reqcondnames = conditions.required
    if isnothing(defaultconds)
        defaultconds = Dict{Symbol,String}()
    end
    optcondnames = setdiff(conditions.condnames, reqcondnames, keys(defaultconds))

    for set in subsets
        debug && println(stderr, "┌ Subset ", repr(set.name))
        pattern = set.pattern
        files = glob(pattern, set.dir)
        if !isnothing(ignorefiles)
            setdiff!(files, ignorefiles)
        end

        for file in files
            _file = foldl((str, pat) -> replace(str, pat), conditions.subst; init=file)
            m = match(rg, _file)

            if isnothing(m)
                if debug
                    pretty_file = foldl((str, pat) -> replace(str, first(pat) =>
                        SubstitutionString(string(red, "\\1", green, last(pat), rst, lgry))),
                        conditions.subst; init=string(lgry, file, rst))*string(rst)
                    println(stderr, "│ ╭ No match")
                    println(stderr, "│ ╰ @ \"", pretty_file, '"')
                end
                continue
            end

            if isnothing(m[:subject]) || any(isnothing.(m[cond] for cond in reqcondnames))
                if debug
                    pretty_file = foldl((str, pat) -> replace(str, first(pat) =>
                        SubstitutionString(string(red, "\\1", green, last(pat), rst, lgry))),
                        conditions.subst; init=string(lgry, file, rst))*string(rst)
                    mstr = repr(m)
                    _rgx = Regex("(("*join(reqcondnames,'|')*")=nothing)")
                    pretty_mstr = replace(mstr, _rgx =>
                        SubstitutionString(string(crayon"bold", "\\1", crayon"!bold")))
                    println(stderr, "│ ╭ Match: ", pretty_mstr)
                    println(stderr, "│ ╰ @ \"", pretty_file, "\"")
                end
                continue
            else
                name = splitext(basename(file))[1]
                sid = !(I <: String) ? parse(I, m[:subject]) : String(m[:subject])
                seenall = findall(trials) do trial
                    trial.subject == sid &&
                    all(enumerate(conditions.condnames)) do (i, cond)
                        trialcond = get(trial.conditions, cond,
                            get(defaultconds, cond, nothing))
                        if isnothing(m[cond])
                            return defaultconds[cond] == trialcond
                        elseif conditions.types[i] === String
                            return m[cond] == trialcond
                        else
                            parse(conditions.types[i], m[cond]) == trialcond
                        end
                    end
                end

                if isempty(seenall)
                    conds = Dict(cond => String(m[cond]) for cond in reqcondnames)
                    foreach(defaultconds) do (k,v)
                        if isnothing(m[k])
                            conds[k] = String(v)
                        else
                            conds[k] = String(m[k])
                        end
                    end
                    foreach(enumerate(optcondnames)) do (i, cond)
                        if !isnothing(m[cond])
                            if conditions.types[i] === String
                                conds[cond] = String(m[cond])
                            else
                                conds[cond] = parse(conditions.types[i], m[cond])
                            end
                        end
                    end
                    push!(trials, Trial(sid, name, conds,
                        Dict{String,AbstractSource}(set.name => set.source(file))))
                else
                    seen = only(seenall)
                    t = trials[seen]
                    if haskey(t.sources, set.name)
                        throw(DuplicateSourceError(t, set, sourcepath(t.sources[set.name]),
                            file))
                    else
                        t.sources[set.name] = set.source(file)
                    end
                end
            end
        end
        debug && println(stderr, "└ End subset: ", repr(set.name))
    end

    return trials
end

"""
    analyzedataset(f, trials, Type{<:AbstractSource}; kwargs...) -> Vector{SegmentResult}

Call function `f` on every trial in `trials` in parallel (multi-threaded). If `f` errors for
a given trial, the `SegmentResult` for that trial will be empty (no results), and the trial
and error will be shown after the analysis has finished.

# Keyword arguments
- `threaded=true`: Analyze `trials` using multiple threads
- `enable_progress=true`: Enable the progress meter
"""
function analyzedataset(
    fun, trials::AbstractVector{Trial{I}}, ::Type{SRC};
    threaded=true, enable_progress=true
) where I where SRC <: AbstractSource
    srs = Vector{SegmentResult{SRC,I}}(undef, length(trials))
    p = Progress(length(trials)+1; output=stdout, enabled=enable_progress,
        desc="Analyzing trials... ")

    if threaded
        @qthreads for i in eachindex(trials)
            srs[i] = try
                fun(trials[i])
            catch e
                bt = catch_backtrace()
                io = IOBuffer()
                print(io, e)
                Base.show_backtrace(IOContext(io, IOContext(stderr)), bt)
                err = replace(String(take!(io)), "\n" => "\n│ ")
                @error trials[i] err
                SegmentResult(Segment(trials[i], SRC()))
            end
            next!(p)
        end
    else
        srs[i] = try
            fun(trials[i])
        catch e
            bt = catch_backtrace()
            io = IOBuffer()
            print(io, e)
            Base.show_backtrace(IOContext(io, IOContext(stderr)), bt)
            err = replace(String(take!(io)), "\n" => "\n│ ")
            @error trials[i] err
            SegmentResult(Segment(trials[i], SRC()))
        end
        next!(p)
    end
    finish!(p)

    return srs
end
