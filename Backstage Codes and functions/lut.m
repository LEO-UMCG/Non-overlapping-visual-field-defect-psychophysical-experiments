% Original script: Lucas Stam (programming and testing) and Nomdo Jansonius (concept and supervision)
% Latest change: 22 December 2014 by RB

% (c) Laboratory of Experimental Ophthalmology, University Medical Center Groningen, University of Groningen

% to be cited as: 

clear all
clc

% This script asks whether one wishes to obtain data for a new look-up table (LUT) or verify an existing LUT function.
% In the first case, the input to the monitor is an entered RGB value; in the second case, the input to the monitor is
% an RGB value calculated by a LUT function (by default in script monitorfunctie.m) via an entered luminance index.

% The psychophysical scripts call a LUT function named monitorfunctie.m. Ensure that this script is present in the same
% directory as the psychophysical scripts and make sure that it corresponds to the attached monitor! 

% R is RGB value with range 0-255; black and white => the same R value is attributed to red, green and blue.
% L is luminance index value (relative luminance of the screen) with range 0-200; L = 100 corresponds to 50% of maximum luminance.

reply= input('Wilt u een nieuwe LUT maken (1) of een bestaande monitorfunctie.m controleren (2)?  [1]');
if isempty(reply) % Default value in case no input is given
    reply=1;
end
if reply ~= 1 && reply ~= 2
    disp('Invoer moet 1 of 2 zijn');
    clear reply
reply= input('Wilt u een nieuwe LUT maken (1) of een bestaande monitorfunctie.m controleren (2)?  [1]');
if isempty(reply) % Default value in case no input is given
    reply=1;
end
end

% If reply is 1 then the required input is an RGB value; the luminance of the screen should subsequently be measured and,
% together with the RGB value, used to create a monitorfunctie.m script.
%
% The LUT function file monitorfunctie.m has input L and output R and should be created in such a way that (1) L = 200 gives
% the maximum luminance of the screen and (2) for L < 200 the luminance of the screen is linearly related to L.  
%

if reply ==1
R= input('R waarde [255; range 0-255]                ');
   if isempty(R) % Default value in case no input is given
   R=255;
   end
end

% If reply is 2 then the required input is a luminance index value; the corresponding measured luminance of the screen should
% be plotted against the luminance index and they should be related linearly (to check that monitorfunctie.m is correct)   
if reply ==2
L= input('Luminantie index [100; range 0-200]        ');
   if isempty(L) % Default value in case no input is given
   L=100;
   end
R = monitorfunctie(L); % Calculate RGB value R from luminance index value L
end


r= input('straal rondje (pixels) [180]               '); % radius of circle
if isempty(r) % Default value in case no input is given
    r=180;
end

% No bright white welcome screen of PSYCHTOOLBOX
Screen('Preference', 'VisualDebuglevel', 3);

screenid = max(Screen('Screens'));
button=0;

% Open window with black background color
win = Screen('OpenWindow', screenid, [0,0,0]);
[w, h] = Screen('WindowSize', win);
vbl=Screen('Flip', win);


while ~button(1)
    
% Query mouse
[xm, ym, button] = GetMouse;

Screen('FillOval',win,[R R R], [ w/2-r h/2-r w/2+r h/2+r]);
Screen('TextSize', win, 20);
Screen('DrawText', win, 'Klik op de linker muisknop als u klaar bent met meten', 100, 100, [250 250 250]);
Screen('Flip', win);

end

Screen('Close', win);
