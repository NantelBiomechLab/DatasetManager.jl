classdef Segment
    properties
        trial (1,1) Trial
        source (1,1) Source
        start = -Inf
        finish = Inf
        conditions
    end

    methods
        function obj = Segment(trial, source, varargin)
            p = inputParser;
            addOptional(p, 'trial', Trial(), @(x) isa(x, 'Trial'));
            addOptional(p, 'source', Source(), @(x) ischar(x) || isa(x, 'Source'));
            addParameter(p, 'Start', -Inf);
            addParameter(p, 'Finish', Inf);
            addParameter(p, 'Conditions', struct());

            parse(p, trial, source, varargin{:});
            obj.trial = p.Results.trial;
            source = p.Results.source;
            obj.source = getsource(trial, source);
            obj.start = p.Results.Start;
            obj.finish = p.Results.Finish;
            obj.conditions = merge(p.Results.Conditions, trial.conditions);
        end

        function data = readsegment(obj, varargin)
            data = readsource(obj.source, varargin{:});
            st = obj.start;
            fin = obj.finish;
            if st ~= -Inf && fin ~= Inf
                data = data(st:fin, :);
            elseif st ~= -Inf
                data = data(st:end);
            elseif fin ~= Inf
                data = data(1:fin);
            end
        end

        function s = subject(obj)
            ts = [obj.trial];
            s = {ts.subject};
        end
    end
end

function map = merge(map1, map2)
    map1keys = fieldnames(map1);
    map2keys = fieldnames(map2);

    intsct = intersect(map1keys, map2keys);
    if ~isempty(intsct)
        remove(map2, intsct);
    end

    map = cell2struct([struct2cell(map1), struct2cell(map2)], [map1keys, ...
        fieldnames(map2)], 1);
end
