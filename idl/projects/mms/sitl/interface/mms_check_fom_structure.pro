; The purpose of this program is to check the FOM structure to make sure that
; it is within acceptable boundaries for submission to the SOC.
; Additionally, we will provide warnings to the user when the FOM values or
; number of buffers starts to reach "unusually large" values, as defined
; by the error tables within this program.

; The errors and warnings will be reported in two ways: a flags array and
; a warnings array, each of which will have the same number of elements.
; Each element of these arrays will correspond to a different test in
; the warning/error tables. The 'flags' array will have either a value of '0' 
; (passed) or '1' (failed), where 'failed" implies there is an error. This
; will be for internal use within EVA. The 'messages' array will contain a
; corresponding error message for each element of the flags array, allowing
; ease of use within EVA to print the messages for the user.

; We need a series of errors and warnings
; I'll make a structure which includes different error classes
; the elements of each sub-array will be the indices of the FOM_str
; where we have errors.

; ---------------------------------------
; ERRORS
; 
; Seg_size                                                                                                                                                                                              
; 
; 
;----------------------------------------


pro mms_check_fom_structure, new_fomstr, old_fomstr, error_flags, orange_warning_flags, $
                             yellow_warning_flags, error_msg, orange_warning_msg, yellow_warning_msg, $
                             error_times, orange_warning_times, yellow_warning_times, $
                             error_indices, orange_warning_indices, yellow_warning_indices, $
                             valstruct=valstruct
 

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

fom_min_str = strtrim(string(fom_bounds(0)), 2)
fom_max_str = strtrim(string(fom_bounds(1)), 2)
fom_gmax_str = strtrim(string(fom_gmax), 2)
buff_max_str = strtrim(string(buff_max), 2)
seg_min_str = strtrim(string(seg_bounds(0)), 2)
seg_max_str = strtrim(string(seg_bounds(1)), 2)
nom_seg_min_str = strtrim(string(nominal_seg_range(0)), 2)
nom_seg_max_str = strtrim(string(nominal_seg_range(1)), 2)

;----------------------------------------------------------------------------
; Define error arrays
;----------------------------------------------------------------------------

old_evaltime = old_fomstr.metadataevaltime
new_evaltime = new_fomstr.metadataevaltime

loc_fom_error = where(new_fomstr.fom lt fom_bounds(0) or new_fomstr.fom gt fom_bounds(1), count_fom_error)
loc_seg_error = where(new_fomstr.seglengths lt seg_bounds(0) or new_fomstr.seglengths gt seg_bounds(1), $
                      count_seg_error)
loc_start_error = where(new_fomstr.start gt new_fomstr.stop, count_start_error)

error_flags = [count_fom_error gt 0, $
               count_seg_error gt 0, $
               count_start_error gt 0] ;, $
;               new_evaltime ne old_evaltime]
               
error_times = ptrarr(n_elements(error_flags), /allocate_heap)
error_indices = ptrarr(n_elements(error_flags), /allocate_heap)
               
; Generate strings that represent the errors
; First, we need to get the appropriate times

if count_fom_error gt 0 then begin
  fom_error_times = strarr(count_fom_error)
  convert_time_stamp, new_fomstr.cyclestart, new_fomstr.start(loc_fom_error), fom_error_times
endif else begin
  fom_error_times = ''
endelse

if count_seg_error gt 0 then begin
  seg_error_times = strarr(count_seg_error)
  convert_time_stamp, new_fomstr.cyclestart, new_fomstr.start(loc_seg_error), seg_error_times
endif else begin
  seg_error_times = ''
endelse

if count_start_error gt 0 then begin
  start_error_times = strarr(count_start_error)
  convert_time_stamp, new_fomstr.cyclestart, new_fomstr.start(loc_start_error), start_error_times
endif else begin
  start_error_times = ''
endelse

; Now we create the warnings that will actually be output
fom_error_txt = 'ERROR: FOM value at following times out of bounds (' + fom_min_str + $
                ' to ' + fom_max_str + '): '

seg_error_txt = 'ERROR: Segment lengths at following times out of bounds (' + $
  seg_min_str + ' to ' + seg_max_str + '): '

start_error_txt = 'ERROR: Start time must be less than stop time for following selections: '

eval_error_txt = 'ERROR: The evaluation times for the automated system and SITL selections do not match!'
               
error_msg = [fom_error_txt, $
              seg_error_txt, $
              start_error_txt];, $
             ; eval_error_txt]


; Provides a list of time strings, as well as array indices for the fomstr.start where errors were found
*(error_times[0]) = fom_error_times
*(error_times[1]) = seg_error_times
*(error_times[2]) = start_error_times
;*(error_times[3]) = 'Orbit-wide error - no error times'

*(error_indices[0]) = loc_fom_error
*(error_indices[1]) = loc_seg_error
*(error_indices[2]) = loc_start_error
;*(error_indices[3]) = loc_start_error



;------------------------------------------------------------------------------
; Define orange warning arrays
;------------------------------------------------------------------------------

loc_fom_approve = where(new_fomstr.fom gt fom_gmax, count_fom_appr)
;loc_fom_percentage = 

orange_warning_flags = [count_fom_appr gt 0, $
                        total(new_fomstr.seglengths) gt buff_max]

orange_warning_times = ptrarr(n_elements(orange_warning_flags), /allocate_heap)
orange_warning_indices = ptrarr(n_elements(orange_warning_flags), /allocate_heap)

; Create time array for warnings
if count_fom_appr gt 0 then begin
  fom_appr_times = strarr(count_fom_appr)
  convert_time_stamp, new_fomstr.cyclestart, new_fomstr.start(loc_fom_approve), fom_appr_times
endif else begin
  fom_appr_times = ''
endelse

Appr_msg = 'Submission needs SuperSITL Approval! '

fom_gwarning_txt = Appr_msg + 'FOM value at the following times exceeds recommended value (' + fom_gmax_str + ') and should ' + $
  'be reserved for the highest priority events or FPI calibrations: '

buff_warning_txt = Appr_msg + 'Number of buffers exceeds maximum (' + buff_max_str + ')!'


orange_warning_msg = [fom_gwarning_txt, $
                      buff_warning_txt]

(*orange_warning_times[0]) = fom_appr_times
(*orange_warning_times[1]) = 'Orbit-wide error - no error times'

(*orange_warning_indices[0]) = loc_fom_approve
(*orange_warning_indices[1]) = !values.f_nan
                
;-----------------------------------------------------------------------------
; Define yellow warnings
;-----------------------------------------------------------------------------

; Note - also makes sure segment isn't already in error.

loc_seg_warning = where((new_fomstr.seglengths lt nominal_seg_range(0) $
  or new_fomstr.seglengths gt nominal_seg_range(1)) and $
  (new_fomstr.seglengths ge seg_bounds(0) and new_fomstr.seglengths le seg_bounds(1)), $
  count_seg_warning)
  
; Now check the number of buffers with priority 1 events
loc_p1 = where(new_fomstr.fom ge type1_range(0) and new_fomstr.fom lt type1_range(1), count_p1)

if count_p1 gt 0 then begin
  num_p1_buffs = total(new_fomstr.seglengths(loc_p1))
endif else begin
  num_p1_buffs = 0
endelse

; Create time array for warnings
if count_seg_warning gt 0 then begin
  seg_warning_times = strarr(count_seg_warning)
  convert_time_stamp, new_fomstr.cyclestart, new_fomstr.start(loc_seg_warning), seg_warning_times
endif else begin
  seg_warning_times = ''
endelse

seg_warning_text = 'Warning - segment lengths outside of nominal bounds (' + $
                    nom_seg_min_str + ' to ' + nom_seg_max_str + $
                    ') at the following time_stamps, requires justification: '

p1_warning_text = 'Warning - number of buffers with priority 1 events larger than nominal. Priority 1 events are reserved for ' + $
                  'the events most likely to be diffusion region crossings. This selection requires justification!'
               
yellow_warning_flags = [count_seg_warning gt 0, $
                        num_p1_buffs/buff_max gt p1_percent/100.]
                        
yellow_warning_times = ptrarr(n_elements(yellow_warning_flags), /allocate_heap)
yellow_warning_indices = ptrarr(n_elements(yellow_warning_flags), /allocate_heap)


yellow_warning_msg = [seg_warning_text, $
                       p1_warning_text]
                       
; Now we are going to pass this into our new submit fom structure - it should get rejected
(*yellow_warning_times[0]) = seg_warning_times
(*yellow_warning_times[1]) = 'Orbit-wide warning - no warning times'

(*yellow_warning_indices[0]) = loc_seg_warning
(*yellow_warning_indices[1]) = !values.f_nan; Orbit wide warning, no warning times

end

