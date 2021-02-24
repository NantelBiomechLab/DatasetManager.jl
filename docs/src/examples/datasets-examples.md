# Describing datasets

Below are two examples of datasets with different organizations and issues which demonstrate the capabilities of DatasetManager.

## Well organized dataset with minimal issues

Consider a dataset organized as follows:

```
📂 genpath
├ 📂 Visual3D
│ ├ 📂 Subject 1
│ │ ├ 📂 export
│ │ │ └ 📂 park
│ │ │   ├ park-none.mat
│ │ │   ├ park-norm.mat
│ │ │   └ park-excess.mat
│ │ └ 📂 import
│ ├ 📂 Subject 2
│ ┊
│
└ 📂 DFlow
  ├ 📂 Subject 1
  │ ├ park-none.csv
  │ ├ park-norm.csv
  │ ├ park-excess.csv
  │ ┊
  ├ 📂 Subject 2
  ┊

📂 rawpath
├ 📂 Subject 1
│ └ 📂 _
│   ├ park-none.c3d
│   ├ park-norm.c3d
│   ├ park-excess.c3d
│   ┊
├ 📂 Subject 2
┊
```

The dataset is organized into 3 separate folders, but all the trials use the same naming
scheme between the different folders. Therefore, we can group the data into 3 different data
subsets (`genpath/Visual3D`, `genpath/DFlow`, and `rawpath`) for this analysis based on
their location and filetype. Each `DataSubset` gets a name, a source type, a parent
directory, and a [glob](https://en.wikipedia.org/wiki/Glob_(programming)) which describes
the structure and location, and possibly more (eg extension), of the files specified by the
`DataSubset`.

```@raw html
<div class="admonition">
<details open="">
<summary class="admonition-header code-icon julia-icon">Julia code</summary>
```

```julia
genpath = "path/to/one/subset"
dflowpath = "path/to/another/subset"

parksubsets = [
    DataSubset("visual3d", V3DExportSource, joinpath(genpath, "Visual3D"), "Subject [0-9]*/export/park/park-*.mat"),
    DataSubset("dflow", DFlowSource, joinpath(genpath, "DFlow"), "Subject [0-9]*/park-*.csv"),
    DataSubset("vicon", C3DSource, rawpath, "Subject [0-9]*/_/park-*.c3d")
]
```

```@raw html
</details>
</div>
</p>
```

```@raw html
<div class="admonition">
<details>
<summary class="admonition-header code-icon matlab-icon">MATLAB code</summary>
```

```matlab
genpath = 'path/to/one/subset'
dflowpath = 'path/to/another/subset'

parksubsets = [
    DataSubset('visual3d', 'V3DExportSource', fullfile(genpath, 'Visual3D/Subject */export/park/park-*.mat')),
    DataSubset('dflow', 'DFlowSource', fullfile(genpath, 'DFlow/Subject */park-*.csv')),
    DataSubset('vicon', 'C3DSource', fullfile(rawpath, 'Subject */_/park-*.c3d'))
]
```

```@raw html
</p>
<div class="admonition-body">
```

!!! info

    The MATLAB globbing syntax only supports asterisks. More info
    [here](https://www.mathworks.com/help/matlab/ref/dir.html#bup_1_c-2).

```@raw html
</div>
</details>
</div>
</p>
```

This dataset only has one condition (aka 'factor' in statistical contexts) with three levels.
The dataset was created with different terms for 2 of the levels, and we also wish to improve the naming of some of the levels. Any trial with `"none"` in the path will be recognized as a
`"held"` trial. If a trial happens to already have the new terminology (`"held"`), it will be recognized as a `"held"` trial. The `"norm"`
condition is left unchanged, and will only match trials with `"norm"` in the path.

```@raw html
<div class="admonition">
<details open="">
<summary class="admonition-header code-icon julia-icon">Julia code</summary>
```

```julia
levels = Dict(:arms => ["none" => "held", "norm", "excess" => "active"])
parkconds = TrialConditions((:arms,), levels)
```

```@raw html
</details>
</div>
</p>
```

```@raw html
<div class="admonition">
<details>
<summary class="admonition-header code-icon matlab-icon">MATLAB code</summary>
```

```matlab
levels.arms(1).from = 'none'
levels.arms(1).to = 'held'
levels.arms(2).to = 'norm'
levels.arms(3).from = 'excess'
levels.arms(3).to = 'active'

parkconds = TrialConditions.generate({'arms'}, levels)
% alternately:
parkconds = TrialConditions.generate(fieldnames(levels), levels)
```

```@raw html
</details>
</div>
</p>
```

The `findtrials` function will search every `DataSubset` for trials which match the `TrialConditions`:

```@raw html
<div class="admonition">
<details open="">
<summary class="admonition-header code-icon julia-icon">Julia code</summary>
```

```julia
# Read all perturbations
parktrials = findtrials(parksubsets, parkconds)
```

```@raw html
</details>
</div>
</p>
```

```@raw html
<div class="admonition">
<details>
<summary class="admonition-header code-icon matlab-icon">MATLAB code</summary>
```

```matlab
parktrials = DataSet.findtrials(parksubsets, parkconds)
```

```@raw html
</details>
</div>
</p>
```

!!! tip "Dealing with duplicate or unwanted files"

    In some cases, there are duplicate (e.g. a trial was redone due to technical
    difficulties, etc) or unwanted (e.g. corrupted data, etc) files that will match the same
    set of conditions in a particular `DataSubset`, and the `findtrials` function will be
    unable to determine which file should be used for that `DataSubset` source. Suppose the
    first of attempt for a trial, `"Subject 01/_/park-norm.c3d"` had an issue, and it was
    repeated with a `'-02'` added after the trial name (`"Subject 01/_/park-norm-02.c3d"`).

    ```julia-repl
    julia> parktrials = findtrials(parksubsets, parkconds)

    ERROR: DuplicateSourceError: Found "vicon" source file "…/Subject 01/_/park-norm-02.c3d" for
     Trial(1, "park-norm", Dict{Symbol,Any}(:arms => "norm"), 3 sources) which already has
     a "vicon" source at "…/Subject 01/_/park-norm.c3d"
    Stacktrace:
     [1] findtrials(::Array{DataSubset,1}, ::TrialConditions; I::Type{T} where T, subject_fmt::Regex, ignorefiles::Array{String,1}, defaultconds::Nothing) at /home/user/.julia/dev/DatasetManager/src/trial.jl:232
     [2] top-level scope at REPL[7]:1
    ```

    This `DuplicateSourceError` alerts you that, for `Trial(1, "park-norm",
    Dict{Symbol,Any}(:arms => "norm"))` there are conflicting files for the `"vicon"`
    source, and gives you the names of the two files.  The solution is to add any duplicate
    or unwanted files to the `ignorefiles` keyword argument (or the `'IgnoreFiles'` optional
    argument in MATLAB).

    **Julia:**
    ```julia
    # Read all perturbations
    parktrials = findtrials(parksubsets, parkconds; ignorefiles=[
        joinpath(rawpath, "Subject 01/_/park-norm-01.c3d")
    ])
    ```

    **MATLAB:**
    ```matlab
    parktrials = DataSet.findtrials(parksubsets, parkconds, 'IgnoreFiles', { ...
        fullfile(rawpath, 'Subject 01/_/park-norm-01.c3d')
    })
    ```



## Dataset with different naming schemes

Consider a different dataset, organized as follows:

```
📂 v3dpath
├ 📂 Subject 1
│ ├ 📂 Export
│ │ ├ 20181204_1400_NORMS_TR03.mat
│ │ ├ 20181204_1400_NONEC_TR03.mat
│ │ ├ 20181204_1400_NORMC_TR03.mat
│ │ ┊
│ └ 📂 import
├ 📂 Subject 2
│ └ 📂 Export
│   ├ norm-singletask.mat
│   ├ held-dualtask.mat
│   ├ norm_dual.mat
│   ┊
┊

📂 dflowpath
├ 📂 N01
│ ├ 20181204_1400_1448_AS_BA_NP_N01_TR01.txt
│ ├ 20181204_1400_1501_NA_CO_NP_N01_TR01.txt
│ ├ 20181204_1400_1506_AS_CO_NP_N01_TR01.txt
│ ┊
┊
```

This analysis only needs 2 `DataSubsets`:

```@raw html
<div class="admonition">
<details open="">
<summary class="admonition-header code-icon julia-icon">Julia code</summary>
```

```julia
v3dpath = "path/to/one/subset"
dflowpath = "path/to/another/subset"

parkdatafiles = [
    DataSubset("visual3d", V3DExportSource, v3dpath, "Subject [0-9]*/Export/*.mat"),
    DataSubset("dflow", RawDFlowPDSource, dflowpath, "N[0-9]*/*.txt")
]
```

```@raw html
</details>
</div>
</p>
```

```@raw html
<div class="admonition">
<details>
<summary class="admonition-header code-icon matlab-icon">MATLAB code</summary>
```

```matlab
v3dpath = 'path/to/one/subset'
dflowpath = 'path/to/another/subset'

parkdatafiles = [
    DataSubset('visual3d', 'V3DExportSource', fullfile(v3dpath, 'Subject */Export/*.mat')),
    DataSubset('dflow', 'RawDFlowPDSource', fullfile(dflowpath, 'N*/*.txt'))
]
```

```@raw html
</details>
</div>
</p>
```

This dataset has several issues which make the level filters more complex and require the use of [Regex](https://en.wikipedia.org/wiki/Regular_expression) to properly find the conditions.

- The `"visual3d"` subset isn't completely consistent in the naming. For example `"Norm"` was sometimes used instead of `"norm"`, and `"dual"` was sometimes used instead of `"dualtask"`.
- The `"dflow"` subset used a completely different trial naming scheme. `"NA"` was used instead of `"held"`, `"RT"` instead of `"rtrip"`, etc.

Such conversions can be dealt with simply. However, a more difficult issue is that the `"singletask"` condition in the `"dflow"` subset is denoted by an "S" following the "arms" factor. Just matching an "S" could match the "S" in "Subject", or in the "RS" condition. We need to only match an "S" that follows the "arms" factor, which can be specified by a [positive lookbehind group](https://en.wikipedia.org/wiki/Perl_Compatible_Regular_Expressions#Features) in Regex,
like so `"(?<=NONE|NORM)S"`. A similar Regex can be used to deal with the "C" for "dualtask".

Additionally, you may not the `"(?<=_)TR(?=_)"` for the "park" condition. This was necessary because the `"dflow"` subset naming scheme separately contained "TR" for *every* trial. This regex requires the presence of underscores on either side of "TR" for it to match.

```@raw html
<div class="admonition">
<details open="">
<summary class="admonition-header code-icon julia-icon">Julia code</summary>
```

```julia
labels = Dict(:arms => [ ["NONE", "NA"] => "held", ["AS", "Norm", "NORM"] => "norm"],
                 :kind => [ ["(?<=NONE|NORM|held|norm)S", "BA", "single"] => "singletask", ["(?<=NONE|NORM|norm|held)C", "CO", "dual"]=> "dualtask",
                           "PO" => "pert", "CP" => "dualtask", ["PARK", "(?<=_)TR(?=_)"] => "park" ],
                 :pert_type => ["NP" => "steadystate", "RT" => "rtrip", "RS" => "rslip",
                                "LT" => "ltrip", "LS" => "lslip"])
conds = TrialConditions((:arms,:kind,:pert_type), labels; required=(:arms,:kind))
```

```@raw html
</details>
</div>
</p>
```

```@raw html
<div class="admonition">
<details>
<summary class="admonition-header code-icon matlab-icon">MATLAB code</summary>
```

```matlab
labels.arms(1).from = {'NONE', 'NA'};
labels.arms(1).to = 'held';
labels.arms(2).from = {'AS', 'Norm', 'NORM'};
labels.arms(2).to = 'norm';

labels.kind(1).from = {'(?<=NONE|NORM|held|norm)S', 'BA', 'single'};
labels.kind(1).to = 'singletask';
labels.kind(2).from = {'(?<=NONE|NORM|norm|held)C', 'CO', 'dual'};
labels.kind(2).to = 'dualtask';
labels.kind(3).from = 'PO';
labels.kind(3).to = 'pert';
labels.kind(4).from = 'CP' ;
labels.kind(4).to = 'dualtask';
labels.kind(5).from = {'park', '(?<=_)TR(?=_)'};
labels.kind(5).to = 'park' ;

labels.pert_type(1).from = 'NP';
labels.pert_type(1).to = 'steadystate';
labels.pert_type(2).from = 'RT';
labels.pert_type(2).to = 'rtrip';
labels.pert_type(3).from = 'RS';
labels.pert_type(3).to = 'rslip';
labels.pert_type(4).from = 'LT';
labels.pert_type(4).to = 'ltrip';
labels.pert_type(5).from = 'LS';
labels.pert_type(5).to = 'lslip';

conds = TrialConditions.generate({'arms','kind','pert_type'}, labels, 'Required', {'arms', 'kind'})
```

```@raw html
</details>
</div>
</p>
```

!!! note

    These `TrialConditions` also include the optional factor of `:pert_type`. When the `required` keyword arg is not specified, it is assumed that all factors are required. In this case, the `"visual3d"` subset only included a `:pert_type` level for trials that included a perturbation.

As always, the `findtrials` function will locate trials and sources within each subset which match the given conditions.

```@raw html
<div class="admonition">
<details open="">
<summary class="admonition-header code-icon julia-icon">Julia code</summary>
```

```julia
# Read all perturbations
parktrials = findtrials(parkdatafiles, conds;
    subject_fmt=r"(?<=Subject |N)(?<subject>\d+)", ignorefiles=[
        joinpath(dflowpath, "N02/20181206_1500_1554_NA_BA_NP_N02_TR01.txt"),
        joinpath(dflowpath, "N02/20181206_1500_1657_AS_CP_RT_N02_TR01.txt"),
        ⋮
        joinpath(dflowpath, "N020/20190509_1000_1113_NA_CP_RS_N020_TR01.txt"),
        joinpath(dflowpath, "N020/20190509_1000_1153_AS_PO_LT_N020_TR01.txt")
    ], defaultconds=Dict(:pert_type => "steadystate"))
```

```@raw html
</details>
</div>
</p>
```

```@raw html
<div class="admonition">
<details>
<summary class="admonition-header code-icon matlab-icon">MATLAB code</summary>
```

```matlab
% Read all perturbations
parktrials = DataSet.findtrials(parkdatafiles, conds, ...
    'SubjectFormat', '(?<=Subject |N)(?<subject>\d+)', 'IgnoreFiles', { ...
        fullfile(dflowpath, 'N02/20181206_1500_1554_NA_BA_NP_N02_TR01.txt'), ...
        fullfile(dflowpath, 'N02/20181206_1500_1657_AS_CP_RT_N02_TR01.txt'), ...
        ⋮
        fullfile(dflowpath, 'N020/20190509_1000_1113_NA_CP_RS_N020_TR01.txt'), ...
        fullfile(dflowpath, 'N020/20190509_1000_1153_AS_PO_LT_N020_TR01.txt') ...
    }, 'DefaultConditions', containers.Map('pert_type', 'steadystate'))
```

```@raw html
</details>
</div>
</p>
```

!!! tip "Keyword arg: `subject_fmt` (`'SubjectFormat'` in MATLAB)"

    The `subject_fmt` Regex has been modified here to match the subject id between the different naming schemes of the two `DataSubsets`.

!!! tip "Keyword arg: `defaultconds` (`'DefaultConditions'` in MATLAB)"

    The `defaultconds` Dict can be particularly useful when some conditions are optional, and therefore may not exist in the file path, but are needed or desired in the `Trial`s.

