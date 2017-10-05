;+
;NAME:
;  spd_ui_init_load_window
;
;PURPOSE:
;  Sets up the window and tab widgets for loading data into the SPEDAS GUI.
;
;CALLING SEQUENCE:
;  spd_ui_init_load_window, gui_id, windowStorage, loadedData, historyWin, $
;                           timerange, treeCopyPtr, loadDataTabs
;
;INPUT:
;  gui_id:  The id of the main GUI window.
;  windowStorage:  The windowStorage object.
;  loadedData:  The loadedData object.
;  historyWin:  The history window object.
;  timerange:  The GUI timerange object.
;  treeCopyPtr:  Pointer variable to a copy of the load widget tree.
;  loadDataTabs: an array of structures containing the "Load Data" panels, loaded via pluginManager->getLoadDataPanels()
;  
;KEYWORDS:
;  none
;
;OUTPUT:
;  none
; 
;HISTORY:
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-05-22 10:59:17 -0700 (Fri, 22 May 2015) $
;$LastChangedRevision: 17673 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_init_load_window.pro $
;-----------------------------------------------------------------------------------



;Helper function, used to guarantee that the tree is up-to-date.  
pro spd_ui_init_load_update_tree_copy,state

  Compile_Opt idl2, hidden

  tab = widget_info(state.tabBase,/tab_current)
 
  ; THEMIS derived products tab has no data tree
  ; but it can change the contents of the tree.
  ; So we change the tree of the first tab 

  if obj_valid(state.treeArray[tab]) then begin
    *state.treeCopyPtr = state.treeArray[tab]->getCopy()
  endif else begin
    if obj_valid(state.treeArray[0]) then begin
      *state.treeCopyPtr = state.treeArray[0]->getCopy()
    endif   
  endelse
  
  
end

;restores user selects from previous panel open
; Note: This procedure is specific to the THEMIS panel, and was
;       commented out because it doesn't work when the THEMIS panel
;       isn't the first load data panel in the Load Data window. It 
;       also references several files that only exist in ../../projects/themis/
;       and the names of these files have changed as of 4/9/2015
;       
;pro spd_ui_load_data_set_user_select,state
;
; widget_control,widget_info(state.tabArray[0],/child),get_uvalue=load_data_state
;
;  if widget_valid(load_data_state.itypeDropList) && (*state.userSelectPtr).inst ne -1 then begin
;    widget_control,load_data_state.itypeDroplist,set_combobox_select=(*state.userSelectPtr).inst
;  endif
;  spd_ui_load_data_file_itype_sel, load_data_state
;   
;  if widget_valid(load_data_state.coordDropList) && (*state.userSelectPtr).coord ne -1 then begin
;    widget_control,load_data_state.coordDropList,set_combobox_select=(*state.userSelectPtr).coord
;  endif 
;  spd_ui_load_data_file_coord_sel, load_data_state
;  
;  if widget_valid(load_data_state.observList) && ptr_valid((*state.userSelectPtr).observPtr) && (*(*state.userSelectPtr).observPtr)[0] ne -1 then begin
;    widget_control,load_data_state.observList,set_list_select=*(*state.userSelectPtr).observPtr
;  endif    
;  spd_ui_load_data_file_obs_sel, load_data_state
;  
;  if widget_valid(load_data_state.level1List) && ptr_valid((*state.userSelectPtr).level1Ptr) && (*(*state.userSelectPtr).level1Ptr)[0] ne -1 then begin
;    widget_control,load_data_state.level1List,set_list_select=*(*state.userSelectPtr).level1Ptr
;  endif    
;  spd_ui_load_data_file_l1_sel, load_data_state
;  
;  if widget_valid(load_data_state.level2List) && ptr_valid((*state.userSelectPtr).level2Ptr) && (*(*state.userSelectPtr).level2Ptr)[0] ne -1 then begin
;    widget_control,load_data_state.level2List,set_list_select=*(*state.userSelectPtr).level2Ptr
;  endif    
;  spd_ui_load_data_file_l2_sel, load_data_state
;
;  raw_data_widget_id = widget_info(widget_info(state.tabArray[0],/child),find_by_uname='raw_data')
;  if widget_valid(raw_data_widget_id) then begin
;    widget_control,raw_data_widget_id,set_button=(*state.userSelectPtr).uncalibrated
;  endif
;
;  widget_control,widget_info(state.tabArray[0],/child),set_uvalue=load_data_state,/no_copy
;end

pro spd_ui_load_data_select_copy,state

  Compile_Opt idl2, hidden

  widget_control,widget_info(state.tabArray[0],/child),get_uvalue=load_data_state

  if ptr_valid(state.userSelectPtr) && is_struct(load_data_state) then begin
     if widget_valid(load_data_state.itypeDroplist) then begin
       (*state.userSelectPtr).inst = where(widget_info(load_data_state.itypeDroplist,/combobox_gettext) eq load_data_state.validItype)
     endif
     
     if widget_valid(load_data_state.coordDropList) then begin
       (*state.userSelectPtr).coord = where(widget_info(load_data_state.coordDropList,/combobox_gettext) eq *load_data_state.validCoords)
     endif
     
     if widget_valid(load_data_state.observList) then begin
       ptr_free,(*state.userSelectPtr).observPtr
       (*state.userSelectPtr).observPtr = ptr_new(widget_info(load_data_state.observList,/list_select))
     endif
     
     if widget_valid(load_data_state.level1List) then begin
       ptr_free,(*state.userSelectPtr).level1Ptr
       (*state.userSelectPtr).level1Ptr = ptr_new(widget_info(load_data_state.level1List,/list_select))
     endif
     
     if widget_valid(load_data_state.level2List) then begin
       ptr_free,(*state.userSelectPtr).level2Ptr
       (*state.userSelectPtr).level2Ptr = ptr_new(widget_info(load_data_state.level2List,/list_select))
     endif
     
     raw_data_widget_id = widget_info(widget_info(state.tabArray[0],/child),find_by_uname='raw_data')
     if widget_valid(raw_data_widget_id) then begin
       (*state.userSelectPtr).uncalibrated = widget_info(raw_data_widget_id,/button_set)
     endif
   endif
       
end

pro spd_ui_init_load_window_event, event

  Compile_Opt idl2, hidden

      ; get the state structure from the widget

  Widget_Control, event.TOP, Get_UValue=state, /No_Copy

      ; put a catch here to insure that the state remains defined

  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    if is_struct(state) then begin
      FOR j = 0, N_Elements(err_msg)-1 DO state.historywin->update,err_msg[j]
      x=state.gui_id
      histobj=state.historywin
      ;update central tree to reflect last expansion of current tree 
      spd_ui_init_load_update_tree_copy,state
    endif
    Print, 'Error--See history'
    ok=error_message('An unknown error occured and the window must be restarted. See console for details.',$
       /noname, /center, title='Error in Load Data')
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    if widget_valid(x) && obj_valid(histobj) then begin 
      spd_gui_error,x,histobj
    endif
    RETURN
  ENDIF
  
  ;kill request block

  IF (Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN  


    exit_sequence:
;    dprint,  'Load SPEDAS Data widget killed.' 
    state.historyWin->Update,'SPD_UI_INIT_LOAD_WINDOW: Widget closed' 
    ;update central tree to reflect last expansion of current tree 
    spd_ui_init_load_update_tree_copy,state
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    Widget_Control, event.top, /Destroy
    RETURN 

  ENDIF

  ;update widget tree when new tab is selected
  IF (Tag_Names(event, /Structure_Name) EQ 'WIDGET_TAB') THEN BEGIN
    tab = event.tab
   
    spd_ui_time_widget_update,state.timeArray[tab], $
      oneday= spd_ui_time_widget_is_oneday(state.timeArray[state.previoustab])
    spd_ui_init_load_update_tree_copy,state
    
    widget_control,event.top,tlb_set_title=state.tabTitleText[tab]
    
    ;THEMIS derived products tab has no data tree
    if obj_valid(state.treeArray[state.previousTab]) then begin
      *state.treeCopyPtr = state.treeArray[state.previousTab]->getCopy()
    endif else begin
      if obj_valid(state.treeArray[0]) then begin
        *state.treeCopyPtr = state.treeArray[0]->getCopy()
      endif
    endelse
   
    if obj_valid(state.treeArray[tab]) then begin
      state.treeArray[tab]->update,from_copy=*state.treeCopyPtr
    endif else begin
      if obj_valid(state.treeArray[0]) then begin
        *state.treeCopyPtr = state.treeArray[0]->getCopy()
      endif
    endelse
   
  
    state.previousTab = tab
    (*state.userSelectPtr).panelID = tab
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    return
  
  endif  
      ; get the uval from this event so we know which widget was used 

  Widget_Control, event.id, Get_UValue=uval
  
  ; check for empty event coming from one of the other event handlers
  if size(uval,/type) eq 0 then begin 
    Widget_Control, event.top, Set_UValue = state, /No_Copy
    RETURN
  endif
  
  state.historywin->update,'SPD_UI_INIT_LOAD_WINDOW: User value: '+uval  ,/dontshow

  CASE uval OF
    'DISMISS':BEGIN
      spd_ui_init_load_update_tree_copy,state
     ; spd_ui_load_data_select_copy,state
      Widget_Control, event.top, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      RETURN
    END
    ELSE:    
  ENDCASE
  
      ; must ALWAYS reset the state value
      
  Widget_Control, event.top, Set_UValue = state, /No_Copy

  RETURN
end

pro spd_ui_init_load_window, gui_id, windowStorage, loadedData, historyWin, $
                             timerange, treeCopyPtr,userSelectPtr, loadDataTabs

  compile_opt idl2, hidden
  
  tlb = widget_base(/Col, Title = "Load Data", Group_Leader = gui_id, $
                    /Modal, /Floating, /TLB_KILL_REQUEST_EVENTS)
  tabBase = widget_tab(tlb, location=0, multiline=10)

  tabNum = n_elements(loadDataTabs)
  
  ; set the titles
  for tab_idx = 0, n_elements(loadDataTabs)-1 do begin
      if loadDataTabs[tab_idx].panel_title eq '' then loadDataTabs[tab_idx].panel_title = loadDataTabs[tab_idx].mission_name
  endfor

  if tabNum eq 0 then begin 
    message,'ERROR: No tabs found in config file. Probable config file error' ;use of message to send error here is okay, methinx, 'cause it is serious and will be caught by the parent error handler'
  endif

      ; create a widget base for each tab
  tabArray = make_array(tabNum, /long)
  for i=0,tabNum-1 do begin
      tabArray[i] = widget_base(tabBase, title=loadDataTabs[i].panel_title, $
                           event_pro=loadDataTabs[i].procedure_name)    
  endfor
     
  bottomBase = widget_base(tlb, /Col, YPad=6, /Align_Left)
  
  ; the following struct saves information on the currently selected panel
  ; so that the correct panel is restored on reopening the load data window
  userSelectStruct = {panelID: 0}
   
  if ~ptr_valid(userSelectPtr) then begin
    userSelectPtr = ptr_new(userSelectStruct)
  endif
  
  widget_control, tabBase, set_tab_current=(*userSelectPtr).panelID
    
  ; Create Status Bar Object
  okButton = Widget_Button(bottomBase, Value='Done', XSize=75, uValue='DISMISS', $
    ToolTip='Dismiss Load Panel', /align_center)
  statusText = Obj_New('SPD_UI_MESSAGE_BAR', $
                       Value='Status information is displayed here.', $
                        bottomBase, XSize=135, YSize=1)

  windowStorage->getProperty, callSequence=callSequence
  
  ;At the moment, this saves user preferences only for the main SPEDAS load window.  
  ; commented out after load data plugins were added since the ordering of 
  ; tabs in this panel is dependent on the plugin file names. We're now using a 
  ; struct with a similar name to persist tab # throughout a SPEDAS session
;  userSelectStruct = $
;    {inst:-1,$
;     coord:-1,$
;     observPtr:ptr_new(-1),$
;     level1Ptr:ptr_new(-1),$
;     level2Ptr:ptr_new(-1),$
;     uncalibrated:0}

  treeArray = objarr(tabNum)
  timeArray = lonarr(tabNum)
   
  for i= 0, tabNum-1 do begin

    call_procedure, strtrim(loadDataTabs[i].procedure_name), tabArray[i], loadedData, historyWin, statusText, $
                    treeCopyPtr, timeRange, callSequence,loadTree=thisTreeArray, $
                    timeWidget=otherTimeWidget
    timeArray[i] = otherTimeWidget
    treeArray[i] = thisTreeArray
      
  endfor     
  
  tabTitleText=loadDataTabs.panel_title

  state = {tlb:tlb, gui_id:gui_id,tabBase:tabBase, historyWin:historyWin, statusText:statusText,treeArray:treeArray,$
        timeArray:timeArray,tabArray:tabArray,treeCopyPtr:treeCopyPtr,previousTab:0,tabTitleText:tabTitleText, userSelectPtr:userSelectPtr}

  CenterTLB, tlb
  Widget_Control, tlb, Set_UValue = state, /No_Copy
  Widget_Control, tlb, /Realize
  
  ; NOTE: after refactoring the plugins, the following will only work if THEMIS
  ; is the first plugin loaded (this means it must be the first file in the directory)
;  Widget_Control, tlb, get_UValue = state, /No_Copy
;  spd_ui_load_data_set_user_select,state
;  Widget_Control, tlb, set_UValue = state, /No_Copy

  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif
  
  XManager, 'spd_ui_init_load_window', tlb, /No_Block
 
  RETURN
end
