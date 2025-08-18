
;+
;TODO
; PROCEDURE: get_ta16_params
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
;           symh(optional): Sym-H index (nT),
;             longitudinal symmetric component of the ring current;
;             should either be a string naming a tplot variable or an
;             array or a single value.  If a tplot input is used it will
;             be interpolated to match the time inputs from the position
;             var. Non-tplot array values must match the number of times in the
;             tplot input for pos_gsm_tvar
;
;           symc(optional): sliding average of Sym-H over 30-min interval,
;             centered on the current time moment.
;             Either symh or symc must be provided.
;             symc can be computed from symh using GEOPACK_GETSYMHC
;             should either be a string naming a tplot variable or an
;             array or a single value.  If a tplot input is used it will
;             be interpolated to match the time inputs from the position
;             var. Non-tplot array values must match the number of times in the
;             tplot input for pos_gsm_tvar
;
;
;           newname(optional): the name of the output tplot variable
;               (default: ta16_par)
;
;           trange(optional): the time range over which the parameters
;               should range, if not set, this program will check the
;               timespan variable or prompt the user for a range
;
;           speed(optional): set this if Vp_tvar is stored as a speed
;
;
; Notes:
;   Modified from get_ta15_params.
;   TA16: Ten-element array parmod: (1) Pdyn [nPa], (2) SymHc, (3) XIND, (4) IMF By [nT].
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2022-09-22 15:29:33 -0700 (Thu, 22 Sep 2022) $
; $LastChangedRevision: 31124 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/ta16/get_ta16_params.pro $
;-
pro get_ta16_params,imf_tvar=imf_tvar,Np_tvar=Np_tvar,Vp_tvar=Vp_tvar,xind_tvar=xind_tvar, symh_tvar=symh_tvar, symc_tvar=symc_tvar,pressure_tvar=pressure_tvar, imf_yz=imf_yz, newname=newname,trange=trange,speed=speed,model=model

  COMPILE_OPT idl2
  model = 'ta16'
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
  endif else if ((size(xind_tvar,/type) ne 7) || (tnames(xind_tvar) eq '')) then begin
    spd_flag = 1
  endif


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
    ; Calculate N-index
    ; No need to interpolate to ntimes, since the imf, den, and spd are already interpolated
    dprint,'N-index variable not supplied, calculating from IMF and speed'
    xind = omni2nindex(yimf=imf_y, zimf=imf_z, V_p=spd)
  endelse

  ; If symc is provided, use it, otherwise compute it from symh
  if ((size(symc_tvar,/type) eq 7) && (tnames(symc_tvar) ne '')) then begin
    symc_dat = symc_tvar
  endif else if ((size(symh_tvar,/type) eq 7) && (tnames(symh_tvar) ne '')) then begin
    dprint,'SYM-HC variable not supplied, calculating from raw SYM-H and pressure'
    symcn=symh_tvar+'_cn'
    pres_var='pres_var'
    store_data, pres_var, data={x:ntimes, y:pram}
    symh2symc, symh=symh_tvar, pdyn=pres_var, trange=trange, newname=symcn
    symc_dat = symcn
    symc = symcn
  endif

; Removed some questionable validation logic here (appeared to be treating symc_dat as a numeric array?)
; Perhaps there is a failure mode in symh2symc that still needs to be checked here.  JWL 2022-09-16

    get_data, symc_dat, data=ds
    sym_times = ds.x
    sym_y = ds.y
    sym_val = interpol(sym_y, sym_times, ntimes)

;    
;help,sym_val

  par = {x:ntimes,y:[[pram],[sym_val],[xind],[imf_y],[dblarr(n)],[dblarr(n)],[dblarr(n)],[dblarr(n)],[dblarr(n)],[dblarr(n)]]}
  if not keyword_set(newname) then begin
    newname = model + '_par'
  endif

  store_data,newname,data=par

end
