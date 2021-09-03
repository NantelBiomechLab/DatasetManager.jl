# Working with sources

!!! warning "Warning: Sources and MATLAB"

    This feature has not been implemented yet in MATLAB.

A single trial will likely have multiple files which contain data associated with that trial.
In such a case, different code will most likely be needed to read each file (e.g. due to
different file types or formatting).

A simple implementation of a source for an OpenSim `.mot` file follows:

The default `Source` type is sufficient for this example. We create a

```julia
struct OpenSimMOT; end
```

and then we provide a `readsource` method. This source is a csv text file, so we will use TextParse.jl to read it in Julia.

```julia
using CSV, DataFrames
function DatasetManager.readsource(src::Source{OpenSimMOT}; kwargs...)
    data = CSV.File(sourcepath(src); header=11, delim='\t', kwargs...) |> DataFrame

    return data
end
```

This is the minimal implementation needed to define a new `Source`. However, there are some
additional methods which can be convenient to define.

## Adding a `readsegment` method

A `readsegment` method should return a semantically equivalent result to
`readsource(seg.source)[start:finish]`. Here is a method for our `OpenSimMOT` source:

```julia
function DatasetManager.readsegment(seg::Segment{OSimMotion}; kwargs...)
    data = readsource(seg.source; kwargs...)
    if !isnothing(seg.start)
        starti = searchsortedfirst(data[!, "time"], seg.start)
    else
        starti = firstindex(data, 1)
    end

    if !isnothing(seg.finish)
        lasti = searchsortedlast(data[!, "time"], seg.finish)
    else
        lasti = lastindex(data, 1)
    end

    return data[starti:lasti, :]
end
```

## Automatically generating sources

Sometimes a source can be generated from another source (or sources). This could be a simple file
conversion (e.g. `.c3d` to `.trc`), or something more involved, such as running inverse
kinematics in OpenSim.

To support generating a source, a `DatasetManager.dependencies` method must be defined to
declare what other sources must be present in order to generate the source of interest.

```julia
struct TRC; end
DatasetManager.dependencies(::Source{TRC}) = (Source{C3DFile},)
```

Then, a `DatasetManager.generatesource` method must be defined which performs the source
generation.

```julia
function DatasetManager.generatesource(trial, src::Source{TRC}, deps)
    writetrc(sourcepath(src), readsource(trial, Source{C3DFile}))
end
```

With those two methods now defined, the `requiresource!` function can be called, which will
generate the `TRC` source if it is not already present, and add it to the `trial.sources`:

```julia
requiresource!(trial, Source{TRC})

# Re-generate the `TRC` source, even if one already exists
requiresource!(trial, Source{TRC}; force=true)

# Override the default dependencies and use a specific `Source{C3DFile}`
# This would only work if the `generatesource` function was designed to allow such an
# override
requiresource!(trial, Source{TRC}; deps=("imu-c3d",))
```

Examples of more complex sources (`readsource`, `generatesource`, etc) can be found at
[LabDataSources.jl](https://github.com/NantelBiomechLab/LabDataSources.jl).

