# MATLAB Reference

## Trials

```@raw html
<article class="docstring">
    <header>
        <a id="DataSubset" class="docstring-binding" href="#DataSubset"><code>DataSubset</code></a>
         — 
        <span class="docstring-category">Class</span>
    </header>
    <section>
        <div>
```
```matlab
DataSubset(name, source, pattern)
```

Describes a subset of data, where files found in and matching `pattern`
(using [glob syntax](https://www.mathworks.com/help/matlab/ref/dir.html#bup_1_c-2')) are
all of the same `AbstractSource` subclass.

```@raw html
        </div>
        <a class="docs-sourcelink" target="_blank" href="https://github.com/NantelBiomechLab/DatasetManager.jl/master/docs/src/matlab-reference.md#LL11-L28">source</a>
    </section>
</article>
```

```@raw html
<article class="docstring">
    <header>
        <a id="TrialConditions" class="docstring-binding" href="#TrialConditions"><code>TrialConditions</code></a>
         — 
        <span class="docstring-category">Class</span>
    </header>
    <section>
        <div>
```
```matlab
TrialConditions
```

Describes the experimental conditions and the labels for levels within each condition.

```@raw html
        </div>
        <a class="docs-sourcelink" target="_blank" href="https://github.com/NantelBiomechLab/DatasetManager.jl/master/docs/src/matlab-reference.md#LL11-L28">source</a>
    </section>
</article>
```

```@raw html
<article class="docstring">
    <header>
        <a id="TrialConditions.generate" class="docstring-binding" href="#TrialConditions.generate"><code>TrialConditions.generate</code></a>
         — 
        <span class="docstring-category">Function</span>
    </header>
    <section>
        <div>
```

```matlab
TrialConditions.generate(conditions, labels, <optional arguments>)
```

Generates a `TrialConditions`.

**Arguments**

- `conditions` is a cell array of condition names (eg `{'medication', 'strength'}`)
- `labels` is a struct with a field for each condition name (eg `isfield(labels, 'medication')`).
  Each condition field must have `to` and `from` fields which contain the final names and all the name possibilities, respectively.
  The `from` field is is optional if the terminology in the filenames is the desired terminology.

**Optional arguments**

- `'Required'` (defaults to all conditions): The conditions which every trial must have (in the case of some
  trials having optional/additional conditions).
- `'Separator'` (defaults to `'[_-]'`): The character separating condition labels

```@raw html
        </div>
        <a class="docs-sourcelink" target="_blank" href="https://github.com/NantelBiomechLab/DatasetManager.jl/master/docs/src/matlab-reference.md#LL11-L28">source</a>
    </section>
</article>
```

```@raw html
<article class="docstring">
    <header>
        <a id="Trial" class="docstring-binding" href="#Trial"><code>Trial</code></a>
         — 
        <span class="docstring-category">Class</span>
    </header>
    <section>
        <div>
```
```matlab
Trial(subject, name, conditions, sources)
```

Describes a single trial, including a reference to the subject, trial name, trial
conditions, and relevant sources of data.

```@raw html
        </div>
        <a class="docs-sourcelink" target="_blank" href="https://github.com/NantelBiomechLab/DatasetManager.jl/master/docs/src/matlab-reference.md#LL11-L28">source</a>
    </section>
</article>
```

```@raw html
<article class="docstring">
    <header>
        <a id="Trial.findtrials" class="docstring-binding" href="#Trial.findtrials"><code>Trial.findtrials</code></a>
         — 
        <span class="docstring-category">Class</span>
    </header>
    <section>
        <div>
```
```matlab
Trial.findtrials(subsets, conditions, <optional arguments>)
```

Find all the trials matching `conditions` which can be found in `subsets`.

**Optional arguments:**

- `'SubjectFormat'`(default is `"(?<=Subject )(?<subject>\\d+)"`): The format (in Regex) that the subject identifier
    will appear in file paths.
- `IgnoreFiles` (default is empty): A cell array of absolute file paths that are in any of the `subsets` folders which are to be ignored.
- `DefaultConditions` (default are none): Any conditions which should be set to a default
    level if the condition is not found in the file path.

```@raw html
        </div>
        <a class="docs-sourcelink" target="_blank" href="https://github.com/NantelBiomechLab/DatasetManager.jl/master/docs/src/matlab-reference.md#LL11-L28">source</a>
    </section>
</article>
```

```@raw html
<article class="docstring">
    <header>
        <a id="name" class="docstring-binding" href="#name"><code>name</code></a>
         — 
        <span class="docstring-category">Class</span>
    </header>
    <section>
        <div>
```
```matlab
```

```@raw html
        </div>
        <a class="docs-sourcelink" target="_blank" href="https://github.com/NantelBiomechLab/DatasetManager.jl/master/docs/src/matlab-reference.md#LL11-L28">source</a>
    </section>
</article>
```

