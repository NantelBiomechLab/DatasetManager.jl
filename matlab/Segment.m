classdef Segment
    % SEGMENT  Describes a segment of time in a source for a trial, optionally with
    % additional conditions specific to that segment of time. The conditions for the whole
    % trial will be combined with any conditions specific to the segment (so that all
    % conditions applicable to that segment of time will be available in one spot).
    %
    %   seg = Segment(trial, source)
    %   seg = Segment(trial, source, Name, Value)
    %
    % # Input arguments
    %
    % - `source`: Can be an instance of a Source class subtype, or the name of a source
    %   known/expected to be present in `trial`.
    %
    % # Name-Value arguments
    %
    % - `'Start'`: The beginning time of the segment
    % - `'Finish'`: The ending time of the segment
    % - `'Conditions'`: A struct containing any additional conditions for that segment.

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
            if isa(source, 'Source')
                obj.source = source;
            else
                obj.source = getsource(trial, source);
            end
            obj.start = p.Results.Start;
            obj.finish = p.Results.Finish;
            obj.conditions = merge(p.Results.Conditions, trial.conditions);
        end

        function data = readsegment(obj, varargin)
            % READSEGMENT  Read the segment of time from the source of `seg`. Name-value
            % arguments (besides `'Start'` and `'Finish'`, which are reserved) are passed on
            % to the `readsource` method for the segment's `src` class.
            %
            %   data = readsegment(seg)
            %   data = readsegment(seg, Name, Value)

            data = readsource(obj.source, 'Start', obj.start, 'Finish', obj.finish, varargin{:});
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
