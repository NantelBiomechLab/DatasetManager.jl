"""
    AbstractSource

The abstract supertype for custom data sources. Implement a subtype of `AbstractSource` if
`Source{S}` is not sufficient for your source requirements (e.g. your source has additional
information besides the path, such as encoding parameters, compression indicator, etc, that
needs to be associated with each instance).

# Extended help

All subtypes of `AbstractSource` **must**:

- have a `path` field or extend the `sourcepath` function.
- accept a single string, the absolute path of the source file, in the constructor.

Minimum method definitions necessary for complete functionality of a subtype of
`AbstractSource` (i.e. `Source{S}` or otherwise):
- [`readsource`](@ref)
- [`sourcepath`](@ref) (if defining a new subtype of `AbstractSource`)

Additional methods to improve user experience and/or additional functionality
- [`readsegment`](@ref)
- [`generatesource`](@ref) (if enabling `requiresource!` generation)
- [`dependencies`](@ref) (if defining a `generatesource` method)
- [`srcext`](@ref)
- [`srcname_default`](@ref)

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

"""
    Source{S}(path)

A basic source, where `S` can be any singleton or existing type
"""
struct Source{S} <: AbstractSource
    path::String
end

Source{S}() where S = Source{S}(tempname()*srcext(Source{S}))

"""
    sourcepath(src) -> String

Return the absolute path to the `src`.
"""
sourcepath(src::AbstractSource) = src.path::String

"""
    srcext(src::Union{S,Type{S}})

    Actual file extension or default file extension for a `src` or `src` type. Period (.) should be the first letter.
"""
srcext(src::AbstractSource) = splitext(sourcepath(src))[2]
srcext(::Type{<:AbstractSource}) = ""

"""
    readsource(src::S; kwargs...) where {S <: AbstractSource}

Read the source data from file.
"""
function readsource end

struct UnknownDeps end

"""
    dependencies(src::Union{S,Type{S}})

Get the sources that `src` depends on to be generated by `generatesource`.
"""
dependencies(::S) where S <: AbstractSource = dependencies(S)
dependencies(::Type{<:AbstractSource}) = UnknownDeps()

"Default name for a source in `Trial.sources`"
srcname_default(::S) where S <: AbstractSource = srcname_default(S)
srcname_default(s) = string(s)

struct MissingSourceError <: Exception
    msg::String
end

function Base.showerror(io::IO, e::MissingSourceError)
    print(io, "MissingSourceError: ")
    print(io, e.msg)
end

"""
    requiresource!(trial, src::Union{S,Type{S}}; force=false, deps, kwargs...) -> nothing
    requiresource!(trial, name::String => src::Union{S,Type{S}}; force=false, deps, kwargs...)

Require a source `src` in `trial`, generate `src` if not present, or throw an error if `src`
is not present and cannot be generated. Returns `nothing`. Keyword argument `deps` defaults to
`dependencies(src)`, but can be manually specified as a `name => src::AbstractSource` pair
per dependency if there exist multiple sources that would match a dependent source type.
`kwargs...` are passed on to the `generatesource` function for `src`.

# Keyword arguments
- `force=false`: Force generating `src`, even if it already exists
- `deps=dependencies(src)`: Manually specify particular dependencies

# Examples
```julia
julia> dependencies(Source{Events})
(Source{C3DFile},)

julia> requiresource!(trial, Source{Events})

julia> requiresource!(trial, Source{Events}; force=true, deps=("mainc3d" => Source{C3DFile}))

```
"""
function requiresource!(trial, src::AbstractSource, parent=nothing; kwargs...)
    requiresource!(trial, srcname_default(src) => src, parent; kwargs...)
end

function requiresource!(trial, src::Type{<:AbstractSource}, parent=nothing; kwargs...)
    requiresource!(trial, srcname_default(src) => src(), parent; kwargs...)
end

function requiresource!(trial, name::Regex)
    requiresource!(trial, name => Source{Nothing}(""), nothing; force=false, deps=UnknownDeps())
end

function requiresource!(trial, namesrc::Pair, parent=nothing;
    force=false, deps=dependencies(namesrc.second), kwargs...
)
    name, src = namesrc
    if !force
        if (parent !== nothing && hassource(trial, typeof(src))) ||
            hassource(trial, name) || hassource(trial, src)
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

"""
    generatesource(trial, src::Union{S,Type{S}}, deps; kwargs...) where S <: AbstractSource -> newsrc::typeof(src)

Generate source `src` using dependent sources `deps` from `trial`. Returns a source of the same
type as `src`, but is not required to be exactly equal to `src` (i.e. a different
`sourcepath(newsrc)` is acceptable).
"""
function generatesource end

generatesource(trial, ::Type{S}, deps; kwargs...) where S <: AbstractSource =
    generatesource(trial, S(), deps; kwargs...)

