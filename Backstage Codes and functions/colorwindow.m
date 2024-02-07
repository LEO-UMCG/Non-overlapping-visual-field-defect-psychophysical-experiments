 function [lm,rgb] = colorwindow ()
screenid = max(Screen('Screens'));
[wPtr,~] = Screen('Openwindow',screenid);
lm=[];
rgb=[];
for i=255:-10:155
  Screen('FillRect', wPtr, [i i i]);
  Screen('Flip',wPtr);
  WaitSecs(0.5);
  newlm = input('say:');
  lm = [lm; newlm];
  rgb = [rgb;i];
end
clear Screen;
end
