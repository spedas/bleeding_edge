;+
; Procedure:
;  omni_solarwind_load
;
; Purpose:
;  Load solarwind data from OMNI (Pressure and Bz).
;  These quantities are used in LMN transformations.
;
; Keywords:
;     trange:     Time range of interest (array with 2 elements, start and end time).
;     prefix:     String to append to the beginning of the loaded tplot variable names.
;     suffix:     String to append to the end of the loaded tplot variable names.
;     hro2:       Flag. Load the newer HRO2 data set instead of HRO.
;     res5min:    Flag. If set, it loads 5min data, instead of 1min data.
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2025-04-13 15:12:57 -0700 (Sun, 13 Apr 2025) $
;$LastChangedRevision: 33257 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/omni/omni_solarwind_load.pro $
;-

pro get_omni_default_solarwind, trange=trange, swdata=swdata
  ; Set default values for pressure and Bz
  times=time_double(trange[0])
  timee=time_double(trange[1])
  timss=times-7200.;sec

  ; To get nominal magnetopause
  nnom=1000
  dt=(timee-times)/(nnom+0.)
  tgrid=times+dt*indgen(nnom+1)
  bzout=fltarr(nnom+1)+0.
  dpout=fltarr(nnom+1)+2.088 ;nPa
  swdata=[[tgrid],[dpout],[bzout]]

end

pro omni_solarwind_load, trange=trange, prefix=prefix, suffix=suffix, hro2=hro2, res5min=res5min

  ; Output tplot names
  if ~keyword_set(prefix) then prefix = 'OMNI_solarwind'
  if ~keyword_set(suffix) then suffix = ''
  if ~keyword_set(hro2) then hro2=0 else hro2=1
  new_bz = prefix + '_BZ' + suffix
  new_p = prefix + '_P' + suffix

  ; Load OMNI data for pressure and BZ
  if ~keyword_set(trange) then begin
    dprint, "trange is required"
    return
  endif
  omni_load_data, trange=trange, varformat='BZ_GSM', hro2=hro2, res5min=res5min
  omni_load_data, trange=trange, varformat='Pressure', hro2=hro2, res5min=res5min

  if hro2 eq 1 then begin
    bz_names = tnames('OMNI_HRO2_*_BZ_GSM')
    p_names= tnames('OMNI_HRO2_*_Pressure')
  endif else begin
    bz_names = tnames('OMNI_HRO_*_BZ_GSM')
    p_names= tnames('OMNI_HRO_*_Pressure')
  endelse

  bz_name = bz_names[0]
  p_name = p_names[0]

  if bz_name eq '' || p_name eq '' then begin
    dprint, 'Could not load OMNI data for BZ or Pressure. Loading default values.'
    ; Load default values
    get_omni_default_solarwind, trange=trange, swdata=swdata

    tout = swdata[*, 0]
    dpout = swdata[*, 1]
    bzout = swdata[*, 2]

    ; Save to tplot
    desc = 'Const BZ'
    data_att = {project:'OMNI', observatory:'OMNI', instrument:'OMNI', coord_sys:'gsm', units: "nT", description:desc}
    dlimits = {data_att: data_att, ysubtitle: '', description: desc}
    store_data, new_bz, data={x:tout, y:bzout}, dlimits=dlimits
    desc = 'Const Pressure'
    data_att = {project:'OMNI', observatory:'OMNI', instrument:'OMNI', coord_sys:'gsm', units: "nPa", description:desc}
    dlimits = {data_att: data_att, ysubtitle: '', description: desc}
    store_data, new_p, data={x:tout, y:dpout}, dlimits=dlimits
  endif else begin
    copy_data, bz_name, new_bz
    copy_data, p_name, new_p
  endelse

  ; Fill gaps and replace NaNs with average values
  tdegap, [new_bz, new_p], /overwrite
  tdeflag, [new_bz, new_p], 'remove_nan', /overwrite

  ; Time-clip data
  time_clip, new_bz, trange[0], trange[1], /replace
  time_clip, new_p, trange[0], trange[1], /replace

  dprint, 'New tplot vars created for OMNI solarwind: ' +new_p + ' ,' + new_bz

end
