%%  Contrast sensitivity testing
    % Original script: Mehrdad Gazanchian (basic layout, programming and testing) and Nomdo Jansonius (supervision)
    % This version is adapted for Linux (matlab-psychtoolbox-3).
    % Latest change: 20 Nov 2023 by MG
    % (c) Laboratory of Experimental Ophthalmology, University Medical Center groningen, University of Groningen
    % To be cited as:

    %%% OBJECTIVE %%%
    % This .m file provides Contrast sensitivity testing. Quest method is used to determine the threshold contrast sensitivity.

    % This script is adjusted to show psychophysical experiments in a dichoptic setup with a stereoscope. 
    % For more info about the experiment setup read the article.
    % The scripts shows a vertical gabor which is randomly oriented 45 degrees clockwise or counter-clockwise.
    % The subject should press the left or right arrow key that corresponds gabor orientation (Left for counter clockwise and right for clockwise). 
    % Based on the response, the script determines contrast of the gabor for the next presentation. 
    % Once enough data points have been acquired, the script automatically stops.

    % After the experiment, data analysis is automatically performed and the contrast sensitivity threshold is calculated.
    % Data are automatically saved in a .csv file on specified location.

    % The script can be aborted during the experiment by pressing the ctrl+c button.
    % This script requires psignifit toolbox available from:
    % https://uni-tuebingen.de/en/fakultaeten/mathematisch-naturwissenschaftliche-fakultaet/fachbereiche/informatik/lehrstuehle/neuronale-informationsverarbeitung/research/software/psignifit/
    % This script requires psychtoolbox 3 available from:
    % http://psychtoolbox.org/download.html
    % You can use the script as it is or change it according to your specific needs.

    % The script has been organised as follows:
        % 1. Case number Input: Get the case number of participant
        % 2. Initial PTB Setup: Do the initial setup of psychtoolbox
        % 3. Quest Setup: Do the initial setup of Quest
        % 4. Monitor Parameters: Give necessary parameters of monitor
        % 5. Gabor Setup: Give necessary parameters of the stimulus gabor
        % 6. Stimulus Rect Setup: Give necessary parameters of Stimulus Rect
        % 7. Test Parameters: Give necessary test parameters
        % 8. Calibration Phase: Initial calibration of stimulus rects to be able to fuse the stimulus in a dichoptic setup
        % 9. External Loop: The loop of all trials starts
            % 9.1. Recalibration after rest: Recalibrating stimulus rects after the rest given after a certain number of trials is done
            % 9.2. Animation Loop: The animation loop for one trial
            % 9.3. Pause Screen: the pause screen in between trials used for collecting responses (if not yet) and updating the Quest to show the appropriate stimuli for next trial
        % 10. Refitting data: Refitting the data to a psychometric function to find out the contrast threshold 
        % 11. Saving Data to Disc



%% 1. Case number input
    clear all;
    casenr = input('Casenumber of participant [9999]:                      ');
    if isempty(casenr)
        casenr = 9999; % Default answer is 9999
    end

%% 2. Initial PTB setup
    % Add the path where other required functions are located (Folder Backstage Codes and Functions)
    addpath '/home/leo/Desktop/Backstage Codes and Functions' 

    % Assert that the system has an OpenGL graphics card
    AssertOpenGL;
    % Skip PTB sync tests and suppress warnings
    Screen('Preference', 'SkipSyncTests', 1);
    Screen('Preference', 'VisualDebugLevel', 0);
    Screen('Preference', 'SuppressAllWarnings', 1);
    % Determine which screen to display the stimulus on
    screenid = max(Screen('Screens'));
    % Set default PTB settings
    PsychDefaultSetup(2); 
    % Determine the colors for the screen
    white = WhiteIndex(screenid);
    black = BlackIndex(screenid);
    grey = white / 2;
    % Prepare the psychtoolbox for showing the best precision
    % for contrast sensitivity testing
    PsychImaging('PrepareConfiguration');
    PsychImaging('AddTask','General','FloatingPoint32BitIfPossible');
    PsychImaging('AddTask','General','NormalizedHighResColorRange', 1);
    PsychImaging('AddTask','FinalFormatting','DisplayColorCorrection','LookupTable');
    % Set the background luminance and calculate the corresponding RGB value
    L0 = 50; % background luminance of 50 cd/m2
    R0 = monitorfunctie(L0)/255;    % use a helper code (this code should be calibrated for each monitor) to calculate the RGB equivalent of wanted luminance
    % Set stereo mode 4 to show two stimulus simultaneously which is
    % suitable for a dichoptic setup with stereoscope
    stereoMode = 4;
    % Open a window using PsychImaging, with the specified background color, screen size, and stereo mode
    [win, rect] = PsychImaging('OpenWindow', screenid, [R0 R0 R0], [], 32, 2, stereoMode, [], [], kPsychNeed32BPCFloat);
    % Enable alpha blending for drawing smoothed points
    Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    % use a premade table for color correction
    % this is important for showing the exact colors in contrast
    % sensitivity tasks. Read more about it in:
    % http://psychtoolbox.org/docs/PsychColorCorrection
    PsychColorCorrection('SetLookupTable', win, benqGamma);
    
    % Determine the frames per second and inter-frame interval for the screen
    fps=Screen('FrameRate',win);
    ifi=Screen('GetFlipInterval', win);
    % If fps is zero, set it to 1/ifi
    if fps==0
        fps=1/ifi; 
    end

    % Recording Movie of the experiment if required
    %movie = Screen('CreateMovie', win, 'Contrast_Sensitivity.mov', rect(3)*2, rect(4), 40, ':CodecSettings=Videoquality=0.8 Profile=2');

    % Hide the mouse cursor and set the priority of the window to the maximum
    HideCursor;
    Priority(MaxPriority(win));
    % Set up the keyboard for the experiment
    KbName('UnifyKeyNames');
    key.break = KbName('escape'); key.space = KbName('space');
    key.up = KbName('UpArrow'); key.down = KbName('DownArrow');
    key.left = KbName('LeftArrow'); key.right = KbName('RightArrow');
    [~,~,calibkeyCode] = KbCheck;
    % Set the text size to 40
    Screen('TextSize', win, 40);
    % Do initial flip
    vbl=Screen('Flip', win);

%% 3. Quest Setup
% Setting up quest for more info read "Quest: A Bayesian adaptive psychometric method" and psychtoolbox code "QuestCreate.m"
    tGuess = 0.07;      % Initial guess of threshold value
    tGuessSd = 0.2;    % Initial guess of standard deviation
    pThreshold =0.75;  % Threshold for the probability of correct response
    beta = 3.5;         % Parameter for the Weibull function
    delta = 0.01;       % Step size of the psychometric function
    gamma = 0.5;       % Guess rate
    grain = 0.01;       % Granularity of the internal representation of the psychometric function
    range = 2;        % Range of the internal representation of the psychometric function
    plotIt = 0;         % Flag for plotting the psychometric function

    % create a quest using weibull distribution
    Q1=QuestCreate(tGuess,tGuessSd,pThreshold,beta,delta,gamma,grain,range, plotIt);
    Q1.normalizePdf=1; % This normalizes the pdf to prevent underflow after many trials
    
    % create 6 different quests for 6 different viewing conditions that we measure
    [Q2, Q3, Q4, Q5, Q6] = deal(Q1);
    % store all the quests in a cell array
    quests = {Q1, Q2, Q3, Q4, Q5, Q6};

    % create a cell array of the condition names
    % 'Left eye' condition shows the stimulus monocularly to the left eye only
    % 'Right eye' condition shows the stimulus monocularly to the right eye only
    % 'Binocular' condition shows the stimulus binocularly
    % 'Binasal' condition only showes the stimulus binocularly in the Binasal scotoma condition
    % 'Altitudinal' condition only showes the stimulus binocularly in the Top down scotoma condition
    % 'Checkered' condition shows the stimulus binocularly in the checkered scotoma condition
    condition_name = {'Left eye', 'Right eye', 'Binocular', 'Binasal', 'Altitudinal', 'Checkered'};

%% 4. Monitor parameters 
    % Determine the width and height of the screen in pixels
    w = rect(3);
    h = rect(4);
    monitor_height = 0.29;      % BenQ screen Height (m) [Max ecc=11]
    viewD = 0.6;                % Viewing distance (m)
    den = h/monitor_height;     % Calculates the Pixel density of monitor
    deg_per_px = rad2deg(atan2(0.5*monitor_height, viewD))/(0.5*h); % calculates degrees per pixel
    ppd = pi * h / atan(monitor_height/viewD/2) / 360;              % calculates pixels per degree

%% 5. Gabor setup
    % setting initial parameters of the gabor we show as the stimulus
    g.sizeDeg = 10;   % gabor size in degrees                  
    g.size = round(g.sizeDeg/deg_per_px);  % gabor size in pixels
    g.Sigma =  g.size/6;
    g.Aspect = 1;
    g.Phase = 0;
    g.BackgroundOffset = [R0 R0 R0 1];
    g.DisableNorm = 1;
    g.cMultiply = 1;
    g.angle = 0;
    modulateColor = 1;
    
    % creating gabor
    g.tex = CreateProceduralGabor(win, g.size, g.size, [], g.BackgroundOffset, g.DisableNorm, g.cMultiply);

%% 6. stimulus rect setup
    xCenter = w/2;      % coordinates of screen Center in horizontal plane
    yCenter = h/2;      % coordinates of screen Center in vertical plane
    stimRectsize = 10;  % size of stimulus rect in degrees
    stimRectsizepix = stimRectsize*ppd ; % convert stimulus rect size to pixels
    stimRect = [0;0;stimRectsizepix;stimRectsizepix]; % stimulus rect coordinates
    noiseTex = CreateProceduralNoise(win, 40, 40, 'Perlin', [R0 R0 R0 1]);   % creating the noise texture to be used around the stim rect

%% 7. Test parameters 
    NTrials = 60;   % number of trials for each condition
    % calculate the number of trials needed based on number of quests and NTrials,
    % +2 is because we start updating quest after 3rd trial and first two trials are not important, 
    % they're just to get the participant ready
    num_trials = NTrials*length(quests)+2;
    % prepare a matrix inside g struct that saves the orientation of gabors for
    % each trial
    g.stimOrder = Shuffle([zeros(1,num_trials/2) ones(1,num_trials/2)]);   % 0 = left, 1 = right
    TPT = 2;                % the time for duration of each trial
    TIP = 0.5;              % Time in between trials
    scotoma_alpha = 1;      % the alpha level of the scotomas shown
    smoothing_length = 0.15;% the percentage of scotoma that we want to smooth
    smoothing_res = 30;     % the resolution of smoothing, too much resolution causes slowing of stimulus presentation 
    Scotoma_R0 = R0;
    % creating trialcondition matrix
    trialcondition = ones(1,num_trials);
    % first two trials are shown binocularly
    trialcondition(1) = 3;
    trialcondition(2) = 3;
    % two for loops below randomize the trialconditions for each trial, and
    % random trial conditions are saved in trialcondition matrix
    a = ones(NTrials,length(quests));
    for j = 1:NTrials
        a(j,:) = randperm(length(quests));
    end
    for j = 1:NTrials*length(quests)
        trialcondition(j+2) = a(j);
    end
    % matrix that has the gabors spatial frequencies we want to show
    spatialfreq = 5/g.sizeDeg;
    % create the matrix that saves the spatial frequency of shown gabor for each trial
    sf = zeros(1,num_trials);
    % create the matrix that saves the contrast of shown gabor for each trial
    ct = zeros(1,num_trials);
    % a matrix to record if subject responsed correctly at each trial
    correctResp = zeros(1,num_trials); 
    % a matrix to record the duration of each trial
    t = zeros(1,num_trials); 


%% 8. Calibration phase
    % Start with stimulus allignment - subject can press arrowkeys to adjust the stimulus positions
    fprintf("start of experiment\n") 
    xOffset = [100 -100];  
    yOffset = [0 0];
    % Set locations (arrowkeys) of fusion rects - press space to continue
    while ~calibkeyCode(key.space)  
        [~,~,calibkeyCode] = KbCheck;
        if calibkeyCode(key.right)
            xOffset(1) = xOffset(1) + 0.5;
            xOffset(2) = xOffset(2) - 0.5;
        elseif calibkeyCode(key.left)
            xOffset(1) = xOffset(1) - 0.5;
            xOffset(2) = xOffset(2) + 0.5;
        elseif calibkeyCode(key.up)
            yOffset(1) = yOffset(1) - 0.5;
            yOffset(2) = yOffset(2) + 0.5;
        elseif calibkeyCode(key.down)
            yOffset(1) = yOffset(1) + 0.5;
            yOffset(2) = yOffset(2) - 0.5;
        end
        % Save the coordinates of the left stimrect based on calibration
        xCenter_left = xCenter+xOffset(1);  
        yCenter_left = yCenter+yOffset(1);  
        left_stimRect = CenterRectOnPointd(stimRect, xCenter_left, yCenter_left);
        % check left stimrect so that it does not get out of bounds
        if left_stimRect(1)-50 <= 0 
            xOffset(1) = xOffset(1) + 0.5;
            xOffset(2) = xOffset(2) - 0.5;
        end
        if left_stimRect(2)-50 <= 0 
            yOffset(1) = yOffset(1) + 0.5;
            yOffset(2) = yOffset(2) - 0.5;
        end
        if left_stimRect(3)+50 > w 
            xOffset(1) = xOffset(1) - 0.5;
            xOffset(2) = xOffset(2) + 0.5;
        end
        if left_stimRect(4)+50 >= h 
            yOffset(1) = yOffset(1) - 0.5;
            yOffset(2) = yOffset(2) + 0.5;
        end
        % Draw the frame
        DrawFrame_OnlyDot(win, xCenter, yCenter, noiseTex, xOffset, yOffset, stimRect);
        % Show instruction text
        DrawFormattedText(win, 'Use arrowkeys to adjust positions\nWhen alligned, press space to continue', 'center',[],[1 0 1]);
       
        % Add frame to experiment movie
        %Screen('AddFrameToMovie', win, CenterRect([0 0 1920 1080], Screen('Rect', screenid)), 'backBuffer');           
        
        vbl = Screen('Flip',win); % Flip to show the above on screen
    end
    % saving the coordinates of left and right stim rect after calibration is complete
    xCenter_left = xCenter+xOffset(1);  xCenter_right = xCenter+xOffset(2);
    yCenter_left = yCenter+yOffset(1);  yCenter_right = yCenter+yOffset(2);
    left_stimRect = CenterRectOnPointd(stimRect, xCenter_left, yCenter_left);
    right_stimRect = CenterRectOnPointd(stimRect, xCenter_right, yCenter_right);
    WaitSecs(0.5);          % wait half a second before starting the experiment
   
%% 9. External loop
    for i = 1:length(trialcondition)
        responded = 0;
        % Get new stimulus orientations
        if g.stimOrder(i)
            g.angle = -45; % if g.stimOder == 0 gabor will be tilted to left (counterclockwise)
        else
            g.angle = 45;  % if g.stimOder == 1 gabor will be tilted to right (clockwise)
        end
        if i== 1
            ct(i) = 0.1;
        elseif i == 2
            ct(i) = 0.09;
        elseif i>2
            ct(i) = QuestMean(quests{trialcondition(i)});
            if ct(i)<=0.001
                ct(i) = 0.001;
            end
        end
    %% 9.1. Recalibration after rest
        % Show the rest screen when 1/3 and 2/3 of the required trials are done
        if i == round(length(trialcondition)/3) || i == round(2*length(trialcondition)/3)
            fprintf("Break time\n")   
            [~,~,calibkeyCode] = KbCheck;
            while ~calibkeyCode(key.space)  % Set locations (arrowkeys) of fusion rects - press space to continue
                [~,~,calibkeyCode] = KbCheck;
                if calibkeyCode(key.right)
                    xOffset(1) = xOffset(1) + 0.5;
                    xOffset(2) = xOffset(2) - 0.5;
                elseif calibkeyCode(key.left)
                    xOffset(1) = xOffset(1) - 0.5;
                    xOffset(2) = xOffset(2) + 0.5;
                elseif calibkeyCode(key.up)
                    yOffset(1) = yOffset(1) - 0.5;
                    yOffset(2) = yOffset(2) + 0.5;
                elseif calibkeyCode(key.down)
                    yOffset(1) = yOffset(1) + 0.5;
                    yOffset(2) = yOffset(2) - 0.5;
                end
                % Save the coordinates of the left stimrect based on calibration
                xCenter_left = xCenter+xOffset(1);  
                yCenter_left = yCenter+yOffset(1);  
                left_stimRect = CenterRectOnPointd(stimRect, xCenter_left, yCenter_left);
                % check left stimrect so that it does not get out of bounds
                if left_stimRect(1)-50 <= 0 
                    xOffset(1) = xOffset(1) + 0.5;
                    xOffset(2) = xOffset(2) - 0.5;
                end
                if left_stimRect(2)-50 <= 0 
                    yOffset(1) = yOffset(1) + 0.5;
                    yOffset(2) = yOffset(2) - 0.5;
                end
                if left_stimRect(3)+50 > w 
                    xOffset(1) = xOffset(1) - 0.5;
                    xOffset(2) = xOffset(2) + 0.5;
                end
                if left_stimRect(4)+50 >= h 
                    yOffset(1) = yOffset(1) - 0.5;
                    yOffset(2) = yOffset(2) + 0.5;
                end
                % Draw the frame
                DrawFrame_OnlyDot(win, xCenter, yCenter, noiseTex, xOffset, yOffset, stimRect);
                % Show instruction text
                DrawFormattedText(win, 'Time to rest\n When ready Use arrowkeys to adjust positions\nWhen alligned, press space to continue', 'center',[],[1 0 1]);
                
                % Add frame to experiment movie
                %Screen('AddFrameToMovie', win, CenterRect([0 0 1920 1080], Screen('Rect', screenid)), 'backBuffer');                      
                
                vbl = Screen('Flip',win); % Flip to show above on screen
            end
            % saving the coordinates of left and right stim rect after calibration is complete
            xCenter_left = xCenter+xOffset(1);  xCenter_right = xCenter+xOffset(2);
            yCenter_left = yCenter+yOffset(1);  yCenter_right = yCenter+yOffset(2);
            left_stimRect = CenterRectOnPointd(stimRect, xCenter_left, yCenter_left);
            right_stimRect = CenterRectOnPointd(stimRect, xCenter_right, yCenter_right);
        end
        
    %% 9.2 Animation loop
        WaitSecs(TIP);  % waiting time between trials  
        %beep   % a beep to mark the start of a new trial (removed because it was distracting)
        tic % start timing the trial
        % Draw the frame with center dot at the start of each trial
        % it will be replace by a frame without central dot when stimulus is
        % showing
        DrawFrame(win, xCenter, yCenter, noiseTex, xOffset, yOffset, stimRect)
        
        % Add frame to experiment movie
        %Screen('AddFrameToMovie', win, CenterRect([0 0 1920 1080], Screen('Rect', screenid)), 'backBuffer'); 
        
        [timeNow] = Screen('Flip',win);
        timeStart = timeNow;
        % Print to console the Trial number, Viewing Condition and contrast
        fprintf('Trial %d:\tCondition: %s\tCt: %.4f\t', i, condition_name{trialcondition(i)}, ct(i));
        % start the loop for showing stimuli in a trial
        while timeNow < timeStart + TPT && ~responded
            % Drawing on the LEFT side of the screen
            if trialcondition(i) ~= 2 % 2 = Right only condition 
                % Drawing on LEFT side of screen
                Screen('SelectStereoDrawBuffer', win, 0);
                % Drawing the gabor texture
                Screen('DrawTextures', win, g.tex, [], left_stimRect, g.angle,...
                     [],1,modulateColor,[],kPsychDontDoRotation, [g.Phase; spatialfreq*deg_per_px;...
                     g.Sigma; ct(i); g.Aspect; 0; 0; 0]);
                % Draw Scotomas if needed
                if trialcondition(i) == 4 % 4 = Binasal viewing condition
                    DrawSmoothedScotoma_Binasal_Left(win,Scotoma_R0,scotoma_alpha,[xCenter_left left_stimRect(2) left_stimRect(3) left_stimRect(4)],smoothing_length, smoothing_res)
                elseif trialcondition(i) == 5 % 5 = Altitudinal viewing condition
                    DrawSmoothedScotoma_Altitudinal_Top(win,Scotoma_R0,scotoma_alpha,[left_stimRect(1) left_stimRect(2) left_stimRect(3) yCenter_left],smoothing_length, smoothing_res)
                elseif trialcondition(i) == 6 % 6 = Checkered viewing condition
                    DrawCheckeredScotomaLeft(win,Scotoma_R0,scotoma_alpha,left_stimRect,smoothing_length, smoothing_res);
                end
            end
    
            if trialcondition(i) ~= 1 % 1 = Left only condition 
                % Drawing on the RIGHT side of the screen
                Screen('SelectStereoDrawBuffer', win, 1);
                % Drawing the gabor texture
                Screen('DrawTextures', win, g.tex, [], right_stimRect, g.angle,...
                        [],1,modulateColor,[],kPsychDontDoRotation, [g.Phase; spatialfreq*deg_per_px;... 
                        g.Sigma; ct(i); g.Aspect; 0; 0; 0]);
                % Draw Scotomas if needed
                if trialcondition(i) == 4 % 4 = Binasal viewing condition
                    DrawSmoothedScotoma_Binasal_Right(win,Scotoma_R0,scotoma_alpha,[right_stimRect(1) right_stimRect(2) xCenter_right right_stimRect(4)],smoothing_length, smoothing_res)
                elseif trialcondition(i) == 5 % 5 = Altitudinal viewing condition
                    DrawSmoothedScotoma_Altitudinal_Down(win,Scotoma_R0,scotoma_alpha,[right_stimRect(1) yCenter_right right_stimRect(3) right_stimRect(4)],smoothing_length, smoothing_res)
                elseif trialcondition(i) == 6 % 6 = Checkered viewing condition
                    DrawCheckeredScotomaRight(win,Scotoma_R0,scotoma_alpha,right_stimRect,smoothing_length, smoothing_res);
                end      
            end
            % Redraw frame without center dot 
            DrawFrame_wo_center(win, xCenter, yCenter, noiseTex, xOffset, yOffset, stimRect)
            
            % Add frame to experiment movie
            %Screen('AddFrameToMovie', win, CenterRect([0 0 1920 1080], Screen('Rect', screenid)), 'backBuffer'); 
            
            [timeNow] = Screen('Flip', win); 
            
            % Check if a key is pressed and if the correct answer is given
            [~,~,keyCode] = KbCheck;
            if keyCode(key.left)
                if g.stimOrder(i) == 0 % if gabor is tilted to left
                    correctResp(i) = true;
                else
                    correctResp(i) = false;
                end
                responded = true;
            elseif keyCode(key.right)
                if g.stimOrder(i) == 1  % if gabor is tilted to right
                    correctResp(i) = true;
                else
                    correctResp(i) = false;
                end
                responded = true;
            end
        end % End of animation loop
    
    %% 9.3. Pause screen
        
        DrawFrame(win, xCenter, yCenter, noiseTex, xOffset, yOffset, stimRect)
        % Add frame to experiment movie
        %Screen('AddFrameToMovie', win, CenterRect([0 0 1920 1080], Screen('Rect', screenid)), 'backBuffer'); 
        Screen('Flip', win);
        % Wait for response if not recieved already 
        while ~responded
            [~,~,keyCode] = KbCheck;
            if keyCode(key.left)
                if g.stimOrder(i) == 0 % if gabor is tilted to left
                    correctResp(i) = true;
                else
                    correctResp(i) = false;
                end
                responded = true;
            elseif keyCode(key.right)
                if g.stimOrder(i) == 1  % if gabor is tilted to right
                    correctResp(i) = true;
                else
                    correctResp(i) = false;
                end
                responded = true;
            end
        end 
        t(i) = toc; % saving the time of trial
        % Updating quest after the third trial based on different vieiwng conditions
        if i>2
            quests{trialcondition(i)}=QuestUpdate(quests{trialcondition(i)},ct(i),correctResp(i));
        end
        % print to the console the result of each trial
        if correctResp(i)
            fprintf('Hit\n')
        else
            fprintf('Miss\n')
        end
    end   % End of external loop
    
    Priority(0);
    ShowCursor;
    sca;

    % Finalize experiment movie
    %Screen('FinalizeMovie', movie);

%% 10. Refitting data
    % Define colors for plotting different quests
    colors = [1,0,0; % quests(1) = Red (Left Only)
                0,0,1; % quests(2) = Blue (Right Only)
                0,0,0; % quests(3) = Black (Binocular)
                1,0.5,0; % quests(4) = Orange (Binasal scotoma)
                0.5,0,0.5; % quests(5) = Purple (Altitudinal scotoma)
                1,1,0]; % quests(6) = Yellow (Checkered scotoma)
    
    % Loop through each quest
    for q = 1:length(quests)
        % Extract stimulus levels and responses for the current quest
        stimulus_level = quests{q}.intensity(1:60);
        stimulus_responses = quests{q}.response(1:60);
    
        % Define plot options for the current quest
        plotOptions = struct;
        plotOptions.lineColor = colors(q,:);
        plotOptions.dataColor = plotOptions.lineColor;
    
        % Round stimulus levels to 3 decimal places
        stimulus_level = round(stimulus_level, 3);
    
        % Find unique stimulus levels
        stimulus_unique=unique(stimulus_level);
    
        % Initialize arrays to store aggregated responses and counts
        response = zeros(1,length(stimulus_unique));
        count = zeros(1,length(stimulus_unique));
    
        % Aggregate responses and counts for each unique stimulus level
        for j = 1:length(stimulus_unique)
            for i = 1:length(stimulus_level)
                if stimulus_level(1,i) == stimulus_unique(j)
                    response(j) = stimulus_responses(i) + response(j);
                    count(j) = 1 + count(j);
                end
            end
        end
    
        % Create a matrix to store stimulus levels, aggregated responses, and counts
        data = [];
        for i = 1:length(stimulus_unique)
            data(i,1) = stimulus_unique(i);
            data(i,2) = response(i);
            data(i,3) = count(i);
        end
        
        % Define options for psychometric fitting
        options = struct;
        options.sigmoidName = 'logistic';   % choose a cumulative Gauss as the sigmoid  'norm' or 'weibull'
        options.expType     = '2AFC';       % choose 2-AFC as the experiment type  
                                            % this sets the guessing rate to .5 (fixed) and  
                                            % fits the rest of the parameters 
    
        % Fit psychometric function using psignifit
        result = psignifit(data,options);
        % Store the fitted result for the current quest
        refitted_result(q) = result.Fit(1);
        % Plot psychometric function for the current quest
        plotPsych(result, plotOptions);
        hold on
    end
    
    % Transpose the refitted_result array for convenience
    refitted_result = refitted_result';

%%  11. Saving Data To Disc
    save_data = 1; % set to zero if you do not want to save results
    if save_data
        date = round(str2double(datestr(now,'yymmdd')));
        c = 1:length(quests);
        % Set the file name for each casenr using the location you want to save
        filename = sprintf('/home/leo/Desktop/Mehrdad/Experiments/data_Contrast_Sensitivity/%i.csv', casenr);
        for i = 1:length(c)
            dlmwrite(filename,[date,casenr,c(i),scotoma_alpha,stimRectsize,...
                QuestMean(quests{i}),QuestMode(quests{i}),QuestQuantile(quests{i}),QuestSd(quests{i}),refitted_result(i),...
                g.sizeDeg,spatialfreq,TPT,quests{i}.trialCount, ...
                tGuess,tGuessSd,range,beta],'-append','delimiter',','); %#ok<DLMWT>
        % Saves in a single row: Date, Patient number, Viewing Condition, Scotoma alpha level (Transparency) and stim Rect size
        % Results including Quest Mean, Quest Mode, Quest Quantile, Quest SD, Threshold Contrast after refitting data on a psychometric function (Main result)
        % Test Parameters including gabor size, gabor spatial frequency, time per trial and Number of trials, 
        % Quest variables, including tGuess, tGuessSD, range and beta of each condition.
        end
    end
