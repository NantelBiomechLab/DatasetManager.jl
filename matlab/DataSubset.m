classdef DataSubset
    % DATASUBSET  Describes a subset of `source` data files found within a folder `dir` which match
    % `pattern`.
    %
    %   subset = DataSubset(name, source, pattern)
    %   subset = DataSubset(name, source, pattern, ext)
    %
    % # Input arguments
    %
    % - `name`: The name of the DataSubset that will be used in `findtrials` as the source
    %   name in a Trial.
    % - `source`: The Source type of all files described by this subset
    % - `pattern`: The pattern (using <a href="matlab:web('https://www.mathworks.com/help/matlab/ref/dir.html#bup_1_c-2')">glob syntax</a>) that defines where sources in this subset are stored on disk.
    %
    % # Examples
    %
    % ```matlab
    % subsets = [
    %     DataSubset('events', @GaitEvents, '/path/to/events/Subject */*.csv')
    % ]
    % ```
    %
    % See also Source, TrialConditions, Trial.findtrials

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
