# Trials

A `Trial` is a [type [Julia]](../../julia-reference#DatasetManager.Trial) or [class
[MATLAB]](../../matlab-reference#Trial) that describes a single (temporal) instance of data
collected from a specific subject. `Trial`s are primarily descriptive, and do not contain
the data that was collected during the trial. `Trial`s record the (unique) subject
identifier, experimental conditions (or other relevant metadata, such as subject specific
characteristics), and they have have one or more `Source`s which refer to the files
containing the actual data collected during the trial.

```@raw html
<div class="admonition">
<summary class="admonition-header code-icon julia-icon">Julia</summary>
<div class="admonition-body" style="background-color:white">
```

```@setup trials
using DatasetManager
```

```@repl trials
trial1 = Trial(1, "baseline", Dict(:group => "control", :session => 2))
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
Trial('1', 'baseline', struct('group', 'Control', 'session', 2))
```
```
ans =

  Trial with properties:

       subject: '1'
          name: 'baseline'
    conditions: [1×1 struct]
       sources: [1×1 struct]
```

```@raw html
</div>
</div>
</p>
```

The descriptive nature of `Trial`s makes it easy to include or exclude trials for an
analysis based on conditions, etc. Various convenience functions have been defined for this
purpose: `hassubject`, `hascondition`, and `hassource`.

```@raw html
<div class="admonition">
<summary class="admonition-header code-icon julia-icon">Julia</summary>
<div class="admonition-body" style="background-color:white">
```

```@setup trials
using DatasetManager
```

```@repl trials
trials = [ Trial(id, "", Dict(:group => group, :week => week, :stimulus => stim))
    for id in 1:5
    for group in 'A':'B'
    for week in 1:4
    for stim in ("sham", "low", "high") ];
trials |> summary
trials[hascondition.(trials, :group => 'A')] |> summary
trials[hascondition.(trials, :group => 'A', :stimulus => ("low", "high"))] |> summary
filter(hassubject(3), trials) |> summary
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
trials = Trial.empty();
for id = 1:5
for group = ['A', 'B']
for week = 1:4
for stim = {'sham', 'low', 'high'}
trials(end+1) = Trial(num2str(id), '', struct('group', group, 'week', week, 'stim', stim));
end
end
end
end

% TODO Add hascondition examples
```

```@raw html
</div>
</div>
</p>
```






