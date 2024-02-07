function DrawCheckeredScotomaLeft(win,R0,scotoma_alpha,left_stimRect,smoothing_length, smoothing_res)

    stim_w = left_stimRect(3)-left_stimRect(1);
    stim_h = left_stimRect(4)-left_stimRect(2);
    xCenter = (left_stimRect(1)+(left_stimRect(3)-left_stimRect(1))/2);
    yCenter = (left_stimRect(2)+(left_stimRect(4)-left_stimRect(2))/2);

    % Left checkered
    Screen('SelectStereoDrawBuffer', win, 0);
% 2 by 2 checkered board
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [0 0 xCenter yCenter]);       % Position A1
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [xCenter yCenter w h]);       % Position B2    
% 4 by 4 checkered board
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [0 0 xCenter-stim_w/4 yCenter-stim_h/4]);             % Position A1
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [0 yCenter xCenter-stim_w/4 yCenter+stim_h/4]);       % Position A3
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [xCenter-stim_w/4 yCenter-stim_h/4 xCenter yCenter]); % Position B2
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [xCenter-stim_w/4 yCenter+stim_h/4 xCenter h]);       % Position B4
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [xCenter 0 xCenter+stim_w/4 yCenter-stim_h/4]);       % Position C1
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [xCenter yCenter xCenter+stim_w/4 yCenter+stim_h/4]); % Position C3
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [xCenter+stim_w/4 yCenter-stim_h/4 w yCenter]);       % Position D2
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [xCenter+stim_w/4 yCenter+stim_h/4 w h]);             % Position D4
% 6 by 6 checkered board
    % Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [0 0 round(xCenter-stim_w/3) round(yCenter-stim_h/3)]);                                               % Position A1
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[left_stimRect(1) left_stimRect(2) round(xCenter-stim_w/3) round(yCenter-stim_h/3)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [0 round(yCenter-stim_h/6) round(xCenter-stim_w/3) round(yCenter)]);                                  % Position A3
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[left_stimRect(1) round(yCenter-stim_h/6) round(xCenter-stim_w/3) round(yCenter)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [0 round(yCenter+stim_h/6) round(xCenter-stim_w/3) round(yCenter+stim_h/3)]);                         % Position A5
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[left_stimRect(1) round(yCenter+stim_h/6) round(xCenter-stim_w/3) round(yCenter+stim_h/3)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter-stim_w/3) round(yCenter-stim_h/3) round(xCenter-stim_w/6) round(yCenter-stim_h/6)]);   % Position B2
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter-stim_w/3) round(yCenter-stim_h/3) round(xCenter-stim_w/6) round(yCenter-stim_h/6)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter-stim_w/3) round(yCenter) round(xCenter-stim_w/6) round(yCenter+stim_h/6)]);            % Position B4
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter-stim_w/3) round(yCenter) round(xCenter-stim_w/6) round(yCenter+stim_h/6)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter-stim_w/3) round(yCenter+stim_h/3) round(xCenter-stim_w/6) h]);                         % Position B6
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter-stim_w/3) round(yCenter+stim_h/3) round(xCenter-stim_w/6) left_stimRect(4)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter-stim_w/6) 0 round(xCenter) round(yCenter-stim_h/3)]);                                  % Position C1
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter-stim_w/6) left_stimRect(2) round(xCenter) round(yCenter-stim_h/3)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter-stim_w/6) round(yCenter-stim_h/6) round(xCenter) round(yCenter)]);                     % Position C3
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter-stim_w/6) round(yCenter-stim_h/6) round(xCenter) round(yCenter)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter-stim_w/6) round(yCenter+stim_h/6) round(xCenter) round(yCenter+stim_h/3)]);            % Position C5
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter-stim_w/6) round(yCenter+stim_h/6) round(xCenter) round(yCenter+stim_h/3)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter) round(yCenter-stim_h/3) round(xCenter+stim_w/6) round(yCenter-stim_h/6)]);            % Position D2
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter) round(yCenter-stim_h/3) round(xCenter+stim_w/6) round(yCenter-stim_h/6)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter) round(yCenter) round(xCenter+stim_w/6) round(yCenter+stim_h/6)]);                     % Position D4
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter) round(yCenter) round(xCenter+stim_w/6) round(yCenter+stim_h/6)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter) round(yCenter+stim_h/3) round(xCenter+stim_w/6) h]);                                  % Position D6
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter) round(yCenter+stim_h/3) round(xCenter+stim_w/6) left_stimRect(4)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter+stim_w/6) 0 round(xCenter+stim_w/3) round(yCenter-stim_h/3)]);                         % Position E1
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter+stim_w/6) left_stimRect(2) round(xCenter+stim_w/3) round(yCenter-stim_h/3)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter+stim_w/6) round(yCenter-stim_h/6) round(xCenter+stim_w/3) round(yCenter)]);            % Position E3
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter+stim_w/6) round(yCenter-stim_h/6) round(xCenter+stim_w/3) round(yCenter)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter+stim_w/6) round(yCenter+stim_h/6) round(xCenter+stim_w/3) round(yCenter+stim_h/3)]);   % Position E5
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter+stim_w/6) round(yCenter+stim_h/6) round(xCenter+stim_w/3) round(yCenter+stim_h/3)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter+stim_w/3) round(yCenter-stim_h/3) w round(yCenter-stim_h/6)]);                         % Position F2
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter+stim_w/3) round(yCenter-stim_h/3) left_stimRect(3) round(yCenter-stim_h/6)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter+stim_w/3) round(yCenter) w round(yCenter+stim_h/6)]);                                  % Position F4
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter+stim_w/3) round(yCenter) left_stimRect(3) round(yCenter+stim_h/6)],smoothing_length, smoothing_res)
    %Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [round(xCenter+stim_w/3) round(yCenter+stim_h/3) w h]);                                               % Position F6    
    DrawSmoothedScotoma(win,R0,scotoma_alpha,[round(xCenter+stim_w/3) round(yCenter+stim_h/3) left_stimRect(3) left_stimRect(4);],smoothing_length, smoothing_res)

end