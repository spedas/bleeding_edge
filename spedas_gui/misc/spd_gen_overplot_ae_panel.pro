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
; $LastChangedBy: nikos $
; $LastChangedDate: 2021-07-08 12:41:39 -0700 (Thu, 08 Jul 2021) $
; $LastChangedRevision: 30110 $
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
        idxae = where(thm_ae_data.X eq ae_nearest_neighbor)
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
    store_data, 'kyoto_thm_combined_ae'+suffix, data={x: kyoto_ae_data.X, y: combined_ae}, dlimits=thm_ae_dlimits
  endif else if is_struct(thm_ae_data) then begin
    ; only THEMIS AE available
    copy_data, 'thmAE', 'kyoto_thm_combined_ae'+suffix
    options, 'kyoto_thm_combined_ae'+suffix, 'ytitle', 'AE index'
    options, 'kyoto_thm_combined_ae'+suffix, 'labels', 'Themis AE'
    options, 'kyoto_thm_combined_ae'+suffix, 'labflag', 1
    options, 'kyoto_thm_combined_ae'+suffix, 'ysubtitle', '[nT]'
    options, 'kyoto_thm_combined_ae'+suffix, 'colors', 0
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