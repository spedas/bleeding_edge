;+ 
;NAME:
; spd_ui_save_data
;
;PURPOSE:
; user interface panel for user to select whether to save data with the 
; SPEDAS GUI Document along with the other settings that are saved in the file
;
;CALLING SEQUENCE:
; result = spd_ui_data(gui_id)   where result 1=save w/data, 0=save settings only
;
;INPUT:
; gui_id    widget id of calling program
;
;OUTPUT:
; 
;HISTORY:
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_save_data.pro $
;
;---------------------------------------------------------------------------------



Pro spd_ui_save_data_event, event

  Compile_Opt hidden

  Widget_Control, event.TOP, Get_UValue=state, /No_Copy

    ;Put a catch here
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error in Save Data'
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
  
  Widget_Control, event.id, Get_UValue=uval
  
  CASE uval OF
    'CANC': BEGIN
      dprint,  'New File widget canceled' 
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      RETURN
    END    
    'OK': BEGIN
      dprint,  'New File widget canceled' 
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      RETURN
    END
    
    Else: dprint,  'Not yet implemented'
  EndCase
  
  Widget_Control, event.top, Set_UValue = state, /No_Copy

  RETURN
END ;--------------------------------------------------------------------------------



PRO spd_ui_save_data, gui_id, historywin

      ;top level land main bases
      
  tlb = Widget_Base(/Col,Title='SPEDAS: Save with Data ', Group_Leader=gui_id, $
                    /Modal, /Floating)
  topBase = Widget_Base(tlb, /Row, /Align_Top, /Align_Left, YPad=1, XPad=10) 
  radioBase = Widget_Base(tlb, /Col, /Align_Center, YPad=8, /Exclusive) 
  buttonBase = Widget_Base(tlb, /Row, /Align_Center, YPad=8) 

  topLabel = Widget_Label(topBase, Value='Which portion of the data would you like to save?')
  
  fieldsButton = Widget_Button(radioBase, Value='Just those fields used in the plot')
  allDataButton = Widget_Button(radioBase, Value='All data')
  Widget_Control, allDataButton, /Set_Button
  
  okButton = Widget_Button(buttonBase, Value='    OK     ', UValue='OK')
  cancelButton = Widget_Button(buttonBase, Value='  Cancel   ', UValue='CANC')

  state = {tlb:tlb, gui_id:gui_id,historywin:historywin}

  CenterTlb, tlb
  Widget_Control, tlb, Set_UValue=state, /No_Copy
  Widget_Control, tlb, /Realize
  
  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif
  
  XManager, 'spd_ui_save_data', tlb, /No_Block

  RETURN
END ;--------------------------------------------------------------------------------

