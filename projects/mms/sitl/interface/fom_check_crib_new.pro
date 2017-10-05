; This is a crib to demonstrate the FOM check script.
;


;; Set up local_dir where you have FOM data stored
local_dir = '/Users/frederickwilder/'
;
;Grab latest fom structure from SOC
get_latest_fom_from_soc, local_dir, fom_file, error_flag, error_msg

restore, fom_file, /verbose

orig_fom_str = fomstr
tai_fomstr = fomstr

; lets convert the time
mms_convert_fom_tai2unix, tai_fomstr, unix_fomstr, start_string

; lets convert back
mms_convert_fom_unix2tai, unix_fomstr, tai_fomstr2

; Now lets make a tplot variable out of the unix fomstr

fom = fltarr(n_elements(unix_fomstr.mdq))

for i=0,unix_fomstr.nsegs-1 do begin; for each segment
  fom[unix_fomstr.start[i]:unix_fomstr.stop[i]] = unix_fomstr.FOM[i] < 256
endfor

store_data, 'mms_stlm_input_fom',data={x:unix_fomstr.timestamps, y:fom}
options,    'mms_stlm_input_fom','ytitle', 'FOM'
options,    'mms_stlm_input_fom','ysubtitle', 'Auto'
options,    'mms_stlm_input_fom','FOMStr',unix_fomstr; The loaded FOMStr is stored here.
options,    'mms_stlm_input_fom','psym', 10

timespan, start_string, 5*60, /minute
tplot, 'mms_stlm_input_fom'

;Now lets convert back to tai
mms_convert_fom_unix2tai, unix_fomstr, updated_tai_fomstr

;You should notice that orig_fom_str and updated_tai_fomstr are identical!!

; Now lets manipulate the FOM structure to demonstrate the error checking
old_fomstr = unix_fomstr

new_starts = old_fomstr.start
new_stops = old_fomstr.stop
new_foms = old_fomstr.fom
old_seglengths = old_fomstr.seglengths
test_seglengths = (new_stops-new_starts)+1

; Lets create some errors
new_foms(2) = new_foms(2) + 175
new_foms(4) = new_foms(4) + 175
new_foms(6) = new_foms(6) + 300
;new_foms(9) = new_foms(9) + 300

new_seglengths = (new_stops-new_starts) + 1

; Now lets create the new structure

new_fomstr = {valid:            old_fomstr.valid, $
              error:            old_fomstr.error, $
              algversion:       old_fomstr.algversion, $
              sourceid:         old_fomstr.sourceid, $
              cyclestart:       old_fomstr.cyclestart, $
              numcycles:        old_fomstr.numcycles, $
              nsegs:            old_fomstr.nsegs, $
              start:            new_starts, $
              stop:             new_stops, $
              seglengths:       new_seglengths, $
              fom:              new_foms, $
              nbuffs:           total(new_seglengths), $
              mdq:              old_fomstr.mdq, $
              timestamps:       old_fomstr.timestamps, $
              targetbuffs:      old_fomstr.targetbuffs, $
              fomave:           old_fomstr.fomave, $
              targetratio:      old_fomstr.targetratio, $
              minsegmentsize:   old_fomstr.minsegmentsize, $
              maxsegmentsize:   old_fomstr.maxsegmentsize, $
              pad:              old_fomstr.pad, $
              searchratio:      old_fomstr.searchratio, $
              fomwindowsize:    old_fomstr.fomwindowsize, $
              fomslope:         old_fomstr.fomslope, $
              fomskew:          old_fomstr.fomskew, $
              fombias:          old_fomstr.fombias, $
              metadatainfo:     old_fomstr.metadatainfo, $
              oldestavailableburstdata: old_fomstr.oldestavailableburstdata, $
              metadataevaltime: old_fomstr.metadataevaltime}


stop
; convert back to TAI before checking

mms_convert_fom_unix2tai, new_fomstr, new_tai_fomstr
mms_convert_fom_unix2tai, old_fomstr, old_tai_fomstr

mms_check_fom_structure, new_tai_fomstr, old_tai_fomstr, error_flags, orange_warning_flags, $
                         yellow_warning_flags, error_msg, orange_warning_msg, yellow_warning_msg, $
                         error_times, orange_warning_times, yellow_warning_times, $
                         error_indices, orange_warning_indices, yellow_warning_indices
               
;----------------------------------------------------------------------------          
; Now we'll print out error warning messages
;----------------------------------------------------------------------------

print, '-------------------------------------------------------------'
print, 'These are the errors that the program picked up: '
loc_error = where(error_flags ne 0, count_error)
if count_error ne 0 then print, error_msg(loc_error)
print, '-------------------------------------------------------------'
print, ' '

print, '-------------------------------------------------------------'
print, 'These are the orange warnings that the program picked up: '
loc_orange = where(orange_warning_flags ne 0, count_orange)
if count_orange ne 0 then print, orange_warning_msg(loc_orange)
print, '-------------------------------------------------------------'
print, ' '

print, '-------------------------------------------------------------'
print, 'These are the yellow warnings that the program picked up: '
loc_yellow = where(yellow_warning_flags ne 0, count_yellow)
if count_yellow ne 0 then print, yellow_warning_msg(loc_yellow)
print, '-------------------------------------------------------------'
print, ' '

print, '-------------------------------------------------------------'
print, 'Now we will try to submit the file, even though errors are present'
print, '-------------------------------------------------------------'
print, ' '

;----------------------------------------------------------------------------
; Here is a demonstration of how the put_fom_structure routine works
; now that error checking is included.
;----------------------------------------------------------------------------

problem_status = 0

mms_convert_fom_unix2tai, new_fomstr, new_tai_fomstr
mms_convert_fom_unix2tai, old_fomstr, old_tai_fomstr

mms_put_fom_structure, new_tai_fomstr, old_tai_fomstr, local_dir, error_flags, $
                       orange_warning_flags, yellow_warning_flags, $
                       error_msg, orange_warning_msg, yellow_warning_msg, $
                       error_times, orange_warning_times, yellow_warning_times, $
                       error_indices, orange_warning_indices, yellow_warning_indices, $
                       problem_status
                       
; First - lets deal with the errors:

print, '-------------------------------------------------------------'
print, '1st submission in error:'
loc_error = where(error_flags ne 0, count_error)
print, error_msg(loc_error)
print, '-------------------------------------------------------------'
print, ' '

; Now let's fix the errors
loc_high_fom = where(new_fomstr.fom gt 250, count_high)
new_fomstr.fom(loc_high_fom) = 120

loc_large_segs = where(new_fomstr.seglengths gt 50, count_segs)
new_fomstr.stop(loc_large_segs) = new_fomstr.stop(loc_large_segs) + 50 - new_fomstr.seglengths(loc_large_segs) - 1

new_fomstr.seglengths(loc_large_segs) = new_fomstr.stop(loc_large_segs) - new_fomstr.stop(loc_large_segs) + 1

print, '-------------------------------------------------------------'
print, 'Now we will submit again, this time with no errors, but we '
print, 'still expect warnings'
print, '-------------------------------------------------------------'
print, ' '

mms_convert_fom_unix2tai, new_fomstr, new_tai_fomstr
mms_convert_fom_unix2tai, old_fomstr, old_tai_fomstr

problem_status = 0
mms_put_fom_structure, new_tai_fomstr, old_tai_fomstr, local_dir, error_flags, $
  orange_warning_flags, yellow_warning_flags, $
  error_msg, orange_warning_msg, yellow_warning_msg, $
  error_times, orange_warning_times, yellow_warning_times, $
  error_indices, orange_warning_indices, yellow_warning_indices, $
  problem_status

print, '-------------------------------------------------------------'
print, '2nd submission has warnings'
print, 'Orange_warnings: '
loc_orange = where(orange_warning_flags ne 0, count_orange)
print, orange_warning_msg(loc_orange)
print, 'Yellow_warnings: '
loc_yellow = where(yellow_warning_flags ne 0, count_yellow)
print, yellow_warning_msg(loc_yellow)
stop
print, *yellow_warning_times(loc_yellow(0))
print, '-------------------------------------------------------------'
print, ' '


;----------------------------------------------------------------------------
; Finally, we will submit the FOM structure and override the warning
;----------------------------------------------------------------------------

problem_status = 0
mms_convert_fom_unix2tai, new_fomstr, new_tai_fomstr
mms_convert_fom_unix2tai, old_fomstr, old_tai_fomstr

mms_put_fom_structure, new_tai_fomstr, old_tai_fomstr, local_dir, error_flags, $
  orange_warning_flags, yellow_warning_flags, $
  error_msg, orange_warning_msg, yellow_warning_msg, $
  error_times, orange_warning_times, yellow_warning_times, $
  error_indices, orange_warning_indices, yellow_warning_indices, $
  problem_status, /warning_override
    
; Need to free pointers
ptr_free, error_times
ptr_free, orange_warning_times
ptr_free, yellow_warning_times
ptr_free, error_indices
ptr_free, orange_warning_indices
ptr_free, yellow_warning_indices

end