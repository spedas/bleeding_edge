pro mms_submit_fpi_calibration_segment, seg_start, seg_stop, fom, sourceid, $
  error_flags, error_msg, yellow_warning_flags, $
  yellow_warning_msg, orange_warning_flags, orange_warning_msg, problem_status, warning_override=warning_override

mms_check_fpi_calibration_segment, seg_start, seg_stop, fom, sourceid, $
  error_flags, error_msg, yellow_warning_flags, $
  yellow_warning_msg, orange_warning_flags, orange_warning_msg
  
loc_yellow = where(yellow_warning_flags eq 1, count_yellow)
loc_orange = where(orange_warning_flags eq 1, count_orange)
loc_error = where(error_flags eq 1, count_error)

if count_error eq 0 then begin
  if ((count_yellow eq 0) and (count_orange eq 0)) or keyword_set(warning_override) then begin
    seed_segment = {id: '0', $
                    datasegmentid: -1, $
                    starttime: seg_start, $
                    endtime: seg_stop, $
                    fom: fom, $
                    status: 'NEW', $
                    source: sourceid, $
                    observatoryid: 'ALL'}
    
    temptime = systime(/utc)
    mostr = strmid(temptime, 4, 3)
    monew = ''
    case mostr of
      'Jan': monew = '01'
      'Feb': monew = '02'
      'Mar': monew = '03'
      'Apr': monew = '04'
      'May': monew = '05'
      'Jun': monew = '06'
      'Jul': monew = '07'
      'Aug': monew = '08'
      'Sep': monew = '09'
      'Oct': monew = '10'
      'Nov': monew = '11'
      'Dec': monew = '12'
    endcase

    daystr = strmid(temptime, 8, 2)
    hrstr = strmid(temptime, 11, 2)
    minstr = strmid(temptime, 14, 2)
    secstr = strmid(temptime, 17, 2)
    yearstr = strmid(temptime, 20, 4)

    day_val = fix(daystr)

    if day_val lt 10 then begin
      daystr = '0'+string(day_val, format = '(I1)')
    endif else begin
      daystr = string(day_val, format = '(I2)')
    endelse

;    lastpos = strlen(local_dir)
;    if strmid(local_dir, lastpos-1, lastpos) eq path_sep() then begin
;      data_dir = local_dir + 'data' + path_sep() + 'mms' + path_sep()
;    endif else begin
;      data_dir = local_dir + path_sep() + 'data' + path_sep() + 'mms' + path_sep()
;    endelse

    temp_dir = !MMS.LOCAL_DATA_DIR
    spawnstring = 'echo ' + temp_dir
    spawn, spawnstring, data_dir
    
    temptime = systime(/utc)

    ;dir_path = data_dir + 'sitl/fpi_cal_segments/' + yearstr + '/'
    
    dir_path = filepath('', root_dir=data_dir, $
      subdirectory = ['sitl', 'fpi_cal_segments', yearstr])

    file_mkdir, dir_path

    savefile = dir_path + 'bdm_sitl_changes_' + yearstr + '-' + monew + $
      '-' + daystr + '-' + hrstr + '-' + minstr + '-' + secstr + '.sav'

    fomstr = seed_segment
    save, file = savefile, fomstr

    sub_status = submit_mms_sitl_selections(savefile)
    print, sub_status

    if sub_status eq 0 then begin
      problem_status = 0
      print, 'file submitted successfully: ' + savefile
    endif else begin
      problem_status = 2
    endelse
    
  endif else begin
    ; There are warnings
    problem_status = 1
  endelse
  
endif else begin
  ; There are errors
  problem_status = 1
endelse

  
end