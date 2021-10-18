classdef TrialConditions
    % TrialConditions Describes the experimental conditions and the labels for levels within each condition.

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
                obj.subst = subst;
            end
        end
    end

    methods(Static)
        function obj = generate(conditions, labels, varargin)
        % GENERATE  Describes the experimental conditions and the labels for levels within each condition.
        %
        % # Arguments
        %
        % - `conditions` is a cell array of condition names (eg `{'medication', 'strength'}`)
        % - `labels` is a struct with a field for each condition name (eg `isfield(labels, 'medication')`).
        %   Each condition field must have 'to' and 'from' fields which contain the final names and all the name possibilities, respectively.
        %   The 'from' field is is optional if the terminology in the filenames is the desired terminology.
        %
        % # Optional arguments
        %
        % - 'Required' (defaults to all conditions): The conditions which every trial must have (in the case of some
        %   trials having optional/additional conditions).
        % - 'Separator' (defaults to '[_-]'): The character separating condition labels

            p = inputParser;
            addRequired(p, 'conditions', @iscell)
            addRequired(p, 'labels', @isstruct)
            addParameter(p, 'Required', conditions, @iscell)
            addParameter(p, 'Separator', '[_-]', @ischar)

            parse(p, conditions, labels, varargin{:})
            required = p.Results.Required;
            sep = strcat(p.Results.Separator, '?');

            labels_rg = '';
            subst = cell(0,2);

            for condi = 1:length(conditions)
                cond = conditions{condi};

                labels_rg = strcat(labels_rg, '(?<', cond, '>');

                if ~isfield(labels, cond)
                    error('Error: ''%s'' was not found in ''labels''', cond)
                end
                if ~isfield(labels.(cond), 'to')
                    error('Error: ''to'' was not found in ''labels.%s''', cond)
                end

                labels_rg = strcat(labels_rg, strjoin({ labels.(cond).('to') }, '|'));

                if any(strcmp(required,cond))
                    optchar = '';
                else
                    optchar = '?';
                end

                if condi == length(conditions)
                    SEP = '';
                else
                    SEP = sep;
                end

                labels_rg = strcat(labels_rg, ')', optchar, SEP);

                for i = 1:length(labels.(cond))
                    condpair = labels.(cond);
                    if isfield(condpair(i), 'from')
                        condlabel = condpair(i).('from');
                        if ~isempty(condlabel)
                            if isa(condlabel, 'char')
                                altlabels = {condlabel};
                            else
                                altlabels = condlabel;
                            end
                            subst = [ subst; { strcat('(?:', strjoin(altlabels, '|'), ')'), ...
                                condpair(i).('to') } ];
                        end
                    end
                end
            end

            obj = TrialConditions(conditions, required, labels_rg, subst);
        end
    end
end
