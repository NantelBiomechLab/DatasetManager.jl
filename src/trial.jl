"""
    DataSubset(name, source::Union{Function,<:AbstractSource}, dir, pattern; [dependent=false])

Describes a subset of `source` data files found within `dir` which match `pattern` (using
[glob syntax](https://en.wikipedia.org/wiki/Glob_(programming))). The `name` of the
DataSubset will be used in `findtrials` as the source name in a Trial.

Some sources described by a DataSubset may not be relevant as standalone/independent Trials
(e.g. maximal voluntary contraction "trials", when collecting EMG data, are typically only
relevant to movement trials for a given subject/session of a data collection, but are not
useful on their own). Dependent sources (eg `dependent=true`) will not create new trials in
`findtrials` and will only be added to pre-existing trials when the required conditions and
a "condition" with the same name as the DataSubset's `name` exists. The matched "condition"
will be used in `findtrials!` as the source name in corresponding Trials.

If `source` is a function, it must accept a file path and return a Source.

See also: [`Source`](@ref), [`TrialConditions`](@ref), [`findtrials`](@ref),
[`findtrials!`](@ref)

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
    ext::String
    dependent::Bool

    DataSubset(name, source, dir, pattern, ext=".", dependent=false) = new(name, source, dir, pattern, escape_period(ext), dependent)
end

function escape_period(ext)
    return replace(ext, r"^\\?\.?" => "\\.")
end

function DataSubset(name, source::Type{S}, dir, pattern; ext=escape_period(srcext(source)), dependent=false) where S <: AbstractSource
    return DataSubset(name, (s) -> source(s), dir, pattern, ext, dependent)
end

function Base.show(io::IO, ds::DataSubset)
    print(io, "DataSubset(", repr(ds.name), ", ", typeof(ds.source("")), ", ",
        repr(ds.dir), ", ", repr(ds.pattern), ')')
end

"""
    TrialConditions(conditions, labels; [required, types, defaults, subject_fmt])

Describes the experimental conditions (aka factors) and the labels for levels within each condition.

# Arguments

- `conditions` is a collection of condition names (eg `(:medication, :dose)`) in the order
  they must appear in the file paths of trial sources
- `labels` must have a key-value pair for each condition name. The value(s) for each key
  describes how that condition will be matched. Acceptable options include a Regex, a pair
  (`old` => `transf` [=> `new`], where `old` may be a Regex or one/multiple String(s), and
  where `transf` may be a `Function` or a `SubstitutionString` (if `old` is a
  Regex), and `new` is a Regex), or an array of any of the preceding. Keys in `labels` which
  are not included in `conditions` will be ignored.

# Keyword arguments

- `required=conditions`: The conditions which every trial is required to have. C
- `types=Dict(conditions .=> String)`: The types that each condition should be parsed as
- `defaults=Dict{Symbol,Any}()`: Default conditions to set when a given condition is not matched
- `subject_fmt=r"Subject (?<subject>\\d+)?"`: The Regex pattern used to match the trial's
    subject ID. Any patterns given under a `:subject` key in `labels` takes precedence.

# Examples
```julia-repl
julia> labels = Dict(
    :subject => r"(?<=Patient )\\d+",
    :group => ["Placebo" => "Control", "Group A", "Group B"],
    :posture => r"(sit|stand)"i => lowercase,
    :cue => r"cue[-_](fast|slow)" => ((s) -> "\$s cue") => r"(fast|slow) cue");

julia> conds = TrialConditions((:subject,:group,:posture,:cue), labels; types=Dict(:subject => Int));
```
"""
struct TrialConditions
    condnames::Vector{Symbol}
    required::Vector{Symbol}
    labels::Dict{Symbol, Regex}
    types::Dict{Symbol,DataType}
    defaults::Dict{Symbol,Any}
    subst::Vector{Pair{Regex,Any}}

    function TrialConditions(conds, required, labels, types, defaults, subst)
        @assert :subject ∈ conds
        :subject ∉ required && push!(required, :subject)
        @assert issubset(conds, keys(labels))
        @assert issubset(required, conds)
        get!.(Ref(types), setdiff(conds, keys(types)), String)
        @assert issubset(conds, keys(types))

        return new(conds, required, labels, types, defaults, subst)
    end
end

str_rgx(r::Regex) = r.pattern
str_rgx(str::String) = str

# TODO: Add tests labels (ie values in `labels`) for:
    # - Regex
    # - Regex => Function
    # - Regex => Function => Vector{String}
    # - Regex => Function => Regex
    # - Regex => SubstitutionString => Regex
    # - Vector{String}
    # - Vector{Union{String,Pair{Vector{String},String}}}
    # - Vector{Pair{Vector{String},String}}
function TrialConditions(
    conditions,
    labels;
    required=conditions,
    types=Dict(conditions .=> String),
    defaults=Dict{Symbol,Any}(),
    subject_fmt=r"Subject (?<subject>\d+)?",
)
    labels_rg = Dict{Symbol,Regex}()
    subst = Vector{Pair{Regex,Any}}(undef, 0)
    conditions = collect(conditions)
    flag = ""

    for cond in conditions
        rg = IOBuffer()
        print(rg, "(?<$cond>")
        if labels[cond] isa Regex
            print(rg, str_rgx(labels[cond]), ')')
            if !iszero(labels[cond].compile_options & Base.PCRE.CASELESS)
                flag = "i"
            end
        elseif typeof(labels[cond]) <: Pair{Regex,Pair{T1,T2}} where {T1,T2}
            if labels[cond].second.second isa Regex || labels[cond].second.second isa String
                print(rg, str_rgx(labels[cond].second.second), ')')
            else
                join(rg, (str_rgx(x) for x in labels[cond].second.second ), '|')
                print(rg, ')')
            end
            push!(subst, labels[cond].first => labels[cond].second.first)
        elseif typeof(labels[cond]) <: Pair{Regex,F} where F <: Function
            print(rg, str_rgx(labels[cond].first), ')')
            push!(subst, labels[cond])
            if !iszero(labels[cond].first.compile_options & Base.PCRE.CASELESS)
                flag = "i"
            end
        else
            join(rg, (x isa Pair ? str_rgx(x.second) : str_rgx(x)
                for x in labels[cond]), '|')
            print(rg, ')')

            foreach(labels[cond]) do condlabel
                if condlabel isa Pair
                    if condlabel.first isa Regex
                        push!(subst, condlabel)
                    else
                        altlabels = condlabel.first isa String ? [condlabel.first] :
                            condlabel.first
                        filter!(label -> label != condlabel.second, altlabels)
                        push!(subst, Regex("("*join(altlabels, '|')*")") => condlabel.second)
                    end
                end
            end
        end
        labels_rg[cond] = Regex(String(take!(rg)), flag)
    end
    if :subject ∉ conditions
        labels_rg[:subject] = subject_fmt
        pushfirst!(conditions, :subject)
    end

    return TrialConditions(conditions, collect(required), labels_rg, types, defaults, subst)
end

function extract_conditions(file, trialconds)
    conds = Dict{Symbol,Any}()
    last_ofst = 1
    first_ofst = 1

    for (i,cond) in enumerate(trialconds.condnames)
        m = match(trialconds.labels[cond], file, last_ofst)
        if !isnothing(m) && !isnothing(m[cond])
            conds[cond] = String(m[cond])
            i == 1 && (first_ofst = m.offset)
            last_ofst = m.offset + length(m.match)
        end
    end

    return file[first_ofst:end], conds
end

"""
    Trial(subject, name, [conditions, sources])

Describes a single trial, including a reference to the subject, trial name, trial
conditions, and relevant sources of data.
"""
mutable struct Trial{I}
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
    if get(io, :compact, true) || get(io, :limit, true)
        print(io, length(conditions(t)), " conditions, ")
    else
        print(io, '(')
        _io = IOContext(io, :typeinfo=>eltype(conditions(t)))
        first = true
        for p in pairs(conditions(t))
            first || print(_io, ", ")
            first = false
            print(_io, p)
        end
        print(io, "), ")
    end
    numsources = length(sources(t))
    plural = numsources == 1 ? "" : "s"
    print(io, numsources, " source", plural, ')')
end

function Base.show(io::IO, _::MIME"text/plain", t::Trial{I}) where I
    println(io, "Trial{", I, "}")
    println(io, "  Subject: ", t.subject)
    println(io, "  Name: ", t.name)
    println(io, "  Conditions:")
    for c in conditions(t)
        print(io, "    ")
        println(io, repr(c.first), " => ", repr(c.second))
    end
    if isempty(sources(t))
        println(io, "  No sources")
    else
        println(io, "  Sources:")
        for p in sources(t)
            print(io, "    ")
            println(io, repr(p.first), " => ", repr(p.second))
        end
    end
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
    hassubject(trial, sub)

Test if the subject ID for `trial` is `sub`
"""
hassubject(trial::Trial, sub) = subject(trial) == sub

"""
    hassubject(sub)

Create a function that tests if a trial has the subject ID `sub`, i.e. a function equivalent
to `t -> hassubject(t, sub)`.
"""
hassubject(sub) = Base.Fix2(hassubject, sub)

"""
    hascondition(trial, condition...)
    hascondition(trial, (condition => value)...)

Test if `trial` has a condition. `value` can be a single level, multiple acceptable levels,
or a predicate function. Multiple conditions and/or condition pairs can be given which all
must be true to match.

# Examples

```jldoctest
julia> trial = Trial(1, "baseline", Dict(:group => "control", :session => 2))

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
hascondition(trial::Trial, cond::Symbol) = haskey(conditions(trial), cond)
hascondition(trial::Trial, cond::Pair{Symbol,T}) where T = (get(conditions(trial), cond.first, missing) == cond.second) === true
hascondition(trial::Trial, cond::Pair{Symbol,T}) where T <: Union{AbstractVector,Tuple} = (get(conditions(trial), cond.first, missing) ∈ cond.second) === true
hascondition(trial::Trial, cond::Pair{Symbol,T}) where T <: Function = cond.second(conditions(trial)[cond.first])
hascondition(trial::Trial, conds::Vararg{Pair{Symbol,T} where T <: Any}) = mapreduce(Base.Fix1(hascondition, trial), &, conds)
hascondition(trial::Trial, conds::NTuple{N, Pair{Symbol,T} where T <: Any}) where N = hascondition(trial, conds...)

"""
    hascondition((condition => value)...)

Create a function that tests if a trial has the given condition(s), i.e. a function equivalent to
`t -> hascondition(t, conditions...)`.

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
hascondition(conds::Vararg{Pair{Symbol,T} where T <: Any}) = Base.Fix2(hascondition, conds)

function renamecondition!(trial, (old, new)::Pair)
    @assert hascondition(trial, old)
    @assert !hascondition(trial, new)
    conditions(trial)[new] = conditions(trial)[old]
    delete!(conditions(trial), old)

    return nothing
end

function recodecondition!(trial, cond::Pair{Symbol,T}) where {T<:Base.Callable}
    @assert hascondition(trial, cond.first)
    f = cond.second
    if hasmethod(f, Tuple{Any,Any})
        conditions(trial)[cond.first] = f(trial, conditions(trial)[cond.first])
    else
        conditions(trial)[cond.first] = f(conditions(trial)[cond.first])
    end
end

function addcondition!(trial, cond::Pair{Symbol,T}) where {T<:Base.Callable}
    @assert !hascondition(trial, cond.first)
    f = cond.second
    c = f(trial)
    if !isnothing(c)
        conditions(trial)[cond.first] = c
    end
    return nothing
end

"""
    hassource(trial, src::String)
    hassource(trial, srctype::S) where {S<:AbstractSource}
    hassource(trial, src::Regex)

Check if `trial` has a source with key or type matching `src`.

# Examples
```jldoctest
julia> trial1 = Trial(1, "baseline", Dict(), Dict("model" => Source{Nothing}()));

julia> hassource(trial, "model")
true

julia> hassource(trial, Source{Nothing})
true

julia> hassource(trial, r"test*")
false
```
"""
hassource(trial::Trial, src::String) = haskey(sources(trial), src)
hassource(trial::Trial, src::Regex) = any(contains(src), keys(sources(trial)))
hassource(trial::Trial, src::S) where S <: AbstractSource = src ∈ values(sources(trial))
hassource(trial::Trial, ::Type{S}) where S <: AbstractSource = S ∈ typeof.(values(sources(trial)))

"""
    hassource(src)

Create a function that tests if a trial has the source `src`, i.e. a function equivalent
to `t -> hassource(t, src)`.

# Examples
```jldoctest
julia> trial1 = Trial(1, "baseline", Dict(), Dict("model" => Source{Nothing}()));

julia> trial2 = Trial(2, "baseline", Dict(), Dict());

julia> filter(hassource("model"), [trial1, trial2])
1-element Vector{Trial{Int64}}:
 Trial(1, "baseline", 0 conditions, 1 source)

"""
hassource(s) = Base.Fix2(hassource, s)

"""
    getsource(trial, name::String) -> Source
    getsource(trial, pattern::Regex) -> Vector{Source}
    getsource(trial, src::S) where {S<:AbstractSource} -> Source
    getsource(trial, name::String => src::Type{<:AbstractSource}) -> Source

Return a source from `trial` with the requested `name` or `src`. When the both `name`
and `src` are given as a pair, a source with `name` will be searched for first, and if
not found, a source of type `src` will be searched for.

If multiple sources of type `src` are present, the desired source must be accessed by
name/pattern only or an error will be thrown.
"""
getsource(trial::Trial, src::String) = sources(trial)[src]
getsource(trial::Trial, src::Regex) = getindex.(Ref(sources(trial)), filter(contains(src), keys(sources(trial))))
function getsource(trial::Trial, ::Type{S}) where S <: AbstractSource
    only(filter(v -> v isa S, collect(values(sources(trial)))))
end
function getsource(trial::Trial, srcpair::Pair{String,T}) where T
    name, src = srcpair
    return get(sources(trial), name, getsource(trial, src))
end

function readsource(trial::Trial, src; kwargs...)
    readsource(getsource(trial, src); kwargs...)
end

const red = Crayon(foreground=:black, background=1)
const green = Crayon(foreground=:black, background=2)
const lgry = Crayon(foreground=:light_gray)
const bold = Crayon(bold=true)
const rst = Crayon(reset=true)

function highlight_matches(str, m, conds)
    hstr = str
    BG_str = string(BOLD*GREEN_BG)
    rst_str = string(rst)

    BG_str_len = length(BG_str)
    rst_str_len = length(rst_str)

    ofst = 1
    for c in conds
        val = get(m, c, nothing)
        if !isnothing(val)
            _m = match(Regex(string(val)), hstr, ofst)
            hstr = string(@view(hstr[1:_m.offset-1]), BG_str, val, rst_str,
                @view(hstr[(_m.offset+length(val)):end]))
            ofst = _m.offset + BG_str_len + length(val) + rst_str_len
        end
    end

    return hstr
end

optionalparse(T, ::Nothing) = nothing
optionalparse(::Type{T}, x::T) where T = x
optionalparse(T, x::U) where {U} = T <: String ? String(x) : parse(T, x)

"""
    findtrials(subsets, conditions; <keyword arguments>) -> Vector{Trial}

Find all the trials matching `conditions` which can be found in `subsets`.

# Keyword arguments:

- `ignorefiles::Union{Nothing, Vector{String}}=nothing`: A list of files, given in the form
   of an absolute path, that are in any of the `subsets` folders which are to be ignored.
- `debug=false`: Show files that did not match (all) the required conditions
- `verbose=false`: Show files that *did* match all required conditions when `debug=true`
- `maxlogs=50`: Maximum number of files per subset to show when debugging

See also: [`Trial`](@ref), [`findtrials!`](@ref), [`DataSubset`](@ref), [`TrialConditions`](@ref)
"""
function findtrials(subsets::AbstractVector{DataSubset}, trialconds::TrialConditions; kwargs...)
    I = trialconds.types[:subject]
    findtrials!(Vector{Trial{I}}(), subsets, trialconds; kwargs...)
end

"""
    findtrials!(trials, subsets, conditions; <keyword arguments>)

Find more trials and/or find additional sources for existing trials.

For DataSubsets in `subsets` which are dependent, candidate source files must have the required conditions and have a "condition" matching the DataSubset name.

See also: [`findtrials`](@ref), [`Trial`](@ref), [`DataSubset`](@ref), [`TrialConditions`](@ref)
"""
function findtrials!(
    trials::Vector{Trial{I}},
    subsets::AbstractVector{DataSubset},
    trialconds::TrialConditions;
    ignorefiles::Union{Nothing, Vector{String}}=nothing,
    debug=false,
    verbose=false,
    maxlogs=50,
) where I
    requiredconds = filter(!=(:subject), trialconds.required)
    condnames_nosubject = filter(!=(:subject), trialconds.condnames)
    defaultconds = trialconds.defaults
    optionalconds = setdiff(condnames_nosubject, requiredconds, keys(defaultconds))
    if !isnothing(ignorefiles)
        ignorefiles .= normpath.(ignorefiles)
    end
    if debug
        pretty_subst = [ pat => SubstitutionString(string(red, "\\1", green, rep, rst, lgry))
            for (pat, rep) in trialconds.subst ]
    end

    for set in subsets
        debugheader, num_debugs = false, 0
        pattern = set.pattern
        files = normpath.(glob(pattern, set.dir))
        if !isnothing(ignorefiles)
            setdiff!(files, ignorefiles)
        end

        for file in files
            _file = replace(file, trialconds.subst...)
            slug, m = extract_conditions(_file, trialconds)

            if debug && num_debugs ≤ maxlogs
                if verbose || any(isnothing.(get(m, cond, nothing) for cond in [:subject; requiredconds]))

                    if !debugheader
                        debugheader = true
                        println(stderr, "┌ Subset ", repr(set.name))
                    end
                    pretty_file = replace(string(lgry, file, rst), pretty_subst...)*string(rst)

                    let io = IOBuffer(), ioc = IOContext(io, IOContext(stderr))
                        if isnothing(m)
                            println(ioc, "│ ╭ No match")
                        else
                            print(ioc, "│ ╭ Match: ")
                            print(ioc, '"', highlight_matches(slug, m, trialconds.condnames), '"')
                            if any(c -> !haskey(m, c), trialconds.condnames)
                                print(ioc, " (not found: ")
                                join(ioc, RED_FG.(string.(setdiff(trialconds.condnames, keys(m)))), ", ")
                                println(ioc, ')')
                            else
                                println(ioc)
                            end
                        end
                        println(ioc, "│ ╰ @ \"", pretty_file, '"')
                        print(stderr, String(take!(io)))
                    end
                    num_debugs += 1
                end
            end

            if any(isnothing.(get(m, cond, nothing) for cond in [:subject; requiredconds]))
                continue
            else
                sid = optionalparse(I, m[:subject])
                if set.dependent
                    if isnothing(get(m, Symbol(set.name), nothing))
                        continue
                    end
                    seenall = findall(trials) do trial
                        sid == subject(trial) &&
                        all(requiredconds) do cond
                            T = trialconds.types[cond]
                            actual = get(conditions(trial), cond, get(defaultconds, cond, nothing))
                            candidate = optionalparse(T, get(m, cond, get(defaultconds, cond, nothing)))

                            return actual == candidate
                        end
                    end
                else
                    seenall = findall(trials) do trial
                        sid == subject(trial) &&
                        all(condnames_nosubject) do cond
                            T = trialconds.types[cond]
                            actual = get(conditions(trial), cond, get(defaultconds, cond, nothing))
                            candidate = optionalparse(T, get(m, cond, get(defaultconds, cond, nothing)))

                            return actual == candidate
                        end
                    end
                end

                if isempty(seenall) && !set.dependent
                    name = splitext(basename(file))[1]
                    conds = Dict{Symbol,Any}()
                    foreach(requiredconds) do cond
                        T = trialconds.types[cond]
                        get!(() -> optionalparse(T, m[cond]), conds, cond)
                    end
                    foreach(defaultconds) do (k,v)
                        T = trialconds.types[k]
                        get!(() -> optionalparse(T, get(m, k, v)), conds, k)
                    end
                    foreach(optionalconds) do cond
                        T = trialconds.types[cond]
                        if !isnothing(get(m, cond, nothing))
                            get!(() -> optionalparse(T, m[cond]), conds, cond)
                        end
                    end
                    push!(trials, Trial(sid, name, conds,
                        Dict{String,AbstractSource}(set.name => set.source(file))))
                else
                    if set.dependent
                        _id=gensym(file)
                    else
                        @assert length(seenall) == 1
                    end

                    for seen in seenall
                        t = trials[seen]
                        if set.dependent
                            src_name = m[Symbol(set.name)]
                        else
                            src_name = set.name
                        end

                        if hassource(t, src_name)
                            if sourcepath(getsource(t, src_name)) == file
                                continue
                            end

                            if !@isdefined(_id)
                                _id=gensym(file)
                            end

                            let io = IOBuffer()
                                showerror(io, DuplicateSourceError(t, set,
                                    sourcepath(t.sources[src_name]), file))
                                @error String(take!(io)) _id=_id maxlog=1
                            end
                        else
                            t.sources[src_name] = set.source(file)
                        end
                    end
                end
            end
        end
        debugheader && println(stderr, "└ End subset: ", repr(set.name))
    end
    flush(stderr)

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
    threaded=(Threads.nthreads() > 1), enable_progress=true, show_errors=true
) where I where SRC <: AbstractSource
    srs = Vector{SegmentResult{SRC,I}}(undef, length(trials))
    p = Progress(length(trials)+1; output=stdout, enabled=enable_progress,
        desc="Analyzing trials... ")

    if threaded
        @qbthreads for i in eachindex(trials)
            local sr
            try
                sr = fun(trials[i])
            catch e
                if e isa InterruptException
                    break
                else
                    bt = catch_backtrace()
                    io = IOBuffer()
                    print(io, e)
                    Base.show_backtrace(IOContext(io, IOContext(stderr)), bt)
                    err = replace(String(take!(io)), "\n" => "\n│ ")
                    show_errors && @error trials[i] err
                    sr = SegmentResult(Segment(trials[i], SRC()))
                end
            end
            srs[i] = sr
            next!(p)
            flush(stdout)
            flush(stderr)
        end
    else
        for i in eachindex(trials)
            local sr
            try
                sr = fun(trials[i])
            catch e
                if e isa InterruptException
                    break
                else
                    bt = catch_backtrace()
                    io = IOBuffer()
                    print(io, e)
                    Base.show_backtrace(IOContext(io, IOContext(stderr)), bt)
                    err = replace(String(take!(io)), "\n" => "\n│ ")
                    show_errors && @error trials[i] err
                    sr = SegmentResult(Segment(trials[i], SRC()))
                end
            end
            srs[i] = sr
            next!(p)
            flush(stdout)
            flush(stderr)
        end
    end
    finish!(p)

    return srs
end

function default_rename(trial, source)
    srcname = srcname_default(source)
    return string("$(subject(trial))_$(srcname)_", basename(sourcepath(getsource(trial, source))))
end

"""
    export_trials([f,] trials, dir[, sources])

Export (copy) `sources` in `trials` to `outdir`. When left unspecified, `sources` is set to
all unique sources found in `trials`. Optionally can be given a function `f`, which must
accept 2 arguments (a trial and a src which is of `eltype(sources)`), to control the names of
the exported data. The default behavior exports all sources to `dir` with no
subdirectories, using the naming schema "\$trial.subject_\$srcname_\$basename(sourcepath)"
(pseudo-code).

# Examples

```julia-repl
julia> export_trials(trials, pwd()) do trial, source
    "\$(subject(trial))_\$(conditions(trial)[:group]).\$(srcext(source))"
end
```
"""
function export_trials(trials::Vector{<:Trial}, outdir, srcs=unique_sources(trials))
    export_trials(default_rename, trials, outdir, srcs)
end

function export_trials(rename, trials::Vector{<:Trial}, outdir, srcs=unique_sources(trials))
    isdir(outdir) || mkpath(outdir)
    # TODO: Generate and print/save code to read exported data (e.g. DataSubset's,
    # TrialConditions, etc)
    for trial in trials, src in srcs
        @debug "Copying $(sourcepath(getsource(trial, src))) to $(joinpath(outdir, rename(trial, src)))"
        exppath = joinpath(outdir, rename(trial, getsource(trial, src)))
        mkpath(dirname(exppath))
        cp(sourcepath(getsource(trial, src)), exppath; follow_symlinks=true)
    end
end

