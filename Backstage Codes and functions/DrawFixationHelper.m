function DrawFixationHelper(win, xScreen, yScreen, xOffset, yOffset, rTarget, widthTarget, RFT)
%% Objective
% the aim of this function is to draw fixation targets using parameters
% given:
% Required Parameters
% w: window
% xCenter and yCenter: x and y coordinates of the center of the screen
% xOffset and yOffset: number of pixel offset from the center of the screen
    
    XCenter = xScreen/2;
    YCenter = yScreen/2;
    
    % Left Fixation target coordinates
    lx1 = XCenter-rTarget+xOffset;
    lx2 = XCenter+rTarget+xOffset;
    ly1 = YCenter+rTarget+yOffset;
    ly2 = YCenter-rTarget+yOffset;

    % Right Fixation target coordinates
    rx1 = XCenter-rTarget-xOffset;
    rx2 = XCenter+rTarget-xOffset;
    ry1 = YCenter+rTarget-yOffset;
    ry2 = YCenter-rTarget-yOffset;
    


    % Drawing Left eye Fixation Target
    % Screen('SelectStereoDrawBuffer', win, 0);
    % Left part of fixation target
    Screen('FillRect',win,[RFT RFT RFT], [lx1-widthTarget  YCenter-widthTarget+yOffset  lx1+widthTarget  YCenter+widthTarget+yOffset]); 	
    % Right part of fixation target
    Screen('FillRect',win,[RFT RFT RFT], [lx2-widthTarget  YCenter-widthTarget+yOffset  lx2+widthTarget  YCenter+widthTarget+yOffset]); 
	% Upper part of fixation target	    
    Screen('FillRect',win,[RFT RFT RFT], [XCenter-widthTarget+xOffset  ly1-widthTarget  XCenter+widthTarget+xOffset  ly1+widthTarget]); 
	% Lower part of fixation target	    
    Screen('FillRect',win,[RFT RFT RFT], [XCenter-widthTarget+xOffset  ly2-widthTarget  XCenter+widthTarget+xOffset  ly2+widthTarget]); 
            
    % Drawing Right eye Fixation Target 
    % Screen('SelectStereoDrawBuffer', win, 1);
    %xOffset = xOffset*-1;
    %yOffset = yOffset*-1;
    % Left part of fixation target
    %Screen('FillRect',win,[RFT RFT RFT], [rx1-widthTarget  YCenter-widthTarget+yOffset  rx1+widthTarget  YCenter+widthTarget+yOffset]); 	
    % Right part of fixation target
    %Screen('FillRect',win,[RFT RFT RFT], [rx2-widthTarget  YCenter-widthTarget+yOffset  rx2+widthTarget  YCenter+widthTarget+yOffset]); 
	% Upper part of fixation target	    
    %Screen('FillRect',win,[RFT RFT RFT], [XCenter-widthTarget+xOffset  ry1-widthTarget  XCenter+widthTarget+xOffset  ry1+widthTarget]); 
	% Lower part of fixation target	    
    %Screen('FillRect',win,[RFT RFT RFT], [XCenter-widthTarget+xOffset  ry2-widthTarget  XCenter+widthTarget+xOffset  ry2+widthTarget]); 
end