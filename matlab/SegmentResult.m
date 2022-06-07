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

        function data = stack(srs)
            sub = subject(srs)';
            conds = struct2cell(conditions(srs)')';
            condnames = fieldnames(srs(1).segment.conditions);
            vars = resultsvariables(srs);
            for vari = 1:length(vars)
                var = vars{vari};
                for i = find(cellfun(@(s) ~isfield(s, var), {srs.results}))
                    srs(i).results.(var) = NaN;
                end
            end
            data = struct2table([srs.results]);
            data = addvars(data, sub, 'Before', 1, 'NewVariableNames', {'subject'});
            for i = size(conds, 2):-1:1
                data = addvars(data, conds(:,i), 'After', 1, 'NewVariableNames', ...
                    condnames(i));
            end

            data.subject = categorical(data.subject);
            for i = 1:length(condnames)
                data.(condnames{i}) = categorical(data.(condnames{i}));
            end
        end
    end
end
