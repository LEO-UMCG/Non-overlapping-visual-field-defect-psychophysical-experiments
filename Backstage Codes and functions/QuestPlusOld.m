classdef QuestPlusOld < handle
    % Matlab implementation of Andrew Watson's QUEST+ algorithm for
    % efficient & flexible adaptive psychophysical parameter estimation.
    %
    %   >>> How to use:
    %   For examples of use, see QuestPlus.runExample()
    %
    %   >>> Background Info:
    %   QUEST+ is highly efficient, as it uses the concept of entropy to
    %   determine the most informative point to test on each successive
    %   trial.
    %   QUEST+ is also highly flexible since, unlike ordinary QUEST, the
    %   user is no longer limited to estimating a single parameter. A
    %   multiparameter model can therefore be specified (e.g., both the
    %   mean and slope of the psychometric function, or as with the
    %   3-paramter tCSF). When using higher-dimensional searchspaces there
    %   may, however, be a noticable lag when initialising the QuestPlus
    %   object, since all possible likelihoods (conditional probabilities
    %   of each outcome at each stimulus value for each parameter value) is
    %   computed/cached. Higher dimensional search spaces also require more
    %   trials to converge on precise estimates, obviously.
    %   Like QUEST, a prior can be specified to help constrain the search
    %   space, potentially making estimates faster and more precise.
    %   (Though if the prior is inappropriate then this may introduce
    %   bias).
    %
    %   >>> Disclaimer:
    %   This software is provided as-is, and I (PRJ) have done relatively
    %   little testing/debugging. Please let me know if you spot any
    %   errors, or can suggest any improvements (<petejonze@gmail.com>).
    %
    %   >>> For further info, and to cite:
    %   Watson (in press): "QUEST+: a general multidimensional Bayesian
    %      adaptive psychometric method"
    %
    % QuestPlus Methods:
    %   * QuestPlus         - QuestPlus Constructor.
    %   * initialise        - Set priors and cache/compute likelihoods.
    %   * setStimSelectOpt  - Set and validate stimulus selection option (Expert users only).
    %   * getTargetStim     - Get target level(s) to present to the observer.
    %   * update            - Update the posterior, based on the presented stimulus level and observed outcome and stimulus location.
    %   * isFinished        - Evaluate the stopRule: return TRUE if QUEST+ if complete, FALSE otherwise.
    %   * getParamEsts      - Compute parameter estimates, using the specified rule (mean, median, mode).
    %   * disp              - Print to console info regarding the internal state of the current Quest+ object.
    %
    % Public Static Methods:
    %   * runExample	- Minimal-working-example(s) of usage
    %
    % Examples of use:
    %   QuestPlus.runExample(1)
    %   QuestPlus.runExample(2)
    %   QuestPlus.runExample(3)
    %   QuestPlus.runExample(4)
    %   QuestPlus.runExample(5)
    %   QuestPlus.runExample(6)
    %   QuestPlus.runExample(7)
    %
    % Author:
    %   Pete R Jones <petejonze@gmail.com>
    %
    % Verinfo:
    %   0.0.1	PJ	30/06/2016 : first_build\n
    %   0.0.2	PJ	01/08/2016 : completed core functionality, and added documentation\n
    %   0.0.3	PJ	09/10/2016 : fixed error in calculation of posterior PDFs (now properly replicates Watson's examples\n
    %   0.0.4	PJ	11/11/2016 : Correcting bugs pointed out by Josh\n
    %
    % @todo allow for non-precomputed-target-stimuli in update?
    % @todo allow for target stimuli to be constrained to not fall more
    %       than X/Y from previous, or to fall within X/Y of prescribed values
    % @todo could add a single-precision mode for if greater
    %       speed/optimisation is absolutely required
    % @todo changing priors shouldnt affect loading in old likelihoods?
    %
    % Copyright 2016 : P R Jones <petejonze@gmail.com>
    % *********************************************************************
    %

    %% ====================================================================
    %  -----PROPERTIES-----
    %$ ====================================================================      

    properties (GetAccess = public, SetAccess = private)
        % mandatory user-specified parameters, set when creating QuestPlus object
        F               % The function / underlying model, which will be attempting to estimate the parameters for
        stimDomain      % Vector/Matrix of possible values over which the function, F, will be analysed. Each variable is a different column, such that domain is an [m n] matrix, where each m is a value, and each n is a variable (NB: currently entered by the user as a list of vectors, before being converted into a matrix)
        paramDomain     % Vector/Matrix of possible stimulus values  (NB: currently entered by the user as a list of vectors, before being converted into a matrix)
        respDomain      % Vector of possible observer response value

        % optional user-specified parameters, set when creating QuestPlus object
        stopRule            = 'entropy' % 'stdev' | 'ntrials' | 'entropy'
        stopCriterion     	= 3         % Value for stopRule: either num presentation (N), or Entropy (H)
        minNTrials          = 0         % minimum number of trials before isFin==true
        maxNTrials          = inf       % maximum number of trials before isFin==true
        
        % advanced target-stimulus selection option, set using setStimSelectOpt()
        stimSelectionMethod  	= 'min'; % Options: 'min' | 'weighted' | 'percentile' | 'minOrRand'
        stimSelectionParam  	= 2;
        stimConstrainToNOfPrev  = []; % in units of 'domain index' 
        
        % computed variables, set when using initialise()
        prior               % vector, containing probability of each parameter-combination
        likelihoods        	% 2D matrix, containing conditional probabilities of each outcome at each stimulus-combination/parameter-combination
        posterior          	% posterior probability distribution over domain.
        
        % measured variables, updated after each call to update()
        history_stim        = []        % vector of stims shown
        history_resp        = []        % vector of responses (1 HIT, 0 MISS)
    end

    
 	%% ====================================================================
    %  -----PUBLIC METHODS-----
    %$ ====================================================================
    
    methods (Access = public)
        
        %% == CONSTRUCTOR =================================================
        
        function obj = QuestPlus(F, stimDomain, paramDomain, respDomain, stopRule, stopCriterion, minNTrials, maxNTrials)
            % QuestPlus Constructor.
            %
            %   Create a new QuestPlus object. Note that this object must
            %   then be explictly initialised before usage.
            %
            % @param    F               function handle for the model that we are attempting to for the parameters of.
            %                             E.g.: F = @(x,mu)([1-normcdf(x,mu,1),normcdf(x,mu,1)])';
            % @param    stimDomain      Vector(s) of possible values over which the function, F, will be analysed. Each variable should be a row vector. If entering multiple vectors, each should be an element in a cell array.
            %                             E.g.: stimDomain = linspace(-1, 10, 50);
            %                             E.g.: stimDomain = {linspace(-1,10,50), linspace(5,40,20)};
            % @param    paramDomain     Vector(s) of possible stimulus values. Each variable should be a row vector. If entering multiple vectors, each should be an element in a cell array.
            %                             E.g.: paramDomain = linspace(-5,5,100);
            %                             E.g.: paramDomain = {linspace(-5,5,50), linspace(.01,3,45)};
            % @param    respDomain      Vector of possible observer response value.
            %                             E.g.: respDomain = [0 1];
            % @param    stopRule        How to determine if the QUEST+ algorithm is complete. Either: 'stdev' | 'ntrials' | 'entropy'. Stdev only permitted in the simple, 1-parameter, case
            %                             E.g.: stopRule = 'stdev'
            %                             Default: 'entropy'            
            % @param    stopCriterion   The criterion for the specified rule. Typically around 1.5 for stdev, 3 for entropy, or 64 for ntrials.
            %                             E.g.: stopCriterion = 1.5
           	%                             Default: 3
            % @param    minNTrials      Minimum N trials before registering as complete. Zero to use the stopRule only to assess completion.
            %                             E.g.: minNTrials = 32
            %                             Default: 0            
            % @param    maxNTrials      Maximum N trials, after which will register as complete. Inf to use the stopRule only to assess completion.
            %                             E.g.: maxNTrials = 128
            %                             Default: inf 
            % @return   QuestPlus       QuestPlus object handle
            %
            % @date     01/08/16
            % @author   PRJ
            %
            % %todo:    check F is a well formed CDF (?)
            %
            
            % ensure inputs are cells, for consistency (format required if
            % inputting multiple vectors)
            if ~iscell(stimDomain)
                stimDomain = {stimDomain};
            end
            if ~iscell(paramDomain)
                paramDomain = {paramDomain};
            end
            
            % validate mandatory inputs 
            if ~isa(F,'function_handle')
                error('F must be a function handle');
            end
            if nargin(F) ~= (length(stimDomain)+length(paramDomain))
                error('domains must contain one cell entry for each parameter of F');
            end
            
            % set mandatory inputs
            obj.F           = F;
            obj.stimDomain  = CombVec(stimDomain{:});   % convert to matrix
            obj.paramDomain = CombVec(paramDomain{:});  % convert to matrix
            obj.respDomain  = respDomain;

            % parse optional inputs
            if nargin >= 5 && ~isempty(stopRule),           obj.stopRule = lower(stopRule);     end
            if nargin >= 6 && ~isempty(stopCriterion),   	obj.stopCriterion = stopCriterion;  end
            if nargin >= 7 && ~isempty(minNTrials),         obj.minNTrials = minNTrials;       	end
            if nargin >= 8 && ~isempty(maxNTrials),         obj.maxNTrials = maxNTrials;       	end

            % if stop rule is 'ntrials', then ensure that nTrials are set
            % appropriately, and that all request parameters are consistent
            if strcmpi(stopRule, 'ntrials')
                if nargin >= 7 && ~isempty(minNTrials) && stopCriterion ~= minNTrials
                    error('If stop rule is "ntrials" then stop criterion (%i) must match requested minNTrials (%i) -- or just don''t bother setting it minNTrials, as it''s redundant when stop rule is "ntrials"', stopCriterion, minNTrials);
                elseif nargin >= 8 && ~isempty(maxNTrials) && stopCriterion ~= maxNTrials
                    error('If stop rule is "ntrials" then stop criterion (%i) must match requested maxNTrials (%i) -- or just don''t bother setting it minNTrials, as it''s redundant when stop rule is "ntrials"', stopCriterion, maxNTrials);
                end
                obj.minNTrials = stopCriterion;
                obj.maxNTrials = stopCriterion;
            end
            
            % validate params
            if ~ismember(obj.stopRule, {'ntrials', 'stdev', 'entropy'})
                error('QuestPlus:Constructor:InvalidInput', 'stopRule (%s) must be one of "ntrials", "stdev", or "entropy"', obj.stopRule);
            end
            if strcmpi(obj.stopRule,'stdev') && size(obj.paramDomain,1)>1
                error('Stdev only defined for one dimensional search spaces. Use entropy or ntrials instead.\n');
            end
            if strcmpi(obj.stopRule,'ntrials') && obj.maxNTrials~=obj.stopCriterion
                warning('Parameter mismatch. Overwriting the maximum number of trials with the stopCriterion specified number of %i trials\n', obj.maxNTrials, obj.stopCriterion);
                obj.stopCriterion = obj.maxNTrials;
            end
            if obj.maxNTrials < obj.minNTrials
                error('minNTrials (%i) cannot exceed maxNTrials (%i)', minNTrials, maxNTrials);
            end
        end
        
        %% == METHODS =================================================
        
        function [] = initialise(obj, priors, likelihoodsFn)
            % Set priors and cache/compute likelihoods.
            %
            %   NB: Currently priors for each parameter are assumed to be
            %   independent. In future, could allow priors to be a full
            %   matrix, including covariation.
            %
            % @param    priors          ######.
            % @param    likelihoodsFn   ######.
            %
            % @date     01/08/16
            % @author   PRJ
            %
            
            % if no priors specified, initialise all as uniform
            if nargin<2 || isempty(priors)
                n = size(obj.paramDomain,1);
                warning('No priors specified, will set all %i PDFs to be uniform over their respective domains', n);
                priors = cell(1, n);
                for i = 1:n
                    nn = length(unique(obj.paramDomain(i,:)));
                    priors{i} = ones(1,nn)/nn;
                end
            end
            
            % if a likelihood file has been specified, will load
            % precomputed likelihood values from there, rather than
            % recomputing them here (which can be an extremely expensive
            % operation)
            precomputedLikelihoods = [];
            if nargin>=3 && ~isempty(likelihoodsFn)
                % console message
                fprintf('Loading precomputed likelihoods from file..\n');
                
                % check file exists
                if ~exist(likelihoodsFn, 'file')
                    error('Specified likelihoods file not found: %s', likelihoodsFn);
                end
                
                % load
                dat = load(likelihoodsFn);
                
                % check content is well-formed
                if ~all(ismember({'stimDomain','paramDomain','respDomain','likelihoods'}, fieldnames(dat)))
                   tmp = fieldnames(dat); 
                   error('The following error was detected when attempting to load the precomputed likelihoods in %s:\n\n   File content not well formed.\n\n   Expected fieldnames: stimDomain,paramDomain,respDomain,likelihoods\n   Detected fieldnames: %s', likelihoodsFn, sprintf('%s, ', tmp{:}) );
                end
                
                % check dimensions match current QUEST+ object
                if ~all(size(dat.stimDomain) == size(obj.stimDomain))
                    error('The following error was detected when attempting to load the precomputed likelihoods in %s:\n\n   Stimulus domain size mismatch.\n   Expected Dimensions: [%s]\n   Detected Dimensions: [%s]', likelihoodsFn, sprintf('%i, ',size(obj.stimDomain)), sprintf('%i, ',size(dat.stimDomain)));
                elseif ~all(size(dat.paramDomain) == size(obj.paramDomain))
                    error('The following error was detected when attempting to load the precomputed likelihoods in %s:\n\n   Parameter domain size mismatch.\n   Expected Dimensions: [%s]\n   Detected Dimensions: [%s]', likelihoodsFn, sprintf('%i, ',size(obj.paramDomain)), sprintf('%i, ',size(dat.paramDomain)));
                elseif ~all(size(dat.respDomain) == size(obj.respDomain))
                    error('The following error was detected when attempting to load the precomputed likelihoods in %s:\n\n   Response domain size mismatch.\n   Expected Dimensions: [%s]\n   Detected Dimensions: [%s]', likelihoodsFn, sprintf('%i, ',size(obj.respDomain)), sprintf('%i, ',size(dat.respDomain)));
                end
               	% check contents match current QUEST+ object
                if ~all(dat.stimDomain(:) == obj.stimDomain(:))
                    disp(obj.stimDomain)
                    disp(dat.stimDomain)
                    error('The following error was detected when attempting to load the precomputed likelihoods in %s:\n\n   Stimulus domain content mismatch', likelihoodsFn);
                elseif ~all(dat.paramDomain(:) == obj.paramDomain(:))
                    disp(obj.paramDomain)
                    disp(dat.paramDomain)
                    error('The following error was detected when attempting to load the precomputed likelihoods in %s:\n\n   Parameter domain content mismatch', likelihoodsFn);
                elseif ~all(dat.respDomain(:) == obj.respDomain(:))
                    disp(obj.respDomain)
                    disp(dat.respDomain)
                    error('The following error was detected when attempting to load the precomputed likelihoods in %s:\n\n   Response domain content mismatch', likelihoodsFn);
                end
                
                % set
                precomputedLikelihoods = dat.likelihoods;
            end

            % ensure inputs are cells, for consistency (format required if
            % inputting multiple vectors)
            if ~iscell(priors)
                priors = {priors};
            end
            
            % check right number of priors
            if length(priors) ~= size(obj.paramDomain,1)
                error('%i arrays of priors were specified, but %i parameters were expected', length(priors), size(obj.paramDomain,1))
            end
            % check each prior contains an entry for each possible value in the domain
            for i = 1:length(priors)
                if length(priors{i}) ~= length(unique(obj.paramDomain(i,:)))
                    error('length of prior %i [%i] does not match the size of domain for that parameter [%i]', i, length(priors{i}), length(unique(obj.paramDomain(i,:))));
                end
            end
            % check each prior is a valid PDF (sums to 1)
            for i = 1:length(priors)
                if abs(sum(priors{i})-1) > 0.000000000001
                    error('QuestPlus:initialise:InternalError', 'Specified prior %i is not well formed? (does not sum up to 1)', i);
                end
            end
            % check not already initialised
            if ~isempty(obj.posterior)
                error('QuestPlus has already been initialised');
            end

            % compute prior
            x = CombVec(priors{:});  % get all combinations of priors
            x = prod(x,1);           % multiply together (assumes independence!!)
            x = x./sum(x);           % normalize so sum to 1
            obj.prior = x;

           	% Compute the likelihoods array (conditional probabilities of
           	% each outcome at each stimulus value for each parameter
           	% value).
            % Store the result in an [MxNxO] matrix, where M is
            % nStimuliCombinations, and N is nParameterCombinations, and O
            % is nResponseOutcomes

            % compute parameters for determining if capable of running a
            % quicker/vectorised caching mode
            nModelParameters = size(obj.paramDomain,1);
            nStimParameters = size(obj.stimDomain,1);
            if nModelParameters==1 && nStimParameters==1
                nFuncOutputs = numel(obj.F(obj.stimDomain, obj.paramDomain(:,1)))/numel(obj.stimDomain);
            end
            
            if ~isempty(precomputedLikelihoods)
                obj.likelihoods = precomputedLikelihoods;
            elseif length(obj.respDomain)==2 && nModelParameters==1 && nStimParameters==1 && nFuncOutputs==1
                % quick/vectorised, but only works if two response
                % alternatives, one model parameter to estimate, one
                % stimulus parameter to vary, and model has been specified
                % to only provide the conditional probability of the second
                % of the two responses (assumed to represent 'success')
                obj.likelihoods = nan(length(obj.stimDomain), length(obj.paramDomain), length(obj.respDomain));
                for j = 1:size(obj.paramDomain,2)
                    obj.likelihoods(:,j,2) = obj.F(obj.stimDomain, obj.paramDomain(j)); % P('success')
                end
                obj.likelihoods(:,:,1) = 1 - obj.likelihoods(:,:,2); % P('failure'): complement of P('success')
            else
                fprintf('Computing likelihoods.. NB: This may be slow. Consider using QP.saveLikelihoods() to save the outcome to disk, and then load in when making any future calls to QuestPlus.initialise() \n');
                x = num2cell([obj.stimDomain(:,1); obj.paramDomain(:,1)]);
                nOutputs = length(obj.F(x{:}));
                if length(obj.respDomain)==2 && nOutputs==1
                    % if response domain is binary, and function only
                    % provides one output, we'll assume that the the
                    % probability of the first resposne is the complement
                    % of the second
                    obj.likelihoods = nan(length(obj.stimDomain), length(obj.paramDomain), length(obj.respDomain));
                    for i = 1:size(obj.stimDomain,2)
                        for j = 1:size(obj.paramDomain,2)
                            x = num2cell([obj.stimDomain(:,i); obj.paramDomain(:,j)]);
                            y = obj.F(x{:});
                            obj.likelihoods(i,j,:) = [1-y; y]; % complement [backwards format versus above???]
                        end
                    end
                else
                    % slow but flexible (works for any number of
                    % parameters/response alternatives)
                    obj.likelihoods = nan(length(obj.stimDomain), length(obj.paramDomain), length(obj.respDomain));
                	% check the correct number of outputs returns
                    if nOutputs ~= size(obj.likelihoods,3)
                        error('Specified function returns %i outputs, but %i response categories are defined', nOutputs, size(obj.likelihoods,3));
                    end
                    % run
                    for i = 1:size(obj.stimDomain,2)
                        for j = 1:size(obj.paramDomain,2)
                            x = num2cell([obj.stimDomain(:,i); obj.paramDomain(:,j)]);
                            obj.likelihoods(i,j,:) = obj.F(x{:});
                        end
                    end
                    % ^^ NB: perhaps this could be vectorised further in future
                    % for speed ^^
                end
            end

            % validate check for every combination of stimuli/parameters,
            % the likelihood of all possible responses sums to 1
            if ~all(all(sum(obj.likelihoods,3)==1))
                warning('all response likelihoods must sum to 1');
            end
            
           	% set the current posterior pdf to be the prior
            obj.posterior = obj.prior;
        end
        
        function [] = setStimSelectOpt(obj, stimSelectionMethod, stimSelectionParam, stimConstrainToNOfPrev)
         	% Set and validate stimulus selection option (expert users
         	% only).
            %
            %   In most cases it should not be necessary to impose
         	%   any constraints on the target stimulus, and doing so will
         	%   decrease test efficiency [assuming an ideal observer]. Also
         	%   note that you are in either case free to disregard the
         	%   stimulus suggested by getTargetStim().
            %
            %   See comments in code for details on each option.
            %
            % @param    stimSelectionMethod     ######.
            % @param    stimSelectionParam      ######.
            % @param    stimConstrainToNOfPrev  ######.
            %
            % @date     10/10/16
            % @author   PRJ
            %
            
            % parse inputs
            if nargin < 2 || isempty(stimSelectionMethod)
                stimSelectionMethod = obj.stimSelectionMethod;
            end
            if nargin < 4 || isempty(stimConstrainToNOfPrev)
                stimConstrainToNOfPrev = obj.stimConstrainToNOfPrev;
            end
                
            % validate stimSelectionParam value
            switch lower(obj.stimSelectionMethod)
                case 'min'
                    % stimSelectionParam is ignored
                    % <do nothing>
                case 'weighted'
                    % stimSelectionParam is the exponent applied to the
                    % inverse-expected-entropy, 1/EH,m weighting.
                    % I.e.:
                    % * x must be greater than 0
                    % * x==0 means that all values will be sampled from
                    %   with equal probability, x==1 means that values will
                    %   be sampled directly in proportion to their EH value
                    %   x>1 will increasingly favour the lowest 1/EH
                    %   value(s))
                    % * recommended value: 2
                    if stimSelectionParam < 0
                        error('Invalid stimSelectionParam value ("%1.2f"), given specified selection method "%s".\nRecommended value is 2', stimSelectionParam, stimSelectionMethod);
                    end
                case 'percentile'
                    % stimSelectionParam is the percentile of 1/EH values
                    % from which the target stimulus will be drawn.
                    % I.e.:
                    % * x must be > 0 and < 1
                    % * x==0.25 means that stimulus will be drawn randomly
                    %   from the lowest 25% of EH values
                    % * recommended value: 0.1
                    if stimSelectionParam < 0 || stimSelectionParam > 1
                        error('Invalid stimSelectionParam value ("%1.2f"), given specified selection method "%s"\nRecommended value is 0.1', stimSelectionParam, stimSelectionMethod);
                    end
                case 'minorrand'
                    % stimSelectionParam is probability of ignoring the
                    % minimum entropy value, and picking a completely
                    % random value instead
                    % I.e.:
                    % * x must be > 0 and < 1
                    % * x==0.25 means that stimulus will be the
                    %   minimum-entropy value on ~75% of trials, and a
                    %   completely random value on ~25% of trials.
                    % * recommended value: 0.1
                    if stimSelectionParam < 0 || stimSelectionParam > 1
                        error('Invalid stimSelectionParam value ("%1.2f"), given specified selection method "%s"\nRecommended value is 0.1', stimSelectionParam, stimSelectionMethod);
                    end
                otherwise
                    error('Stimulus Selection Method not recognised: "%s"', obj.stimSelectionMethod); % defensive
            end
            
            % further checks
            if ~isempty(stimConstrainToNOfPrev)% && size(obj.stimDomain,1)>1
                if ~iscolumn(stimConstrainToNOfPrev)
                    % warning('stimConstrainToNOfPrev should be a column vector. Correcting')
                    stimConstrainToNOfPrev = stimConstrainToNOfPrev(:);
                end
                if size(stimConstrainToNOfPrev,1) ~= size(obj.stimDomain, 1)
                    error('Dimension mismatch: %i stimulus domains, but only %i constraints specified.', size(obj.paramDomain, 1), length(stimConstrainToNOfPrev));
                end
                if any(mod(stimConstrainToNOfPrev,2))~=1 || any(stimConstrainToNOfPrev<1)
                    error('stimConstrainToNOfPrev (%1.2f) must be an integer, and greater than 0\n', stimConstrainToNOfPrev);
                end
            end
            
            % set values
            obj.stimSelectionMethod     = stimSelectionMethod;
            obj.stimSelectionParam      = stimSelectionParam;
            obj.stimConstrainToNOfPrev  = stimConstrainToNOfPrev;
        end
        
        function [stim, idx] = getTargetStim(obj)
            % Get target level(s) to present to the observer.
            %
            %   NB: targets are rounded to nearest domain entry
            %
            % @return   stim	stimulus target value, to present
            % @return   idx   	index of target value, in stimDomain
            %
            % @date     01/08/16
            % @author   PRJ
            %

          	% check initialised
            if isempty(obj.posterior)
                error('QuestPlus has not yet been initialised');
            end

            % Compute the product of likelihood and current
            % posterior array, at each outcome and stimulus
            % location.
            postTimesL = bsxfun(@times, obj.posterior, obj.likelihoods); % newPosteriors:[nStims nParams nResps]

            % Compute the (total) probability of each outcome at each
            % stimulus location.
            pk = sum(postTimesL,2); % pk:[nStims 1 nResps]
            
            % Computer new posterior PDFs, by normalising values so that
            % they sum to 1
            newPosteriors = bsxfun(@rdivide, postTimesL, sum(postTimesL,2));
            
            % Compute the the entropy that would result from outcome r at stimulus x,
            H = -nansum(newPosteriors .* log(newPosteriors), 2); % H:[nStims 1 nResps] -- NB: nansum, since if any newPosteriors==0, then log2(newPosteriors)==-inf, and 0*-inf is NaN
            % ALT: H = -sum(newPosteriors .* log(newPosteriors+realmin), 2); % ~20% quicker than using nansum (tested MACI64, using qCSF_v1.m), but can result in NaN values

            % Compute the expected entropy for each stimulus
            % location, summing across all responses (Dim 3)           
            EH = sum(pk.*H, 3); % EH:[nStims 1]

            % select stimulus
            switch lower(obj.stimSelectionMethod)
                case 'min'
                    % Find the index of the stimulus with the smallest
                    % expected entropy.
                    [~,idx] = min(EH);
                case 'weighted'
                    % Pick a stimulus using a weighted-random-draw, with
                    % weights proportional to inverse-exepcted-entropy
                    % (1/EH)
                    idx = randsample(1:length(EH), 1, true, (1./EH).^obj.stimSelectionParam);
                case 'percentile'                   
                    % Pick a random stimulus from the lowest X percentile
                    % of expected-entropy values
                    idx = randsample(1:length(EH), 1, true, EH < prctile(EH, obj.stimSelectionParam));
                case 'minorrand'
                    % With a probability of P, ignore the minimum entropy
                    % value, and pick another value completely at random
                    % (uniform probability)
                    idx    = randsample(1:length(EH), 1, true, (EH==min(EH))*obj.stimSelectionParam + (1-obj.stimSelectionParam)/(length(EH)-1)*(EH~=min(EH)));
                otherwise
                    error('Stimulus Selection Method not recognised: "%s"', obj.stimSelectionMethod); % defensive
            end

            % Set the next stimulus location to the location of the
            % smallest expected entropy.
            stim = obj.stimDomain(:,idx);

            % constrain selection if required (and if not on first trial)
            % -- new method, based on actual domain-entry units
            if ~isempty(obj.stimConstrainToNOfPrev) && ~isempty(obj.history_stim)
                % get values, and ensure column vectors
                prevStim = obj.history_stim(:,end);

                for i = 1:size(obj.stimDomain,1)
                    % extract unique values for this parameter
                    domain = unique(obj.stimDomain(i,:));
                    
                    % find nearest domain entry of previous stimulus
                    [~,idx0] = min(abs(domain-prevStim(i)));

                    % find equivalent target index in unique domain
                    targIdx = find(domain==stim(i));
                    
                    % if the target (e.g., minimum-entropy) stimulus change is
                    % greater than that permitted, truncate the step to be the
                    % greatest permitted
                    if abs(targIdx-idx0) > obj.stimConstrainToNOfPrev(i)
                        idx1 = idx0 + sign(targIdx-idx0) * obj.stimConstrainToNOfPrev(i);
                        stim(i) = domain(idx1);
                    end
                end
            end 
        end

        function [] = update(obj, stim, resp)
            % Update the posterior, based on the presented stimulus level
            % and observed outcome and stimulus location.
            %
            %   To do this, we multiply the existing posterior density (on
            %   trial k) by the likelihood of observing the outcome (on
            %   trial k+1).
            %
            % @param    stim  stimulus value(s).
            % @param    resp  response value.
            %
            % @date     01/08/16
            % @author   PRJ
            %
            
            % Get stimIdx, check valid
            stimIdx = all(bsxfun(@eq, stim, obj.stimDomain),1);
            if sum(stimIdx)~=1
                obj.stimDomain
                error('Stimulus "%1.2f" not recognised? (not found in stimDomain)', stim);
            end
            % Get respIdx, check valid
            respIdx = resp==obj.respDomain;
            if sum(stimIdx)~=1
                error('Response not recognised? (not found in respDomain)');
            end
            
            % Update posterior PDF (assuming trial-by-trial independence)
            obj.posterior = obj.posterior .* obj.likelihoods(stimIdx, :, respIdx);

            % renormalise posterior PDF so that it sums to 1
            obj.posterior = obj.posterior/sum(obj.posterior);
            
            % store vals for convenience
            obj.history_stim(:,end+1) = stim;
            obj.history_resp(end+1) = resp;
        end

        function isFin = isFinished(obj)
            % Evaluate the stopRule: return TRUE if QUEST+ if complete,
            % FALSE otherwise.
            %
            % @return   isFin   TRUE is routine is finished.
            %
            % @date     01/08/16
            % @author   PRJ
            %
            
            % Set to be never finished if not reached minimum number of
            % trials, and always finished if reached maximum number of
            % trials...
            nTrials = obj.nTrialsCompleted();      
            if nTrials < obj.minNTrials
                isFin = false;
                return;
            elseif nTrials >= obj.maxNTrials
                isFin = true;
                return;
            end

            % ...otherwise, for intermediate numbers of trials, determine
            % completion based on specified metric/criterion:
            switch lower(obj.stopRule)
                case 'stdev'
                    isFin = obj.stdev() <= obj.stopCriterion;
                case 'entropy'
                    isFin = obj.entropy() <= obj.stopCriterion;
                case 'ntrials'
                    isFin = false; %<do nothing> [already covered, above]
                otherwise % defensive
                    error('stopType not recognised: %s', obj.stopRule);
            end
        end

        function ests = getParamEsts(obj, thresholdingRule, roundStimuliToDomain)
            % Compute parameter estimates, using the specified rule (mean,
            % median, mode).
            %
            % @param    thresholdingRule    'mean', 'median', or 'mode'.
            %                               Recommended: 'mean'
            % @return   ests                Scalar estimates for each parameter
            %
            % @date     01/08/16
            % @author   PRJ
            %            
            
            % parse inputs: if not specified, values will be rounded to
            % nearest domain element
            if nargin<3 || isempty(roundStimuliToDomain)
                roundStimuliToDomain = true;
            end

            switch lower(thresholdingRule)
                case 'mean'
                    if ~roundStimuliToDomain
                        ests = sum(bsxfun(@times, obj.posterior, obj.paramDomain), 2);
                        return
                    else
                        [~,paramIdx] = min(sqrt(mean(bsxfun(@minus, obj.paramDomain, sum(bsxfun(@times, obj.posterior, obj.paramDomain), 2)).^2,1)));
                    end
                case 'median'  % same irrespective of roundStimuliToDomain
                    [~,paramIdx] = min(abs(cumsum(obj.posterior) - 0.5));
                case 'mode'  % same irrespective of roundStimuliToDomain
                    [~,paramIdx] = max(obj.posterior);
                otherwise
                    error('QuestPlus:getParamEsts:unknownInput', 'specified thresholdingRule ("%s") not recognised.\nMust be one of: "mean" | "median" | "mode"', thresholdingRule)
            end
            
            % get threshold estimate
            ests = obj.paramDomain(:,paramIdx);
        end
        
        function [] = saveLikelihoods(obj, fn)
            % Export likelihoods matrix to .mat file
            %
            % @date     03/10/16
            % @author   PRJ
            %
            
            % use generic file name in local directory, if none specified
            if nargin<2 || isempty(fn)
                fn = sprintf('./QuestPlus_likelihoods_%s.mat', datestr(now(),30));
            end
            
            % construct
            dat = struct();
            dat.stimDomain  = obj.stimDomain;
            dat.paramDomain = obj.paramDomain;
            dat.respDomain  = obj.respDomain;
            dat.likelihoods = obj.likelihoods; %#ok (saved below)
            
            % save to disk
            save(fn, '-struct', 'dat')
        end
        
        function [] = disp(obj)
            % Print to console info regarding the internal state of the
            % current Quest+ object.
            %
            %   NB: Uses fprintf to write to current print feed, so the
            %   output could in principle be rerouted to an offline log
            %   file.
            %
            % @date     01/08/16
            % @author   PRJ
            %
            fprintf('------------------------\nQUEST+ Properties:\n------------------------\n');
            fprintf('     stopRule: %s\n',      obj.stopRule);
            fprintf('stopCriterion: %1.2f\n',   obj.stopCriterion);
            fprintf('   minNTrials: %i\n',      obj.minNTrials);
            fprintf('   maxNTrials: %i\n',      obj.maxNTrials);
            fprintf('------------------------\nHistory:\n------------------------\n');
            fprintf('     stimulus: %s\n',      sprintf('%6.2f, ', obj.history_stim));
            fprintf('     response: %s\n',      sprintf('%6.2f, ', obj.history_resp));  
            fprintf('------------------------\nCurrent Param Estimates:\n------------------------\n');
            est_mean = obj.getParamEsts('mean');
            est_median = obj.getParamEsts('median');
            est_mode = obj.getParamEsts('mode');
            for i = 1:length(est_mean)
                fprintf('Parameter %i of %i\n', i, length(est_mean));
                fprintf('         Mean: %1.2f\n', est_mean(i));
                fprintf('       Median: %1.2f\n', est_median(i));
                fprintf('         Mode: %1.2f\n', est_mode(i));
            end
            fprintf('------------------------\nCurrent State:\n------------------------\n');
            fprintf('     Finished: %g\n',  	obj.isFinished());
            fprintf('N Trials Done: %i\n',  	obj.nTrialsCompleted());
            fprintf('      Entropy: %1.2f\n',	obj.entropy());
            if size(obj.paramDomain,1)>1
                fprintf('      Std Dev: N/A\n');
            else
                fprintf('      Std Dev: %1.2f\n',  obj.stdev());
            end
        end

    end

 	%% ====================================================================
    %  -----PRIVATE METHODS-----
    %$ ====================================================================
    
    methods (Access = private)
        
        function n = nTrialsCompleted(obj)
            % Compute n trials responded to (internal helper function).
            n = length(obj.history_stim);
        end
        
        function sd = stdev(obj)
            % Compute pdf standard deviation (internal helper function).
            sd = sqrt(sum(obj.posterior .* obj.paramDomain .* obj.paramDomain) - sum(obj.posterior .* obj.paramDomain)^2);
        end
        
        function H = entropy(obj)
            % Compute pdf entropy (internal helper function).
            H = -nansum(obj.posterior .* log2(obj.posterior), 2);
        end
        
    end
    
    

   	%% ====================================================================
    %  -----STATIC METHODS (public)-----
    %$ ====================================================================
      
    methods (Static, Access = public)

        function QP = runExample(exampleN)
            % Examples of use, demonstrating/testing key functionalities.
            % Examples include:
            %   1. Simple, 1D case
            %   2. 1D with dynamic stopping
            %   3. 1D with dynamic stopping & faster initialisation
            %   4. More complex, 2D case
            %   5. More complex, 2D case, with non-uniform prior
            %   6. A direct example from P7 of Watson's original paper
            %   7. quick CSF (requires external function qCSF_getPC.m)  
            %
            % @param    exampleN	Example to run [1|2|3|4|5|6|7]. Defaults to 1.
            %
            % @date     26/06/14
            % @author   PRJ
            %
            
            % suppress warnings in editor of the form "There is a property
            % named X. Did you mean to reference it?"
            %#ok<*PROP>
             
            % parse inputs: if no example specified, run example 1
            if nargin<1 || isempty(exampleN)
                exampleN = 1;
            end

            % run selected example
            switch exampleN
                case 1 % Simple, 1D case
                    % set model
                    F = @(x,mu)([1-normcdf(x,mu,1),normcdf(x,mu,1)])';
                    % set true param(s)
                    mu = 7;
                    trueParams = {mu};
                    % create QUEST+ object
                    stimDomain = linspace(-10, 10, 50);
                    paramDomain = linspace(-8,8,30);
                    respDomain = [0 1];
                    QP = QuestPlus(F, stimDomain, paramDomain, respDomain, [],2.5);
                    % initialise (with default, uniform, prior)
                    QP.initialise();
                    % run
                    startGuess_mean = QP.getParamEsts('mean');
                    startGuess_mode = QP.getParamEsts('mode');        
                    while ~QP.isFinished()
                        targ = QP.getTargetStim();
                        tmp = F(targ,mu);
                        pC = tmp(2);
                        anscorrect = rand()<pC;
                        QP.update(targ, anscorrect);
                    end
             
                    % get final parameter estimates
                    endGuess_mean = QP.getParamEsts('mean');
                    endGuess_mode = QP.getParamEsts('mode');
                case 2 % 1D with dynamic stopping, explicit priors, and stimulus constraints
                    % set model
                    F = @(x,mu)([1-normcdf(x,mu,1),normcdf(x,mu,1)])';
                    % set true param(s)
                    mu = 2;
                    trueParams = {mu};
                    % create QUEST+ object
                    stimDomain      = linspace(-1, 10, 50);
                    paramDomain     = linspace(-5,5,100);
                    respDomain    	= [0 1];
                    stopRule       	= 'entropy';    % try changing
                    stopCriterion  	= 3;            % try changing
                    minNTrials    	= 10;           % try changing
                    maxNTrials   	= 512;          % try changing
                    QP = QuestPlus(F, stimDomain, paramDomain, respDomain, stopRule, stopCriterion, minNTrials, maxNTrials);
                 	% construct prior(s)
                  	% priors = ones(1,length(paramDomain))/length(paramDomain); % uniform
                    priors = normpdf(paramDomain, mu, 1); % non-uniform
                    priors = priors./sum(priors);
                    % initialise priors/likelihoods
                    QP.initialise(priors)
                    % constrain target stimulus
                    QP.setStimSelectOpt('min', [], 3);
                    % run
                    startGuess_mean = QP.getParamEsts('mean');
                    startGuess_mode = QP.getParamEsts('mode');
                    while ~QP.isFinished()
                        fprintf('. ');
                        targ = QP.getTargetStim();
                        anscorrect = (targ+randn()*1) > mu;
                        QP.update(targ, anscorrect);
                    end
                    % get final parameter estimates
                    endGuess_mean = QP.getParamEsts('mean');
                    endGuess_mode = QP.getParamEsts('mode');                    
                case 3 % 1D with dynamic stopping & faster initialisation
                    % set model
                    F = @(x,mu)(1-normcdf(x,mu,1))'; % only pass in the probability of respDomain(1). Saves approx 0.1 seconds in this simple case - but this can be substantial when running simulations(!)
                    % set true param(s)
                    mu = 2;
                    trueParams = {mu};
                    % create QUEST+ object
                    stimDomain      = linspace(-1, 10, 50);
                    paramDomain     = linspace(-5,5,100);
                    respDomain    	= [0 1];
                    stopRule       	= 'entropy';    % try changing
                    stopCriterion  	= 3;            % try changing
                    minNTrials    	= 10;           % try changing
                    maxNTrials   	= 512;          % try changing
                    QP = QuestPlus(F, stimDomain, paramDomain, respDomain, stopRule, stopCriterion, minNTrials, maxNTrials);
                    % initialise priors/likelihoods
                    priors = ones(1,length(paramDomain))/length(paramDomain);
                    QP.initialise(priors)
                    % run
                    startGuess_mean = QP.getParamEsts('mean');
                    startGuess_mode = QP.getParamEsts('mode');
                    while ~QP.isFinished()
                        fprintf('. ');
                        targ = QP.getTargetStim();
                        anscorrect = (targ+randn()*1) > mu;
                        QP.update(targ, anscorrect);
                    end
                    % get final parameter estimates
                    endGuess_mean = QP.getParamEsts('mean');
                    endGuess_mode = QP.getParamEsts('mode');
                case 4 % More complex, 2D case
                    % set model
                    F = @(x,mu,sigma)([1-normcdf(x,mu,sigma),normcdf(x,mu,sigma)])';
                    % set true param(s)
                    mu = 4;
                    sigma = 2;
                    trueParams = {mu, sigma};
                    % create QUEST+ object
                    stimDomain = linspace(0, 40, 30);
                    paramDomain = {linspace(-5,5,20), linspace(.01,3,25)};
                    respDomain = [0 1];
                    QP = QuestPlus(F, stimDomain, paramDomain, respDomain);
                    % initialise priors/likelihoods
                    priors = {ones(1,length(paramDomain{1}))/length(paramDomain{1}), ones(1,length(paramDomain{2}))/length(paramDomain{2})};
                    QP.initialise(priors)
                    % run
                    startGuess_mean = QP.getParamEsts('mean');
                    startGuess_mode = QP.getParamEsts('mode');
                    while ~QP.isFinished()
                        targ = QP.getTargetStim();
                        anscorrect = normrnd(targ,sigma) > mu;
                        QP.update(targ, anscorrect);
                    end
                    % get final parameter estimates
                    endGuess_mean = QP.getParamEsts('mean');
                    endGuess_mode = QP.getParamEsts('mode');
                case 5 % More complex, 2D case, with non-uniform prior
                    % set model
                    F = @(x,mu,sigma)([1-normcdf(x,mu,sigma),normcdf(x,mu,sigma)])';
                    % set true param(s)
                    mu = 4;
                    sigma = 2;
                    trueParams = {mu, sigma};
                    % create QUEST+ object
                    stimDomain      = linspace(0, 40, 30);
                    paramDomain     = {linspace(-5,5,25), linspace(.01,3,25)};
                    respDomain      = [0 1];                   
                    stopRule     	= 'entropy';
                    stopCriterion 	= 3; 
                    minNTrials     	= 50;
                    maxNTrials     	= 512;
                    QP = QuestPlus(F, stimDomain, paramDomain, respDomain, stopRule, stopCriterion, minNTrials, maxNTrials);
                    % initialise priors/likelihoods
                    y1 = normpdf(paramDomain{1},4,3);
                    y1 = y1./sum(y1);
                    y2 = normpdf(paramDomain{2},2,3);
                    y2 = y2./sum(y2);
                    priors = {y1, y2};
                    QP.initialise(priors)
                    % constrain target stimulus
                    QP.setStimSelectOpt('min', [], 3);
                    % run
                    startGuess_mean = QP.getParamEsts('mean');
                    startGuess_mode = QP.getParamEsts('mode');
                    while ~QP.isFinished()
                        targ = QP.getTargetStim();
                        anscorrect = normrnd(targ,sigma) > mu;
                        QP.update(targ, anscorrect);
                    end
                    % get final parameter estimates
                    endGuess_mean = QP.getParamEsts('mean');
                    endGuess_mode = QP.getParamEsts('mode');
                case 6 % A direct example from P7 of Watson's original paper
                    % set model
                    PF = @(x,mu)(.5+(1-.5-.02)*cdf('wbl',10.^(x/20),10.^(mu/20),3.5));
                    % set true param(s)
                    mu = -10;
                    trueParams = {mu};
                    % create QUEST+ object
                    stimDomain      = -40:0;
                    paramDomain     = -40:0;
                    respDomain      = [0 1];                   
                    stopRule     	= 'entropy';
                    stopCriterion 	= 2.5; 
                    minNTrials     	= 32;
                    maxNTrials     	= 512;
                    QP = QuestPlus(PF, stimDomain, paramDomain, respDomain, stopRule, stopCriterion, minNTrials, maxNTrials);
                    % initialise priors/likelihoods
                    QP.initialise();
                    % run
                    startGuess_mean = QP.getParamEsts('mean');
                    startGuess_mode = QP.getParamEsts('mode');
                    while ~QP.isFinished()
                        targ = QP.getTargetStim();
                        anscorrect = rand() < PF(targ,trueParams{:});
                        QP.update(targ, anscorrect);
                    end
                    % get final parameter estimates
                    endGuess_mean = QP.getParamEsts('mean');
                    endGuess_mode = QP.getParamEsts('mode');    
                case 7 % quick CSF (requires external function qCSF_getPC.m)  
                    % check external dependencies are present
%                     if ~exist('qCSF_getPC', 'file')
%                         error('This example requires an external file ''qCSF_getPC.m'', which cannot be found')
%                     end
                    
                    % set model
%                     F = @qCSF_getPC;
                    F = @(x,y,Gmax,Fmax,D,B,pf_beta,pf_gamma,pf_lambda)(log10(Gmax)-D*((log10(x)-log10(Fmax))/(B/2))^2);
                    
                    % set true param(s)
                    Gmax        = 150;	% peak gain (sensitivity): 2 -- 2000
                    Fmax        = 3; 	% peak spatial frequency: 0.2 to 20 cpd
                    B           = 1; 	% bandwidth (full width at half maximum): 1 to 9 octaves
                    D           = 0.4; 	% truncation level at low spatial frequencies: 0.02 to 2 decimal log units
                    pf_beta     = 3;    % psychometric function: slope
                    pf_gamma    = 0.5;  % psychometric function: guess rate
                    pf_lambda   = 0;    % psychometric function: lapse rate
                    trueParams  = [Gmax Fmax B D pf_beta pf_lambda pf_gamma];
                    
                    % define testing domain
                    stimDomain = {logspace(log10(.25), log10(40), 15)   ... % spatial frequency
                        ,logspace(log10(0.01), log10(100), 15)          ... % contrast
                        };
                    paramDomain = {linspace(2, 2000, 10)                ...
                        ,logspace(log10(0.2), log10(20), 10)            ...
                        ,linspace(1, 9, 10)                             ...
                        ,linspace(0.02, 2, 10)                          ...
                        ,pf_beta                                        ...
                        ,pf_gamma                                       ...
                        ,pf_lambda                                      ...
                        };
                    respDomain = [0 1];
                    
                    % define priors
                    priors = cell(size(paramDomain));
                    priors{1} = normpdf(paramDomain{1}, 800, 200*2);
                    priors{1} = priors{1}./sum(priors{1});
                    priors{2} = normpdf(paramDomain{2}, 7, 2*2);
                    priors{2} = priors{2}./sum(priors{2});
                    priors{3} = normpdf(paramDomain{3}, 3, 1*2);
                    priors{3} = priors{3}./sum(priors{3});
                    priors{4} = normpdf(paramDomain{4}, 1, .15*2);
                    priors{4} = priors{4}./sum(priors{4});
                    priors{5} = 1;
                    priors{6} = 1;
                    priors{7} = 1;
                    
                    % define other parameters (blank for default)
                    stopRule        = [];
                    stopCriterion   = [];
                    minNTrials      = 150;
                    maxNTrials      = 250;
                    
                    % create QUEST+ object
                    QP = QuestPlus(F, stimDomain, paramDomain, respDomain, stopRule, stopCriterion, minNTrials, maxNTrials);
                    
                    % initialise priors/likelihoods
                    fn = 'myLikelihoods.mat';
                    if exist(fn, 'file')
                        QP.initialise(priors, fn)
                    else
                        QP.initialise(priors);
                        QP.saveLikelihoods(fn);
                    end
                    
                    % constrain target stimulus (just trying this for fun)
                    QP.setStimSelectOpt('min', [], [3, 1]);
                    
                    % display
                    QP.disp();
                    startGuess_mean = QP.getParamEsts('mean');
                    fprintf('Gmax estimate: %1.2f   [true: %1.2f]\n', startGuess_mean(1), Gmax);
                    fprintf('Fmax estimate: %1.2f   [true: %1.2f]\n', startGuess_mean(2), Fmax);
                    fprintf('   B estimate: %1.2f   [true: %1.2f]\n', startGuess_mean(3), B);
                    fprintf('   D estimate: %1.2f   [true: %1.2f]\n', startGuess_mean(4), D);

                    % run -------------------------------------------------
                    profile on
                    tic()
                    while ~QP.isFinished()
                        stim = QP.getTargetStim();
                        pC = F(stim(1),stim(2), Gmax,Fmax,B,D, pf_beta,pf_gamma,pf_lambda);
                        anscorrect = rand() < pC;
                        QP.update(stim, anscorrect);
                    end
                    toc()
                    
                    % get final parameter estimates
                    endGuess_mean = QP.getParamEsts('mean');
                    
                    % display
                    QP.disp();
                    fprintf('Gmax estimate: %1.2f	[true: %1.2f]	[start: %1.2f]\n', endGuess_mean(1), Gmax, startGuess_mean(1));
                    fprintf('Fmax estimate: %1.2f	[true: %1.2f]	[start: %1.2f]\n', endGuess_mean(2), Fmax, startGuess_mean(2));
                    fprintf('   B estimate: %1.2f	[true: %1.2f]	[start: %1.2f]\n', endGuess_mean(3), B, startGuess_mean(3));
                    fprintf('   D estimate: %1.2f	[true: %1.2f]	[start: %1.2f]\n', endGuess_mean(4), D, startGuess_mean(4));
                    
                    % display debug info
                    profile viewer
                    
                    % plot ------------------------------------------------
                    % compute
                    Gmax    = trueParams(1);	% peak gain (sensitivity): 2 -- 2000
                    Fmax    = trueParams(2); 	% peak spatial frequency: 0.2 to 20 cpd
                    B       = trueParams(3);	% bandwidth (full width at half maximum): 1 to 9 octaves
                    D       = trueParams(4); 	% truncation level at low spatial frequencies: 0.02 to 2 decimal log units
                    f = logspace(log10(0.01), log10(60), 1000);
                    Sp = log10(Gmax) - log10(2) * ( (log10(f) - log10(Fmax)) / log10(2*B)/2 ).^2;
                    idx = (f<Fmax) & (Sp<(log10(Gmax)-D));
                    S = Sp;
                    S(idx) = log10(Gmax) - D;
                    S_true = S;
                    
                  	% compute S_start
                    Gmax    = startGuess_mean(1);	% peak gain (sensitivity): 2 -- 2000
                    Fmax    = startGuess_mean(2); 	% peak spatial frequency: 0.2 to 20 cpd
                    B       = startGuess_mean(3);	% bandwidth (full width at half maximum): 1 to 9 octaves
                    D       = startGuess_mean(4); 	% truncation level at low spatial frequencies: 0.02 to 2 decimal log units
                    f = logspace(log10(0.01), log10(60), 1000);
                    Sp = log10(Gmax) - log10(2) * ( (log10(f) - log10(Fmax)) / log10(2*B)/2 ).^2;
                    idx = (f<Fmax) & (Sp<(log10(Gmax)-D));
                    S = Sp;
                    S(idx) = log10(Gmax) - D;
                    S_start = S;
                    
                    % compute S_end
                    Gmax    = endGuess_mean(1);     % peak gain (sensitivity): 2 -- 2000
                    Fmax    = endGuess_mean(2); 	% peak spatial frequency: 0.2 to 20 cpd
                    B       = endGuess_mean(3);     % bandwidth (full width at half maximum): 1 to 9 octaves
                    D       = endGuess_mean(4); 	% truncation level at low spatial frequencies: 0.02 to 2 decimal log units
                    f = logspace(log10(0.01), log10(60), 1000);
                    Sp = log10(Gmax) - log10(2) * ( (log10(f) - log10(Fmax)) / log10(2*B)/2 ).^2;
                    idx = (f<Fmax) & (Sp<(log10(Gmax)-D));
                    S = Sp;
                    S(idx) = log10(Gmax) - D;
                    S_end = S;
                    
                    % unlog units
                    S_start = round(10.^S_start); %exp10(S_start);
                    S_end	= round(10.^S_end); 
                    S_true	= round(10.^S_true);
                    
                    % plot
                    figure()
                    hold on
                    plot(f, S_start, 'k');
                    plot(f, S_end, 'b:');
                    plot(f, S_true, 'r--');

                    % annotate and format
                    legend('Prior','Empirical','True', 'Location','South');
                    set(gca, 'XScale','log', 'YScale','log');
                    set(gca, 'XTick',[.5 1 2 5 10 20], 'YTick',[2 10 50 300 2000]);
                    xlabel('Spatial Frequency (cpd)'); ylabel('Contrast Sensitivity (1/C)')
                    xlim([.25 40]); ylim([1 2000]);
                    
                    % don't bother with rest of the QuestPlus.runExamples()
                    % function
                    return;
                otherwise
                    error('Specified example not recognised.\n\nTo run, type:\n   QP = QuestPlus.runExample(n)\nwhere n is an integer %i..%i\n\nE.g., QP = QuestPlus.runExample(6);', 1, 7);
            end
            
         	% display generic status report
            QP.disp(); % show QUEST+ info
            
            % compare estimates to 'ground truth' (known exactly, since
            % simulated)
            n = length(startGuess_mean);
            fprintf('\n-------------------------------------------------\n');
            for i = 1:n
                fprintf('Parameter %i of %i\n', i, n);
                fprintf(' True Value = %1.2f\n', trueParams{i});
                fprintf('Start Guess = %1.2f (mean), %1.2f (mode)\n', startGuess_mean(i), startGuess_mode(i));
                fprintf('  End Guess = %1.2f (mean), %1.2f (mode)\n', endGuess_mean(i), endGuess_mode(i));
            end
            fprintf('-------------------------------------------------\n\n\n');

            % Plot results
            figure()
            n = sum(diff(sort(QP.paramDomain'))~=0)+1; %#ok
            if length(n)==1
                P = QP.posterior;
                bar(paramDomain, P)
                [~,idx] = max(P);
                vline(paramDomain(idx))
            elseif length(n)==2
                P = reshape(QP.posterior, n);
                imagesc(paramDomain{2}, paramDomain{1}, P)
                ests = QP.getParamEsts('mean');
                h1 = hline(ests(1),'r-');
                vline(ests(2),'r-');
                h2 = hline(trueParams{1},'g--');
                vline(trueParams{2},'g--');
                legend([h1 h2], 'est', 'true')
            end
            
            % All done
            fprintf('\n\nAll checks ok\n');
        end
    end
  
end