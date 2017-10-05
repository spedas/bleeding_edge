;+
;NAME:
; spd_ui_widget_tree_test
;
;PURPOSE:
;  tests the tree widget
;    
;CALLING SEQUENCE:
; spd_ui_widget_tree_test,gui_id
; 
;INPUT:
; gui_id:  id of top level base widget from calling program
;
;OUTPUT:
;
; 
;HISTORY:
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_widget_tree_test.pro $
;
;--------------------------------------------------------------------------------

pro spd_ui_widget_tree_test_event,event

  compile_opt hidden,idl2

  Widget_Control, event.TOP, Get_UValue=state, /No_Copy

  ;Put a catch here to insure that the state remains defined
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error in Widget Tree Test'
    
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
     ; copy = state.tree->getCopy()
    ;  defsysv,'!TEST',copy
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      RETURN
    END
    'OK': BEGIN
      copy = state.tree->getCopy()
      defsysv,'!TEST',copy
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      RETURN
    END
    'MODE0':BEGIN
      widget_control,state.text,set_value=''
      state.tree->setProperty,mode=0
    END
    'MODE1':BEGIN
      widget_control,state.text,set_value=''
      state.tree->setProperty,mode=1
    END
    'MODE2':BEGIN
      widget_control,state.text,set_value=''
      state.tree->setProperty,mode=2
    END
    'MODE3':BEGIN
      widget_control,state.text,set_value=''
      state.tree->setProperty,mode=3
    END
    'TREE':BEGIN
      widget_control,event.id,get_value=value
      val = value->getValue()
      if size(val,/type) eq 10 then begin
        s = ['']
        for i = 0,n_elements(val)-1 do begin
          printdat,*val[i],output=o
          append_array,s,o
        endfor
        widget_control,state.text,set_value=s
      endif else if is_string(val) then begin
        widget_control,state.text,set_value=val
      endif else begin
        widget_control,state.text,set_value=''
      endelse
    END
    ELSE: BEGIN
      dprint, 'Unhandled Event'
    END
  ENDCASE
    
  Widget_Control, event.top, Set_UValue=state, /No_Copy

  RETURN

end

pro spd_ui_widget_tree_test,gui_id,loadedData, historywin

  compile_opt idl2
  
  tlb = Widget_Base(/Col, Title='Tree', Group_Leader=gui_id, $
    /Modal, /Floating)
    
  row1 = widget_base(tlb,/row)
  
  tree_widget = obj_new('spd_ui_widget_tree',row1,'TREE',loadedData,xsize=200,ysize=200,mode=0,multi=0,leafonly=1,/showdatetime)
  
  defsysv,'!TEST',exists=e
  
  if e && widget_valid(!TEST) then begin
    tree_widget->update,from_copy=!TEST
  endif
  
  text_widget = widget_text(row1,value='',uvalue='TEXT',xsize=60,ysize=40)  
  
  row2 = widget_base(tlb,/row,/exclusive)
  
  button1 = widget_button(row2,value='tplot var mode',uvalue='MODE0')
  widget_control,button1,/set_button
  button2 = widget_button(row2,value='component mode 1',uvalue='MODE1')
  button3 = widget_button(row2,value='component mode 2',uvalue='MODE2')
  button4 = widget_button(row2,value='component mode 3',uvalue='MODE3')
  
  last_row = widget_base(tlb,/row)
  
  ok_button = widget_button(last_row,value='OK',uvalue='OK')
  canc_button = widget_button(last_row,value='Cancel',uvalue='CANC')  
  
  state = {tlb:tlb,  $
           gui_id:gui_id, $
           text:text_widget, $
           tree:tree_widget, $
           historywin:historywin $
           }
            
  Widget_Control, tlb, Set_UValue = state, /No_Copy
  Widget_Control, tlb, /Realize
  
  XManager, 'spd_ui_widget_tree_test', tlb, /No_Block

  return
  
end
