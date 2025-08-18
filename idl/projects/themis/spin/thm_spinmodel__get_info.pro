;+
; NAME:
;    THM_SPINMODEL::GET_INFO.PRO
;
; PURPOSE:
;    Return information about the valid time range or shadow times given
;    a spinmodel object reference.
;
; CATEGORY:
;   TDAS
;
; CALLING SEQUENCE:
;   spinmodel->get_info,min_shadow_duration=min_shadow_duration,$
;      shadow_count=shadow_count, $
;      shadow_start=shadow_start,shadow_end=shadow_end,$
;      start_time=start_time, end_time=end_time
;
;  INPUTS:
;    min_shadow_duration: Optional parameter specifying the minimum
;       gap between BAU sun sensor crossing times to be considered a shadow 
;       interval. Defaults to 60.0 sec.
;
;  OUTPUTS: (all optional)
;    shadow_count: Number of shadow intervals found.
;    shadow_start: Double precision array of shadow start times.
;    shadow_end: Double precision array of shadow end times.
;    start_time: Double precision scalar indicating start time
;       of loaded spinmodel data
;    end_time: Double precision scalar indicating end time of
;       loaded spinmodel data 
;
;  PROCEDURE:
;     Shadow intervals consist of spinmodel segments where the
;       "maxgap" parameter exceeds the min_shadow_duration threshold.
;     Start time is the start time of the first segment.
;     End time is the end time of the last segment.
;     If no spinmodel data is loaded for the requested probe,
;     start_time = end_time = 0.0D.
;     If no shadows are found, shadow_count is set to zero and
;     no start/end times are returned.
;  
;  EXAMPLE:
;     timespan,'2007-03-23',1,/days
;     thm_load_state,probe='a',/get_support_data
;
;     spinmodel_get_info,probe='a',shadow_count=shadow_count,$
;       shadow_start=shadow_start, shadow_end=shadow_end,$
;       start_time=start_time,end_time=end_time
;
;-

pro thm_spinmodel::get_info,min_shadow_duration=min_shadow_duration,$
   shadow_count=shadow_count,shadow_start=shadow_start,shadow_end=shadow_end,$
   start_time=start_time,end_time=end_time

  if ~keyword_set(min_shadow_duration) then min_shadow_duration = 60.0D

  sp = self.segs_ptr

  ; If state support data is loaded for at least one probe, but not
  ; this particular probe, then spinmodel_get_ptr will return a
  ; valid pointer, but the data structure it points to won't
  ; contain any segments.

  if ~ptr_valid(sp) then begin
     if arg_present(shadow_count) then shadow_count = 0L
     if arg_present(start_time) then start_time=0.0D
     if arg_present(end_time) then end_time=0.0D
     return
  endif

  ; If we reach this point, the spinmodel structure should contain
  ; at least one segment.

  seg_array=*sp
  seg_count=n_elements(seg_array)
  my_start_time=seg_array[0].t1
  my_end_time=seg_array[seg_count-1].t2

  ; Find eclipse intervals.  The LSBit in segflags indicates that
  ; the BAU telemetry is reporting "shadow" for that time interval.
  ; If FGM sun pulses were used, there may be several consecutive
  ; segments with the eclipse flag set -- they should be merged
  ; into a single interval.

  ; The original algorithm used large gaps between sun pulses as
  ; a proxy for eclipse intervals.  This is unreliable, and is no 
  ; longer supported.

  my_shadow_status = 0
  my_shadow_count=0L
  this_start_time = 0.0D
  this_end_time = 0.0D 
  
  for i=0L,seg_count-1 do begin
    this_eclipse_flag = seg_array[i].segflags AND 1
    if ((this_eclipse_flag EQ 0) AND (my_shadow_status EQ 0)) then begin
       ; Previous and current segments not in eclipse -- do nothing.
    endif else if ((this_eclipse_flag EQ 0) AND (my_shadow_status EQ 1)) then begin
       ; Transition out of eclipse -- update shadow list with eclipse that
       ; just ended, reset shadow status to 0.
       my_shadow_status = 0
       ;dprint,'Eclipse end: '+time_string(this_end_time)
       if (my_shadow_count EQ 0) then begin
          my_shadow_count=1L
          my_shadow_start=[this_start_time]
          my_shadow_end=[this_end_time]
       endif else begin
          my_shadow_count = my_shadow_count + 1
          my_shadow_start = [my_shadow_start, this_start_time]
          my_shadow_end = [my_shadow_end, this_end_time]
       endelse
    endif else if ((this_eclipse_flag EQ 1) AND (my_shadow_status EQ 0)) then begin
       ; Transition into eclipse -- update status and start/end times.
       my_shadow_status = 1
       this_start_time=seg_array[i].t1
       this_end_time=seg_array[i].t2
       ;dprint,'Eclipse start: '+time_string(this_start_time)
    endif else if ((this_eclipse_flag EQ 1) AND (my_shadow_status EQ 1)) then begin
       ; Previous and current segments both in eclipse, update eclipse end time
       this_end_time = seg_array[i].t2
       ;dprint,'Eclipse continues: '+time_string(this_start_time)+' '+time_string(this_end_time)
    endif else begin
       dprint,'Internal error while processing eclipse flags'
    endelse
  endfor

  ; If the very last segment was in shadow, that eclipse hasn't yet been added to
  ; the shadow list, so do it here.
  if (my_shadow_status EQ 1) then begin
     ;dprint,'Last segment in spin model was an eclipse, updating list.'

     if (my_shadow_count EQ 0) then begin
        my_shadow_count=1L
        my_shadow_start=[this_start_time]
        my_shadow_end=[this_end_time]
     endif else begin
        my_shadow_count = my_shadow_count + 1
        my_shadow_start = [my_shadow_start, this_start_time]
        my_shadow_end = [my_shadow_end, this_end_time]
     endelse
  endif

  if arg_present(shadow_count) then shadow_count=my_shadow_count
  if ((my_shadow_count GT 0) AND arg_present(shadow_start)) then shadow_start=my_shadow_start
  if ((my_shadow_count GT 0) AND arg_present(shadow_end)) then shadow_end=my_shadow_end
  if arg_present(start_time) then start_time=my_start_time
  if arg_present(end_time) then end_time=my_end_time
  return 
end
