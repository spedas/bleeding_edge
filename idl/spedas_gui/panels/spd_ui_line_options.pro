 ;+
 ;NAME:
 ; spd_ui_line_options
 
 ;PURPOSE:
 ; A widget interface for modifying line attributes
 ;
 ;CALLING SEQUENCE:
 ; spd_uifile, gui_id
 ;
 ;INPUT:
 ; gui_id = the id number of the widget that calls this
 ;
 ;OUTPUT:
 ;
 ;
 ;HISTORY:
 ;$LastChangedBy: jwl $
 ;$LastChangedDate: 2022-03-08 13:43:52 -0800 (Tue, 08 Mar 2022) $
 ;$LastChangedRevision: 30662 $
 ;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_line_options.pro $
 ;
 ;---------------------------------------------------------------------------------
 

 ; The following function spd_ui_line_options_show_hide
 ; enables (show_or_hide=1) or disables (show_or_hide=0) the line options
 pro spd_ui_line_options_show_hide, tlb, state, show_or_hide
   ;lineMirrorButtonid = widget_info(tlb, find_by_uname='mirror')
   lpaletteButtonid = widget_info(tlb, find_by_uname='palette')
   linestyleDroplistid = widget_info(tlb, find_by_uname='linestyle')
   lineThickIncrementid = widget_info(tlb, find_by_uname='thickness')
   drawButtonBaseid = widget_info(tlb, find_by_uname='drawButtonBase')
   
   if show_or_hide   then begin
     state.statusBar->Update, 'Line Options: Show Line turned on.'
     ;widget_control, lineMirrorButtonid, sensitive=1
     widget_control, lpaletteButtonid, sensitive=1
     widget_control, linestyleDroplistid, sensitive=1
     widget_control, lineThickIncrementid, sensitive=1
     widget_control, drawButtonBaseid, sensitive=1
   endif else begin
     state.statusBar->Update, 'Line Options: Show Line turned off.'
     ;widget_control, lineMirrorButtonid, sensitive=0
     widget_control, lpaletteButtonid, sensitive=0
     widget_control, linestyleDroplistid, sensitive=0
     widget_control, lineThickIncrementid, sensitive=0
     widget_control, drawButtonBaseid, sensitive=0
   endelse
   
 end
 
 ; The following function spd_ui_symbol_options_show_hide
 ; enables (show_or_hide=1) or disables (show_or_hide=0) the line options
 pro spd_ui_symbol_options_show_hide, tlb, state, show_option
   fillsymbolid = widget_info(tlb, find_by_uname='fillsymbol')
   palette1Buttonid = widget_info(tlb, find_by_uname='palette1')
   symbolstyleid = widget_info(tlb, find_by_uname='symbolstyle')
   symbolsizeid = widget_info(tlb, find_by_uname='symbolsize')
   plot1Baseid = widget_info(tlb, find_by_uname='plot1Base')
   
   if show_option then begin
     state.statusBar->Update, 'Symbol Options: Show Symbol turned on.'
     widget_control, fillsymbolid, sensitive=1
     widget_control, palette1Buttonid, sensitive=1
     widget_control, symbolstyleid, sensitive=1
     widget_control, symbolsizeid, sensitive=1
     widget_control, plot1Baseid, sensitive=1
   endif else begin
     state.statusBar->Update, 'Symbol Options: Show Symbol turned off.'
     widget_control, fillsymbolid, sensitive=0
     widget_control, palette1Buttonid, sensitive=0
     widget_control, symbolstyleid, sensitive=0
     widget_control, symbolsizeid, sensitive=0
     widget_control, plot1Baseid, sensitive=0
   endelse
   
 end
 
 pro spd_ui_init_line_panel, tlb, state=state
 
   compile_opt idl2, hidden
   
   statedef = ~(~size(state,/type))
   ;
   if ~statedef then begin
     Widget_Control, tlb, Get_UValue=state, /No_Copy  ;Only get STATE if it is not passed in.
   endif else begin
     tlb = state.tlb
   endelse
   
   ; if there are no traces desensitize the trace text field
   tracetextid = widget_info(tlb, find_by_uname='tracename')
   if ~obj_valid(*state.ctrace) then begin
     widget_control, tracetextid, sensitive = 0
   endif else widget_control, tracetextid, sensitive = 1
   
   ;if selected trace is spectra then desensitize line options
   if ~obj_valid(*state.ctrace) || obj_isa(*state.ctrace, 'spd_ui_spectra_settings') then begin
   
     widget_control, state.subMainLineBase, sensitive=0
     ;    widget_control, state.subMainLineBaseRight, sensitive=0
     if ~statedef then Widget_Control, tlb, Set_UValue=state, /No_Copy   ;Only put STATE if it was not passed in.
     RETURN
   endif else begin
     widget_control, state.subMainLineBase, sensitive = 1
   endelse
   
   
   
   ;****** Line Options **********************************************************
   id = widget_info(tlb, find_by_uname = 'showline')
   *state.ctrace->GetProperty, LineStyle=lineStyleObj
   lineStyleObj->GetProperty, Show=value
   widget_control, id, set_button = value
   spd_ui_line_options_show_hide, tlb, state, value
   
;   id = widget_info(tlb, find_by_uname = 'mirror')
;   *state.ctrace->GetProperty, mirrorline=value
;   widget_control, id, set_button = value
   
   ; intialize color window
   *state.ctrace->GetProperty, LineStyle=lineStyleObj
   lineStyleObj->GetProperty, color=value
   Widget_Control, state.lcolorWindow, Get_Value=lcolorWin
   if obj_valid(scene) then scene->remove,/all
   scene=obj_new('IDLGRSCENE', color=value)
   lcolorWin->draw, scene
   
   id = widget_info(tlb, find_by_uname = 'linestyle')
   *state.ctrace->GetProperty, LineStyle=lineStyleObj
   lineStyleObj->GetProperty, id=value
   widget_control, id, set_combobox_select = value
   
   id = widget_info(tlb, find_by_uname = 'thickness')
   *state.ctrace->GetProperty, LineStyle=lineStyleObj
   lineStyleObj->GetProperty, thickness=value
   widget_control, id, set_value = value
   
   
   ;****** Symbol Options ********************************************************
   id = widget_info(tlb, find_by_uname = 'showsymbol')
   *state.ctrace->GetProperty, symbol=symbolObj
   symbolObj->GetProperty, show=value
   widget_control, id, set_button = value
   spd_ui_symbol_options_show_hide, tlb, state, value
   
   id = widget_info(tlb, find_by_uname = 'fillsymbol')
   *state.ctrace->GetProperty, symbol=symbolObj
   symbolObj->GetProperty, fill=value
   widget_control, id, set_button = value
   
   ; intialize color window
   *state.ctrace->GetProperty, symbol=symbolObj
   symbolObj->GetProperty, color=value
   Widget_Control, state.scolorWindow, Get_Value=scolorWin
   if obj_valid(scene) then scene->remove,/all
   scene=obj_new('IDLGRSCENE', color=value)
   scolorWin->draw, scene
   
   id = widget_info(tlb, find_by_uname = 'symbolstyle')
   *state.ctrace->GetProperty, symbol=symbolObj
   symbolObj->GetProperty, id=value
   widget_control, id, set_combobox_select = value-1
   
   id = widget_info(tlb, find_by_uname = 'symbolsize')
   *state.ctrace->GetProperty, symbol=symbolObj
   symbolObj->GetProperty, size=value
   widget_control, id, set_value = value
   
   
   ;****** Symbol Frequency ******************************************************
   *state.ctrace->GetProperty, PlotPoints=value
   CASE value OF
     0: BEGIN
       id = widget_info(tlb, find_by_uname = 'allpoints')
       Widget_Control, state.everyBase, sensitive=0
     END
     1: BEGIN
       id = widget_info(tlb, find_by_uname = 'firstlast')
       Widget_Control, state.everyBase, sensitive=0
     END
     2: BEGIN
       id = widget_info(tlb, find_by_uname = 'first')
       Widget_Control, state.everyBase, sensitive=0
     END
     3: BEGIN
       id = widget_info(tlb, find_by_uname = 'last')
       Widget_Control, state.everyBase, sensitive=0
     END
     4: BEGIN
       id = widget_info(tlb, find_by_uname = 'majorticks')
       Widget_Control, state.everyBase, sensitive=0
     END
     5: BEGIN
       id = widget_info(tlb, find_by_uname = 'everypoint')
       Widget_Control, state.everyBase, sensitive=1
     END
   ENDCASE
   widget_control, id, /set_button
   
   id = widget_info(tlb, find_by_uname = 'everyinc')
   *state.ctrace->GetProperty, everyother=value
   Widget_Control, id, set_value=value
   
   
   ;****** Lines Between Points **************************************************
   id = widget_info(tlb, find_by_uname = 'drawbetween')
   *state.ctrace->GetProperty, drawBetweenPts=value
   widget_control, id, set_button = value
   
   if value then begin
     Widget_Control, state.drawLabel, /sensitive
     Widget_Control, state.drawText, /sensitive
     Widget_Control, state.drawDroplist, /sensitive
   endif else begin
     Widget_Control, state.drawLabel, sensitive=0
     Widget_Control, state.drawText, sensitive=0
     Widget_Control, state.drawDroplist, sensitive=0
   endelse
   
   id = widget_info(tlb, find_by_uname = 'drawdroplist')
   *state.ctrace->GetProperty, SeparatedUnits=value
   if obj_valid(*state.cpanel) then *state.cpanel->GetProperty, xAxis=xaxis
   if obj_valid(xaxis) then units = xaxis->GetUnits() else units = ['<none>']
   widget_control, id, set_value=units
   widget_control, id, set_combobox_select = value
   id = widget_info(tlb, find_by_uname = 'drawtext')
   *state.ctrace->GetProperty, SeparatedBy=value
   widget_control, id, set_value = strcompress(string(value), /remove_all)
      
   if ~statedef then Widget_Control, tlb, Set_UValue=state, /No_Copy   ;Only put STATE if it was not passed in.
 end
 
 ; helper function to add a number to the beginning of trace names and truncate.
 ; This avoids the problem of identical traces in the combobox, and the problem on x11 systems of the
 ; combobox down arrow getting pushed out of view by long traces.
 function spd_ui_line_options_truncate_trace_names, tracenames
 
   for traceit = 0, n_elements(tracenames)-1 do begin
     traceNames[traceit] = strtrim(string(traceit +1),2)+traceNames[traceit]
     if strlen(traceNames[traceit]) GT 65 then traceNames[traceit]=strmid(traceNames[traceit], 0, 65)+'...'
   endfor
   return, tracenames
 end
 
 ; helper function to get the full trace name (rather than the truncated version stored in the combobox)
 function spd_ui_line_options_get_full_trace_names, panelobj
   if obj_valid(panelobj) then begin
     panelobj->getProperty,traceSettings=traceSettingscur
     tracescur = traceSettingscur->get(/all)
     if obj_valid(tracescur[0]) then begin
       ntrcur = n_elements(tracescur)
       if ntrcur gt 0 then begin
         fulltrNames = panelobj->constructTraceNames()
       endif else fulltrNames = 'No Traces'
     endif else fulltrnames = 'No Traces'
   endif else fulltrNames = 'No Traces'
   return, fulltrNames
 end
 
 ; Issue messages to user and reset spinner values that are non numeric or negative.
 ; Valid entries are currently handled as soon as user enters them.
 ; Intended to be called when user clicks Apply/OK/Save to template.
 pro spd_ui_line_options_check_spinners, ctrace,topid
 
   ;Don't check spinners if it is a spectra
   if obj_valid(ctrace) && ~obj_isa(ctrace, 'spd_ui_spectra_settings') then begin
     ; Only produce a dialog box if spinners values will actually matter - i.e spinners sensitized
     showmessage = 1
     ; Separated by value
     ctrace->GetProperty, drawBetweenPts=drawset
     showmessage = drawset
     id = widget_info(topid, find_by_uname='drawtext')
     widget_control, id, get_value=current_drawtext
     ctrace->GetProperty, SeparatedBy=prev_drawtext
     if finite(current_drawtext, /nan) then begin
       if showmessage then begin
         messageString = 'Invalid Separated by value entered; value reset.'
         response=dialog_message(messageString,/CENTER)
       endif
       widget_control,id,set_value=prev_drawtext
     endif else if current_drawtext lt 0 then begin
       if showmessage then begin
         messageString = 'Separated by value must be greater than 0; value set to 0.'
         response=dialog_message(messageString,/CENTER)
       endif
       widget_control,id,set_value=0
       ctrace->SetProperty, SeparatedBy=0
     endif
     ; thickness
     id = widget_info(topid, find_by_uname='thickness')
     widget_control, id, get_value=current_thickness
     ctrace->GetProperty, LineStyle=lineStyleObj
     lineStyleObj->GetProperty, Thickness=prevThickness, Show=showline
     showmessage = showline
     if finite(current_thickness, /nan) then begin
       if showmessage then begin
         messageString = 'Invalid thickness value entered; value reset.'
         response=dialog_message(messageString,/CENTER)
       endif
       widget_control,id,set_value=prevThickness
     endif else if current_thickness lt 1 then begin
       if showmessage then begin
         messageString = 'Thickness must be greater than 0; value set to 1.'
         response=dialog_message(messageString,/CENTER)
       endif
       widget_control,id,set_value=1
       lineStyleObj->SetProperty, Thickness=1
     endif else if current_thickness gt 10 then begin
       if showmessage then begin
         messageString = 'Maximum line thickness is 10.'
         response=dialog_message(messageString,/CENTER)
       endif
       widget_control, id, set_value=10
       lineStyleObj->SetProperty, Thickness=10
     endif
     ; symbol size
     id = widget_info(topid, find_by_uname='symbolsize')
     widget_control, id, get_value=current_symbolsize
     ctrace->GetProperty, symbol=symbolObj
     IF Obj_Valid(symbolObj) THEN begin
       symbolObj->GetProperty, Size=prev_symbolsize, show=showsymbol
       showmessage=showsymbol
       if finite(current_symbolsize, /nan) then begin
         if showmessage then begin
           messageString = 'Invalid symbol size entered; value reset.'
           response = dialog_message(messageString, /CENTER)
         endif
         widget_control, id, set_value=prev_symbolsize
       endif else if current_symbolsize lt 1 then begin
         if showmessage then begin
           messageString = 'Symbol size must be greater than 0; value set to 1.'
           response = dialog_message(messageString, /CENTER)
         endif
         widget_control, id, set_value=1
         symbolObj->SetProperty, Size=1
       endif
     endif else widget_control,id,set_value=''
     
     ; symbol frequency
     id = widget_info(topid, find_by_uname='everyinc')
     widget_control, id, get_value=current_everyinc
     ctrace->GetProperty, EveryOther=prev_everyinc, PlotPoints=pointsetting
     if pointsetting eq 5 then showmessage=1 else showmessage=0
     if finite(current_everyinc, /nan) then begin
       if showmessage then begin
         messageString = 'Invalid symbol frequency; value reset.'
         response = dialog_message(messageString, /CENTER)
       endif
       widget_control, id, set_value=prev_everyinc
     endif else if current_everyinc lt 1 then begin
       if showmessage then begin
         messageString = 'Symbol Frequency: Every point values must be positive; value set to 1.'
         response = dialog_message(messageString, /CENTER)
       endif
       widget_control, id, set_value=1
       ctrace->SetProperty, everyother=1
     endif
   endif
   
   
 end
 
 pro  spd_ui_line_options_applyall, ctrace, ctraces, applyall_error=applyall_error
 ; applies all values from current line to all lines of current panel
 ; values applied are: line thickness, show line, show symbol, symbol size, symbol filled, symbol frequency, gapsize
 ; operates by copying from current line to all other lines of the same panel
  
  ntr = n_elements(ctraces)
  if ntr lt 2 then begin 
    applyall_error = 1
    return
  endif else applyall_error = 0
  
  ; Get values of current line
  ctrace->GetProperty, LineStyle=lineStyleObj0, symbol=symbolObj0, $
    PlotPoints=read_plotpoints, EveryOther=read_every, drawBetweenPts=read_drawbetween, SeparatedUnits=read_sepU, SeparatedBy=read_sepBy
  lineStyleObj0->GetProperty, Thickness=read_thickness, Show=read_show  
  symbolObj0->GetProperty, show=read_symbshow, size=read_size, fill=read_fill
    
  ; Set values of all lines  
  for i=0,ntr-1 do begin 
     if obj_valid((ctraces)[i]) then begin
       ctracen=(ctraces)[i]
       
       ctracen->GetProperty, LineStyle=lineStyleObj, symbol=symbolObj
       lineStyleObj->SetProperty, Thickness=read_thickness, Show=read_show       
       symbolObj->SetProperty, show=read_symbshow, size=read_size, fill=read_fill       
       
       ctracen->SetProperty, PlotPoints=read_plotpoints, $
        EveryOther=read_every, drawBetweenPts=read_drawbetween, SeparatedUnits=read_sepU, SeparatedBy=read_sepBy
     endif
  endfor
 
 end
 
 
 PRO spd_ui_line_options_event, event
 
   Compile_Opt hidden
   
   Widget_Control, event.TOP, Get_UValue=state, /No_Copy
   
   ;Put a catch here to insure that the state remains defined
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error in Line Options'
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
   ;kill request block
   
   IF (Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN
   
     ;Redraw:
     ;*******
     ;
     state.origWindow->GetProperty, panels=origPanels
     state.cWindow->SetProperty, panels=origPanels
     state.drawObject->update,state.windowStorage,state.loadedData
     state.drawObject->draw
     
     state.historyWin->Update,'SPD_UI_LINE_OPTIONS: Active window refreshed.'
     state.statusbar->Update,'Active window refreshed.'
     
     dprint, dlevel=4, 'Line Options widget killed'
     state.historyWin->Update,'SPD_UI_LINE_OPTIONS: Widget killed'
     Widget_Control, event.TOP, Set_UValue=state, /No_Copy
     Widget_Control, event.top, /Destroy
     RETURN
     
   ENDIF
   
   ;deal with tabs
   
   IF (Tag_Names(event, /Structure_Name) EQ 'WIDGET_TAB') THEN BEGIN
     Widget_Control, event.TOP, Set_UValue=state, /No_Copy
     RETURN
   ENDIF
   
   ; Get the instructions from the Widget causing the event and
   ; act on them.
   
   Widget_Control, event.id, Get_UValue=uval
   
   
   IF Size(uval, /Type) NE 0 THEN BEGIN
   
     state.historyWin->Update,'SPD_UI_LINE_OPTIONS: User value: '+uval,/dontshow
     
     CASE uval OF
     
       ;****** Line Bar **********************************************************
       'NEGATIVE': *state.ctrace->SetProperty, NegativeEndPt=state.dataNames[event.index]
       'POSITIVE': *state.ctrace->SetProperty, PositiveEndPt=state.dataNames[event.index]
       'RELNEGATIVE': *state.ctrace->SetProperty, NegativeEndRel=event.select
       'RELPOSITIVE': *state.ctrace->SetProperty, PositiveEndRel=event.select
       'SHOWBAR':  BEGIN
         result = Widget_Info(event.id, /Button_Set)
         *state.ctrace->GetProperty, BarLine=BarLineObj
         IF result EQ 0 THEN BEGIN
           Widget_Control, state.endFrameBase, Sensitive=0
           Widget_Control, state.styleFrameBase, Sensitive=0
           Widget_Control, state.endMarkFrameBase, Sensitive=0
           BarLineObj->SetProperty, Show=0
         ENDIF ELSE BEGIN
           Widget_Control, state.endFrameBase, Sensitive=1
           Widget_Control, state.styleFrameBase, Sensitive=1
           Widget_Control, state.endMarkFrameBase, Sensitive=1
           BarLineObj->SetProperty, Show=1
         ENDELSE
       END
       ;**************************************************************************
       
       ;****** Lines Between Points***********************************************
       'DRAWBETWEEN': BEGIN
         result = Widget_Info(event.id, /Button_Set)
         *state.ctrace->SetProperty, drawBetweenPts=result
         Widget_Control, state.drawLabel, sensitive=result
         Widget_Control, state.drawText, sensitive=result
         Widget_Control, state.drawDroplist, sensitive=result
         if result then state.statusBar->Update, 'Draw Between options activated.' $
         else state.statusBar->Update, 'Draw Between options de-activated.'
       END
       'DRAWDROPLIST': BEGIN
         if obj_valid(*state.cpanel) then *state.cpanel->GetProperty, xAxis=xaxis
         if obj_valid(xaxis) then units = xaxis->GetUnits()
         if N_Elements(units) gt 1 then value=event.index else value=4
         *state.ctrace->SetProperty, SeparatedUnits=value
         state.statusBar->Update, "Separated by units updated."
       END
       'DRAWTEXT': BEGIN
         if event.valid then begin
           IF event.value LT 0 THEN BEGIN
             state.statusBar->Update, 'Separated by values must be positive. Please re-enter'
           ;delay handling this until user attempts to apply value
           ;widget_control,event.id,set_value=0
           ENDIF ELSE BEGIN
             *state.ctrace->SetProperty, SeparatedBy=event.value
             state.statusBar->Update, 'Separated By value updated.'
           ENDELSE
         endif else if ~finite(event.value, /nan) then begin
           state.statusBar->Update, 'Separated by values must be positive.'
         endif else state.statusBar->update, 'Invalid Separated By value, please re-enter.'
       END
       
       ;****** Line Options ******************************************************
       'LINESTYLE': BEGIN
         *state.ctrace->GetProperty, LineStyle=lineStyleObj
         styleNames = lineStyleObj->GetLineStyles()
         lineStyleObj->SetProperty, Id=event.index, Name=styleNames[event.index]
         state.statusBar->Update, 'Line Options: Style updated.'
       END
       'MIRROR': BEGIN
         *state.ctrace->SetProperty, MirrorLine=event.select
         if event.select then state.statusBar->Update, 'Line Options: Mirror turned on.' $
         else state.statusBar->Update, 'Line Options: Mirror turned off.'
       END
       'PALETTE': BEGIN
         *state.ctrace->GetProperty, LineStyle=lineStyleObj
         lineStyleObj->GetProperty, Color=currentcolor
         color = PickColor(!P.Color, Group_Leader=state.tlb, Cancel=cancelled, $
           currentcolor=currentcolor)
         if cancelled then begin
           color=currentcolor
           state.statusBar->Update, 'Line Options: Color unchanged.'
         endif else state.statusBar->Update, 'Line Options: Color updated.'
         lineStyleObj->SetProperty, Color=color
         Widget_Control, state.lcolorWindow, Get_Value=lcolorWin
         if obj_valid(scene) then scene->remove,/all
         scene=obj_new('IDLGRSCENE', color=reform(color))
         lcolorWin->draw, scene
         *state.cpanel->SyncLabelsToLines
       END
       'SHOWLINE': BEGIN
         *state.ctrace->GetProperty, LineStyle=lineStyleObj
         lineStyleObj->SetProperty, Show=event.select
         ;if event.select then state.statusBar->Update, 'Line Options: Show Line turned on.' $
         ;else state.statusBar->Update, 'Line Options: Show Line turned off.'
         
         if event.select then spd_ui_line_options_show_hide, state.tlb,  state, 1 $
         else spd_ui_line_options_show_hide, state.tlb, state, 0
         
       END
       ;      'SYNC': BEGIN
       ;        *state.cpanel->SetProperty, SyncFlag=event.select
       ;        if event.select then state.statusBar->Update, 'Line Options: Sync Labels to Lines turned on.' $
       ;          else state.statusBar->Update, 'Line Options: Sync Labels to Lines turned off.'
       ;      END
       'THICKNESS': BEGIN
         *state.ctrace->GetProperty, LineStyle=lineStyleObj
         if event.valid then begin
           IF event.value LT 0 THEN BEGIN
             state.statusBar->Update, 'Line thickness values must be positive. Please re-enter'
           ;Delay handling until user changes panels or clicks apply/ok
           ;lineStyleObj->GetProperty, Thickness=prevThickness
           ;widget_control, event.id, set_value=prevThickness
           endif else if event.value gt 10 then begin
             state.statusBar->Update, 'Maximum line thickness is 10.'
           ENDIF ELSE BEGIN
             lineStyleObj->SetProperty, Thickness=event.value
             state.prevThickness=event.value
             state.statusBar->Update, 'Line Options: Thickness updated.'
           ENDELSE
         endif else if finite(event.value, /nan) then begin
           state.statusBar->update, 'Invalid thickness, please re-enter.'
         ; Delay handling
         ;lineStyleObj->GetProperty, Thickness=prevThickness
         ;widget_control, event.id, set_value=prevThickness
         endif else begin
           state.statusBar->update, 'Line thickness values must be between 1 and 10.'
         endelse
       END
       ;**************************************************************************
       
       
       ;****** Line Bar End Mark *************************************************
       'EMTHICKNESS': BEGIN
         widget_control,event.id,get_value=value
         IF value LT 0 THEN BEGIN
           state.statusBar->Update, 'Line thickness values must be positive. Please re-enter'
           widget_control,event.id,set_value=''
         ENDIF ELSE BEGIN
           *state.ctrace->GetProperty, BarLine=barline
           barline->SetProperty, Thickness=value
           state.prevemthick=value
           state.statusBar->Update, 'Line thickness value updated.'
         ENDELSE
       END
       'PALETTE3': BEGIN
         *state.ctrace->GetProperty, MarkSymbol=lineStyleObj
         lineStyleObj->GetProperty, Color=currentcolor
         color = PickColor(!P.Color, Group_Leader=state.tlb, Cancel=cancelled, $
           currentcolor=currentcolor)
         if cancelled then color=currentcolor
         lineStyleObj->SetProperty, Color=color
         Widget_Control, state.mcolorWindow, Get_Value=mcolorWin
         if obj_valid(scene) then scene->remove,/all
         scene=obj_new('IDLGRSCENE', color=reform(color))
         mcolorWin->draw, scene
         *state.cpanel->GetProperty, SyncFlag=syncflag
         IF syncflag EQ 1 THEN *state.cpanel->SyncLabelsToLines
       END
       ;**************************************************************************
       
       
       ;****** Line Bar Line Style ***********************************************
       'LSTHICKNESS': BEGIN
         IF event.value LT 0 THEN BEGIN
           state.statusBar->Update, 'Line thickness values must be positive. Please re-enter'
           widget_control,event.id,set_value=''
         ENDIF ELSE BEGIN
           *state.ctrace->GetProperty, BarLine=lineStyleObj
           lineStyleObj->SetProperty, Thickness=event.value
           state.statusBar->Update, 'Line thickness value updated.'
           prevlsthick=event.value
         ENDELSE
       END
       'PALETTE2': BEGIN
         *state.ctrace->GetProperty, BarLine=lineStyleObj
         lineStyleObj->GetProperty, Color=currentcolor
         color = PickColor(!P.Color, Group_Leader=state.tlb, Cancel=cancelled, $
           currentcolor=currentcolor)
         if cancelled then color=currentcolor
         lineStyleObj->SetProperty, Color=color
         Widget_Control, state.lscolorWindow, Get_Value=lscolorWin
         if obj_valid(scene) then scene->remove,/all
         scene=obj_new('IDLGRSCENE', color=reform(color))
         lscolorWin->draw, scene
       END
       
       ;**************************************************************************
       
       
       ;****** Symbol Options ****************************************************
       'FILLSYMBOL': BEGIN
         *state.ctrace->GetProperty, symbol=symbolObj
         symbolObj->SetProperty, fill=event.select
         if event.select then state.statusBar->Update, 'Symbol Options: Filled turned on.' $
         else state.statusBar->Update, 'Symbol Options: Filled turned off.'
         
         
       END
       'PALETTE1': BEGIN
         *state.ctrace->GetProperty, Symbol=symbolObj
         symbolObj->GetProperty, Color=currentcolor
         color = PickColor(!P.Color, Group_Leader=state.tlb, Cancel=cancelled, $
           currentcolor=currentcolor)
         if cancelled then begin
           color=currentcolor
           state.statusBar->Update, 'Symbol Options: Color unchanged.'
         endif else state.statusBar->Update, 'Symbol Options: Color updated.'
         
         symbolObj->SetProperty, Color=color
         Widget_Control, state.scolorWindow, Get_Value=scolorWin
         if obj_valid(scene) then scene->remove,/all
         scene=obj_new('IDLGRSCENE', color=reform(color))
         scolorWin->draw, scene
       END
       'SHOWSYMBOL': BEGIN
         *state.ctrace->GetProperty, symbol=symbolObj
         symbolObj->SetProperty, show=event.select
         ;if event.select then state.statusBar->Update, 'Symbol Options: Show Symbol turned on.' $
         ;else state.statusBar->Update, 'Symbol Options: Show Symbol turned off.'
         
         if event.select then spd_ui_symbol_options_show_hide, state.tlb, state, 1 $
         else spd_ui_symbol_options_show_hide, state.tlb, state, 0
         
       END
       'SYMBOLSIZE': BEGIN
         *state.ctrace->GetProperty, symbol=symbolObj
         if event.valid then begin
           IF event.value LT 1 THEN BEGIN
             state.statusBar->Update, 'Size values must be positive. Please re-enter'
           ; delay handling
           ;IF Obj_Valid(symbolObj) THEN begin
           ;symbolObj->GetProperty, Size=prevsize
           ;widget_control,event.id,set_value=prevsize
           ;endif else widget_control,event.id,set_value=''
           ENDIF ELSE BEGIN
             IF Obj_Valid(symbolObj) THEN symbolObj->SetProperty, Size=event.value
             prevSymbolSize=event.value
             state.statusBar->Update, 'Symbol Options: Size updated.'
           ENDELSE
         endif else if finite(event.value, /nan) then begin
           state.statusBar->update, 'Invalid symbol size, please re-enter.'        
         endif else begin
           state.statusBar->update, 'Size values must be positive.'
         endelse
       END
       'SYMBOLSTYLE': BEGIN
         *state.ctrace->GetProperty, symbol=symbolObj
         styleNames = symbolObj->GetSymbols()
         symbolObj->SetProperty, Id=event.index+1, Name=styleNames[event.index]
         state.statusBar->Update, 'Symbol Options: Style updated.'
       END
       ;**************************************************************************
       
       
       ;****** Symbol Frequency **************************************************
       'ALLPOINTS': BEGIN
         *state.ctrace->SetProperty, PlotPoints=0
         Widget_Control, state.everyBase, sensitive=0
         state.statusBar->Update, 'Symbol Frequency: All points selected.'
       END
       'FIRSTLAST': BEGIN
         *state.ctrace->SetProperty, PlotPoints=1
         Widget_Control, state.everyBase, sensitive=0
         state.statusBar->Update, 'Symbol Frequency: First and last point selected.'
       END
       'FIRST': BEGIN
         *state.ctrace->SetProperty, PlotPoints=2
         Widget_Control, state.everyBase, sensitive=0
         state.statusBar->Update, 'Symbol Frequency: First point selected.'
       END
       'LAST': BEGIN
         *state.ctrace->SetProperty, PlotPoints=3
         Widget_Control, state.everyBase, sensitive=0
         state.statusBar->Update, 'Symbol Frequency: Last point selected.'
       END
       'MAJORTICKS': BEGIN
         *state.ctrace->SetProperty, PlotPoints=4
         Widget_Control, state.everyBase, sensitive=0
         state.statusBar->Update, 'Symbol Frequency: Major ticks selected.'
       END
       'EVERYINC': BEGIN
         *state.ctrace->GetProperty, EveryOther=prevEvery
         if event.valid then begin
           IF event.value LT 1 THEN BEGIN
             state.statusBar->Update, 'Symbol Frequency: Every point values must be positive. Please re-enter.'
           ; Delay handling
           ;widget_control,event.id,set_value='1'
           ENDIF ELSE BEGIN
             *state.ctrace->SetProperty, EveryOther=event.value
             state.statusBar->Update, 'Symbol Frequency: Every point value updated.'
             prevInc=event.value
           ENDELSE
         endif else if finite(event.value, /nan) then begin
           state.statusBar->update, 'Invalid symbol frequency, please re-enter.'
         ; Delay handling
         ;widget_control, event.id, set_value=prevEvery
         endif else begin
           state.statusBar->update, 'Symbol Frequency: Every point values must be positive.'
         endelse
       END
       'EVERYPOINT': BEGIN
         *state.ctrace->SetProperty, PlotPoints=5
         Widget_Control, state.everyBase, sensitive=1
         state.statusBar->Update, 'Symbol Frequency: Every point selected.'
       END
       ;**************************************************************************
       
       
       'APPLY': BEGIN
         if ptr_valid(state.ctrace) && obj_valid(*state.ctrace) then begin
           ; check spinner entries are valid
           spd_ui_line_options_check_spinners, *state.ctrace,state.tlb
           ;Sync labels:        ;
           ;        *state.cpanel->GetProperty, SyncFlag=syncflag
           if ptr_valid(state.cpanel) && obj_valid(*state.cpanel) then begin
             *state.cpanel->SyncLabelsToLines
           endif
           
           state.drawObject->update,state.windowStorage,state.loadedData
           state.drawObject->draw
           state.historyWin->Update, 'SPD_UI_LINE_OPTIONS: Changes applied.'
           state.statusBar->Update, 'Changes applied.'
         endif else begin
           state.historywin->update,'No Traces Available, changes could not be applied'
           state.statusBar->update,'No Traces Available, changes could not be applied'
         endelse
         
       END
       'APPLYTOALL': BEGIN
        
         if ptr_valid(state.ctrace) && obj_valid(*state.ctrace) then begin
           ; check spinner entries are valid
           spd_ui_line_options_check_spinners, *state.ctrace,state.tlb
           
           spd_ui_line_options_applyall, *state.ctrace, *state.ctraces, applyall_error=applyall_error
           
           
           ;Sync labels:        ;
           if ptr_valid(state.cpanel) && obj_valid(*state.cpanel) then begin
             *state.cpanel->SyncLabelsToLines
           endif
           
           state.drawObject->update,state.windowStorage,state.loadedData
           state.drawObject->draw

           if applyall_error eq 1 then begin
            state.historyWin->Update, 'SPD_UI_LINE_OPTIONS: This panel contains no lines to copy changes to.'
            state.statusBar->Update, 'This panel contains no lines to copy changes to.'            
           endif else begin
             state.historyWin->Update, 'SPD_UI_LINE_OPTIONS: Changes applied to all lines.'
             state.statusBar->Update, 'Changes applied to all lines.'            
           endelse
         endif else begin
           state.historywin->update,'No Traces Available, changes could not be applied'
           state.statusBar->update,'No Traces Available, changes could not be applied'
         endelse       
        
        END
        'SETALL': BEGIN
          ; check spinner entries are valid
          spd_ui_line_options_check_spinners, *state.ctrace,state.tlb
          widget_control, state.drawText, get_value=sepBy
          result = Widget_Info(state.drawButtonButton, /Button_Set)
          *state.ctrace->GetProperty, SeparatedUnits=sepU
          if obj_valid((*state.ctraces)[0]) then begin
            ntr = n_elements(*state.ctraces)
            for i=0,ntr-1 do begin
              ctrace=(*state.ctraces)[i]
              ctrace->SetProperty, drawBetweenPts=result, SeparatedUnits=sepU, $
                SeparatedBy=sepBy
            endfor
            state.statusBar->Update, 'Draw Between settings set for all traces in panel.'
          endif
        END
        ;**************************************************************************
       'CANC': BEGIN
         state.origWindow->GetProperty, panels=origPanels
         state.cWindow->SetProperty, panels=origPanels
         state.drawObject->update,state.windowStorage,state.loadedData
         state.drawObject->draw
         dprint, dlevel=4, 'Line Options widget cancelled. No changes made.'
         state.historyWin->Update, 'SPD_UI_LINE_OPTIONS: Line Options window cancelled. No changes made.'
         state.tlb_statusbar->Update,'Line Options cancelled'
         Widget_Control, event.TOP, Set_UValue=state, /No_Copy
         Widget_Control, event.top, /destroy
         RETURN
       END
       'OK': BEGIN
         if ptr_valid(state.ctrace) && obj_valid(*state.ctrace) then begin
           ; check spinner entries are valid
           spd_ui_line_options_check_spinners, *state.ctrace,state.tlb
         endif
         state.drawObject->update,state.windowStorage,state.loadedData
         state.drawObject->draw
         dprint, dlevel=4, 'Line options update. Line Options widget closed.'
         state.historyWin->Update, 'SPD_UI_LINE_OPTIONS: Line options update. Line Options widget closed.'
         state.tlb_statusbar->Update,'Line Options closed'
         Widget_Control, event.TOP, Set_UValue=state, /No_Copy
         Widget_Control, event.top, /destroy
         RETURN
       END
       'TEMP': begin
       
         if ptr_valid(state.ctrace) && obj_valid(*state.ctrace) then begin
           ; check spinner entries are valid
           spd_ui_line_options_check_spinners, *state.ctrace,state.tlb
           lsettings = (*state.ctrace)->copy()
           lsettings->setProperty,dataX='',dataY=''
           state.template->setProperty,line=lsettings
           state.historywin->update,'Current line options stored for use in a Template'
           state.statusBar->update,'Current line options stored for use in a Template'
          
           messageString = 'These values have now been stored!' +  string(10B) + string(10B) + 'To save them in a template, click File->Graph Options Template->Save Template'
           response=dialog_message(messageString,/CENTER, /information)
          
         endif else begin
           state.historywin->update,'Cannot store options. Needs a valid trace object to store options for a template.'
           state.statusBar->update,'Cannot store options. Needs a valid trace object to store options for a template.'
         endelse
       end
       'PANELLIST': BEGIN
         pindex = widget_info(state.panelDroplist, /combobox_gettext)
         widget_control, state.panelDroplist, get_value = pindexval
         pindex = where(pindexval eq pindex)
         if ptr_valid(state.ctrace) && obj_valid(*state.ctrace) then begin
           ; check spinner entries are valid
           spd_ui_line_options_check_spinners, *state.ctrace,state.tlb
         endif
         if ptr_valid(state.panelObjs) && n_elements(*state.panelObjs) ge pindex && obj_valid((*state.panelObjs)[pindex]) then begin
           cpanel = (*state.panelObjs)[pindex]
           
           cpanel->getProperty,traceSettings=traceSettings, XAxis=xaxis
           traces = traceSettings->get(/all)
           
           if obj_valid(traces[0]) then begin
             trNames = cPanel->constructTraceNames()
             trNames = spd_ui_line_options_truncate_trace_names(trNames)
             
             traces[0]->getProperty, dataX=dataX, dataY=dataY
             ctrace = traces[0]
             
             if obj_isa(traces[0],'spd_ui_spectra_settings') then begin
             
               traces[0]->getProperty,dataZ=dataZ
             endif else begin
               dataZ = ''
             endelse
             
           endif else begin
             trNames = 'No Traces'
           endelse
           
           
           widget_control, state.traceDroplist, set_value = trNames
           widget_control, state.traceDroplist, set_combobox_select = 0
           tracetextid = widget_info(event.top, find_by_uname='tracename')
           fulltrNames = spd_ui_line_options_get_full_trace_names(cpanel)
           widget_control, tracetextid, set_value = fulltrNames[0]
           
           *state.cpanel_num = pindex
           *state.ctr_num = 0
           
           if ptr_valid(state.cpanel) then ptr_free, state.cpanel
           state.cpanel = ptr_new(cpanel)
           if ptr_valid(state.ctraces) then ptr_free, state.ctraces
           state.ctraces = ptr_new(traces)
           if ptr_valid(state.ctrace) then ptr_free, state.ctrace
           state.ctrace = ptr_new(ctrace)
           
           spd_ui_init_line_panel, state=state
           
           state.statusBar->Update, 'Panel selection changed.'
         endif
         
       END
       'TRACELIST': BEGIN
         pindex = widget_info(state.traceDropList, /combobox_gettext)
         widget_control, state.tracedroplist, get_value = pindexval
         pindex = where(pindexval eq pindex)
         if ptr_valid(state.ctrace) && obj_valid(*state.ctrace) then begin
           ; check spinner entries are valid
           spd_ui_line_options_check_spinners, *state.ctrace,state.tlb
         endif
         ;in case combobox has identical entries
         if n_elements(pindex) gt 1 then begin
           pindex = event.index
         endif
         tracetextid = widget_info(event.top, find_by_uname='tracename')
         if ptr_valid(state.panelObjs) && obj_valid((*state.panelObjs)[*state.cpanel_num]) then begin
           cpanel = (*state.panelObjs)[*state.cpanel_num]
           fulltrNames = spd_ui_line_options_get_full_trace_names(cpanel)
         endif else fulltrNames = 'No Traces'
         widget_control, tracetextid, set_value = fulltrNames[pindex]
         if n_elements(*state.ctraces) gt 0 then begin ;when there are no traces *state.ctraces can be undefined
           if obj_valid((*state.ctraces)[pindex]) then begin
           
             (*state.ctraces)[pindex]->getProperty, dataX=dataX, dataY=dataY
             ctrace = (*state.ctraces)[pindex]
             
             if obj_isa((*state.ctraces)[pindex],'spd_ui_spectra_settings') then begin
             
               (*state.ctraces)[pindex]->getProperty,dataZ=dataZ
             endif else begin
             
               dataZ = ''
             endelse
             
           endif
           
           *state.ctr_num = pindex
           
           if ptr_valid(state.ctrace) then ptr_free, state.ctrace
           state.ctrace = ptr_new(ctrace)
           
           spd_ui_init_line_panel, state=state
           
           state.statusBar->Update, 'Trace selection changed.'
         endif
       END
       ELSE: ;dprint,  ''
     ENDCASE
   ENDIF
   
   Widget_Control, event.TOP, Set_UValue=state, /No_Copy
   
   RETURN
 END ;--------------------------------------------------------------------------------
 
 
 
 PRO spd_ui_line_options, gui_id, windowStorage, loadedData, historyWin, $
     drawObject, template, cpanel_num=cpanel_num, ctr_num=ctr_num, tlb_statusbar
     
   err_xxx = 0
   Catch, err_xxx
   IF(err_xxx Ne 0) THEN BEGIN
     Catch, /Cancel
     Help, /Last_Message, Output=err_msg
     FOR j = 0, N_Elements(err_msg)-1 DO Begin
       dprint, dlevel=1,  err_msg[j]
       If(obj_valid(historywin)) Then historyWin -> update, err_msg[j]
     Endfor
     dprint, dlevel=1, 'Error--See history'
     ok = error_message('An unknown error occured starting line options. See console for details.',$
       /noname, /center, title='Error in Line Options')
     spd_gui_error, gui_id, historywin
     RETURN
   ENDIF
   
   ;build top level and main tab bases
   tlb_statusBar->update,'Line Options opened'
   tlb = Widget_Base(/Col, title='Line Options', Group_Leader=gui_id, $
     /modal, /Floating, /TLB_KILL_REQUEST_EVENTS, tab_mode=1)
   mainBase = Widget_Base(tlb, /Col, /Align_Center)
   buttonStatusBase = Widget_Base(tlb, /Col, /Align_center)
   panelBase=Widget_Base(mainBase, /Col)
   lineBase = Widget_Base(mainBase, /Col)
   
   ; Line Tab Bases
   
   mainLineBase = Widget_Base(lineBase, /Col)
   dummy_base = Widget_Base(MainLineBase, /row)
   subMainLineBase = Widget_Base(Dummy_Base, /col, frame=3)
   traceBase = Widget_Base(submainlineBase, /col)
   subMainLineBase = widget_base(submainlinebase, /col, space=0)
   col1Base1 = Widget_Base(submainlineBase, /Col)
   optionsBase = Widget_Base(col1Base1, /Row)
   c1Base = Widget_Base(optionsBase, /col)
   r1c1Base = Widget_Base(c1Base, /row)
   r2c1Base = Widget_Base(c1Base, /row)
   c2Base = Widget_Base(optionsBase, /Row)
   lineOptionsBase = Widget_Base(r1c1Base, /Col)
   symbolOptionsBase = Widget_Base(r1c1Base, /Col)
   frequencyBase = Widget_Base(c2Base, /Col)
   drawBase = Widget_Base(r2c1Base, /Col, frame = 3, uname='drawButtonBase')
   
   if ~ptr_valid(cpanel_num) then cpanel_num = ptr_new(0)
   if ~ptr_valid(ctr_num) then ctr_num = ptr_new(0)
   
   ;retrieve data and panel info for display
   dataNames = loadedData->GetAll(/child)
   IF is_num(dataNames) THEN dataNames=''
   cWindow = windowStorage->GetActive()
   origWindow = cWindow->Copy()
   IF NOT Obj_Valid(cWindow) THEN BEGIN
     panelNames=['']
   ENDIF ELSE BEGIN
     cWindow->GetProperty, Panels=panels, nRows=nRows, nCols=nCols
     ;     cwindow->GetProperty, variables=variablescontainer
     ;     variablesobjects = variablescontainer->get(/all)
     IF NOT Obj_Valid(panels) THEN panelObjs=[''] ELSE panelObjs = panels->Get(/All)
   ENDELSE
   
   ; initialize drawUnits to none, if panel and axes are valid objects then units
   ; will be set later
   drawUnits = ['<none>']
   
   if obj_valid(panelObjs[0]) then begin
   
     npanels = n_elements(panelObjs)
     panelNames = strarr(npanels)
     panelTitles = panelNames
     
     for i = 0,npanels-1 do begin ; loop over panels
     
       cPanel = panelObjs[i]
       panelNames[i] = cPanel->constructPanelName()
       if i eq 0 then panelValue = cPanel->constructPanelName() $
       else panelValue = [panelValue, cPanel->constructPanelName()]
       
       if i eq 0 then panelLayout = cPanel->getLayoutStructure() $
       else panelLayout = [panelLayout, cPanel->getLayoutStructure()]
       
       ; NB: the panelLayout id is the number of the panel-1 (ie Panel 1 is 0). This does not necessarily
       ; start at 0, nor is it necessarily consecutive, if the user has deleted some panels.
       ; Trying to use just the panel number from the total number of panels instead.
       if i eq 0 then panelValueInfo = {panelListInfo, ispanel:1, istrace:0, $
         panelid:i, traceid:-1} $
       else panelValueInfo = [panelValueInfo, {panelListInfo, ispanel:1, istrace:0, $
       panelid:i, traceid:-1}]
     ;if i eq 0 then panelValueInfo = {panelListInfo, ispanel:1, istrace:0, $
     ;                                 panelid:panelLayout[i].id, traceid:-1} $
     ;  else panelValueInfo = [panelValueInfo, {panelListInfo, ispanel:1, istrace:0, $
     ;                                          panelid:panelLayout[i].id, traceid:-1}]
       
     cPanel->getProperty,traceSettings=traceSettings
     traces = traceSettings->get(/all)
     
     if i eq *cpanel_num then ctraces = traces
     
     if obj_valid(traces[0]) then begin
       ntr = n_elements(traces)
       trNames = cPanel->constructTraceNames()
       ; add a number to the trace names and truncate to fit.
       ; NB: truncation isn't added to constructTraceNames because that is used for display in plot layout etc too.
       trNames = spd_ui_line_options_truncate_trace_names(trNames)
       
       for j = 0,ntr-1 do begin
       
         panelValue = [panelValue, trNames[j]]
         
         panelValueInfo = [panelValueInfo, {panelListInfo, ispanel:0, istrace:1, $
           panelid:i, traceid:j}]
         ;panelValueInfo = [panelValueInfo, {panelListInfo, ispanel:0, istrace:1, $
         ;                                   panelid:panelLayout[i].id, traceid:j}]
           
         if (*cpanel_num eq i) AND (*ctr_num eq j) then begin
           traces[j]->getProperty,dataX=dataX, dataY=dataY
           ctrace = traces[j]
           
           if obj_isa(traces[j],'spd_ui_spectra_settings') then begin
             traces[j]->getProperty,dataZ=dataZ
             
             ;if spectra was selected, check for valid traces
             for k = 0, ntr-1 do begin
               if obj_isa(traces[k],'spd_ui_line_settings') then begin
                 traces[j]->getProperty,dataX=dataX, dataY=dataY
                 dataZ = ''
                 ctrace = traces[k]
                 *ctr_num = k
                 break
               endif
             endfor
             
           endif else dataZ = ''
           
         endif
       endfor
       
     endif
   endfor
   
 endif else begin
   npanels=0
   panelNames='No Panels'
 endelse
 
 if obj_valid(panelObjs[0]) then cpanel = panelObjs[*cpanel_num]
 
 ctextvalues=['']
 ;widgets for line panel
 
 paneldbase = widget_base(panelBase, /row)
 paneldlabel = widget_label(paneldBase, value = '   Panel: ')
 panelDroplist = Widget_combobox(paneldBase, $
   Value=panelNames, UValue='PANELLIST')
 widget_control, panelDroplist, set_combobox_select=*cpanel_num
 
 if is_struct(panelValueInfo) then begin
 
   tr_nums = where((panelValueInfo.panelid eq *cpanel_num) $
     and (panelValueInfo.istrace eq 1), ntr_nums)
     
 endif else begin
   tr_nums = 0
   ntr_nums = 0
 endelse
 
 
 if ntr_nums gt 0 then begin
   traceNames=panelValue[tr_nums]
 endif else begin
   traceNames='No Traces'
 endelse
 
 ; get the full version of the selected trace in case the version in the combobox has been truncated.
 fulltrNames = spd_ui_line_options_get_full_trace_names(cpanel)
 
 tracedbase = widget_base(tracebase, /row)
 tracedlabel = widget_label(tracedBase, value = 'Select Trace: ')
 traceDroplist = Widget_combobox(tracedBase, Value=traceNames, UValue='TRACELIST')
 widget_control, traceDroplist, set_combobox_select=*ctr_num
 
 IF Is_Num(dataNames) OR dataNames[0] EQ '' THEN dataNames=['No Loaded Data']
 
 tracetextbase = widget_base(tracebase, /row, xpad=17)
 tracetextlabel = widget_label(tracetextbase, value = '     Trace: ')
 tracetextedit = widget_text(tracetextbase, value = fulltrNames[*ctr_num], uname = 'tracename',xsize=50)
 
 
 ;****** Line Options **********************************************************
 lineOptionsLabel = Widget_Label(lineOptionsBase, Value='Line Options: ', /Align_Left)
 lineFrameBase = Widget_Base(lineOptionsBase, /Col, Frame=3)
 lineShowBase = Widget_Base(lineFrameBase, /NonExclusive, /row)
 lineShowButton = Widget_Button(lineShowBase, Value='Show Line', UValue='SHOWLINE', uname='showline')
 lpaletteBase = Widget_Base(lineFrameBase, /Row, XPad=1)
 lcolorLabel = Widget_Label(lpaletteBase, Value='Color:', /align_left)
 
 getresourcepath,rpath
 palettebmp = read_bmp(rpath + 'color.bmp', /rgb)
 spd_ui_match_background, tlb, palettebmp
 
 lpaletteButton = Widget_Button(lpaletteBase, Value=palettebmp, /Bitmap, $
   UValue='PALETTE', UName='palette', Tooltip='Choose color from Palette')
 lspaceLabel = Widget_Label(lpaletteBase, Value=' ')
 lcolorbase = widget_base(lpalettebase, /col)
 ;  ccolorlabel = Widget_Label(lcolorBase, Value = 'Currently')
 lcolorWindow = WIDGET_DRAW(lcolorBase,graphics_level=2,renderer=1, $
   retain=1, XSize=50, YSize=19, units=0, frame=1, /expose_events)
   
 if obj_valid(ctrace) && obj_isa(ctrace,'spd_ui_line_style') then begin
   ctrace->GetProperty, LineStyle=linestyleobj
 endif else begin
   linestyleobj = obj_new('spd_ui_line_style')
 endelse
 styleNames=linestyleobj->GetLineStyles()
 lsdBase = widget_base(lineFrameBase, /row)
 lsdLabel = widget_label(lsdBase, value = 'Style:', /align_left)
 linestyleDroplist = Widget_combobox(lsdBase, $
   Value=styleNames, UValue='LINESTYLE', UName='linestyle')
 lineThickBase = Widget_Base(lineFrameBase, /Row)
 lthicklabel = widget_label(lineThickBase, value = 'Thickness:', /align_left)
 lineThickIncrement = spd_ui_spinner(lineThickBase, $
   Increment=1, Value=1, UValue='THICKNESS', UName='thickness',min_value=1, max_value=10)
 prevThickness=1
 ;******************************************************************************
 
 
 ;****** Symbol Options ********************************************************
 symbolOptionsLabel = Widget_Label(symbolOptionsBase, Value='Symbol Options: ', $
   /Align_Left)
 symbolFrameBase = Widget_Base(symbolOptionsBase, /Row, Frame=3)
 symbol1Base = Widget_Base(symbolFrameBase, /Col)
 symbolShowBase = Widget_Base(symbol1Base, /Nonexclusive, /row)
 symbolShowButton = Widget_Button(symbolShowBase, Value='Show Symbol', $
   UValue='SHOWSYMBOL', UName='showsymbol')
 symbolFilledButton = Widget_Button(symbolShowBase, Value='Filled', $
   UValue='FILLSYMBOL', UName='fillsymbol')
 spaletteBase = Widget_Base(symbol1Base, /Row, XPad=1)
 scolorLabel = Widget_Label(spaletteBase, Value='Color:', /align_left)
 ;  palettebmp = filepath('palette.bmp', Subdir=['resource', 'bitmaps'])
 spaletteButton = Widget_Button(spaletteBase, Value=palettebmp, /Bitmap, $
   UValue='PALETTE1', uname='palette1', Tooltip='Choose color from Palette')
 sspaceLabel = Widget_Label(spaletteBase, Value=' ')
 scolorbase = widget_base(spalettebase, /col)
 ;  ccolorlabel = Widget_Label(scolorBase, Value = 'Currently')
 scolorWindow = WIDGET_DRAW(scolorBase,graphics_level=2,renderer=1, $
   retain=1, XSize=50, YSize=19, units=0, frame=1, /expose_events)
 if obj_valid(ctrace) && obj_isa(ctrace,'spd_ui_line_style') then begin
   ctrace->GetProperty, Symbol=symbolobj
 endif else begin
   symbolobj = obj_new('spd_ui_symbol')
 endelse
 
 symbolnames = symbolobj->GetSymbols()
 ssdBase = widget_base(symbol1Base, /row)
 ssdLabel = widget_label(ssdBase, value = 'Style:', /align_left)
 symbolStyleDroplist = Widget_combobox(ssdBase, $
   Value=symbolNames, UValue='SYMBOLSTYLE', UName='symbolstyle')
 symbolThickBase = Widget_Base(symbol1Base, /Row)
 sthicklabel = widget_label(symbolThickBase, value = 'Size:', /align_left)
 symbolThickIncrement = spd_ui_spinner(symbolThickBase, $
   Increment=1, Value=2, UValue='SYMBOLSIZE', UName='symbolsize',min_value=1)
 prevSymbolSize=2
 ;******************************************************************************
 
 
 ;****** Symbol Frequency ******************************************************
 plotOptionLabel = Widget_Label(frequencyBase, Value='Symbol Frequency:', /Align_Left)
 plotFrameBase = Widget_Base(frequencyBase, /col, Frame=3, XPad=5, ypad=6, uname='plot1Base')
 plot1Base = Widget_Base(plotFrameBase, /Exclusive, /COL)
 allPtsButton = Widget_Button(plot1Base, Value = 'All', UValue='ALLPOINTS', $
   UName='allpoints')
 firstLastButton = Widget_Button(plot1Base, Value = 'First, Last', $
   UValue='FIRSTLAST', UName='firstlast')
 firstButton = Widget_Button(plot1Base, Value = 'First', UValue='FIRST', $
   UName='first')
 lastButton = Widget_Button(plot1Base, Value = 'Last', UValue='LAST', $
   UName='last')
 majorButton = Widget_Button(plot1Base, Value = 'Major ticks', UValue='MAJORTICKS', $
   UName='majorticks')
 everyButton = Widget_Button(plot1Base, Value = 'Every', UValue='EVERYPOINT', $
   UName='everypoint')
 Widget_Control, allPtsButton, /Set_Button
 everyBase = Widget_Base(plotFrameBase, /Row, Sensitive=0)
 everyIncrement = spd_ui_spinner(everyBase, label= '  ',increment=1, Value=1, $
   UValue='EVERYINC', UName='everyinc',min_value=1)
 prevInc = 1
 ;******************************************************************************
 
 
 ;****** Lines Between Points **************************************************
 drawButtonBase = Widget_Base(drawBase, /Col, /NonExclusive)
 drawButtonButton = Widget_Button(drawButtonBase, UValue='DRAWBETWEEN', $
   UName='drawbetween', Value='Do not draw lines between points if')
 drawFrameBase = Widget_Base(drawBase, /Row, XPad=1)
 drawLabel = Widget_Label(drawFrameBase, Value='separated by more than ',sensitive=0)
 ;  drawText = Widget_TEXT(drawFrameBase, Value=' 0', YSize=1, XSize=5, $
 ;    UVALUE='DRAWTEXT', UName='drawtext', sensitive=0, /editable, /All_events)
 drawText = spd_ui_spinner(drawFrameBase, increment=1, Value=0, $
   sensitive=0, UVALUE='DRAWTEXT', UName='drawtext',min_value=0)
 ; get units for droplist
 separatedUnits = ['<none>']
 if obj_valid(cpanel) then begin
   cPanel->GetProperty, XAxis=xaxis
   if obj_valid(xAxis) then separatedUnits=xAxis->GetUnits()
 endif
 drawDroplist = Widget_combobox(drawFrameBase, sensitive=0, Uvalue='DRAWDROPLIST', $
   UName='drawdroplist', Value=separatedUnits)
 ;    UName='drawdroplist', Value=[' seconds', ' minutes', ' hours', ' days', '<none>'])
 ;  spaceLabel = Widget_Label(drawFrameBase, Value=' ')
 drawSetBase = Widget_Base(drawBase, /col)
; drawSetButton = Widget_Button(drawBase, Value='Set All Lines',UValue='SETALL', XSize=95, /align_center)
 
 buttonsBase = Widget_Base(buttonStatusBase, /row, /align_center)
 okButton = Widget_Button(buttonsBase, Value='OK', UValue='OK')
 applyButton = Widget_Button(buttonsBase, Value='Apply', UValue='APPLY')
 applyButton = Widget_Button(buttonsBase, Value='Apply to All Lines', UValue='APPLYTOALL', tooltip="Apply changes to all lines of this panel (except color and style)")
 cancelButton = Widget_Button(buttonsBase, Value='Cancel', UValue='CANC')
 templateButton = Widget_Button(buttonsBase,  Value='Store for a Template', UValue='TEMP',tooltip='Use these settings when saving a Graph Options Template')
 
 statusBase = Widget_Base(buttonStatusBase, /row)
 statusBar = Obj_New('SPD_UI_MESSAGE_BAR', statusBase, XSize=75, YSize=1)
 ;  blank_label_for_space = widget_label(statusBase, Value = '      ')
 
 
 state = {tlb:tlb, gui_id:gui_id, winID:0, xSelect:0, ySelect:0, $ 
   lpaletteBase:lpaletteBase, statusBar:statusBar, $ 
   lcolorWindow:lcolorWindow, scolorWindow:scolorWindow, $
   cpanel_num:cpanel_num, ctr_num:ctr_num, prevSymbolSize:prevSymbolSize, $
   panelDroplist:panelDroplist, traceDroplist:traceDroplist, $
   drawText:drawText, drawLabel:drawLabel, prevInc:prevInc, $
   drawDroplist:drawDroplist, drawButtonButton:drawButtonButton, $
   everyBase:everyBase, everyIncrement:everyIncrement, $
   vcolorWin:0, hfcolorWin:0, ciscolorWin:0, dataNames:dataNames, $
   drawObject:drawObject, historyWin:historyWin, $ 
   loadedData:loadedData, windowStorage:windowStorage, origWindow:origWindow, $
   cWindow:cWindow, prevThickness:prevThickness, $
   panelObjs:ptr_new(panelObjs), cpanel:ptr_new(cpanel), ctrace:ptr_new(ctrace), $
   ctraces:ptr_new(ctraces), $
   subMainLineBase:subMainLineBase,template:template, tlb_statusbar:tlb_statusbar}
   
 Widget_Control, tlb, Set_UValue=state, /No_Copy
 CenterTLB, tlb
 Widget_Control, tlb, /Realize
 
 spd_ui_init_line_panel, tlb
 
 ;keep windows in X11 from snaping back to
 ;center during tree widget events
 if !d.NAME eq 'X' then begin
   widget_control, tlb, xoffset=0, yoffset=0
 endif
 
 XManager, 'spd_ui_line_options', tlb, /no_block
 
 RETURN
 END
