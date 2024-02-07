function DrawCheckeredScotomaRight(win,R0,scotoma_alpha,right_stimRect,smoothing_length, smoothing_res)
    stim_w = right_stimRect(3)-right_stimRect(1);
    stim_h = right_stimRect(4)-right_stimRect(2);
    xCenter = (right_stimRect(1)+(right_stimRect(3)-right_stimRect(1))/2);
    yCenter = (right_stimRect(2)+(right_stimRect(4)-right_stimRect(2))/2);

    % Right checkered
    Screen('SelectStereoDrawBuffer', win, 1);
% 2 by 2 checkered board
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [0 yCenter xCenter h]);       % Position A2
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [xCenter 0 w yCenter]);       % Position B1
% 4 by 4 checkered board
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [0 yCenter-stim_h/4 xCenter-stim_w/4 yCenter]);       % Position A2
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [0 yCenter+stim_h/4 xCenter-stim_w/4 h]);             % Position A4
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [xCenter-stim_w/4 0 xCenter yCenter-stim_h/4]);       % Position B1
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [xCenter-stim_w/4 yCenter xCenter yCenter+stim_h/4]); % Position B3
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [xCenter yCenter-stim_h/4 xCenter+stim_w/4 yCenter]); % Position C2
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [xCenter yCenter+stim_h/4 xCenter+stim_w/4 h]);       % Position C4
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [xCenter+stim_w/4 0 w yCenter-stim_h/4]);             % Position D1
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [xCenter+stim_w/4 yCenter w yCenter+stim_h/4]);       % Position D3
% 6 by 6 checkered board
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [0 round(yCenter-stim_h/3) round(xCenter-stim_w/3) round(yCenter-stim_h/6)]);                         % Position A2
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[right_stimRect(1) round(yCenter-stim_h/3) round(xCenter-stim_w/3) round(yCenter-stim_h/6)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [0 round(yCenter) round(xCenter-stim_w/3) round(yCenter+stim_h/6)]);                                  % Position A4
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[right_stimRect(1) round(yCenter) round(xCenter-stim_w/3) round(yCenter+stim_h/6)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [0 round(yCenter+stim_h/3) round(xCenter-stim_w/3) h]);                                               % Position A6
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[right_stimRect(1) round(yCenter+stim_h/3) round(xCenter-stim_w/3) right_stimRect(4)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter-stim_w/3) 0 round(xCenter-stim_w/6) round(yCenter-stim_h/3)]);                         % Position B1
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter-stim_w/3) right_stimRect(2) round(xCenter-stim_w/6) round(yCenter-stim_h/3)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter-stim_w/3) round(yCenter-stim_h/6) round(xCenter-stim_w/6) round(yCenter)]);            % Position B3
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter-stim_w/3) round(yCenter-stim_h/6) round(xCenter-stim_w/6) round(yCenter)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter-stim_w/3) round(yCenter+stim_h/6) round(xCenter-stim_w/6) round(yCenter+stim_h/3)]);   % Position B5
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter-stim_w/3) round(yCenter+stim_h/6) round(xCenter-stim_w/6) round(yCenter+stim_h/3)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter-stim_w/6) round(yCenter-stim_h/3) round(xCenter) round(yCenter-stim_h/6)]);            % Position C2
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter-stim_w/6) round(yCenter-stim_h/3) round(xCenter) round(yCenter-stim_h/6)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter-stim_w/6) round(yCenter) round(xCenter) round(yCenter+stim_h/6)]);                     % Position C4
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter-stim_w/6) round(yCenter) round(xCenter) round(yCenter+stim_h/6)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter-stim_w/6) round(yCenter+stim_h/3) round(xCenter) h]);                                  % Position C6
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter-stim_w/6) round(yCenter+stim_h/3) round(xCenter) right_stimRect(4)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter) 0 round(xCenter+stim_w/6) round(yCenter-stim_h/3)]);                                  % Position D1
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter) right_stimRect(2) round(xCenter+stim_w/6) round(yCenter-stim_h/3)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter) round(yCenter-stim_h/6) round(xCenter+stim_w/6) round(yCenter)]);                     % Position D3
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter) round(yCenter-stim_h/6) round(xCenter+stim_w/6) round(yCenter)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter) round(yCenter+stim_h/6) round(xCenter+stim_w/6) round(yCenter+stim_h/3)]);            % Position D5
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter) round(yCenter+stim_h/6) round(xCenter+stim_w/6) round(yCenter+stim_h/3)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter+stim_w/6) round(yCenter-stim_h/3) round(xCenter+stim_w/3) round(yCenter-stim_h/6)]);   % Position E2
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter+stim_w/6) round(yCenter-stim_h/3) round(xCenter+stim_w/3) round(yCenter-stim_h/6)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter+stim_w/6) round(yCenter) round(xCenter+stim_w/3) round(yCenter+stim_h/6)]);            % Position E4
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter+stim_w/6) round(yCenter) round(xCenter+stim_w/3) round(yCenter+stim_h/6)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter+stim_w/6) round(yCenter+stim_h/3) round(xCenter+stim_w/3) h]);                         % Position E6
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter+stim_w/6) round(yCenter+stim_h/3) round(xCenter+stim_w/3) right_stimRect(4)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter+stim_w/3) 0 w round(yCenter-stim_h/3)]);                                               % Position F1
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter+stim_w/3) right_stimRect(2) right_stimRect(3) round(yCenter-stim_h/3)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter+stim_w/3) round(yCenter-stim_h/6) w round(yCenter)]);                                  % Position F3
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter+stim_w/3) round(yCenter-stim_h/6) right_stimRect(3) round(yCenter)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter+stim_w/3) round(yCenter+stim_h/6) w round(yCenter+stim_h/3)]);                         % Position F5
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter+stim_w/3) round(yCenter+stim_h/6) right_stimRect(3) round(yCenter+stim_h/3)],smoothing_length, smoothing_res)

end