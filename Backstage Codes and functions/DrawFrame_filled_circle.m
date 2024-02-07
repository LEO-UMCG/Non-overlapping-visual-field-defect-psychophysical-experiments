function DrawFrame_filled_circle(w, xCenter, yCenter, xOffset, yOffset, stimRect,R0, noiseTex)
    % Draws stimulus borders to help with fusion
    stimRectLeft = CenterRectOnPoint(stimRect', xCenter + xOffset(1), yCenter + yOffset(1))';
    stimRectRight = CenterRectOnPoint(stimRect', xCenter + xOffset(2), yCenter + yOffset(2))';     
       
    leftXCenter = xCenter+xOffset(1);  rightXCenter = xCenter+xOffset(2);
    leftYCenter = yCenter+yOffset(1);  rightYCenter = yCenter+yOffset(2);

    % left eye
    Screen('SelectStereoDrawBuffer', w, 0);
    Screen('DrawTexture', w, noiseTex, [], stimRectLeft)
    Screen('FillOval', w, [R0 R0 R0 1], [stimRectLeft(1)+25 stimRectLeft(2)+25 stimRectLeft(3)-25 stimRectLeft(4)-25])
    Screen('DrawLine', w, [0 0 0 1], leftXCenter, stimRectLeft(2)+50, leftXCenter, stimRectLeft(2)+25, 4);
    Screen('DrawLine', w, [0 0 0 1], leftXCenter, stimRectLeft(4)-25, leftXCenter, stimRectLeft(4)-50, 4);
    Screen('DrawLine', w, [0 0 0 1], stimRectLeft(1)+50, leftYCenter, stimRectLeft(1)+25, leftYCenter, 4);
    Screen('DrawLine', w, [0 0 0 1], stimRectLeft(3)-25, leftYCenter, stimRectLeft(3)-50, leftYCenter, 4);
    Screen('FillOval', w, [0 0 0 1], [leftXCenter-5 leftYCenter-5 leftXCenter+5 leftYCenter+5]);
    
    % right eye
    Screen('SelectStereoDrawBuffer', w, 1);
    Screen('DrawTexture', w, noiseTex, [], stimRectRight)
    Screen('FillOval', w, [R0 R0 R0 1], [stimRectRight(1)+25 stimRectRight(2)+25 stimRectRight(3)-25 stimRectRight(4)-25])
    Screen('DrawLine', w, [0 0 0 1], rightXCenter, stimRectRight(2)+50, rightXCenter, stimRectRight(2)+25, 4);
    Screen('DrawLine', w, [0 0 0 1], rightXCenter, stimRectRight(4)-25, rightXCenter, stimRectRight(4)-50, 4);
    Screen('DrawLine', w, [0 0 0 1], stimRectRight(1)+50, rightYCenter, stimRectRight(1)+25, rightYCenter, 4);
    Screen('DrawLine', w, [0 0 0 1], stimRectRight(3)-25, rightYCenter, stimRectRight(3)-50, rightYCenter, 4);
    Screen('FillOval', w, [0 0 0 1], [rightXCenter-5 rightYCenter-5 rightXCenter+5 rightYCenter+5]);
end