;+
; PROCEDURE: tcalc_pdyn
;
; PURPOSE: This procedure calculates the solar wind dynamic pressure from proton speed and proton density, accounting for contributions from both
;          protons and alpha particles.  Previous SPEDAS code only accounted for protons.  OMNIweb provides a "Pressure" data set that assumes
;          f_alpha = N_a/N_p = 0.05, which according to Vassilis may be a little high.   This routine accepts an f_alpha parameter, whicb defaults to 0.04.
;
; 
;
; INPUTS:   
;           N_p_tvar: tplot variable name storing the solar wind
;                   ion density(rho) cm^-3
;           
;           V_p_tvar: tplot variable name storing the proton velocity
;
;           model: a string, should be 'TA15N' or 'TA15B'
;           
; Returns:
;           Dynamic pressure in units of nPa, suitable for passing to GEOPACK field models
;
; KEYWORDS:
;
;           newname(optional): the name of the output tplot variable, defaults to 'Pdyn' if not provided.
;
;           times(optional): Timestamps at which the pressure shall be calculated.  If not provided, the times of the density input variable will be used.
;
;           speed(optional): set this if Vp_tvar is stored as a speed
;           
; Notes:
; Derivation of Alpha particle pressure correction is here: https://omniweb.gsfc.nasa.gov/ftpbrowser/bow_derivation.html

;
; $LastChangedBy: jwl $
; $LastChangedDate: 2021-07-28 18:16:15 -0700 (Wed, 28 Jul 2021) $
; $LastChangedRevision: 30156 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/tcalc_pdyn.pro $
;-
pro tcalc_pdyn,N_p_tvar=N_p_tvar,V_p_tvar=V_p_tvar,f_alpha=f_alpha,newname=newname,times=times,speed=speed

COMPILE_OPT idl2

if size(N_p_tvar,/type) ne 7 then message,'N_p_tvar must be a string'
if tnames(N_p_tvar) eq '' then message,N_p_tvar + ' not a valid tplot variable'

; deflag solar wind density
tdeflag, N_p_tvar, 'linear', /overwrite
get_data,N_p_tvar,data=d
wind_den_times = d.x
wind_den = d.y

if size(V_p_tvar,/type) ne 7 then message,'V_p_tvar must be a string'
if tnames(V_p_tvar) eq '' then message,V_p_tvar+' not a valid tplot variable'

; deflag solar wind velocity
tdeflag, V_p_tvar, 'linear', /overwrite
get_data,V_p_tvar,data=d

wind_spd_times = d.x

if ~keyword_set(speed) then begin
   wind_spd = sqrt(total(d.y^2,2))
endif else begin
   wind_spd = d.y
endelse

if n_elements(times) eq 0 then times=wind_den_times

; The tdeflag calls above will have removed NaNs from the input variables by this point.  If that changes (e.g. to avoid modifying the inputs), 
; the interpolation should probably be changed to use tinterpolate_mxn, /ignore_nans to avoid propagating NaNs into the modeling routines.

den = interpol(wind_den,wind_den_times,times)
spd = interpol(wind_spd,wind_spd_times,times)

; Calculate the dynamic pressure from the proton density, proton speed, and fraction of alpha particles

pram = calc_pdyn(N_p=den, V_p=spd, f_alpha=f_alpha)

if n_elements(newname) eq 0 then newname='Pdyn'

store_data,newname,data={x:times,y:pram}
options,newname,ysubtitle='[nPa]'


end
