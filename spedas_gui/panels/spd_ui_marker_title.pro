;+
;NAME:
; spd_ui_marker_title
;
;PURPOSE:
; this window is displayed whenever a user has marked an area
; the window handles marker information such as title
;    
;CALLING SEQUENCE:
; spd_ui_marker_title, gui_id
;INPUT:
; gui_id     id of top level base widget from calling program
;
;OUTPUT:
; 
;HISTORY:
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_marker_title.pro $
;
;--------------------------------------------------------------------------------



PRO spd_ui_marker_title_event, event

  Compile_Opt hidden

  Widget_Control, event.TOP, Get_UValue=state, /No_Copy

    ;Put a catch here to insure that the state remains defined
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error in Marker Title'
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
   ; Get the instructions from the widget causing the event and
   ; act on them.
   IF(Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN
     state.historyWin->update,"Marker Canceled"
     state.statusBar->update,"Marker Canceled"
     state.markerTitle->SetProperty, Cancelled=1, Name=''
     return
   ENDIF

  Widget_Control, event.id, Get_UValue=uval
  CASE uval OF
     'CANC': BEGIN
      state.historyWin->update,"Marker Canceled"
      state.statusBar->update,"Marker Canceled"
      state.markerTitle->SetProperty, Cancelled=1, Name=''
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      RETURN
    END 
    'NAME': BEGIN
      state.markerTitle->GetProperty, UseDefault=useDefault
      Widget_Control, event.id, Get_Value=name
      IF useDefault EQ 1 THEN state.markerTitle->SetProperty, Name=name, DefaultName=name $
        ELSE state.markerTitle->SetProperty, Name=name
      state.statusBar->Update, String('Marker title has been set to '+name)
      state.historyWin->Update, String('Marker title has been set to '+name)
    END
  
    'OK': BEGIN
      state.historyWin->update,"Marker Title Widget Closed"
      state.statusBar->update,"Marker Title Widget Closed"
      state.markerTitle->SetProperty, Cancelled=0 
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      RETURN
    END
    
    ELSE: dprint,  'Not yet implemented'
  ENDCASE

  Widget_Control, event.top, Set_UValue=state, /No_Copy

  RETURN
END ;--------------------------------------------------------------------------------



function spd_ui_marker_title, gui_id, historyWin, statusBar

      ;top level base widget
      
  tlb = Widget_Base(/Col, Title='Marker Title', Group_Leader=gui_id, $
                    /Modal, /Floating)
                    
      ;base widgets
                    
  markerTBase = Widget_Base(tlb, /Row) 
  markerBBase = Widget_Base(tlb, /Col, /Nonexclusive, sensitive=0) 
  buttonBase = Widget_Base(tlb, /Row, /Align_Center)
 
      ;get initial values for widgets
  
  markerTitle = obj_new('spd_ui_marker_title')
  markerTitle->GetProperty, Name=name, UseDefault=useDefault, DefaultName=defaultName

      ;widgets
    
  markerTLabel = Widget_Label(markerTBase, Value='Marker Title: ')
  markerTText = Widget_Text(markerTBase, Value=name, /Editable, XSize=30, UValue='NAME', /All_Events)
  okButton = Widget_Button(buttonBase, Value='    OK     ', UValue='OK')
  cancelButton = Widget_Button(buttonBase, Value = '  Cancel   ', UValue='CANC')

  state = {tlb:tlb, gui_id:gui_id, markerTitle:markerTitle, historyWin:historyWin, statusBar:statusBar}

  Widget_control, tlb, Set_UValue=state, /No_Copy
  Widget_control, tlb, /Realize
  XManager, 'spd_ui_marker_title', tlb, /No_Block

  RETURN,markerTitle
END ;--------------------------------------------------------------------------------

