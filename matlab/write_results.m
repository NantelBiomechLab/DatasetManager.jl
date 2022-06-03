function write_results(filename, data, conditions, varargin)
    p = inputParser;
    addRequired(p, 'filename', @ischar);
    addRequired(p, 'data', @istable);
    addRequired(p, 'conditions', @iscell);
    addParameter(p, 'Variables', setdiff(data.Properties.VariableNames, vertcat({'subject'; 'values'}, conditions)), @iscell);
    addParameter(p, 'Archive', false, @islogical);
    addParameter(p, 'Format', 'wide', @(f) ismember(f, {'wide'; 'long'}));

    parse(p, filename, data, conditions, varargin{:});
    variables = p.Results.Variables;
    archive = p.Results.Archive;
    format = p.Results.Format;

    [path, name, ext] = fileparts(filename);
    if isempty(path)
        path = pwd();
    end
    tempfn = [ path '/~' name '-' num2hex(rand(1,'single')) ext ];

    if strcmp(format, 'long')
        long = stack(data(:, vertcat({'subject'}, conditions, variables)), variables, ...
            'NewDataVariableName', 'value', 'IndexVariableName', 'variable');
        long = sortrows(long, vertcat({'subject'}, conditions));

        writetable(long, tempfn);
        if archive && isfile(filename)
            movefile(filename, [filename '.bak'], 'f')
        end

        % a file at `filename` shouldn't exist at this point so no need to force
        movefile(tempfn, filename)
    else % strcmp(format, 'wide') == true
        long = stack(data(:, vertcat({'subject'}, conditions, variables)), variables, ...
            'NewDataVariableName', 'value', 'IndexVariableName', 'variable');
        long = sortrows(long, vertcat({'subject'}, conditions));
        
        labels = join(cellfun(@char, table2cell(long(:, conditions)), 'UniformOutput', false), '_', 2);
        wide = addvars(long, labels, 'After', conditions{end}, 'NewVariableNames', {'labels'});
        wide = unstack(wide, 'value', 'subject');
        wide = movevars(wide, 'variable', 'Before', 1);

        widechar = cellfun(@string, table2cell(wide)', 'UniformOutput', false);
        widechar = cellfun(@char, widechar, 'UniformOutput', false);

        subrownames = setdiff(wide.Properties.VariableNames, vertcat({'subject'; 'labels'; 'variable'}, conditions))';
        subrownames = vertcat({'variable'}, conditions, {'labels'}, subrownames);

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
