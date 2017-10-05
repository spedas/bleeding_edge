pro mms_put_back_structure, new_backstr, old_backstr, $
                            mod_error_flags, mod_yellow_warning_flags, mod_orange_warning_flags, $
                            mod_error_msg, mod_yellow_warning_msg, mod_orange_warning_msg, $
                            mod_error_times, mod_yellow_warning_times, mod_orange_warning_times, $
                            mod_error_indices, mod_yellow_warning_indices, mod_orange_warning_indices, $
                            new_segs, new_error_flags, orange_warning_flags, $
                            yellow_warning_flags, new_error_msg, orange_warning_msg, yellow_warning_msg, $
                            new_error_times, orange_warning_times, yellow_warning_times, $
                            new_error_indices, orange_warning_indices, yellow_warning_indices, $
                            problem_status, warning_override = warning_override


; First we need to check the backstructure for errors and warnings

mms_back_structure_check_modifications, new_backstr, old_backstr, mod_error_flags, mod_yellow_warning_flags, mod_orange_warning_flags, $
                                        mod_error_msg, mod_yellow_warning_msg, mod_orange_warning_msg, $
                                        mod_error_times, mod_yellow_warning_times, mod_orange_warning_times, $
                                        mod_error_indices, mod_yellow_warning_indices, mod_orange_warning_indices
                                       
mms_back_structure_check_new_segments, new_backstr, new_segs, new_error_flags, orange_warning_flags, $
                                       yellow_warning_flags, new_error_msg, orange_warning_msg, yellow_warning_msg, $
                                       new_error_times, orange_warning_times, yellow_warning_times, $
                                       new_error_indices, orange_warning_indices, yellow_warning_indices



loc_mod_errors = where(mod_error_flags gt 0, count_mod_errors)
loc_mod_yellow_warnings = where(mod_yellow_warning_flags gt 0, count_mod_yellow_warnings)
loc_mod_orange_warnings = where(mod_orange_warning_flags gt 0, count_mod_orange_warnings)
loc_new_errors = where(new_error_flags gt 0, count_new_errors)
loc_orange_warnings = where(orange_warning_flags gt 0, count_orange)
loc_yellow_warnings = where(yellow_warning_flags gt 0, count_yellow)

; If statement to determine if we are ready submit

if count_mod_errors eq 0 and count_new_errors eq 0 then begin

  if ((count_mod_yellow_warnings eq 0) and (count_mod_orange_warnings eq 0) and $
    (count_orange eq 0) and (count_yellow eq 0)) or keyword_set(warning_override) then begin

;-------------------------------------------------------------------------------------
; Translate the backstructure into the format necessary to submit to soc
; eventually this will need to be done inside an "if" statement to make sure
; error messages and warnings are either non-existent, or over-ridden
;-------------------------------------------------------------------------------------

   tai_starts = new_backstr.start
   tai_stops = new_backstr.stop
   
   loc_altered = where(new_backstr.changestatus gt 0 or new_backstr.datasegmentid lt 0, count_altered)
   
; Create empty structure
   if count_altered gt 0 then begin
      seed_segment = {id: ' ', $
                      datasegmentid: 0l, $
                      starttime: ulong(0), $
                      endtime: ulong(0), $
                      fom: 0.1, $
                      status: ' ', $
                      source: ' ', $
                      observatoryid: ' ', $
                      discussion: ' '}
                

      sub_segments = REPLICATE(seed_segment, count_altered)
      ids = indgen(n_elements(tai_starts))
      idstring = strtrim(string(ids))
      
      status = strarr(count_altered)
      
      new_change_status = new_backstr.changestatus(loc_altered)
      new_segid = new_backstr.datasegmentid(loc_altered)
      
      loc_mod = where(new_change_status eq 1, count_mod)
      if count_mod gt 0 then status(loc_mod) = 'Modified'
      loc_del = where(new_change_status eq 2, count_del)
      if count_del gt 0 then status(loc_del) = 'Deleted'
      loc_new = where(new_segid lt 0, count_new)
      if count_new gt 0 then status(loc_new) = 'New'

      for i = 0, n_elements(sub_segments)-1 do begin
        sub_segments(i).id = idstring(i)
        sub_segments(i).datasegmentid = new_backstr.datasegmentid(loc_altered(i))
        sub_segments(i).starttime = tai_starts(loc_altered(i))
        sub_segments(i).endtime = tai_stops(loc_altered(i))
        sub_segments(i).fom = new_backstr.fom(loc_altered(i))
        sub_segments(i).status = status(i)
        sub_segments(i).source = new_backstr.sourceid(loc_altered(i))
        sub_segments(i).observatoryid = "ALL"
        sub_segments(i).discussion = new_backstr.discussion(loc_altered(i))
      endfor

;Get the time of sitl submission
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

;        lastpos = strlen(local_dir)
;        if strmid(local_dir, lastpos-1, lastpos) eq path_sep() then begin
;          data_dir = local_dir + 'data' + path_sep() + 'mms' + path_sep()
;        endif else begin
;          data_dir = local_dir + path_sep() + 'data' + path_sep() + 'mms' + path_sep()
;        endelse

      temp_dir = !MMS.LOCAL_DATA_DIR
      spawnstring = 'echo ' + temp_dir
      spawn, spawnstring, data_dir

      temptime = systime(/utc)

      dir_path = filepath('', root_dir=data_dir, $
        subdirectory=['sitl','bdm_sitl_changes',yearstr])

      ;dir_path = data_dir + 'sitl/bdm_sitl_changes/' + yearstr + '/'
      
      file_mkdir, dir_path
      
      savefile = dir_path + 'bdm_sitl_changes_' + yearstr + '-' + monew + $
                 '-' + daystr + '-' + hrstr + '-' + minstr + '-' + secstr + '.sav'

      fomstr = sub_segments
      save, file = savefile, fomstr
      
      sub_status = submit_mms_sitl_selections(savefile)
      print, sub_status
      
      if sub_status eq 0 then begin
        problem_status = 0
        print, 'file submitted successfully: ' + savefile
      endif else begin
        problem_status = 3
      endelse

    endif else begin
      ;Nothing to submit, no changes made to backstructure!
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