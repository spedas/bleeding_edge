;;;;;;;;;;;;;;;;;;;;
; swfo_stis_lpt.pro
; IFC analysis
; only works for L0b + L1a, since needs energy bin info.
; IFC works by:
; - cycling down the DAC for threshold for each
; - pulsers on
; 

pro stis_threshold_analysis, log=log

  ; the ifc script names:
  ifc_user_09 = [130, 113, 114, 116]
  ; Map of relevant values
  map_dac_to_det = dictionary("O1", 0, "O2", 1, "O3", 2, "F1", 4, "F2", 5, "F3", 6)
  single_detector = ["O1", "O2", "O3", "F1", "F2", "F3"]
  ; colors = ['b', 'g', 'r', 'm', 'c', 'k']
  colors = dictionary("O1", 'b', "O2", 'g', "O3", 'r', "F1", 'm', "F2", 'c', "F3", 'k')
  colors = [2,4,6,1,3,0]
  n_en = 48

  ; Get the Level 0b and Level 1a str
  ; Note, they have the same time indices
  get_data, 'swfo_stis_L0b_DAC_VALUES', data=dac_values_tplot
  get_data, 'swfo_stis_L0b_USER_09', data=user_09_tplot, ptr=ptr
  l0b_ddata = ptr.ddata
  get_data, 'swfo_stis_L1a_TIME_UNIX', ptr=ptr
  l1a_ddata = ptr.ddata

  ; Get the time info
  t_unix = user_09_tplot.x
  user_09 = user_09_tplot.y
  dac = dac_values_tplot.y

  ; Threshold tests: get first nonzero energy:
  thresh_index = where(user_09 eq ifc_user_09[0], nt)
  ifc_start_index = thresh_index[0]
  dac_0 = reform(dac[ifc_start_index - 2, *])
  dac_thresh = dac[thresh_index, *]
  thresh_t_unix = t_unix[thresh_index]
  ; print, nt
  ; print, thresh_index

  if ~keyword_set(log) then begin
    lim = dictionary('yrange', [-20, 200], 'xrange', [0, 1000], 'xtitle', 'DAC', 'ytitle', 'En., keV')
  endif else begin
    lim = dictionary('yrange', [1, 500], 'xrange', [1, 1000],$
                     'xtitle', 'DAC', 'ytitle', 'En., keV', 'ylog', 1, 'xlog', 1)
  endelse
  window, 2
  box, lim

  foreach det, single_detector, detector_index do begin
    ; Get the time index range over which the DAC for each detector
    ; varies. Since it starts way higher than the default and
    ; goes much lower, can try to identify all indices that aren't
    ; default dac and get the start/end for that range
    dac_index = detector_index *(detector_index lt 3) + (detector_index + 1) * (detector_index ge 3)
    index_varying = where(dac_thresh[*, dac_index] ne dac_0[dac_index])
    start = index_varying[0] + thresh_index[0]
    last = index_varying[-1] + thresh_index[0]

    n_t = last - start + 1
    det_varying_index = indgen(n_t) + start


    print, det, detector_index
    print, start, last
    print, det_varying_index
    ; stop

    l0b_dda_thresh = l0b_ddata.slice(det_varying_index)
    l1a_dda_thresh = l1a_ddata.slice(det_varying_index)
    ; stop

    str_element, l0b_dda_thresh, "DAC_VALUES", dac_i
    str_element, l1a_dda_thresh, "RATE_" + det, rate
    str_element, l1a_dda_thresh, "SPEC_" + det + "_NRG", nrg

    ; Ignore indices where there is no counts in any energy
    ; bin, since cannot determine the first energy bin with
    ; nonzero counts:
    tot_rate = total(rate, 1)
    skip_indices = where(tot_rate eq 0)
    ; print, 'Zero counts, skip indices:', skip_indices

    ; Make new arrays for each detector/coincidence
    first_en = fltarr(n_t) + !values.f_nan

    ; Iterate through each energy channel,
    ; from index 0, and identify bins != 0.
    ; If Bin number already logged, ignore:
    for j = 0, n_en -1 do begin
      rate_j = rate[j, *]
      nonzero_j = where(rate_j ne 0, /null)
      print,'Nonzero at ', j, ':', nonzero_j

      ; exclude indices already in the skipped array:
      foreach k, skip_indices do begin
        excl_index = where(nonzero_j eq k, n_in_skip, complement=rest_index, /null)
        if n_in_skip ne 0 then nonzero_j = nonzero_j[rest_index]

      endforeach



      first_en[nonzero_j] = nrg[j, nonzero_j]

      ; Add elements that were in:
      skip_indices = [skip_indices, nonzero_j]
      skip_indices = skip_indices[sort(skip_indices)]
      print, 'New skip:', skip_indices

      if n_elements(skip_indices) eq n_t then break

    endfor
    ; print, first_en
    ; Subset to only the nonnan elements:
    dac_i = dac_i[dac_index, *]
    nonnan = where(finite(first_en))

    dac_i = dac_i[nonnan]
    first_en = first_en[nonnan]
    print, dac_i
    print, first_en

    index_below_floor = where((first_en[1:*] - first_en[-1]) eq 0)

    if index_below_floor[0] gt 1 then begin
      dac_i = dac_i[0:index_below_floor[0]]
      first_en = first_en[0:index_below_floor[0]]
      ; scatt_i = scatterplot(dac_i, first_en, /xlog, /ylog, xtit='DAC ' + det, ytit=det + ' Energy, keV')


      oplot, dac_i, first_en, psym=4, color=colors[detector_index]

      ; Fit: IDL
      if keyword_set(log) then begin
        weights = linfit(alog10(dac_i), alog10(first_en))
        xv = findgen(1000)
        oplot, xv, 10^(weights[1]*alog10(xv) + weights[0]), color=colors[detector_index]

      endif else begin
        ; Fit: Davin's method
        p = polycurve2(order=1)
        fit, dac_i, first_en, param=p
        pf, p, color=colors[detector_index]
      endelse

      stop
    endif else print, 'Not enough signal, skipping to next channel.'


  endforeach

end

;;;;;;;;;;;;;;;;;;;;
; stis_pulser_analysis 
;;;;;;;

pro stis_pulser_analysis

  ; the ifc script names:
  ifc_user_09 = [130, 113, 114, 116]
  ; Map of relevant values
  map_dac_to_det = dictionary("O1", 0, "O2", 1, "O3", 2, "F1", 4, "F2", 5, "F3", 6)
  single_detector = ["O1", "O2", "O3", "F1", "F2", "F3"]
  ; colors = ['b', 'g', 'r', 'm', 'c', 'k']
  colors = dictionary("O1", 'b', "O2", 'g', "O3", 'r', "F1", 'm', "F2", 'c', "F3", 'k')
  colors = [2,4,6,1,3,0]
  n_en = 48

  ; Get the Level 0b and Level 1a str
  ; Note, they have the same time indices
  get_data, 'swfo_stis_L0b_DAC_VALUES', data=dac_values_tplot
  get_data, 'swfo_stis_L0b_USER_09', data=user_09_tplot, ptr=ptr
  l0b_ddata = ptr.ddata
  get_data, 'swfo_stis_L1a_TIME_UNIX', ptr=ptr
  l1a_ddata = ptr.ddata

  ; Get the time info
  t_unix = user_09_tplot.x
  user_09 = user_09_tplot.y
  dac = dac_values_tplot.y

  ; Threshold tests: get first nonzero energy:
  thresh_index = where(user_09 eq ifc_user_09[0], nt)
  ifc_start_index = thresh_index[0]
  dac_0 = reform(dac[ifc_start_index - 2, *])
  dac_thresh = dac[thresh_index, *]
  thresh_t_unix = t_unix[thresh_index]
  ; print, nt
  ; print, thresh_index

  lim = dictionary('yrange', [-20, 200], 'xrange', [0, 1000], 'xtitle', 'DAC', 'ytitle', 'En., keV')
  box, lim

  foreach det, single_detector, detector_index do begin
    ; Get the time index range over which the DAC for each detector
    ; varies. Since it starts way higher than the default and
    ; goes much lower, can try to identify all indices that aren't
    ; default dac and get the start/end for that range
    dac_index = detector_index *(detector_index lt 3) + (detector_index + 1) * (detector_index ge 3)
    index_varying = where(dac_thresh[*, dac_index] ne dac_0[dac_index])
    start = index_varying[0] + thresh_index[0]
    last = index_varying[-1] + thresh_index[0]

    n_t = last - start + 1
    det_varying_index = indgen(n_t) + start


    print, det, detector_index
    print, start, last
    print, det_varying_index
    ; stop

    l0b_dda_thresh = l0b_ddata.slice(det_varying_index)
    l1a_dda_thresh = l1a_ddata.slice(det_varying_index)
    ; stop

    str_element, l0b_dda_thresh, "DAC_VALUES", dac_i
    str_element, l1a_dda_thresh, "RATE_" + det, rate
    str_element, l1a_dda_thresh, "SPEC_" + det + "_NRG", nrg

    ; Ignore indices where there is no counts in any energy
    ; bin, since cannot determine the first energy bin with
    ; nonzero counts:
    tot_rate = total(rate, 1)
    skip_indices = where(tot_rate eq 0)
    ; print, 'Zero counts, skip indices:', skip_indices

    ; Make new arrays for each detector/coincidence
    first_en = fltarr(n_t) + !values.f_nan

    ; Iterate through each energy channel,
    ; from index 0, and identify bins != 0.
    ; If Bin number already logged, ignore:
    for j = 0, n_en -1 do begin
      rate_j = rate[j, *]
      nonzero_j = where(rate_j ne 0, /null)
      print,'Nonzero at ', j, ':', nonzero_j

      ; exclude indices already in the skipped array:
      foreach k, skip_indices do begin
        excl_index = where(nonzero_j eq k, n_in_skip, complement=rest_index, /null)
        if n_in_skip ne 0 then nonzero_j = nonzero_j[rest_index]

      endforeach



      first_en[nonzero_j] = nrg[j, nonzero_j]

      ; Add elements that were in:
      skip_indices = [skip_indices, nonzero_j]
      skip_indices = skip_indices[sort(skip_indices)]
      print, 'New skip:', skip_indices

      if n_elements(skip_indices) eq n_t then break

    endfor
    ; print, first_en
    ; Subset to only the nonnan elements:
    dac_i = dac_i[dac_index, *]
    nonnan = where(finite(first_en))

    dac_i = dac_i[nonnan]
    first_en = first_en[nonnan]
    print, dac_i
    print, first_en

    index_below_floor = where((first_en[1:*] - first_en[-1]) eq 0)

    if index_below_floor[0] gt 1 then begin
      dac_i = dac_i[0:index_below_floor[0]]
      first_en = first_en[0:index_below_floor[0]]
      ; scatt_i = scatterplot(dac_i, first_en, /xlog, /ylog, xtit='DAC ' + det, ytit=det + ' Energy, keV')


      oplot, dac_i, first_en, psym=4, color=colors[detector_index]

      ; Fit: IDL
      weights = linfit(dac_i, first_en)
      xv = findgen(1000)
      oplot, xv, weights[1]*xv + weights[0], color=colors[detector_index]

      ; Fit: Davin's method
      p = polycurve2(order=1)
      fit, dac_i, first_en, param=p
      pf, p, color=colors[detector_index]

      stop
    endif else print, 'Not enough signal, skipping to next channel.'


  endforeach

end


;;;;;;;;;;;;;;;;;;;
; Script:


LPT_times = [['2025/09/30 15:04:32', '2025/09/30 15:58:32'],$
             ['2025/10/07 15:42:13', '2025/10/07 16:36:10']]

; IFC_times

eval_instrument_health = 0
make_health_plot = 1

mission_start = '2025 9 30'
mission_start_unix = time_double(mission_start)

; These aren't all LPTs, but the script will work all the same
LPT_days = ['2025 9 30', '2025 10 7', '2025 10 15']
LPT_days = ['2025 9 30']

; Indicate which data struct you want. I used L0b,
; but you can use the hkp packets too.
; note: l0b in science cadence, not hkp cadence
; health_struct = 'pb_swfo_stis_hkp1_'
; health_struct = 'pb_swfo_stis_hkp2_'
; health_struct = 'swfo_stis_hkp1_'
; health_struct = 'swfo_stis_hkp2_'
health_struct = 'swfo_stis_L0b'
tcheck_struct = 'swfo_stis_L0b'

ifc_var = ['USER_09', 'DAC_VALUES', 'SPEC_O3', 'NOISE_HISTOGRAM', 'RATE6', 'PULSER_BITS',$
           'PULSER_DELAY_CLOCK_CYCLES', 'SCI_MODE_BITS', 'SCI_RESOLUTION', 'SCI_TRANSLATE']
ifc_var_ref = ['L0b', 'L0b', 'L1a', 'L1a', 'L1a', 'L0b',$
               'L0b', 'L0b', 'L0b', 'L0b']

ifc_user_09 = [130, 113, 114, 116]
lpt_user_09 = [98, 17, 81, 67, 33, 49, 177, 193, 209, 225, 145, 161]
rxnwheel_user_09 = 135

for i=0, n_elements(LPT_days) - 1 do begin

    ; get one day of data:
    lpt_day_i = LPT_days[i]
    print, 'For LPT on ', lpt_day_i
    timespan, lpt_day_i, 1

    ; Get STIS data - full res
    swfo_stis_load, /l1b, no_update=1, no_download=1

    ; Get User09 - this will give the exact index when LPT begins,
    ; allowing determination of instrument health before (/after?)
    get_data, tcheck_struct + '_USER_09', data=user09dat

    user_09 = user09dat.y
    t_unix = user09dat.x
    test_in_progress = where((user_09 ne 1) and (user09dat.x gt mission_start_unix), n_test)

    if n_test eq 0 then begin
        print, 'No test at ' + lpt_day_i + ', continuing to next.'
        continue
    endif

    test_continuity = test_in_progress[1:*] - test_in_progress[0:-1]
    index_diff_test = where(test_continuity ne 1, nscript_changes)
    ; include the first mode:
    nscript_changes = nscript_changes + 1

    ; Since there are tests, get L0b and L1a arrays:
    get_data, 'swfo_stis_L1a_SPEC_O1', ptr=ptr
    l1a_ddata = ptr.ddata
    l1a_arr = l1a_ddata.array

    start_index = [test_in_progress[0], test_in_progress[index_diff_test + 1]]
    end_index = [test_in_progress[index_diff_test], test_in_progress[-1]]

    for j=0, nscript_changes - 1 do begin
        start_index_j = start_index[j]
        end_index_j = end_index[j]
        ; Get time of start/end of test, user_09:
        trange_in_test = [user09dat.x[start_index_j], user09dat.x[end_index_j]]
        user_09_j = user_09[start_index_j:end_index_j]
        t_j = t_unix[start_index_j:end_index_j]

        print, 'Analyzing non-routine USER_09 at ', time_string(trange_in_test)

        ; Health parameters check:
        if eval_instrument_health then swfo_stis_health_check, trange_in_test,$
          struct_name=health_struct, save_dir=save_dir, make_plot=make_health_plot


        ; Now, time to show IFC.
        if user_09[start_index_j] eq ifc_user_09[0] then begin

            ifc_last_script = where(user_09_j eq ifc_user_09[-1])
            end_ifc_index = ifc_last_script[-1]
            end_ifc_unix = t_j[end_ifc_index]

            ; Make tplot of the housekeeping for nominal statuses:
            tplot, 'swfo_stis_' + ifc_var_ref +'_' + ifc_var
            tlimit, [trange_in_test[0], end_ifc_unix]
            ; write_png, save_dir + 'stis_ifc_' + tstring_start+ '.png', tvrd(/true)

            stis_threshold_analysis, /log




            stop

        endif

    endfor
    swfo_apdat_info, /re





endfor


end