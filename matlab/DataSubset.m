classdef DataSubset
    % DataSubset Describe a subset of your data
    %   Describes a subset of data, where files found in and matching `pattern`
    %   (using <a href="matlab:web('https://www.mathworks.com/help/matlab/ref/dir.html#bup_1_c-2')">glob syntax</a>) are all of the same `AbstractSource` subclass.
    properties
        name = ''
        source
        pattern = ''
        ext = '(?(lastreqgroup)\w*?|)\.'
    end
    
    methods
        function obj = DataSubset(name, source, varargin)
            if nargin > 0
                if nargin > 3
                    obj.name = name;
                    obj.source = source;
                    obj.pattern = varargin{1};
                    obj.ext = strcat('(?(lastreqgroup)\w*?|)', regexprep(varargin{2}, '^\\?\.?', '\\.'));
                elseif nargin == 3
                    obj.name = name;
                    obj.source = source;
                    obj.pattern = varargin{:};
                    obj.ext = strcat('(?(lastreqgroup)\w*?|)', regexprep(srcext(source()), '^\\?\.?', '\\.'));
                end
            end
        end
    end
end
