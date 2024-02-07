function DrawSmoothedScotoma_Heminasal_Right(win,R0,scotoma_alpha,scotoma_rect,smoothing_length, smoothing_res)
    x1 = scotoma_rect(1);
    y1 = scotoma_rect(2);
    x2 = scotoma_rect(3);
    y2 = scotoma_rect(4);
    scotoma_w = x2-x1;
    scotoma_h = y2-y1;
    x_cut_width = scotoma_w*smoothing_length/smoothing_res;
    y_cut_width = scotoma_h*smoothing_length/smoothing_res;
    smoothing_strength = scotoma_alpha/smoothing_res;

    Screen('SelectStereoDrawBuffer', win, 1);

    Screen('FillRect', win, [R0 R0 R0 smoothing_strength], [x1 y1 x2 y2]);
    
    for i = 1:smoothing_res
        Screen('FillRect', win, [R0 R0 R0 smoothing_strength], [x1 y1 floor(x2-(i*x_cut_width)) y2]);
    end
    
    Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [x1 y1 floor(x2-i*x_cut_width) y2]);
end