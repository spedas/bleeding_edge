; Seg start and seg stop are TAI time tags

pro mms_check_fpi_calibration_segment, seg_start, seg_stop, fom, sourceid, $
                                       error_flags, error_msg, yellow_warning_flags, $
                                       yellow_warning_msg, orange_warning_flags, orange_warning_msg, $
                                       valstruct=valstruct
on_error, 2                                   
if n_elements(valstruct) eq 0 then valstruct = mms_load_fom_validation()
if typename(valstruct) eq 'INT' then message, 'ERROR: Unable to load FOM validation parameters ' + $
  'from SDC. Check your internet connection.'

fom_fpi_min = valstruct.fom_fpi_min
fpi_seg_bounds = valstruct.fpi_seg_bounds

; Segment length of FPI calibration segment
seglength = (seg_stop-seg_start)/10

seg_min_str = strtrim(string(fpi_seg_bounds(0)), 2)
seg_max_str = strtrim(string(fpi_seg_bounds(1)), 2)
fom_min_str = strtrim(string(fom_fpi_min, 2))


;-------------------------------------------------------------
; Do errors first
;-------------------------------------------------------------

start_error = seg_start gt seg_stop
seglength_error = seglength gt fpi_seg_bounds(1) or seglength lt fpi_seg_bounds(0)

start_error_msg = 'ERROR: Start time must be less than stop time for the selection.'
seglength_error_msg = 'ERROR: Segment length is out of bounds (' + $
  seg_min_str + ' to ' + seg_max_str + ')'
  
error_flags = [start_error, $
               seglength_error]
error_msg = [start_error_msg, $
             seglength_error_msg]
  
;-------------------------------------------------------------
; Yellow warnings
;-------------------------------------------------------------

fom_warning = fom lt fom_fpi_min

fom_warning_msg = 'Warning: FOM for FPI calibration segments should be greater than ' + $
                   fom_min_str + ' in order to prioritize downlink.'
                   
yellow_warning_flags = fom_warning
yellow_warning_msg = fom_warning_msg


;-------------------------------------------------------------
; Orange warnings
;-------------------------------------------------------------

orange_warning_flags = 0
orange_warning_msg = ''

end


