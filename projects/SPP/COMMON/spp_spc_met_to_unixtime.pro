;coeff = [0.00E+00,  0.00E+00,  -5.76E-20, 5.01E-15,  -1.68E-10,
;         2.69E-06,  -2.33E-02, 9.33E+01]


function spp_rt,t,min=min,max=max,range=range,reset=reset
   common spp_sample_com2, sze,npoints,samples,allowed
   if (not keyword_set(sze)) or keyword_set(reset) then begin
    sze= 500
    dprint,'Reseting spp_rt'
    if keyword_set(reset) && (reset gt 10) then sze=reset
    samples= dblarr(sze) * !values.d_nan
    npoints = 0
    allowed = time_double(['2016-1-1','2024-1-1'])
   endif
   if keyword_set(max) then return, max(samples,/nan)
   if keyword_set(min) then return, min(samples,/nan)
   if keyword_set(range) or n_elements(t) eq 0 then return, minmax(samples,/nan)
   tt = t[0]
   if tt gt allowed[1] then begin 
     dprint,"Bad time: "+time_string(tt)+' Ignored' 
     tt=!values.d_nan 
   endif
   if tt lt allowed[0] then begin 
     dprint,"Bad time: "+time_string(tt)+' Ignored'
     tt=!values.d_nan 
   end
   samples[npoints++ mod sze] = tt
   return,tt
end

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
    dprint,dlevel=2,'Bad MET ',time_string(met+epoch),dwait=15.
    met = !values.d_nan
  endif
  unixtime =  met +  epoch
  dummy= spp_rt(unixtime)
  return,unixtime

end
