%% Notes
    % increasing the speed makes the test easier, speed of 3 deg/sec is logical
    % increasing the N of trials makes the QuestSD lower, making the results
    % more reliable (N = 60 is logical)
    % increasing tGuess resulted in lower QuestSD => more reliable results
    % (tGuess = 0.25 is logical)
    % increasing tGuessSD resulted in higher QuestSD => less reliable results
    % (tGuessSD = 0.25 is logical)
    % increasing range resulted in higher QuestSD and higher QuestMean => less
    % reliable results, also decreasing range resulted in higher QuestMean 
    % which was also not reliable (range = 0.5 is logical)

%%  Coherent motion perception testing
    % Original script: Mehrdad Gazanchian (basic layout, programming and testing) and Nomdo Jansonius (supervision)
    % This version is adapted for Linux (matlab-psychtoolbox-3).
    % Latest change: 20 Nov 2023 by MG
    % (c) Laboratory of Experimental Ophthalmology, University Medical Center groningen, University of Groningen
    % To be cited as:

    %%% OBJECTIVE %%%
    % This .m file provides coherent motion perception testing. Quest method is used to determine
    % the threshold that is the percent of coherent moving dots.

    % This script is adjusted to show psychophysical experiments in a dichoptic setup with a stereoscope. 
    % For more info about the experiment setup read the article.
    % The scripts shows random dots moving with a subset of them moving coherently in one of the cardinal directions.
    % The subject should press the arrow button that corresponds to the movement direction of coherent moving dots. 
    % Based on the response, the script determines percent of coherent moving dots of the next presentation. 
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
        % 6. Test Parameters: Give necessary test parameters
        % 7. Calibration Phase: Initial calibration of stimulus rects to be able to fuse the stimulus in a dichoptic setup
        % 8. Initial dot positions and velocities
        % 9. External Loop: The loop of all trials starts
            % 9.1. Recalibration after rest: Recalibrating stimulus rects after the rest given after a certain number of trials is done
            % 9.2. Random Dots Configurations: Configuring position and movement direction of random dots
            % 9.3. Coherent Dots Configurations: Configuring position and movement direction of coherently moving dots
            % 9.4. Animation Loop: The animation loop for one trial
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
    [win, rect] = PsychImaging('OpenWindow', screenid, [R0 R0 R0], [], 32, 2, stereoMode, [], [], kPsychNeed32BPCFloat);
    % Enable alpha blending for drawing smoothed points
    Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    % Determine the frames per second and inter-frame interval for the screen
    fps=Screen('FrameRate',win);
    ifi=Screen('GetFlipInterval', win);
    % If fps is zero, set it to 1/ifi
    if fps==0
        fps=1/ifi; 
    end

    % Recording Movie of the experiment if required
    %movie = Screen('CreateMovie', win, 'Dottest_coherent.mov', rect(3)*2, rect(4), 40, ':CodecSettings=Videoquality=0.8 Profile=2');

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
    tGuess = 0.25;      % Initial guess of threshold value
    tGuessSd = 0.25;    % Initial guess of standard deviation
    pThreshold =0.625;  % Threshold for the probability of correct response
    beta = 3.5;         % Parameter for the Weibull function
    delta = 0.01;       % Step size of the psychometric function
    gamma = 0.25;       % Guess rate
    grain = 0.01;       % Granularity of the internal representation of the psychometric function
    range = 0.5;        % Range of the internal representation of the psychometric function
    plotIt = 0;         % Flag for plotting the psychometric function

    % create a quest using the normal distribution rather than weibull distribution
    % QuestCreateNormal is a tailormade code for normal distribution based on QuestCreate
    Q1=QuestCreateNormal(tGuess,tGuessSd,pThreshold,beta,delta,gamma,grain,range, plotIt);
    Q1.normalizePdf=1; % This normalizes the pdf to prevent underflow after many trials
    
    % create 8 different quests for 8 different conditions that we measure
    [Q2, Q3, Q4, Q5, Q6, Q7, Q8] = deal(Q1);
    % store all the quests in a cell array
    quests = {Q1, Q2, Q3, Q4, Q5, Q6, Q7, Q8};

    % create a cell array of the condition names
    % 'Left eye' condition shows the stimulus monocularly to the left eye only
    % 'Right eye' condition shows the stimulus monocularly to the right eye only
    % 'Binocular' condition shows the stimulus binocularly
    % 'Binasal_Horizontal' condition only showes the coherent dots moving in the Horizontal plane binocularly in the Binasal scotoma condition
    % 'Binasal_Vertical' condition only showes the coherent dots moving in the Vertical plane binocularly in the Binasal scotoma condition
    % 'Altitudinal_Horizontal' condition only showes the coherent dots moving in the Horizontal plane binocularly in the Top down scotoma condition
    % 'Altitudinal_Vertical' condition only showes the coherent dots moving in the Vertical plane binocularly in the Top down scotoma condition
    % 'Checkered' condition shows the stimulus binocularly in the checkered scotoma condition
    condition_name = {'Left eye', 'Right eye', 'Binocular', 'Binasal_Horizontal', 'Binasal_Vertical', 'Altitudinal_Horizontal', 'Altitudinal_Vertical', 'Checkered'};

%% 4. Monitor parameters 
    % Determine the width and height of the screen in pixels
    w = rect(3);
    h = rect(4);
    viewD = 0.6;    % Viewing distance (m)
    monitor_height = 0.29;  % BenQ screen Height (m) [Max ecc=11]
    den = h/monitor_height; % Calculates the Pixel density of monitor
    deg_per_px = rad2deg(atan2(0.5*monitor_height, viewD))/(0.5*h); % calculates degrees per pixel
    ppd = pi * h / atan(monitor_height/viewD/2) / 360;              % calculates pixels per degree

%% 5. stimulus rect setup
    xCenter = w/2;      % coordinates of screen Center in horizontal plane
    yCenter = h/2;      % coordinates of screen Center in vertical plane
    stimRectsize = 10;  % size of stimulus rect in degrees
    stimRectsizepix = stimRectsize*ppd ; % convert stimulus rect size to pixels
    stimRect = [0;0;stimRectsizepix;stimRectsizepix]; % stimulus rect coordinates
    noiseTex = CreateProceduralNoise(win, 40, 40, 'Perlin', [R0 R0 R0 1]);   % creating the noise texture to be used around the stim rect

%% 6. Test parameters 
    dot_speed   = 3;        % dot speed (deg/sec)
    ndots       = 200;      % number of dots
    dot_w       = 0.1;      % dot diameter (deg)
    pfs = dot_speed * ppd / fps;  % dot speed (pixels/frame)
    s = dot_w * ppd;              % dot diameter (pixels)
    c_color     = white;    % coherent dots color
    r_color     = white;    % random dots color
    waitframes = 1;         % Show new dot-images at each waitframes'th monitor refresh.
    % four cardinal directions (Right[1;0], Left[-1;0], Down[0;1], Up[0;-1]) that coherent dots can choose from
    directions = [1 -1 0 0; 0 0 1 -1]; 
    NTrials = 60;           % Number of trials
    TPT = 1;                % Time per Trial
    TIP = 0.5;              % Time in between Trials
    responded = 0;          % dummy variable for knowing whether participant responded or not
    scotoma_alpha = 1;      % the alpha level of the scotomas shown
    smoothing_length = 0.15;% the percentage of scotoma that we want to smooth
    smoothing_res = 30;     % the resolution of smoothing, too much resolution causes slowing of stimulus presentation 
    % calculate the number of trials needed based on number of quests and NTrials,
    % +2 is because we start updating quest after 3rd trial and first two trials are not important, 
    % they're just to get the participant ready
    num_trials = NTrials*length(quests)+2;
    % creating trialcondition matrix
    trialcondition = ones(1,num_trials);
    % first two trials are shown binocularly
    trialcondition(1) = 3;
    trialcondition(2) = 3;
    % two for loops below randomize the trialconditions for each trial
    % random trial conditions are saved in trialcondition matrix
    a = ones(NTrials,length(quests));
    for j = 1:NTrials
        a(j,:) = randperm(length(quests));
    end
    for j = 1:NTrials*length(quests)
        trialcondition(j+2) = a(j);
    end
    % a matrix to record if subject responsed correctly at each trial
    correctResp = zeros(1,num_trials); 
    % a matrix to record the duration of each trial
    t = zeros(1,num_trials); 
    % create the matrix that saves the percentage of coherent dots for each trial
    c_percent = zeros(1,num_trials);
    % create a cell that saves the direction of coherent dots for each trial
    coherent_dir = cell(1,num_trials);
    % create a cell that saves the pressed keyboard button for each trial
    keyCode = cell(1,num_trials);
    
%% 7. Calibration phase 
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

%% 8. Initial dot positions
    left_r_rect = round(left_stimRect);                 % left rect of random dots
    left_c_rect = round(left_stimRect);                 % left rect of coherent dots

    right_r_rect = round(right_stimRect);               % right rect of random dots
    right_c_rect = round(right_stimRect);               % right rect of coherent dots

%% 9. External loop
    for i = 1:length(trialcondition)
        responded = 0;  % Resetting response to zero
        % getting the quest suggested value for percentage of coherent dots
        c_percent(i) = QuestMean(quests{trialcondition(i)});
        % adjusting the quest suggested value for percentage of coherent dots
        if c_percent(i) <= 0
            c_percent(i) = 0.001;
        elseif c_percent(i) >= 1
            c_percent(i) = 0.999;
        end
        WaitSecs(TIP); % wait TIP before going to next trial
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

            % update initial dot positions if calibration changes
            left_r_rect = round(left_stimRect);                 % rect of random dots
            left_c_rect = round(left_stimRect);                 % rect of coherent dots
            right_r_rect = round(right_stimRect);               % rect of random dots
            right_c_rect = round(right_stimRect);               % rect of coherent dots
            WaitSecs(0.5);  % wait half a second before resuming the experiment
        end % end of break time
       
    %% 9.2. Random dots configurations
        % Calculate number of random dots
        n_rdots = round(ndots.*(1-c_percent(i)));

        % Calculate random dots coordinations in LEFT side
        left_r_x = randi([left_r_rect(1) left_r_rect(3)],n_rdots,1);	% random dots x coordinates
        left_r_y = randi([left_r_rect(2) left_r_rect(4)],n_rdots,1);	% random dots y coordinates
        left_r_xy = [left_r_x left_r_y];                                % random dot positions
        left_r_xymatrix = transpose(left_r_xy);                         % xy matrix of random dots for left side of screen

        % Calculate random dots coordinations in RIGHT side based on dots of left side
        right_r_x = left_r_x-xOffset(1)+xOffset(2);	        % random dots x coordinates
        right_r_y = left_r_y-yOffset(1)+yOffset(2);	        % random dots y coordinates
        right_r_xy = [right_r_x right_r_y];                 % random dot positions
        right_r_xymatrix = transpose(right_r_xy);           % xy matrix of random dots for right side of screen

        % Calculate random dots movement
        r_mdirx = (2 .* rand(n_rdots,1)) - 1;    % motion direction (in x) for each dot (-1 or 1)
        r_dirx = pfs .* r_mdirx;                 % change in x direction in radius per frame (pixels)
        r_mdiry = (2 .* rand(n_rdots,1)) - 1;    % motion direction (in y) for each dot (-1 or 1)
        r_diry = pfs .* r_mdiry;                 % change in y direction in radius per frame (pixels)
        r_dirxy = [r_dirx r_diry];               % change in x and y per frame (pixels)

	%% 9.3. Coherent dots configurations 
        % Calculate number of coherent dots
        n_cdots = round(ndots.*c_percent(i));

        % Calculate coherent dots coordinations in LEFT side
        left_c_x = randi([left_c_rect(1) left_c_rect(3)],n_cdots,1);    % coherent dots x coordinates
        left_c_y = randi([left_c_rect(2) left_c_rect(4)],n_cdots,1);	% coherent dots y coordinates
        left_c_xy = [left_c_x left_c_y];                                % coherent dot positions
        left_c_xymatrix = transpose(left_c_xy);                         % xy matrix of coherent dots for left side of screen

        % Calculate coherent dots coordinations in RIGHT side based on dots of left side
        right_c_x = left_c_x-xOffset(1)+xOffset(2);     % coherent dots x coordinates
        right_c_y = left_c_y-yOffset(1)+yOffset(2);	    % coherent dots y coordinates
        right_c_xy = [right_c_x right_c_y];             % coherent dot positions
        right_c_xymatrix = transpose(right_c_xy);       % xy matrix of coherent dots for right side of screen

        % randomly selects one of the directions specified for movement of coherent dots
        coherent_dir{i} = directions(:,randi(4)); 
        % limit the direction of coherent dots in conditions that only allow horizontal movement ('Binasal_Horizontal' and 'Altitudinal_Horizontal')
        if trialcondition(i) == 4 || trialcondition(i) == 6
            coherent_dir{i} = directions(:,randi(2));
        % limit the direction of coherent dots in conditions that only allow vertical movement ('Binasal_Vertical' and 'Altitudinal_Vertical')
        elseif trialcondition(i) == 5 || trialcondition(i) == 7
            coherent_dir{i} = directions(:,randi(3:4));
        end
        c_xdirection = coherent_dir{i}(1);          % x direction of coherent dots movement
        c_ydirection = coherent_dir{i}(2);          % y direction of coherent dots movement
        c_mdirx = ones(n_cdots,1).*c_xdirection;    % motion direction (in x) for each dot
        c_dirx = pfs .* c_mdirx;                    % change in x direction in radius per frame (pixels)
        c_mdiry = ones(n_cdots,1).*c_ydirection;    % motion direction (in y) for each dot
        c_diry = pfs .* c_mdiry;                    % change in y direction in radius per frame (pixels)
        c_dirxy = [c_dirx c_diry];                  % change in x and y per frame (pixels)

    %% 9.4. Animation loop
        tic % start timing the trial
        
        % Add frame to experiment movie
        %Screen('AddFrameToMovie', win, CenterRect([0 0 1920 1080], Screen('Rect', screenid)), 'backBuffer');
        
        [timeNow] = Screen('Flip',win);
        timeStart = timeNow;
        % Print to console the Trial number and Condition
        fprintf('Trial %d:\tCondition: %s\t\tCoherent percent: %.3f...\t', i, condition_name{trialcondition(i)}, c_percent(i));
        % start the loop for showing stimuli in a trial
        while timeNow < timeStart + TPT && ~responded
            if trialcondition(i) ~= 2 % 2 = Right only condition             
                % Drawing on LEFT side of screen
                Screen('SelectStereoDrawBuffer', win, 0);
                % Draw dots:
                Screen('DrawDots', win, left_r_xymatrix, s, r_color, [0 0], 1); 
                Screen('DrawDots', win, left_c_xymatrix, s, c_color, [0 0], 1);
                % Draw Scotomas if needed
                if trialcondition(i) == 4 || trialcondition(i) == 5 % 4 = Binasal_Horizontal, 5 = Binasal_Vertical 
                    DrawSmoothedScotoma_Binasal_Left(win,R0,scotoma_alpha,[xCenter_left left_stimRect(2) left_stimRect(3) left_stimRect(4)],smoothing_length, smoothing_res)
                elseif trialcondition(i) == 6 || trialcondition(i) == 7 % 6 = Altitudinal_Horizontal, 7 = Altitudinal_Vertical 
                    DrawSmoothedScotoma_Altitudinal_Top(win,R0,scotoma_alpha,[left_stimRect(1) left_stimRect(2) left_stimRect(3) yCenter_left],smoothing_length, smoothing_res)
                elseif trialcondition(i) == 8 % 8 = Checkered condition
                    DrawCheckeredScotomaLeft(win,R0,scotoma_alpha,left_stimRect,smoothing_length, smoothing_res);
                end
            end
            if trialcondition(i) ~= 1 % 1 = Left only condition
                % Drawing on RIGHT side of screen
                Screen('SelectStereoDrawBuffer', win, 1);
                % Draw dots:
                Screen('DrawDots', win, right_r_xymatrix, s, r_color, [0 0], 1);  
                Screen('DrawDots', win, right_c_xymatrix, s, c_color, [0 0], 1);
                % Draw Scotomas if needed
                if trialcondition(i) == 4 || trialcondition(i) == 5  % 4 = Binasal_Horizontal, 5 = Binasal_Vertical
                    DrawSmoothedScotoma_Binasal_Right(win,R0,scotoma_alpha,[right_stimRect(1) right_stimRect(2) xCenter_right right_stimRect(4)],smoothing_length, smoothing_res)
                elseif trialcondition(i) == 6 || trialcondition(i) == 7 % 6 = Altitudinal_Horizontal, 7 = Altitudinal_Vertical 
                    DrawSmoothedScotoma_Altitudinal_Down(win,R0,scotoma_alpha,[right_stimRect(1) yCenter_right right_stimRect(3) right_stimRect(4)],smoothing_length, smoothing_res)
                elseif trialcondition(i) == 8 % 8 = Checkered condition
                    DrawCheckeredScotomaRight(win,R0,scotoma_alpha,right_stimRect,smoothing_length, smoothing_res);
                end
            end
            % Draw the frame
            DrawFrame(win, xCenter, yCenter, noiseTex, xOffset, yOffset, stimRect);
            Screen('DrawingFinished', win); % Tell PTB that no further drawing commands will follow before Screen('Flip')

            % update coordinates on the LEFT side of the screen
            
            % update random dots coordinates
            left_r_x = left_r_x + r_dirx;  
            left_r_y = left_r_y + r_diry;
            left_r_xy = [left_r_x left_r_y]; 
            % update coherent dots coordinates
            left_c_x = left_c_x + c_dirx;  
            left_c_y = left_c_y + c_diry;
            left_c_xy = [left_c_x left_c_y];

            % update coordinates on the RIGHT side of the screen
            
            % update random dots coordinates
            right_r_x = right_r_x + r_dirx;  
            right_r_y = right_r_y + r_diry;
            right_r_xy = [right_r_x right_r_y];
            % update coherent dots coordinates
            right_c_x = right_c_x + c_dirx; 
            right_c_y = right_c_y + c_diry;
            right_c_xy = [right_c_x right_c_y];

            % check to see which RANDOM dots have gone beyond the borders of 
            % the frame, we make the frame 5 pixels smaller to avoid noises at
            % the edge of the stimulus rect when presenting scotomas
            r_out = find(left_r_x > left_r_rect(3)-5 | left_r_y > left_r_rect(4)-5 | left_r_x < left_r_rect(1)+5 | left_r_y < left_r_rect(2)+5);	% dots to reposition
            r_nout = length(r_out);
            if r_nout
            % choose new coordinates
                left_r_x(r_out) = randi([left_r_rect(1) left_r_rect(3)],r_nout,1);
                left_r_y(r_out) = randi([left_r_rect(2) left_r_rect(4)],r_nout,1);
                left_r_xy(r_out,:) = [left_r_x(r_out) left_r_y(r_out)];

                right_r_x(r_out) = left_r_x(r_out)-xOffset(1)+xOffset(2);
                right_r_y(r_out) = left_r_y(r_out)-yOffset(1)+yOffset(2);
                right_r_xy(r_out,:) = [right_r_x(r_out) right_r_y(r_out)];
            end

            left_r_xymatrix = transpose(left_r_xy);         %xy matrix of random dots for left side of screen
            right_r_xymatrix = transpose(right_r_xy);       %xy matrix of random dots for right side of screen

            % check to see which COHERENT dots have gone beyond the borders of
            % the frame, we make the frame 5 pixels smaller to avoid noises at
            % the edge of the stimulus rect when presenting scotomas
            c_out = find(left_c_x > left_c_rect(3)-4 | left_c_y > left_c_rect(4)-4 | left_c_x < left_c_rect(1)+4 | left_c_y < left_c_rect(2)+4);	% dots to reposition
            c_nout = length(c_out);
            if c_nout
            % choose new coordinates for left side of screen
                left_c_x(c_out) = randi([left_c_rect(1) left_c_rect(3)],c_nout,1);
                left_c_y(c_out) = randi([left_c_rect(2) left_c_rect(4)],c_nout,1);
                left_c_xy(c_out,:) = [left_c_x(c_out) left_c_y(c_out)];
            % choose new coordinates for left side of screen
                right_c_x(c_out) = left_c_x(c_out)-xOffset(1)+xOffset(2);
                right_c_y(c_out) = left_c_y(c_out)-yOffset(1)+yOffset(2);
                right_c_xy(c_out,:) = [right_c_x(c_out) right_c_y(c_out)];
            end

            left_c_xymatrix = transpose(left_c_xy);         %xy matrix of coherent dots for left side of screen
            right_c_xymatrix = transpose(right_c_xy);       %xy matrix of coherent dots for right side of screen


            % Add frame to experiment movie
            %Screen('AddFrameToMovie', win, CenterRect([0 0 1920 1080], Screen('Rect', screenid)), 'backBuffer');

            timeNow=Screen('Flip', win, timeNow + (waitframes-0.5)*ifi);

            % Check if a key is pressed and if the correct answer is given
            [~,~,keyCode{i}] = KbCheck;
            if keyCode{i}(key.left)
                responded = 1;
                if isequal(coherent_dir{i}, [-1;0]) % check if correct answer is left
                    correctResp(i) = 1;
                else
                    correctResp(i) = 0;
                end
            elseif keyCode{i}(key.right)
                responded = 1;
                if isequal(coherent_dir{i}, [1;0]) % check if correct answer is right
                    correctResp(i) = 1;
                else
                    correctResp(i) = 0;
                end
            elseif keyCode{i}(key.up)
                responded = 1;
                if isequal(coherent_dir{i}, [0;-1]) % check if correct answer is up
                    correctResp(i) = 1;
                else
                    correctResp(i) = 0;
                end                           
            elseif keyCode{i}(key.down)
                responded = 1;
                if isequal(coherent_dir{i}, [0;1]) % check if correct answer is down
                    correctResp(i) = 1;
                else
                    correctResp(i) = 0;
                end
            end  
        end % End of animation loop

    %% 9.5. Pause screen
        DrawFrame(win, xCenter, yCenter, noiseTex, xOffset, yOffset, stimRect);
        
        % Add frame to experiment movie
        %Screen('AddFrameToMovie', win, CenterRect([0 0 1920 1080], Screen('Rect', screenid)), 'backBuffer');

        Screen('Flip', win);    
       
        % wait for response if not given previously
        while responded == 0
            [~,~,keyCode{i}] = KbCheck;
            if keyCode{i}(key.left)
                responded = 1;
                if isequal(coherent_dir{i}, [-1;0]) % check if correct answer is left
                    correctResp(i) = 1;
                else
                    correctResp(i) = 0;
                end
            elseif keyCode{i}(key.right)
                responded = 1;
                if isequal(coherent_dir{i}, [1;0]) % check if correct answer is right
                    correctResp(i) = 1;
                else
                    correctResp(i) = 0;
                end
            elseif keyCode{i}(key.up)
                responded = 1;
                if isequal(coherent_dir{i}, [0;-1]) % check if correct answer is up
                    correctResp(i) = 1;
                else
                    correctResp(i) = 0;
                end                           
            elseif keyCode{i}(key.down)
                responded = 1;
                if isequal(coherent_dir{i}, [0;1]) % check if correct answer is down
                    correctResp(i) = 1;
                else
                    correctResp(i) = 0;
                end
            end
        end
        t(i) = toc; % saving the time of trial
        
        % Updating quest after the third trial based on different conditions
        if i>2
            quests{trialcondition(i)}=QuestUpdate(quests{trialcondition(i)},c_percent(i),correctResp(i));
        end
        % print to the console the result of each trial
        if correctResp(i)
            fprintf('Hit\n');
        else
            fprintf('Miss\n');
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
                0,1,1; % quests(4) = Cyan (Binasal_Horizontal)
                1,0,1; % quests(5) = Magenta (Binasal_Vertical)
                1,0.5,0; % quests(6) = Orange (Altitudinal_Horizontal)
                0.5,0,0.5; % quests(7) = Purple (Altitudinal_Vertical)
                1,1,0]; % quests(8) = Yellow (Checkered scotoma)
    
    % Loop through each quest
    for q = 1:length(quests)
        
        % Extract stimulus levels and responses for the current quest
        stimulus_level = quests{q}.intensity(1:NTrials);
        stimulus_responses = quests{q}.response(1:NTrials);
        
        % Define plot options for the current quest
        plotOptions = struct;
        plotOptions.lineColor = colors(q,:);
        plotOptions.dataColor = plotOptions.lineColor;
        
        % Round stimulus levels to 3 decimal places
        stimulus_level = round(stimulus_level, 3);
        
        % Find unique stimulus levels
        stimulus_unique = unique(stimulus_level);
        
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
        options.sigmoidName = 'logistic'; % Choose a cumulative Gauss as the sigmoid (can also be 'norm' or 'weibull')
        options.expType = '4AFC';         % Choose 4-AFC as the experiment type
        
        % Fit psychometric function using psignifit
        result = psignifit(data, options);
        
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
        filename = sprintf('/home/leo/Desktop/Mehrdad/Experiments/data_Coherent_Dots/%i.csv', casenr);
        for i = 1:length(c)
            dlmwrite(filename,[date,casenr,c(i),scotoma_alpha,stimRectsize,...
                QuestMean(quests{i}),QuestMode(quests{i}),QuestQuantile(quests{i}),QuestSd(quests{i}),refitted_result(i),...
                dot_speed,ndots,dot_w,TPT,quests{i}.trialCount, ...
                tGuess,tGuessSd,range,beta],'-append','delimiter',','); %#ok<DLMWT>
        % Saves in a single row: Date, Patient number, Viewing Condition, Scotoma alpha level (Transparency) and stim Rect size
        % Results including Quest Mean, Quest Mode, Quest Quantile, Quest SD, Threshold after refitting data on a psychometric function (Main result)
        % Test Parameters including dots speed, number of dots, dots' width, Number of trials, 
        % Quest variables, including tGuess, tGuessSD, range and beta of each condition.
        end
    end

