

function spp_poisson, x,  $
    parameters=p  ;,  p_names = p_names, pder_values= pder_values
  
  if not keyword_set(p) then $
     p = {func:'poisson',h:1.d, avg:1.0d,integer:1}
  if n_params() eq 0 then return,p
  
  x1 = p.integer ? round(x) : x
  
  if(p.avg lt 100)  then  y = (p.avg^x1)/gamma(x1+1.d) * exp(-p.avg) $
  else y = exp(-.5*(x1-p.avg)^2/p.avg) /sqrt(p.avg*2.*!dpi)
  
  return,p.h*y

end
