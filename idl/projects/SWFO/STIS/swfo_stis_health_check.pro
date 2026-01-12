;+
;PROCEDURE:  SWFO_STIS_HEALTH_CHECK
;PURPOSE: Calculates average properties of the SWFO STIS instrument
; before, during, and after a requested period of time. Assumes tplot
; variables are already loaded (e.g. via swfo_stis_load).
;
;USAGE:
;  ;Load data first:
;  swfo_stis_load, trange=['2025-09-30', '2025-09-30']
;  ; Then show the health:
;  swfo_stis_health_check, ['2025 9 30 15:04', '2025 9 30 15:58']
;
;KEYWORDS:
;       STRUCT_NAME:  Reference tplot name to access HKP variables from.
;                     string, either 'swfo_stis_L0b' or 'swfo_stis_hkp2'.
;
;       SAVE_DIR:     Optional, location to save plot of data.
;
;       MAKE_PLOT:    Optional, default enabled, makes plot of STIS health
;                     variables.
;
;       WINDOW_BEFORE:  Range of number of seconds to average over before
;                       trange, defaults to -60 sec to -2 sec before.
;
;       WINDOW_AFTER:   Range of number of seconds to average over after
;                       trange, defaults to +2 sec to +60 sec after.
;
;       DURATION:   Number of seconds to average after trange if trange is
;                   a single time (e.g. 2025-12-15 08:00), defaults to 60 sec.
;
; $LastChangedBy: rjolitz $
; $LastChangedDate: 2026-01-05 11:50:28 -0800 (Mon, 05 Jan 2026) $
; $LastChangedRevision: 33966 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_health_check.pro $


pro swfo_stis_health_check, trange,$
  struct_name=struct_name,$
  save_dir=save_dir, make_plot=make_plot,$
  window_before=window_before, window_after=window_after,$
  duration=duration


  if ~keyword_set(struct_name) then struct_name = 'swfo_stis_L0b'
  if ~keyword_set(save_dir) then save_dir = '~/'
  if ~keyword_set(make_plot) then make_plot = 0b
  if ~keyword_set(window_before) then window_before = [-60, -2]
  if ~keyword_set(window_after) then window_after = [2, 60]
  if ~keyword_set(duration) then duration = 60

  trange = time_double(trange)
  if n_elements(trange) eq 1 then trange = [trange, trange + duration]

  ; list of names to show
  hkp_var = ['ADC_BIAS_VOLTAGE', 'TEMP_DAP', 'VOLTAGE_1P5_VD',$
             'VOLTAGE_3P3_VD', 'VOLTAGE_5P0_VD', 'VOLTAGE_DFE_POS_VA',$
             'VOLTAGE_DFE_NEG_VA', 'BIAS_CURRENT_MICROAMPS', 'TEMP_SENSOR1', 'TEMP_SENSOR2',$
             'FPGA_REV']



  ; Will return average housekeeping variables before/during/after
  ; test:
  pre_trange = trange + window_before
  post_trange = trange + window_after
  ; stop

  ; Get the dynamic array containing the housekeeping values
  get_data, struct_name + '_DAC_VALUES', ptr=ptr
  ddata = ptr.ddata

  ; Make list of tranges and labels:
  tranges = list(pre_trange, trange, post_trange)
  trange_names = ['before', 'during', 'after']

  avg = dictionary()
  for var_i=0, n_elements(hkp_var) - 1 do avg[hkp_var[var_i]] = list()

  for i = 0, n_elements(tranges) - 1 do begin
    ; get trange / name
    trange_i = tranges[i]
    ; trange_name_i = trange_names[i]
    ; print, strupcase(trange_name_i) + ' TEST:'
    ; get dynamic array in range and then average the results
    dda_in_range = ddata.sample(range=trange_i, tagname='TIME_UNIX')
    avg_dda = average(dda_in_range, /nan)

    ; if anything is in the average structure (will be null if
    ; there's no elements before/after), return a print statement
    ; with the requested info:
    if isa(avg_dda) then begin
      for var_i=0, n_elements(hkp_var) - 1 do begin
        var_name_i = hkp_var[var_i]
        str_element, avg_dda, var_name_i, v
        ; print, 'AVG ' + var_name_i + ' ' + trange_name_i + ' test: ', v
        avg[var_name_i].add, v
      endfor
    endif else begin

      for var_i=0, n_elements(hkp_var) - 1 do begin
        var_name_i = hkp_var[var_i]
        avg[var_name_i].add, !values.f_nan
      endfor


    endelse
  endfor

  print, format='(A23, " | ", A6," | ", A6," | ", A6)',$
    "HKP var name", trange_names[0], trange_names[1], trange_names[2]
  print, '========================================================'
  for var_i=0, n_elements(hkp_var) - 1 do begin
    var = hkp_var[var_i]
    avg_i = avg[var]
    print, var, avg_i[0], avg_i[1], avg_i[2], format='(A23, " | ", F6.2, " | ", F6.2, " | ", F6.2)'

  endfor

  ; make the tplot
  if make_plot then begin
    tplot, struct_name + '_' + hkp_var
    tstart = pre_trange[0]
    tend = post_trange[1]

    ymd_str = time_string(tstart, tformat="YYYYMMDD")
    start_str = time_string(tstart, tformat="hhmmss")
    end_str = time_string(tend, tformat="hhmmss")

    tlimit, [tstart, tend]
    fname = 'stis_health_' + ymd_str + '_' + start_str + 'to' + end_str + '.png'
    if ~save_dir.endswith('/') then save_dir = save_dir + '/'
    save_path = save_dir + fname
    write_png, save_path, tvrd(/true)
   endif

   ; stop

end