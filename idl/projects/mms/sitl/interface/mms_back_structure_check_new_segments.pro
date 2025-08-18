; This one checks new segments the user is attempting to add to the backstructure.
; It makes the same checks as one would make for new fom structure elements.


pro mms_back_structure_check_new_segments, new_backstr, new_segs, new_error_flags, orange_warning_flags, $
  yellow_warning_flags, new_error_msg, orange_warning_msg, yellow_warning_msg, $
  new_error_times, orange_warning_times, yellow_warning_times, $
  new_error_indices, orange_warning_indices, yellow_warning_indices, $
  valstruct=valstruct

;--------------------------------------------------------------------------------------
; Define parameters that lead to errors and warnings
on_error, 2
if n_elements(valstruct) eq 0 then valstruct = mms_load_fom_validation()

if typename(valstruct) eq 'INT' then message, 'ERROR: Unable to load FOM validation parameters ' + $
  'from SDC. Check your internet connection.'

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
high_fom_val = 150

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

high_fom_str = strtrim(string(high_fom_val), 2)

;--------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------
; Split the backstructure into two parts:
; orig_segs: This is original segments that are contained in old_backstr, with flags
;            input by the user to determine how those segments were modified.
;            These are checked by the code 'mms_back_structure_check_modifications'.
;
; new_segs: These are new burst segments created by the user, and will be marked with
;           new_backstr.datasegmentid = 1. These will be checked for the same basic
;           errors/warnings that are appled to new 'fomstr' variables in EVA. The
;           checking will be implemented in this code.
;--------------------------------------------------------------------------------------

loc_new = where(new_backstr.datasegmentid lt 0, count_new)

if count_new gt 0 then begin

  new_foms = new_backstr.fom(loc_new)
  new_seglengths = new_backstr.seglengths(loc_new)
  new_starts = new_backstr.start(loc_new)
  new_stops = new_backstr.stop(loc_new)
  
  ;--------------------------------------------------------------------------------------
  ; Lets do errors first
  ;--------------------------------------------------------------------------------------
  
  loc_fom_error_temp = where(new_foms lt fom_bounds(0) or new_foms gt fom_bounds(1), count_fom_error)
  loc_seg_error_temp = where(new_seglengths lt seg_bounds(0) or new_seglengths gt seg_bounds(1), $
                             count_seg_error)
  loc_start_error_temp = where(new_starts gt new_stops, count_start_error)
  
  new_error_flags = [count_fom_error gt 0, $
                     count_seg_error gt 0, $
                     count_start_error gt 0]
  
  loc_fom_error = -1
  loc_seg_error = -1
  loc_start_error = -1
  new_error_indices = ptrarr(n_elements(new_error_flags), /allocate_heap)
  new_error_times = ptrarr(n_elements(new_error_flags), /allocate_heap)
  
  if count_fom_error gt 0 then loc_fom_error = loc_new(loc_fom_error_temp)
  if count_seg_error gt 0 then loc_seg_error = loc_new(loc_seg_error_temp)
  if count_start_error gt 0 then loc_start_error = loc_new(loc_start_error_temp)
  
  fom_error_txt = 'ERROR: FOM value at following times out of bounds (' + fom_min_str + $
                  ' to ' + fom_max_str + '): '
  seg_error_txt = 'ERROR: Segment lengths at following times out of bounds (' + $
                  seg_min_str + ' to ' + seg_max_str + '): '
  start_error_txt = 'ERROR: Start time must be less than stop time for following selections: '
                 
  
  if count_fom_error gt 0 then begin
    fom_error_times = strarr(count_fom_error)
    for c=0, count_fom_error-1 do begin
      create_time_strings, new_backstr.start[loc_fom_error[c]], stemp
      fom_error_times[c] = stemp
    endfor
  endif else begin
    fom_error_times = ''
  endelse
  
  if count_seg_error gt 0 then begin
    seg_error_times = strarr(count_seg_error)
    for c = 0, count_seg_error-1 do begin
      create_time_strings, new_backstr.start[loc_seg_error[c]], stemp
      seg_error_times[c] = stemp
    endfor
  endif else begin
    seg_error_times = ''
  endelse
  
  if count_start_error gt 0 then begin
    start_error_times = strarr(count_start_error)
    for c=0, count_start_error-1 do begin
      create_time_strings, new_backstr.start[loc_start_error[c]], stemp
      start_error_times[c] = stemp
    endfor
  endif else begin
    start_error_times = ''
  endelse
  
  new_error_msg = [fom_error_txt, $
                   seg_error_txt, $
                   start_error_txt]
  
  (*new_error_times[0]) = fom_error_times
  (*new_error_times[1]) = seg_error_times
  (*new_error_times[2]) = start_error_times
  
  (*new_error_indices[0]) = loc_fom_error
  (*new_error_indices[1]) = loc_seg_error
  (*new_error_indices[2]) = loc_start_error
  
  ;--------------------------------------------------------------------------------------
  ; Lets do yellow warnings
  ;--------------------------------------------------------------------------------------
  
  loc_seg_warning_temp = where(new_seglengths lt nominal_seg_range(0) $
    or new_seglengths gt nominal_seg_range(1), $
    count_seg_warning)
    
  ; Now check the number of buffers with priority 1 events
  loc_high_warning_temp = where(new_foms ge 150, count_high_warning)
  
  yellow_warning_flags = [count_seg_warning gt 0, $
                          count_high_warning gt 0]
  
  loc_seg_warning = -1
  loc_high_warning = -1
  yellow_warning_indices = ptrarr(n_elements(yellow_warning_flags), /allocate_heap)
  yellow_warning_times = ptrarr(n_elements(yellow_warning_flags), /allocate_heap)
  
  if count_seg_warning gt 0 then loc_seg_warning = loc_new(loc_seg_warning_temp)
  if count_high_warning gt 0 then loc_high_warning = loc_new(loc_high_warning_temp)
  
  if count_seg_warning gt 0 then begin
    seg_warning_times = strarr(count_seg_warning)
    for c=0,count_seg_warning-1 do begin
      create_time_strings, new_backstr.start[loc_seg_warning[c]], stemp
      seg_warning_times[c] = stemp
    endfor
  endif else begin
    seg_warning_times = ''
  endelse
  
  if count_high_warning gt 0 then begin
    high_warning_times = strarr(count_high_warning)
    for c=0,count_high_warning-1 do begin
      create_time_strings, new_backstr.start[loc_high_warning[c]], stemp
      high_warning_times[c] = stemp
    endfor
  endif else begin
    high_warning_times = ''
  endelse
  
  seg_warning_txt = 'Warning: Segment lengths at following times out of bounds (' + $
    nom_seg_min_str + ' to ' + nom_seg_max_str + '): '
  high_warning_txt = 'Warning: The following segments have FOM greater than ' + high_fom_str + $
    ', please justify: '
  
  yellow_warning_msg = [seg_warning_txt, $
                        high_warning_txt]
                        
  (*yellow_warning_times[0]) = seg_warning_times
  (*yellow_warning_times[1]) = high_warning_times
  
  (*yellow_warning_indices[0]) = loc_seg_warning
  (*yellow_warning_indices[1]) = loc_high_warning
  
  ;--------------------------------------------------------------------------------------
  ; Lets do orange warnings
  ;--------------------------------------------------------------------------------------
  
  loc_fom_approve_temp = where(new_foms gt fom_gmax, count_fom_approve)
  ;loc_fom_percentage =
  
  orange_warning_flags = [count_fom_approve gt 0]
  
  loc_fom_approve = -1
  orange_warning_times = ptrarr(n_elements(orange_warning_flags), /allocate_heap)
  orange_warning_indices = ptrarr(n_elements(orange_warning_flags), /allocate_heap)
  
  if count_fom_approve gt 0 then loc_fom_approve = loc_new(loc_fom_approve_temp)
  
  ; Create time array for warnings
  if count_fom_approve gt 0 then begin
    fom_appr_times = strarr(count_fom_approve)
    for c=0,count_fom_approve-1 do begin
      create_time_strings, new_backstr.start[loc_fom_approve[c]], stemp
      fom_appr_times[c] = stemp
    endfor
  endif else begin
    fom_appr_times = ''
  endelse
  
  Appr_msg = 'Submission needs SuperSITL Approval! '
  
  fom_gwarning_txt = Appr_msg + 'FOM value at the following times exceeds recommended value (' + fom_gmax_str + ') and should ' + $
    'be reserved for the highest priority events or FPI calibrations: '
    
  orange_warning_msg = [fom_gwarning_txt]
  
  (*orange_warning_times[0]) = fom_appr_times
  (*orange_warning_indices[0]) = loc_fom_approve
  
  
  new_segs = 1

endif else begin
  new_segs = 0
  
  new_error_flags = [0, 0, 0]
  orange_warning_flags = [0]
  yellow_warning_flags = [0, 0]
  
  new_error_msg = ['','','']
  orange_warning_msg = ['','','']
  yellow_warning_msg = ['','','']
  
  new_error_indices = ptrarr(n_elements(new_error_flags), /allocate_heap)
  new_error_times = ptrarr(n_elements(new_error_flags), /allocate_heap)
  yellow_warning_indices = ptrarr(n_elements(yellow_warning_flags), /allocate_heap)
  yellow_warning_times = ptrarr(n_elements(yellow_warning_flags), /allocate_heap)
  orange_warning_times = ptrarr(n_elements(orange_warning_flags), /allocate_heap)
  orange_warning_indices = ptrarr(n_elements(orange_warning_flags), /allocate_heap)

endelse

end