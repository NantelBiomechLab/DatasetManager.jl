classdef SegmentResult
    % SEGMENTRESULT  Contains a segment and the results of an analysis.
    %
    %   segres = SegmentResult(seg)
    %   segres = SegmentResult(seg, results)
    %
    % # Input arguments
    %
    % - `seg`: A Segment
    % - `results`: (Optional) A struct where each field is an individual result. If omitted,
    % an empty struct will be created.

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

        function tbl = stack(srs, varargin)
            % STACK  Stack an array of SegmentResults into a long form table
            %
            %   tbl = stack(segres)
            %   tbl = stack(segres, Name, Value)
            %
            % # Name-Value arguments
            %
            % - `'Conditions'`: The conditions to include in the table (default is all
            %   conditions present in any trials/segments). Used to remove "conditions"
            %   which are not experimental (i.e. needed for grouping/reducing in subsequent
            %   statistics)
            % - `'Variables'`: The variables to include in the table (default is all
            %   variables present in any trials/segments).

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
            tbl = struct2table([srs.results]);

            % Add conditions columns to table
            tbl = addvars(tbl, sub, 'Before', 1, 'NewVariableNames', {'subject'});
            for i = 1:length(condnames)
                tbl = addvars(tbl, reshape({srs.conditions.(condnames{i})}, [], 1), 'After', 1, ...
                    'NewVariableNames', condnames{i});
            end

            % Convert conditions columns to categorical
            tbl.subject = categorical(tbl.subject);
            for i = 1:length(condnames)
                % convert to string because categorical doesn't accept missing's in cell arrays of
                % char vectors (cell arrays of strings ok with missing)
                tbl.(condnames{i}) = categorical(cellfun(@string, tbl.(condnames{i})));
            end

            tbl = stack(tbl(:, vertcat({'subject'}, condnames, vars)), vars, ...
                'NewDataVariableName', 'value', 'IndexVariableName', 'variable');
            tbl = sortrows(tbl, vertcat({'variable'; 'subject'}, condnames));
        end
    end
end
