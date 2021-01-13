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

"""
    sourcepath(src) -> String

Return the absolute path to the `src`.
"""
sourcepath(src::S) where S <: AbstractSource = src.path

"""
    readsource(src::S; kwargs...) where {S <: AbstractSource}

Read the source data from storage.
"""
function readsource end
