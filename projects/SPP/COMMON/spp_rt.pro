; Routine to help with real time plotting


function spp_rt,t,min=min,max=max,range=range,reset=reset
   common spp_sample_com2, sze,npoints,samples,allowed
   if (not keyword_set(sze)) or keyword_set(reset) then begin
    sze= 500
    dprint,'Reseting spp_rt'
    if keyword_set(reset) && (reset gt 10) then sze=reset
    samples= dblarr(sze) * !values.d_nan
    npoints = 0
    allowed = time_double(['2016-1-1','2024-1-1'])
    allowed = [systime(1)-100*24d*3600,time_double('2024-1-1')]
   endif
   if keyword_set(max) then return, max(samples,/nan)
   if keyword_set(min) then return, min(samples,/nan)
   if keyword_set(range) or n_elements(t) eq 0 then return, minmax(samples,/nan)
   tt = t[0]
   if tt gt allowed[1] then begin 
     dprint,dlevel=4,"Bad time: "+time_string(tt)+' Ignored' 
     tt=!values.d_nan 
   endif
   if tt lt allowed[0] then begin 
     if debug(5) then begin
       dprint,dlevel=4,"Early time: "+time_string(tt)+' Ignored'  ; warning this dprint statement will slow processing
       help,/trace
     endif
     tt=!values.d_nan 
   end
   samples[npoints++ mod sze] = tt
 ;  print,time_string(tt)
   return,tt
end
