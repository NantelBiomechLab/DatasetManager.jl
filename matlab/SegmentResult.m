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
                resvar = [resvar, fieldnames(obj(i).results)];
            end

            resvar = unique(resvar);
        end

        function data = stack(obj)
            sub = subject(obj)';
            conds = struct2cell(conditions(obj)')';
            condnames = fieldnames(obj(1).segment.conditions);
            data = struct2table([obj.results]);
            data = addvars(data, sub, 'Before', 1, 'NewVariableNames', {'subject'});
            for i = size(conds, 2):-1:1
                data = addvars(data, conds(:,i), 'After', 1, 'NewVariableNames', ...
                    condnames(i));
            end
        end
    end
end
