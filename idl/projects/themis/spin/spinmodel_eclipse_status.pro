;+
; NAME:
;    SPINMODEL_ECLIPSE_STATUS.PRO
;
; PURPOSE:
;    For each eclipse period in a spinmodel, report the start and stop times, segment flag values, and status strings
;    describing the level of spinmodel corrections available for that eclipse.
;
; CATEGORY:
;   TDAS
;
; CALLING SEQUENCE:
;   spinmodel_eclipse_status,model=modelptr, start_times=start_times, end_times=end_times, flags=flags, flag_strings=flag_strings
;
;  INPUTS:
;    Model: pointer to s spinmodel structure
;
;  OUTPUTS:
;    start_times: start times of each eclipse
;    end_times: end times of each eclipse
;    flags: segment flag values (valid values 0=sunlight, 1=uncorrected eclipse, 3=partial corrections, 7=full corrections
;    flag_strings: descriptive strings for each possible status
;
;  
;-

pro spinmodel_eclipse_status,model=model,start_times=start_times, end_times=end_times,flags=flags, flag_strings=flag_strings

  if (keyword_set(model) NE 1) then begin
     message,'Required MODEL keyword argument not present.'
  end

  spinmodel_get_info,model=model,shadow_count=shadow_count,shadow_start=start_times, shadow_end=end_times
  ecl_mid_times = start_times + (end_times-start_times)/2.0
  model->interp_t,time=ecl_mid_times,segflag=flags
  flag_strings=[]
  for i=0,shadow_count-1 do begin
    if flags[i] eq 0 then begin
      flag_strings=[flag_strings,"in sunlight"]
    endif else if flags[i] eq 1 then begin
      flag_strings=[flag_strings,"uncorrected eclipse"]
    endif else if flags[i] eq 3 then begin
      flag_strings=[flag_strings,"partially corrected eclipse: field waveforms corrected; particle data and EFI and FGM spin fits will have uncorrected spin phase offsets"]
    endif else if flags[i] eq 7 then begin
      flag_strings=[flag_strings,"fully corrected eclipse"]
    endif else begin
      flag_strings=[flag_strings,"unrecognized flag code " + string(flag)]
    endelse   
  endfor

end
