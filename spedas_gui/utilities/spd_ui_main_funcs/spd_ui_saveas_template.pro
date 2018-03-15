;+
;
;  Name: SPD_UI_SAVEAS_TEMPLATE
;  
;  Purpose: SAVES a spedas template with a new file name
;  
;  Inputs: The info structure from the main gui
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-03-14 15:33:03 -0700 (Wed, 14 Mar 2018) $
;$LastChangedRevision: 24888 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_main_funcs/spd_ui_saveas_template.pro $
;-

pro spd_ui_saveas_template,info

  compile_opt idl2
  
  messageString = 'Saving a Graph Options Template is a two step process: 1. Store some Graph Options, 2. Save them in a template.' +  string(10B)+  string(10B) $
    + 'For example, click Graph->Page Options, change some settings, and then click "Store for a Template".' + string(10B) + string(10B) $
    + 'If you have already done this, click "OK" below to save the template.' +  string(10B) $
    + 'Otherwise, click Cancel.' +  string(10B)
  
  response=dialog_message(messageString,/CENTER, /CANCEL, /information)
  
  if (response eq 'Cancel') then begin
    dprint, 'User canceled saving the template.'
    return
  endif

  if info.marking ne 0 || info.rubberbanding ne 0 then begin
    return
  endif
  
  info.ctrl = 0

  filestring=info.template_filename
  IF NOT Is_String(filestring) then begin
     xt = Time_String(systime(/sec))
     timeString = Strmid(xt, 0, 4)+Strmid(xt, 5, 2)+Strmid(xt, 8, 2)+$
       '_'+Strmid(xt,11,2)+Strmid(xt,14,2)+Strmid(xt,17,2)
     filestring = 'spedas_template_'+timeString+'.tgt'
  ENDIF
  
  path = file_dirname(filestring)
  
  ;fileName = dialog_pickfile(Title='Save As:', $
  ;     Filter='*.tgt', File = fileString,path=path, /Write, Dialog_Parent=info.master)
  fileName = spd_ui_dialog_pickfile_save_wrapper(Title='Save As SPEDAS Graph Options Template:', $
       Filter='*.tgt', File = fileString,path=path, /Write, Dialog_Parent=info.master)
  IF(Is_String(fileName)) THEN BEGIN
     ;For Windows, test filename for '.tgt' extension and add if not present
     ;copied from spd_ui_save, aaf, 2014-08-18
     If(!version.os_family Eq 'Windows') Then Begin
       test_tgd = strpos(filename, '.tgt')
       If(test_tgd[0] Eq -1) Then filename = filename+'.tgt'
     Endif
     save_spedas_template,template=info.template_object,filename=fileName,$
         statusmsg=statusmsg,statuscode=statuscode
     IF (statuscode LT 0) THEN BEGIN
       ; statuscode -6 means "operation cancelled by user", no
       ; need to pop up another dialog
       IF (statuscode NE -6) THEN dummy=dialog_message(statusmsg,/ERROR,/CENTER, title='Error in GUI')
     ENDIF ELSE BEGIN
       info.template_filename=filename
     ENDELSE
     info.statusBar->Update, statusmsg
     info.historywin->Update,statusmsg
  ENDIF ELSE BEGIN
    info.statusBar->Update, 'Operation Cancelled'
  ENDELSE

end
