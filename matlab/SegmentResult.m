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
            conds = [segs.conditions];
        end

        function resvar = resultsvariables(obj)
            resvar = {};
            for i = 1:length(obj)
                resvar = [resvar; fieldnames(obj(i).results)];
            end

            resvar = unique(resvar);
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
