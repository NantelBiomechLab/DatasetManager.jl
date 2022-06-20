function write_results(filename, tbl, conds, varargin)
    % WRITE_RESULTS  Write the results in `tbl` to file at `filename`, including only the
    % conditions given by `conds`.
    %
    %   write_results(filename, tbl, conds)
    %   write_results(filename, tbl, conds, Name, Value)
    %
    % # Input arguments
    %
    % - `filename`: The path to write the results to
    % - `tbl`: The table containing results. Must already be in 'long' form (default from
    %   stack)
    % - `conds`: A cell array listing the subset of conditions which are to be included/written
    %   to file
    %
    % # Name-Value arguments
    %
    % - `'Variables'`: A cell array listing the subset of variables to be written to file
    % - `'Format'`: Must be either `'wide'` or `'long'`, defaults to `'wide'`. Determines the
    %   shape of the written results. (Needs to be 'wide' for some common stats in SPSS, e.g.
    %   ANOVA.)
    % - `'Archive'`: A logical value controlling whether a file already existing at
    %   `filename` should be archived to `[filename '.bak']` before writing the new results to
    %   `filename`.
    % See also SegmentResult.stack

    p = inputParser;
    addRequired(p, 'filename', @ischar);
    addRequired(p, 'tbl', @istable);
    addRequired(p, 'conds', @iscell);
    addParameter(p, 'Variables', unique(tbl.variable), @iscell);
    addParameter(p, 'Archive', false, @islogical);
    addParameter(p, 'Format', 'wide', @(f) ismember(f, {'wide'; 'long'}));

    parse(p, filename, tbl, conds, varargin{:});
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

    long = tbl(ismember(tbl.variable, variables), :);
    ignore_conds = setdiff(tbl.Properties.VariableNames, ...
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
