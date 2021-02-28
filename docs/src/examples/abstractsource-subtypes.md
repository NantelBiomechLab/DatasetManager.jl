# Using `AbstractSource` subtypes

!!! warning "Warning: Sources and MATLAB"

    This feature has not been implemented yet in MATLAB.

The multiple different sources of data for any single trial might all have different file formats. In such a case, different code will be needed to read each file format. Two function stubs, `readsource` and `readsegment`, are defined for `AbstractSource` subtypes to implement methods appropriate for the source.

We will construct an example module that will fully implement the `AbstractSource` API.

First, we define the type:

```julia
struct DFlowSource <: AbstractSource
    path::String
end
```

and then we provide a `readsource` method. This source is a csv text file, so we will use TextParse.jl to read it in Julia.

```julia
function DatasetManager.readsource(s::DFlowSource; kwargs...)
    Textparse.csvread(sourcepath(s); skiplines_begin=2, header_exists=false, kwargs...)
end
```

Finally, the `readsegment` method should produce a result equivalent to `readsource(seg.source)[start:finish]`. Here is the appropriate method for `DFlowSource`:

```julia
function DatasetManager.readsegment(seg::Segment{DFlowSource}; kwargs...)
    columns, colnames = readsource(seg.source; kwargs...)
    firsttime = first(columns[timecol])
    lasttime = last(columns[timecol])

    if isnothing(seg.finish)
        _finish = lasttime
    else
        _finish = seg.finish
    end

    firsttime ≤ seg.start ≤ lasttime || throw(error("$s start time $(seg.start) is not within"*
        "the source time range of $firsttime:$lasttime"))
    firsttime ≤ _finish ≤ lasttime || throw(error("$s finish time $(seg.finish) is not within "*
        "the source time range of $firsttime:$lasttime"))

    startidx = searchsortedfirst(columns[timecol], firsttime)

    if isnothing(seg.finish)
        finidx = lastindex(columns[timecol])
    else
        finidx = searchsortedlast(columns[timecol], seg.finish)
    end

    segcolumns = ntuple(i -> columns[i][startidx:finidx], length(columns))

    return segcolumns, colnames
end
```

```@raw html
<div class="admonition">
<details>
<summary class="admonition-header">Complete example <code>DFlow</code> module</summary>
```

```julia
module DFlow

using DatasetManager, TextParse

export DFlowSource

struct DFlowSource <: AbstractSource
    path::String
end

function DatasetManager.readsource(s::DFlowSource; kwargs...)
    csvread(sourcepath(s); skiplines_begin=2, header_exists=false, kwargs...)
end

function DatasetManager.readsegment(seg::Segment{DFlowSource}; kwargs...)
    columns, colnames = readsource(seg.source; kwargs...)
    firsttime = first(columns[timecol])
    lasttime = last(columns[timecol])

    if isnothing(seg.finish)
        _finish = lasttime
    else
        _finish = seg.finish
    end

    firsttime ≤ seg.start ≤ lasttime || throw(error("$s start time $(seg.start) is not within"*
        "the source time range of $firsttime:$lasttime"))
    firsttime ≤ _finish ≤ lasttime || throw(error("$s finish time $(seg.finish) is not within "*
        "the source time range of $firsttime:$lasttime"))

    startidx = searchsortedfirst(columns[timecol], firsttime)

    if isnothing(seg.finish)
        finidx = lastindex(columns[timecol])
    else
        finidx = searchsortedlast(columns[timecol], seg.finish)

    end
    segcolumns = ntuple(i -> columns[i][startidx:finidx], length(columns))

    return segcolumns, colnames
end

end
```

```@raw html
</details>
</div>
</p>
```

