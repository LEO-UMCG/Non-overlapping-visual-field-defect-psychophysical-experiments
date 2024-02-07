function DrawQCSFHelper(w, xCenter, yCenter, noiseTex, xOffset, yOffset, stimRect, color)
    % Draws stimulus borders to help with fusion
    if isempty(color)
        color = 0.5;
    end
    
    stimRectLeft = CenterRectOnPoint(stimRect', xCenter + xOffset(1), yCenter + yOffset(1))';
    stimRectRight = CenterRectOnPoint(stimRect', xCenter + xOffset(2), yCenter + yOffset(2))';
    
    apertureRectLeft = [stimRectLeft(1)-25 stimRectLeft(2)-25 stimRectLeft(3)+25 stimRectLeft(4)+25]';
    apertureRectRight = [stimRectRight(1)-25 stimRectRight(2)-25 stimRectRight(3)+25 stimRectRight(4)+25]';
    
    fusionRectLeft = [stimRectLeft(1)-50 stimRectLeft(2)-50 stimRectLeft(3)+50 stimRectLeft(4)+50]';
    fusionRectRight = [stimRectRight(1)-50 stimRectRight(2)-50 stimRectRight(3)+50 stimRectRight(4)+50]';
    
    leftXCenter = xCenter+xOffset(1);  rightXCenter = xCenter+xOffset(2);
    leftYCenter = yCenter+yOffset(1);  rightYCenter = yCenter+yOffset(2);
    
    % Still to change rest of variable names
    
    % left eye
    Screen('SelectStereoDrawBuffer', w, 0);
    Screen('DrawTexture', w, noiseTex, [], fusionRectLeft,[],[],1,[],[],[],[0.5,0,0,1]);
    Screen('FillRect', w, [color color color 1], apertureRectLeft);
    Screen('DrawLine', w, [0 0 0 1], leftXCenter, stimRectLeft(2)-25, leftXCenter, stimRectLeft(4)+25, 4);
    Screen('DrawLine', w, [0 0 0 1], stimRectLeft(1)-25, leftYCenter, stimRectLeft(3)+25, leftYCenter, 4);
    Screen('FillRect', w, [color color color 1], stimRectLeft);
    Screen('FillOval', w, [0 0 0 1], [leftXCenter-5 leftYCenter-5 leftXCenter+5 leftYCenter+5]);
    
    % right eye
    Screen('SelectStereoDrawBuffer', w, 1);
    Screen('DrawTexture', w, noiseTex, [], fusionRectRight,[],[],1,[],[],[],[0.5,0,0,1]);
    Screen('FillRect', w, [color color color 1], apertureRectRight);
    Screen('DrawLine', w, [0 0 0 1], rightXCenter, stimRectRight(2)-25, rightXCenter, stimRectRight(4)+25, 4);
    Screen('DrawLine', w, [0 0 0 1], stimRectRight(1)-25, rightYCenter, stimRectRight(3)+25, rightYCenter, 4);
    Screen('FillRect', w, [color color color 1], stimRectRight);
    Screen('FillOval', w, [0 0 0 1], [rightXCenter-5 rightYCenter-5 rightXCenter+5 rightYCenter+5]);
end