;+
; Procedure:
;         spd_gen_overplot_ae_panel
;
; Purpose:
;         Generates combined AE index for overview plots
;
; Keywords:
;         date: start date for the plot
;         duration: int how many days, default is one
;         suffix: string for suffix
;         out_tname: (output) tplot name
;         error: (output) indicates an error
;
; Notes:
;   This is used in THEMIS and GOES overview plots.
;   Combines THEMIS AE with Kyoto AE.
;   When the Kyoto AE is available, it shows [Themis AE (black, 0), Kyoto AE (blue, 2)]
;   When the Kyoto AE is not available, it shows [Themis AE (black, 0), Real Time Kyoto AE 5-min (green, 4)]
;
; $LastChangedBy: crussell $
; $LastChangedDate: 2024-10-02 04:51:07 -0700 (Wed, 02 Oct 2024) $
; $LastChangedRevision: 32867 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/misc/spd_gen_overplot_ae_panel.pro $
;-

pro spd_gen_overplot_ae_panel, date=date, duration=duration, suffix=suffix, out_tname=out_tname, error=error
  ;; Kyoto and THEMIS AE
  compile_opt idl2
  error = 0

  if undefined(suffix) then suffix=''
  if undefined(duration) then duration = 1 ; days
  if ~undefined(date) then begin
    overviewdate = time_string(date)
    timespan, overviewdate, duration, /day
  endif

  ; For error handling and recovery
  input_timerange = timerange()

  ; Catch errors and return
  catch, errstats
  if errstats ne 0 then begin
    error = 1
    dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
    store_data,'kyoto_thm_combined_ae'+suffix, data={x:input_timerange, y:replicate(!values.d_nan,2)}
    options, 'kyoto_thm_combined_ae'+suffix, 'ytitle', 'AE Index'
    options, 'kyoto_thm_combined_ae'+suffix, 'ysubtitle', '[nT]'
    catch, /cancel
    return
  endif

  del_data, 'kyoto_ae'
  del_data, 'thg_idx_*'
  del_data, 'kyoto_thm_combined*'
  kyoto_ae_label = 'Kyoto AE'
  kyoto_colors = [0, 2]
  kyoto_color_single = [0]

  kyoto_load_ae, datatype = 'ae'
  thm_load_pseudoAE,datatype=['ae', 'uc_avg']
  if tnames('thg_idx_ae') eq '' then begin
    thm_make_AE ; no sites check, since the bad sites test is not distributed, jmm, 2018-04-30
  endif else copy_data, 'thg_idx_ae', 'thmAE'

  get_data, 'thmAE', data=thm_ae_data, dlimits=thm_ae_dlimits
  ; check thmAE yaxis limits
  if ~is_struct(thm_ae_data) then begin
    undefine, ylims
    if max(thm_ae_data.y) GT 2000. or min(thm_ae_data.y) LT -10. then ylims=[-10.,2000.]
  endif
  
  get_data, 'kyoto_ae', data=kyoto_ae_data, dlimits=kyoto_ae_dlimits
  if ~is_struct(kyoto_ae_data) then begin
    ; In this case, use the Kyoto real time AE generated at UCLA
    get_data, 'thg_idx_uc_avg', data=kyoto_ae_data, dlimits=kyoto_ae_dlimits
    kyoto_ae_label = 'Kyoto!C proxy AE'
    kyoto_colors = [0, 4]
    kyoto_color_single = [4]
  endif

  if is_struct(kyoto_ae_data) && is_struct(thm_ae_data) then begin
    combined_ae = fltarr(n_elements(kyoto_ae_data.X), 2)

    ; combine them into a single AE tplot variable
    for i=0l, n_elements(kyoto_ae_data.X)-1 do begin
      ae_nearest_neighbor = find_nearest_neighbor(thm_ae_data.X, kyoto_ae_data.X[i])
      if ae_nearest_neighbor ne -1 then begin
        idxae = where(thm_ae_data.X eq ae_nearest_neighbor, count)
        if count gt 1 then idxae = max(idxae)
        if idxae ge 0 && idxae le (n_elements(thm_ae_data.Y)-1) then begin
          combined_ae[i,0] = thm_ae_data.Y[idxae]
        endif else begin
          combined_ae[i,0] =  !values.f_nan
        endelse
        combined_ae[i,1] = kyoto_ae_data.Y[i]
      endif else begin
        combined_ae[i,0] = !values.f_nan
        combined_ae[i,1] = !values.f_nan
      endelse
    endfor
    str_element, thm_ae_dlimits, 'labels', ['Themis AE', kyoto_ae_label], /add
    str_element, thm_ae_dlimits, 'colors', kyoto_colors, /add
    str_element, thm_ae_dlimits, 'ytitle', 'AE index', /add
    str_element, thm_ae_dlimits, 'ysubtitle', '[nT]', /add
    str_element, thm_ae_dlimits, 'labflag', 1, /add
    if ~undefined(ylims) then begin
      str_element, thm_ae_dlimits, 'yaxis', ylims, /add
      str_element, thm_ae_dlimits, 'ystyle', 1, /add
    endif
    store_data, 'kyoto_thm_combined_ae'+suffix, data={x: kyoto_ae_data.X, y: combined_ae}, dlimits=thm_ae_dlimits
  endif else if is_struct(thm_ae_data) then begin
    ; only THEMIS AE available
    copy_data, 'thmAE', 'kyoto_thm_combined_ae'+suffix
    options, 'kyoto_thm_combined_ae'+suffix, 'ytitle', 'AE index'
    options, 'kyoto_thm_combined_ae'+suffix, 'labels', 'Themis AE'
    options, 'kyoto_thm_combined_ae'+suffix, 'labflag', 1
    options, 'kyoto_thm_combined_ae'+suffix, 'ysubtitle', '[nT]'
    options, 'kyoto_thm_combined_ae'+suffix, 'colors', 0
    if ~undefined(ylims) then begin
      options, 'kyoto_thm_combined_ae'+suffix, 'yaxis', ylims
      options, 'kyoto_thm_combined_ae'+suffix, 'ystle', 1
    endif
  endif else if is_struct(kyoto_ae_data) then begin
    ; only Kyoto AE available
    copy_data, 'kyoto_ae', 'kyoto_thm_combined_ae'+suffix
    options, 'kyoto_thm_combined_ae'+suffix, 'ytitle', 'AE index'
    options, 'kyoto_thm_combined_ae'+suffix, 'labels', kyoto_ae_label
    options, 'kyoto_thm_combined_ae'+suffix, 'labflag', 1
    options, 'kyoto_thm_combined_ae'+suffix, 'ysubtitle', '[nT]'
    options, 'kyoto_thm_combined_ae'+suffix, 'colors', kyoto_color_single
  endif else begin ;if nothing is there, create empty variable
    store_data,'kyoto_thm_combined_ae'+suffix, data={x:input_timerange, y:replicate(!values.d_nan,2)}
    options, 'kyoto_thm_combined_ae'+suffix, 'ytitle', 'AE Index'
    options, 'kyoto_thm_combined_ae'+suffix, 'ysubtitle', '[nT]'
  endelse

  out_tname = 'kyoto_thm_combined_ae'+suffix

end