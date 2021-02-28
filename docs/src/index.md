```@meta
CurrentModule = DatasetManager
```

# DatasetManager

DatasetManager was designed to solve several common problems when working with new datasets
from human subjects research studies with the overall goal of reducing the amount of
repetitive and custom code needed for new research.

The core functionality of DatasetManager eases the analysis of a new dataset by allowing the
researcher to describe the dataset (e.g. the locations of the various sources or data,
naming formats, etc) and then finding all the trials and associated metadata (e.g. subject
identifier, trial conditions) in the dataset. Additional functionality includes the ability
to define segments of the timeseries of a trial and attach experimental conditions specific
to those segments, and a user-extensible common interface for reading/loading different sources
of data using the correct method based on the type of data.

### Common issues solved by DatasetManager

- Most datasets have a unique organization and structure to how and where the data is stored
  on disk. Similarly, many datasets will use different naming schemes for trials and
  experimental conditions, based on the needs of the study and the preferences of the
  researcher. These unique aspects of each dataset require writing custom code to find and
  interpret the naming for every new dataset, which wastes valuable time the researcher
  could be spending developing analyses or interpreting results.
  - The `findtrials` function returns a list of every trial in the dataset when given a
    description of how and where the data is stored, paving the way for batch processing of
    the dataset.


- Datasets often have more than one source of data per trial (e.g. if multiple systems were
  used to collect different kinds of data, such as EMG and motion capture). These different
  kinds of data require special code to load them for analysis. Furthermore, even within the
  same file extension (e.g. `.csv`), files can have different data organization (e.g. the
  number of lines in the header); these differences make the use of file extension to choose
  the loading function a less than optimal solution for loading various kinds of data.
  - DatasetManager provides a simple interface where the researcher can specify the
    appropriate function for reading a particular type of data.


- Oftentimes, the entirety of a trial may not be needed, such as if the first part of a
  trial isn't used, or if a trial contains multiple different experimental conditions
  applied at different intervals throughout the duration of the trial.
  - `Segment`s describe the specific interval (the start time and end time) within a given
    trial and any experimental conditions specific to that interval of time.

### Limitations

The `findtrials` function currently requires all the desired trial metadata (e.g. subject
identifier, experimental conditions, etc) to be present in the absolute path of every trial.
The ability to find trial metadata in alternate formats or locations (e.g. trial metadata is
stored in separate files) is a feature we plan to add in the future.

Different sources are collated into a single trial when the subject identifier and all
experiemental conditions match. Duplicate trials (in terms of identical experimental
conditions and subject ID) are not currently supported.

Please open an [issue](https://github.com/NantelBiomechLab/DatasetManager.jl/issues/new) if
either of these limitations are a impediment to using DatasetManager.jl with your data, if
you have a request for a feature that would be a good fit for this package, or if you have
any issues using this package.

