classdef Source
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
            if nargin == 0
                ext = '';
            else
                [~,~,ext] = fileparts(obj.path);
            end
        end

        function readsource(obj)
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
