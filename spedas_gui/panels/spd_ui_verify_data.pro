;+ 
;NAME:
; spd_ui_verify_data
;
;PURPOSE:
;  this window allows the user to view and change the meta data associated with GUI data, either tplot variables 
;  being imported or GUI data being exported.
;    
;CALLING SEQUENCE:
; spd_ui_verify_data,names,loadedData,windowStorage,gui_id=gui_id,edit=edit,newnames=newnames
; 
; Inputs:
;   names:  The names for which verification is done
;   loadedData: The loadedData object
;   windowstorage: The windowStorage object
; 
;Keywords:
; gui_id:  id of top level base widget from calling program(not required if not used inside the gui)
; edit:  Set this to indicate that this is only being used to edit metadata.  This means that data will not be deleted on failure/error
; newnames:  This returns the set of datanames after any modifcations
;  
;OUTPUT:
; 
;HISTORY:
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-04-24 18:45:02 -0700 (Fri, 24 Apr 2015) $
;$LastChangedRevision: 17429 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_verify_data.pro $
;
;--------------------------------------------------------------------------------

;updates a page with the new contents from the metadata element at index
pro spd_ui_update_verify,state

  compile_opt hidden,idl2
  
  index = state.currentindex
  
  if index eq -1 || ~ptr_valid(state.metaData) then begin 
  
    if index eq -1 then begin
      value =''
    endif else begin
      value='<unknown>'
    endelse
  
    for i = 0,7 do begin
      if i ne 5 then begin
        widget_control,state.textWidgets[i],set_value=value
      endif else begin
        widget_control,state.textWidgets[i],set_combobox_select=where(state.validcoords eq 'N/A')
      endelse
    endfor
  endif else begin
    Widget_Control, state.textWidgets[0], set_value=(*state.metaData)[index].name
    Widget_Control, state.textWidgets[1], set_value=(*state.metaData)[index].mission
    Widget_Control, state.textWidgets[2], set_value=(*state.metaData)[index].observatory
    Widget_Control, state.textWidgets[3], set_value=(*state.metaData)[index].instrument
    Widget_Control, state.textWidgets[4], set_value=(*state.metaData)[index].unit
    Widget_Control, state.textWidgets[5], set_combobox_select=(*state.metaData)[index].coordinate
    Widget_Control, state.textWidgets[6], set_value=(*state.metaData)[index].filename
    Widget_Control, state.textWidgets[7], set_combobox_select=(*state.metaData)[index].st_type
  endelse

end

pro spd_ui_update_meta,state,element,value

  compile_opt idl2,hidden

  list = widget_info(state.varList,/list_select)
  
  if ~ptr_valid(state.metadata) || list[0] eq -1 then return
  
  idx = where(element eq strlowcase(tag_names((*state.metadata)[0])),c)
  
  if c eq 0 then return
  
  for i = 0,n_elements(list)-1 do begin
  
    (*state.metadata)[list[i]].(idx) = value  
  
  endfor

end



pro spd_ui_verify_data_event,event

  compile_opt hidden,idl2

  Widget_Control, event.TOP, Get_uvalue=state, /No_Copy

  ;Put a catch here to insure that the state remains defined
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error in Verify Data'
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
  
  IF(Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN  
    state.historyWin->update,'Widget Killed'
    IF ~keyword_set(state.edit) && ptr_valid(state.metadata) THEN BEGIN
      numData=N_Elements(*state.metaData)
      IF numData GT 0 THEN FOR i=0,numData-1 DO result=state.loadedData->Remove(state.origNames[i])
    ENDIF 
    Widget_Control, event.TOP, Set_uValue=state, /No_Copy    
    Widget_Control, event.top, /Destroy
    RETURN      
  ENDIF

  Widget_Control, event.id, Get_UValue=uval

  state.historywin->update,'SPD_UI_VERIFY_DATA: User value: '+uval  ,/dontshow

  CASE uval OF
    'CANC': BEGIN
      IF ~keyword_set(state.edit) && ptr_valid(state.metadata) THEN BEGIN
        numData=N_Elements(*state.metaData)
        IF numData GT 0 THEN BEGIN
          FOR i=0,numData-1 DO BEGIN
            if ~in_set(state.origNames[i], state.origGuiNames) then $
              result=state.loadedData->Remove(state.origNames[i])
          ENDFOR
        ENDIF
      ENDIF 
      Widget_Control, event.TOP, Set_uValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      RETURN
    END
    'OK': BEGIN   
      state.historyWin->update,'Closing verify panel'
      if ptr_valid(state.metadata) && n_elements(*state.metaData) gt 0 then begin
        numData=N_Elements(*state.metaData)
        existingData=state.loadedData->GetAll(/Parent)
        FOR i=0,numData-1 DO BEGIN
          ; check st_type
          st_type = 'none' ; default to none
          if (*state.metaData)[i].st_type eq 1 then st_type = 'pos'
          if (*state.metaData)[i].st_type eq 2 then st_type = 'vel'

          ;This check verifies that the requested name is in the set of selected names, but that the name is not THIS variable's name(which would be the case if the name was left unchanged)
          if in_set((*state.metadata)[i].name,existingData) && (*state.metadata)[i].name ne state.origNames[i] then begin
            messageString=String('The name '+(*state.metaData)[i].name +' is already used by another variable. Name will not be changed')              
            response=dialog_message(messageString,/CENTER)
            state.loadedData->SetDataInfo, $
              state.origNames[i], $
              Mission=(*state.metaData)[i].mission, $
              Observatory=(*state.metaData)[i].observatory,$
              Instrument=(*state.metaData)[i].instrument, $
              Units=(*state.metaData)[i].unit, $
              st_type=st_type,$
              Coordinate_System=state.validCoords[(*state.metaData)[i].coordinate], $
              windowstorage=state.windowStorage, fail=fail 
              
            if obj_valid(state.callSequence) && ~fail then begin
              state.callSequence->addDataInfoOp,$
                  state.origNames[i], $
                  (*state.metaData)[i].mission, $
                  (*state.metaData)[i].observatory,$
                  (*state.metaData)[i].instrument, $
                  (*state.metaData)[i].unit, $
                  state.validCoords[(*state.metaData)[i].coordinate], $
                  st_type=st_type
            endif
          endif else begin
          
            state.loadedData->SetDataInfo, $
              state.origNames[i], $
              newname=(*state.metadata)[i].name,$
              Mission=(*state.metaData)[i].mission, $
              Observatory=(*state.metaData)[i].observatory,$
              Instrument=(*state.metaData)[i].instrument, $
              Units=(*state.metaData)[i].unit, $
              st_type=st_type,$
              Coordinate_System=state.validCoords[(*state.metaData)[i].coordinate], $
              windowstorage=state.windowStorage, fail=fail 
              
            if obj_valid(state.callSequence) && ~fail then begin
              state.callSequence->addDataInfoOp,$
                  state.origNames[i], $
                  newname=(*state.metadata)[i].name,$
                  st_type=st_type,$
                  (*state.metaData)[i].mission, $
                  (*state.metaData)[i].observatory,$
                  (*state.metaData)[i].instrument, $
                  (*state.metaData)[i].unit, $
                  state.validCoords[(*state.metaData)[i].coordinate]
            endif 
              
           endelse
         
           IF Fail EQ 1 THEN BEGIN
              result=state.loadedData->Remove(state.metaData[i].name)
              messageString=String('Error setting meta data values for '+state.names[i]+'. Do you want to continue?')
              result=dialog_message(messageString,/QUESTION,/CENTER, title='Error in Verify Data')
              IF result EQ 'No' && ~keyword_set(state.edit) THEN BEGIN
                 if i lt numData-1 then begin
                   for j = i+1,numData-1 do begin
                     result=state.loadedData->Remove(state.metaData[i].name)
                   endfor
                 endif
                 Widget_Control, event.TOP, Set_uValue=state, /No_Copy    
                 RETURN
              ENDIF
           ENDIF
        ENDFOR
      ENDIF 
      *state.success = 1
      Widget_Control, event.TOP, Set_uValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      RETURN
    END
    'VARLIST': BEGIN
      state.currentIndex = event.index
      spd_ui_update_verify,state  
    END
    'NAME': BEGIN
      Widget_Control, state.textWidgets[0], Get_Value=value
      current_select = widget_info(state.varList,/list_select)
      if current_select[0] ne -1 && n_elements(current_select) eq 1 then begin
        spd_ui_update_meta,state,'name',value
        state.names[current_select[0]] = value
        Widget_Control, state.varList, set_value=state.names
        Widget_Control, state.varList, set_list_select=current_select
      endif else if n_elements(current_select) ne 1 then begin
        state.statusbar->update,'Cannot update more than one name at once'
      endif
    END
    'MISSION': BEGIN
      Widget_Control, state.textWidgets[1], Get_Value=value
      spd_ui_update_meta,state,'mission',value
    END
    'OBSERVATORY': BEGIN
      Widget_Control, state.textWidgets[2], Get_Value=value
      spd_ui_update_meta,state,'observatory',value
    END
    'INSTRUMENT': BEGIN
      Widget_Control, state.textWidgets[3], Get_Value=value
      spd_ui_update_meta,state,'instrument',value
      
    END
    'UNIT': BEGIN
      Widget_Control, state.textWidgets[4], Get_Value=value
      spd_ui_update_meta,state,'unit',value
    END
    'COORDINATE': BEGIN
      index = event.index
      if index[0] ne -1 then begin
        spd_ui_update_meta,state,'coordinate',index
      endif
    END
    'ST_TYPE': BEGIN
        Widget_Control, state.textWidgets[7], Get_Value=value ; value = array of possible values
        ; get the current selection
        cb_text = widget_info(state.textWidgets[7], /COMBOBOX_GETTEXT)
        cb_selected_idx = where(value eq cb_text)
        if cb_selected_idx ne -1 then spd_ui_update_meta, state, 'st_type', cb_selected_idx
    END
    'UP': BEGIN
       IF ptr_valid(state.metadata) && state.currentIndex ne - 1 then begin   
         state.currentIndex = (-1 + state.currentIndex + n_elements(*state.metadata)) mod n_elements(*state.metadata)
         widget_control,state.varList,set_list_select=state.currentIndex
         spd_ui_update_verify,state
       endif 
    END
    'DOWN': BEGIN
       IF ptr_valid(state.metadata) && state.currentIndex ne - 1 then begin   
         state.currentIndex = (1 + state.currentIndex + n_elements(*state.metadata)) mod n_elements(*state.metadata)
         widget_control,state.varList,set_list_select=state.currentIndex
         spd_ui_update_verify,state
       endif 
    END
    ELSE: dprint, 'Not yet implemented'
  ENDCASE
    
  Widget_Control, event.top, Set_uValue=state, /No_Copy

  RETURN

END ;----------------------------------------------------------------------------



PRO spd_ui_verify_data, gui_id, names, loadedData, windowstorage, historywin, edit=edit,newnames=newnames,success=success,callSequence=callSequence

  compile_opt idl2
 
   err_xxx = 0
  Catch, err_xxx
  If(err_xxx Ne 0) Then Begin
    Catch, /Cancel
    Help, /Last_Message, output = err_msg
    FOR j = 0, N_Elements(err_msg)-1 DO historywin->update,err_msg[j]
    ;Print, 'Error--See history'
    ok = error_message('An unknown error occured starting Verify Data.  See console for details.',$
         /noname, /center, title='Error in Verify Data')
    Widget_Control,tlb,/destroy
    spd_gui_error,gui_id, historywin
    RETURN
  EndIf
 

  tlb = Widget_Base(/col, Title='Verify Data', /floating, Group_Leader=gui_id, /Modal, $
                    /tlb_kill_request_events)
  
  mainBase = Widget_Base(tlb, /row, tab_mode=1)
  varListBase = Widget_Base(mainBase, /col)
     varLabelBase = Widget_Base(varListBase, /row)
     varTextBase = Widget_Base(varListBase, /row)
     arrowBase = Widget_Base(varListBase, /row, /align_center)
  metaDataBase = Widget_Base(mainBase, /col)
     metaLabelBase=Widget_Base(metaDataBase, /row, ypad=2)
     metaFrameBase=Widget_Base(metaDataBase, /col, frame=3)
       variableBase = Widget_Base(metaFrameBase, /row, ypad=1)
       missionBase = Widget_Base(metaFrameBase, /row, ypad=1)
       observatoryBase = Widget_Base(metaFrameBase, /row, ypad=1)
       instrumentBase = Widget_Base(metaFrameBase, /row, ypad=1)
       unitBase = Widget_Base(metaFrameBase, /row, ypad=1)
       coordinateBase = Widget_Base(metaFrameBase, /row, ypad=1)
       st_typeBase = Widget_Base(metaFrameBase, /row, ypad=1)
       filenameBase = Widget_Base(metaFrameBase, /row, ypad=1)
;       arrowBase = Widget_Base(metaFrameBase, /row, /align_center)
    
  button_row = widget_base(tlb,/row, /align_center, tab_mode=1)
  status_row = widget_base(tlb,/row)
  
  ; initialize the valid missions, instruments, probes, and coordinate systems
  validMissions = ['SPEDAS']
  validInstruments = [' ASI     ', ' ASK', ' ESA', ' EFI', ' FBK', ' FFT', ' FGM', $
               ' FIT ', ' GMAG', ' MOM', ' SCM', ' SPIN', ' SST', ' STATE']
  validProbes = [' * (All)', ' A (P5)', ' B (P1)', ' C (P2)', ' D (P3)', $
                 ' E (P4)', ' F (Flatsat)']
                 
 ; validCoords = ['N/A','DSL', 'SSL', 'GSE', 'GEI', 'SPG', 'GSM', 'GEO', 'SM','ENP','RTN','GCI','HDZ']
  ; make a list of valid coordinate systems 
  coord_sys_obj = obj_new('spd_ui_coordinate_systems')
  validCoords = coord_sys_obj->makeCoordSysList(/uppercase, /include_none, /include_misc)
  obj_destroy, coord_sys_obj


  ; get pre-existing gui variable names
  origGuiNames = loadedData->GetAll(/Parent)
 
  ; initialize the meta data structure
  metaDataStruc = {name:'', mission:'', observatory:'', instrument:'',unit:'', coordinate:0, $
     st_type: 0, filename:''}
  IF N_Elements(names) GT 0 THEN BEGIN
     metaData=replicate(metaDataStruc, N_Elements(names))
     FOR i=0,N_Elements(names)-1 DO BEGIN
        loadedData->GetDataInfo, names[i], mission=mission, observatory=observatory, dlimit=dlimit, st_type=st_type, $
           instrument=instrument, units=unit, coordinate_system=coordinate, filename=filename, fail=fail
        IF fail THEN BEGIN
          ok = error_message('Error retrieving data for ' + names[i], $
               /center, title='Error in Verify Data')
          continue
        endif      
        metaData[i].name=names[i]
        metaData[i].mission=mission
        metaData[i].observatory=observatory
        metaData[i].instrument=instrument
        metaData[i].unit=unit
        index=where(strlowcase(validCoords) EQ strlowcase(coordinate))
        IF index EQ -1 THEN index = 0
        metaData[i].coordinate=index
        metaData[i].filename=filename
        ; get the st_type (position, velocity or none) from the dlimits structure
        ; metaData[i].st_type can be:
        ; 0 - 'none', 1 - 'position', 2 - 'velocity'
        if undefined(st_type) || st_type eq 'none' then begin
          metaData[i].st_type = 0
          st_type = 'none'
        endif
        if st_type eq 'pos' then metaData[i].st_type = 1
        if st_type eq 'vel' then metaData[i].st_type = 2

     ENDFOR
     metaData = ptr_new(metaData)
  ENDIF ELSE BEGIN
     metaData=ptr_new()
     names = ['<none>']
  ENDELSE  
  
  varLabel = Widget_Label(varLabelBase, value='Data: ')
  varList = Widget_List(varTextBase, value=names, xsize =28, ysize=18, /multiple, UValue='VARLIST')
  
  sectionLabel = Widget_Label(metaLabelBase, value='Metadata:')  
  varNameLabel = Widget_Label(variableBase, value = 'Name:                    ')
  missionLabel = Widget_Label(missionBase, value = 'Mission:                  ')
  observatoryLabel = Widget_Label(observatoryBase, value = 'Observatory:           ')
  instrumentLabel = Widget_Label(instrumentBase, value = 'Instrument:              ')
  unitsLabel = Widget_Label(unitBase, value = 'Units:                      ')
  coordinateLabel = Widget_Label(coordinateBase, value = 'Coordinate System: ')
  st_typeLabel = Widget_Label(st_typeBase, value = 'Variable type:          ')
  filenameLabel = Widget_Label(filenameBase, value = 'Filename:                 ')

  varNameText = Widget_Text(variableBase, value='', uValue='NAME', /editable, xsize=20,/all_events)             
  missionText = Widget_Text(missionBase, Value='', uval='MISSION',/editable, xsize=20,/all_events)
  observatoryText = Widget_Text(observatoryBase, Value='', uval='OBSERVATORY',/editable, xsize=20,/all_events)
  instrumentText = Widget_Text(instrumentBase, Value='', uval='INSTRUMENT',/editable, xsize=20,/all_events)
  unitText = Widget_Text(unitBase, Value='', uval='UNIT',/editable, xsize=20,/all_events)
  coordinateDroplist = Widget_Combobox(coordinateBase, Value=validCoords, uval='COORDINATE')
  st_typeComboBox = Widget_Combobox(st_typeBase, value=['N/A', 'position', 'velocity'], uval='ST_TYPE')
  filenameText = Widget_Text(filenameBase, Value='', xsize=20)

  if undefined(st_type) || st_type eq 'none' then begin
    st_type_cb_idx = 0
    st_type = 'none'
  endif
  if st_type eq 'pos' then st_type_cb_idx = 1
  if st_type eq 'vel' then st_type_cb_idx = 2
  
  widget_control, st_typeComboBox, set_combobox_select=st_type_cb_idx
  
  getresourcepath,rpath
  upArrow = read_bmp(rpath + 'arrow_090_medium.bmp', /rgb)
  downArrow = read_bmp(rpath + 'arrow_270_medium.bmp', /rgb)

  spd_ui_match_background, tlb, upArrow
  spd_ui_match_background, tlb, downArrow

;shiftUpButton = Widget_Button(varButtonBase, Value=upArrow, /Bitmap, UValue='UP', uname = 'shiftupbutton', Tooltip='Move this panel up by one', $
;  sensitive = 0)   
;  leftbmp = filepath('shift_left.bmp', SubDir=['resource', 'bitmaps'])
;  rightbmp =filepath('shift_right.bmp', SubDir=['resource', 'bitmaps'])
  leftButton = Widget_Button(arrowBase, Value=upArrow, /Bitmap, UValue='UP', $
              ToolTip='Tab up through variable names')
  rightButton = Widget_Button(arrowBase, Value=downArrow, /Bitmap, $
                Uvalue='DOWN', $
                ToolTip='Tab down through variable names')
  ok_button = widget_button(button_row,value='OK',uvalue='OK', xsize=75)
  canc_button = widget_button(button_row,value='Cancel',uvalue='CANC', xsize=75)  
  
  statusBar = Obj_New("SPD_UI_MESSAGE_BAR", status_row, Xsize=82, YSize=1)
  
  textWidgets = [varNameText, missionText, observatoryText, instrumentText, unitText, $
      coordinateDroplist, filenameText, st_typeComboBox]
  origNames = names
  index = [0]
  selectedIndices=Ptr_New(index)
  
  if ~obj_valid(callSequence) then begin
    callSequence = obj_new()
  endif

  if ~is_num(edit) then edit = 0

  state = {tlb:tlb, gui_id:gui_id, statusBar:statusBar, metaData:metaData, $
           currentIndex:0, loadedData:loadedData, names:names, validCoords:validCoords, $
           textWidgets:textWidgets, varList:varList, windowStorage:windowStorage, $
           origNames:origNames, edit:edit, historywin:historywin,success:ptr_new(), $
           origGuiNames:origGuiNames, callSequence:callSequence}
            
  Widget_Control, tlb, Set_UValue = state, /No_Copy
  CenterTlb, tlb
  Widget_Control, tlb, /Realize
  Widget_Control, tlb, Get_UValue = state, /No_Copy
  widget_control, varList, set_list_select=0
  state.currentIndex=0
  
  spd_ui_update_verify,state
  
  success_ptr = ptr_new(0)
 
  state.success = success_ptr
  
  Widget_Control, tlb, Set_UValue = state, /No_Copy
  
  historywin->update,'Verify panel opened'
  
  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif
  
  XManager, 'spd_ui_verify_data', tlb
  
  historywin->update,'Verify panel closing'
  
  if arg_present(newnames) && ptr_valid(metaData) then begin
    newnames = (*metaData)[*].name
  endif
  
  success = *success_ptr

  RETURN
  
END
