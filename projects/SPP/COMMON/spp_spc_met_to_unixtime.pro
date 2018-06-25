;coeff = [0.00E+00,  0.00E+00,  -5.76E-20, 5.01E-15,  -1.68E-10,
;         2.69E-06,  -2.33E-02, 9.33E+01]


function spp_spc_met_to_unixtime,met,reverse=reverse
  
 ; dprint,'hello'
  ;; long(time_double('2000-1-1/12:00'))  ;Early SWEM definition
  epoch =  946771200d - 12L*3600
  ;; long(time_double('2010-1-1/0:00')) ; Correct SWEM use
  epoch =  1262304000d
  if keyword_set(reverse) then begin
    return,met -epoch
  endif
  if met lt 1e6 then begin
    dprint,dlevel=4,'Bad MET ',time_string(met+epoch) ,dwait=5.
  ;  help,/trace
    return, !values.d_nan
  endif
  if met gt 'FFFFFFFE'x then begin
    dprint,dlevel=4,'Bad MET: 0xFFFF  - Restarting Op???'
    return, !values.d_nan
  endif
  unixtime =  met +  epoch
  
  return,unixtime

end
