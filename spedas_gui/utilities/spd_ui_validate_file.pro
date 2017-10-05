;+
;PRO:
;  spd_ui_validate_file
;
;PURPOSE:
;
;  Verifies file read/write permissions and file availability
;
;Inputs:
;  filename:name of the file
;
;Outputs:
;  statuscode: negative value indicates failure, 0 indicates success
;  statusmsg: a message to be returned in the event of an error
;
;Keywords:
;  write: validate for save
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_validate_file.pro $
;-

; Status codes and interpretations:
;
; 0  :  Successful validation, operation may proceed
; < 0:  Unsuccessful validation, do not perform operation
;
; -1 :  Malformed filename
; -2 :  Directory does not exist
; -3 :  Directory does not have write permission
; -4 :  Specified filename is actually a directory
; -5 :  File does not have write permission
; -6 :  Operation cancelled by user
; -7 :  File does not exist
;-99 :  Error caught during validation

pro spd_ui_validate_file,filename=filename,statuscode=statuscode,statusmsg=statusmsg,write=write

catch,Error_status

if (Error_status NE 0) then begin
   statusmsg = !ERROR_STATE.MSG
   statuscode = -99
   catch,/cancel
   return
endif

statuscode = 0
statusmsg = ''

if ~is_string(filename) then begin
 statusmsg='"'+routine_name+'": Malformed filename' 
 statuscode=-1
 return
endif

filename = (expand_path(filename))[0]

traceback = scope_traceback(/structure)

routine_name = traceback[n_elements(traceback)-2].routine

tgt_dirname=file_dirname(filename)

fi=file_info(tgt_dirname)

if keyword_set(write) then begin
  if ~fi.exists then begin
     statusmsg=string(tgt_dirname,format='("'+routine_name+': Failed. Directory ",A," does not exist.")')
     statuscode=-2
     return
  endif else if ~fi.write then begin
     statusmsg=string(tgt_dirname,format='("'+routine_name+': Failed. Directory ",A," is not writeable by you.")')
     statuscode=-3
     return
  endif
  
  fi=file_info(filename)
  if (fi.directory) then begin
     statusmsg=string(filename,format='("'+routine_name+': Failed: ",A," is a directory.")')
     statuscode=-4
     return
  endif else if (fi.exists AND ~fi.write) then begin
     statusmsg=string(filename,format='("'+routine_name+': Failed. File ",A," exists, and is not writeable by you.")')
     statuscode=-5
     return
  end else if (fi.exists) then begin
   statusmsg=string(filename,format='("'+routine_name+': File ",A," already exists. Do you wish to overwrite it?")')
   answer=dialog_message(statusmsg,/question,/default_no, /center )
   if (answer NE 'Yes') then begin
      statusmsg=routine_name+': Save cancelled by user.'
      statuscode=-6
      return
   endif
 
  endif
endif else begin
  fi=file_info(filename)
  if (fi.directory) then begin
     statusmsg=string(filename,format='("'+routine_name+': Failed ",A," is a directory.")')
     statuscode=-4
     return
  endif else if (~fi.exists) then begin
     statusmsg=string(filename,format='("'+routine_name+': Failed. File ",A," does not exist.")')
     statuscode=-7
     return
  endif
endelse

end
