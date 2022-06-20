classdef Trial < handle
    % TRIAL  Characterizes a single instance of data collected from a specific `subject`.
    % The Trial has a `name`, and may have on or more `conditions` which describe
    % experimental conditions and/or subject specific charateristics which are relevant to
    % subsequent analyses. A Trial may have one or more complementary `sources` of data
    % (e.g. simultaneous recordings from separate equipment stored in separate files,
    % supplementary data for a primary data source, etc).
    %
    %   trial = Trial(subject, name, conditions, sources)
    %
    % # Input arguments
    %
    % - `subject`: The unique identifier (ID) char vector of the subject/participant in the trial
    % - `name`: The trial name (a char vector)
    % - `conditions`: A struct containing a field for every condition
    % - `sources`: A struct containing a field for every source
    %
    % # Examples
    %
    % ```matlab
    % trial = Trial('1', 'baseline', struct('group', 'control', 'session', 2), struct())
    % ```

    properties
        subject(1,:) char
        name(1,:) char
        conditions
        sources
    end

    methods
        function obj = Trial(subject, name, conditions, sources)
            if nargin > 0
                obj.subject = subject;
                obj.name = name;
                obj.sources = sources;
                obj.conditions = conditions;
            end
        end

        function bl = isequal(obj, y)
            bl = strcmp({obj.subject}, {y.subject}) & strcmp({obj.name}, {y.name}) & ...
                arrayfun(@isequal, repmat(obj.conditions, 1, length(y)), [y.conditions]);
        end

        function bl = equiv(obj, y)
            bl = strcmp({obj.subject}, {y.subject}) & ...
                arrayfun(@isequal, repmat(obj.conditions, 1, length(y)), [y.conditions]);
        end

        function bool = hassource(trial, src)
            bool = false(size(trial));

            if isa(src, 'Source')
                bool = bool | reshape(cellfun(@(s) any(structfun(@(x) x == src, s)), {trial.sources}), size(trial));
            elseif ischar(src)
                if exist(src, 'class') == 8
                    bool = bool | reshape(cellfun(@(s) any(structfun(@(x) isa(x, src), s)), {trial.sources}), size(trial));
                else
                    bool = bool | reshape(cellfun(@(s) isfield(s, src), {trial.sources}), size(trial));
                end
            end
        end

        function src = getsource(trial, arg1, arg2)
            if nargin == 2
                if isa(arg1, 'char')
                    src = trial.sources.(arg1);
                elseif isa(arg1, 'Source')
                    bool = structfun(@(x) isa(x, class(arg1)), trial.sources);
                    if sum(bool) > 1
                        error('multiple sources of type %s in trial', class(arg1))
                    elseif sum(bool) == 0
                        error('no sources of type %s in trial', class(arg1))
                    end
                    srcs = struct2cell(trial.sources);
                    src = srcs(bool);
                    src = src{1};
                else
                    error('second argument must be a char array or a Source')
                end
            elseif nargin == 3
                if isfield(trial.sources, arg1)
                    src = trial.sources.(arg1);
                else
                    bool = structfun(@(x) isa(x, class(arg2)), trial.sources);
                    if sum(bool) > 1
                        error('multiple sources of type %s in trial', class(arg2))
                    elseif sum(bool) == 0
                        error('no sources of type %s in trial', class(arg2))
                    end
                    srcs = struct2cell(trial.sources);
                    src = srcs(bool);
                    src = src{1};
                end
            end
        end

        function requiresource(trial, src, varargin)
            % REQUIRESOURCE  Require a source to exist for a trial, attempt to generate the
            % source if missing and possible to generate.
            %
            %   requiresource(trial, src)
            %   requiresource(trial, src, Name, Value)
            %

            p = inputParser;
            p.KeepUnmatched = true;
            addRequired(p, 'trial', @(x) isa(x, 'Trial'));
            addRequired(p, 'src', @(x) isa(x, 'Source'));
            addOptional(p, 'parent', false, @islogical);
            addParameter(p, 'Name', srcname_default(src), @ischar);
            addParameter(p, 'Force', false, @islogical);
            addParameter(p, 'Dependencies', dependencies(src));

            parse(p, trial, src, varargin{:});
            parent = p.Results.parent;
            name = p.Results.Name;
            force = p.Results.Force;
            deps = p.Results.Dependencies;

            if ~force
                if (~parent && hassource(trial, class(src))) || hassource(trial, name) || hassource(trial, src)
                    return
                elseif isfile(src.path)
                    trial.sources.(name) = src
                    return
                end
            end

            % TODO: Decide if `false` is an acceptable design choice (in lieu of the Julia
            % version's `UnknownDeps`
            if islogical(deps) && deps == false
                trialstr = evalc('display(trial)');
                srcstr = evalc('display(src)');
                error('unable to generate missing source %s\nfor %s', srcstr(12:end-1), trialstr(14:end-2))
            else
                for i = 1:length(deps)
                    requiresource(trial, deps{i}, true, 'Force', false);
                end
            end

            new_src = generatesource(src, trial, deps, p.Unmatched);
            if ~isfile(new_src.path)
                trialstr = evalc('display(trial)');
                srcstr = evalc('display(new_src)');
                error('unable to generate missing source %s\nfor %s', srcstr(15:end-1), trialstr(14:end-2))
            end

            trial.sources.(name) = new_src;
        end
    end

methods(Static)
    function trials = findtrials(subsets, conditions, varargin)
        % FINDTRIALS  Find all the trials matching `conditions` which can be found in `subsets`.
        %
        %   trials = findtrials(subsets, conditions)
        %   trials = findtrials(subsets, conditions, Name, Value)
        %
        % # Input arguments
        %
        % - `subsets`: The `DataSubset`s to use when finding sources
        % - `conditions`: The `TrialConditions` for these sources/trials
        %
        % # Name-Value arguments:
        %
        % - `'SubjectFormat'`: The regex pattern used to match the trial's subject ID.
        %   (defaults to 'Subject (?<subject>\d+)'`).
        % - `'IgnoreFiles'`: A list of files to ignore that are in any of the `subsets`, given in the form
        %     of an absolute path.
        % - `'DefaultConditions'`: Default conditions to set when a given condition is not
        %   matched. Defaults can be given for required conditions. If a condition is not
        %   required, has no default, and is not matched, it will not be included as a
        %   condition for a source.
        % - `'Debug'`: Show files that did not match all the required conditions (default is
        %   false)
        % - `'Verbose'`: Also show files that *did* match all required conditions. Has no
        %   effect is `'Debug'` is set to false.
        % - `'MaxLog'`: The maximum number of files per subset to show when `'Debug'` is set
        %   to true
        %
        % See also Trial, DataSubset, TrialConditions.generate

        p = inputParser;
        addRequired(p, 'subsets', @(x) isa(x, 'DataSubset'));
        addRequired(p, 'conditions', @(x) isa(x, 'TrialConditions'));
        addParameter(p, 'SubjectFormat', 'Subject (?<subject>\d+)', @ischar);
        addParameter(p, 'IgnoreFiles', {}, @iscell);
        addParameter(p, 'DefaultConditions', struct());
        addParameter(p, 'Debug', false);
        addParameter(p, 'MaxLog', 25);
        addParameter(p, 'Verbose', false);

        parse(p, subsets, conditions, varargin{:});
        subject_fmt = p.Results.SubjectFormat;
        ignorefiles = GetFullPath(p.Results.IgnoreFiles);
        defaultconds = p.Results.DefaultConditions;
        debug = p.Results.Debug;
        maxlog = p.Results.MaxLog;
        verbose = p.Results.Verbose;

        trials = Trial.empty;

        rg = strcat(subject_fmt, '(?:.*?)', conditions.labels_rg);

        reqcondnames = conditions.required;
        optcondnames = setdiff(setdiff(conditions.condnames, reqcondnames), ...
            fieldnames(defaultconds));

        for seti = 1:length(subsets)
            debugheader = false;
            num_debugs = 0;
            set = subsets(seti);
            rsearchext = strcat(rg, regexprep(set.ext, 'lastreqgroup', reqcondnames(end)));
            pattern = set.pattern;
            files = dir(pattern);
            files = fullfile({files.folder}, {files.name});

            if ~isempty(ignorefiles)
                files = setdiff(files, ignorefiles);
            end

            for filei = 1:length(files)
                file = files{filei};
                priv_file = regexprep(file, conditions.subst(:,1), conditions.subst(:,2));

                m = regexp(priv_file, rsearchext, 'names');

                if debug && num_debugs <= maxlog
                    if verbose || isempty(m) || any(selectstructfun(@isempty, m, reqcondnames))
                        if ~debugheader
                            debugheader = true;
                            fprintf('┌ Subset ''%s'' Searching using regex: ''%s''\n', set.name, rsearchext);
                        end

                        if isempty(m)
                            fprintf('│ ╭ No match\n')
                        else
                            newm = regexp(priv_file, rsearchext, 'match');
                            str = sprintf('''%s''', newm{:});
                            if any(selectstructfun(@isempty, m, reqcondnames))
                                fns = fieldnames(m);
                                is = ismember(fns, reqcondnames);
                                is = structfun(@isempty, m) & is;
                                notfields_joined = join(fns(is), ', ');
                                str = strcat(str, sprintf(' (not found: %s)', notfields_joined{:}));
                            end
                            fprintf('│ ╭ Match: %s\n', str);
                        end
                        fprintf('│ ╰ @ ''%s''\n', file);
                        num_debugs = num_debugs + 1;
                    end
                end

                if isempty(m) || isempty(m.('subject')) || any(selectstructfun(@isempty, m, reqcondnames))
                    continue
                else
                    [~, name, ~] = fileparts(file);

                    subject = m.subject;
                    m = rmfield(m, 'subject');

                    conds = struct();
                    for i = 1:length(reqcondnames)
                        conds.(reqcondnames{i}) = m.(reqcondnames{i});
                    end

                    defkeys = fieldnames(defaultconds);
                    for i = 1:length(defkeys)
                        if isempty(m.(defkeys{i}))
                            conds.(defkeys{i}) = defaultconds.(defkeys{i});
                        else
                            conds.(defkeys{i}) = m.(defkeys{i});
                        end
                    end

                    for i = 1:length(optcondnames)
                        if ~isempty(m.(optcondnames{i}))
                            conds.(optcondnames{i}) = m.(optcondnames{i});
                        end
                    end

                    srcfun = set.source;
                    new_trial = Trial(subject, name, conds, struct(set.name, srcfun(file)));

                    if ~isempty(trials)
                        seenall = find(equiv(new_trial, trials));
                    else
                        seenall = [];
                    end

                    if ~any(seenall) % No matching trials found
                        trials = [trials; new_trial ];
                    else
                        if length(find(seenall)) > 1
                            error()
                        else
                            seen = seenall(1);
                        end
                        trial = trials(seen);
                        if isfield(trial.sources, set.name)
                            compath = sharedpath(file, trial.sources.(set.name).path);
                            short_file = ['.../', regexprep(file, compath, '')];
                            short_orig = ['.../', regexprep(trial.sources.(set.name).path, compath, '')];
                            trialdisp = sprintf("Trial('%s','%s', %i conditions, %i sources)", ...
                                trial.subject, trial.name, length(trial.conditions), ...
                                length(trial.sources));
                            error('Trial:DuplicateSource', "  Duplicate source. Found '%s' source file '%s'\n  for %s which already\n  has a source '%s' at '%s'.", ...
                                set.name, short_file, trialdisp, set.name, short_orig)
                        else
                            trial.sources.(set.name) = srcfun(file);
                        end
                    end
                end
            end
            if debugheader
                fprintf('└ End subset: ''%s''', set.name);
            end
        end
    end

    function summarize(trials, varargin)
        % SUMMARIZE  Summarize an array of trials
        %
        %   summarize(trials)
        %   summarize(trials, Name, Value)
        %
        % # Name-Value arguments
        %
        % - `'Verbosity'`: The maximum number of unique level combinations to show

        p = inputParser;

        addRequired(p, 'trials');
        addParameter(p, 'Verbosity', 5);
        parse(p, trials, varargin{:});
        verbosity = p.Results.Verbosity;

        N = length(trials);
        if N == 0
            disp('0 trials present')
            return
        end

        subs = unique({trials.subject});
        Nsubs = length(subs);

        fprintf('Subjects:\n')
        fprintf(' └ %d: ', Nsubs)
        disp(strjoin(cellfun(@(s) sprintf('''%s''',s), subs, 'UniformOutput', false), ', '))

        fprintf('Trials:\n')
        fprintf(' ├ %d trials\n', N)
        fprintf(' └ Trials per subject:\n')

        Ntrials = cellfun(@(ID) sum(strcmp({trials.subject}, ID)), subs);
        [C,~,ic] = unique(Ntrials);
        Ntrialsdist = sort(accumarray(ic, 1), 'descend');

        for j = 1:min(length(Ntrialsdist),verbosity)
            num = C(length(C) + 1 - j);
            if j < min(length(Ntrialsdist),verbosity)
                sep = '├';
            else
                sep = '└';
            end

            if j >= verbosity
                fprintf('   %s ≤%d: %d/%d (%.f%%)\n', sep, num, sum(Ntrialsdist(j:end)),  Nsubs, ...
                    sum(Ntrialsdist(j:end))/Nsubs*100)
            else
                fprintf('   %s %d: %d/%d (%.f%%)\n', sep, num, Ntrialsdist(j), Nsubs, ...
                    Ntrialsdist(j)/Nsubs*100)
            end
        end

        fprintf('Conditions:\n')
        fprintf(' ├ Observed levels:\n')

        factors = cellfun(@fieldnames, {trials.conditions}, 'UniformOutput', false);
        factors = unique(vertcat(factors{:}));

        levels = cellfun(@struct2cell, {trials.conditions}, 'UniformOutput', false);
        levels = horzcat(levels{:})';

        condsTable = table(categorical(levels(:,1)),'VariableNames',factors(1));
        for i = 2:length(factors)
            T = table(categorical(levels(:,i)),'VariableNames',factors(i));
            condsTable = [condsTable T];
        end

        [unq_conds,~,ic] = unique(condsTable);
        cats = varfun(@categories, unq_conds, 'OutputFormat', 'cell');
        for i = 1:length(factors)
            if i == length(factors)
                sep = '└';
            else
                sep = '├';
            end

            fprintf(' │ %s %s => ', sep, factors{i})
            disp(strcat('{', strjoin(cellfun(@(s) sprintf('''%s''',s), ...
                cats{:,i}, 'UniformOutput', false), ', '), '}'))
        end

        fprintf(' └ Unique level combinations observed: %d', height(unq_conds))
        if height(unq_conds) == prod(cellfun(@length, cats))
            fprintf(' (full factorial)\n')
        else
            fprintf('\n')
        end
        unq_conds = [ unq_conds table(accumarray(ic,1),'VariableNames',{'num_trials'}) ];
        unq_conds = sortrows(unq_conds, 'num_trials', 'descend');
        disp(unq_conds)

        fprintf('Sources:\n')
        sources = cellfun(@fieldnames, {trials.sources}, 'UniformOutput', false);
        sources = unique(vertcat(sources{:}));
        classes = structfun(@class, trials(1).sources, 'UniformOutput', false);
        if ~all(ismember(sources, fieldnames(classes)))
            missing = ismember(sources, fieldnames(classes));
            missing = {sources{~missing}};

            for i = 1:length(missing)
                idx = find(hassource(trials, missing{i}));
                classes.(missing{i}) = class(trials(idx(1)).sources.(missing{i}));
            end
        end
        for i = 1:length(sources)
            if i == length(sources)
                sep = '└';
            else
                sep = '├';
            end

            c = sum(hassource(trials, sources{i}));
            fprintf(" %s '%s' => @%s, %i trials (%.0f%%)\n", sep, sources{i}, classes.(sources{i}), c, c/length(trials)*100)
        end
    end

    function srs = analyzetrials(fun, trials, varargin)
        % ANALYZETRIALS  Evaluate a function on each trial in an array of trials
        %
        %   results = analyzetrials(func, trials)
        %   results = analyzetrials(func, trials, Name, Value)
        %
        % If the function errors for a particular trial, an emtpy result will be returned
        % for that trial, and a warning will be printed that includes the problematic trial
        % and the error that was thrown. However, the rest of the trials in the array will
        % continue to be analyzed with the given function.
        %
        % # Input arguments
        %
        % - `func`: A handle to a function, e.g. `@<function name>`
        % - `trials`: An array of `Trial`s, typically generated by `findtrials`
        %
        % # Name-Value arguments
        %
        % - `'Parallel'`: Use multiple threads/processes to evaluate the function on
        %   multiple trials at once. Can result in a faster analysis, but requires the
        %   "Parallel Computing Toolbox"
        %
        % See also Trial.findtrials
        p = inputParser;
        addRequired(p, 'fun');
        addRequired(p, 'trials', @(x) isa(x, 'Trial'));
        addParameter(p, 'Parallel', false, @islogical);

        parse(p, fun, trials, varargin{:});
        parallel = p.Results.Parallel;

        srs = SegmentResult.empty(length(trials),0);

        warning('on', 'Trial:analyzetrials')

        if parallel
            parpool('local');
            parfor i = 1:length(trials)
                try
                    srs(i,1) = fun(trials(i));
                catch e
                    fprintf('Error at index (%i)', i)
                    disp(trials(i))
                    warning('Trial:analyzetrials', '%s', e.message)
                    srs(i,1) = SegmentResult(Segment(trials(i), Source()));
                end
            end
        else
            for i = 1:length(trials)
                try
                    srs(i,1) = fun(trials(i));
                catch e
                    fprintf('Error at index (%i)', i)
                    disp(trials(i))
                    warning('Trial:analyzetrials', '%s', e.message)
                    srs(i,1) = SegmentResult(Segment(trials(i), Source()));
                end
            end
        end
    end
end % methods

end

function dir = sharedpath(file1, file2)
    ms = regexp({file1, file2}, '(?<dir>[^\.\\\/:*?"<>|\r\n]+[\/\\])', 'end');
    li = max(ms{1}(ms{1} == ms{2}));

    assert(strcmp(file1(1:li), file2(1:li)));
    dir = file1(1:li);
end

function bool = selectstructfun(fun, s, fields)
    bool = false(length(fields),1);
    for i = 1:length(fields)
        bool(i) = fun(getfield(s, fields{i}));
    end
end
