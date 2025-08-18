;+
; Procedure:
;  lmn_matrix_make
;
; Purpose:
;  Creates a tplot variable, using the GSM to LMN transformation gsm2lmn.
;
; Parameters (required):
;     pos_var_name: tplot name with position in GSM coorinates.
;     mag_var_name: tplot name with B field in GSM coordinates.
;
; Keywords (optional):
;     trange:   Time range of interest (array with 2 elements, start and end time).
;               If trange is not provided, it will be extracted from mag_var_name.
;     hro2:     Flag. Load the newer HRO2 data set instead of HRO.
;     newname:  Name for the output tplot variable. If not set, newname will be mag_var_name + "_lmn_mat".
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2025-04-13 15:15:43 -0700 (Sun, 13 Apr 2025) $
;$LastChangedRevision: 33258 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/lmn_transform/lmn_matrix_make.pro $
;-

pro lmn_matrix_make, pos_var_name, mag_var_name, trange=trange, hro2=hro2, newname=newname

  if ~keyword_set(pos_var_name) && tnames(pos_var_name) ne '' then begin
    dprint,'lmn_matrix_make requires pos_var_name to be set'
    return
  endif
  if ~keyword_set(mag_var_name) && tnames(mag_var_name) ne '' then begin
    dprint,'lmn_matrix_make requires mag_var_name to be set'
    return
  endif
  if ~keyword_set(trange) || n_elements(trange) ne 2 then begin
    ; Set trange from input tplot variable
    get_data, mag_var_name, data=d, dlimits=dl
    trange = [min(d.x), max(d.x)]
    dprint, 'trange was set using mag_var_name:', trange
  endif
  if ~keyword_set(newname) then begin
    newname = mag_var_name + "_lmn_mat"
  endif

  ; Get solarwind data
  omni_solarwind_load, trange=trange, hro2=hro2
  bz_names = tnames('OMNI_solarwind_BZ')
  p_names = tnames('OMNI_solarwind_P')
  ; We are using repeat_extrapolate because the BZ and Pressure have values for 1min
  ; but the B field can many more values (every 3 secs) and the edges can go off with extrapolation
  bz_interpol = bz_names[0] + '_interpol'
  p_interpol = p_names[0] + '_interpol'
  tinterpol, bz_names[0], mag_var_name, newname=bz_interpol, /repeat_extrapolate
  tinterpol, p_names[0], mag_var_name, newname=p_interpol, /repeat_extrapolate
  get_data, bz_interpol, data=dbz, dl=dlbz
  get_data, p_interpol, data=dp, dl=dlp
  timesw = dbz.x
  swdata = dindgen(n_elements(timesw), 3)
  swdata[*, 0] = timesw
  swdata[*, 1] = dp.y
  swdata[*, 2] = dbz.y

  ; Get position data
  pos_interpol = pos_var_name + "_interpol"
  tinterpol, pos_var_name, mag_var_name, newname=pos_interpol
  get_data, pos_interpol, data=dpos, limits=lp, dlimits=dlp
  timesp = dpos.x
  txyz = dindgen(n_elements(timesp), 4)
  txyz[*, 0] = timesp
  txyz[*, 1] = dpos.y[*, 0]
  txyz[*, 2] = dpos.y[*, 1]
  txyz[*, 3] = dpos.y[*, 2]

  ; Get magnetic field data
  get_data, mag_var_name, data=db, limits=lb, dlimits=dlb
  Bxyz = db.y

  ; Apply GSM to LMN
  gsm2lmn, txyz, Bxyz, Blmn, swdata

  ; Store output in tplot
  d_new = dlb
  str_element, d_new, 'ytitle', /delete
  str_element, d_new, 'ysubtitle', '[LMN]', /add
  str_element, d_new, 'data_att.coord_sys', 'LMN', /add
  str_element, d_new, 'labels', ['Bl', 'Bm', 'Bn'], /add
  store_data, newname, data={x:timesw, y:Blmn}, dlimits=d_new

  time_clip, newname, trange[0], trange[1], /replace

  dprint, "LMN data saved in tplot variable: " + newname

end
