;+
Pro mvn_l2gen_multiprocess_a, function_in, nproc, offset, time_range, $
                              proc_workdir, remove_lock = remove_lock
; function_in is an IDL main program (LEAVE OUT THE .pro)
; THis function needs to run on inputs read in from start and end time files.
; nproc is the number of processes that are desired
; time_range is a 2xN array of start and end times,
; proc_workdir is the directory where the function_in program lives,
; each subprocess will create a directory, copy the function_in
; program into that directory, and run it there. The function_in
; program must pick up its start_time from a file
; 'function_in_start_time.txt' in that directory, and not work 
; past 'function_in_end_time.txt'. These files are created for the
; first process, and the start_time file gets updated each time the
; program runs.
; 23-apr-2009, jmm, Now only sets up the process, processing is handled
; be generic_multiprocess_b.sh 
; Changed name, removed the SSW calls, for use for overplotting. Note
; also that this version overwrites start and end times if the
; subdirectories exist, jmm, 21-nov-2011
; Added offset to be able to use multiple computers, jmm, 6-oct-2013
;-
  full_fn = proc_workdir+'/'+function_in+'.pro'
  For j = offset, offset+nproc-1 Do Begin
      js = strcompress(string(j), /remove_all)
      dirname = proc_workdir+'/'+function_in+js
      If(is_string(file_search(dirname)) Eq 0) Then Begin
;if the working directory doesn't exist, then create it
          file_mkdir, dirname
      Endif
      If(keyword_set(remove_lock)) Then Begin
          spawn, '/bin/rm '+dirname+'/*lock*'
          spawn, '/bin/rm '+dirname+'/*.out'
      Endif
;copy in the main program
      spawn, '/bin/cp '+ full_fn + ' '+dirname
;Create time range files
      openw, unit, dirname+'/'+function_in+'_start_time.txt', /get_lun
      printf, unit, time_string(time_range[0, j-offset])
      free_lun, unit
      openw, unit, dirname+'/'+function_in+'_end_time.txt', /get_lun
      printf, unit, time_string(time_range[1, j-offset])
      free_lun, unit
  Endfor
  Return
End

