"""
    AbstractSource

In recognition that data sources vary, and the mechanism of reading trials will differ
between data sources, implement a subtype of AbstractSource for your data.

# Example:

```julia
struct MySource <: AbstractSource
    path::String
end

DatasetManager.readsource(src::MySource) = customreadfunc(sourcepath(src))
DatasetManager.readsegment(seg::Segment{MySource}) = readsource(seg.source)[start:finish]
```
"""
abstract type AbstractSource end

sourcepath(src::S) where S <: AbstractSource = src.path

"""
    readsource(src::S; kwargs...) where {S <: AbstractSource}

Implement this function for reading your `AbstractSource` subtype.
"""
function readsource end
