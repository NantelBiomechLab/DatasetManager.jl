struct DataSubset
    name::String
    source::Type
    dir::String
    pattern::String

    function DataSubset(name, source::Type{S}, dir, pattern) where S <: AbstractSource
        return new(name, source, dir, pattern)
    end
end

struct TrialConditions
    condnames::Vector{Symbol}
    required::Vector{Symbol}
    labels_rg::Regex
    subst::Vector{Pair{Regex,String}}
    types::Vector{Type}
end

"""
    TrialConditions(conditions, labels; kwargs...) -> TrialConditions

- `conditions` is a collection of condition names (eg `(:medication, :strength)`)
- `labels` is a `Dict` with keys for each condition name (eg `haskey(labels, :medication)`). Each key gets a collection of the labels for all levels and any transformation desired for that condition.

# Keyword arguments

- `required`: The conditions which every trial must have (in the case of some trials having optional/additional conditions)
- `types`: The (Julia) types for each condition (eg `[String, Int]`)
- `sep`: The character separating condition labels
"""
function TrialConditions(
    conditions,
    labels;
    required=conditions,
    types=fill(String, length(conditions)),
    sep="[_-]"
)
    labels_rg = ""
    subst = Vector{Pair{Regex,String}}(undef, 0)

    for cond in conditions
        labels_rg *= "(?<$cond>"
        if labels[cond] isa Regex
            labels_rg *= labels[cond].pattern
        else
            labels_rg *= join((x isa Pair ? x.second : x for x in labels[cond]), '|')
        end
        optchar = cond in required ? "" : "?"
        labels_rg *= string(')', optchar, sep, '?')
        foreach(labels[cond]) do condlabel
            if condlabel isa Pair
                altlabels = condlabel.first isa Union{Symbol,String} ? [condlabel.first] : condlabel.first
                filter!(label -> label != condlabel.second, altlabels)
                push!(subst, Regex("(?:"*join(altlabels, '|')*")") => condlabel.second)
            end
        end
    end

    return TrialConditions(collect(conditions), collect(required), Regex(labels_rg), subst, types)
end

"""
    Trial{I}

A `Trial` describes the referenced trial. Trials are parameterized for
different locations to allow for dispatching by the Trial parameter.
"""
struct Trial{I}
    "The subject identifier"
    subject::I

    "The trial name"
    name::String

    "The source type of the `paths`"
    sources::Dict{String,<:AbstractSource}

    "The specific trial conditions; if unneeded, this can be empty"
    conds::Dict{Symbol,Any}
end

function Trial(subject::I, name, sources, conds) where I
    return Trial{I}(subject, name, sources, conds)
end

function Base.show(io::IO, t::Trial)
    print(io, "Trial(", repr(t.subject), ", ", repr(t.name), ", ")
    if length(t.sources) == 1
        print(io, t.sources, ", ", t.conds, ')')
    else
        print(io, length(t.sources), " sources, ", t.conds, ')')
    end
end

function Base.show(io::IO, ::MIME"text/plain", t::Trial{I}) where I
    println(io, "Trial{", I, "}")
    println(io, "  Subject: ", t.subject)
    println(io, "  Name: ", t.name)
    print(io, "  Sources:")
    for p in t.sources
        print(io, "\n    ")
        print(io, repr(p.first), " => ", repr(p.second))
    end
    print(io, "\n  Conditions:")
    for c in t.conds
        print(io, "\n    ")
        print(io, repr(c.first), " => ", repr(c.second))
    end
    println(io)
end

function Base.isequal(x::Trial{I}, y::Trial{T}) where {I,T}
    return I == T && x.subject == y.subject && x.name == y.name && x.conds == y.conds
end

function Base.hash(x::Trial{I}, h::UInt) where I
    h = hash(x.subject, h)
    h = hash(x.name, h)
    h = hash(x.conds, h)
    return h
end

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

function Base.show(io::IO, e::DuplicateSourceError)
    numfolders = count(r"[/\\]", string(e.datasubset.pattern))
    _original = joinpath("…", splitpath(e.original)[(end-numfolders):end]...)

    duplicatesourceerror_show(io, e.trial, e.datasubset, _original, repr(e.dup))
end

# function Base.show(io::IO, ::MIME"text/html", e::DuplicateSourceError)
#     numfolders = count(r"[/\\]", string(e.datasubset.pattern))
#     _dup = joinpath("…", splitpath(e.dup)[(end-numfolders):end]...)
#     _original = joinpath("…", splitpath(e.original)[(end-numfolders):end]...)
#
#     duplicatesourceerror_show(io, trial, datasubset,
#         "<a href=\"file:///$e.original\">$_original</a>",
#         "<a href=\"file:///$e.dup\">$_dup</a>")
# end

function duplicatesourceerror_show(io, trial, datasubset, original, dup)
    print(io, "DuplicateSourceError: ")
    print(io, "Found file ", dup, " which matches ", trial)
    print(io, " that already contains a matching file ", original)
    print(io, " for ", datasubset)
end


function findtrials(
    subsets::AbstractVector{DataSubset},
    conditions::TrialConditions;
    I::Type=Int,
    subject_fmt=r"(?<=Subject )(?<subject>\d+)",
    ignorefiles::Union{Nothing, Vector{String}}=nothing,
    defaultconds::Union{Nothing, Dict{Symbol}}=nothing
)
    trials = Vector{Trial{I}}()
    rg = subject_fmt*r".*"*conditions.labels_rg
    reqcondnames = conditions.required
    optcondnames = setdiff(conditions.condnames, reqcondnames)
    _defaultconds = Dict(cond => nothing for cond in conditions.condnames)
    if !isnothing(defaultconds)
        _defaultconds = merge(_defaultconds, defaultconds)
    end
    AllSources = Union{(set.source for set in subsets)...}

    for set in subsets
        pattern = set.pattern
        files = glob(pattern, set.dir)
        if !isnothing(ignorefiles)
            setdiff!(files, ignorefiles)
        end

        for file in files
            _file = foldl((str, pat) -> replace(str, pat), conditions.subst; init=file)
            m = match(rg, _file)
            isnothing(m) && continue

            if isnothing(m[:subject]) || any(isnothing.(m[cond] for cond in reqcondnames))
                continue
            else
                name = splitext(basename(file))[1]
                sid = !(I <: String) ? parse(I, m[:subject]) : String(m[:subject])
                seenall = findall(trials) do trial
                    trial.subject == sid &&
                    all(enumerate(conditions.condnames)) do (i, cond)
                        trialcond = get(trial.conds, cond, _defaultconds[cond])
                        if isnothing(m[cond])
                            return isnothing(trialcond)
                        elseif conditions.types[i] === String
                            return m[cond] == trialcond
                        else
                            parse(conditions.types[i], m[cond]) == trialcond
                        end
                    end
                end

                if isempty(seenall)
                    conds = Dict(cond => String(m[cond]) for cond in reqcondnames)
                    foreach(enumerate(optcondnames)) do (i, cond)
                        if !isnothing(m[cond])
                            if conditions.types[i] === String
                                conds[cond] = String(m[cond])
                            else
                                conds[cond] = parse(conditions.types[i], m[cond])
                            end
                        end
                    end
                    push!(trials, Trial(sid, name,
                        Dict{String,AllSources}(set.name => set.source(file)), conds))
                else
                    seen = only(seenall)
                    t = trials[seen]
                    if haskey(t.sources, set.name)
                        throw(DuplicateSourceError(t, set, path(t.sources[set.name]), file))
                    else
                        t.sources[set.name] = set.source(file)
                    end
                end
            end
        end
    end

    return trials
end
