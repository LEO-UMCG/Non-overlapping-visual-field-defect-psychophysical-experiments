function DrawFrame(w, xCenter, yCenter, noiseTex, xOffset, yOffset, stimRect)
    % Draws stimulus borders to help with fusion
   
    stimRectLeft = CenterRectOnPoint(stimRect', xCenter + xOffset(1), yCenter + yOffset(1))';
    stimRectRight = CenterRectOnPoint(stimRect', xCenter + xOffset(2), yCenter + yOffset(2))';
            
    Right_UpperNoisePos = [stimRectRight(1)-50 stimRectRight(2)-50 stimRectRight(3)+50 stimRectRight(2)-25];
    Right_LowerNoisePos = [stimRectRight(1)-50 stimRectRight(4)+25 stimRectRight(3)+50 stimRectRight(4)+50];
    Right_LeftNoisePos = [stimRectRight(1)-50 stimRectRight(2)-50 stimRectRight(1)-25 stimRectRight(4)+50];
    Right_RightNoisePos = [stimRectRight(3)+25 stimRectRight(2)-50 stimRectRight(3)+50 stimRectRight(4)+50];
    
    Left_UpperNoisePos = [stimRectLeft(1)-50 stimRectLeft(2)-50 stimRectLeft(3)+50 stimRectLeft(2)-25];
    Left_LowerNoisePos = [stimRectLeft(1)-50 stimRectLeft(4)+25 stimRectLeft(3)+50 stimRectLeft(4)+50];
    Left_LeftNoisePos = [stimRectLeft(1)-50 stimRectLeft(2)-50 stimRectLeft(1)-25 stimRectLeft(4)+50];
    Left_RightNoisePos = [stimRectLeft(3)+25 stimRectLeft(2)-50 stimRectLeft(3)+50 stimRectLeft(4)+50];
    
    leftXCenter = xCenter+xOffset(1);  rightXCenter = xCenter+xOffset(2);
    leftYCenter = yCenter+yOffset(1);  rightYCenter = yCenter+yOffset(2);
        
    % left eye
    Screen('SelectStereoDrawBuffer', w, 0);
    Screen('DrawTexture', w, noiseTex, [], Left_UpperNoisePos,[],[],1,[],[],[],[0.5,0,0,1]);
    Screen('DrawTexture', w, noiseTex, [], Left_LowerNoisePos,[],[],1,[],[],[],[0.5,0,0,1]);
    Screen('DrawTexture', w, noiseTex, [], Left_LeftNoisePos,[],[],1,[],[],[],[0.5,0,0,1]);
    Screen('DrawTexture', w, noiseTex, [], Left_RightNoisePos,[],[],1,[],[],[],[0.5,0,0,1]);
    Screen('DrawLine', w, [0 0 0 1], leftXCenter, stimRectLeft(2)-25, leftXCenter, stimRectLeft(2), 4);
    Screen('DrawLine', w, [0 0 0 1], leftXCenter, stimRectLeft(4), leftXCenter, stimRectLeft(4)+25, 4);
    Screen('DrawLine', w, [0 0 0 1], stimRectLeft(1)-25, leftYCenter, stimRectLeft(1), leftYCenter, 4);
    Screen('DrawLine', w, [0 0 0 1], stimRectLeft(3), leftYCenter, stimRectLeft(3)+25, leftYCenter, 4);
    Screen('FillOval', w, [0 0 0 1], [leftXCenter-5 leftYCenter-5 leftXCenter+5 leftYCenter+5]);
    
    % right eye
    Screen('SelectStereoDrawBuffer', w, 1);
    Screen('DrawTexture', w, noiseTex, [], Right_UpperNoisePos,[],[],1,[],[],[],[0.5,0,0,1]);
    Screen('DrawTexture', w, noiseTex, [], Right_LowerNoisePos,[],[],1,[],[],[],[0.5,0,0,1]);
    Screen('DrawTexture', w, noiseTex, [], Right_LeftNoisePos,[],[],1,[],[],[],[0.5,0,0,1]);
    Screen('DrawTexture', w, noiseTex, [], Right_RightNoisePos,[],[],1,[],[],[],[0.5,0,0,1]);
    Screen('DrawLine', w, [0 0 0 1], rightXCenter, stimRectRight(2)-25, rightXCenter, stimRectRight(2), 4);
    Screen('DrawLine', w, [0 0 0 1], rightXCenter, stimRectRight(4), rightXCenter, stimRectRight(4)+25, 4);
    Screen('DrawLine', w, [0 0 0 1], stimRectRight(1)-25, rightYCenter, stimRectRight(1), rightYCenter, 4);
    Screen('DrawLine', w, [0 0 0 1], stimRectRight(3), rightYCenter, stimRectRight(3)+25, rightYCenter, 4);
    Screen('FillOval', w, [0 0 0 1], [rightXCenter-5 rightYCenter-5 rightXCenter+5 rightYCenter+5]);
end