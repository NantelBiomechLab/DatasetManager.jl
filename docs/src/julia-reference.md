# Julia Reference

## Trials

```@docs
TrialConditions
DataSubset
Trial
subject
conditions
sources
hassubject
hassource
hascondition
getsource
findtrials
findtrials!
analyzedataset
export_trials
```

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

## Segments

```@docs
Segment
SegmentResult
readsegment
trial
segment
source
results
resultsvariables
```

## Utilities

```@docs
summarize
DatasetManager.stack
write_results
```
