function DrawFrame_wo_center(w, xCenter, yCenter, noiseTex, xOffset, yOffset, stimRect)
    % Draws stimulus borders to help with fusion
    
    stimRectLeft = CenterRectOnPoint(stimRect', xCenter + xOffset(1), yCenter + yOffset(1))';
    stimRectRight = CenterRectOnPoint(stimRect', xCenter + xOffset(2), yCenter + yOffset(2))';
    
    %apertureRectLeft = [stimRectLeft(1)-25 stimRectLeft(2)-25 stimRectLeft(3)+25 stimRectLeft(4)+25]';
    %apertureRectRight = [stimRectRight(1)-25 stimRectRight(2)-25 stimRectRight(3)+25 stimRectRight(4)+25]';
    
    RightUpperNoisePos = [stimRectRight(1)-50 stimRectRight(2)-50 stimRectRight(3)+50 stimRectRight(2)-25];
    RightLowerNoisePos = [stimRectRight(1)-50 stimRectRight(4)+25 stimRectRight(3)+50 stimRectRight(4)+50];
    RightRightNoisePos = [stimRectRight(1)-50 stimRectRight(2)-50 stimRectRight(1)-25 stimRectRight(4)+50];
    RightLeftNoisePos = [stimRectRight(3)+25 stimRectRight(2)-50 stimRectRight(3)+50 stimRectRight(4)+50];
    %fusionRectLeft = [stimRectLeft(1)-50 stimRectLeft(2)-50 stimRectLeft(3)+50 stimRectLeft(4)+50]';
    %fusionRectRight = [stimRectRight(1)-50 stimRectRight(2)-50 stimRectRight(3)+50 stimRectRight(4)+50]';
    LeftUpperNoisePos = [stimRectLeft(1)-50 stimRectLeft(2)-50 stimRectLeft(3)+50 stimRectLeft(2)-25];
    LeftLowerNoisePos = [stimRectLeft(1)-50 stimRectLeft(4)+25 stimRectLeft(3)+50 stimRectLeft(4)+50];
    LeftRightNoisePos = [stimRectLeft(1)-50 stimRectLeft(2)-50 stimRectLeft(1)-25 stimRectLeft(4)+50];
    LeftLeftNoisePos = [stimRectLeft(3)+25 stimRectLeft(2)-50 stimRectLeft(3)+50 stimRectLeft(4)+50];
    
    leftXCenter = xCenter+xOffset(1);  rightXCenter = xCenter+xOffset(2);
    leftYCenter = yCenter+yOffset(1);  rightYCenter = yCenter+yOffset(2);
    
    % Still to change rest of variable names
    
    % left eye
    Screen('SelectStereoDrawBuffer', w, 0);
    Screen('DrawTexture', w, noiseTex, [], LeftUpperNoisePos,[],[],1,[],[],[],[0.5,0,0,1]);
    Screen('DrawTexture', w, noiseTex, [], LeftLowerNoisePos,[],[],1,[],[],[],[0.5,0,0,1]);
    Screen('DrawTexture', w, noiseTex, [], LeftLeftNoisePos,[],[],1,[],[],[],[0.5,0,0,1]);
    Screen('DrawTexture', w, noiseTex, [], LeftRightNoisePos,[],[],1,[],[],[],[0.5,0,0,1]);
    Screen('DrawLine', w, [0 0 0 1], leftXCenter, stimRectLeft(2)-25, leftXCenter, stimRectLeft(2), 4);
    Screen('DrawLine', w, [0 0 0 1], leftXCenter, stimRectLeft(4), leftXCenter, stimRectLeft(4)+25, 4);
    Screen('DrawLine', w, [0 0 0 1], stimRectLeft(1)-25, leftYCenter, stimRectLeft(1), leftYCenter, 4);
    Screen('DrawLine', w, [0 0 0 1], stimRectLeft(3), leftYCenter, stimRectLeft(3)+25, leftYCenter, 4);
    
    
    % right eye
    Screen('SelectStereoDrawBuffer', w, 1);
    Screen('DrawTexture', w, noiseTex, [], RightUpperNoisePos,[],[],1,[],[],[],[0.5,0,0,1]);
    Screen('DrawTexture', w, noiseTex, [], RightLowerNoisePos,[],[],1,[],[],[],[0.5,0,0,1]);
    Screen('DrawTexture', w, noiseTex, [], RightLeftNoisePos,[],[],1,[],[],[],[0.5,0,0,1]);
    Screen('DrawTexture', w, noiseTex, [], RightRightNoisePos,[],[],1,[],[],[],[0.5,0,0,1]);
    Screen('DrawLine', w, [0 0 0 1], rightXCenter, stimRectRight(2)-25, rightXCenter, stimRectRight(2), 4);
    Screen('DrawLine', w, [0 0 0 1], rightXCenter, stimRectRight(4), rightXCenter, stimRectRight(4)+25, 4);
    Screen('DrawLine', w, [0 0 0 1], stimRectRight(1)-25, rightYCenter, stimRectRight(1), rightYCenter, 4);
    Screen('DrawLine', w, [0 0 0 1], stimRectRight(3), rightYCenter, stimRectRight(3)+25, rightYCenter, 4);
    
end