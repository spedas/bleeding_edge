;coeff = [0.00E+00,  0.00E+00,  -5.76E-20, 5.01E-15,  -1.68E-10,
;         2.69E-06,  -2.33E-02, 9.33E+01]


function spp_spc_met_to_unixtime,met,reverse=reverse
  
 ; dprint,'hello'
  ;; long(time_double('2000-1-1/12:00'))  ;Early SWEM definition
  epoch =  946771200d - 12L*3600
  ;; long(time_double('2010-1-1/0:00')) ; Correct SWEM use
  epoch =  1262304000
  if keyword_set(reverse) then begin
    return,met -epoch
  endif
  if met lt 1e6 then begin
    dprint,dlevel=2,'Bad MET ',time_string(met+epoch) ;,dwait=15.
    met = !values.d_nan
  endif
  unixtime =  met +  epoch
  
;  if unixtime gt 1830297600 then unixtime -= 315532800   ; this cluge is a temporary fix to correct the usr log messages.
  
;  dummy= spp_rt(unixtime)
  return,unixtime

end
