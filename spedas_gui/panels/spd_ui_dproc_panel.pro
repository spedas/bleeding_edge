;+
;NAME:
; spd_ui_dproc_panel
; 
;PURPOSE:
; A widget interface that can be used to set the active data variables
; and perform various data analysis tasks.
; 
;CALLING SEQURNCE:
; spd_ui_dproc_panel, gui_id
; 
;INPUT:
; gui_id = the id of the calling widget
; 
;OUTPUT:
; No explicit output, processes are done
; 
;HISTORY:
; 21-nov-2008, jmm, jimm@ssl.berkeley.edu
; 24-apr-2015, af, event handler uses uname instead of uvalue
; 
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-04-24 18:45:02 -0700 (Fri, 24 Apr 2015) $
;$LastChangedRevision: 17429 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_dproc_panel.pro $
;-

;helper function for setting active data/determining tree selection
pro spd_ui_dproc_panel_get_tree_select, state, sobj

    compile_opt idl2, hidden

  widget_control,state.loadedlist,get_value=treeobj
  treeptrarr=treeobj->GetValue()
  if ~is_num(treeptrarr[0]) then begin
      If(ptr_valid(state.data_choice)) Then ptr_free, state.data_choice
      treelist=(*(treeptrarr[0])).groupname               ;Concatenate data names.
      n_treeptrarr=n_elements(treeptrarr)
      if n_treeptrarr gt 1 then begin
        for i=1,n_treeptrarr-1 do treelist=[treelist,(*(treeptrarr[i])).groupname]
      endif
      state.data_choice=ptr_new(treelist)
      sobj -> update, 'Variables chosen: '+strjoin(*state.data_choice, ',', /single)
      state.info.historywin-> update, 'Data Processing: Variables chosen: '+strjoin(*state.data_choice, ',', /single)
  Endif Else begin
    ptr_free, state.data_choice
    sobj -> update, 'Bad Selection, Please try again'
    state.info.historywin-> update, 'Data Processing: Bad Selection, Please try again'
  endelse

end

; helper function for determining the selected active data
pro spd_ui_dproc_panel_get_active_select, state, sobj

    compile_opt idl2, hidden

  pindex = widget_info(state.activelist, /list_select)
  If(pindex[0] Ne -1) Then Begin
      If(ptr_valid(state.act_data)) Then Begin
          If(ptr_valid(state.data_choice)) Then ptr_free, state.data_choice
          state.data_choice = ptr_new((*state.act_data)[pindex])
          sobj -> update, 'Variables chosen: '+strjoin(*state.data_choice, ',', /single)
          state.info.historywin-> update, 'Data Processing: Variables chosen: '+strjoin(*state.data_choice, ',', /single)
      Endif Else begin
        sobj -> update, 'No Active Data Available'
        state.info.historywin-> update, 'Data Processing: No Active Data Available'
      endelse
  Endif Else begin
    sobj -> update, 'Bad Selection, Please try again'
    state.info.historywin-> update, 'Data Processing: Bad Selection, Please try again'
  Endelse
end


Pro spd_ui_dproc_panel_event, event

 ; print, ''
;Catch here to insure that the state remains defined
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    if is_struct(state) then begin
      FOR j = 0, N_Elements(err_msg)-1 DO state.info.historywin->update,err_msg[j]
      x=state.gui_id
      histobj=state.info.historywin
      if obj_valid(state.treeObj) then begin
        *state.treeCopyPtr = state.treeObj->getCopy() 
      endif  
    endif
    Print, 'Error--See history'
    ok=error_message('An unknown error occured and the window must be restarted. See console for details.',$
       /noname, /center, title='Error in Data Processing')
    If(is_struct(state)) Then Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    if widget_valid(x) && obj_valid(histobj) then begin
      spd_gui_error,x,histobj
    endif
    RETURN
  ENDIF

widget_control, /hourglass

;Get info from state, and data object from gui_id
widget_control, event.top, get_uvalue = state, /no_copy
dproc_id = state.master
dobj = state.info.loadeddata
sobj_main = state.info.statusbar
sobj = state.statusbar
historywin = state.info.historywin

;kill request block
If(TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_KILL_REQUEST') Then Begin
    historywin-> update, 'Kill request on Data Processing Panel'
    if obj_valid(state.treeObj) then begin
      *state.treeCopyPtr = state.treeObj->getCopy() 
    endif  
    widget_control, event.top, set_uvalue = state, /no_copy
    widget_control, event.top, /destroy
    sobj_main -> update, 'Data Processing Panel killed'
    Return
Endif
If(obj_valid(dobj) Eq 0) Then message, 'No valid data object'

;now deal with the event
uname = widget_info(event.id, /uname)
SPL = strsplit(uname, ':', /extract)

;uvalues only used for plugins atm, coule be expanded if needed
widget_control, event.id, get_uvalue=uvalue

;Handle most data processing options
If(spl[0] Eq 'PROC') Then Begin
    ptree = ptr_new(state.treeobj->getcopy())
    otp = spd_ui_dproc(state.info, spl[1], ext_statusbar = sobj, plugin_structure=uvalue, $ 
                           group_leader = state.master, ptree = ptree)
    
    ;synchronize tree expansion state.(Since Interpol popup uses data tree)
    if spl[1] eq 'INTERPOL' then begin
      state.treeobj->update,from_copy=*ptree
    endif
    
    ptr_free, ptree
    widget_control, event.top, set_uvalue = state, /no_copy
    spd_ui_dproc_reset_act_data, dproc_id, /update_tree

;Handle coordinate transformations
Endif Else If(spl[0] Eq 'COTRANS') Then Begin

    active = state.info.loadedData->getActive(/parent)
    state.info.windowStorage->getProperty,callSequence=callSequence
    spd_ui_cotrans, event.top,spl[1],active,state.info.loadedData, sobj,historywin,callSequence
    widget_control, event.top, set_uvalue = state, /no_copy
    spd_ui_dproc_reset_act_data, dproc_id, /update_tree

;Handle window events
Endif Else Begin
    state.info.historywin->update,'SPD_UI_DPROC_PANEL: User Value: '+uname,/dontshow
;    sobj->update,string('SPD_UI_DPROC_PANEL: User Value: '+uval)
    Case uname of
        'CANC': Begin
            state.info.historywin-> update, 'Closing Data Processing Panel'
            if obj_valid(state.treeObj) then begin
              *state.treeCopyPtr = state.treeObj->getCopy() 
            endif 
            widget_control, event.top, set_uvalue = state, /no_copy
            widget_control, event.top, /destroy
            sobj_main -> update, 'Data Processing Panel Closed'
            Return
        End
        'DATALOADLIST': Begin
          spd_ui_dproc_panel_get_tree_select, state, sobj
        End
        'ACTIVELIST': Begin
          spd_ui_dproc_panel_get_active_select, state, sobj
        End
        'CLEAR':Begin
            dobj -> clearallactive
            sobj -> update, 'All Active variables cleared'
            state.info.historywin-> update, 'All Active variables cleared'
            spd_ui_dproc_reset_act_data, state
        End
        'SETACTIVE':Begin
            spd_ui_dproc_panel_get_tree_select, state, sobj
            If(ptr_valid(state.data_choice)) Then Begin
                dc = *state.data_choice
                For j = 0, n_elements(dc)-1 Do dobj -> setactive, dc[j]
                ptr_free, state.data_choice
                spd_ui_dproc_reset_act_data, state
                sobj -> update, 'Variables set to active: '+strjoin(dc, ',', /single)
                state.info.historywin-> update, 'Variables set to active: '+strjoin(dc, ',', /single)
            Endif Else sobj -> update, 'No Data has been selected'
        End
        'UNSETACTIVE':Begin
            spd_ui_dproc_panel_get_active_select, state, sobj
            If(ptr_valid(state.data_choice)) Then Begin
                dc = *state.data_choice
                For j = 0, n_elements(dc)-1 Do dobj -> clearactive, dc[j]
                ptr_free, state.data_choice
                spd_ui_dproc_reset_act_data, state
                sobj -> update, 'Variables set to inactive: '+strjoin(dc, ',', /single)
                state.info.historywin-> update, 'Variables set to inactive: '+strjoin(dc, ',', /single)
            Endif Else begin
              sobj -> update, 'No Data has been selected'
              state.info.historywin-> update, 'No Data has been selected'
            endelse
        End
        'TRASH':Begin
            ; delete data directly from the data processing window - egrimes 1/4/13
            spd_ui_dproc_panel_get_tree_select, state, sobj
            If(ptr_valid(state.data_choice)) Then Begin
                select = *state.data_choice
                result=dialog_message('Are you sure you want to delete the selected data from the GUI?', $
                    /question,/center, title='Data Processing: Delete GUI data?')
                if result eq 'Yes' then begin
                    for i = 0,n_elements(select)-1 do begin
                      if ~state.info.loadedData->remove(select[i]) then begin
                        state.statusBar->update,'Error deleting: ' + select[i]
                        state.info.historyWin->update,'Error deleting: ' + select[i]
                        return
                      endif else begin
                        state.info.windowStorage->getProperty,callSequence=callSeq
                          ; store deletion in the call sequence object
                          if obj_valid(callSeq) then begin
                              callSeq->adddeletecall,select[i]
                          endif else begin
                              dprint, dlevel = 0, 'Error getting the call sequence object from the window in spd_ui_dproc_panel'
                          endelse
                      endelse 
                    endfor
                    if double(!version.release) lt 8.0d then heap_gc
                    state.treeobj->update
                    state.statusBar->update,'Deleted Selection'
                    state.info.historyWin->update,'Deleted Selection'
                    spd_ui_dproc_reset_act_data, state
                    state.treeobj->clearSelected
                endif
            Endif Else begin
              sobj -> update, 'No Data has been selected'
              state.info.historywin-> update, 'No Data has been selected'
            endelse
        End
        else:begin
          ;nothing to do
        end
    Endcase
    widget_control, event.top, set_uvalue = state, /no_copy
Endelse
Return
End

Pro spd_ui_dproc_panel, info

err_xxx = 0
catch, err_xxx
If(err_xxx Ne 0) Then Begin
    catch, /cancel
    Help, /Last_Message, Output=err_msg
    FOR j = 0, N_Elements(err_msg)-1 DO begin
      Print, err_msg[j]
      info.historywin->update,err_msg[j]
    endfor
    Print, 'Error--See history'

    ok = error_message('An unknown error occured starting Data Processing. See console for details.', $
                       traceback=0, /noname, /center, title='Error in Data Processing')
    widget_control,master,/destroy
    spd_gui_error, info.master, info.historywin
    Return
Endif

gui_id = info.master
master = widget_base(/col, title = 'Data Processing', $
                     group_leader = gui_id, /floating, /tlb_kill_request_events, /modal)

;This base widget will hold the lists of loaded and active data:
listsbase = widget_base(master, /row)
loadedbase = widget_base(listsbase, /column)
addbase = widget_base(listsbase, /column, ypad=140)
activebase = widget_base(listsbase, /column, ypad=5)
analysismenu = widget_base(listsbase, /column)

;This base will hold the buttons on the bottom:
buttonbase = widget_base(master, /row, /align_center)

; Create Status Bar Object
statusBar = Obj_New('SPD_UI_MESSAGE_BAR', Value = 'Status information is displayed here.', master, Xsize = 100, YSize = 1)

loadedLabel = WIDGET_LABEL(loadedBase, value='Loaded Data')

;get the loaded data and active data:
state = {master:master, gui_id:gui_id, info:info, $
         val_data:ptr_new(), data_choice:ptr_new(), $
         act_data:ptr_new(), val_data_t:ptr_new(), $
         act_data_t:ptr_new(), treeobj:obj_new(), $
         activelist:-1L,loadedlist:-1L,$
         statusbar:statusbar,treeCopyPtr:info.guiTree}

spd_ui_dproc_reset_act_data, state, /update_tree ;this sets up the data lists

screen_size = get_screen_size()
xtree_size = min([300,floor((screen_size[0]/4.5))])
ytree_size = min([300,floor((screen_size[1]/3.5))])
xtree_size = 270
ytree_size = 370
state.treeobj = obj_new('spd_ui_widget_tree', loadedbase, 'DATALOADLIST', $
                        info.loadeddata, xsize = xtree_size, ysize = ytree_size, mode = 0, $
                        /multi, uname = 'dataloadlist', /showdatetime)
                        
state.treeObj->update,from_copy=*state.treeCopyPtr
state.loadedlist=widget_info(master,find_by_uname='dataloadlist')

;set up the buttons to add, subtract active data as in the load data widget
getresourcepath,rpath
leftArrow = read_bmp(rpath + 'arrow_180_medium.bmp', /rgb)
rightArrow = read_bmp(rpath + 'arrow_000_medium.bmp', /rgb)
trashcan = read_bmp(rpath + 'trashcan.bmp',/rgb)

spd_ui_match_background, master, leftArrow
spd_ui_match_background, master, rightArrow
spd_ui_match_background, master, trashcan

;plusbmp = filepath('shift_right.bmp', SubDir = ['resource', 'bitmaps'])
;minusbmp = filepath('shift_left.bmp', SubDir = ['resource', 'bitmaps'])
addButton = Widget_Button(addBase, Value = rightArrow, /Bitmap,  uname = 'SETACTIVE', $
                          ToolTip = 'Set Selected Data to Active')
minusButton = Widget_Button(addBase, Value = leftArrow, /Bitmap, $
                            uname = 'UNSETACTIVE', $
                            ToolTip = 'Unset selected data from Active')
trashbutton = Widget_Button(addBase, Value=trashcan, /Bitmap,  uname='TRASH', $
              ToolTip='Delete data selected in the list of loaded data', xsize=27, ysize=27) 
activeLabel = Widget_Label(activeBase, value='Active Data')

state.activelist = widget_list(activebase, value = *state.act_data_t, $
                               uname = 'ACTIVELIST', $
                               XSize = 55, YSize = 22, scr_ysize=ytree_size, /multiple)

;buttons along the bottom
clear_button = Widget_Button(buttonBase, Value = ' Clear Active ', XSize = 85, $
                             uname = 'CLEAR')
; Analysis Pull Down Menu, hacked from spd_gui.pro
;analysisMenu = Widget_Button(buttonbase, Value='Analysis ',/menu
;xsize = 85)
subAvgMenu = Widget_Button(analysisMenu, Value='Subtract Average ', $
                           uname='PROC:SUBAVG', tooltip = 'Subtracts average of each trace')
subMedMenu = Widget_Button(analysisMenu, Value='Subtract Median ', $
                           uname='PROC:SUBMED', tooltip = 'Subtracts median of each trace from each trace')
smoothMenu = Widget_Button(analysisMenu, Value='Smooth Data... ', uname='PROC:SMOOTH', $
                          tooltip = 'Smooths data in time, using input resolution')
hpfiltMenu = Widget_Button(analysisMenu, Value='High Pass filter... ', uname='PROC:HPFILT', $
                          tooltip = 'Subtracts smoothed values from each trace')
blkAvgMenu = Widget_Button(analysisMenu, Value='Block Average... ', uname='PROC:BLKAVG',$
                          tooltip = 'Block time average of each trace')
clipMenu = Widget_Button(analysisMenu, Value='Clip... ', uname='PROC:CLIP', $
                         tooltip = 'Clips traces at input max and min values')
deflagMenu = Widget_Button(analysisMenu, Value='Deflag... ', uname='PROC:DEFLAG', $
                           tooltip = 'Replaces NaN values with interpolated or repeated values')
degapMenu = Widget_Button(analysisMenu, Value='Degap... ', uname='PROC:DEGAP',$
                          tooltip = 'Fills data gaps with NaN values')
interpMenu = Widget_Button(analysisMenu, value='Interpolate...', uname='PROC:INTERPOL', $
                           tooltip = 'Performs interpolation on active data')
spikeMenu = Widget_Button(analysisMenu, Value='Clean Spikes...', uname='PROC:SPIKE', $
                          tooltip = 'Replaces single-point spikes with NaN values')
derivMenu = Widget_Button(analysisMenu, Value='Time Derivative...', uname='PROC:DERIV', $
                          tooltip = 'Time derivatives of each trace')
waveMenu = Widget_Button(analysisMenu, Value='Wavelet Transform...', uname='PROC:WAVE', $
                         tooltip = 'Performs wavelet transform for each trace')
pwrspecMenu = Widget_Button(analysisMenu, Value='Power Spectrum...', uname='PROC:PWRSPC', $
                         tooltip = 'Performs Dynamic power spectrum for each trace')
cotranMenu = Widget_Button(analysisMenu, Value='Coordinate Transform...', uname='PROC:COTRAN', $
                         tooltip = 'Performs a coordinate transform on active data', /menu)
;validCoords = ['DSL', 'SSL', 'GSE', 'GEI', 'SPG', 'GSM', 'GEO', 'SM', 'SSE', 'SEL', 'MAG']

; make a list of valid coordinate systems 
coord_sys_obj = obj_new('spd_ui_coordinate_systems')
validCoords = coord_sys_obj->makeCoordSysList(/uppercase)
obj_destroy, coord_sys_obj

coordMenus = LonArr(N_Elements(validCoords))
FOR i = 0, N_Elements(validCoords)-1 DO $
  coordMenus[i] = Widget_Button(cotranMenu, Value=string(validCoords[i]+'  '),uname='COTRANS:'+validCoords[i])
splitMenu = Widget_Button(analysisMenu, Value='Split Variable', uname='PROC:SPLIT', $
                         tooltip = 'Splits a variable into its different componenets (e.g. _x,_y,_z)')
joinMenu = Widget_Button(analysisMenu, Value='Join Variables...', uname='PROC:JOIN', $
                         tooltip = 'Joins similar variables into one. To be used after splitting.')

valid_plugins = info.pluginManager->getDataProcessingPlugins()

pluginsMenu = Widget_Button(analysisMenu, value='More...', $ uname='PROC:PLUGIN', $
                            tooltip='More data processing options...', /menu)

spd_ui_plugin_menu, pluginsMenu, valid_plugins, uname='PROC:PLUGIN'

;plugin_menus = lonarr(n_elements(valid_plugins))
;for i = 0, n_elements(plugin_menus)-1 do $
;    plugin_menus[i] = Widget_Button(pluginsMenu, value=valid_plugins[i].item, uname='PROC:PLUGIN;'+valid_plugins[i].procedure)    

;Dude...
cancel_button = Widget_Button(buttonBase, Value = '  Done   ', XSize = 85, $
                              uname = 'CANC')
CenterTlb, master
Widget_Control, master, Set_UValue = state, /No_Copy
Widget_Control, master, /Realize

  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, master, xoffset=0, yoffset=0
  endif

XManager, 'spd_ui_dproc_panel', master, /No_Block

End



