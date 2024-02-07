% This file will be called by csf.m and similar psychophysical scripts from our lab.
% It has to be placed in the same directory as the script.
% The function relates monitor luminance index to RGB value. 
% As such, it has to be adapted for the monitor "in charge"!

% Latest update: November 5, 2021 by Nomdo Jansonius

% (c) Laboratory of Experimental Ophthalmology, University Medical Center Groningen, University of Groningen

function [R] = monitorfunctie(Li)
% Input of this function is the desired luminance index (Li) (range 0-200); output is an RGB value (0-255).

% Example of a simplified monitorfunctie.m that assumes the max monitor luminance is 164 cd/m2
% (equal to Luminance index of 200) returns the RGB value of 255.
% The RGB value for other luminance index can be calculated using the formula specific for each monitor.
L = Li/(200/205);
if L >= 205
    R = 255;
elseif L <= 0.0001
    R = 0;
else
    R = ((-0.00003586).*(L.^3))+((0.00807).*(L.^2))+(1.042).*L+7.008;
end
end

% the script that calls monitorfunctie.m should limit the range of Li to 0-200!

% To calibrate a monitor for usage with csf.m, first search for the RGB value that results in the highest
% luminance (RGBmax). Next, measure the luminance for a series of RGB values below RGBmax and think up
% a function to describe the observed relationship between monitor luminance and RGB value.
