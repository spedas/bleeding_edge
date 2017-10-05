
;+
; NAME:
;   SPD_UI_PRINT
;
; PURPOSE:
;   Modularizes the print code.  Mainly so that it can be grouped in its own separate catch block.
; 
;
; CALLING SEQUENCE:
;   spd_ui_print,info,event
; 
; Input:
;  Info: The info struct from the main gui block
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_main_funcs/spd_ui_print.pro $
;-----------------------------------------------------------------------------------

pro spd_ui_print,info

  compile_opt idl2
  
  err_xxx = 0
  Catch, err_xxx
  IF(err_xxx Ne 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output=err_msg
    FOR j = 0, N_Elements(err_msg)-1 DO begin
      Print, err_msg[j]
      info.historyWin->Update,err_msg[j]
    endfor
    Print, 'Error--See history'
    x=info.master
    histobj=info.historyWin
   ; Widget_Control, event.TOP, Set_UValue=info, /No_Copy
   
    spd_gui_error,x,histobj
    
    ;Now we recover
    info.drawObject->setProperty, destination=info.drawWin
    info.drawObject->update,info.windowStorage,info.loadedData
    info.drawObject->Draw
    
    vBar = widget_info(info.trackVMenu,/button_set)
    if vBar eq 1 then begin
      IF info.trackAll EQ 1 THEN info.drawObject->vBarOn, /all ELSE info.drawObject->vBarOn
    endif
   
    hBar = widget_info(info.trackhMenu,/button_set)
    if hBar eq 1 then begin
  ;    IF info.trackAll EQ 1 THEN info.drawObject->hBarOn, /all ELSE info.drawObject->hBarOn
      info.drawObject->hBarOn
    endif   
   
    result = Widget_Info(info.showPositionMenu, /button_set)
    IF result EQ 1 THEN BEGIN
       IF info.trackAll EQ 1 THEN info.drawObject->legendOn, /All ELSE info.drawObject->legendOn
    ENDIF
    
    RETURN
  ENDIF

  if info.printWarning eq 0 then begin
    ok = dialog_message("IDL printer support can be unreliable." + ssl_newline() + $
                        'If you have trouble, try exporting from the "File->Export to Image File" menu.' + ssl_newline() + $
                        '"File->Export to Image File" supports eps, png, and numerous other image formats.',$
                        dialog_parent=info.master) 
    info.printwarning=1  
  endif
    
  info.statusbar->update,'Warning: IDL printer support can be unreliable, if you have trouble try exporting to via the "File->Export to Image File" menu.'  
    
  if ~obj_valid(info.printObj) then begin
    info.printObj = Obj_New("IDLgrPRINTER", Print_Quality=2, Quality=2)
  endif
  
  cwindow = info.windowstorage->getactive()
  cwindow->getproperty, settings=cwsettings
  cwsettings->getproperty, orientation=orientation
  info.printobj->setproperty, landscape=orientation


  result=Dialog_Printjob(info.printObj, Dialog_Parent=info.master)
  IF result NE 0 THEN BEGIN
    info.drawObject->vbaroff
    info.drawObject->hbaroff
    info.drawobject->legendoff
    info.drawObject->SetProperty,destination=info.printObj
    info.drawObject->update,info.windowStorage,info.loadedData
    ;instancing will leave static display components hidden.
    ;They should not be hidden when printing
    info.drawObject->removeInstance
    info.drawObject->Draw
    info.printObj->NewDocument
    info.drawObject->setProperty, destination=info.drawWin
    info.drawObject->update,info.windowStorage,info.loadedData
    info.drawObject->Draw
    
    result = widget_info(info.trackvMenu,/button_set)
    if result eq 1 then begin
      result = widget_info(info.trackAllMenu,/button_set)
      IF result eq 1 THEN info.drawObject->vBarOn, /all ELSE info.drawObject->vBarOn
    endif
    
    result = widget_info(info.trackhMenu,/button_set)
    if result eq 1 then begin
     ; result = widget_info(info.trackAllMenu,/button_set)
     ; IF result eq 1 THEN info.drawObject->hBarOn, /all ELSE info.drawObject->hBarOn
      info.drawObject->hBarOn
    endif

    result = Widget_Info(info.showPositionMenu, /button_set)
    IF result EQ 1 THEN BEGIN
       IF info.trackAll EQ 1 THEN info.drawObject->legendOn, /All ELSE info.drawObject->legendOn
    ENDIF
  ENDIF
    
end
      
