classdef TrialConditions
  % TRIALCONDITIONS  Defines the names and levels of experimental conditions.
  %
  % See also TrialConditions.generate

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
    % GENERATE  Define the names of experimental `conditions` (aka factors) and the
    % possible `labels` (aka levels) within each condition. Conditions are determined from the
    % absolute path of potential sources.
    %
    % trialconds = generate(conditions, labels)
    % trialconds = generate(conditions, labels, Name, Value)
    %
    % # Input arguments
    %
    % - `conditions` is a cell array of condition names (eg `{'medication', 'dose'}`)
    % in the order they must appear in the file paths of trial sources
    % - `labels` is a struct with a field for each condition name (eg `isfield(labels,
    % 'medication')`). Each condition must be a a struct with a 'to' field which
    % contains a cell array of the acceptable labels. A 'from' field in the struct is used
    % to match non-standard labels and convert to the standard form (e.g. typos,
    % inconsistent capitalization, etc).
    %
    % # Name-value arguments
    %
    % - `'Required'` (defaults to all conditions): The conditions which every trial must
    % have (in the case of some trials having optional/additional conditions).
    % - `'Separator'` (defaults to `'[_-]'`): The character separating condition labels
    %
    % # Examples
    %
    % ```matlab
    % labels.session(1).to = '\d';
    % labels.stim(1).to = 'stim';
    % labels.stim(2).to = 'placebo';
    % % or equivalently:
    % labels.session.to = '\d';
    % labels.stim = struct('to', { 'stim'; 'placebo' });
    %
    % conds = TrialConditions.generate({'session';'stim'}, labels)
    % ```

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

        optchar = '?';

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
