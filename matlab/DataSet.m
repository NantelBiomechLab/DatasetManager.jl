classdef DataSet

methods(Static, Access = private)
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
        addParameter(p, 'SubjectFormat', '(?<=Subject )(?<subject>\d+)', @ischar);
        addParameter(p, 'IgnoreFiles', {}, @iscell);

        priv_defaultconds = containers.Map.empty;
        addParameter(p, 'DefaultConditions', priv_defaultconds, @(x) isa(x, 'containers.Map'))

        parse(p, subsets, conditions, varargin{:});
        subject_fmt = p.Results.SubjectFormat;
        ignorefiles = p.Results.IgnoreFiles;
        defaultconds = p.Results.DefaultConditions;

        trials = Trial.empty;

        rg = strcat(subject_fmt, '.*', conditions.labels_rg);

        reqcondnames = conditions.required;
        optcondnames = setdiff(setdiff(conditions.condnames, reqcondnames), ...
            keys(defaultconds));

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
                priv_file = DataSet.multregexprep(file, conditions.subst(:,1), conditions.subst(:,2));

                m = regexp(priv_file, rg, 'names');
                if isempty(m)
                    continue
                end

                if isempty(m.('subject')) || any(DataSet.selectstructfun(@isempty, m, reqcondnames))
                    continue
                else
                    [~, name, ~] = fileparts(file);

                    subject = m.subject;
                    m = rmfield(m, 'subject');

                    conds = containers.Map.empty;
                    for i = 1:length(reqcondnames)
                        conds(reqcondnames{i}) = m.(reqcondnames{i});
                    end

                    defkeys = keys(defaultconds);
                    for i = 1:length(defkeys)
                        if isempty(m.(defkeys{i}))
                            conds(defkeys{i}) = defaultconds(defkeys{i});
                        else
                            conds(defkeys{i}) = m.(defkeys{i});
                        end
                    end

                    for i = 1:length(optcondnames)
                        if ~isempty(m.(optcondnames{i}))
                            conds(optcondnames{i}) = m.(optcondnames{i});
                        end
                    end

                    new_trial = Trial(subject, name, conds, struct(set.name, file));

                    if ~isempty(trials)
                        seenall = find(arrayfun(@(x) equiv(new_trial, x), trials));
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
                            trial.sources.(set.name) = file;
                            trials(seen) = trial;
                        end
                    end
                end
            end
        end
    end
end % methods

end
