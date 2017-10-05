;+
; Function:
;         spd_ui_add_variable
;
; Purpose:
;         Widget for selecting a variable in the GUI
;
; Input:
;         guiId: standard ID of the master widget
;         loadedData: object containing loadedData 
;         guiTree: pointer to the widget tree
;         historywin: history window object
;         statusBar: status bar object
;         
; Output:
;         Returns an array of strings containing the selected data 
; 
; Keywords:
;         multi: allow multple selections
;         control: no interpolation; match the selected data to the control variable point-by-point
;         leafonly: only allow the user to select a leaf
;         treemode: selection mode for the tree widget. See the header of the spd_ui_widget_tree object
;                 for details
;         windowtitle: override the default window title
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_add_variable.pro $
;-
pro spd_ui_add_variable_event, event

  Compile_Opt idl2, hidden
  
  Widget_Control, event.TOP, Get_UValue=state
  
  ;Put a catch here to insure that the state remains defined
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error in Variable Options'
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
  ;kill request block
  
  IF (Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN
    *state.guiTree = state.treeObj->GetCopy()
    Widget_Control, event.top, /Destroy
    RETURN
  ENDIF
  
  Widget_Control, event.id, Get_UValue=uval
  
  CASE uval OF
  
    'CANC': BEGIN
    
      state.historyWin->Update,'Exiting variable selection widget'
      state.statusbar->Update,'Exiting variable selection widget'
      ;
      *state.guiTree = state.treeObj->GetCopy()
      
      Widget_Control, event.top, /destroy
      RETURN
    END
    'OK': begin
      ;Get indices of user selection:
      ;******************************
      id=widget_info(event.top,find_by_uname='addvarwlist')
      
      widget_control,id,get_value=wlist ;tree
      *state.return=wlist->GetValue() ;tree -- may need to reconstruct indicies to NAME.
      
      *state.guiTree = state.treeObj->GetCopy()
      Widget_Control, event.top, /destroy
      RETURN
    end
    else:
  ENDCASE
  
end

function spd_ui_add_variable, guiId,loadedData,guiTree,historywin,statusBar,multi=multi,control=control,leafonly=leafonly,treemode=treemode,windowtitle=windowtitle

  Compile_Opt idl2, hidden
  
  if undefined(treemode) then treemode = 1
  if undefined(windowtitle) then windowtitle = 'Add Variable(s)'
  if ~keyword_set(multi) then multi = 0

  
  tlb=widget_base(/col,title=windowtitle,group_leader=guiId,/floating,/modal, $
    xpad=4,ypad=4,space=6)
  ;  buttonbase=widget_base(tlb,/row,/align_center)
    
  ;Widgets:
  ;********
    
  ;add description if choosing control
  if keyword_set(control) then begin
    cr = ssl_newline()
    text = [ 'The selected data will be matched to the control variable point-by-point.', $
      'No interpolation will occur.']
      
    ;cross platform size control
    mx = max(strlen(text), mi)
    dummy = widget_label(tlb, value=text[mi])
    geo = widget_info(dummy,/geo)
    widget_control, dummy, /destroy
    
    title = widget_label(tlb, value=strjoin(text,cr), $
      xsize=geo.scr_xsize, $
      ysize=geo.scr_ysize*2.1 )
  endif
  
  treeObj=obj_new('spd_ui_widget_tree',tlb,'VARIABLES',loadeddata,xsize=400,ysize=400,uname='addvarwlist',mode=treemode, $
    multi=multi,leafonly=leafonly,/showdatetime,from_copy=*guiTree)  ;tree
  
    
  buttonbase=widget_base(tlb,/row,/align_center)
  okbutton=widget_button(buttonbase,value='OK', uval='OK')
  cancelbutton=widget_button(buttonbase,value='CANCEL', uval = 'CANC')
  
  return_value = ptr_new('')
  
  state = {treeObj:treeObj,guiTree:guiTree,historywin:historywin,statusbar:statusbar,return:return_value}
  
  ;Make sure the window is centered:
  ;*********************************
  CenterTlb, tlb
  
  ;Make and store state structure:
  ;********************************
  widget_control,tlb,set_uval=state
  
  ;Realize widget:
  ;***************
  widget_control,tlb,/realize
  
  ;keep windows in X11 from snaping back to
  ;center during tree widget events
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif
  
  XManager, 'spd_ui_add_variable', tlb, /No_Block
  
  ;Return success:
  ;***************
  return,*return_value
  
end
