# TrialConditions

A `TrialConditions` is a [type
[Julia]](../../../julia-reference/#DatasetManager.TrialConditions) or [class
[MATLAB]](../../../matlab-reference/#TrialConditions) that describes the names and possible
values for the experimental conditions (aka factors) and other characteristics (e.g. subject
ID, etc) which are needed to describe and recognize multiple sources as being
associated with a single, unique `Trial`.

A correctly specified `TrialConditions` allows the `findtrials` function to search
`DataSubset`s for suitable sources and match/group them into a `Trial`. Datasets may have
a complex design and a complex
organization (including typos, inconsistent naming of the same level in a condition, etc).
Therefore `TrialConditions` is designed to be capable of describing such complexity.

!!! tip "Terms"

    **condition**:

    1. The name of an experimental condition or factor

    **label**:

    1. A value of a condition, aka a level of a factor

    Example: `"control"` is a valid label for the condition "*group*"

!!! compat "Current Assumptions/Limitations"

    - All conditions (needed to uniquely describe a trial) are present in the absolute path of a
      source
    - Conditions have a consistent order (e.g. condition *session* is always after *group*)


The simplest datasets can be described by listing all valid labels for each condition. This might look like:

```@raw html
<div class="admonition">
<summary class="admonition-header code-icon julia-icon">Julia</summary>
<div class="admonition-body" style="background-color:white">
```

```@setup conditions
using DatasetManager
```

```@repl conditions
labels = Dict(
    :subject => ["1", "2", "3", "4", "5"],
    :arms => ["held", "norm", "active"]
);
conds = TrialConditions((:subject,:arms), labels);
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
labels.subject(1).to = '1';
labels.subject(2).to = '2';
labels.subject(3).to = '3';
labels.subject(4).to = '4';
labels.subject(5).to = '5';
labels.arms(1).to = 'held';
labels.arms(2).to = 'norm';
labels.arms(3).to = 'active';

conds = TrialConditions.generate({'subject','arms'}, labels);
```

```@raw html
</div>
</div>
</p>
```

But many datasets aren't that simple or organized so perfectly. Suppose some trials had capitalized first letters for the arms conditions. The original `labels` would not match, and those trials would be ignored. We can explicitly add capitalized options:

```@raw html
<div class="admonition">
<summary class="admonition-header code-icon julia-icon">Julia</summary>
<div class="admonition-body" style="background-color:white">
```

```@repl conditions
labels = Dict(
    :subject => ["1", "2", "3", "4", "5"],
    :arms => ["Held" => "held", "Norm" => "norm", "Active" => "active"]
);
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
labels.subject(1).to = '1';
labels.subject(2).to = '2';
labels.subject(3).to = '3';
labels.subject(4).to = '4';
labels.subject(5).to = '5';
labels.arms(1).from = 'Held';
labels.arms(1).to = 'held';
labels.arms(2).from = 'Norm';
labels.arms(2).to = 'norm';
labels.arms(3).from = 'Active';
labels.arms(3).to = 'active';
```

```@raw html
</div>
</div>
</p>
```

We now are matching all hypothetical trials. However, the capitalized conditions will not be recognized as the same actual levels as the corresponding lowercase levels. One solution is to define conversions for non-canonical (e.g. capitalized, known typos, etc) levels.

```@raw html
<div class="admonition">
<summary class="admonition-header code-icon julia-icon">Julia</summary>
<div class="admonition-body" style="background-color:white">
```

```@repl conditions
labels = Dict(
    :subject => ["1", "2", "3", "4", "5"],
    :arms => ["Held" => "held", "Norm" => "norm", "Active" => "active"]
);
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
labels.subject(1).to = '1';
labels.subject(2).to = '2';
labels.subject(3).to = '3';
labels.subject(4).to = '4';
labels.subject(5).to = '5';
labels.arms(1).from = 'Held';
labels.arms(1).to = 'held';
labels.arms(2).from = 'Norm';
labels.arms(2).to = 'norm';
labels.arms(3).from = 'Active';
labels.arms(3).to = 'active';
```

```@raw html
</div>
</div>
</p>
```

Now all the capitalized conditions will be converted to lowercase.

## Advanced definitions

In some cases, explicitly listing all the possible labels is untenable. In these cases, the
`labels` in `TrialConditions` can use regexes, and functions which modify strings (Julia only), in addition to arrays of strings, to identify all conditions/labels and improve the consistency of label naming.

Some examples (multiple equivalent alternatives presented in green):

```@raw html
<div class="admonition">
<summary class="admonition-header code-icon julia-icon">Julia</summary>
<div class="admonition-body" style="background-color:white">
```

```diff
labels = Dict(
-     :subject => ["1", "2", "3", "4", "5"],
+     :subject => r"\d",

-     :arms => ["Held" => "held", "Norm" => "norm", "Active" => "active"],
+     :arms => [r"held"i, r"norm"i, r"active"i] => lowercase,
+     :arms => r"(held|norm|active)"i => lowercase,
);
```

In the example for `:arms`, the `'i'` after the closing double quote signals that the regex
is case-insensitive. By itself, this would lead to the earlier discussed problem of matching
both the lowercase and capitalized labels, and would produce mismatched labels. The pair `=>` syntax should be read as "convert to/with", so the matches by the regex are given as arguments to the `lowercase` function with the function output being added as an `:arms` condition to any trials, instead of the direct match from the regex. See [`TrialConditions`](@ref) for more details.

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


```diff
- labels.subject(1).to = '1';
+ labels.subject(1).to = '\d';
```

Regexes could be used for the `arms` label, but the MATLAB version doesn't currently support
using functions to transform regex matches. If the use of regexes is needed or desired, it
would be possible to normalize mismatched labels after running `findtrials`.

```@raw html
</div>
</div>
</p>
```



