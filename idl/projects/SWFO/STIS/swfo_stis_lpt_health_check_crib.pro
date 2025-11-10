; swfo_stis_lpt_health_check_crib.pro

LPT_times = [['2025/09/30 15:04:32', '2025/09/30 15:58:32'],$
             ['2025/10/07 15:42:13', '2025/10/07 16:36:10']]

; IFC_times

save_dir = '~/'

mission_start = '2025 9 30'
mission_start_unix = time_double(mission_start)

; These aren't all LPTs, but the script will work all the same
LPT_days = ['2025 9 30', '2025 10 7', '2025 10 15']

; Indicate which data struct you want. I used L0b,
; but you can use the hkp packets too.
; note: l0b in science cadence, not hkp cadence
; tplot_prefix = 'pb_swfo_stis_hkp1_'
; tplot_prefix = 'pb_swfo_stis_hkp2_'
; tplot_prefix = 'swfo_stis_hkp1_'
; tplot_prefix = 'swfo_stis_hkp2_'
tplot_prefix = 'swfo_stis_L0b_'

health_hkp_var = ['ADC_BIAS_VOLTAGE', 'TEMP_DAP', 'VOLTAGE_1P5_VD',$
                  'VOLTAGE_3P3_VD', 'VOLTAGE_5P0_VD', 'VOLTAGE_DFE_POS_VA',$
                  'VOLTAGE_DFE_NEG_VA', 'BIAS_CURRENT_MICROAMPS', 'TEMP_SENSOR1', 'TEMP_SENSOR2',$
                  'FPGA_REV']


for i=0, n_elements(LPT_days) - 1 do begin

    ; get one day of data:
    lpt_day_i = LPT_days[i]
    print, 'For LPT on ', lpt_day_i
    timespan, lpt_day_i, 1

    ; Get STIS data - full res
    swfo_stis_load

    ; Make tplot of the housekeeping for nominal statuses:
    tplot, tplot_prefix + health_hkp_var

    ; Get User09 - this will give the exact index when LPT begins,
    ; allowing determination of instrument health before (/after?)
    get_data, tplot_prefix + 'USER_09', data=user09dat, ptr=ptr
    ddata = ptr.ddata
    user_09 = user09dat.y
    test_in_progress = where((user_09 ne 1) and (user09dat.x gt mission_start_unix), n_test)

    if n_test eq 0 then begin
        print, 'No test at ' + lpt_day_i + ', continuing to next.'
        continue
    endif
    test_continuity = test_in_progress[1:*] - test_in_progress[0:-1]
    index_diff_test = where(test_continuity ne 1, nscript_changes)
    ; include the first mode:
    nscript_changes = nscript_changes + 1

    start_index = [test_in_progress[0], test_in_progress[index_diff_test + 1]]
    end_index = [test_in_progress[index_diff_test], test_in_progress[-1]]

    for j=0, nscript_changes - 1 do begin
        start_index_j = start_index[j]
        end_index_j = end_index[j]
        trange_in_test = [user09dat.x[start_index_j], user09dat.x[end_index_j]]
        pre_test_trange = [trange_in_test[0] - 60, trange_in_test[0] - 2]
        post_test_trange = [trange_in_test[1] + 2, trange_in_test[1] + 60]
        print, 'Analyzing non-routine USER_09 at ', time_string(trange_in_test)
        ; get all info
        ; BEFORE test
        print, 'BEFORE TEST:'
        dda_in_range = ddata.sample(range=pre_test_trange, tagname='TIME_UNIX')
        avg_dda = average(dda_in_range, /nan)
        ; now, evaluate the health of the parameters before, during, after
        ; get the struct:
        if isa(avg_dda) then begin
            for var_i=0, n_elements(health_hkp_var) - 1 do begin
                str_element, avg_dda, health_hkp_var[var_i], v
                print, 'AVG ' + health_hkp_var[var_i] + ' before test: ', v
            endfor
        endif

        print, 'DURING TEST:'
        dda_in_range = ddata.sample(range=trange_in_test, tagname='TIME_UNIX')
        avg_dda = average(dda_in_range, /nan)
        if isa(avg_dda) then begin
            ; now, evaluate the health of the parameters before, during, after
            ; get the struct:
            for var_i=0, n_elements(health_hkp_var) - 1 do begin
                str_element, avg_dda, health_hkp_var[var_i], v
                print, 'AVG ' + health_hkp_var[var_i] + ' during test: ', v
            endfor
        endif

        print, 'AFTER TEST:'
        dda_in_range = ddata.sample(range=post_test_trange, tagname='TIME_UNIX')
        avg_dda = average(dda_in_range, /nan)
        ; now, evaluate the health of the parameters before, during, after
        ; get the struct:
        for var_i=0, n_elements(health_hkp_var) - 1 do begin
            str_element, avg_dda, health_hkp_var[var_i], v
            print, 'AVG ' + health_hkp_var[var_i] + ' after test: ', v
        endfor


        tlimit, [pre_test_trange[0], post_test_trange[1]]
        write_png, save_dir + 'stis_health_' + time_string(trange_in_test[0], tformat="YYYYMMDDhhmmss") + '.png', tvrd(/true)
        ; stop

    endfor





endfor


end