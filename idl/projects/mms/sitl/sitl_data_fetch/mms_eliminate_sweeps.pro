;+
; FUNCTION: mms_eliminate_sweeps
;
; PURPOSE: Describe the procedure.
;
; INPUT:
; :Params:
;    cdfie: cdf info structure, output of cdf_load_vars
;
; OUTPUT:
; :Keywords:
;    verbose - MAKE IT TALK TO YOU
; :Author: Katherine Goodrich, contact: katherine.goodrich@colorado.edu
;-
function mms_eliminate_sweeps, cdfie, verbose=verbose

  dprint, " WARNING! DOESN'T ALWAYS REMOVE SWEEPS BECAUSE CDFS AREN'T ALWAYS RELIABLE IN LOGGING WHEN THEY OCCUR"
  PRINT, "It's not ideal, but I'm sick of dealing with it. -Katy"
  new_cdfi = cdfie

  names = cdfie.vars[*].name
  nnames = n_elements(names)
  dce_name = ''
  dcv_name = ''
  id = cdf_open(cdfie.filename)
  for n=0, nnames-1 do begin
    cdf_attget, id, 'VAR_TYPE', names[n], vtyp
    strs = strsplit(names[n], '_', /extract)
    Emtch = total(strmatch(strs, 'dce'))
    Vmtch = total(strmatch(strs, 'dcv'))
    if Emtch eq 1 and vtyp eq 'data' then dce_name = names[n]
    if Vmtch eq 1 and vtyp eq 'data' then dcv_name = names[n]
  endfor
  cdf_close, id
  fle = cdfie.filename
  dirstrs = strsplit(fle, '/', /extract)
  fle = dirstrs[-1]

  flestrs = strsplit(fle, '_', /extract)
  obs = flestrs[0]
  inst = flestrs[1]
  mode = flestrs[2]
  lvl = flestrs[3]
  typ = flestrs[4]
  timestr = flestrs[5]
  year = strmid(timestr, 0, 4)

  ;support data variable names
  eph_name = 'Epoch'
  sst_name = obs + '_sweep_start'
  ssp_name = obs + '_sweep_stop'

  ;sweep variable names
  swt_name = obs + '_sweep_swept'
  tab_name = obs + '_sweep_table'

  ;data variable names
  ;dce_name = obs + '_edp_dce_sensor'
  ;dcv_name = obs + '_edp_dcv_sensor'

  swp_start = get_variable_data(cdfie, sst_name)
  swp_stop = get_variable_data(cdfie, ssp_name)
  if swp_start[0] eq 0 or swp_stop[0] eq 0 then begin
    PRINT, ''
    dprint, 'NOT ENOUGH SWEEP INFORMATION IN CDF, YOU WILL JUST HAVE TO KEEP THEM'
    print, ''
    return, cdfie
  endif

  ;swp_probe = get_variable_data(cdfie, swt_name)
  ;  stop
  if dce_name eq '' then begin
    dprint, 'NO DCE DATA FOUND'
    dce = 0.0
  endif else begin
    dce = get_variable_data(cdfie, dce_name)
  endelse
  if dcv_name eq '' then begin
    dprint, 'NO DCV DATA FOUND'
    dcv = 0.0
  endif else begin
    dcv = get_variable_data(cdfie, dcv_name)
  endelse

  dce_time = get_variable_data(cdfie, eph_name)

  dce_size = size(dce)
  dcv_size = size(dv)
  if dce_size[0] ne 0 then begin
    new_dce = dce
    nswps = n_elements(swp_start)
    prb = 0
    for s = 0, nswps-1 do begin
      if swp_start[s] gt max(dce_time) then break
      if swp_stop[s] gt max(dce_time) then break
      ind = where(dce_time ge swp_start[s] - 5d8 and dce_time le swp_stop[s] + 5d8)
      if total(ind) ne -1 then begin

        ;      stop

        x = dce_time[ind]
        x = x - x[0]
        y = dce[ind,prb]
        slp = (y[-1] - y[0])/(x[-1] - x[0])
        yfit = y[0] + slp*x
        new_dce[ind,prb] = yfit
        ;    stop
        ;    window, 1
        if keyword_set(verbose) then begin
          plot, dce_time, dce[*,prb], xra=[swp_start[s]-2d9, swp_stop[s] + 2d9], xstyle=1
          plots, [swp_start[s]-5d8, swp_start[s] - 5d8], [-500,500]
          plots, [swp_stop[s]+ 5d8, swp_stop[s] + 5d8], [-500,500]
          oplot, dce_time, new_dce[*,prb], co=fsc_color('red')
          stop
        endif
      endif
      prb += 1
      if prb eq 3 then prb = 0
      ;    stop
    endfor
    ind = where(cdfie.vars[*].name eq dce_name)
    ;    new_dce = [[dce_x], [dce_y], [dce_z]]
    dateptr = ptr_new(new_dce)
    new_cdfi.vars[ind].dataptr = dateptr

  endif
  if dcv_size[0] ne 0 then begin
    dcv_1 = dcv[*,0]
    dcv_2 = dcv[*,1]
    dcv_3 = dcv[*,2]
    dcv_4 = dcv[*,3]
    dcv_5 = dcv[*,4]
    dcv_6 = dcv[*,5]
    nswps = n_elements(swp_start)
    prb = 0
    for s = 0, nswps-1 do begin

      if swp_start[s] gt max(dce_time) then break
      if swp_stop[s] gt max(dce_time) then break
      ind = where(dce_time ge swp_start[s] and dce_time le swp_stop[s] + 1d9)
      plot, dce_time[ind], dce_x[ind]

      if prb eq 0 then begin
        dcv_1[ind] = 0.0
        dcv_2[ind] = 0.0
      endif
      if prb eq 1 then begin
        dcv_3[ind] = 0.0
        dcv_4[ind] = 0.0
      endif
      if prb eq 2 then begin
        dcv_5[ind] = 0.0
        dcv_6[ind] = 0.0
      endif
      ;    stop
      ;    window, 1
      oplot, dce_time[ind], dce_x[ind], co=fsc_color('red')
      stop
      prb += 1
      if prb eq 3 then prb = 0
      ;    stop
    endfor
    ind = where(cdfie.vars[*].name eq dcv_name)
    new_dcv = [[dcv_1],[dcv_2],[dcv_3],[dcv_4],[dcv_5],[dcv_6]] ; will change eventually after commissioning
    datvptr = ptr_new(new_dcv)
    new_cdfi.vars[ind].dataptr = datvptr
  endif

  return,new_cdfi
end