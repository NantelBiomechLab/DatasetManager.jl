classdef Trial
    % Trial Describes a single trial, including a reference to the subject, trial name, trial
    % conditions, and relevant sources of data.
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

        function bool = hassource(trial, varargin)
            p = inputParser;

            addRequired(p, 'trial', @(x) isa(x, 'Trial'));
            addOptional(p, 'name', '');
            addOptional(p, 'src', Source(), @(x) isa(x, 'Source'));
            addParameter(p, 'OfClass', false, @islogical);

            parse(p, trial, varargin{:});
            name = p.Results.name;
            src = p.Results.src;
            ofclass = p.Results.OfClass;

            bool = false;

            bool = bool | isfield(trial.sources, name);

            bool = bool | any(structfun(@(x) x == src, trial.sources));
            
            if ofclass
                bool = bool | structfun(@(x) isa(x, class(src)), trial.sources);
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
    end

methods(Static)
    function trials = findtrials(subsets, conditions, varargin)
        % FINDTRIALS Find all the trials matching `conditions` which can be found in `subsets`.
        %
        % # Keyword arguments:
        %
        % - 'SubjectFormat'  "(?<=Subject )(?<subject>\\d+)"`: The format that the subject identifier
        %     will appear in file paths.
        % - `ignorefiles::Union{Nothing, Vector{String}}=nothing`: A list of files, given in the form
        %     of an absolute path, that are in any of the `subsets` folders which are to be ignored.
        % - `defaultconds::Union{Nothing, Dict{Symbol}}=nothing`: Any conditions which have a default
        %     level if the condition is not found in the file path.

        p = inputParser;
        addRequired(p, 'subsets', @(x) isa(x, 'DataSubset'));
        addRequired(p, 'conditions', @(x) isa(x, 'TrialConditions'));
        addParameter(p, 'SubjectFormat', 'Subject (?<subject>\d+)', @ischar);
        addParameter(p, 'IgnoreFiles', {}, @iscell);

        addParameter(p, 'DefaultConditions', struct());

        parse(p, subsets, conditions, varargin{:});
        subject_fmt = p.Results.SubjectFormat;
        ignorefiles = GetFullPath(p.Results.IgnoreFiles);
        defaultconds = p.Results.DefaultConditions;

        trials = Trial.empty;

        rg = strcat(subject_fmt, '.*', conditions.labels_rg);

        reqcondnames = conditions.required;
        optcondnames = setdiff(setdiff(conditions.condnames, reqcondnames), ...
            fieldnames(defaultconds));

        for seti = 1:length(subsets)
            set = subsets(seti);
            pattern = set.pattern;
            files = dir(pattern);
            files = fullfile({files.folder}, {files.name});

            if ~isempty(ignorefiles)
                files = setdiff(files, ignorefiles);
            end

            for filei = 1:length(files)
                file = files{filei};
                priv_file = multregexprep(file, conditions.subst(:,1), conditions.subst(:,2));

                m = regexp(priv_file, rg, 'names');
                if isempty(m)
                    continue
                end

                if isempty(m.('subject')) || any(selectstructfun(@isempty, m, reqcondnames))
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
                            [~, short_file, ext] = fileparts(file);
                            [~, short_orig, o_ext] = fileparts(trial.sources.(set.name));
                            trialdisp = sprintf("Trial('%s','%s', %i conditions, %i sources)", ...
                                trial.subject, trial.name, length(trial.conditions), ...
                                length(trial.sources));
                            error("Error: Duplicate source. Found '%s' source file\n'%s'\nfor %s which already has\na '%s' source at '%s'.", ...
                                set.name, [short_file, ext], trialdisp, set.name, [short_orig, o_ext])
                        else
                            trial.sources.(set.name) = srcfun(file);
                            trials(seen) = trial;
                        end
                    end
                end
            end
        end
    end

    function summarize(trials)
        verbosity = 5;
        N = length(trials);
        if N == 0
            disp('0 trials present')
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
        Ntrialsdist = accumarray(ic, 1);
        [Ntrialsdist, ord] = sort(Ntrialsdist, 'descend');

        for j = 1:min(length(Ntrialsdist),verbosity)
            num = Ntrialsdist(ord(j));
            if j < min(length(Ntrialsdist),verbosity)
                sep = '├';
            else
                sep = '└';
            end

            if j >= verbosity
                fprintf('   %s ≤%d: %d/%d (%3.f%%)\n', sep, ord(j), num, Nsubs, ...
                    sum(Ntrialsdist(ord(j:end))./Nsubs)*100)
            else
                fprintf('   %s %d: %d/%d (%3.f%%)\n', sep, ord(j), num, Nsubs, ...
                    num/Nsubs*100)
            end
        end

        fprintf('Conditions:\n')
        fprintf(' ├ Observed levels:\n')

        factors = cellfun(@keys, {trials.conditions}, 'UniformOutput', false);
        factors = unique(vertcat(factors{:}));

        levels = cellfun(@values, {trials.conditions}, 'UniformOutput', false);
        levels = vertcat(levels{:});

        condsTable = table(categorical(levels(:,1)),'VariableNames',factors(1));
        for i = 2:length(factors)
            T = table(categorical(levels(:,i)),'VariableNames',factors(i));
            condsTable = [condsTable T];
        end

        [unq_conds,~,ic] = unique(condsTable);
        cats = varfun(@categories, unq_conds);
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
        if height(unq_conds) == prod(varfun(@length, cats, 'OutputFormat', 'uniform'))
            fprintf(' (full factorial)\n')
        else
            fprintf('\n')
        end
        unq_conds = [ unq_conds table(accumarray(ic,1),'VariableNames',{'num_trials'}) ];
        unq_conds = sortrows(unq_conds, 'num_trials', 'descend');
        disp(unq_conds)

        fprintf('Sources:\n')
        sources = fieldnames([trials.sources]);
        for i = 1:length(sources)
            if i == length(sources)
                sep = '└';
            else
                sep = '├';
            end

            fprintf(' %s ''%s''\n', sep, sources{i})
        end
    end

    function srs = analyzetrials(fun, trials, varargin)
        p = inputParser;
        addRequired(p, 'fun');
        addRequired(p, 'trials', @(x) isa(x, 'Trial'));
        addParameter(p, 'Parallel', false, @isbool);

        parse(p, fun, trials, varargin{:});
        parallel = p.Results.Parallel;

        srs = SegmentResult.empty(length(trials),0);

        if parallel
            parpool('local');
            parfor i = 1:length(trials)
                srs(i) = fun(trials(i));
            end
        else
            for i = 1:length(trials)
                srs(i,1) = fun(trials(i));
            end
        end
    end
end % methods

end

function newstr = multregexprep(str, regex, rep)
    newstr = str;
    length(regex) == length(rep);
    for i = 1:length(regex)
        newstr = regexprep(newstr, regex{i}, rep{i});
    end
end

function bool = selectstructfun(fun, s, fields)
    bool = false(length(fields),1);
    for i = 1:length(fields)
        bool(i) = fun(getfield(s, fields{i}));
    end
end
