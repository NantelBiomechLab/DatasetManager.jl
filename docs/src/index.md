```@meta
CurrentModule = DatasetManager
```

# DatasetManager

Find your data, summarize high-level characteristics, analyze it, and collect the results for statistical testing!

```@setup simplefakedata
using DatasetManager, DataFrames, CSV
include(joinpath(pkgdir(DatasetManager), "test", "makedata.jl"))
gensimpledata()
datadir = relpath(joinpath(pkgdir(DatasetManager), "test/data/simple"))
struct GaitEvents; end
subsets = [ DataSubset("events", Source{GaitEvents}, datadir, "*.csv") ]
conds = TrialConditions((:session,:stim), Dict(:session => r"\d", :stim => ["stim", "placebo"]);
    subject_fmt=r"ID(?<subject>\d+)", types=Dict(:session => Int, :stim => String))
ENV["LINES"] = 17
```

```@repl simplefakedata
using DatasetManager, DataFrames, CSV, Statistics
trials = findtrials(subsets, conds;
    ignorefiles=[joinpath(datadir, "ID4_3_stim-02.csv")]);
summarize(trials)
analysis_results = analyzedataset(trials, Source{GaitEvents}) do trial
    events = CSV.File(sourcepath(getsource(trial, "events"))) |> DataFrame
    res = SegmentResult(Segment(trial, "events"))
    results(res)["avg_stride"] = mean(diff(events[!, "RHS"]))

    return res
end;
df = DatasetManager.stack(analysis_results, conds)
```

DatasetManager was designed to solve several common problems when working with new datasets
from human subjects research studies with the overall goal of reducing the amount of
repetitive and custom code needed for new research by providing a flexible framework that
can work with many different datasets.

The core functionality of DatasetManager eases the analysis of a new dataset by allowing the
researcher to describe the dataset (e.g. the locations of the various sources or data,
naming formats, etc) and then finding all the trials and associated metadata (e.g. subject
identifier, trial conditions) in the dataset. Additional functionality includes the ability
to define segments of the timeseries of a trial and attach experimental conditions specific
to those segments, and a user-extensible common interface for reading/loading different
sources of data using the correct method based on the type of data.

### Key functionality

- The `findtrials` function returns a list of every trial in the dataset when given a
  description of how and where the data is stored, paving the way for batch processing of
  the dataset.
  - Most datasets have a unique organization and structure to how and where the data is
    stored on disk. Similarly, many datasets will use different naming schemes for trials
    and experimental conditions, based on the needs of the study and the preferences of the
    researcher. These unique aspects of each dataset normally require writing custom code to
    find and interpret the naming for every new dataset, which wastes valuable time the
    researcher could be spending developing analyses or interpreting results.

- Data `Source`s allow the researcher to define a standard function for reading (and even
  generating/transforming) a particular type of data (e.g. a file type/extension, or a
  specifically formatted `.csv`, etc).
  - Datasets often have more than one source of data per trial (e.g. if multiple systems
    were used to collect different kinds of data, such as EMG and motion capture). These
    different kinds of data require special code to load them for analysis. Furthermore,
    even within the same file extension (e.g. `.csv`), files can have different data
    organization (e.g. the number of lines in the header) which would benefit from special
    handling; these differences can challenge the use of file extension as the basis for
    choosing which function is appropriate for reading a particular file.

- `Segment`s describe a specific interval (the start time and end time) within a given
  trial and any experimental conditions specific to that interval of time.
  - Oftentimes, the entirety of a trial may not be needed, such as if the first part of a
    trial isn't used, or if a trial contains multiple different experimental conditions
    applied at different intervals throughout the duration of the trial.

- The `analyzedataset` function will batch process (with multiple threads if available) all
  trials or segments using any given analysis function.

- Collect analysis results and all trial metadata (subject ID's, conditions, etc) into a
  `DataFrame` using [`DatasetManager.stack`](@ref)[^1]

### Limitations

The `findtrials` function currently requires all the desired trial metadata (e.g. subject
identifier, experimental conditions, etc) to be present in the absolute path of every trial.
The ability to find trial metadata in alternate formats or locations (e.g. trial metadata is
stored in separate files) is a feature we plan to add in the future.

Different sources are collated into a single trial when the subject identifier and all
experiemental conditions match. Duplicate trials (in terms of identical experimental
conditions and subject ID with no other distinguishing elements) are not currently
supported.

Please open an [issue](https://github.com/NantelBiomechLab/DatasetManager.jl/issues/new) if
you have a request for a feature that would be a good fit for this package, or if you have
any issues using this package.

[^1]: `DatasetManager.stack` is not exported due to a naming conflict with the `stack` function in `DataFrames.jl`.

