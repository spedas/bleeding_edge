;+
; PROCEDURE:
;         elf_find_phase_delay
;
; PURPOSE:
;         This routine will retrieve all the phase delay values. The routine
;         searches through the time stamped phase delay values to find the closest 
;         science zone. A structure is returned
;           phase_delay={dsect2add:dsect2add, dphang2add:dphang2add, minpa:minpa, $
;                        badflag:badflag, medianflag:medianflag}

;
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probe:        'a' or 'b' 
;         no_download:  set this flag to search for the file on your local disk
;         hourly:       set this flag to find the nearest science zone within an hour of the 
;                       trange
;
;-
function elf_find_phase_delay, trange=trange, no_download=no_download, probe=probe, $
    instrument=instrument, hourly=hourly 

  ; Initialize parameters if needed
  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init
  if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
    dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
    return, 1
  endif
  if ~undefined(trange) && n_elements(trange) eq 2 $
    then tr = timerange(trange) $
    else tr = timerange()
  if not keyword_set(probe) then probe = 'a'
  if ~undefined(instrument) then instrument='epde'
 
  ; download and read the phase delay file
  phase_delays=elf_get_phase_delays(no_download=nodownload, probe=probe, $
     instrument=instrument)

  npd = n_elements(phase_delays)
  if size(phase_delays, /type) NE 8 then begin
    dprint, dlevel = 0, 'Unable to retrieve phase delays.' 
    return, -1
  endif

   tdiff= abs(phase_delays.starttimes - tr[0])
   mdt = min(tdiff,midx)
 
   ; check to see which phase delay is closest to the time range entered  
   if mdt LE 600. then begin  
     if phase_delays.badflag[midx] eq 0 then begin
       dsect2add=phase_delays.sect2add[midx]
       dphang2add=phase_delays.phang2add[midx]
       badflag=phase_delays.badflag[midx]
     endif else begin       
       dsect2add=phase_delays.LASTESTMEDIANSECTR[midx]
       dphang2add=phase_delays.latestmedianphang[midx]
       badflag=phase_delays.badflag[midx]
     endelse  
   endif else begin
     dsect2add=phase_delays.LASTESTMEDIANSECTR[midx]
     dphang2add=phase_delays.latestmedianphang[midx]
     badflag=2 
   endelse

   phase_delay={dsect2add:dsect2add, dphang2add:dphang2add, badflag:badflag}

  return, phase_delay 
  
 end
     