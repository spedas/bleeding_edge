; Inspired by TIC and TOC programs of IDL ver 8
; EVA has to be able to run on IDL6.4 so I created this small program.
FUNCTION eva_tic, name, DEFAULT=default, PROFILER=profiler
  compile_opt idl2
  common eva_tictoc, tictoc_time, tictoc_profiler
  
  if size(tictoc_time,/type) ne 5 then tictoc_time = 0d
  if size(name,/type) ne 7 then name = ''
  
  ; make sure toc is ready to go, to avoid including the compile time.
  resolve_routine, 'eva_toc', /no_recompile
  
  if (isa(profiler)) then begin
    tictoc_profiler = keyword_set(profiler)
    profiler, /reset
    if (tictoc_profiler) then begin
      profiler
      profiler, /system
    endif else begin
      profiler, /system, /clear
      profiler, /clear
    endelse
  endif
  
  tt = systime(/seconds)
  result = {name: name, time: tt}
  
  if (keyword_set(default)) then tictoc_time = tt
    
  return, result
end


PRO eva_tic, name, PROFILER=profiler
  compile_opt idl2
  common eva_tictoc, tictoc_time, tictoc_profiler
  
  !NULL = eva_tic(name, /DEFAULT, PROFILER=profiler)
END

