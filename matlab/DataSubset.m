classdef DataSubset
    % DataSubset Describe a subset of your data
    %   Describes a subset of data, where files found in and matching `pattern`
    %   (using <a href="matlab:web('https://www.mathworks.com/help/matlab/ref/dir.html#bup_1_c-2')">glob syntax</a>) are all of the same `AbstractSource` subclass.
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
