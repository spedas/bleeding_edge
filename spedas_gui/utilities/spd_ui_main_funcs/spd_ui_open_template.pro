;+
;
;  Name: SPD_UI_OPEN_TEMPLATE
;  
;  Purpose: Opens a spedas template
;  
;  Inputs: The info structure from the main gui
;
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_main_funcs/spd_ui_open_template.pro $
;-
pro spd_ui_open_template,info

  compile_opt idl2

  if info.marking ne 0 || info.rubberbanding ne 0 then begin
    return
  endif
  
  info.ctrl = 0

  filestring=info.template_filename
  IF is_String(filestring) then begin
    path = file_dirname(filestring)
  endif
 
  fileName = Dialog_Pickfile(Title='Open SPEDAS Template:', $
    Filter='*.tgt', Dialog_Parent=info.master,file=filestring,path=path,/must_exist)
  IF(Is_String(fileName)) THEN BEGIN
    open_spedas_template,template=template,filename=fileName,$
        statusmsg=statusmsg,statuscode=statuscode
    IF (statuscode LT 0) THEN BEGIN
        dummy=error_message(statusmsg,/ERROR,/CENTER,traceback=0)
    ENDIF ELSE BEGIN
      info.template_filename = filename
      info.template_object = template
      info.windowStorage->setProperty,template=template
    ENDELSE
    info.statusBar->Update, statusmsg
    info.historywin->Update,statusmsg
  ENDIF ELSE BEGIN
    info.statusBar->Update, 'Invalid Filename'
  ENDELSE
    
end
