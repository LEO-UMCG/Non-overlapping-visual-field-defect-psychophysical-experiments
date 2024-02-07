function F = psychfunc(g,u,v,x)
F = g+(1-g)*0.5*(1+erf((x-u)/sqrt(2*v^2)));
end