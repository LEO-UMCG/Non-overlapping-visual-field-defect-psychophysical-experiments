%%%%%%%%%%
%% notes %
%%%%%%%%%%
% adding jitter would make the test easier!
% the difficulty of the test can be increased by increasing the
% angle_diff_sd

%%  Shape recognition testing
    % Original script: Mehrdad Gazanchian (basic layout, programming and testing) and Nomdo Jansonius (supervision)
    % This version is adapted for Linux (matlab-psychtoolbox-3).
    % Latest change: 27 Nov 2023 by MG
    % (c) Laboratory of Experimental Ophthalmology, University Medical Center groningen, University of Groningen
    % To be cited as:

    %%% OBJECTIVE %%%
    % This .m file provides shape recognition testing. Quest method is used to determine
    % the threshold that is the percent of coherent moving dots.

    % This script is adjusted to show psychophysical experiments in a dichoptic setup with a stereoscope. 
    % For more info about the experiment setup read the article.
    % The scripts shows a grid of gabors called background gabors and 6 target gabors that form the outline of a triangle
    % This hidden triangle is recognizable due to a mean difference in their orientation compared to the background gabors.
    % The triangle's tip is toward one of the cardinal directions.
    % The subject should press the arrow button that corresponds to the direction that tip of the triangle is pointig. 
    % Based on the response, the script determines mean angle difference between background and target gabors for the next presentation. 
    % Once enough data points have been acquired, the script automatically stops.

    % After the experiment, data analysis is automatically performed and the threshold is calculated.
    % Data are automatically saved in a .csv file on the desktop.

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
        % 5. Stimulus Rect Setup: Give necessary parameters of Stimulus Rect
        % 6. Creating gabor texture: Defining the variables required for PTB to creat gabors
        % 7. Test Parameters: Give necessary test parameters
        % 8. Calibration Phase: Initial calibration of stimulus rects to be able to fuse the stimulus in a dichoptic setup
        % 9. External Loop: Looping through all trials
            % 9.1. Recalibration after rest: Recalibrating stimulus rects after the rest given after a certain number of trials is done
            % 9.2. Setting up Target gabors: Defining the parameters of target gabors for each trial
            % 9.3. Setting up Background gabors: Defining the parameters of background gabors for each trial
            % 9.4. Animation Loop: Looping through one trial
            % 9.5. Pause Screen: the pause screen in between trials used for collecting responses (if not yet) and updating the Quest to show the appropriate stimuli for next trial
        % 10. Refitting data: Refitting the data to a psychometric function to find out the threshold
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
    % Set the background luminance and calculate the corresponding RGB value
    L0 = 50; % background luminance of 50 cd/m2
    R0 = monitorfunctie(L0)/255;  % use a helper code (this code should be calibrated for each monitor) to calculate the RGB equivalent of wanted luminance
    % Set stereo mode 4 to show two stimulus simultaneously which is
    % suitable for a dichoptic setup with stereoscope
    stereoMode = 4;
    % Open a window using PsychImaging, with the specified background color, screen size, and stereo mode
    [win, winRect] = PsychImaging('OpenWindow', screenid, [R0 R0 R0], [], 32, 2, stereoMode, [], [], kPsychNeed32BPCFloat);
    % Enable alpha blending for drawing smoothed points
    Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    % Determine the frames per second and inter-frame interval for the screen
    fps=Screen('FrameRate',win);
    ifi=Screen('GetFlipInterval', win);
    % If fps is zero, set it to 1/ifi
    if fps==0
        fps=1/ifi; 
    end

    % Recording Movie of the experiment if required (rect(3)*2 because we
    % are using stereo mode 4 which is split screen if we don't multiply by
    % 2 then only half the screen will be recorded
    %movie = Screen('CreateMovie', win, 'Shape_Recognition.mov', winRect(3)*2, winRect(4), 40, ':CodecSettings=Videoquality=0.8 Profile=2');

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
    tGuess = 30;      % Initial guess of threshold value
    tGuessSd = 30;    % Initial guess of standard deviation
    pThreshold = 0.75;  % Threshold for the probability of correct response
    beta = 3.5;         % Parameter for the Weibull function
    delta = 0.01;       % Step size of the psychometric function
    gamma = 0.5;       % Guess rate
    grain = 1;       % Granularity of the internal representation of the psychometric function
    range = 90;        % Range of the internal representation of the psychometric function
    plotIt = 0;         % Flag for plotting the psychometric function

    % create a quest using the normal distribution rather than weibull distribution
    % QuestCreateNormal is a tailormade code for normal distribution based on QuestCreate
    Q1=QuestCreateNormal(tGuess,tGuessSd,pThreshold,beta,delta,gamma,grain,range, plotIt);
    Q1.normalizePdf=1; % This normalizes the pdf to prevent underflow after many trials
    
    % create 6 different quests for 6 different conditions that we measure
    [Q2, Q3, Q4, Q5, Q6] = deal(Q1);
    % store all the quests in a cell array
    quests = {Q1, Q2, Q3, Q4, Q5, Q6};

    % create a cell array of the condition names
    % 'Left eye' condition shows the stimulus monocularly to the left eye only
    % 'Right eye' condition shows the stimulus monocularly to the right eye only
    % 'Binocular' condition shows the stimulus binocularly
    % 'Binasal' condition only shows the stimuli binocularly in the Binasal scotoma condition
    % 'Altitudinal' condition only shows the stimuli binocularly in the Top down scotoma condition
    % 'Checkered' condition shows the stimulus binocularly in the checkered scotoma condition
    condition_name = {'Left eye', 'Right eye', 'Binocular', 'Binasal', 'Altitudinal', 'Checkered'};

%% 4. Monitor parameters 
    % Determine the width and height of the screen in pixels
    w = winRect(3);
    h = winRect(4);
    viewD = 0.6;    % Viewing distance (m)
    monitor_height = 0.29;  % BenQ screen Height (m) [Max ecc=11]
    den = h/monitor_height; % Calculates the Pixel density of monitor
    deg_per_px = rad2deg(atan2(0.5*monitor_height, viewD))/(0.5*h); % calculates degrees per pixel
    ppd = pi * h / atan(monitor_height/viewD/2) / 360;              % calculates pixels per degree

%% 5. Stimulus Rect Setup
    xCenter = w/2;      % coordinates of screen Center in horizontal plane
    yCenter = h/2;      % coordinates of screen Center in vertical plane
    stimRectsize = 10;  % size of stimulus rect in degrees
    stimRectsizepix = stimRectsize*ppd ; % convert stimulus rect size to pixels
    stimRect = [0;0;stimRectsizepix;stimRectsizepix]; % stimulus rect coordinates
    noiseTex = CreateProceduralNoise(win, 40, 40, 'Perlin', [R0 R0 R0 1]);   % creating the noise texture to be used around the stim rect

%% 6. Creating gabor texture
    si = 1;                     %initial size in degrees
    s = ceil(si/deg_per_px);    % size of gabors in pixels
    sigma = s/7;        % sigma of gabors gaussian function
    contrast = 1;       % contrast of gabors in michelson
    aspectRatio = 1;    % I don't know
    phase = 1;          % I don't know
    % Spatial Frequency (Cycles Per Pixel)
    % One Cycle = Grey-Black-Grey-White-Grey i.e. One Black and One White Lobe
    numCycles = 5;
    freq = numCycles / s;
    % Build a procedural gabor texture (Note: to get a "standard" Gabor patch
    % we set a background offset equal to background with 1 alpha level, disable normalisation, and set a
    % pre-contrast multiplier of 0.5.
    backgroundOffset = [R0 R0 R0 0.5];
    disableNorm = 1;
    preContrastMultiplier = 0.5;
    gabortex = CreateProceduralGabor(win, s, s, [],...
      backgroundOffset, disableNorm, preContrastMultiplier);
    % Randomise the phase of the Gabors and make a properties matrix.
    propertiesMat = [phase, freq, sigma, contrast, aspectRatio, 0, 0, 0];
    texrect = [0 0  s s];

%% 7. Test parameters 
    NTrials = 60;           % Number of trial for each condition
    TPT = 0.5;              % Time per trial
    TIP=0.5; 			    % Time in between trials
    scotoma_alpha = 1;      % the alpha level of the scotomas shown
    smoothing_length = 0.15; % the percentage of scotoma that we want to smooth
    smoothing_res = 30;     % the resolution of smoothing, too much resolution causes slowing of stimulus presentation 
    % calculate the number of trials needed for all conditions based on number of quests and NTrials,
    % +2 is because we start updating quest after 3rd trial and first two trials are not important, 
    % they're just to get the participant ready
    NTrials_all = NTrials*length(quests)+2;
    % creating trialcondition matrix
    trialcondition = ones(1,NTrials_all);
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
    % a matrix to record if subject responsed correctly at each trial
    correctResp = zeros(1,NTrials_all); 
    % a matrix to record the duration of each trial
    t = zeros(1,NTrials_all); 
    % create the matrix that saves the percentage of coherent dots for each trial
    angle_diff_mean = zeros(1,NTrials_all);
    % create a matrix that saves shape of target shown for each trial
    st_shape = zeros(1,NTrials_all);
    % create a cell that saves the pressed keyboard button for each trial
    keyCode = cell(1,NTrials_all);
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

        vbl = Screen('Flip',win); % Flip to show above on screen
    end
    % saving the coordinates of left and right stim rects after calibration is complete
    xCenter_left = xCenter+xOffset(1);  xCenter_right = xCenter+xOffset(2);
    yCenter_left = yCenter+yOffset(1);  yCenter_right = yCenter+yOffset(2);
    left_stimRect = CenterRectOnPointd(stimRect, xCenter_left, yCenter_left);
    right_stimRect = CenterRectOnPointd(stimRect, xCenter_right, yCenter_right);
    WaitSecs(0.5);          % wait half a second before starting the experiment

%% 9. External loop
    for i = 1:length(trialcondition)
        KbReleaseWait(); 
        responded = 0;
        WaitSecs(TIP);      % Wait for TIP before going to next trial
    %% 9.1. Recalibration after rest
        % Show the rest screen when 1/3 and 2/3 of the required trials are done
        if i == round(length(trialcondition)/3) || i == round(2*length(trialcondition)/3) 
            fprintf("Break time\n") 
            [~,~,calibkeyCode] = KbCheck;
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
            WaitSecs(0.5); % wait half a second before resuming the experiment
        end % end of break time
    
    %% 9.2 Setting up Target gabors
        % next lines clear previous stimulus coordinates from memomry
        if i>1
            clear st_xPos*
            clear st_yPos*
            clear st_dest*
            clear st_grid
            clear bg_grid
            clear bg_xPos*
            clear bg_yPos*
            clear bg_dest*
            clear st_Angles
        end
    
        shapes = [0,3]; % 0 represents upward, 1 represents downward, 2 represents right-ward and 3 represents left-ward
        % choosing a random shape from above shapes
        st_shape(i) = randi(shapes); 
        % creating stimulus gabor coordinates based on the random shape selected
        if st_shape(i) == 0 % Upward triangle coordinates
            % set the position of target gabors in x and y plane
            st_xPos = [0  -1  1 -2 0 2].*(stimRectsize/7);
            st_yPos = [-2  0  0  2 2 2].*(stimRectsize/7);
            st_numGabors = length(st_xPos);
        elseif st_shape(i) == 1 % Downward Triangle coordinates
            % set the position of target gabors in x and y plane
            st_xPos = [0  -1  1 -2 0 2].*(stimRectsize/7);
            st_yPos = [2  0  0  -2 -2 -2].*(stimRectsize/7);
            st_numGabors = length(st_xPos);
        elseif st_shape(i) == 2 % Right-ward Triangle coordinates
            % set the position of target gabors in x and y plane
            st_xPos = [2  0  0 -2 -2 -2].*(stimRectsize/7);
            st_yPos = [0  1 -1  -2 0  2].*(stimRectsize/7);
            st_numGabors = length(st_xPos);
        elseif st_shape(i) == 3 % Left-ward Triangle coordinates
            % set the position of target gabors in x and y plane
            st_xPos = [-2 0  0  2 2 2].*(stimRectsize/7);
            st_yPos = [0  1 -1 -2 0 2].*(stimRectsize/7);
            st_numGabors = length(st_xPos);
        end
        st_grid = [st_xPos; st_yPos]';
        % Scale the grid spacing to the size of our abckground gabors and centre
        st_xPosGrid_left = st_xPos.*s + xCenter_left;
        st_yPosGrid_left = st_yPos.*s + yCenter_left;
        st_xPosGrid_right = st_xPos.*s + xCenter_right;
        st_yPosGrid_right = st_yPos.*s + yCenter_right;
        
        % Calculate stimulus gabors positions on the LEFT side of screen
        for gab = 1:st_numGabors
            st_randomness = rand*5*randi([-1,1])*stimRectsize/10;
            st_destRect_left(:, gab) = CenterRectOnPointd(texrect,  st_xPosGrid_left(gab)+st_randomness, st_yPosGrid_left(gab)+st_randomness);
        end
    
        % Calculate stimulus gabors positions on the LEFT side of screen
        st_destRect_right(1,:) = st_destRect_left(1,:)-xOffset(1)+xOffset(2);
        st_destRect_right(2,:) = st_destRect_left(2,:)-yOffset(1)+yOffset(2);
        st_destRect_right(3,:) = st_destRect_left(3,:)-xOffset(1)+xOffset(2);
        st_destRect_right(4,:) = st_destRect_left(4,:)-yOffset(1)+yOffset(2);
        
        % stimulus gabor orientations from a gaussion distribution with a mean of tTest (suggested by Quest and within our limits) and a standard deviation of 5.
        st_Angle = randi(90);
        st_Angles = normrnd(st_Angle,2, size(st_xPos)); % calculating angle of each stimulus gabor with mean of st_Angle(N) and std of 5
        st_Alpha = 1;
    %% 9.3 Setting up background gabors
        % Make the coordinates for our grid of background gabors
        [bg_xPos, bg_yPos] = meshgrid(-3:1:3, -3:1:3);
    
        % Calculate the number of squares and reshape the matrices of coordinates
        % of background gabors into a vector
        [bg_s1, bg_s2] = size(bg_xPos);
        bg_numGabors = bg_s1*bg_s2;
        bg_xPos = reshape(bg_xPos, 1, bg_numGabors).*(stimRectsize/7);
        bg_yPos = reshape(bg_yPos, 1, bg_numGabors).*(stimRectsize/7);
            
        % updating background grid based on stimulus grid
        bg_grid = [bg_xPos;bg_yPos]';
        [ia, ib] = ismember(bg_grid, st_grid, 'rows');
        bg_grid(ia,:)=[];
        bg_grid = bg_grid';
        bg_xPos = bg_grid(1,:);
        bg_yPos = bg_grid(2,:);
        
        % Scale the grid spacing to the size of background gabors and center
        bg_xPosGrid_left = bg_xPos.*s + xCenter_left;
        bg_yPosGrid_left = bg_yPos.*s + yCenter_left;
        bg_xPosGrid_right = bg_xPos.*s + xCenter_right;
        bg_yPosGrid_right = bg_yPos.*s + yCenter_right;
        
        % recalculating number of background gabors
        [bg_s1, bg_s2] = size(bg_xPos);
        bg_numGabors = bg_s1*bg_s2;
        
        % making quest suggestions within our wanted limits
        angle_diff_mean(i)  = round(QuestMean(quests{trialcondition(i)}),2);
        if angle_diff_mean(i) < 0
            angle_diff_mean(i) = 0;
        elseif angle_diff_mean(i) > 90
            angle_diff_mean(i) = 90; 
        end
    
        angle_diff_sd = 2;  % the SD of angle difference between background gabors
        bg_Angle = st_Angle + angle_diff_mean(i);
        bg_Angles = normrnd(bg_Angle,angle_diff_sd, size(bg_xPos)); % background gabor orientations from a gaussion distribution with a mean of bg_Angle and a standard deviation of angle_diff_sd.
        bg_Alpha = 1;
        % Calculate background gabors positions on the LEFT side of screen
        for gab = 1:bg_numGabors
            bg_randomness = rand*5*randi([-1,1])*stimRectsize/10;
            bg_destRect_left(:, gab) = CenterRectOnPointd(texrect,  bg_xPosGrid_left(gab)+bg_randomness, bg_yPosGrid_left(gab)+bg_randomness);
        end
        
        % Calculate background gabors positions on the RIGHT side of screen
        bg_destRect_right(1,:) = bg_destRect_left(1,:)-xOffset(1)+xOffset(2);
        bg_destRect_right(2,:) = bg_destRect_left(2,:)-yOffset(1)+yOffset(2);
        bg_destRect_right(3,:) = bg_destRect_left(3,:)-xOffset(1)+xOffset(2);
        bg_destRect_right(4,:) = bg_destRect_left(4,:)-yOffset(1)+yOffset(2);      

    %% 9.4 Animation loop     
        tic % start timing the trial
    
        % Add frame to experiment movie
        %Screen('AddFrameToMovie', win, CenterRect([0 0 1920 1080], Screen('Rect', screenid)), 'backBuffer'); 
        
        [timeNow] = Screen('Flip',win);
        timeStart = timeNow;
        sourceRect = []; % use all of the source rect
        % Print to console the Trial number and Condition
        fprintf('Trial %d:\tCondition: %s\tAngle difference: %.2f ...\t ', i, condition_name{trialcondition(i)}, angle_diff_mean(i))
        % start the loop for showing stimuli in a trial
        while timeNow < timeStart + TPT && ~responded  
            if trialcondition(i) ~= 2 % 2 = Right only condition
                % Drawing on LEFT side of screen
                Screen('SelectStereoDrawBuffer', win, 0);
                % Draw background gabors
                Screen('DrawTextures', win, gabortex, sourceRect, bg_destRect_left, bg_Angles, [], bg_Alpha, [], [],kPsychDontDoRotation, propertiesMat');
                % Draw target gabors
                Screen('DrawTextures', win, gabortex, sourceRect, st_destRect_left, st_Angles, [], st_Alpha, [], [],kPsychDontDoRotation, propertiesMat');
                % Draw scotomas if needed
                if trialcondition(i) == 4 % 4 = Binasal viewing condition
                    DrawSmoothedScotoma_Binasal_Left(win,R0,scotoma_alpha,[xCenter_left left_stimRect(2) left_stimRect(3) left_stimRect(4)],smoothing_length, smoothing_res);
                elseif trialcondition(i) == 5 % 5 = Altitudinal viewing condition
                    DrawSmoothedScotoma_Altitudinal_Top(win,R0,scotoma_alpha,[left_stimRect(1) left_stimRect(2) left_stimRect(3) yCenter_left],smoothing_length, smoothing_res);
                elseif trialcondition(i) == 6 % 6 = Checkered viewing condition
                    DrawCheckeredScotomaLeft(win,R0,scotoma_alpha,left_stimRect,smoothing_length/2, smoothing_res);
                end
            end
    
            if trialcondition(i) ~= 1 % 1 = Left only condition 
                % Drawing on RIGHT side of screen 
                Screen('SelectStereoDrawBuffer', win, 1);
                % Draw background gabors
                Screen('DrawTextures', win, gabortex, sourceRect, bg_destRect_right, bg_Angles, [], bg_Alpha, [], [],kPsychDontDoRotation, propertiesMat'); 
                % Draw target gabors
                Screen('DrawTextures', win, gabortex, sourceRect, st_destRect_right, st_Angles, [], st_Alpha, [], [],kPsychDontDoRotation, propertiesMat');
                % Draw scotomas if needed
                if trialcondition(i) == 4 % 4 = Binasal viewing condition
                    DrawSmoothedScotoma_Binasal_Right(win,R0,scotoma_alpha,[right_stimRect(1) right_stimRect(2) xCenter_right right_stimRect(4)],smoothing_length, smoothing_res);
                elseif trialcondition(i) == 5 % 5 = Altitudinal viewing condition
                    DrawSmoothedScotoma_Altitudinal_Down(win,R0,scotoma_alpha,[right_stimRect(1) yCenter_right right_stimRect(3) right_stimRect(4)],smoothing_length, smoothing_res);
                elseif trialcondition(i) == 6 % 6 = Checkered viewing condition
                    DrawCheckeredScotomaRight(win,R0,scotoma_alpha,right_stimRect,smoothing_length/2, smoothing_res);
                end
            end
    
            % Draw the frame
            DrawFrame_wo_center(win, xCenter, yCenter, noiseTex, xOffset, yOffset, stimRect);
            
            % Add frame to experiment movie
            %Screen('AddFrameToMovie', win, CenterRect([0 0 1920 1080], Screen('Rect', screenid)), 'backBuffer'); 
            
            [timeNow] = Screen('Flip', win);
    
             % Check if a key is pressed and if the correct answer is given
            [~,~,keyCode{i}] = KbCheck;
            % check if up is pressed for upward triangle
            if keyCode{i}(key.up)
                responded = 1;
                if st_shape(i) == 0
                    correctResp(i) = 1;
                else 
                    correctResp(i) = 0;
                end
            % check if down is pressed for downward triangle
            elseif keyCode{i}(key.down)
                responded = 1;
                if st_shape(i) == 1
                    correctResp(i) = 1;
                else
                    correctResp(i) = 0;
                end
            % check if right is pressed for right-ward triangle
            elseif keyCode{i}(key.right)
                responded = 1;
                if st_shape(i) == 2
                    correctResp(i) = 1;
                else
                    correctResp(i) = 0;
                end
            % check if left is pressed for left-ward triangle
            elseif keyCode{i}(key.left)
                responded = 1;
                if st_shape(i) == 3
                    correctResp(i) = 1;
                else
                    correctResp(i) = 0;
                end
            end
        end     % end of animation loop

    %% 9.5. Pause screen
        DrawFrame(win, xCenter, yCenter, noiseTex, xOffset, yOffset, stimRect);
        
        % Add frame to experiment movie
        %Screen('AddFrameToMovie', win, CenterRect([0 0 1920 1080], Screen('Rect', screenid)), 'backBuffer');

        Screen('Flip', win);    
       
        % wait for response if not given previously  
        while responded == 0
            [~,~,keyCode{i}] = KbCheck();
            % check if up is pressed for upward triangle
            if keyCode{i}(key.up)
                responded = 1;
                if st_shape(i) == 0
                    correctResp(i) = 1;
                else 
                    correctResp(i) = 0;
                end
            % check if down is pressed for downward triangle
            elseif keyCode{i}(key.down)
                responded = 1;
                if st_shape(i) == 1
                    correctResp(i) = 1;
                else
                    correctResp(i) = 0;
                end
            % check if right is pressed for right-ward triangle
            elseif keyCode{i}(key.right)
                responded = 1;
                if st_shape(i) == 2
                    correctResp(i) = 1;
                else
                    correctResp(i) = 0;
                end
            % check if left is pressed for left-ward triangle
            elseif keyCode{i}(key.left)
                responded = 1;
                if st_shape(i) == 3
                    correctResp(i) = 1;
                else
                    correctResp(i) = 0;
                end
            end
        end
        t(i) = toc; % saving the time of trial

        % Updating quest after the third trial based on different conditions
        if i>2
            quests{trialcondition(i)}=QuestUpdate(quests{trialcondition(i)},angle_diff_mean(i),correctResp(i));
        end
        % print to the console the result of each trial
        if correctResp(i)
            fprintf('Hit\n')
        else
            fprintf('Miss\n')
        end
    end % End of external loop
    
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
        stimulus_level = quests{q}.intensity(1:NTrials);
        stimulus_responses = quests{q}.response(1:NTrials);
    
        % Define plot options for the current quest
        plotOptions = struct;
        plotOptions.lineColor = colors(q,:);
        plotOptions.dataColor = plotOptions.lineColor;
    
        % Round stimulus levels to 1 decimal places
        stimulus_level = round(stimulus_level, 1);
    
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
        options.expType     = '4AFC';       % choose 4-AFC as the experiment type  
                                            % this sets the guessing rate to .25 (fixed) and  
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
        filename = sprintf('/home/leo/Desktop/Mehrdad/Experiments/data_Shape_Recognition/%i.csv', casenr);
        for i = 1:length(c)
            dlmwrite(filename,[date,casenr,c(i),scotoma_alpha,stimRectsize,...
                QuestMean(quests{i}),QuestMode(quests{i}),QuestQuantile(quests{i}),QuestSd(quests{i}),refitted_result(i),...
                angle_diff_sd,TPT,quests{i}.trialCount, ...
                tGuess,tGuessSd,range,beta],'-append','delimiter',','); %#ok<DLMWT>
        % Saves in a single row: Date, Patient number, Viewing Condition, Scotoma alpha level (Transparency) and stim Rect size
        % Results including Quest Mean, Quest Mode, Quest Quantile, Quest SD, Threshold after refitting data on a psychometric function (Main result)
        % Test Parameters including SD of angle difference between background gabors, time per trial and Number of trials, 
        % Quest variables, including tGuess, tGuessSD, range and beta of each condition.
        end
    end

