```@meta
CurrentModule = DatasetManager
```

# DatasetManager

DatasetManager was designed to solve several common problems when working with new datasets
from human subjects research studies with the overall goal of reducing the amount of
boilerplate style code needed for new research.

**Issues**:

1. Most datasets have a unique heirarchy used to organize/structure how the data is stored
   on disk.

2. Every dataset will name trials and experimental conditions differently, based on the
   needs of the study and the preferences of the researcher.

3. Every trial may have more than one associated file which is a source of data for that
   trial. For example, if multiple systems were used to collect data, or data has undergone
   an intermediate stage of processing, but the original data is also needed in the final
   analysis.

4. Given a list of trials to be analysed, each trial will (should[^1]) be analysed
   identically (e.g. the same function will be run on every trial)

5. The entirety of a trial may not need to be analysed, but only a segment of the trial,
   such as if the first 10 s of a trial are ignored to avoid transient behavior related to
   the beginning of the trial, or if a trial refers to a timeseries which contains multiple
   different experimental conditions applied at different moments throughout the duration of
   the trial.

Issues 1 & 2 require writing a custom "harness" to find and interpret the naming of every
new dataset, which wastes valuable time the researcher could be spending developing analyses
or interpreting results.

Issue 3 can force code gymnastics to access the different source files needed to analyse a
trial, and requires specialized code to read sources which are of different file types, e.g.
`.csv`, `.c3d`, `.mat`.

Issue 4 requires the existence of the list of trials to be analysed.

Issue 5 is often managed in a hodge podge of ad-hoc code to strip the unneccesary portion of
the time series signals.

DatasetManager eases the analysis of a new dataset by allowing the researcher to describe
the dataset, including the organization heirarchy, naming schemes, and the locations of the
various sources of data. The core functionality of DatasetManager solves issues 1, 2 and 3,
by providing a function which will return a list of all the trials in a dataset when given
an appropriate description. Additionally, segments of a particular source for a given trial
can be described (solving issue 5), allowing a complete description of the metadata for the
data comprising a dataset.

A secondary functionality of DatasetManager is to solve issue 3 by providing two functions,
which can be extended to support reading various sources.

[^1]: Organizing analysis code into a single function promotes better code quality,
  organization and reuse, ensures that the results were all generated with the same code,
  and enables incremental or partial analyses (e.g. for testing, analysis of incomplete
  datasets, re-analysing problematic trials, etc)

