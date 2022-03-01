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

        function requiresource(obj, trial, parent, varargin)
            p = inputParser;
            p.KeepUnmatched = true;
            addRequired(p, 'obj', @(x) isa(x, 'Source'));
            addRequired(p, 'trial', @(x) isa(x, 'Trial'));
            addOptional(p, 'parent', false, @islogical);
            addParameter(p, 'Name', srcname_default(obj), @ischar);
            addParameter(p, 'Force', false, @islogical);
            addParameter(p, 'Dependencies', dependencies(obj));

            parse(p, obj, trial, parent, varargin{:});
            parent = p.Results.Parent;
            name = p.Results.Name;
            force = p.Results.Force;
            deps = p.Results.Dependencies;

            if ~force
                if hassource(trial, name) || hassource(trial, obj) || ...
                    (~parent && hassource(trial, obj))
                    return
                elseif isfile(obj.path)
                    trial.sources.(name) = obj
                end
            end

            % TODO: Decide if `false` is an acceptable design choice (in lieu of the Julia
            % version's `UnknownDeps`
            if ~deps
                error('unable to generate missing source %s for %s', obj, trial)
            else
                for i = 1:length(deps)
                    requiresource(deps(i), trial, true, 'Force', false);
                end
            end

            new_obj = generatesource(obj, trial, deps, p.Unmatched);
            if ~isfile(new_obj.path)
                error('failed to generate source ''%s'': %s for %s', name, new_obj, trial)
            end

            trial.sources.(name) = new_obj;
        end
    end

end
