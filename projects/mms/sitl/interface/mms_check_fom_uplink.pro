pro mms_check_fom_uplink, tai_fomstr, sroi_structure, error_flags, error_indices, error_msg, error_times

; Now we check whether the structure falls within a sub_roi
sroi_starts_tai = mms_unix2tai(time_double(sroi_structure.starts))
sroi_stops_tai = mms_unix2tai(time_double(sroi_structure.stops))

roi_check = -1 ; tells me which ROI index is bad
for i = 0, n_elements(sroi_starts_tai)-1 do begin
  if tai_fomstr.evalstarttime ge sroi_starts_tai[i] and tai_fomstr.evalstarttime le sroi_stops_tai[i] then begin
    roi_check += 1
  endif
endfor

; Finally, we check to make sure there are no selections after the designated close
; real_stops = tai_fomstr.cyclestart + tai_fomstr.stop
; real_starts = tai_fomstr.cyclestart + tai_fomstr.start
real_stops = tai_fomstr.timestamps[tai_fomstr.stop] + 10.d0
real_starts = tai_fomstr.timestamps[tai_fomstr.start]
oob_loc = where(real_stops ge tai_fomstr.evalstarttime, count_oob)
roi_before_loc = where(sroi_stops_tai lt tai_fomstr.evalstarttime, count_before)

if count_oob gt 0 then begin
  oob_warning_times = strarr(count_oob)
  convert_time_stamp, tai_fomstr.cyclestart, tai_fomstr.start[oob_loc], oob_warning_times
endif else begin
  oob_warning_times = ''
endelse

empty_roi = 0
;if count_before gt 0 then begin
;  for i = 0, count_before-1 do begin
;    loc_select = where(real_starts ge sroi_starts_tai[roi_before_loc[i]] $
;      and real_stops le sroi_stops_tai[roi_before_loc[i]], count_select)
;    if count_select eq 0 then empty_roi += 1
;  endfor
;endif


;-----------------------------------------------------------------------------
; Define output arrays
;-----------------------------------------------------------------------------
 
error_flags = [roi_check ge 0, $
               count_oob gt 0, $
               empty_roi gt 0]
               
error_indices = ptrarr(n_elements(error_flags), /allocate_heap)
error_times = ptrarr(n_elements(error_flags), /allocate_heap)
error_msg = strarr(n_elements(error_flags))

oob_times = tai_fomstr.start[oob_loc]

(*error_indices[0]) = !values.f_nan
(*error_indices[1]) = oob_times
(*error_indices[2]) = !values.f_nan

(*error_times[0]) = 'Window-wide error, no times'
(*error_times[1]) = oob_warning_times
(*error_times[2]) = 'Window-wide error, no times'

error_msg = ['ERROR, close time may not be within a sub-ROI', $
             'ERROR, selections at the following time stamps are after the close time, which is not allowed: ', $
             'WARNING, close time includes a SROI with no selections']

end