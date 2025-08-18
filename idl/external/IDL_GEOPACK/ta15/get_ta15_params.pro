;+
; PROCEDURE: get_ta15_params
;
; PURPOSE: this procedure will interpolate inputs, generate
;          tsyganenko model parameters and store them in a tplot 
;          variable that can be passed directly to the model 
;          procedure
;
; 
;
; KEYWORDS: 
;           imf_tvar: tplot variable name with IMF data.  Can be just the Y and Z components as a composite tplot variable,
;                     or 3-vectors. 
;                     
;           /imf_yz:  Set this keyword if using just the T abd Z components, otherwise 3-vectors assumed
;           
;           Np_tvar: tplot variable name storing the solar wind
;                   ion density(rho) cm^-3
;           
;           Vp_tvar: tplot variable name storing the proton velocity.  Can be a scalar (speed only), or 3-vectors
;           
;           /speed: Set this keyword if Vp_tvar contains scalar speeds
;
;           model: a string, should be 'ta15n' or 'ta15b'
;           
;
;
;           newname(optional): the name of the output tplot variable
;               (default: ta15n_par or ta15b_par depending on 
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
; $LastChangedDate: 2022-02-03 13:03:01 -0800 (Thu, 03 Feb 2022) $
; $LastChangedRevision: 30557 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/ta15/get_ta15_params.pro $
;-
pro get_ta15_params,imf_tvar=imf_tvar,Np_tvar=Np_tvar,Vp_tvar=Vp_tvar,xind_tvar=xind_tvar,pressure_tvar=pressure_tvar, imf_yz=imf_yz, newname=newname,trange=trange,speed=speed,model=model

COMPILE_OPT idl2
if not keyword_set(trange) then tlims = timerange(/current) else tlims=trange

;identify the number of 5 minute time intervals in the specified range
n = fix(tlims[1]-tlims[0],type=3)/300 +1
;the geopack parameter generating functions only work on 5 minute intervals

;construct a time array
ntimes=dindgen(n)*300+tlims[0]

if size(imf_tvar,/type) ne 7 then message,'imf_tvar must be a string'

if tnames(imf_tvar) eq '' then message,'imf_tvar ('+imf_tvar+') must be a valid tplot variable'

if keyword_set(imf_yz) then begin

  get_data,imf_tvar,data=d

  if n_elements(d) ne 2 then message,'Wrong format for imf_yz tvar'

  if tnames(d[0]) eq '' then message,'imf_tvar y component is invalid tplot variable'

  if tnames(d[1]) eq '' then message,'imf_tvar z component is invalid tplot variable'

  ; deflag Y component of the IMF
  tdeflag, d[0], 'linear', /overwrite
  get_data,d[0],data=dy

  imf_y_times = dy.x
  imf_y = interpol(dy.y,imf_y_times,ntimes)

  ; deflag Z component of the IMF
  tdeflag, d[1], 'linear', /overwrite
  get_data,d[1],data=dz

  imf_z_times = dz.x
  imf_z = interpol(dz.y,imf_z_times,ntimes)

endif else begin
  ; deflag the IMF
  tdeflag, imf_tvar, 'linear', /overwrite
  get_data,imf_tvar,data=d

  imf_times = d.x
  imf_vec = d.y
  imf_y = interpol(imf_vec[*,1],imf_times,ntimes)
  imf_z = interpol(imf_vec[*,2],imf_times,ntimes)


endelse

; Flags to tell if density or speed variables need to be processed
den_flag = 0
spd_flag = 0

if (size(pressure_tvar,/type) ne 7) || (tnames(pressure_tvar) eq '') then begin
  den_flag = 1
  spd_flag = 1
endif else if (strlowcase(model) eq 'ta15b') && ((size(xind_tvar,/type) ne 7 )|| (tnames(xind_tvar) eq ''))  then begin 
  den_flag = 1
  spd_flag = 1
endif else if (strlowcase(model) eq 'ta15n') && ((size(xind_tvar,/type) ne 7) || (tnames(xind_tvar) eq '')) then spd_flag = 1
  

if den_flag then begin
  if size(Np_tvar,/type) ne 7 then message,'Np_tvar must be a string'

  if tnames(Np_tvar) eq '' then message,'Np_tvar ('+Np_tvar + ') must be a valid tplot variable'

  ; deflag solar wind density
  tdeflag, Np_tvar, 'linear', /overwrite

  get_data,Np_tvar,data=d

  wind_den_times = d.x
  wind_den = d.y
  den = interpol(wind_den,wind_den_times,ntimes)

endif

if spd_flag then begin
  if size(Vp_tvar,/type) ne 7 then message,'Vp_tvar must be a string'

  if tnames(Vp_tvar) eq '' then message,'Vp_tvar ('+Vp_tvar+') must be a valid tplot variable'

  ; deflag solar wind velocity
  tdeflag, Vp_tvar, 'linear', /overwrite
  get_data,Vp_tvar,data=d

  wind_spd_times = d.x

  if ~keyword_set(speed) then begin
    wind_spd = sqrt(total(d.y^2,2))
  endif else begin
    wind_spd = d.y
  endelse

  spd = interpol(wind_spd,wind_spd_times,ntimes)
 
endif

if (size(pressure_tvar,/type) eq 7) && (tnames(pressure_tvar) ne '') then begin
   
   ; deflag solar wind density
   tdeflag, pressure_tvar, 'linear', /overwrite

   get_data,pressure_tvar,data=d

   pram_times = d.x
   pram = interpol(d.y,pram_times,ntimes)
endif else begin
   dprint,'Pressure variable not supplied, calculating from density and speed'
   ; Calculate pressure using default f_alpha (fraction of alpha particles)   
   pram = calc_pdyn(N_p=den,V_p=spd)
   ; No need to interpolate to ntimes here, since den and spd are already interpolated
endelse

if (size(xind_tvar,/type) eq 7) && (tnames(xind_tvar) ne '') then begin

  ; deflag index data
  tdeflag, xind_tvar, 'linear', /overwrite
  get_data,xind_tvar,data=d

  xind_times = d.x
  xind_vals = d.y
  
  xind = interpol(xind_vals,xind_times,ntimes)
endif else begin

; Calculate B-index or N-index
; No need to interpolate to ntimes, since the imf, den, and spd are already interpolated
if strlowcase(model) eq 'ta15b' then begin  
  dprint,'B-index variable not supplied, calculating from IMF, density, and speed'
  xind = omni2bindex(yimf=imf_y, zimf=imf_z,N_p=den,V_p=spd)
endif else if strlowcase(model) eq 'ta15n' then begin
  dprint,'N-index variable not supplied, calculating from IMF and speed'
  xind = omni2nindex(yimf=imf_y, zimf=imf_z, V_p=spd)
endif else message,model+' not recognized as a TA15 model name.'

endelse

par = {x:ntimes,y:[[pram],[imf_y],[imf_z],[xind],[dblarr(n)],[dblarr(n)],[dblarr(n)],[dblarr(n)],[dblarr(n)],[dblarr(n)]]}
if not keyword_set(newname) then begin 
 newname = model + '_par'
endif

store_data,newname,data=par

end
