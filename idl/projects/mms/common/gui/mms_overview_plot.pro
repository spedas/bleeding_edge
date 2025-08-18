;+
; Procedure:
;         mms_overview_plot
;
; Purpose:
;         Generates overview plots for MMS data
;
; Keywords:
;         date: start date for the overview plot
;         duration: duration of the overview plot, in days; defaults to 1-day
;         directory: local directory to save the overview plots to (should end with '/' or '\')
;         device: change the plot device for cron plotting (for cron use device = 'z')
;         geopack_lshell: calculate L-shell by tracing field lines
;             to the equator instead of using the dipole assumption
;         skip_ae_idx: set this keyword to skip downloading/plotting AE data
;         error: 1 indicates an error, 0 for no error
;
;    * Keywords specific to creating overview plots in the GUI:
;         gui_overplot: overview plot was created in the GUI
;         oplot_calls: pointer to an int for tracking calls to overview plots - for
;             avoiding overwriting tplot data already loaded during this session
;          import_only: Used to make this routine import the data into the gui, but not plot it.
;
; Notes:
;
;
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2023-11-27 09:29:13 -0800 (Mon, 27 Nov 2023) $
; $LastChangedRevision: 32257 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/gui/mms_overview_plot.pro $
;-

pro mms_overview_plot, date = date, probe = probe_in, directory = directory, device = device, $
  geopack_lshell = geopack_lshell, duration = duration, gui_overplot = gui_overplot, $
  oplot_calls = oplot_calls, error = error, skip_ae_idx = skip_ae_idx, import_only=import_only, $
  _extra=_extra


  compile_opt idl2
  error = 0

  ; Catch errors and return
  catch, errstats
  if errstats ne 0 then begin
    error = 1
    dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
    catch, /cancel
    return
  endif

  ; delete any tplot variables sitting around
  ;store_data, '*', /delete

  if undefined(probe_in) then probe = '1' else probe=probe_in[0]
  if undefined(date) then overviewdate = '2015-10-16' else overviewdate = time_string(date)
  if undefined(duration) then duration = 1 ; days
  if undefined(oplot_calls) then suffix = '' else suffix = strcompress('_op'+string(oplot_calls[0]), /rem)

  timespan, overviewdate, duration, /day
  time = time_struct(overviewdate)
  earth_radius = 6371.

  window_xsize = 750
  window_ysize = 800
  if undefined(directory) then dir = 'mms'+probe+path_sep() else dir = directory
  if ~undefined(device) then begin
    set_plot, device
    device, set_resolution = [window_xsize, window_ysize]
  endif
  if undefined(skip_ae_idx) then begin
    ;;=============================================================================
    ;; Panel 1: Kyoto and THEMIS AE
    kyoto_load_ae, datatype = 'ae'
    thm_make_AE

    get_data, 'thmAE', data=thm_ae_data, dlimits=thm_ae_dlimits
    get_data, 'kyoto_ae', data=kyoto_ae_data, dlimits=kyoto_ae_dlimits

    if is_struct(kyoto_ae_data) && is_struct(thm_ae_data) then begin
      combined_ae = fltarr(n_elements(kyoto_ae_data.X), 2)

      ; combine them into a single AE tplot variable
      for i=0l, n_elements(kyoto_ae_data.X)-1 do begin
        ae_nearest_neighbor = find_nearest_neighbor(thm_ae_data.X, kyoto_ae_data.X[i])
        if ae_nearest_neighbor ne -1 then begin
          combined_ae[i,0] = thm_ae_data.Y[where(thm_ae_data.X eq ae_nearest_neighbor)]
          combined_ae[i,1] = kyoto_ae_data.Y[i]
        endif else begin
          combined_ae[i,0] = !values.f_nan
          combined_ae[i,1] = !values.f_nan
        endelse
      endfor
      str_element, thm_ae_dlimits, 'labels', ['THEMIS AE', 'Kyoto AE'], /add
      str_element, thm_ae_dlimits, 'colors', [2,0], /add
      str_element, thm_ae_dlimits, 'ytitle', 'AE index', /add
      str_element, thm_ae_dlimits, 'ysubtitle', '[nT]', /add
      str_element, thm_ae_dlimits, 'labflag', 1, /add
      store_data, 'kyoto_thm_combined_ae'+suffix, data={x: kyoto_ae_data.X, y: combined_ae}, dlimits=thm_ae_dlimits
    endif else if is_struct(thm_ae_data) then begin
      ; only THEMIS AE available
      copy_data, 'thmAE', 'kyoto_thm_combined_ae'+suffix
      options, 'kyoto_thm_combined_ae'+suffix, 'ytitle', 'AE index'
      options, 'kyoto_thm_combined_ae'+suffix, 'labels', 'THEMIS AE'
      options, 'kyoto_thm_combined_ae'+suffix, 'labflag', 1
      options, 'kyoto_thm_combined_ae'+suffix, 'ysubtitle', '[nT]'
    endif else if is_struct(kyoto_ae_data) then begin
      ; only Kyoto AE available
      copy_data, 'kyoto_ae', 'kyoto_thm_combined_ae'+suffix
      options, 'kyoto_thm_combined_ae'+suffix, 'ytitle', 'AE index'
      options, 'kyoto_thm_combined_ae'+suffix, 'labels', 'Kyoto AE'
      options, 'kyoto_thm_combined_ae'+suffix, 'labflag', 1
      options, 'kyoto_thm_combined_ae'+suffix, 'ysubtitle', '[nT]'
    endif

  endif
  ;;=============================================================================
  ; load the data
  mms_load_fgm, probes=probe, suffix=suffix
  
  mms_load_fpi, probes=probe, datatype=['des-moms', 'dis-moms'], suffix=suffix
  
  store_data, 'mms'+probe+'_fpi_density'+suffix, data='mms'+probe+['_dis_numberdensity_fast', '_des_numberdensity_fast']+suffix
  
  mms_load_edp, probes=probe, suffix=suffix
  
  mms_load_hpca, datatype='moments', probes=probe, suffix=suffix
  
  mms_load_feeps, datatype='electron', probes=probe, suffix=suffix
  
  mms_load_eis, datatype='extof', probes=probe, suffix=suffix

  ; no errors up to this point
  error = 0
  ;;=============================================================================
  ; Make the figure
  !p.background=255.
  !p.color=0.
  time_stamp,/off
  loadct2,43
  !p.charsize=0.8

  full_mms_plot = 'mms'+probe+['_fgm_b_gsm_srvy_l2_bvec', $
                              '_epd_eis_srvy_l2_extof_proton_flux_omni', $
                              '_dis_energyspectr_omni_fast', $
                              '_epd_feeps_srvy_l2_electron_intensity_omni', $
                              '_des_energyspectr_omni_fast', $
                              '_hpca_hplus_number_density', $
                              '_edp_dce_dsl_fast_l2', $
                              '_fpi_density', $
                              '_hpca_hplus_ion_bulk_velocity_GSM', $
                              '_hpca_oplus_ion_bulk_velocity_GSM']+suffix

  if undefined(gui_overplot) then begin
    if ~undefined(device) then begin
      tplot_options,'title','MMS-'+probe+' Overview ('+overviewdate+')'
      tplot, ['kyoto_thm_combined_ae', $ ; AE plot
        [full_mms_plot]]
    endif else begin
      window, 1, xsize=window_xsize, ysize=window_ysize
      tplot_options,'title','MMS-'+probe+' Overview ('+overviewdate+')', window=1
      tplot, ['kyoto_thm_combined_ae', $ ; AE plot
        [full_mms_plot]], window=1
    endelse

    thm_gen_multipngplot, 'mms'+probe, overviewdate, directory = dir, /mkdir

  endif else begin
    tplot_gui, /no_verify, /add_panel, import_only=import_only, ['kyoto_thm_combined_ae'+suffix, $ ; AE plot
      [full_mms_plot]]

  endelse
end