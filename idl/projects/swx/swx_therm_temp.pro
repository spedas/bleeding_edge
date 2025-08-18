function swx_therm_temp,dval,parameter=p
  if not keyword_set (p) then begin
     ;p = {func:'mvn_sep_therm_temp2',$
     ;     R1:10000d, $
     ;     xmax:1023d, $
     ;     Rv:1d8,$
     ;     thm:thermistor_temp()}
     p = {func:'swx_therm_temp',$
          R1:10000d, $
          xmax:1023d, $
          Rv:1d9, $
          thm:'thermistor_resistance_ysi4908'}
  endif
  if n_params() eq 0 then return,p
  ;print,dval
  x = dval/p.xmax
  rt = p.r1*(x/(1-x*(1+p.R1/p.Rv)))
  tc = thermistor_resistance_ysi4908(rt,/inverse)
  ;print,dval,x,rt,tc
  return,float(tc)
end

