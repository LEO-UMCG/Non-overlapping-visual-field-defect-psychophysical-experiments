%%  Line test
    % Original script: Mehrdad Gazanchian (basic layout, programming and testing) and Nomdo Jansonius (supervision)
    % This version is adapted for Linux (matlab-psychtoolbox-3).
    % Latest change: 20 Nov 2023 by MG
    % (c) Laboratory of Experimental Ophthalmology, University Medical Center groningen, University of Groningen
    % To be cited as:

    %%% OBJECTIVE %%%
    % This .m file provides line test and a quest method is used to determine
    % minimum amplitude required for subjects to see line movement (Dmin)

    % This script is adjusted to show psychophysical experiments in a dichoptic setup with a stereoscope. 
    % For more info about the experiment setup read the article.

    % The scripts shows two set of three lines. The middle line is oscillating either on the left set or the right set. 
    % The subject should press the left arrow or right arrow key based on which set has the oscillating line. \
    % Based on the response the script determines the amplitude of the next presentation. 
    % Once enough data points have been acquired, the script automatically stops.

    % After the experiment, data analysis is automatically performed and the threshold for Dmin is calculated.
    % Data are automatically saved in a .csv file on the desktop.

    % The script can be aborted during the experiment by pressing the ctrl+c button.
    % This script requires psignifit toolbox available from:
    % https://uni-tuebingen.de/en/fakultaeten/mathematisch-naturwissenschaftliche-fakultaet/fachbereiche/informatik/lehrstuehle/neuronale-informationsverarbeitung/research/software/psignifit/
    % This script requires psychtoolbox 3 available from:
    % http://psychtoolbox.org/download.html
    % You can use the script as is or change it according to your specific needs as long as you cite it.

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
            % 9.2. Animation Loop: The animation loop for one trial
                % 9.2.1. Setting up lines for presentation: Preparing the line locations and color modulation based on time elapsed in each trial
                % 9.2.2. Producing textures on screen: Drawing the lines on screen
                % 9.2.3. Checking for response: Checking the keyboard to see if tge participant has answered or not
            % 9.3. Pause Screen: the pause screen in between trials used for collecting responses (if not yet) and updating the Quest to show the appropriate stimuli for next trial
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
    %movie = Screen('CreateMovie', win, 'Linetest.mov', rect(3)*2, rect(4), 40, ':CodecSettings=Videoquality=0.8 Profile=2');

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
    tGuess = 25;      % Initial guess of threshold value
    tGuessSd = 15;    % Initial guess of standard deviation
    pThreshold =0.75;  % Threshold for the probability of correct response
    beta = 3.5;         % Parameter for the Weibull function
    delta = 0.01;       % Step size of the psychometric function
    gamma = 0.5;       % Guess rate
    grain = 0.5;       % Granularity of the internal representation of the psychometric function
    range = 50;        % Range of the internal representation of the psychometric function
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
    % 'Left eye' condition shows the stimuli monocularly to the left eye only
    % 'Right eye' condition shows the stimuli monocularly to the right eye only
    % 'Binocular' condition shows the stimuli binocularly
    % 'Binasal' condition only shows the stimuli binocularly in the Binasal scotoma condition
    % 'Altitudinal' condition only shows the stimuli binocularly in the Top down scotoma condition
    % 'Checkered' condition shows the stimuli binocularly in the checkered scotoma condition
    condition_name = {'Left eye', 'Right eye', 'Binocular', 'Binasal', 'Altitudinal', 'Checkered'};

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
    % Size and luminance of mask
    LM = L0;			% Default value of mask luminance is average background luminance
    D = 7;  			% Diameter of mask in arc degrees; default value is 1 arc degree (diameter of fovea)
    RM = monitorfunctie(LM)/255;	% Calculate RGB value of mask (/255 for standardization)
    Dpix=(2*pi*viewD*D/360)*den;	% Diameter of the mask from arc degrees to pixels
    m=0.08; % Modulation depth
    half_w=D/2; % Half line width in arcminutes
    half_w_pix=half_w*2*pi*viewD*den/360/60;	% Half line width from arc minutes to pixels
    f=2; % Modulation frequency in Hz
    LL = 0; % Index value of line luminance
    RL = monitorfunctie(LL)/255; 	% Calculate RGB value of line L (/255 for standardization)
    
    NTrials=60;				    % Number of trials
    TPT=1; 				        % Time per trial
    TIP=0.5; 			        % Time in between trials
    scotoma_alpha = 1;          % the alpha level of the scotomas shown
    smoothing_length = 0.10;    % the percentage of scotoma that we want to smooth
    smoothing_res = 30;         % the resolution of smoothing, too much resolution causes slowing of stimulus presentation 
    linespace = 1;              % the space between lines (arc degree)
    linespacePix = (2*pi*viewD*linespace/360)*den;   % the space between lines (pixels)
    % calculate the number of trials needed based on number of quests and NTrials,
    % +2 is because we start updating quest after 3rd trial and first two trials are not important, 
    % they're just to get the participant ready
    num_trials = NTrials*length(quests)+2;
    % creating trialcondition matrix
    trialcondition = ones(1,num_trials);
    % first two trials are shown binocularly
    trialcondition(1) = 3;
    trialcondition(2) = 3;
    % two for loops below randomize the trialconditions for each trial, and
    % random trial conditions are saved in trialcondition matrix
    e = ones(NTrials,length(quests));
    for j = 1:NTrials
        e(j,:) = randperm(length(quests));
    end
    for j = 1:NTrials*length(quests)
        trialcondition(j+2) = e(j);
    end
    % a matrix to record if subject responsed correctly at each trial
    correctResp = zeros(1,num_trials); 
    % a matrix to record the duration of each trial
    t = zeros(1,num_trials); 
    % create the matrix that saves amplitude of movement for each trial
    M_amplitude = zeros(1,num_trials);
    % create a matrix that saves which line was moving in each trial
    Moving_line = randi(2,1,num_trials); % randomize line that is moving 1 = left 2 = right
    Line_name = {'Left line', 'Right line'};
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

%% 9. External loop
    for i = 1:num_trials
        KbReleaseWait();
        t1=0;  % Resetting individual stimulus timer
        responded=0;   % Resetting response to zero
        % setting amplitude of oscillations according to quest suggestion and our limits
        M_amplitude(i)=QuestMean(quests{trialcondition(i)}); % getting quest suggestion
        % limiting quest suggestion to our limits
        if M_amplitude(i) <= 0.1
           M_amplitude(i) = 0.1;
        end
        M_amplitude_pix=M_amplitude(i)*2*pi*viewD*den/360/60/60;	    % Convert amplitude of oscillation from arc seconds to pixels
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
            WaitSecs(0.5) % wait half a second before resuming the experiment
        end % end of break time
	    
    %% 9.2 Animation Loop
        tic % start timing the trial

        % Add frame to experiment movie
        %Screen('AddFrameToMovie', win, CenterRect([0 0 1920 1080], Screen('Rect', screenid)), 'backBuffer');
        
        [timeNow] = Screen('Flip',win);
        timeStart = timeNow;
        % Print to console the Trial number and Condition
        fprintf('Trial %d:\tCondition: %s\t\tMoving line: %s\tAmplitude: %.1f...\t', i, condition_name{trialcondition(i)}, Line_name{Moving_line(i)}, M_amplitude(i));
        % start the loop for showing stimuli in a trial
        while timeNow < timeStart + TPT && ~responded       
            % calculation of line positions without taking into account the x and y offset
	        xL = 0.5*w - 2*linespacePix;    % Default Left line position  
            xR = 0.5*w + 2*linespacePix;    % Default Right line position
            xLL = xL - linespacePix;        % Default Left Left flanker line position
            xLR = xL + linespacePix;        % Default Left Right flanker line position
            xRL = xR - linespacePix;        % Default Right Left flanker line position
            xRR = xR + linespacePix;        % Default Right Right flanker line position

            t1 = toc;       % the timestamp used for calculating movement and luminance
            if Moving_line(i) == 1
                % make the left middle line move
                xL = M_amplitude_pix*sin(2*pi*f*t1)+xL ;     % calculating the X position of left middle line based on time
            elseif Moving_line(i) == 2
                % make the right middle line move
                xR=M_amplitude_pix*sin(2*pi*f*t1)+xR ;       % calculating the X position of right middle line based on time
            end
            
           
            %% 9.2.1. Setting up lines for presentation
            % CALCULATION OF LUMINANCES (Changing luminance makes the movement of line smoother)
            L1= L0*(1-m*sin(2*pi*f*t1)); % Luminance index of left  surface as a function of time			
            L2= L0*(1+m*sin(2*pi*f*t1)); % Luminance index of right surface as a function of time
        
            % Calculating luminance for boundaries of middle line (Adding
            % boundaries with modulating luminance to the moving line makes
            % the movement smoother)
            LLLa = L1+(ceil(xL-half_w_pix)-(xL-half_w_pix))*(LL-L1); 	            % modulation depth left boundary of middle line
            LLLb = L2+((xL+half_w_pix)-floor(xL+half_w_pix))*(LL-L2);	            % modulation depth right boundary of middle line
    
            RLLa = L1+(ceil(xR-half_w_pix)-(xR-half_w_pix))*(LL-L1); 	            % modulation depth left boundary of middle line
            RLLb = L2+((xR+half_w_pix)-floor(xR+half_w_pix))*(LL-L2);	            % modulation depth right boundary of middle line
    
            % CALCULATION OF CORRESPONDING RGB VALUES:
            RLLLa = monitorfunctie(LLLa)/255;	% Calculate R value for left boundary (/255 for standardization)
            RLLLb = monitorfunctie(LLLb)/255;	% Calculate R value for right boundary (/255 for standardization)
    
            RRLLa = monitorfunctie(RLLa)/255;	% Calculate R value for left boundary (/255 for standardization)
            RRLLb = monitorfunctie(RLLb)/255;	% Calculate R value for right boundary (/255 for standardization)
            
            %% 9.2.2. Producing textures on Screen
            if trialcondition(i) ~= 2
                % Drawing on the left part of screen
                Screen('SelectStereoDrawBuffer', win, 0);
                % Drawing the lines
                Screen('FillRect',win,[RL RL RL 1], [ceil(xL-half_w_pix+xOffset(1)) 0 floor(xL+half_w_pix+xOffset(1)) h]);	    % Left Middle line
                Screen('FillRect',win,[RL RL RL 1], [ceil(xLL-half_w_pix+xOffset(1))  0 floor(xLL+half_w_pix+xOffset(1)) h]);   % Left Left flanker line
                Screen('FillRect',win,[RL RL RL 1], [ceil(xLR-half_w_pix+xOffset(1))  0 floor(xLR+half_w_pix+xOffset(1)) h]);	% Left Right flanker line
                
                Screen('FillRect',win,[RL RL RL 1], [ceil(xR-half_w_pix+xOffset(1)) 0 floor(xR+half_w_pix+xOffset(1)) h]);	    % Right Middle line
                Screen('FillRect',win,[RL RL RL 1], [ceil(xRL-half_w_pix+xOffset(1))  0 floor(xRL+half_w_pix+xOffset(1)) h]);	% Right left flanker line
                Screen('FillRect',win,[RL RL RL 1], [ceil(xRR-half_w_pix+xOffset(1))  0 floor(xRR+half_w_pix+xOffset(1)) h]);	% Right right flanker line
    
                
                % Drawing boundries for the moving lines (it makes the movement smoother)
                Screen('FillRect',win,[RLLLa RLLLa RLLLa 1], [floor(xL-half_w_pix+xOffset(1)) 0 ceil(xL-half_w_pix+xOffset(1)) h]);		% Left line left boundary
                Screen('FillRect',win,[RLLLb RLLLb RLLLb 1], [floor(xL+half_w_pix+xOffset(1)) 0 ceil(xL+half_w_pix+xOffset(1)) h]);		% Left line right boundary
    
                Screen('FillRect',win,[RRLLa RRLLa RRLLa 1], [floor(xR-half_w_pix+xOffset(1)) 0 ceil(xR-half_w_pix+xOffset(1)) h]);		% Right line left boundary
                Screen('FillRect',win,[RRLLb RRLLb RRLLb 1], [floor(xR+half_w_pix+xOffset(1)) 0 ceil(xR+half_w_pix+xOffset(1)) h]);		% Right line right boundary
                
                % The next lines summon a mask which is used to confine the lines height:
                Screen('FillRect',win,[RM RM RM 1], [0 0 w round(((h-Dpix)/2)+yOffset(1))]); % upper surface
                Screen('FillRect',win,[RM RM RM 1], [0 round(((h+Dpix)/2)+yOffset(1)) w h]); % lower surface
                % Drawing the Scotoma if needed
                if trialcondition(i) == 4
                    DrawSmoothedScotoma_Binasal_Left(win,R0,scotoma_alpha,[xCenter_left left_stimRect(2) left_stimRect(3) left_stimRect(4)],smoothing_length, smoothing_res);
                elseif trialcondition(i) == 5
                    DrawSmoothedScotoma_Altitudinal_Top(win,R0,scotoma_alpha,[left_stimRect(1) left_stimRect(2) left_stimRect(3) yCenter_left],smoothing_length, smoothing_res);
                elseif trialcondition(i) == 6
                    DrawCheckeredScotomaLeft(win,R0,scotoma_alpha,left_stimRect,smoothing_length, smoothing_res);
                end
            end
    
            if trialcondition(i) ~= 1
                % Drawing on the right part of screen
                Screen('SelectStereoDrawBuffer', win, 1);
                % Drawing the line
                Screen('FillRect',win,[RL RL RL 1], [ceil(xL-half_w_pix+xOffset(2))  0 floor(xL+half_w_pix+xOffset(2)) h]);		% Left Middle line
                Screen('FillRect',win,[RL RL RL 1], [ceil(xLL-half_w_pix+xOffset(2))  0 floor(xLL+half_w_pix+xOffset(2)) h]);	% Left left flanker line
                Screen('FillRect',win,[RL RL RL 1], [ceil(xLR-half_w_pix+xOffset(2))  0 floor(xLR+half_w_pix+xOffset(2)) h]);	% Left right flanker line
                
                Screen('FillRect',win,[RL RL RL 1], [ceil(xR-half_w_pix+xOffset(2))  0 floor(xR+half_w_pix+xOffset(2)) h]);		% Right Middle line
                Screen('FillRect',win,[RL RL RL 1], [ceil(xRL-half_w_pix+xOffset(2))  0 floor(xRL+half_w_pix+xOffset(2)) h]);	% Right right flanker line
                Screen('FillRect',win,[RL RL RL 1], [ceil(xRR-half_w_pix+xOffset(2))  0 floor(xRR+half_w_pix+xOffset(2)) h]);	% Right left flanker line
                       
                % Drawing boundries for the moving lines (it makes the movement smoother)
                Screen('FillRect',win,[RLLLa RLLLa RLLLa 1], [floor(xL-half_w_pix+xOffset(2)) 0 ceil(xL-half_w_pix+xOffset(2)) h]);		% left line left boundary
                Screen('FillRect',win,[RLLLb RLLLb RLLLb 1], [floor(xL+half_w_pix+xOffset(2)) 0 ceil(xL+half_w_pix+xOffset(2)) h]);		% left line right boundary
    
                Screen('FillRect',win,[RRLLa RRLLa RRLLa 1], [floor(xR-half_w_pix+xOffset(2)) 0 ceil(xR-half_w_pix+xOffset(2)) h]);		% right line left boundary
                Screen('FillRect',win,[RRLLb RRLLb RRLLb 1], [floor(xR+half_w_pix+xOffset(2)) 0 ceil(xR+half_w_pix+xOffset(2)) h]);		% right line right boundary
                
                % The next lines summon a mask which is used to confine the lines height:
                Screen('FillRect',win,[RM RM RM 1], [0 0 w round(((h-Dpix)/2)+yOffset(2))]); % upper surface
                Screen('FillRect',win,[RM RM RM 1], [0 round(((h+Dpix)/2)+yOffset(2)) w h]); % lower surface
                
                % Drawing the Scotoma if needed
                if trialcondition(i) == 4
                    DrawSmoothedScotoma_Binasal_Right(win,R0,scotoma_alpha,[right_stimRect(1) right_stimRect(2) xCenter_right right_stimRect(4)],smoothing_length, smoothing_res);
                elseif trialcondition(i) == 5
                    DrawSmoothedScotoma_Altitudinal_Down(win,R0,scotoma_alpha,[right_stimRect(1) yCenter_right right_stimRect(3) right_stimRect(4)],smoothing_length, smoothing_res);
                elseif trialcondition(i) == 6
                    DrawCheckeredScotomaRight(win,R0,scotoma_alpha,right_stimRect,smoothing_length, smoothing_res);
                end
            end
                  
            DrawFrame(win, xCenter, yCenter, noiseTex, xOffset, yOffset, stimRect);

            % Add frame to experiment movie
            %Screen('AddFrameToMovie', win, CenterRect([0 0 1920 1080], Screen('Rect', screenid)), 'backBuffer');
            Screen('Flip', win);
	    
	        %% 9.2.3. Checking for response 
	        [~,~,keyCode{i}] = KbCheck;
	        if keyCode{i}(key.left)
                responded=1;        % This indicates a response has been given
                if Moving_line(i) == 1
                    % check if left is pressed for left line movement
                    correctResp(i) = true;
                else
                    correctResp(i) = false;
                end
            elseif keyCode{i}(key.right)
                responded=1;        % This indicates a response has been given
                if Moving_line(i) == 2
                    % check if right is pressed for right line movement
                    correctResp(i) = true;
                else
                    correctResp(i) = false;
                end
	        end 
        end % end of animation loop
            
    %% 9.3 Pause screen 
        % Wait for response if not recieved already
        DrawFrame(win, xCenter, yCenter, noiseTex, xOffset, yOffset, stimRect)
        
        % Add frame to experiment movie
        %Screen('AddFrameToMovie', win, CenterRect([0 0 1920 1080], Screen('Rect', screenid)), 'backBuffer');
        
        Screen('Flip', win);
         
        % wait for response if not given previously
        while responded == 0
            [~,~,keyCode{i}] = KbCheck;
            if keyCode{i}(key.left)
                responded=1;        % This indicates a response has been given
                if Moving_line(i) == 1
                    % check if left is pressed for left line movement
                    correctResp(i) = true;
                else
                    correctResp(i) = false;
                end
            elseif keyCode{i}(key.right)
                responded=1;        % This indicates a response has been given
                if Moving_line(i) == 2
                    % check if right is pressed for right line movement
                    correctResp(i) = true;
                else
                    correctResp(i) = false;
                end
            end 
        end 

        t(i) = toc; % saving the time of trial
      
        % Updating quest after the third trial based on different conditions
        if i>2
            quests{trialcondition(i)}=QuestUpdate(quests{trialcondition(i)},M_amplitude(i),correctResp(i));
        end
        % print to the console the result of each trial
        if correctResp(i)
            fprintf('Hit\n');
        else
            fprintf('Miss\n');
        end
    end % end of external loop
    
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
% modulation depth, halfline width, background luminance, line luminance, and modulation frequency and Quest variables, including tGuess, tGuessSD, range and beta..
 save_data = 1; % set to zero if you do not want to save results
    if save_data
        date = round(str2double(datestr(now,'yymmdd')));
        c = 1:length(quests);
        % Set the file name for each casenr using the location you want to save
        filename = sprintf('/home/leo/Desktop/Mehrdad/Experiments/data_Linetest/%i.csv', casenr);
        for i = 1:length(c)
            dlmwrite(filename,[date,casenr,c(i),scotoma_alpha,stimRectsize,...
                QuestMean(quests{i}),QuestMode(quests{i}),QuestQuantile(quests{i}),QuestSd(quests{i}),refitted_result(i),...
                half_w*2,L0,LL,f,TPT,quests{i}.trialCount, ...
                tGuess,tGuessSd,range,beta],'-append','delimiter',','); %#ok<DLMWT>
        % Saves in a single row: Date, Patient number, Viewing Condition, Scotoma alpha level (Transparency) and stim Rect size
        % Results including Quest Mean, Quest Mode, Quest Quantile, Quest SD, Threshold after refitting data on a psychometric function (Main result)
        % Test Parameters including line width, background luminance, Line Luminance, modulation frequency, time per trial and Number of trials, 
        % Quest variables, including tGuess, tGuessSD, range and beta of each condition.
        end
    end

