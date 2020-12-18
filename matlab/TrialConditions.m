classdef TrialConditions
    properties
        condnames(1,:)
        required(1,:)
        labels_rg
        subst(:,2)
    end

    methods
        function obj = TrialConditions(condnames, required, labels_rg, subst)
            if nargin > 0
                obj.condnames = condnames;
                obj.required = required;
                obj.labels_rg = labels_rg;
                obj.subst    = subst;
            end
        end
    end

    methods(Static)
        function obj = generate(conditions, labels, varargin)
            p = inputParser;
            addRequired(p, 'conditions', @iscell)
            addRequired(p, 'labels', @isstruct)
            addParameter(p, 'Required', conditions, @iscell)
            addParameter(p, 'Separator', '[_-]', @ischar)

            parse(p, conditions, labels, varargin{:})
            required = p.Results.Required;
            sep = p.Results.Separator;

            labels_rg = '';
            subst = cell(0,2);

            for cond = conditions
                cond = cond{1};

                labels_rg = strcat(labels_rg, '(?<', cond, '>');

                tmp = struct2cell(getfield(labels, cond));
                labels_rg = strcat(labels_rg, strjoin({ tmp{2,:} }, '|'));

                if any(strcmp(required,cond))
                    optchar = '';
                else
                    optchar = '?';
                end

                labels_rg = strcat(labels_rg, ')', optchar, sep, '?');

                for i = 1:length(getfield(labels, cond))
                    condpair = getfield(labels, cond);
                    condlabel = getfield(condpair(i), 'from');
                    if ~isempty(condlabel)
                        if isa(condlabel, 'char')
                            altlabels = {condlabel};
                        else
                            altlabels = condlabel;
                        end
                        subst = [ subst; { strcat('(?:', strjoin(altlabels, '|'), ')'), ...
                            getfield(condpair(i), 'to') } ];
                    end
                end
            end

            obj = TrialConditions(conditions, required, labels_rg, subst);
        end
    end
end
