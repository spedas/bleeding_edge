;+ 
;NAME: 
; spd_ui_marker_options
;
;PURPOSE:
; This routine creates a window for the user to set options for markers
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
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_marker_options.pro $
;--------------------------------------------------------------------------------



PRO spd_ui_marker_options_event, event

  Compile_Opt hidden

  Widget_Control, event.TOP, Get_UValue=state, /No_Copy

    ;Put a catch here to insure that the state remains defined
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state.info, err_msg, /error, err_msgbox_title='Error in Marker Options'
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
    ;kill request block

  IF (Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN  
    exit_sequence:
    dprint,  'widget killed' 
    Widget_Control, event.top, Set_UValue=state, /No_Copy
    Widget_Control, event.top, /Destroy
    RETURN      
  ENDIF

   ; Get the instructions from the widget causing the event and
   ; act on them.

  Widget_Control, event.id, Get_UValue=uval
  
  CASE uval OF
    'CANC': BEGIN
      DPRINT,  'Layout widget canceled' 
      Widget_Control, event.top, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /destroy
      RETURN
    END
    ELSE: ;dprint,  ''
  ENDCASE

  Widget_Control, event.TOP, Set_UValue=state, /No_Copy
  
RETURN
END ;--------------------------------------------------------------------------------



PRO spd_ui_marker_options, gui_id, historywin

      ; top level base widget
      
  tlb = Widget_Base(/Col, Title='SPEDAS: Marker Options ', Group_Leader = gui_id, $
                    /Modal, /Floating)
                    
      ; widget bases
      
  panelLabelBase = Widget_Base(tlb, /Row)
  panelMainBase = Widget_Base(tlb, /Col, Frame=3)
  panelBase = Widget_Base(panelMainBase, /Row, YPad=1)
    panelTextBase = Widget_Base(panelBase, /Row)
    panelArrowBase = Widget_Base(panelBase, /Col, YPad=40, XPad=3)
    currentMarkerBase = Widget_Base(panelBase, /Col, YPad=10, XPad=4) 
    allPanelBase = Widget_Base(panelBase, /Col, YPad=10) 
  propertiesBase = Widget_Base(panelMainBase, /Col, XPad=5)
    plabelBase = Widget_Base(propertiesBase, /Row)
    pFrameBase = Widget_Base(propertiesBase, /Col, Frame=3, XPad=5)
      propertyBase = Widget_Base(pFrameBase, /Row)
      controlsBase = Widget_Base(pFrameBase, /Row, /NonExclusive)
      placeBase = Widget_Base(pFrameBase, /Row, XPad=2)
        placementBase = Widget_Base(placeBase, /Col)
        spaceLabel = Widget_Label(placeBase, Value='  ')
        appearanceBase = Widget_Base(placeBase, /Col)
  buttonBase = Widget_Base(tlb, /Row, /Align_Center)

      ; widgets

  panelLabel = Widget_Label(panelLabelBase, Value='Panel: ')
  panelValue=['Panel 1: ', '   tha_fge', '       tha_fge_x', '       tha_fge_y', $
    '       tha_fge_z', 'Panel 2: ', '    thb_fge', 'Panel 3: ', '    thc_fge']
  panelDroplist = Widget_combobox(panelLabelBase, Value=panelValue, XSize=220)
  panelText = Widget_Text(panelTextBase, /Editable, Value=' ', XSize=40, YSize=9)  
  shiftupbmp = filepath('shift_up.bmp', Subdir=['resource', 'bitmaps'])
  shiftdownbmp = filepath('shift_down.bmp', Subdir=['resource', 'bitmaps'])
  shiftupButton = Widget_Button(panelArrowBase, Value=shiftupbmp, /Bitmap, UValue='UP', $
    Tooltip='Move this panel up by one')
  shiftdownButton = Widget_Button(panelArrowBase, Value=shiftdownbmp, /Bitmap, UValue='DOWN', $
    Tooltip='Move this panel down by one') 
  currentLabel = Widget_Label(currentMarkerBase, Value='Current Marker')
  copyButton = Widget_Button(currentMarkerBase, Value='  Copy...  ')
  removeButton = Widget_Button(currentMarkerBase, Value=' Remove ')
  removeallButton = Widget_Button(currentMarkerBase, Value=' Remove All ')
  allpanelLabel = Widget_Label(allPanelBase, Value='All Panels')
  clearButton = Widget_Button(allPanelBase, Value='Clear All')
  makesimiliarButton = Widget_Button(allPanelBase, Value='Make Similar')
  copyappearButton = Widget_Button(allPanelBase, Value='Copy Appearance')  
  propertyLabel = Widget_Label(pLabelBase, Value='Properties: ')
  labelLabel = Widget_Label(propertyBase, Value = 'Label: ')
  labelText = Widget_Text(propertyBase, Value='  ', YSize=1, XSize=40, /Editable)
  isTimeBase = Widget_Base(propertyBase, /Row, /NonExclusive)
  isTimeButton = Widget_Button(isTimeBase, Value='Is Time')  
  markercontrolButton = Widget_Button(controlsBase, $
    Value='Marker controls range of data displayed in other panels')  
  placeLabel = Widget_Label(placementBase, Value='Placement:', /Align_Left)
  placeFrameBase = Widget_Base(placementBase, Frame=3, /Col, XPad=4, YPad=4)
  startBase = Widget_Base(placeFrameBase, /Row)
  startLabel = Widget_Label(startBase, Value='Start at: ')
  startText = Widget_Text(startBase, Value='  ', XSize=15, YSize=1, /Editable)
  endBase = Widget_Base(placeFrameBase, /Row)
  endLabel = Widget_Label(endBase, Value='End at:  ')
  endText = Widget_Text(endBase, Value='  ', XSize=15, YSize=1, /Editable)
  verticalValues = ['Top', 'Near Top', 'Above Middle', 'Middle', 'Below Middle', $
    'Near Bottom','Bottom']
  vdBase = widget_base(placeFrameBase, /row)
  vdLabel = widget_base(vdBase, value = 'Vertical: ')
  verticalDroplist = Widget_combobox(vdBase, Value=verticalValues)
  appearanceLabel = Widget_Label(appearanceBase, Value='Appearance: ', /align_left)
  appearBase = Widget_Base(appearanceBase, /Col, Frame=3, YPad=1, XPad=4)
  paletteBase = Widget_Base(appearBase, /Row, XPad=4)
  colorLabel = Widget_Label(paletteBase, Value='Color:  ')
  palettebmp = filepath('palette.bmp', Subdir=['resource', 'bitmaps'])
  paletteButton = Widget_Button(paletteBase, Value=palettebmp, /Bitmap, UValue='PALETTE', $
    Tooltip='Choose color from Palette')
  borderBase = Widget_Base(appearBase, /Row)
  borderButtonBase = Widget_Base(borderBase, /NonExclusive)
  lineBase = Widget_Base(borderBase, /Row)
  borderButton = Widget_Button(borderButtonBase, Value='Draw Borders ')
  lineValues = [' solid ', ' dashed  ', 'dotted']
  ldLabel = widget_label(lineBase, value = 'Line Style: ')
  lineDroplist = Widget_combobox(lineBase, Sensitive=0, $
    Value=lineValues)
  opaqueBase = Widget_Base(appearBase, /NonExclusive)
  opaqueButton = Widget_Button(opaqueBase, Value = 'Draw Opaque')
 
  okButton = Widget_Button(buttonBase, Value=' OK ', UValue='OK', XSize=80, $
    Tooltip='Applies the changes to the layout and closes the window')
  cancelButton = Widget_Button(buttonBase, Value=' Cancel ', UValue='CANC', XSize=80, $
    Tooltip='Cancels the operation and closes the window')
   
  state = {tlb:tlb, gui_id:gui_id, historywin:historywin}

  Widget_Control, tlb, Set_UValue=state, /No_Copy
  Widget_Control, tlb, /Realize
  XManager, 'spd_ui_marker_options', tlb, /No_Block
  
RETURN
END ;--------------------------------------------------------------------------------
