# Data Subsets

A `DataSubset` is a [type [Julia]](../../julia-reference#DatasetManager.DataSubset) or
[class [MATLAB]](../../matlab-reference#DataSubset) that describes a group of sources of a
single kind of `Source` in a dataset.

A dataset can have multiple different kinds of sources, which may be located and/or
organized in different manners (e.g. due to being created with different software or on
different systems). So we use the term `DataSubset` to refer to these subsets of a
dataset.

In simple cases, the files in a `DataSubset` might be all of the files within a single
directory, e.g. `/data/events/`. However, in many cases, the files may be organized with a
more complex structure, involving multiple folders and subfolders. For these situations,
a [glob](https://en.wikipedia.org/wiki/Glob_(programming)) is used to specify the
locations and files/filetypes that are a part of the subset. For example, instead of
including all the files in a folder, `/data/events/`, a specific filetype can be specified:
`/data/events/*.csv`

## Examples

```@raw html
<div class="admonition">
<summary class="admonition-header code-icon julia-icon">Julia</summary>
<div class="admonition-body" style="background-color:white">
```

```@setup subsets
using DatasetManager
struct Events; end
struct C3DFile; end
```

This is an example of a `DataSubset` named `"events"` of `Source{Events}`. Note the
[wildcard](https://en.wikipedia.org/wiki/Glob_(programming)#Syntax) after `"Subject"`, which
will match any text (e.g. `"Subject 12/events/..."` or `"Subject 13_BAD/events/..."`).

```@repl subsets
DataSubset("events", Source{Events}, "/path/to/subset", "Subject */events/*.tsv")
```

Alternately, the following is slightly more specific because the wildcard after `"Subject"`
is limited to the characters `0` through `9`.

```@repl subsets
DataSubset("events", Source{Events}, "/path/to/subset", "Subject [0-9]*/events/*.tsv")
```
In some cases, a more specific glob may be necessary or preferable to exclude certain
folders/files, due to the organization of sources, or for performance (if the more specific
glob matches significantly fewer files), however in many cases, a simpler, less specific
glob will be perfectly acceptable.

The folder given as the third argument should be the deepest, non-glob containing (e.g. `*`,
etc) path. Globs in the third argument will cause errors, and a shallower path split (e.g.
`"/path/to/"`, `"subset/Subject */events/*.tsv"` vs `"/path/to/subset/"`, `"Subject
*/events/*.tsv"`) may be noticeably slower (due to searching more files and folders).

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

The source type for `DataSubset`s in MATLAB is prefixed with an ampersand (`@`) to denote that
we are referring to the class itself, not an instance of the class. More info
[here](https://www.mathworks.com/help/matlab/ref/function_handle.html?s_tid=doc_ta) and
[here](https://www.mathworks.com/help/matlab/matlab_prog/pass-a-function-to-another-function.html).

```matlab
DataSubset('events', @EventsSource, '/path/to/subset/Subject */events/*.tsv')
```

Globbing support is different in MATLAB, and the complete path, including globs, is given as
a single string; additionally, only asterisk globs are supported in MATLAB. More info
[here](https://www.mathworks.com/help/matlab/ref/dir.html#bup_1_c-2).

```@raw html
</div>
</div>
</p>
```

## Dependent subsets

(The following refers to concepts which haven't been introduced yet. Read [Trials](../trials) and
[TrialConditions](../trialconditions) for background information.)

Some sources described by a `DataSubset` may not be relevant as standalone/independent
Trials (e.g. maximal voluntary contraction "trials", when collecting EMG data, are typically
only relevant to movement trials for that specific subject/session of a data collection, but
are may not be useful on their own).

When `findtrials` is called with a dependent `DataSubset`, sources will only be added to pre-existing trials and no new trials will be created solely for a dependent source. Dependent sources are only added to trials when the required conditions for the dependent `DataSubset` match the corresponding conditions in the trials.

```@raw html
<div class="admonition">
<summary class="admonition-header code-icon julia-icon">Julia</summary>
<div class="admonition-body" style="background-color:white">
```

```@repl subsets
labels = Dict(
    :subject => r"(?<=Patient )\\d+",
    :session => r"(?<=Session )\\d+",
    :mvic => r"mvic_[rl](bic|tric)", # Defines possible source names for MVIC "trials"
);
conds = TrialConditions((:subject,:session,:mvic), labels;
    required=(:subject,:session,));
subsets = [
    DataSubset("mvic", Source{C3DFile}, "/path/to/c3d", "Subject */Session */*.c3d";
        dependent=true)
];
```

The pattern for the `:mvic` "condition" would match any of `["mvic_rbic", "mvic_lbic",
"mvic_rtric", "mvic_ltric"]`.

The dependent `"mvic"` subset has the `:subject` and `:session` conditions set as required,
so only sources (that match the `:mvic` pattern) with matching `:subject` and `:session`
will be added to a given trial. For example, a source with a filename of `"Subject 3/Session
2/mvic_rbic.c3d"` would be recognized as having conditions `(:subject => 3, :session => 2,
:mvic => "mvic_rbic")` and would be added as a source to any trial(s)
with conditions  `(:subject => 3, :session => 2)`.

!!! warning "Dependent source names"

    Note that the names of dependent sources are determined differently than regular
    sources. While regular sources are given the name of the `DataSubset` they originate
    from (e.g. `"mvic"`), this would cause `DuplicateSourceError`s if multiple (and unique)
    dependent sources were needed for a `Trial`. Instead, dependent sources are named using
    the (value of the) "condition" which matches the `DataSubset` name. Using the above
    example, the `"mvic"` subset looks for a "condition" with the same name (e.g. `:mvic`),
    and the source name is set to the value of the matched condition: `"mvic_rbic"`.

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

\[Not implemented yet\]

```@raw html
</div>
</div>
</p>
```

