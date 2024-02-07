function DrawFusionHelper(w, xCenter, yCenter, noiseTex, apertureRect, stimRect, fusionRect)
    % Draws stimulus borders to help with fusion
    
%     % left eye
%     Screen('SelectStereoDrawBuffer', w, 0);
%     Screen('DrawTexture', w, noiseTex, [], fusionRect,[],[],[],[],[],[],[0.5,0,0,0]);
%     Screen('FillRect', w, 127, apertureRect);
%     Screen('DrawLine', w, 0, xCenter, stimRect(2)-25, xCenter, stimRect(4)+25, 4);
%     Screen('DrawLine', w, 0, stimRect(1)-25, yCenter, stimRect(3)+25, yCenter, 4);
%     Screen('FillRect', w, 127, stimRect);
%     Screen('FillOval', w, 0, [xCenter-3 yCenter-3 xCenter+3 yCenter+3]);
    
    % right eye
    Screen('SelectStereoDrawBuffer', w, 1);
    Screen('DrawTexture', w, noiseTex, [], fusionRect,[],[],[],[],[],[],[0.5,0,0,0]);
    Screen('FillRect', w, 127, apertureRect);
    Screen('DrawLine', w, 0, xCenter, stimRect(2)-25, xCenter, stimRect(4)+25, 4);
    Screen('DrawLine', w, 0, stimRect(1)-25, yCenter, stimRect(3)+25, yCenter, 4);
    Screen('FillRect', w, 127, stimRect);
    Screen('FillOval', w, 0, [xCenter-3 yCenter-3 xCenter+3 yCenter+3]);
end