;+
;Procedure:
;  spd_ui_download_callback
;
;
;Purpose:
;  A callback function for the idlneturl object as used by spd_download_file
;
;
;Calling Sequence:
;  N/A - function name set as idlneturl object's callback_function property
;
;
;Input/Output:
;  status:  See "Using Callbacks with the IDLnetURL Object" in IDL documentation
;  progress:  See "Using Callbacks with the IDLnetURL Object" in IDL documentation
;  data:  Custom data structure for passing variables from spd_download_file 
;         to this function.
;          {
;            net_object:   reference to current idlneturl object
;            msg_time:  pointer to time of the last status message
;            msg_data:  bytes transferred as of msg_time
;            progress_object:  reference to applicable status output object
;            error: pointer to flag denoting whether an error occurred in this code
;                   (to be used by handler later)
;           }
;
;
;Output:
;  return_value:  1 if everything is OK, 0 if operation should be canceled
;
;
;Notes:
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-01-13 11:24:43 -0800 (Fri, 13 Jan 2017) $
;$LastChangedRevision: 22594 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/spd_download/spd_download_callback.pro $
;
;-

function spd_download_callback, status, progress, data

    compile_opt idl2, hidden


; Exceptions in this code would normally be caught in spd_download_file.
; However, if the download is not canceled by returning 0 here then the
; file will remain locked by idl (windows).  The flag alerts the error 
; handler that the cancel was actually an error.
catch, error
if error ne 0 then begin
  catch,/cancel
  help,/last_message
  if is_struct(data) then begin
    *(data.error) = 1b
  endif
  return, 0
endif


;time in sec between messages
delay = 5d
elapsed = systime(/sec) - *(data.msg_time)

if elapsed ge delay then begin

  ;if progress data is valid then print the total progress,
  ;otherwise print the current status message
  if progress[0] then begin

    ;speed in kb/s
    speed = '('+strtrim( string( (progress[2] - *(data.msg_data)) / elapsed / 1e3, format='(f12.1)'), 2)+' KB/s)'

    ;if total size is unknown then only print amount transferred and speed
    if progress[1] eq 0 then begin
      complete = ' '+strtrim(progress[2],2) + ' bytes'
    endif else begin
      complete = string( 100. * progress[2] / progress[1], format='(f5.1)')+'%' ;extra space in case of "100"
    endelse

    msg = ' '+complete+' complete   '+speed

  endif else begin

    msg = '  '+status

  endelse

  *(data.msg_time) = systime(/sec)
  *(data.msg_data) = progress[2]

  dprint, dlevel=2, sublevel=1, msg
  
  if obj_valid(data.progress_object) then begin
    ;data.progress_object -> update, msg 
  endif

endif

return, 1

end