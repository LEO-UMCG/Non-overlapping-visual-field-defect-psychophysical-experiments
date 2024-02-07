function DrawSmoothedScotoma(win,R0,scotoma_alpha,scotoma_rect,smoothing_length, smoothing_res)
    x1 = scotoma_rect(1);
    y1 = scotoma_rect(2);
    x2 = scotoma_rect(3);
    y2 = scotoma_rect(4);
    scotoma_w = x2-x1;
    scotoma_h = y2-y1;
%     xedge = scotoma_w/cuts;
%     yedge = scotoma_h/cuts;
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha/10], [x1 y1 x2 y2]);                                               % Position 1
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha/10], [x1+xedge y1+yedge x2-xedge y2-yedge]);                       % Position 2
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha/10], [x1+(2*xedge) y1+(2*yedge) x2-(2*xedge) y2-(2*yedge)]);       % Position 3
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha/10], [x1+(3*xedge) y1+(3*yedge) x2-(3*xedge) y2-(3*yedge)]);       % Position 4
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha/10], [x1+(4*xedge) y1+(4*yedge) x2-(4*xedge) y2-(4*yedge)]);       % Position 5
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha/10], [x1+(5*xedge) y1+(5*yedge) x2-(5*xedge) y2-(5*yedge)]);       % Position 6
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha/10], [x1+(6*xedge) y1+(6*yedge) x2-(6*xedge) y2-(6*yedge)]);       % Position 7
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha/10], [x1+(7*xedge) y1+(7*yedge) x2-(7*xedge) y2-(7*yedge)]);       % Position 8
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha/10], [x1+(8*xedge) y1+(8*yedge) x2-(8*xedge) y2-(8*yedge)]);       % Position 9
%     Screen('FillRect', win, [R0 R0 R0 scotoma_alpha/10], [x1+(9*xedge) y1+(9*yedge) x2-(9*xedge) y2-(9*yedge)]);       % Position 10


    x_cut_width = scotoma_w*smoothing_length/smoothing_res;
    y_cut_width = scotoma_h*smoothing_length/smoothing_res;
    smoothing_strength = scotoma_alpha/smoothing_res;

 
    Screen('FillRect', win, [R0 R0 R0 smoothing_strength], [x1 y1 x2 y2]);

    for i = 1:smoothing_res
        Screen('FillRect', win, [R0 R0 R0 smoothing_strength], [x1+(i*x_cut_width) y1+(i*y_cut_width) x2-(i*x_cut_width) y2-(i*y_cut_width)]);                       
    end

    Screen('FillRect', win, [R0 R0 R0 scotoma_alpha], [x1+(i*x_cut_width) y1+(i*y_cut_width) x2-(i*x_cut_width) y2-(i*y_cut_width)]); 
end
