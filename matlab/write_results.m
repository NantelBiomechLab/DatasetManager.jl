function write_results(filename, data, conds, varargin)
    p = inputParser;
    addRequired(p, 'filename', @ischar);
    addRequired(p, 'data', @istable);
    addRequired(p, 'conds', @iscell);
    addParameter(p, 'Variables', unique(data.variable), @iscell);
    addParameter(p, 'Archive', false, @islogical);
    addParameter(p, 'Format', 'wide', @(f) ismember(f, {'wide'; 'long'}));

    parse(p, filename, data, conds, varargin{:});
    variables = p.Results.Variables;
    archive = p.Results.Archive;
    format = p.Results.Format;

    [path, name, ext] = fileparts(filename);
    if isempty(path)
        path = pwd();
    end
    tempfn = [ path '/~' name '-' num2hex(rand(1,'single')) ext ];

    variables = reshape(variables, length(variables), []);
    conds = reshape(conds, length(conds), []);

    long = data(ismember(data.variable, variables), :);
    ignore_conds = setdiff(data.Properties.VariableNames, ...
        vertcat({'subject';'variable';'value'}, conds));
    if ~isempty(ignore_conds)
        long = removevars(long, ignore_conds);
    end
    long = sortrows(long, vertcat({'variable'; 'subject'}, conds));

    long = movevars(long, 'subject', 'Before', 1);
    for i = 1:(length(conds)-1)
        cond = conds{i};
        nextcond = conds{i+1};
        long = movevars(long, cond, 'Before', nextcond);
    end
    long = movevars(long, conds{end}, 'Before', 'variable');

    if strcmp(format, 'long')
        writetable(long, tempfn);
        if archive && isfile(filename)
            movefile(filename, [filename '.bak'], 'f')
        end

        % a file at `filename` shouldn't exist at this point so no need to force
        movefile(tempfn, filename)
    else % strcmp(format, 'wide') == true
        labels = join(cellfun(@char, table2cell(long(:, conds)), 'UniformOutput', false), '_', 2);
        wide = addvars(long, labels, 'After', conds{end}, 'NewVariableNames', {'labels'});
        wide = unstack(wide, 'value', 'subject');
        wide = movevars(wide, 'variable', 'Before', 1);

        widechar = cellfun(@string, table2cell(wide)', 'UniformOutput', false);
        MISS = cellfun(@ismissing, widechar);
        [widechar{MISS}] = deal("");
        widechar = cellstr(widechar);

        subrownames = setdiff(wide.Properties.VariableNames, vertcat({'subject'; 'labels'; 'variable'}, conds))';
        subrownames = vertcat({'variable'}, conds, {'labels'}, subrownames);

        widechar = horzcat(subrownames, widechar);
        cstr = join(widechar, ',');

        fid = fopen(tempfn, 'w+');
        fprintf(fid, '%s\n', cstr{:});
        fclose(fid);

        if archive && isfile(filename)
            movefile(filename, [filename '.bak'], 'f')
        end

        % a file at `filename` shouldn't exist at this point so no need to force
        movefile(tempfn, filename)
    end


end
