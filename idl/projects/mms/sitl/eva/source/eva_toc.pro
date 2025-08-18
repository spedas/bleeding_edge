; Inspired by TIC and TOC programs of IDL ver 8
; EVA has to be able to run on IDL6.4 so I created this small program.

function eva_toc, clock, REPORT=profilerReport
  compile_opt idl2
  
  common eva_tictoc, tictoc_time, tictoc_profiler
  
  time = systime(/seconds)
  
  if (size(clock,/type) ne 8  && size(tictoc_time,/type) ne 5 ) then begin
    message, 'no tic, no toc', /informational
    return, !null
  endif
  
  if (size(clock,/type) ne 8 && keyword_set(tictoc_profiler)) then begin
    tictoc_profiler = 0b
    profiler, /system, /clear
    profiler, /clear
  endif
  
  if (arg_present(profilerreport)) then $
    profiler, /report, data=profilerreport
    
  result = (size(clock,/type) eq 8) ? time - clock.time : time - tictoc_time
  
  return, result
end


;-------------------------------------------------------------------------------
;+
; :Description:
;   Prints the toc of the clock
;
; :Parameters:
;   clock - (Optional) ID of clock to toc, can be an array
;
; :Keywords:
;   help - Prints the time hash
;
;   named - Prints the name of the clock with the output
;-
PRO eva_toc, clock, REPORT=profilerReport, str=str
  compile_opt idl2
  common eva_tictoc, tictoc_time, tictoc_profiler
  
  time = eva_toc(clock, REPORT=profilerReport)
  if size(time,/type) ne 5 then return
  
  for i=0,n_elements(time)-1 do begin
    str = '% time elapsed'
    if (n_elements(clock) ne 0 && clock[i].name ne '') then begin
      str += ' ' + clock[i].name
    endif
    str += ': '
    tmin = time[i]/60.0; minutes
    if tmin[i] lt  1.0 then begin
      str += strtrim(time[i],2) + ' seconds.'
    endif else begin
      str += string(tmin,format='(F10.3)')+' minutes.'
    endelse
    print, 'EVA: '+str
  endfor
  
END
