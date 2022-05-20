# Julia Reference

## Sources

```@docs
AbstractSource
Source
readsource
sourcepath
requiresource!
generatesource
dependencies
DatasetManager.srcext
DatasetManager.srcname_default
```

## Trials

```@docs
DataSubset
TrialConditions
Trial
hassource
getsource
sources
findtrials
findtrials!
analyzedataset
export_trials
```

## Segments

```@docs
Segment
SegmentResult
readsegment
trial
subject
segment
source
conditions
results
resultsvariables
```

## Utilities

```@docs
summarize
DatasetManager.stack
```
