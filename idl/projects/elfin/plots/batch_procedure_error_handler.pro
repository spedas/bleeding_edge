;+
;Procedure: batch_procedure_error_handler
;
;Purpose:

;This routine catches errors for procedure calls, to prevent individual routine
;failures from killing the whole process
;
;Inputs:
;  proc_name: is a string naming the procedure to be called
;  date: The date for the call(positional argument is common to all calls being error handled
;  _extra: is used to allow any set of keyword parameters for the call
;  arg0-arg9: Support for up to 10 positional parameters.  How many are used depends upon the procedure
;
;
;Example:
;  check_state_files_error_handler,'map_themis_state_south_t96','2007-03-23',/gifout,noview=noview,/move
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2016-03-14 12:22:36 -0700 (Mon, 14 Mar 2016) $
; $LastChangedRevision: 20440 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/thmsoc/trunk/idl/thmsoc/asi/batch_procedure_error_handler.pro $
;-
pro batch_procedure_error_handler,proc_name,arg0,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,_extra=ex

  catch,err ;jumps back to here on error
  if err eq 0 then begin
    ;initial execution(non-error state)
    case n_params() of
      1 :call_procedure,proc_name,_extra=ex
      2 :call_procedure,proc_name,arg0,_extra=ex
      3 :call_procedure,proc_name,arg0,arg1,_extra=ex
      4 :call_procedure,proc_name,arg0,arg1,arg2,_extra=ex
      5 :call_procedure,proc_name,arg0,arg1,arg2,arg3,_extra=ex
      6 :call_procedure,proc_name,arg0,arg1,arg2,arg3,arg4,_extra=ex
      7 :call_procedure,proc_name,arg0,arg1,arg2,arg3,arg4,arg5,_extra=ex
      8 :call_procedure,proc_name,arg0,arg1,arg2,arg3,arg4,arg5,arg6,_extra=ex
      9 :call_procedure,proc_name,arg0,arg1,arg2,arg3,arg4,arg5,arg6,arg7,_extra=ex
      10:call_procedure,proc_name,arg0,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,_extra=ex
      11:call_procedure,proc_name,arg0,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,_extra=ex
      else: dprint,'Number of parameters unsupported by batch_procedure_error_handler, modify this procedure to add more'
    endcase
  endif else begin
    ;handle error,(basically just output and skip)
    dprint,'ERROR Caught: ' + !error_state.msg
    help, /last_message, output = err_msg
    For j = 0, n_elements(err_msg)-1 Do dprint, err_msg[j]
  endelse

end
