; This converts backstructure data from the burst segment status table into a variable
; similar to the fom structure

pro mms_get_back_structure, start_time_unix, stop_time_unix, backstr, pw_flag, pw_message

pw_flag = 0
pw_message = 'ERROR: Unable to retrieve back-structure from SDC. Login failed or no data available for specified time range.'

; Convert start and stop times to tai
load_leap_table2, leaps, juls

table_length = n_elements(leaps)

;FDWHACK - The -9 seconds is to match my time with the SDC's SPICE
;based time conversion.

;start_jul = start_time_unix/double(86400) + julday(1, 1, 1970, 0, 0, 0)
;loc_greater = where(start_jul gt juls, count_greater)
;last_loc = loc_greater(count_greater-1)
;current_leap = leaps(last_loc)
;start_utc = double(86400)*(start_jul - julday(1, 1, 1958, 0, 0, 0))
;start_tai = long(start_utc + current_leap - 9)

start_tai = mms_unix2tai(start_time_unix)

;stop_jul = stop_time_unix/double(86400) + julday(1, 1, 1970, 0, 0, 0)
;loc_greater = where(stop_jul gt juls, count_greater)
;last_loc = loc_greater(count_greater-1)
;current_leap = leaps(last_loc)
;stop_utc = double(86400)*(stop_jul - julday(1, 1, 1958, 0, 0, 0))
;stop_tai = long(stop_utc + current_leap - 9)

stop_tai = mms_unix2tai(stop_time_unix)

; Get the burst segment status table
burst_segments = get_mms_burst_segment_status(start_time = start_tai, end_time = stop_tai)

if n_elements(burst_segments) gt 1 then begin

  ; Get tagnames
  burst_tags = tag_names(burst_segments)
  num_tags = n_tags(burst_segments)

  starts = burst_segments.taistarttime
  stops = burst_segments.taiendtime
  
  

  seglengths = (stops-starts)/10

  fom = burst_segments.fom

  ; Create the back structure

  backstr = {start: starts, $
             stop: stops, $
             fom: fom, $
             seglengths: seglengths, $
             nbuffs: total(seglengths), $
             changestatus: replicate(0, n_elements(fom)), $
             datasegmentid: burst_segments.datasegmentid, $
             parametersetid: burst_segments.parametersetid, $
             ispending: burst_segments.ispending, $
             inplaylist: burst_segments.inplaylist, $
             status: burst_segments.status, $
             numevalcycles: burst_segments.numevalcycles, $
             sourceid: burst_segments.sourceid, $
             createtime: burst_segments.createtime, $
             finishtime: burst_segments.finishtime, $
             discussion: burst_segments.discussion} 
              
endif else begin
  if n_tags(burst_segments) eq 0 then begin
    backstr = 0
    pw_flag = 1
;  if typename(burst_segments) eq 'INT' then begin
;    backstr = 0
;    pw_flag = 1
;  endif else if burst_segments.taistarttime eq 0 then begin
;    backstr = 0
;    pw_flag = 1
  endif else begin
    burst_tags = tag_names(burst_segments)
    num_tags = n_tags(burst_segments)
    
    starts = burst_segments.taistarttime
    stops = burst_segments.taiendtime
    
    seglengths = (stops-starts)/10
    
    fom = burst_segments.fom
    
    ; Create the back structure
    
    backstr = {start: starts, $
               stop: stops, $
               fom: fom, $
               seglengths: seglengths, $
               nbuffs: total(seglengths), $
               changestatus: 0, $
               datasegmentid: burst_segments.datasegmentid, $
               parametersetid: burst_segments.parametersetid, $
               ispending: burst_segments.ispending, $
               inplaylist: burst_segments.inplaylist, $
               status: burst_segments.status, $
               numevalcycles: burst_segments.numevalcycles, $
               sourceid: burst_segments.sourceid, $
               createtime: burst_segments.createtime, $
               finishtime: burst_segments.finishtime, $
               discussion: burst_segments.discussion}
  endelse
endelse 

end