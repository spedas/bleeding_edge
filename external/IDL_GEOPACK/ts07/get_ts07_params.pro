;+
; PROCEDURE: get_ts07_params
;
; PURPOSE: this procedure will interpolate inputs, generate
;          tsyganenko model parameters and store them in a tplot 
;          variable that can be passed directly to the model 
;          procedure; 
;
; INPUTS:   
;
; KEYWORDS:
;
;           Np_tvar: tplot variable name storing the solar wind
;                   ion density(rho) cm^-3.  Optional, if pressure_tvar supplied
;
;           Vp_tvar: tplot variable name storing the proton velocity (km/sec)
;                    Optional, if pressure_tvar_supplied.
;           
;           pressure_tvar (optional): tplot variable name storing the dynamic pressure.
;                    If not provided, will be calulated from Np and Vp.
;
;           newname(optional): the name of the output tplot variable
;               (default: t96_par','t01_par' or 't04s_par' depending on 
;               selected model)
;
;           trange(optional): the time range over which the parameters
;               should range, if not set, this program will check the
;               timespan variable or prompt the user for a range
;
;           speed(optional): set this if Vp_tvar is stored as a speed
;
;           
;           
;          
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2021-07-28 18:16:15 -0700 (Wed, 28 Jul 2021) $
; $LastChangedRevision: 30156 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/ts07/get_ts07_params.pro $
;-
pro get_ts07_params,Np_tvar=Np_tvar,Vp_tvar=Vp_tvar,pressure_tvar=pressure_tvar,newname=newname,trange=trange,speed=speed

COMPILE_OPT idl2
if not keyword_set(trange) then tlims = timerange(/current) else tlims=trange

;identify the number of 5 minute time intervals in the specified range
n = fix(tlims[1]-tlims[0],type=3)/300 +1
;the geopack parameter generating functions only work on 5 minute intervals

;construct a time array
ntimes=dindgen(n)*300+tlims[0]

if (size(pressure_tvar,/type) eq 7) && (tnames(pressure_tvar) ne '') then begin
  ; deflag solar wind pressure
  tdeflag, pressure_tvar, 'linear', /overwrite

  get_data,pressure_tvar,data=d

  pram_times = d.x
  pram_vals = d.y
  pram = interpol(pram_vals,pram_times,ntimes)

endif else begin
  
   dprint,'No pressure variable supplied, calculating from proton speed and density'
   if size(Np_tvar,/type) ne 7 then message,'Np_tvar must be a string'

   if tnames(Np_tvar) eq '' then message,'Np_tvar (' +Np_tvar + ') must be a valid tplot variable'

   ; deflag solar wind density
   tdeflag, Np_tvar, 'linear', /overwrite

   get_data,Np_tvar,data=d

   wind_den_times = d.x
   wind_den = d.y

   if size(Vp_tvar,/type) ne 7 then message,'Vp_tvar must be a string'

   if tnames(Vp_tvar) eq '' then message,Vp_tvar+' must be a valid tplot variable'

   ; deflag solar wind velocity
   tdeflag, Vp_tvar, 'linear', /overwrite
   get_data,Vp_tvar,data=d

   wind_spd_times = d.x

   if ~keyword_set(speed) then begin
      wind_spd = sqrt(total(d.y^2,2))
   endif else begin
      wind_spd = d.y
   endelse

   den = interpol(wind_den,wind_den_times,ntimes)
   spd = interpol(wind_spd,wind_spd_times,ntimes)

   ; Solar wind dynamic pressure (Pdyn parameter for GEOPACK)
   ; Previous version only accounted for contribution by protons, not alphas, and were not consistent (off by a factor of 1.2) with 
   ; OMNI pressure data.  
   ;
   ; Derivation of Alpha particle pressure correction is here: https://omniweb.gsfc.nasa.gov/ftpbrowser/bow_derivation.html
   ;
   ; JWL 2021-06-09

   ; Calculate dynamic pressure from speed and density, using the default fraction of alpha particles f_alpha = 0.04
   pram = calc_pdyn(N_p=den,V_p=spd)
   
   ; No need to interpolate to ntimes here, since dan and speed are already interpolated

endelse

par = {x:ntimes,y:[[pram],[dblarr(n)],[dblarr(n)],[dblarr(n)],[dblarr(n)],[dblarr(n)],[dblarr(n)],[dblarr(n)],[dblarr(n)],[dblarr(n)]]}
if not keyword_set(newname) then begin 
 newname = 'ts07_par'
endif

store_data,newname,data=par

end
