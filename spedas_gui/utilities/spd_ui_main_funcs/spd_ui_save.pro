;+
;
;  Name: SPD_UI_SAVE
;  
;  Purpose: SAVES a spedas document
;  
;  Inputs: The info structure from the main gui
;
;
;$LastChangedBy: jimmpc1 $
;$LastChangedDate: 2014-05-07 10:48:54 -0700 (Wed, 07 May 2014) $
;$LastChangedRevision: 15065 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_main_funcs/spd_ui_save.pro $
;-
pro spd_ui_save,info

  compile_opt idl2
  
  if info.marking ne 0 || info.rubberbanding ne 0 then begin
    return
  endif

  info.ctrl = 0
    
    activeWindow=info.windowStorage->GetActive()
    activeWindow->GetProperty, Name=name
    filename=info.mainFileName  
    reset_filename_flag = 0
    IF NOT Is_String(filename) then filename=''
    IF filename EQ '' THEN BEGIN 
      xt = Time_String(systime(/sec))
      timeString = Strmid(xt, 0, 4)+Strmid(xt, 5, 2)+Strmid(xt, 8, 2)+$
        '_'+Strmid(xt,11,2)+Strmid(xt,14,2)+Strmid(xt,17,2)
      fileString = 'spedas_saved_'+timeString+'.tgd'
      ;filename = dialog_pickfile(Title='Save SPEDAS Document:', $
      ;   Filter='*.tgd', File = fileString, /Write, Dialog_Parent=info.master)
      filename = spd_ui_dialog_pickfile_save_wrapper(Title='Save SPEDAS Document:', $
         Filter='*.tgd', File = fileString, /Write, Dialog_Parent=info.master)
      reset_filename_flag=1
    ENDIF 

    IF(Is_String(filename)) THEN BEGIN
;For Windows, test filename for '.tgd' extension, if it isn't
;there add it, jmm, 2014-05-07
       If(!version.os_family Eq 'Windows') Then Begin
          test_tgd = strpos(filename, '.tgd')
          If(test_tgd[0] Eq -1) Then filename = filename+'.tgd'
       Endif
       widget_control,/hourglass
       save_document,windowstorage=info.windowstorage,filename=filename,$
           statusmsg=statusmsg,statuscode=statuscode
       IF (statuscode LT 0) THEN BEGIN
            ; -6 is the code for "operation cancelled by user", 
            ; no need to pop up another notification 
            IF (statuscode NE -6) THEN dummy=dialog_message(statusmsg,/ERROR,/CENTER)
       ENDIF ELSE BEGIN
            if (reset_filename_flag EQ 1) then begin
               activeWindow->GetProperty, Name=name
               info.mainFileName=filename
               info.gui_title = filename
            endif
       ENDELSE
       info.statusBar->Update, statusmsg
       info.historywin->Update,statusmsg
    ENDIF ELSE BEGIN
      info.statusBar->Update, 'Operation Cancelled'
    ENDELSE
  
end
