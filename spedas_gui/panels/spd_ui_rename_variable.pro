;+ 
;NAME:
; spd_ui_rename_variable
;
;PURPOSE:
;  this window allows the user to rename a tplot variable as it is being imported to avoid a name conflict with existing variables
;    
;CALLING SEQUENCE:
; spd_ui_rename_variable, gui_id, names, loadedData, windowstorage, historywin,newnames=newnames,success=success,callSequence=callSequence
; 
; Inputs:
;   names:  The names to be changed
;   loadedData: The loadedData object
;   windowstorage: The windowStorage object
; 
;Keywords:
; gui_id:  id of top level base widget from calling program(not required if not used inside the gui)
; newnames:  This returns the set of datanames after any modifcations
; success: Returns 1 if the successful
;  
;OUTPUT:
; 
;HISTORY:
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_rename_variable.pro $
;
; This is copied largely from spd_ui_verify_data
;
;--------------------------------------------------------------------------------

;updates a page with the new contents from the name element at index
pro spd_ui_update_variable,state

  compile_opt hidden,idl2
  
  index = state.currentindex
  if index eq -1 then begin
      value =''
  endif else begin
    Widget_Control, state.textWidgets[0], set_value=(*(state.names))[index]
  endelse

end


pro spd_ui_rename_variable_event,event

  compile_opt hidden,idl2

  Widget_Control, event.TOP, Get_uvalue=state, /No_Copy

  ;Put a catch here to insure that the state remains defined
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error in Rename Variable'
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
  IF(Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN  
    state.historyWin->update,'Widget Killed' 
    Widget_Control, event.TOP, Set_uValue=state, /No_Copy    
    Widget_Control, event.top, /Destroy
    RETURN      
  ENDIF

  Widget_Control, event.id, Get_UValue=uval

  state.historywin->update,'SPD_UI_RENAME_VARIABLE: User value: '+uval  ,/dontshow

  CASE uval OF
    'CANC': BEGIN
      Widget_Control, event.TOP, Set_uValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      RETURN
    END
    'OK': BEGIN  
      validnames = 1
      numdata = n_elements(*(state.names))
      ; check each name is unique
      uniqueIndices = uniq(*(state.names),sort(*(state.names)))
      if (n_elements(*(state.names)) ne n_elements(uniqueIndices)) then begin
          messageString=String('Multiple variables with the same name. Please enter a unique name for each variable.')              
          response=dialog_message(messageString,/CENTER,/information)
          validnames = 0
      endif
      i =0
      while (i lt numData) and (validnames) do begin
        if in_set((*(state.names))[i], state.origGUINames) then begin
          messageString=String('The name '+(*(state.names))[i] +' is already used by another variable. Please enter a new name.')              
          response=dialog_message(messageString,/CENTER,/information)
          validnames = 0
        endif
        i++
      endwhile
      if (validnames) then begin
        *state.success = 1
        Widget_Control, event.TOP, Set_uValue=state, /No_Copy
        Widget_Control, event.top, /Destroy
        RETURN
       endif
    END
    'VARLIST': BEGIN
      state.currentIndex = event.index
      spd_ui_update_variable,state  
    END
    'NAME': BEGIN
      Widget_Control, state.textWidgets[0], Get_Value=value
      current_select = widget_info(state.varList,/list_select)
      if current_select[0] ne -1 && n_elements(current_select) eq 1 then begin
        (*(state.names))[current_select[0]] = value
        Widget_Control, state.varList, set_list_select=current_select
      endif else if n_elements(current_select) ne 1 then begin
        state.statusbar->update,'Cannot update more than one name at once'
      endif
    END
    'UP': BEGIN
       IF state.currentIndex ne - 1 then begin   
         state.currentIndex = (-1 + state.currentIndex + n_elements(*(state.names))) mod n_elements(*(state.names))
         widget_control,state.varList,set_list_select=state.currentIndex
         spd_ui_update_variable,state
       endif 
    END
    'DOWN': BEGIN
        IF state.currentIndex ne - 1 then begin   
         state.currentIndex = (1 + state.currentIndex + n_elements(*(state.names))) mod n_elements(*(state.names))
         widget_control,state.varList,set_list_select=state.currentIndex
         spd_ui_update_variable,state
       endif 
    END
    ELSE: dprint, 'Not yet implemented'
  ENDCASE
    
  Widget_Control, event.top, Set_uValue=state, /No_Copy

  RETURN

END ;----------------------------------------------------------------------------



PRO spd_ui_rename_variable, gui_id, names, loadedData, windowstorage, historywin,newnames=newnames,success=success,callSequence=callSequence

  compile_opt idl2
 
   err_xxx = 0
  Catch, err_xxx
  If(err_xxx Ne 0) Then Begin
    Catch, /Cancel
    Help, /Last_Message, output = err_msg
    FOR j = 0, N_Elements(err_msg)-1 DO historywin->update,err_msg[j]
    ok = error_message('An unknown error occured in Rename Variable.  See console for details.',$
         /noname, /center, title='Error in Rename Variable')
    Widget_Control,tlb,/destroy
    spd_gui_error,gui_id, historywin
    RETURN
  EndIf
 

  tlb = Widget_Base(/col, Title='Rename Variable', /floating, Group_Leader=gui_id, /Modal, $
                    /tlb_kill_request_events)
  
  mainBase = Widget_Base(tlb, /row, tab_mode=1)
  varListBase = Widget_Base(mainBase, /row)
  varLabelBase = Widget_Base(varListBase, /row)
  varTextBase = Widget_Base(varListBase, /row)
  arrowBase = Widget_Base(varListBase, /col, /align_center)
  nameBase = Widget_Base(mainBase, /row)
      
;       arrowBase = Widget_Base(metaFrameBase, /row, /align_center)
    
  button_row = widget_base(tlb,/row, /align_center, tab_mode=1)
  status_row = widget_base(tlb,/row)
  
  ; get pre-existing gui variable names
  origGuiNames = loadedData->GetAll(/Parent)
 
  varLabel = Widget_Label(varLabelBase, value='Data: ')
  varList = Widget_List(varTextBase, value=names, xsize =28, ysize=4, /multiple, UValue='VARLIST')
  
  varNameLabel = Widget_Label(nameBase, value = 'New Name: ')
  
  varNameText = Widget_Text(nameBase, value='', uValue='NAME', /editable, xsize=28,/all_events)             
  
  getresourcepath,rpath
  upArrow = read_bmp(rpath + 'arrow_090_medium.bmp', /rgb)
  downArrow = read_bmp(rpath + 'arrow_270_medium.bmp', /rgb)

  spd_ui_match_background, tlb, upArrow
  spd_ui_match_background, tlb, downArrow

  leftButton = Widget_Button(arrowBase, Value=upArrow, /Bitmap, UValue='UP', $
              ToolTip='Tab up through variable names')
  rightButton = Widget_Button(arrowBase, Value=downArrow, /Bitmap, $
                Uvalue='DOWN', $
                ToolTip='Tab down through variable names')
  ok_button = widget_button(button_row,value='OK',uvalue='OK', xsize=75)
  canc_button = widget_button(button_row,value='Cancel',uvalue='CANC', xsize=75)  
  
  statusBar = Obj_New("SPD_UI_MESSAGE_BAR", status_row, Xsize=82, YSize=1)
  
  textWidgets = [varNameText]
  origNames = names
  index = [0]
  selectedIndices=Ptr_New(index)
  
  if ~obj_valid(callSequence) then begin
    callSequence = obj_new()
  endif

  if ~is_num(edit) then edit = 0
  names_ptr = ptr_new(names)
  state = {tlb:tlb, gui_id:gui_id, statusBar:statusBar,$
           currentIndex:0, loadedData:loadedData, names:names_ptr,$
           textWidgets:textWidgets, varList:varList, windowStorage:windowStorage, $
           origNames:origNames, edit:edit, historywin:historywin,success:ptr_new(), $
           origGuiNames:origGuiNames, callSequence:callSequence}
            
  Widget_Control, tlb, Set_UValue = state, /No_Copy
  CenterTlb, tlb
  Widget_Control, tlb, /Realize
  Widget_Control, tlb, Get_UValue = state, /No_Copy
  widget_control, varList, set_list_select=0
  state.currentIndex=0
  
  spd_ui_update_variable, state
  
  success_ptr = ptr_new(0)
 
  state.success = success_ptr
  
  Widget_Control, tlb, Set_UValue = state, /No_Copy
  
  historywin->update,'Rename Variable panel opened'

  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif

  XManager, 'spd_ui_rename_variable', tlb
  
  historywin->update,'Rename Variable panel closing'
  
  if arg_present(newnames) then begin
    newnames = *names_ptr
  endif
  
  success = *success_ptr

  RETURN
  
END
