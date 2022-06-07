classdef SegmentResult
    properties
        segment Segment
        results
    end

    methods
        function obj = SegmentResult(seg, res)
            if nargin == 1
                obj.segment = seg;
                obj.results = struct();
            elseif nargin == 2
                obj.segment = seg;
                obj.results = res;
            end
        end

        function t = trial(obj)
            segs = [obj.segment];
            t = [segs.trial];
        end

        function s = subject(obj)
            s = subject([obj.segment]);
        end

        function conds = conditions(obj)
            segs = [obj.segment];
            condnames = unique_conditions(obj);
            conditions_cell = {segs.conditions};
            for ci = 1:length(condnames)
                cond = condnames{ci};
                I = find(cellfun(@(c) ~isfield(c, cond), conditions_cell));
                for i = I
                    conditions_cell{i}.(cond) = missing;
                end
            end

            conds = [conditions_cell{:}];
        end

        function resvar = resultsvariables(obj)
            resvar = cellfun(@fieldnames, {obj.results}, 'UniformOutput', false);
            resvar = unique(vertcat(resvar{:}));
        end

        function conds = unique_conditions(segres)
            segs = [segres.segment];
            withdups = cellfun(@fieldnames, {segs.conditions}, 'UniformOutput', false);
            conds = unique(vertcat(withdups{:}));
        end

        function data = stack(srs, varargin)
            p = inputParser;
            addRequired(p, 'srs', @(x) isa(x, 'SegmentResult'));
            addParameter(p, 'Conditions', unique_conditions(srs), @iscell);
            addParameter(p, 'Variables', resultsvariables(srs), @iscell);

            parse(p, srs, varargin{:});
            condnames = p.Results.Conditions;
            vars = p.Results.Variables;

            sub = reshape(subject(srs), [], 1);
            for vari = 1:length(vars)
                var = vars{vari};
                for i = find(cellfun(@(s) ~isfield(s, var), {srs.results}))
                    srs(i).results.(var) = NaN;
                end
            end
            data = struct2table([srs.results]);

            % Add conditions columns to table
            data = addvars(data, sub, 'Before', 1, 'NewVariableNames', {'subject'});
            for i = 1:length(condnames)
                data = addvars(data, reshape({srs.conditions.(condnames{i})}, [], 1), 'After', 1, ...
                    'NewVariableNames', condnames{i});
            end

            % Convert conditions columns to categorical
            data.subject = categorical(data.subject);
            for i = 1:length(condnames)
                % convert to string because categorical doesn't accept missing's in cell arrays of
                % char vectors (cell arrays of strings ok with missing)
                data.(condnames{i}) = categorical(cellfun(@string, data.(condnames{i})));
            end

            data = stack(data(:, vertcat({'subject'}, condnames, vars)), vars, ...
                'NewDataVariableName', 'value', 'IndexVariableName', 'variable');
            data = sortrows(data, vertcat({'variable'; 'subject'}, condnames));
        end
    end
end
