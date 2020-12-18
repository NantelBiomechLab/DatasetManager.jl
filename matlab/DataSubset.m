classdef DataSubset
    properties
        name = ''
        source = ''
        pattern = ''
    end
    
    methods
        function obj = DataSubset(name, source, pattern)
            if nargin > 0
                obj.name = name;
                obj.source = source;
                obj.pattern = pattern;
            end
        end
    end
end
