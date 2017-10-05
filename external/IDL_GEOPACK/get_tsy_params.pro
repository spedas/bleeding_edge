;+
; PROCEDURE: get_tsy_params
;
; PURPOSE: this procedure will interpolate inputs, generate
;          tsyganenko model parameters and store them in a tplot 
;          variable that can be passed directly to the model 
;          procedure
;
;          relevant variables can be loaded from
; 
;
; INPUTS:   dst_tvar: tplot variable storing the dst index
;           
;           imf_tvar: tplot variable name storing the interplanetary 
;           magnetic field bvector in gsm
;
;           Np_tvar: tplot variable name storing the solar wind
;                   ion density(rho) cm^-3
;           
;           Vp_tvar: tplot variable name storing the proton velocity
;
;           model: a string, should be 'T96','T01' or 'T04S' (upper or
;           lower case)
;
; KEYWORDS:
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
;           imf_yz(optional): set this to indicate that the imf_tvar is actually storing
;               two separate tplot variables(the first being the y component
;               of the imf and the second being the z)
;           
;               This can be done as follows:  
;                   store_data,'omni_imf',data=['OMNI_HRO_1min_BY_GSM','OMNI_HRO_1min_BZ_GSM']
;               Then just pass omni_imf into get_tsy_params and set /imf_yz
;
;           g_coefficients (optional): set this to specify a tplot variable containing the 
;               G coefficients for the T01 field model. If this keyword is not set, Geopack
;               will calculate the G coefficients automatically. This keyword is ignored for
;               field models other than T01
;               
;           w_coefficients (optional): set this to specify a tplot variable containing 
;               the W coefficients for the Tsyganenko-Sitnov (04) field model. If this 
;               keyword is not set, Geopack will calculate the W coefficients automatically.
;               This keyword is ignored for field models other than TS04
;           
;           
;          
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-12-03 13:55:21 -0800 (Thu, 03 Dec 2015) $
; $LastChangedRevision: 19524 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/get_tsy_params.pro $
;-
pro get_tsy_params,dst_tvar,imf_tvar,Np_tvar,Vp_tvar,model,newname=newname,$
                   trange=trange,speed=speed,imf_yz=imf_yz,g_coefficients=g_coefficients,$
                   w_coefficients=w_coefficients

COMPILE_OPT idl2
if not keyword_set(trange) then tlims = timerange(/current) else tlims=trange

;identify the number of 5 minute time intervals in the specified range
n = fix(tlims[1]-tlims[0],type=3)/300 +1
;the geopack parameter generating functions only work on 5 minute intervals

;construct a time array
ntimes=dindgen(n)*300+tlims[0]

if size(dst_tvar,/type) ne 7 then message,'dst_tvar must be a string'

if tnames(dst_tvar) eq '' then message,'dst_tvar must be a valid tplot variable'

; deflag Dst data
tdeflag, dst_tvar, 'linear', /overwrite
get_data,dst_tvar,data=d

dst_times = d.x
dst_val = d.y


if size(imf_tvar,/type) ne 7 then message,'imf_tvar must be a string'

if tnames(imf_tvar) eq '' then message,'imf_tvar must be a valid tplot variable'

if keyword_set(imf_yz) then begin
  
  get_data,imf_tvar,data=d
  
  if n_elements(d) ne 2 then message,'Wrong format for imf_yz tvar'
  
  if tnames(d[0]) eq '' then message,'imf_tvar y component is invalid tplot variable'
  
  if tnames(d[1]) eq '' then message,'imf_tvar z component is invalid tplot variable'
  
  ; deflag Y component of the IMF
  tdeflag, d[0], 'linear', /overwrite
  get_data,d[0],data=dy
  
  imf_times = dy.x
  imf_y = dy.y
  
  ; deflag Z component of the IMF
  tdeflag, d[1], 'linear', /overwrite
  get_data,d[1],data=dz
  
  imf_z = dz.y
  
endif else begin
  ; deflag the IMF
  tdeflag, imf_tvar, 'linear', /overwrite
  get_data,imf_tvar,data=d

  imf_times = d.x
  imf_vec = d.y
  imf_y = imf_vec[*,1]
  imf_z = imf_vec[*,2]
  
  
endelse

if size(Np_tvar,/type) ne 7 then message,'Np_tvar must be a string'

if tnames(Np_tvar) eq '' then message,'Np_tvar must be a valid tplot variable'

; deflag solar wind density
tdeflag, Np_tvar, 'linear', /overwrite

get_data,Np_tvar,data=d

wind_den_times = d.x
wind_den = d.y

if size(Vp_tvar,/type) ne 7 then message,'Vp_tvar must be a string'

if tnames(Vp_tvar) eq '' then message,'Vp_tvar must be a valid tplot variable'

; deflag solar wind velocity
tdeflag, Vp_tvar, 'linear', /overwrite
get_data,Vp_tvar,data=d

wind_spd_times = d.x

if ~keyword_set(speed) then begin
   wind_spd = sqrt(total(d.y^2,2))
endif else begin
   wind_spd = d.y
endelse

dst = interpol(dst_val,dst_times,ntimes)
imf_y = interpol(imf_y,imf_times,ntimes)
imf_z = interpol(imf_z,imf_times,ntimes)
den = interpol(wind_den,wind_den_times,ntimes)
spd = interpol(wind_spd,wind_spd_times,ntimes)

pram = 1.667e-6*den*spd^2 

if strlowcase(model) eq 't01' then begin 
   if ~keyword_set(g_coefficients) then begin
       ; the user didn't specify a tplot variable containing G coefficients,
       ; need to calculate them using Geopack
       geopack_getg,spd,imf_y,imf_z,out 

   endif else begin
       if tnames(g_coefficients) ne '' then begin
           tdeflag, g_coefficients, 'linear', /overwrite
           get_data, g_coefficients, data=g_coeff_data
           if is_struct(g_coeff_data) then begin
               g1 = interpol(g_coeff_data.Y[*,0], g_coeff_data.X, ntimes)
               g2 = interpol(g_coeff_data.Y[*,1], g_coeff_data.X, ntimes)
               out = [[g1],[g2]]
           endif else begin
               ; invalid/no data in the tplot variable
               dprint, dlevel = 1, 'Error reading the tplot variable containing the G coefficients - invalid structure returned'
               return
           endelse
       endif else begin
           ; the user set the w_coefficients keyword, but not
           ; with a valid tplot variable
           dprint, dlevel = 1, 'Error reading G coefficients tplot variable - not found in tplot_names'
           return
       endelse
   endelse
   par = {x:ntimes,y:[[pram],[dst],[imf_y],[imf_z],[out[*,0]],[out[*,1]],[dblarr(n)],[dblarr(n)],[dblarr(n)],[dblarr(n)]]}
   
   if not keyword_set(newname) then newname = 't01_par'

endif else if strlowcase(model) eq 't04s' then begin

   if ~keyword_set(w_coefficients) then begin
       ; the user didn't specify a tplot variable containing W coefficients, 
       ; need to calculate them using Geopack
       geopack_getw,den,spd,imf_z,out
   endif else begin
       if tnames(w_coefficients) ne '' then begin
           tdeflag, w_coefficients, 'linear', /overwrite
           get_data, w_coefficients, data=w_coeff_data
           if is_struct(w_coeff_data) then begin
               w1 = interpol(w_coeff_data.Y[*,0], w_coeff_data.X, ntimes)
               w2 = interpol(w_coeff_data.Y[*,1], w_coeff_data.X, ntimes)
               w3 = interpol(w_coeff_data.Y[*,2], w_coeff_data.X, ntimes)
               w4 = interpol(w_coeff_data.Y[*,3], w_coeff_data.X, ntimes)
               w5 = interpol(w_coeff_data.Y[*,4], w_coeff_data.X, ntimes)
               w6 = interpol(w_coeff_data.Y[*,5], w_coeff_data.X, ntimes)
               out = [[w1],[w2],[w3],[w4],[w5],[w6]]
           endif else begin
               ; invalid/no data in the tplot variable
               dprint, dlevel = 1, 'Error reading the tplot variable containing the W coefficients - invalid structure returned'
               return
           endelse
       endif else begin
           ; the user set the w_coefficients keyword, but not
           ; with a valid tplot variable
           dprint, dlevel = 1, 'Error reading W coefficients tplot variable - not found in tplot_names'
           return
       endelse
   endelse
   par = {x:ntimes,y:[[pram],[dst],[imf_y],[imf_z],[out[*,0]],[out[*,1]],[out[*,2]],[out[*,3]],[out[*,4]],[out[*,5]]]}
   if not keyword_set(newname) then newname = 't04s_par'

endif else if strlowcase(model) eq 't96' then begin

   par = {x:ntimes,y:[[pram],[dst],[imf_y],[imf_z],[dblarr(n)],[dblarr(n)],[dblarr(n)],[dblarr(n)],[dblarr(n)],[dblarr(n)]]}

   if not keyword_set(newname) then newname = 't96_par'

endif else message,'model name unrecognized'

store_data,newname,data=par

end
