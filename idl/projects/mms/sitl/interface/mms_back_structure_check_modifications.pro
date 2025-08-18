; This validation routine will ONLY look at modified burst segments from the original burst
; segment status table. A separate routine will validate new segments.
;
; Assumes new_backstr.start and new_backstr.start are both in TAI time.

pro mms_back_structure_check_modifications, new_backstr, old_backstr, mod_error_flags, mod_yellow_warning_flags, mod_orange_warning_flags, $
                                            mod_error_msg, mod_yellow_warning_msg, mod_orange_warning_msg, $
                                            mod_error_times, mod_yellow_warning_times, mod_orange_warning_times, $
                                            mod_error_indices, mod_yellow_warning_indices, mod_orange_warning_indices, $
                                            valstruct=valstruct

;--------------------------------------------------------------------------------------
; Define parameters that lead to errors and warnings
if n_elements(valstruct) eq 0 then valstruct = mms_load_fom_validation()
fom_gmax = valstruct.fom_gmax
fom_bounds = valstruct.fom_bounds
seg_bounds = valstruct.seg_bounds
buff_max = valstruct.buff_max
p1_percent = valstruct.p1_percent
nominal_seg_range = valstruct.nominal_seg_range
type1_range = valstruct.type1_range
type2_range = valstruct.type2_range
type3_range = valstruct.type3_range
type4_range = valstruct.type4_range
fom_del_max = valstruct.fom_del_max
fom_mod_percent = valstruct.fom_mod_percent

fom_percent = floor(fom_mod_percent*100)

fom_min_str = strtrim(string(fom_bounds(0)), 2)
fom_max_str = strtrim(string(fom_bounds(1)), 2)
fom_gmax_str = strtrim(string(fom_gmax), 2)
buff_max_str = strtrim(string(buff_max), 2)
seg_min_str = strtrim(string(seg_bounds(0)), 2)
seg_max_str = strtrim(string(seg_bounds(1)), 2)
nom_seg_min_str = strtrim(string(nominal_seg_range(0)), 2)
nom_seg_max_str = strtrim(string(nominal_seg_range(1)), 2)
fom_percent_str = strtrim(string(fom_percent), 2)
fom_del_max_str = strtrim(string(fom_del_max), 2)
;--------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------
; Split the backstructure into two parts:
; orig_segs: This is original segments that are contained in old_backstr, with flags
;            input by the user to determine how those segments were modified.
;            These will be checked by the code, with special attention to how they
;            compare to the original structure (old_backstr)
;
; new_segs: These are new burst segments created by the user, and will be marked with
;           new_backstr.datasegmentid = 1. These will be checked for the same basic
;           errors/warnings that are appled to new 'fomstr' variables in EVA.
;--------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------
; Validate deletes
;--------------------------------------------------------------------------------------

loc_delete = where(new_backstr.datasegmentid gt 0 and $
                   new_backstr.changestatus eq 2, del_count)

count_del_warnings = 0
loc_del_warning = -1

if del_count gt 0 then begin
  old_fom_deleted = old_backstr.fom(loc_delete)
  
  loc_del_warning_temp = where(old_fom_deleted gt fom_del_max, count_del_warnings)
  
  if count_del_warnings gt 0 then loc_del_warning = loc_delete(loc_del_warning_temp)
  
endif

;--------------------------------------------------------------------------------------
; Validate modifications
;--------------------------------------------------------------------------------------

loc_mod = where(new_backstr.datasegmentid gt 0 and $
                new_backstr.changestatus eq 1, mod_count)
                
count_mod_percent = 0
count_fom_errors = 0
loc_mod_percent = -1
loc_fom_error = -1

; Identify errors and warnings

if mod_count gt 0 then begin
  old_fom_mod = old_backstr.fom(loc_mod)
  new_fom_mod = new_backstr.fom(loc_mod)
  
  old_fom_thresh = fom_mod_percent*old_fom_mod
  fom_diff = abs(old_fom_mod - new_fom_mod)/old_fom_mod
  
  loc_mod_percent_temp = where(fom_diff gt fom_mod_percent, count_mod_percent)
  if count_mod_percent gt 0 then loc_mod_percent = loc_mod(loc_mod_percent_temp)
  
  loc_fom_error_temp = where(new_fom_mod gt fom_bounds(1) or new_fom_mod lt fom_bounds(0), count_fom_errors)
  if count_fom_errors gt 0 then loc_fom_error = loc_mod(loc_fom_error_temp)
endif

;-----------------------------------------------------------------------------------
; Create the appropriate variables with flags and output
;-----------------------------------------------------------------------------------

; First do the errors for modified segments
mod_error_flags = 0
mod_error_times = ptrarr(n_elements(mod_error_flags), /allocate_heap)
mod_error_indices = ptrarr(n_elements(mod_error_flags), /allocate_heap)

fom_error_txt = 'ERROR: FOM value at following times out of bounds (' + fom_min_str + $
  ' to ' + fom_max_str + '): '

if count_fom_errors gt 0 then begin
   fom_error_times = strarr(count_fom_errors)
   for c=0,count_fom_errors-1 do begin
    ; ALERT - need to change this!!!
    create_time_strings, new_backstr.start[loc_fom_error[c]], stemp
    fom_error_times[c] = stemp
   endfor
endif else begin
   fom_error_times = ''
endelse

mod_error_msg = fom_error_txt
mod_error_flags = count_fom_errors gt 0
*(mod_error_times[0]) = fom_error_times
*(mod_error_indices[0]) = loc_fom_error

; Now we will deal for the yellow warnings
mod_yellow_warning_flags = intarr(2)
mod_yellow_warning_times = ptrarr(n_elements(mod_yellow_warning_flags), /allocate_heap)
mod_yellow_warning_indices = ptrarr(n_elements(mod_yellow_warning_flags), /allocate_heap)

delete_warning_text = 'WARNING: The segments at the following times with FOM greater than ' + fom_del_max_str + ' have been deleted: '
mod_warning_text = 'WARNING: The segments at the following times have a modified FOM value which differs from the original value by more than ' + $
                    fom_percent_str + ' percent: '
                    
if count_del_warnings gt 0 then begin
  del_warning_times = strarr(count_del_warnings)  
  cmax = n_elements(loc_del_warning)
  for c=0,cmax-1 do begin
    create_time_strings, new_backstr.start[loc_del_warning[c-1]], stemp
    del_warning_times[c-1] = stemp
  endfor
endif else begin
  del_warning_times = ''
endelse

if count_mod_percent gt 0 then begin
  mod_percent_times = strarr(count_mod_percent)
  for c=0,count_mod_percent-1 do begin
    create_time_strings, new_backstr.start[loc_mod_percent[c]], stemp
    mod_percent_times[c] = stemp
  endfor
endif else begin
  mod_percent_times = ''
endelse

mod_yellow_warning_flags = [count_del_warnings gt 0, $
                    count_mod_percent gt 0]
mod_yellow_warning_msg = [delete_warning_text, $
                   mod_warning_text]
*(mod_yellow_warning_times[0]) = del_warning_times
*(mod_yellow_warning_times[1]) = mod_percent_times
*(mod_yellow_warning_indices[0]) = loc_del_warning
*(mod_yellow_warning_indices[1]) = loc_mod_percent

; Now we will deal for the orange warnings
mod_orange_warning_flags = intarr(1)
mod_orange_warning_times = ptrarr(n_elements(mod_orange_warning_flags), /allocate_heap)
mod_orange_warning_indices = ptrarr(n_elements(mod_orange_warning_flags), /allocate_heap)
mod_orange_warning_msg = strarr(n_elements(mod_orange_warning_flags))

end 