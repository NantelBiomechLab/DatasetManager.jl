```@meta
CurrentModule = DatasetManager
```

# DatasetManager

DatasetManager was designed to solve several common problems when working with new datasets from human subjects research studies with the overall goal of reducing the amount of boilerplate style code needed for new research.

**Problems**:

1. Most datasets have a unique heirarchy used to organize/structure how the data is stored on disk.
2. Every dataset will name trials and experimental conditions differently, based on the needs of the study and the preferences of the researcher.
3. Every trial may have more than one associated file which is a source of data for that trial. For example, if multiple systems were used to collect data, or data has undergone an intermediate stage of processing, but the original data is also needed in the final analysis.
4. Given a list of trials to be analysed, each trial will (should[^1]) be analysed identically (e.g. the same function will be run on every trial)

Problems 1 & 2 require writing a custom "harness" to find and interpret the naming of every new dataset, which wastes valuable time the researcher could be spending developing analyses or interpreting results.

Problem 3 can force code gymnastics to access the different files needed to analyse a trial, and often requires specialized code to read the different files (which might be in different file types, e.g. `.csv`, `.c3d`, `.mat`).

Problem 4 requires the existence of the list of trials to be analysed.

DatasetManager eases the analysis of a new dataset by allowing the researcher to describe the dataset, including the organization heirarchy, naming schemes, and the locations of the various sources of data. The primary interface of DatasetManager, `findtrials` will then return a list of all the trials in a dataset.

[^1]: Organizing analysis code into a single function promotes better code quality, organization and reuse, ensures that the results were all generated with the same code, and enables incremental or partial analyses (e.g. for testing, analysis of incomplete datasets, re-analysing problematic trials, etc)

