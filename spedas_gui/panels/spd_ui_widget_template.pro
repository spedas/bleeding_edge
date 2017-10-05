;+
;NAME:
; spd_ui_widget_template
;
;PURPOSE:
;  template that contains repeated code in widget creation
;    
;CALLING SEQUENCE:
; spd_ui_widget_template,gui_id
; 
;INPUT:
; gui_id:  id of top level base widget from calling program
;
;OUTPUT:
; 
;HISTORY:
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_widget_template.pro $
;
;--------------------------------------------------------------------------------

pro spd_ui_widget_template_event,event

  compile_opt hidden,idl2

  Widget_Control, event.TOP, Get_UValue=state, /No_Copy

  ;Put a catch here to insure that the state remains defined
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error in Widget Template'
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    RETURN
  ENDIF
  
  IF(Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN  
    Exit_Sequence:
    dprint,  'Widget Killed' 
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy    
    Widget_Control, event.top, /Destroy
    RETURN      
  ENDIF

  Widget_Control, event.id, Get_UValue=uval
  CASE uval OF
    'CANC': BEGIN
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      RETURN
    END
    'OK': BEGIN
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      RETURN
    END
    ELSE: dprint, 'Not yet implemented'
  ENDCASE
    
  Widget_Control, event.top, Set_UValue=state, /No_Copy

  RETURN

end


pro spd_ui_widget_template,gui_id, historywin

  compile_opt idl2
  
  tlb = Widget_Base(/Col, Title='Template', Group_Leader=gui_id, $
    /Modal, /Floating,/tlb_kill_request_events)
    
  button_row = widget_base(tlb,/row)
  status_row = widget_base(tlb,/row)
  
  ok_button = widget_button(button_row,value='OK',uvalue='OK')
  canc_button = widget_button(button_row,value='Cancel',uvalue='CANC')  
  
  statusBar = Obj_New("SPD_UI_MESSAGE_BAR", status_row, Xsize=30, $
YSize=1)
  
  state = {tlb:tlb,  $
           gui_id:gui_id, $
           statusBar:statusBar, $
           historywin:historywin}
            
  Widget_Control, tlb, Set_UValue = state, /No_Copy
  Widget_Control, tlb, /Realize
  
  XManager, 'spd_ui_widget_template', tlb, /No_Block

  return
  
end
