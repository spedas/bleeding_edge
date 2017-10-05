;+ 
;NAME:
; spd_ui_jump
;
;PURPOSE:
; small window that allows the user to enter a new start time for the x axis
; 
;CALLING SEQUENCE:
; spd_ui_jump
;
;INPUT:
; gui_id    id of the top level base widget that is calling this routine
;
;OUTPUT:
; 
;HISTORY:
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_jump.pro $
;
;---------------------------------------------------------------------------------



PRO spd_ui_jump_event, event

  COMPILE_OPT hidden

  Widget_Control, event.TOP, Get_UValue=state, /No_Copy

    ;Put a catch here to insure that the state remains defined
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state.info, err_msg, /error, err_msgbox_title='Error in Jump'
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
  
    ;Which widget caused this event? 
    
  Widget_Control, event.id, Get_UValue=uval
  
    ;Deal with it
    
  CASE uval OF
    'CANC': BEGIN
       DPRINT,  'New File widget canceled' 
       Widget_Control, event.TOP, Set_UValue=state, /No_Copy
       Widget_Control, event.top, /Destroy
       RETURN
    END    
    'OK': BEGIN
       DPRINT,  'New File widget canceled' 
       Widget_Control, event.TOP, Set_UValue=state, /No_Copy
       Widget_Control, event.top, /Destroy
       RETURN
    END
    'TEXT': BEGIN
       ; do something here with text
    END
    ELSE: dprint,  'Not yet implemented'
  ENDCASE
  
  Widget_Control, event.top, Set_UValue=state, /No_Copy

  RETURN
END ;--------------------------------------------------------------------------------



PRO spd_ui_jump, gui_id, historywin

    ;build master widget

  tlb = Widget_Base(/Col, title='SPEDAS: Marker Title', Group_Leader = gui_id, $
                    /Modal, /Floating)

    ;widget bases
    
  spaceBase = Widget_Base(tlb, /Row)
  jumptoBase = Widget_Base(tlb, /Row, XPad=10)
  textBase = Widget_Base(tlb, /Row)
  buttonBase = Widget_Base(tlb, /Row, /Align_Center, XPad=10, YPad=10)

    ;widgets
    
  spaceLabel = Widget_Label(spaceBase, Value='  ')  
  jumptoLabel = Widget_Label(jumptoBase, Value='Jump To: ')
  jumptoText = Widget_Text(jumptoBase, Value='  ', /Editable, XSize=30, UValue='TEXT')
  jumptoLabel = Widget_Label(textBase, Value='                    Format:  YYYY/MM/DD-HH:MM:SS.S')  
  okButton = Widget_Button(buttonBase, Value='    OK     ', UValue='OK')
  cancelButton = Widget_Button(buttonBase, Value='  Cancel   ', UValue='CANC')

  state = {tlb:tlb,gui_id:gui_id, historywin:historywin}

  Widget_Control, tlb, Set_UValue=state, /No_Copy
  Widget_Control, tlb, /Realize
  XManager, 'spd_ui_jump', tlb, /No_Block

  RETURN
END ;--------------------------------------------------------------------------------

