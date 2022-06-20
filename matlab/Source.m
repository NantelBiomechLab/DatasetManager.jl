classdef Source
    % SOURCE  A type representing a source of data in a particular file format
    %
    %   src = Source(path)
    %
    % # Input arguments
    %
    % - `path`: The absolute path to the source file
    %
    % # Examples
    %
    % ```matlab
    % src = Source('/path/to/source/file')
    % ```
    %
    % # Creating custom sources
    %
    % All subtypes of `Source` **must**:
    %
    % - have a `path` field
    % - have at least these two constructors:
    %   - empty constructor
    %   - single argument constructor accepting a char vector of an absolute path
    %
    % `Source` subtypes **should**:
    %
    % - have a [`Source.readsource`](@ref) method
    %
    % `Source` subtypes **may** implement these additional methods to improve user
    % experience and/or enable additional funcitonality:
    %
    % - [`Source.readsegment`](@ref)
    % - [`Source.generatesource`](@ref) (if enabling `requiresource!` generation)
    % - [`Source.dependencies`](@ref) (if defining a `generatesource` method)
    % - [`Source.srcext`](@ref)
    % - [`Source.srcname_default`](@ref)

    properties
        path(1,:) char
    end

    methods
        function obj = Source(path)
            if nargin > 0
                obj.path = path;
            else
                obj.path = tempname;
            end
        end

        function bool = eq(obj, y)
            bool = strcmp(class(obj), class(y));
            if bool
                bool = bool & strcmp(obj.path, y.path);
            end
        end

        function ext = srcext(obj)
            % SRCEXT  Get the file extension for a source.
            %
            %   ext = srcext(src)
            %
            % # Input arguments
            %
            % - `src`: Can be the class of a source subtype or an instance of a source. If
            %   `src` is a class, the default extension for that `src < Source` class will be
            %   returned; if `src` is an instance of a source, then the actual extension for
            %   that `src` will be returned, regardless of whether it matches the default
            %   extension for that class or not.
            %
            % # Examples
            %
            % ```matlab
            % % assuming the existence of a class `GaitEvents` which subtypes `Source`
            % src = GaitEvents('/path/to/file.tsv')
            % ext = srcext(GaitEvents) % == '.csv'
            % ext = srcext(src) % == '.tsv'
            % ```
            %
            % # Implementation notes
            %
            % When defining a method for a custom class subtyping `Source`, the period
            % should be included in the extension.
            %
            % ## Example implementation
            %
            % ```matlab
            % function ext = srcext(obj)
            %     %% Calling the default `srcext` method for `Source` will return the actual
            %     %% extension for `< Source` instances
            %     ext = srcext@Source(obj);
            %
            %     if isempty(ext)
            %         ext = '.ext';
            %     end
            % end
            % ```

            if nargin == 0
                ext = '';
            else
                [~,~,ext] = fileparts(obj.path);
            end
        end

        function readsource(obj)
            % READSOURCE  Read the source data from file.
            %
            %   data = readsource(src)
            %

            error('Error: A `readsource` function has not been implemented yet for %s', ...
                class(obj))
        end

        function generatesource(obj)
            error('Error: A `generatesource` function has not been implemented yet for %s', ...
                class(obj))
        end

        function deps = dependencies(obj)
            deps = false;
        end

        function name = srcname_default(obj)
            name = class(obj);
        end

    end

end
