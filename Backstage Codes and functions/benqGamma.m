% BenQ LUT

function f = benqGamma

    p1 =  -2.491e-12;  
    p2 =   3.211e-09; 
    p3 =  -1.554e-06;  
    p4 =    0.000342;  
    p5 =    -0.03343;  
    p6 =       2.032;  
    p7 =      -1.778;  
    mx =        1.16;
    

    for x = 1:256
       f(x, 1:3) = ((p1*x^6 + p2*x^5 + p3*x^4 + p4*x^3 + p5*x^2 + p6*x + p7) * mx) / 256;
    end

end
