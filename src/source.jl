"""
    AbstractSource

The abstract supertype for custom data sources. Implement a subtype of `AbstractSource` to
enable loading your data while benefitting from multiple-dispatch.

# Extended help

All subtypes of `AbstractSource` **must**:

- have a `path` field or extend the `sourcepath` function.
- accept a single string, the absolute path of the source file, in the constructor.

## Example

```julia
struct MySource <: AbstractSource
    path::String
end

DatasetManager.readsource(src::MySource) = customreadfunc(sourcepath(src))
DatasetManager.readsegment(seg::Segment{MySource}) = readsource(seg.source)[start:finish]
```
"""
abstract type AbstractSource end

(::Type{S})() where S <: AbstractSource = S(tempname()*srcext(S))

struct Source{S} <: AbstractSource
    path::String
end

Source{S}() where S = Source{S}(tempname()*srcext(Source{S}))

"""
    sourcepath(src) -> String

Return the absolute path to the `src`.
"""
sourcepath(src::S) where S <: AbstractSource = src.path

srcext(src::S) where S <: AbstractSource = splitext(sourcepath(src))[2]
srcext(::Type{<:AbstractSource}) = ""

"""
    readsource(src::S; kwargs...) where {S <: AbstractSource}

Read the source data from storage.
"""
function readsource end

struct UnknownDeps end
dependencies(::S) where S <: AbstractSource = dependencies(S)
dependencies(::Type{<:AbstractSource}) = UnknownDeps()

srcname_default(::S) where S <: AbstractSource = srcname_default(S)
srcname_default(s) = string(s)

struct MissingSourceError <: Exception
    msg::String
end

function Base.showerror(io::IO, e::MissingSourceError)
    print(io, "MissingSourceError: ")
    print(io, e.msg)
end

function requiresource!(trial, src::S, parent=nothing; kwargs...) where S <: AbstractSource
    requiresource!(trial, srcname_default(src) => src, parent; kwargs...)
end

function requiresource!(trial, src::Type{<:AbstractSource}, parent=nothing; kwargs...)
    requiresource!(trial, srcname_default(src) => src(), parent; kwargs...)
end

function requiresource!(trial, namesrc::Pair, parent=nothing;
    force=false, deps=dependencies(namesrc.second), kwargs...
)
    name, src = namesrc
    if !force
        if hassource(trial, name) || hassource(trial, src) ||
            (parent !== nothing && hassource(trial, typeof(src)))
            return nothing
        elseif isfile(sourcepath(src))
            sources(trial)[name] = src
            return nothing
        end
    end

    if deps isa UnknownDeps
        throw(MissingSourceError("unable to generate missing source $src for $trial"))
    else
        foreach(deps) do reqsrc
            requiresource!(trial, reqsrc, src; force=false)
        end
    end
    _src = generatesource(trial, src, deps; kwargs...)
    isfile(sourcepath(_src)) ||
        throw(MissingSourceError("failed to generate source $name => $_src for $trial"))

    sources(trial)[name] = _src

    return nothing
end

function generatesource end

generatesource(trial, ::Type{S}, deps; kwargs...) where S <: AbstractSource =
    generatesource(trial, S(), deps; kwargs...)

