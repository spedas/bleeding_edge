;+ 
;NAME: 
; spd_ui_export_marker
;
;PURPOSE:
; This routine creates and handles the panel for exporting marker data 
;
;CALLING SEQUENCE:
; spd_ui_marker_options
;
;INPUT:
; gui_id:  id for the master base widget (tlb)
;
;OUTPUT:
;
;HISTORY:
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_export_markers.pro $
;---------------------------------------------------------------------------------



PRO spd_ui_export_markers_event, event

  Compile_Opt hidden

  Widget_Control, event.TOP, Get_UValue=state, /No_Copy

    ;Put a catch here to insure that the state remains defined
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg

    spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error in Export Markers'
  
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF

   ; Get the instructions from the widget causing the event and
   ; act on them.

  Widget_Control, event.id, Get_UValue=uval
  
  CASE uval OF
    'CANC': BEGIN
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      RETURN
    END    
    'OK': BEGIN
      ; create spedas marker default file name and save,  exit when done
      xt = Time_String(Systime(/sec))
      timeString = StrMid(xt, 0, 4)+StrMid(xt, 5, 2)+StrMid(xt, 8, 2)+$
         '_'+StrMid(xt,11,2)+StrMid(xt,14,2)+StrMid(xt,17,2)
      fileString = 'spedas_marker_'+timeString
      fileName = Dialog_Pickfile(Title = 'Save SPEDAS Marker File:', $
         Filter = '*.mrk', File = fileName, /Write)
      IF (Is_String(fileName)) THEN BEGIN 
        Widget_Control, event.TOP, Set_UValue=state, /No_Copy
        Widget_Control, event.top, /Destroy
        RETURN
      ENDIF ELSE BEGIN
      ENDELSE
    END
    ; fill this in with all other events, for now just print something  
    ELSE: dprint,  'Not yet implemented'
  ENDCase
  
  Widget_Control, event.top, Set_UValue=state, /No_Copy

  RETURN
END ;--------------------------------------------------------------------------------



PRO spd_ui_export_markers, gui_id

     ;build master and base widgets
     
  tlb = Widget_Base(/Col, Title = 'SPEDAS: Export Markers', group_leader = gui_id, $
                    /modal, /floating)
  topBase = Widget_Base(tlb, /Row) 
    selectionBase = Widget_Base(topBase, /Col, XPad=4)
    flabelBase = Widget_Base(selectionBase, /Row, YPad=1) 
    fFrameBase = Widget_Base(selectionBase, /Col, Frame=3)
    fbuttonBase = Widget_Base(fFrameBase, /Row, /exclusive)
    itemsBase = Widget_Base(fFrameBase, /Row)
    timeBase = Widget_Base(fFrameBase, /Row)
    numberBase = Widget_Base(fFrameBase, /Row)
    panelBase = Widget_Base(selectionBase, /Col)
    plabelBase = Widget_Base(panelBase, /Row)
    fromBase = Widget_Base(panelBase, /Col)
    dplabelBase = Widget_Base(selectionBase, /Row)
    proximityBase = Widget_Base(selectionBase, /Col )
    col1Base = Widget_Base(topBase, /Col, XPad=4, YPad=2)
      elabelBase = Widget_Base(col1Base, /Row)
      exportBase = Widget_Base(col1Base, /Col, Frame=3)
        expbBase = Widget_Base(exportBase, /Col, /Exclusive)
        expdBase = Widget_Base(exportBase, XPad=20, /Col, /Exclusive)

  buttonBase = Widget_Base(col1Base, /Row, /Align_Center, YPad=6)

    ; Create all the widgets on this panel
    
  exportLabel = Widget_Label(elabelBase, Value='Export:', /Align_Left)
  startButton = Widget_Button(expbBase, Value='Start of marker', UValue='START') 
  endButton = Widget_Button(expbBase, Value='END of marker', UValue='END') 
  bothButton = Widget_Button(expbBase, Value='Both start and end of marker', UValue='BOTH') 
  dataButton = Widget_Button(expbBase, Value='Data within marker', UValue='DATA')
  Widget_Control, startButton, /Set_Button
  recordsButton = Widget_Button(expdBase, Value='All Records', Sensitive=0, UValue='RECORDS') 
  averageButton = Widget_Button(expdBase, Value='All Average', Sensitive=0, UValue='AVERAGE')
  proxdbase = widget_base(proximityBase, /row)
  proxdlabel = widget_label(proxdbase, value = 'Data/Marker Proximity: ')
  proximityDroplist = Widget_combobox(proxdBase, XSize=207, $
      UValue='PROXIMITY', $
      Value=['Nearest ', 'Before ', 'After ', 'Interpolated to marker '])                           
  formatLabel = Widget_Label(flabelBase, Value = 'Format of Exported File:', /Align_Left)
  flatButton = Widget_Button(fbuttonBase, Value = 'Flatfile', UValue='FLAT')
  asciiButton = Widget_Button(fbuttonBase, Value = 'ASCII Table', UValue='ASCII') 
  Widget_Control, flatButton, /Set_Button
    separatorLabel = Widget_Label(itemsBase, Value='Item Separators: ')
  separatorDroplist = Widget_combobox(itemsBase, Value=['commas', 'spaces', 'tab'], $
    XSize=120, UValue='SEPARATOR')
  timeLabel = Widget_Label(timeBase, Value='Time Format:      ')
  timeDroplist = Widget_combobox(timeBase, XSize= 120, UValue='TIME', $
     Value=['DFS_STYLE 1989-Jan-19 11:45:30.29', $
     'ABBRDFS_STYLE 1989/Jan/19 11:45:30.27', 'ISO_STYLE U19890119114530.27'])
  numberLabel = Widget_Label(numberBase, Value='Number Format:  ')
  numberDroplist = Widget_combobox(numberBase, XSize= 120, Value = ['e6 (0.000123e4)', $
     'f6 (0.001234)', 'e0 (123e4)'], UValue='NUMBER')
  panelDbase = widget_base(fromBase, /row)
  panelDlabel = widget_label(paneldbase, value = 'From Panel:                 ')
  panelDroplist = Widget_combobox(paneldbase, XSize=202, Value=['0: example',$
     '1: fgm', '2: new window'], UValue='PANEL')
  
  okButton = Widget_Button(buttonBase, Value='  OK    ', UValue='OK', XSize=80)
  cancelButton = Widget_Button(buttonBase, Value = '  Cancel  ', UValue='CANC', XSize=80)
  
    ; State structure, fill in values as needed by event handler
    
  state = {tlb:tlb}

    ; Display panel
    
  Widget_Control, tlb, Set_UValue = state, /No_Copy
  Widget_Control, tlb, /Realize
  XManager, 'spd_ui_export_markers', tlb, /No_Block

  RETURN
END ;--------------------------------------------------------------------------------

