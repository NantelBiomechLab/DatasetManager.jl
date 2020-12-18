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

    function out = selectstructmerge(fun, s, m)
        out = struct;
        fields = union(fieldnames(s), fieldnames(m), 'stable');
        for i = 1:length(fields)
            if isfield(s, fields{i}) && isfield(m, fields{i})
                if fun(s)
                    out.(fields{i}) = m.(fields{i});
                else
                    out.(fields{i}) = s.(fields{i});
                end
            elseif isfield(s, fields{i})
                out.(fields{i}) = s.(fields{i});
            else
                out.(fields{i}) = m.(fields{i});
            end
        end
    end

    function s = structfrommap(map)
        s = struct;
        ks = keys(map);
        vs = values(map);
        for i = 1:length(map)
            s.(ks{i}) = vs{i};
        end
    end
end

methods(Static)
    function trials = findtrials(subsets, conditions, varargin)
        p = inputParser;
        addRequired(p, 'subsets', @(x) isa(x, 'DataSubset'));
        addRequired(p, 'conditions', @(x) isa(x, 'TrialConditions'));
        addParameter(p, 'SubjectFormat', '(?<=Subject )0*(?<subject>\d+)', @ischar);
        addParameter(p, 'IgnoreFiles', {}, @iscell);

        priv_defaultconds = containers.Map(conditions.condnames, cellstr(strings(length(conditions.condnames),1)));
        addParameter(p, 'DefaultConditions', priv_defaultconds, @(x) isa(x, 'containers.Map'))

        parse(p, subsets, conditions, varargin{:});
        subject_fmt = p.Results.SubjectFormat;
        ignorefiles = p.Results.IgnoreFiles;
        defaultconds = p.Results.DefaultConditions;

        trials = Trial.empty;

        rg = strcat(subject_fmt, '.*', conditions.labels_rg);

        reqcondnames = conditions.required;
        optcondnames = setdiff(conditions.condnames, reqcondnames);

        defaultconds = [priv_defaultconds; defaultconds];

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

                    conds = containers.Map(fieldnames(m), struct2cell(m));
                    ks = keys(conds);
                    for i = 1:length(conds)
                        if isempty(conds(ks{i})) && isKey(defaultconds, ks{i}) && ~isempty(defaultconds(ks{i}))
                            conds(ks{i}) = defaultconds(ks{i});
                        end
                    end

                    diffkeys = setdiff(keys(conds), keys(defaultconds));
                    if ~isempty(diffkeys)
                        for i = 1:length(diffkeys)
                            conds(diffkeys{i}) = defaultconds(diffkeys{i});
                        end
                    end

                    trial = Trial(subject, name, struct(set.name, file), conds);

                    if ~isempty(trials)
                        seenall = find(arrayfun(@(x) equiv(trial, x), trials));
                    else
                        seenall = [];
                    end

                    if ~any(seenall) % No matching trials found
                        trials = [trials; trial ];
                    else
                        if length(find(seenall)) > 1
                            error()
                        else
                            seen = seenall(1);
                        end
                        trial = trials(seen);
                        if isfield(trial.sources, set.name)
                            error('duplicate source found')
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
