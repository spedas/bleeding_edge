;+
; NAME:
;    SPINMODEL_GET_INFO.PRO
;
; PURPOSE:
;    Given a probe string or spinmodel pointer, return information
;    about the valid time range or shadow times.
;
; CATEGORY:
;   TDAS
;
; CALLING SEQUENCE:
;   spinmodel_get_info,model=modelptr,min_shadow_duration=min_shadow_duration,$
;      shadow_count=shadow_count, $
;      shadow_start=shadow_start,shadow_end=shadow_end,$
;      start_time=start_time, end_time=end_time
;
;  INPUTS:
;    Model: pointer to s spinmodel structure
;    Probe: a string identifying the probe.
;       The caller must specify either a model pointer or probe string.
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

pro spinmodel_get_info,model=model,probe=probe,min_shadow_duration=min_shadow_duration,$
   shadow_count=shadow_count,shadow_start=shadow_start,shadow_end=shadow_end,$
   start_time=start_time,end_time=end_time

  if ((n_elements(model) GT 1) OR (n_elements(probe) GT 1)) then begin
     message,'Multiple probes not supported'
  end
 
  if keyword_set(probe) then begin
     valid_probes=['a','b','c','d','e','f'] 
     idx=where(strcmp(probe,valid_probes) EQ 1,count)
     if (count NE 1) then begin
        message,'Unrecognized probe string: valid choices are ''a'',''b'',''c'',''d'',''e'', or ''f'' '
     end
  end

  if keyword_set(model) then begin
     mptr=model
  endif else if keyword_set(probe) then begin
     mptr=spinmodel_get_ptr(probe)
  endif else begin
     message,'No model or probe string specified'
  endelse

  ; If no state support data is loaded yet for *any* probe, spinmodel_get_ptr
  ; returns null.

  if ~obj_valid(mptr) then begin
     if arg_present(shadow_count) then shadow_count = 0L
     if arg_present(start_time) then start_time=0.0D
     if arg_present(end_time) then end_time=0.0D
     return
  end
 
  if ~keyword_set(min_shadow_duration) then min_shadow_duration = 60.0D

  mptr->get_info,min_shadow_duration=min_shadow_duration,$
   shadow_count=shadow_count,shadow_start=shadow_start,shadow_end=shadow_end,$
   start_time=start_time,end_time=end_time
end
