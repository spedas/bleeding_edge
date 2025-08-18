;+
;
;  Name: SPD_UI_DIALOG_PICKFILE_SAVE_WRAPPER
;  
;  Purpose: Wrapper for the IDL routine dialog_pickfile. Checks for invalid characters in the filename.
;  
;  Inputs: Any keywords that need to be passed on to dialog_pickfile (see note 1 below for special cases)
;
;  Output: Filename ('' if dialog is cancelled)
;  
;  NOTE: 
;  1. This routine should not be used if the multiple_files keyword is being passed to dialog_pickfile
;        as ';' will be flagged as invalid if used to separate file names.
;  2. This routine doesn't check for all characters that can cause problems on windows. A large number of cases
;    are already screened by dialog_pickfile on windows (cases that cause no problems on linux).
;  
;  
;$LastChangedBy: egrimes $
;$LastChangedDate: 2014-07-10 15:57:22 -0700 (Thu, 10 Jul 2014) $
;$LastChangedRevision: 15553 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_dialog_pickfile_save_wrapper.pro $
;-

function spd_ui_dialog_pickfile_save_wrapper,get_path=newpath,_extra=ex
  
  ; this fixes a bug specific to the default_extension and filter keywords in IDL 7.1
  if is_struct(ex) then begin
      ; check that both default_extension and filter keywords are set in the ex struct
      str_element, ex, 'default_extension', success=de_success
      str_element, ex, 'filter', success=filter_success
      if filter_success && de_success then $
          if n_elements(ex.filter) eq 1 then str_element, ex, 'filter', [ex.filter], /add_replace
  endif 

  validfile = 0
  while ~validfile do begin
    filename = dialog_pickfile(get_path=newpath,_extra=ex)
    if stregex(filename,'\*|\{|;|\?', /boolean) then begin
      messageString = 'Invalid characters in filename. Please enter a new name.'
      response=dialog_message(messageString,/CENTER)
    endif else validfile = 1
  endwhile
  return, filename
end
