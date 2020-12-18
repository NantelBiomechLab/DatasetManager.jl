classdef Trial % < matlab.mixin.CustomDisplay
    properties
        subject(1,:) char
        name(1,:) char
        sources
        conds containers.Map
    end

    methods
        function obj = Trial(subject, name, sources, conds)
            if nargin > 0
                obj.subject = subject;
                obj.name = name;
                obj.sources = sources;
                obj.conds = conds;
            end
        end

        function bl = isequal(obj, y)
            bl = strcmp({obj.subject}, {y.subject})' & strcmp({obj.name}, {y.name})' & ...
                arrayfun(@(x, y) isequal(keys(x.conds), keys(y.conds)) && ...
                                 isequal(values(x.conds), values(y.conds)), obj, y);
        end

        function bl = equiv(obj, y)
            bl = strcmp(obj.subject, y.subject) && isequal(obj.conds, y.conds);
        end
    end

    % CustomDisplay method overloads
    % methods (Access = protected)
    % end
end
