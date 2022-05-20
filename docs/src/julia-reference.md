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
```
