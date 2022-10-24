# Sources

A `Source` is a [type [Julia]](/julia-reference.html#DatasetManager.Source) or [class
[MATLAB]](/matlab-reference.html#Source) that refers to the location of a source of data
(typically a path to a file). DatasetManager normally assumes that sources contain
time-series data (e.g. in [`readsegment`](@ref), however this is not a requirement).

Datasets often have more than one kind of source (e.g. if multiple systems were
used to collect different kinds of data, such as EMG and motion capture). These different
kinds of data require special code to load them for analysis. Furthermore, even within the
same file extension (e.g. .csv), files can have different data organization (e.g. the number
of lines in the header, type of data in columns, etc) which require special handling. These
differences make using the file extension too inaccurate for choosing which function is
appropriate for reading a particular file.

By defining custom `readsource` functions
\[[Julia](/julia-reference.html#DatasetManager.readsource)/[MATLAB](/matlab-reference.html#Source.readsource)\], we can ensure that the data in any source can be correctly accessed using a single standard function.

## Example source definitions

[OpenSim](https://opensim.stanford.edu/) is an open-source software for neuromusculoskeletal modeling, simulation, and
analysis. Motion data is stored in tab-separated files with the extension
[`.mot`](https://simtk-confluence.stanford.edu:8443/display/OpenSim/Motion+%28.mot%29+Files).

```@raw html
<div class="admonition">
<summary class="admonition-header code-icon julia-icon">Julia</summary>
<div class="admonition-body" style="background-color:white">
```

We'll define a singleton type to dispatch on:

```julia
struct OSimMotion; end
```

and then define a `readsource` method for `Source{OSimMotion}`:

```julia
using CSV, DataFrames
function DatasetManager.readsource(src::Source{OSimMotion})
    data = CSV.File(sourcepath(src); header=11, delim='\t') |> DataFrame

    return data
end
```

```@raw html
</div>
</div>
</p>
```

```@raw html
<div class="admonition">
<summary class="admonition-header code-icon matlab-icon">MATLAB</summary>
<div class="admonition-body" style="background-color:white">
```

We'll define a class inheriting from the [Source](/matlab-reference.html#Source) class, and
use the OpenSim MATLAB bindings to read the motion file:

```matlab
classdef OSimMotion < Source
    methods
        function data = readsource(obj, varargin)
            import org.opensim.modeling.*
            % TimeSeriesTable from the OpenSim MATLAB bindings can read standard OpenSim
            % file types
            data = TimeSeriesTable(obj.path);
        end
    end
end
```

```@raw html
</div>
</div>
</p>
```

These are the minimal implementations needed to define a `Source` for reading OpenSim motion
files, and could be used like this:

```julia
readsource(Source{OSimMotion}("/path/to/mot"))
```

```matlab
readsource(OSimMotion('/path/to/mot'))
```

!!! info

    Theoretically, Sources do not need to be locally stored or individual files (e.g. a
    source could be stored in a database and could be defined to include a SQL query to retrieve the
    particular referenced data from the server). However at the time of writing, all
    datasets that have been used with DatasetManager have been locally stored in sources
    referring to separate, individual files.

### Adding a `readsegment` method

A `Segment` \[[Julia](/julia-reference.html#DatasetManager.Segment)/[MATLAB](/matlab-reference.html#Segment)\] refers to a segment of time in a time-series source. A `readsegment` method should be functionally equivalent to
`readsource(segment.source)[starttime:finishtime]`. Here is an example for our `OSimMotion` source:

```@raw html
<div class="admonition">
<summary class="admonition-header code-icon julia-icon">Julia</summary>
<div class="admonition-body" style="background-color:white">
```

```julia
function DatasetManager.readsegment(seg::Segment{Source{OSimMotion}})
    data = readsource(seg.source)
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

```@raw html
</div>
</div>
</p>
```

```@raw html
<div class="admonition">
<summary class="admonition-header code-icon matlab-icon">MATLAB</summary>
<div class="admonition-body" style="background-color:white">
```

```matlab
% define in methods of the classdef for OSimMotion
function data = readsegment(seg)
    data = readsource(seg.source);
    % the trimFrom function is a part of OpenSim's MATLAB bindings
    data.trimFrom(seg.start, seg.finish);
end
```

```@raw html
</div>
</div>
</p>
```

## Required sources and automatically generating sources

Sometimes a source can be generated from another source (or sources). This could be a simple
file conversion (e.g. `.c3d` to `.trc`), or something more involved, such as running inverse
kinematics in OpenSim. The [`requiresource!`](@ref)/[`requiresource`
[MATLAB]](/matlab-reference.html#Trial.requiresource) interface will check if a source
exists, and attempt to generate it if not, and throw an error if it is unable to generate
the source.

To support generating a source, a `dependencies` method
\[[Julia](/julia-reference.html#DatasetManager.dependencies)/[MATLAB](/matlab-reference.html#Source.dependencies)\]
must be defined to declare what other sources the source of interest depends on to be
generated.

```@raw html
<div class="admonition">
<summary class="admonition-header code-icon julia-icon">Julia</summary>
<div class="admonition-body" style="background-color:white">
```

Define the dependencies:

```julia
DatasetManager.dependencies(::Source{OSimMotion}) = (Source{OSimIKSetup},)
```

Then we define a `generatesource` method:

```julia
function DatasetManager.generatesource(trial, src::Source{OSimMotion}, deps)
    iksetup = getsource(trial, only(filter(x-> Source{OSimIKSetup} === x, deps)))
    run(`opensim-cmd run-tool $(sourcepath(iksetup))`)

    return src
end
```

```@raw html
</div>
</div>
</p>
```

```@raw html
<div class="admonition">
<summary class="admonition-header code-icon matlab-icon">MATLAB</summary>
<div class="admonition-body" style="background-color:white">
```

Define the dependencies:

```matlab
% define in methods of the classdef for OSimMotion
function deps = dependencies(obj)
    deps = {OSimIKSetup()};
end
```

Then we define a `generatesource` method:

```matlab
% define in methods of the classdef for OSimMotion
function src = generatesource(obj, trial, deps)
    status = system(['opensim-cmd run-tool ' sourcepath(obj)]);
    assert(status == 0)

    src = obj;
end
```

```@raw html
</div>
</div>
</p>
```

With those two methods now defined, the `requiresource!` function can be called, which will
generate the `OSimMotion` source if it is not already present:

```julia
requiresource!(trial, Source{OSimMotion})
```
```matlab
requiresource(trial, OSimMotion)
```

The preceding Julia/MATLAB examples are simplified for clarity. Complete working examples in
Julia and MATLAB for an OpenSim motion file source and other sources can be found at
[LabDataSources.jl](https://github.com/NantelBiomechLab/LabDataSources.jl) and
[LabDataSources](https://github.com/NantelBiomechLab/LabDataSources), respectively.



