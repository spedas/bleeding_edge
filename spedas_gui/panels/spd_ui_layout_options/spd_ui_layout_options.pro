;+ 
;NAME: 
; spd_ui_layout_options
;PURPOSE:
; This routine creates and handles the layout widget.
;CALLING SEQUENCE:
; spd_ui_layout_options
;INPUT:
; info:  Info structure from spd_gui.
;OUTPUT:
; none
;HISTORY:
;
;(lphilpott, 06/21/2011) Modified the event handling for the spinners so that it delays handling invalid entries until
;the user clicks OK/Apply or changes panels. Added code to set the minimums for the Columns per page and Rows per page 
;spinner (as they change) so that the user can't click down below valid values.
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2014-07-28 13:47:52 -0700 (Mon, 28 Jul 2014) $
;$LastChangedRevision: 15619 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_layout_options/spd_ui_layout_options.pro $
;--------------------------------------------------------------------------------

; the following procedure exists to reset custom trace names set by the user
; in the event that they add/remove trace names from a panel using Layout Options
pro spd_ui_layout_sync_traces, state
  thewindows = state.info.windowStorage->getActive()
  
  panel_names = spd_ui_get_panels(thewindows, panelObjs=panelObjs)
  num_panels =  n_elements(panelObjs)
  if ~obj_valid(panelObjs[0]) then return

  for panel_idx = 0, num_panels-1 do begin
        ; grab the legendSettings
        panelObjs[panel_idx]->getProperty, legendSettings = legendSettings
        
        ; are custom traces set for this panel?
        legendSettings->getProperty, traces=traces, customTracesSet = customTracesSet
        
        ; check if custom traces are set by the user
        if customTracesSet eq 1 then begin
            ; need to check whether the user added a line to this panel
            (*state.panelObjs)[panel_idx]->getproperty, tracesettings=new_tracesettings
            new_traces=new_tracesettings->get(/all)
            
            num_old_traces = n_elements((*traces).tracenames)
            num_new_traces = n_elements(new_traces)
            if num_new_traces ne num_old_traces then begin ; out of sync
                legendSettings->setProperty, customTracesSet = 0
                
                out_of_sync_error = 'SPD_UI_LAYOUT_OPTIONS: Conflict with trace names set in Legend Options - resetting to default names.'
                state.historywin->update, out_of_sync_error
                state.statusbar->update, out_of_sync_error
            endif
        endif
  endfor
end

function spd_ui_check_panel_layout, state
  
  compile_opt idl2, hidden
  
  if obj_valid((*state.panelObjs)[0]) then begin
    for i=0,n_elements(*state.panelObjs)-1 do begin
    
      currentPanel = (*state.panelObjs)[i]
      panelLayoutPos = state.cwindow->getPanelPos(currentPanel)
      
      if panelLayoutPos eq -1 then begin
        state.historywin->update,'SPD_UI_LAYOUT_OPTIONS: Problem evaluating locked panel layout.'
        state.statusbar->update,'SPD_UI_LAYOUT_OPTIONS: Problem evaluating locked panel layout.'
        ok=error_message('Problem panel layout in "Locked Mode," probably from overlapping panels.' + $
                         ' Closing Layout Window and resetting to previous layout.',/noname,/center, $
                         title='Error in Plot/Layout Options', traceback=0)
        return, 0
      endif
    endfor
    return, 1
  endif else return, 1
end


; Resize the page to fit the current panels
;
pro spd_ui_layout_resize_page, state, row=row, col=col, single=single

    compile_opt idl2, hidden

  rows = 2
  cols = 1

  ;get largest values
  for i=0, n_elements(*state.panelObjs)-1 do begin
    l = (*state.panelObjs)[i]->getlayoutstructure()
    rows = rows > (l.row + l.rspan - 1)
    cols = cols > (l.col + l.cspan - 1)
  endfor 

  ; get current settings 
  state.cWindow->getProperty, nrows=nrows, ncols=ncols
  
  ; check difference if only a single collapse is requested
  r = keyword_set(single) ? nrows-rows eq 1 : 1b
  c = keyword_set(single) ? ncols-cols eq 1 : 1b
  
  ;update obj and widgets
  if keyword_set(row) and r then begin
    state.cWindow->setProperty,nrows=rows
    widget_control, state.rowPageText, set_value = rows
  endif
  
  if keyword_set(col) and c then begin
    state.cWindow->setProperty, ncols=cols
    widget_control, state.colPageText, set_value = cols
  endif

end


;pro spd_ui_layout_set_yselect, state, value
;; set state.ySelect
;
;  compile_opt idl2, hidden
;  
;  value->getProperty, mode=mode
;
;  CASE mode OF
;    0: BEGIN                    ; tplot mode
;      val = value->getValue()
;
;      if ptr_valid(state.ySelect) then ptr_free, state.ySelect
;      
;      if size(val, /type) eq 10 then begin
;      
;        for i=0,n_elements(val)-1 do begin
;        
;          ; get datanames for each y selection
;          ySelect_i = (*val[i]).datanames
;          
;          ; add to array of y datanames
;          if i eq 0 then ySelect = ySelect_i else ySelect = [ySelect, ySelect_i]
;        endfor
;
;        state.ySelect = ptr_new(ySelect)
;        
;        ; get x datanames from timename of y data tree            
;        if ~state.compviewmode then begin
;        
;          if ptr_valid(state.xSelect) then ptr_free, state.xSelect
;          
;          for i=0,n_elements(val)-1 do begin
;          
;            ; make sure xSelect has same number of elements as ySelect
;            xSelect_i = replicate(((*val[i]).timename), n_elements((*val[i]).datanames))
;            
;            ; add to array of x datanames
;            if i eq 0 then xSelect = xSelect_i else xSelect = [xSelect, xSelect_i]
;          endfor
;          
;          state.xSelect = ptr_new(xSelect)
;        endif
;      endif
;    END
;    1: BEGIN
;      yNames = value->getValue()
;      if ptr_valid(state.ySelect) then ptr_free, state.ySelect
;      state.ySelect = Ptr_New(yNames)
;    END
;    2: BEGIN
;      yNames = value->getValue()
;      if ptr_valid(state.ySelect) then ptr_free, state.ySelect
;      state.ySelect = Ptr_New(yNames)
;    END
;    3: BEGIN
;      yNames = value->getValue()
;      
;      for i=0,n_elements(yNames)-1 do begin
;      
;        ; get datanames for each y selection
;        if state.loadedData->isparent(yNames[i]) then begin
;          group = state.loadedData->getGroup(yNames[i])
;          ySelect_i = group->getDataNames()
;        endif else ySelect_i=yNames[i]
;        
;        ; add to array of y datanames
;        if i eq 0 then ySelect = ySelect_i else ySelect = [ySelect, ySelect_i]
;      endfor
;      
;      ySelect = ySelect[uniq(strlowcase(ySelect),bsort(strlowcase(ySelect)))]
;
;      if ptr_valid(state.ySelect) then ptr_free, state.ySelect
;      state.ySelect = ptr_new(ySelect)
;      
;      for i=0,n_elements(ySelect)-1 do begin
;      
;        group = state.loadedData->getobjects(name=ySelect[i])
;        group[0]->getproperty, timename=xSelect_i, indepName=indepName
;        
;        ; use diff quantity for x-axis if specified by indepName 
;        if is_string(indepName) then xSelect_i=indepName
;        
;        ; add to array of x datanames
;        if i eq 0 then xSelect = xSelect_i else xSelect = [xSelect, xSelect_i]
;      endfor
;      
;      if ptr_valid(state.xSelect) then ptr_free, state.xSelect
;      state.xSelect = ptr_new(xSelect)
;    END
;  ENDCASE
;end


pro spd_ui_layout_draw_update,tlb,state,apply=apply

  compile_opt idl2,hidden

  state.info.drawObject->update,state.info.windowStorage,state.info.loadedData, errmsg=errmsg
  
  ; Issue a dialog message to user if an important error has occured. 
  ; Note: not every drawObject error will return an errmsg structure.
  ; Note: no reset is done as this would complicate matters as the user probably wouldn't want to lose added panels etc.
  if keyword_set(errmsg) then begin
    if in_set('TYPE', tag_names(errmsg)) then begin
      if strupcase(errmsg.type) eq 'ERROR' then begin
        if in_set('VALUE', tag_names(errmsg)) then begin
          ok = dialog_message('Error: '+errmsg.value,/center)
        endif
      endif
    endif
  endif
  state.info.drawObject->draw
  state.info.scrollbar->update

end


pro spd_ui_update_panel_list, state=state, panelNames=panelNames, $
                              panelValue=panelValue, panel_ValueInfo=panel_ValueInfo, $
                              panelLayout=panelLayout, ntr=ntr
; get panel/tracenames and panel layout

  compile_opt idl2, hidden

  if state.npanels LT 1 then begin
    result=dialog_message("There are no panels on this page. Please create a panel before performing operations.", /INFO, /CENTER) 
    return
  endif
  
  panelNames = strarr(state.npanels)
  ntr = intarr(state.npanels)

  for i = 0,state.npanels-1 do begin ; loop over panels
  
    cPanel = (*state.panelObjs)[i]
    
    panelNames[i] = cPanel->constructPanelName()
    state.cwindow->GetProperty, locked=locked
    if i eq locked then panelNames[i] = state.lockPrefix + panelNames[i]
    
    if i eq 0 then panelValue = panelNames[i] $
      else panelValue = [panelValue, panelNames[i]]

    if i eq 0 then panelLayout = cPanel->getLayoutStructure() $
      else panelLayout = [panelLayout, cPanel->getLayoutStructure()]
    
    if i eq 0 then panel_ValueInfo = {panelListInfo, ispanel:1, istrace:0, $
                                     panelid:panelLayout[i].id, traceid:-1} $
      else panel_ValueInfo = [panel_ValueInfo, {panelListInfo, ispanel:1, istrace:0, $
                                              panelid:panelLayout[i].id, traceid:-1}]
    
    cPanel->getProperty,traceSettings=traceSettings
    traces = traceSettings->get(/all)
    
    if obj_valid(traces[0]) then begin
      ntr[i] = n_elements(traces)
      trNames = cPanel->constructTraceNames()
      
      for j = 0,ntr[i]-1 do begin
  
        panelValue = [panelValue, trNames[j]]
        
        panel_ValueInfo = [panel_ValueInfo, {panelListInfo, ispanel:0, istrace:1, $
                                           panelid:panelLayout[i].id, traceid:j}]
        
        traces[j]->getProperty,dataX=dx, dataY=dy
        
        if obj_isa(traces[j],'spd_ui_spectra_settings') then begin
            traces[j]->getProperty,dataZ=dz
        endif else dz = ''
        
      endfor
      
    endif
  endfor
 
end

pro spd_ui_init_tree_widgets, tlb, state=state

compile_opt idl2, hidden

  statedef = ~(~size(state,/type))
  ; 
  if ~statedef then begin
    Widget_Control, tlb, Get_UValue=state, /No_Copy  ;Only get STATE if it is not passed in.
  endif else begin
    tlb = state.tlb
  endelse
  
  ;**********************************************************
  ; Initialize tree widgets
  ;**********************************************************
  
  widget_control,tlb,update=0
  
  ;the index of the tab that should be selected after update
  tab_index = 0
    
  ; destroy tertiary (x-axis) tree widget
  if widget_info(state.terBase, /valid_id) then begin
    
    widget_control, state.terBase, /destroy
    if obj_valid(state.terTree) then obj_destroy, state.terTree
  endif
  
    ; destroy tertiary (y-axis) tree widget
  if widget_info(state.secBase, /valid_id) then begin
    
    widget_control, state.secBase, /destroy
    if obj_valid(state.secTree) then obj_destroy, state.secTree
  endif
  
    ; destroy tertiary (z-axis) tree widget
  if widget_info(state.priBase, /valid_id) then begin
    
    widget_control, state.priBase, /destroy
    if obj_valid(state.priTree) then obj_destroy, state.priTree
  endif
  
  if state.compviewmode then begin
 
  ; create secondary (x-axis) tree widget/object

    if state.xtree_copy gt 0 then begin
      xcopy=state.xtree_copy
    endif else if state.pritree_copy gt 0 then begin
      xcopy=state.pritree_copy
    endif else begin
      xcopy=0
    endelse

    state.terBase = Widget_Base(state.tabBase, Title='X-Var', /Col)
    state.terTree = obj_new('spd_ui_widget_tree', state.terBase,'TERTREE', $
                      state.loadedData, XSize=state.tree_size, YSize=340, $
                      mode=1, multi=1, leafonly=1, uname='tertree', /showdatetime,$
                      from_copy=xcopy)
    
    id = widget_info(state.tlb, find_by_uname='tertree')
    widget_control, id, get_value=val
   
    if state.sectree_copy gt 0 then begin
      ycopy=state.sectree_copy
    endif else if state.pritree_copy gt 0 then begin
      ycopy=state.pritree_copy
    endif else begin
      ycopy=0
    endelse
    
    state.secBase = Widget_Base(state.tabBase, Title='Y-Var', /Col)
    state.secTree = obj_new('spd_ui_widget_tree', state.secBase,'SECTREE', $
                          state.loadedData, XSize=state.tree_size, YSize=340, $
                          mode=3, multi=1,leafonly=1, uname='sectree', /showdatetime,$
                          from_copy=ycopy) 
        
    id = widget_info(state.tlb, find_by_uname='sectree')
    widget_control, id, get_value=val
  
    tab_index = 2 
        
    pri_name = 'Z-Var'
  endif else begin
    pri_name = 'Dependent Variable'
  endelse

  if state.pritree_copy gt 0 then begin
    pricopy=state.pritree_copy
  endif else begin
    pricopy=0
  endelse

  state.priBase = Widget_Base(state.tabBase, Title=pri_name, /Col)
  state.priTree = obj_new('spd_ui_widget_tree', state.priBase,'PRITREE', $
                    state.loadedData, XSize=state.tree_size, YSize=340, $
                    mode=3, multi=1, leafonly=1, uname='pritree', /showdatetime,$
                    from_copy=pricopy)

  
  id = widget_info(state.tlb, find_by_uname='pritree')
  widget_control, id, get_value=val
 
  ;set selected tab
  widget_control,state.tabBase,set_tab_current=tab_index
  
  widget_control,tlb,update=1
  
  if ~statedef then Widget_Control, tlb, Set_UValue=state, /No_Copy   ;Only put STATE if it was not passed in.

end

pro spd_ui_update_var_widget, tlb, state=state

  compile_opt idl2, hidden
  
  statedef = ~(~size(state,/type))
  ; 
  if ~statedef then begin
    Widget_Control, tlb, Get_UValue=state, /No_Copy  ;Only get STATE if it is not passed in.
  endif else begin
    tlb = state.tlb
  endelse
  
  
  ; Initialize Variables widget
  if state.npanels gt 0 then cpanel = (*state.panelObjs)[state.panel_sel]
  IF Obj_Valid(cpanel) THEN cpanel->GetProperty, Variables=variables ELSE variables=-1 
  IF Obj_Valid(variables) THEN varObjs = variables->Get(/all) ELSE varObjs=-1
  IF Size(varObjs, /type) EQ 11 THEN BEGIN
     varNames = make_array(N_Elements(varObjs), /string)
     FOR i=0,N_Elements(varObjs)-1 DO BEGIN
        varObjs[i]->GetProperty, Text=text
        IF Obj_Valid(text) THEN text->GetProperty, Value=value
        varNames[i]=value 
     ENDFOR
  ENDIF
  IF Size(varNames, /Type) NE 0 && N_Elements(varNames) GT 0 THEN BEGIN
    WIDGET_CONTROL, state.variableText, set_value=varnames,set_text_select=[0,0]
  ENDIF ELSE WIDGET_CONTROL, state.variableText, set_value=''
end

;modularizes repeated panel add code
;Adds a panel to the list, updates state representation
pro spd_ui_layout_add_panel,state

  compile_opt idl2,hidden
  
   ; Add panel to panel layout
  spd_ui_make_default_panel, state.info.windowStorage,state.template, outpanel=newpanel
      
  newpanelLayout = newpanel->getlayoutstructure()
  widget_control, state.rowText, set_value=newpanelLayout.row
  widget_control, state.colText, set_value=newpanelLayout.col
  widget_control, state.rowSpan, set_value=newpanelLayout.rspan
  widget_control, state.colSpan, set_value=newpanelLayout.cspan

; begin "in case of cancel of child panel" code
  state.cWindow->GetProperty, Panels=panels, locked=locked
  
;; move variables down from last panel if panels are locked
;; lphilpott 15-feb-2012 Removing this code as it is no longer necessary. Variables can be displayed between
;; locked panels now.
;  if locked ge 0 then begin
;    panelObjs = panels->get(/all)
;    if obj_valid(panelObjs[0]) then begin
;      np = n_elements(panelObjs)
;      if np ge 2 then begin
;        panelObjs[np-2]->getProperty, variables=variables
;        if array_equal(obj_valid(variables->get(/all)),1) then begin
;          panelObjs[np-1]->setProperty, variables=variables
;          panelObjs[np-2]->setProperty, variables=obj_new('IDL_Container')
;        endif
;      endif
;    endif
;  endif

  if ptr_valid(state.panels) then ptr_free, state.panels
  state.panels = ptr_new(panels)
; end "in case of cancel of child panel" code

  if ptr_valid(state.panelObjs) then ptr_free, state.panelObjs
  state.panelObjs = ptr_new(*state.panels->Get(/All))
  
  ; should apply any changes made to panel layout
  spd_ui_update_nrows_ncols,*state.panelObjs,state.cwindow,state.tlb
  
  state.npanels = n_elements(*state.panelObjs)
  if ptr_valid(state.panelValue) then ptr_free, state.panelValue
  if ptr_valid(state.panel_ValueInfo) then ptr_free, state.panel_ValueInfo
  if ptr_valid(state.panelNames) then ptr_free, state.panelNames
  ;panelNames = strarr(state.npanels)

  ; get panel/tracenames and panel layout
  spd_ui_update_panel_list, state=state, panelNames=panelNames, $
     panelValue=panelValue, panel_ValueInfo=panel_ValueInfo, $
     panelLayout=panelLayout

  if ptr_valid(state.panelLayout) then ptr_free, state.panelLayout
  state.panelLayout = ptr_new(panelLayout)
  state.panelValue = ptr_new(panelValue)
  state.panel_ValueInfo = ptr_new(panel_ValueInfo)
  state.panelNames = ptr_new(panelNames)
  state.panel_sel = state.npanels-1
  state.trace_sel = -1
  

  widget_control, state.rowText, /sensitive
  widget_control, state.colText, /sensitive
  widget_control, state.rowSpan, /sensitive
  widget_control, state.colSpan, /sensitive
  widget_control, state.shiftupButton, /sensitive
  widget_control, state.shiftdownButton, /sensitive
  widget_control, state.shiftleftButton, /sensitive
  widget_control, state.shiftrightButton, /sensitive
  id = widget_info(state.tlb, find_by_uname='rempan')
  widget_control, id, /sensitive
  widget_control, state.editButton, sensitive=1
  
  ; sensitize the add/edit variables button
  id = widget_info(state.tlb, find_by_uname='edvar')
  widget_control, id, /sensitive
  ; sensitize the lock/unlock panels buttons
  id = widget_info(state.tlb, find_by_uname='unlock_pan')
  widget_control, id, /sensitive
  id = widget_info(state.tlb, find_by_uname='lock_pan')
  widget_control, id, /sensitive
  
 ; Widget_Control, state.plusButton, /sensitive
  
  widget_control, state.panelList, set_value=*state.panelValue
  widget_control, state.panelList, $
                  set_list_select=where((*state.panelNames)[state.npanels-1] eq *state.panelValue)

  state.historywin->Update, 'SPD_UI_LAYOUT_OPTIONS: New panel added.'
  state.statusbar->update,'SPD_UI_LAYOUT_OPTIONS: New panel added.'

end

;This modularizes duplicated code for adding spectra and lines
;Set keyword spect, to indicate spectrograms should be created
;from current state.
pro spd_ui_layout_add_trace,event,state,spectra=spectra

  compile_opt idl2,hidden
  
    ;Add selected traces to selected panel

  ;IF N_Elements(*state.xSelect) GT 0 && N_Elements(*state.ySelect) GT 0 THEN BEGIN
  ;IF is_string(*state.xSelect) && (state.isspec || is_string(*state.ySelect)) THEN BEGIN
        
  h_msg = 'SPD_UI_LAYOUT_OPTIONS: '
  e_msg = ''
 
  state.historywin->Update, h_msg+'Adding Variables to Panel...'

  state.statusbar->update, 'Adding Variables to Panel...'
        
  spd_ui_layout_get_selection,state,x_select=xnames,y_select=ynames,z_select=znames,spectra=spectra
   
  nnames = n_elements(xnames)

  ; Check for auto-panel options and whether current panel is empty
  autopanel = widget_info(state.autopanel,/button_set)
  if autopanel and state.panel_sel ge 0 then begin
    ((*state.panelObjs)[state.panel_sel])->getproperty, tracesettings=tr
    autopanel = autopanel and (tr->count() gt 0)
  endif

;Loop Over Names
;---------------
  bad=0
  for i=0,nnames-1 do begin
    msg=''

    ;if ((n_elements(znames) eq 1 && znames[0] eq '') || znames[i] eq '') && keyword_set(spectra) then begin
    if undefined(znames) && keyword_set(spectra) then begin
      ;checking is ordered
      msg = 'Invalid Z variable selection, unable to add "'+xnames[i]+'"/"'+ynames[i]+'" to panel.'
    endif else if undefined(ynames[i]) then begin
      msg = 'Invalid Y variable selection, unable to add "'+xnames[i]+'" to panel.'
    endif else if undefined(xnames[i]) then begin
      msg = 'Invalid X variable selection, unable to add "'+ynames[i]+'" to panel.'
    endif

    if keyword_set(msg) then begin ;notify user, then skip variable or return
      bad++
      state.statusbar->update, msg
      state.historywin->update, h_msg+msg
      e_msg = 'At least one variable could not be added. Check history window for details.'
      continue
    endif 
    
    ;first valid component
    if i-bad eq 0 then begin    
      ;*************************
      ;Create a panel if none exist or automatic option is on
      ;*************************
      if state.npanels eq 0 or autopanel then begin
        spd_ui_layout_add_panel,state
      endif

      ;*************************
      ;Add trace/spectra
      ;*************************
      ;widget_control,event.id,get_value=value
      pindex = widget_info(state.panelList, /list_select)
    
      cpanel = (*state.panelObjs)[state.panel_sel]
    endif

    if ~keyword_set(spectra) then begin
      spd_ui_make_default_lineplot, state.info.loadedData, cpanel, $
                                    xnames[i], ynames[i], state.template,$
                                    gui_sbar=state.statusBar, datanum=i
    endif else begin
      
      spd_ui_make_default_specplot, state.info.loadedData, cpanel, $
                                        xnames[i], ynames[i], $
                                        znames[i], state.template,gui_sbar=state.statusBar
    
    endelse
    
  endfor
  ;End loop over names
  ;-------------------
  
  ;all components invalid
  if i-bad eq 0 then return


  ; begin "in case of cancel of child panel" code
    state.cWindow->GetProperty, Panels=panels, nRows=nrows, nCols=ncols;, locked=locked ;locked necessary?
    if ptr_valid(state.panels) then ptr_free, state.panels
    state.panels = ptr_new(panels)

    if ptr_valid(state.panelObjs) then ptr_free, state.panelObjs
    state.panelObjs = ptr_new(*state.panels->Get(/All))
    cpanel = (*state.panelObjs)[state.panel_sel]
  ; end "in case of cancel of child panel" code

    
    cpanel->getProperty, traceSettings=traceSettings
    state.trace_sel = traceSettings->Count() - 1
    
    ; check whether selected trace is line or spectra
    traces = traceSettings->get(/all) ; get traces to check for spectra/line type
    if obj_isa(traces[state.trace_sel], 'spd_ui_spectra_settings') then $
      state.is_trace_spec = 1 else state.is_trace_spec = 0

    state.npanels = n_elements(*state.panelObjs)
    if ptr_valid(state.panelValue) then ptr_free, state.panelValue
    if ptr_valid(state.panel_ValueInfo) then ptr_free, state.panel_ValueInfo
    if ptr_valid(state.panelNames) then ptr_free, state.panelNames

    ; get panel/tracenames and panel layout
    spd_ui_update_panel_list, state=state, panelNames=panelNames, $
       panelValue=panelValue, panel_ValueInfo=panel_ValueInfo, $
       panelLayout=panelLayout, ntr=ntr

    if ptr_valid(state.panelLayout) then ptr_free, state.panelLayout
    state.panelLayout = ptr_new(panelLayout)
    state.panelValue = ptr_new(panelValue)
    state.panel_ValueInfo = ptr_new(panel_ValueInfo)
    state.panelNames = ptr_new(panelNames)
    
        ;state.panel_sel = (*state.panel_ValueInfo)[pindex].panelid
        ;state.trace_sel = (*state.panel_ValueInfo)[pindex].traceid
    
    ; advance selected y-axis dataname to next down the list
    if nnames eq 1 && state.compviewmode eq 0 then begin
      ld = state.loadeddata ->getall()
      ldi = where(ld eq (keyword_set(spectra)?znames[0]:ynames[0]),c)
      if c gt 0 then begin
        ;use last index in case parent and child have same name
        if c gt 1 then ldi = ldi[n_elements(ldi)-1]
        next_idx = (long(ldi)+1) mod n_elements(ld)
        next = ld[next_idx]
        if state.loadeddata->ischild(next[0]) && ~state.loadeddata->isparent(next[0]) then begin
          *state.ySelect = next
          state.pritree->clearSelected
          state.pritree->setSelected,next
        endif
      endif
    endif
                   
    widget_control, state.panelList, set_value=*state.panelValue
    ;widget_control, state.panelList, set_list_select=state.panel_sel + ntr
    
    new_trace_ind = where(*state.panelValue eq (*state.panelNames)[state.panel_sel]) $
                      + ntr[state.panel_sel]
    widget_control, state.panelList, set_list_select=new_trace_ind
    widget_control, state.shiftleftButton, sensitive=0
    widget_control, state.shiftrightButton, sensitive=0
    widget_control, state.rowtext, sensitive=0
    widget_control, state.coltext, sensitive=0
    widget_control, state.rowSpan, sensitive=0
    widget_control, state.colSpan, sensitive=0
    widget_control, state.editButton, sensitive=1
    
    if state.trace_sel eq 0 then widget_control, state.shiftupButton, sensitive=0 $
      else widget_control, state.shiftupButton, sensitive=1
      
    if state.trace_sel eq (ntr[state.panel_sel]-1) then widget_control, state.shiftdownButton, sensitive=0 $
      else widget_control, state.shiftdownButton, sensitive=1
            
    msg = 'Add Finished. '+e_msg
    state.historywin->update, h_msg + msg
    state.statusbar->update, msg

end

;returns selection in x_select,y_select,z_select
;keyword spectra, set to return spectral selection rather than line selection
pro spd_ui_layout_get_selection,state,x_select=x_select,y_select=y_select,z_select=z_select,spectra=spectra

  compile_opt idl2,hidden
  
  undefine,x_select
  undefine,y_select
  undefine,z_select
  failtype = 0

  if state.compviewmode eq 0 then begin
  
    pri_selection = state.priTree->getValue()
  
    if ~keyword_set(pri_selection[0]) then begin
      ok=dialog_message("No variable selected, Unable to add to panel", /information, /center, dialog_parent=state.tlb)
      state.statusBar->update,'Warning: No variable selected'
      return
    endif
  
    ;get line selection when not in component mode
    if ~keyword_set(spectra) then begin
   
      undefine,obj_list
      
      ;loop over selections to get data ojects
      for i = 0,n_elements(pri_selection)-1 do begin
        
        ;if selection is a parent get all constituent objects
        if state.loadedData->isParent(pri_selection[i]) then begin
          group = state.loadedData->getGroup(pri_selection[i])
          
          if ~obj_Valid(group[0]) then continue
          
          dataObjects = group->getDataObjects()
          
        ;otherwise get named objects as usual
        endif else begin
        
          dataObjects = state.loadedData->getObjects(name=pri_selection[i])
  
        endelse
         
        if ~obj_valid(dataObjects[0]) then continue
        
        ;add to array of objects
        obj_list = array_concat(dataObjects,obj_list)
        
      endfor
      
      ;loop over objects to obtain lists of variable names
      for i = 0,n_elements(obj_list)-1 do begin
      
        if ~obj_valid(obj_list[i]) then continue
        
        obj_list[i]->getProperty,name=name,timeName=timeName,indepName=indepName
        
        y_select = array_concat(name,y_select)
        
        if ~keyword_set(indepName) then begin
          x_select = array_concat(timename,x_select)
        endif else begin
          x_select = array_concat(indepName,x_select)
        endelse
        
      endfor
    
    ;get spectra selection when not in component mode
    endif else begin
    
      ;loop over selections
      ;variable names will be aggregated within this loop
      for i = 0,n_elements(pri_selection)-1 do begin
      
        ;if selection is a parent get it's name, not its the constituents'
        if state.loadedData->isParent(pri_selection[i]) then begin
          group = state.loadedData->getGroup(pri_selection[i])
          
          if ~obj_Valid(group[0]) then continue
          
          indepName = group->getIndepName()
          timename = group->getTimeName()
          name = group->getName()
          yaxisname = group->getyaxisname()
        
        ;otherwise get name as usual
        endif else begin
        
          obj = state.loadedData->getObjects(name=pri_selection[i])
          
          if ~obj_valid(obj[0]) then continue
        
          obj->getProperty,name=name,timename=timename,indepname=indepname,yaxisname=yaxisname
             
        endelse
      
        ;concatenate list of variable names
        if ~keyword_set(indepName) then begin
          x_select = array_concat(timename,x_select)
        endif else begin
          x_select = array_concat(indepName,x_select)
        endelse
          
        y_select = array_concat(yaxisname,y_select)
        z_select = array_concat(name,z_select)
      
      endfor
    
    endelse
  endif else begin ;identify selection for component mode
  
    z_selection = state.priTree->getValue()
    y_selection = state.secTree->getValue()
    x_selection = state.terTree->getValue()
    
    if ~keyword_set(x_selection[0]) then begin
       state.statusBar->update,'Warning: No X-variable selected'
       ok=dialog_message("No X-variable selected, Unable to add to panel", /information, /center, dialog_parent=state.tlb)
       return
    endif
    
    if ~keyword_set(y_selection[0]) then begin
      state.statusbar->update,'Warning: No Y-variable selected'
      ok=dialog_message("No Y-variable selected, Unable to add to panel", /information, /center, dialog_parent=state.tlb)
      return
    endif
  
    if ~keyword_set(spectra) then begin
    
      ;allows a one-to-many, many-to-one, or a one-to-one, but not a general m-to-n match
    
      if n_elements(x_selection) ne 1 && $
         n_elements(y_selection) ne 1 && $
         n_elements(x_selection) ne n_elements(y_selection) then begin
         state.statusbar->update,'Warning: Number of X and Y elements do not match'
         ok=dialog_message("Number of X & Y elements do not match, Unable to add to panel", /information, /center, dialog_parent=state.tlb)
         return
       endif 
       
       if n_elements(x_selection) eq 1 && $
          n_elements(y_selection) gt 1 then begin
          
          x_selection = replicate(x_selection,n_elements(y_selection))
          
       endif else if n_elements(y_selection) eq 1 && $
                     n_elements(x_selection) gt 1 then begin
                     
          y_selection = replicate(y_selection,n_elements(y_selection))
         
       endif
          
       for i = 0,n_elements(y_selection)-1 do begin
       
         if state.loadedData->isParent(y_selection[i]) then begin
         
           y_children = state.loadedData->getChildren(y_selection[i])
           x_children = replicate(x_selection[i],n_elements(y_children))
           
         endif else begin
         
           y_children = y_selection[i]
           x_children = x_selection[i]
           
         endelse
       
         x_select = array_concat(x_children,x_select)
         y_select = array_concat(y_children,y_select)
         
       endfor
      
    endif else begin
    
      ;allows a one-to-many, many-to-one, or a one-to-one, but not a general m-to-n match
    
      if ~keyword_set(z_selection[0]) then begin
        state.statusbar->update,'Warning: No Z-variable selected'
        ok=dialog_message("No Z-variable selected, Unable to add to panel", /information, /center, dialog_parent=state.tlb)
        return
      endif
      
      if n_elements(x_selection) ne 1 && $
         n_elements(z_selection) ne 1 && $
         n_elements(x_selection) ne n_elements(z_selection) then begin
        state.statusbar->update,'Warning: Number of X and Z elements do not match'
        ok=dialog_message("Number of X & Z elements do not match, Unable to add to panel", /information, /center, dialog_parent=state.tlb)
        return
      endif 
       
       if n_elements(x_selection) eq 1 && $
          n_elements(z_selection) gt 1 then begin
          
         x_selection = replicate(x_selection,n_elements(z_selection))
          
       endif else if n_elements(z_selection) eq 1 && $
                     n_elements(x_selection) gt 1 then begin
                     
         z_selection = replicate(z_selection,n_elements(x_selection))
         
       endif
           
      if n_elements(y_selection) ne 1 && $
         n_elements(z_selection) ne 1 && $
         n_elements(y_selection) ne n_elements(z_selection) then begin
        state.statusbar->update,'Warning: Number of Y and Z elements do not match'
        ok=dialog_message("Number of Y & Z elements do not match, Unable to add to panel", /information, /center, dialog_parent=state.tlb)
        return
      endif 
       
      if n_elements(y_selection) eq 1 && $
          n_elements(z_selection) gt 1 then begin
          
         y_selection = replicate(y_selection,n_elements(z_selection))
          
       endif else if n_elements(y_selection) eq 1 && $
                     n_elements(z_selection) gt 1 then begin
                     
         z_selection = replicate(z_selection,n_elements(y_selection))
         
       endif  
       
       x_select = x_selection
       y_select = y_selection
       z_select = z_selection
       
       for i = 0,n_elements(z_select)-1 do begin
       
         if (state.loadedData->isParent(z_select[i]) && $
            ~state.loadedData->isParent(y_select[i])) then begin
            
            state.statusbar->update,'WARNING: Z-axis is group-variable, but Y-variable is not. May generate invalid plot'
            
         endif else if (state.loadedData->isParent(y_select[i]) && $
            ~state.loadedData->isParent(z_select[i])) then begin
            
            state.statusbar->update,'WARNING: Y-axis is group-variable, but Z-variable is not. May generate invalid plot'
        
         endif 
       
       endfor
       
    endelse
  
  endelse
  
end

;if out of bound rows or cols, put back in bounds
pro spd_ui_update_nrows_ncols,panelobjs,windowobj,topid

  if ~obj_valid(panelobjs[0]) then return

  windowObj->getProperty,nrows=current_rows,ncols=current_cols

  row_id = widget_info(topid,find_by_uname='page_row')
  col_id = widget_info(topid,find_by_uname='page_col')

  for i = 0,n_elements(panelObjs)-1 do begin
    layout = panelObjs[i]->getLayoutStructure() 
    if (layout.row + layout.rspan-1) ge current_rows then begin
      current_rows = layout.row+layout.rspan-1
      windowObj->setProperty,nrows=current_rows
      widget_control,row_id,set_value=current_rows
    endif
    
    if (layout.col + layout.cspan-1) ge current_cols then begin
      current_cols = layout.col+layout.cspan-1
      windowObj->setProperty,ncols=current_cols
      widget_control,col_id,set_value=current_cols
      spd_ui_spinner_set_min_value, col_id, current_cols
    endif
  endfor

end


; Shift traces position
;
pro spd_ui_layout_shift_traces, state, up=up, down=down

    compile_opt idl2, hidden

  pindex = state.panel_sel

  u = keyword_set(up) ? -1:1

  cpanel = (*state.panelObjs)[pindex]
  cpanel->GetProperty, tracesettings=traceSettings, xaxis=xaxisSettings, $
                       yaxis=yaxisSettings

  xaxisSettings->GetProperty, labels=xlabels
  yaxisSettings->GetProperty, labels=ylabels
  ntraces = tracesettings->count()
  
  if state.trace_sel + u le ntraces - 1 && $
     state.trace_sel + u ge 0 then begin
    tracesettings->Move, state.trace_sel, state.trace_sel + u
    xlabels->Move, state.trace_sel, state.trace_sel + u
    ylabels->Move, state.trace_sel, state.trace_sel + u
    
    xaxisSettings->SetProperty, labels=xlabels
    yaxisSettings->SetProperty, labels=ylabels
      
    state.trace_sel = state.trace_sel + u
    cpanel->SetProperty, tracesettings=traceSettings, xaxis=xaxisSettings, $
                         yaxis=yaxisSettings
  endif

  new_trace_ind = where(*state.panelValue eq (*state.panelNames)[state.panel_sel]) $
                    + state.trace_sel + 1
  widget_control, state.panelList, set_list_select=new_trace_ind        
  widget_control, state.shiftupButton, sensitive = state.trace_sel eq 0 ? 0:1
  widget_control, state.shiftdownButton, sensitive = state.trace_sel eq (ntraces-1) ? 0:1

end


; Shift panel position and update widgets 
;
pro spd_ui_layout_shift_panels, state, left=left, right=right, up=up, down=down

    compile_opt idl2, hidden

  h = keyword_set(left) or keyword_set(right)        ;horizontal
  s = keyword_set(down) or keyword_set(right) ? 1:-1 ;down/right

  pindex = state.panel_sel


  ;Get panel obj and locations
  cpanel = (*state.panelObjs)[pindex]
  ol = cpanel->getlayoutstructure()

  ;Get page settings 
  state.cWindow->getProperty,nRows=current_rows, $
                             nCols=current_cols
  
  ;Set new row/col number and expand page settings if needed
  if h then begin
    value = ((*state.panelLayout).col)[pindex] + s
    
    if value lt 1 then return
    
    cpanel->SetLayoutStructure,col=value
    widget_control, state.colText, set_value=value
    
    if s gt 0 && (value + ol.cspan - 1) gt current_cols then begin
      current_cols = value + ol.cspan - 1
      state.cWindow->SetProperty, nCols=current_cols
      id = widget_info(state.tlb, find_by_uname='page_col')
      widget_control, id, set_value=current_cols
    endif
  
  endif else begin
    value = ((*state.panelLayout).row)[pindex] + s
    
    if value lt 1 then return
    
    cpanel->SetLayoutStructure,row=value
    widget_control, state.rowText, set_value=value
    
    if s gt 0 && (value + ol.rspan - 1) gt current_rows then begin
      current_rows = value + ol.rspan - 1
      state.cWindow->SetProperty, nRows=current_rows
      id = widget_info(state.tlb, find_by_uname='page_row')
      widget_control, id, set_value=current_rows
    endif 
  
  endelse

  ; Check if panels should be swapped
  ; (only if at same location and with same size)
  cl = cpanel->getlayoutstructure()
  for i=0, n_elements(*state.panelObjs)-1 do begin
    
    if i eq pindex then continue
    
    l = (*state.panelObjs)[i]->getlayoutstructure()
    
    if l.col eq cl.col && l.row eq cl.row &&  $
       l.cspan eq cl.cspan && l.rspan eq cl.rspan then begin
       (*state.panelObjs)[i]->setlayoutstructure, row=ol.row, col=ol.col
    endif 
    
  endfor 

end


; Shift Panels and Traces 
;
pro spd_ui_layout_shift, state, _extra=_extra

     compile_opt idl2, hidden

  ; Shift panels/traces
  if state.trace_sel eq -1 then begin
    spd_ui_layout_shift_panels, state, _extra=_extra
  endif else begin
    spd_ui_layout_shift_traces, state, _extra=_extra
  endelse

  ; Panels Obj pointer
  if ptr_valid(state.panelObjs) then ptr_free, state.panelObjs
  state.panelObjs = ptr_new(*state.panels->Get(/All))

  ; Get panel/tracenames and panel layout
  spd_ui_update_panel_list, state=state, panelNames=panelNames, $
     panelValue=panelValue, panel_ValueInfo=panel_ValueInfo, $
     panelLayout=panelLayout, ntr=ntr

  ; Reset other pointers
  if ptr_valid(state.panelValue) then ptr_free, state.panelValue
  if ptr_valid(state.panel_ValueInfo) then ptr_free, state.panel_ValueInfo
  if ptr_valid(state.panelNames) then ptr_free, state.panelNames
  if ptr_valid(state.panelLayout) then ptr_free, state.panelLayout
    
  state.panelValue = ptr_new(panelValue)
  state.panel_ValueInfo = ptr_new(panel_ValueInfo)
  state.panelNames = ptr_new(panelNames)
  state.panelLayout = ptr_new(panelLayout)
  state.npanels = n_elements(*state.panelObjs)

  ; Update Widgets
  widget_control, state.panelList, set_value=*state.panelValue
  if state.trace_sel eq -1 then begin
    widget_control, state.panelList, set_list_select = $
         where((*state.panelNames)[state.panel_sel] eq *state.panelValue)
  endif else begin
    widget_control, state.panelList, set_list_select = $
         where(*state.panelValue eq (*state.panelNames)[state.panel_sel]) + state.trace_sel + 1
  endelse


end


;Update the minimum for the Rows per page and columns per page spinners to reflect 
; panel column and row settings
pro spd_ui_layout_options_update_spinner_min, panelObjs, topid
  
  npanels = n_elements(panelObjs)
  maxcspan=1
  maxrspan=1
  for i = 0,npanels-1 do begin
    cPanel = panelObjs[i]
    cpanel->GetProperty, settings=panelSettings
    panelSettings->GetProperty, cspan=cspan_temp, rspan=rspan_temp
    panelLayout = cPanel->getLayoutStructure()
    totalspan_c = cspan_temp + panelLayout.col - 1
    totalspan_r = rspan_temp + panelLayout.row -1
    if totalspan_c gt maxcspan then maxcspan = totalspan_c
    if totalspan_r gt maxrspan then maxrspan = totalspan_r
  endfor 
  cid = widget_info(topid, find_by_uname='page_col')
  spd_ui_spinner_set_min_value, cid, maxcspan
  rid = widget_info(topid, find_by_uname='page_row')
  spd_ui_spinner_set_min_value, rid, maxrspan
end

; Issue messages to user and reset row/col/row pp/col pp spinner values that are non numeric or negative.
; Negative values are reset rather than set to 1 to avoid any unforeseen consequences.
; Valid entries are currently handled as soon as user enters them.
; Intended to be called when user changes panel or clicks Apply/OK.
pro spd_ui_layout_options_check_spinners, panelObjs, panelLayout, windowobj, panelnum,topid, maxrows,maxcols

if ~(panelnum eq -1) then begin
; Column Number
  id = widget_info(topid, find_by_uname='pan_col')
  widget_control, id, get_value=current_col_num
  prev_col_num = (panelLayout.col)[panelnum]
  if finite(current_col_num, /nan) then begin
    messageString = 'Invalid column number entered; value reset.'
    response=dialog_message(messageString,/CENTER)
    widget_control,id,set_value=prev_col_num
  endif else if current_col_num lt 1 then begin
    messageString = 'Column number must be greater than 1; value reset.'
    response=dialog_message(messageString,/CENTER)
    widget_control,id,set_value=prev_col_num
  endif
; Row Number
  id = widget_info(topid, find_by_uname='pan_row')
  widget_control, id, get_value=current_row_num
  prev_row_num = (panelLayout.row)[panelnum]
  if finite(current_row_num, /nan) then begin
    messageString = 'Invalid row number entered; value reset.'
    response=dialog_message(messageString,/CENTER)
    widget_control,id,set_value=prev_row_num
  endif else if current_row_num lt 1 then begin
    messageString = 'Row number must be greater than 1; value reset.'
    response=dialog_message(messageString,/CENTER)
    widget_control,id,set_value=prev_row_num
  endif
; Column Span
  id = widget_info(topid, find_by_uname='col_span')
  widget_control, id, get_value=current_col_span
  prev_col_span = (panelLayout.cspan)[panelnum]
  if finite(current_col_span, /nan) then begin
    messageString = 'Invalid column span entered; value reset.'
    response=dialog_message(messageString,/CENTER)
    widget_control,id,set_value=prev_col_span
  endif else if current_col_span lt 1 then begin
    messageString = 'Column span must be greater than 1; value reset.'
    response=dialog_message(messageString,/CENTER)
    widget_control,id,set_value=prev_col_span
  endif
; Row Span
  id = widget_info(topid, find_by_uname='row_span')
  widget_control, id, get_value=current_row_span
  prev_row_span = (panelLayout.rspan)[panelnum]
  if finite(current_row_span, /nan) then begin
    messageString = 'Invalid row span entered; value reset.'
    response=dialog_message(messageString,/CENTER)
    widget_control,id,set_value=prev_row_span
  endif else if current_row_span lt 1 then begin
    messageString = 'Row span must be greater than 1; value reset.'
    response=dialog_message(messageString,/CENTER)
    widget_control,id,set_value=prev_row_span
  endif
  
; Columns per page
  id = widget_info(topid, find_by_uname='page_col')
  widget_control, id, get_value=current_page_col
  windowobj->getProperty, ncols=prev_page_col
  if finite(current_page_col, /nan) then begin
    messageString = 'Invalid columns per page entered; value reset.'
    response=dialog_message(messageString,/CENTER)
    widget_control,id,set_value=prev_page_col  
  endif else begin
    maxcspan = 1
    for i = 0,n_elements(panelObjs)-1 do begin
      cpanel_temp = panelObjs[i]
      cpanel_temp->GetProperty, settings=panelSettings_temp
      panelSettings_temp->GetProperty, cspan=cspan_temp
      panelLayout_temp = cPanel_temp->getLayoutStructure()
      totalspan = cspan_temp + panelLayout_temp.col - 1
      if totalspan gt maxcspan then maxcspan = totalspan
    endfor
    if current_page_col lt maxcspan then begin
      messageString = 'Columns per page must be greater than the column number of any individual panel; value reset.'
      response=dialog_message(messageString,/CENTER)
      widget_control,id,set_value=prev_page_col
    endif
  endelse

; Rows per page
  id = widget_info(topid, find_by_uname='page_row')
  widget_control, id, get_value=current_page_row
  windowobj->getProperty, nrows=prev_page_row
  if finite(current_page_row, /nan) then begin
    messageString = 'Invalid rows per page entered; value reset.'
    response=dialog_message(messageString,/CENTER)
    widget_control,id,set_value=prev_page_row
  endif else begin
    maxrspan = 1 
    for i = 0,n_elements(panelObjs)-1 do begin
      cpanel_temp = panelObjs[i]
      cpanel_temp->GetProperty, settings=panelSettings_temp
      panelSettings_temp->GetProperty, rspan=rspan_temp
      panelLayout_temp = cPanel_temp->getLayoutStructure()
      totalspan = rspan_temp + panelLayout_temp.row - 1
      if totalspan gt maxrspan then maxrspan = totalspan
    endfor
    if current_page_row lt maxrspan then begin
      messageString = 'Rows per page must be greater than the row number of any individual panel; value reset.'
      response=dialog_message(messageString,/CENTER)
      widget_control,id,set_value=prev_page_row
    endif
  endelse
endif else begin;this handles the case where there are no panels and apply is clicked with invalid entries in the Rows per page or Cols per page spinners
  id = widget_info(topid, find_by_uname='page_col')
  widget_control, id, get_value=current_page_col
  windowobj->getProperty, ncols=prev_page_col
  if finite(current_page_col, /nan) then begin
    widget_control,id,set_value=prev_page_col  
  endif else if current_page_col lt 1 then begin
    widget_control, id, set_value=prev_page_col
  endif
  id = widget_info(topid, find_by_uname='page_row')
  widget_control, id, get_value=current_page_row
  windowobj->getProperty, nrows=prev_page_row
  if finite(current_page_row, /nan) then begin
    widget_control,id,set_value=prev_page_row
  endif else if current_page_row lt 1 then begin
    widget_control, id, set_value=prev_page_row
  endif
endelse

end

Pro spd_ui_layout_options_event, event

  Compile_Opt idl2, hidden
  
  Widget_Control, event.TOP, Get_UValue=state, /No_Copy

    ;Put a catch here to insure that the state remains defined

  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    if is_struct(state) then begin
      FOR j = 0, N_Elements(err_msg)-1 DO state.historywin->update,err_msg[j]

        value = 'NO UVALUE'
        if widget_valid(event.id) then begin
          widget_control, event.id, get_uvalue=val
          if keyword_set(val) then begin
            value = val
          endif
        endif
          
      ; Store most recent events
       
        state.uvalHist[1:4] = state.uvalHist[0:3]
        state.uvalHist[0] = 'UVALUE: ' + value ; most recent uval
        
        for i=n_elements(state.eventHist)-1,1L,-1 do begin
          *state.eventHist[i] = *state.eventHist[i-1]
        endfor
        *state.eventHist[0] = event
      
      ; Output most recent events
      state.historywin->update, strcompress(string(n_elements(state.uvalHist)), /remove_all) + $
                             ' most recent events in Layout Options (in descending order):'
      for j=0,n_elements(state.uvalHist)-1 do begin
        state.historywin->update, state.uvalHist[j]
        printdat, *state.eventHist[j], output=eventStruct
        for k=0L,n_elements(eventStruct)-1 do state.historywin->update, '   ' + eventStruct[k] 
      endfor
      
      x=state.info.master
      histobj=state.historywin
    endif
    Print, 'Error--See history'
    ok=error_message('An unknown error occured and the window must be restarted. See console for details.',$
                     /noname, /center, title='Error in Plot/Layout Options')
   
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    if widget_valid(x) && obj_valid(histobj) then begin 
      spd_gui_error,x,histobj
    endif
    RETURN
  ENDIF


  ; Store most recent events
    widget_control, event.id, get_uvalue=value
    state.uvalHist[1:4] = state.uvalHist[0:3]
    if ~keyword_set(value) then value='NO UVALUE'
    state.uvalHist[0] = 'UVALUE: ' + value ; most recent uval
    
    for i=n_elements(state.eventHist)-1,1L,-1 do begin
      *state.eventHist[i] = *state.eventHist[i-1]
    endfor
    *state.eventHist[0] = event

    ;kill request block

  IF(Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN  
      state.origWindow->GetProperty, panels=origPanels, nRows=nRows, nCols=nCols, locked=locked
      state.cWindow->SetProperty, panels=origPanels, nRows=nRows, nCols=nCols, locked=locked
       
      spd_ui_layout_draw_update,event.top,state
      
      state.historywin->Update,'SPD_UI_LAYOUT_OPTIONS: Active window refreshed.'
      state.statusbar->update,'SPD_UI_LAYOUT_OPTIONS: Active window refreshed.'
     
      if obj_valid(state.priTree) then begin
        *state.treeCopyPtr = state.priTree->getCopy()
      endif
     
      state.historywin->Update, 'Layout Options window cancelled. No changes made.'
      state.statusbar->update, 'Layout Options window cancelled. No changes made.'
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /destroy
      RETURN
  ENDIF

 ;deal with tabs

IF (Tag_Names(event, /Structure_Name) EQ 'WIDGET_TAB') THEN BEGIN  
;  Widget_Control, state.panelDroplists[event.tab], set_droplist_select = state.axispanelselect
  Widget_Control, event.TOP, Set_UValue=state, /No_Copy
  RETURN 
EndIF

   ; Get the instructions from the widget causing the event and
   ; act on them.

  Widget_Control, event.id, Get_UValue=uval

  state.historywin->update,'SPD_UI_LAYOUT_OPTIONS: User value: '+uval  ,/dontshow
  
 
  CASE uval OF
    'ADDPAN': BEGIN
    
      spd_ui_layout_add_panel,state
     
      ;spd_ui_init_tree_widgets, state=state
      spd_ui_update_var_widget, state=state
      
      ;widget_control, state.editButton, sensitive=0; temp til panel options works
      
    END
    'ADDLINE': BEGIN
      spd_ui_layout_add_trace,event,state 
    END
   'ADDSPEC': BEGIN
      spd_ui_layout_add_trace,event,state,/spectra
    END
    'ADDVAR': BEGIN
      if ~ptr_valid(state.ySelect) then begin
        RETURN
      endif

      if ptr_valid(state.varList) then begin ; Add variables from y-axis list
        varList = *state.varList
        ptr_free, state.varList
        varList = [varList, *state.ySelect]
      endif else varList = *state.ySelect
      state.varList = ptr_new(varList)
      widget_control, state.variableText, set_value=*state.varList
    END
    'APPLY': BEGIN
      ;if state.npanels gt 0 then begin
        ; Handle any invalid spinner entries
        ; We need to check rows per page and columns per page even if there are no panels.
        ; If there are no panels *state.panelObjs =-1 (which is handled fine). If you add and remove a panel state.panelLayout is a null pointer and
        ; thus needs to be dealt with separately.
      if ptr_valid(state.panelLayout) then begin
        spd_ui_layout_options_check_spinners, *state.panelObjs, *state.panelLayout,state.cwindow,state.panel_sel,event.top
      endif else spd_ui_layout_options_check_spinners, *state.panelObjs, -1, state.cwindow, -1, event.top
      ;endif
      
      ; should apply any changes made to panel layout
      spd_ui_update_nrows_ncols,*state.panelObjs,state.cwindow,event.top
      ; make sure no panels overlap
      if spd_ui_check_overlap(*state.panelobjs, state.cwindow[0]) then break
      state.cWindow->getProperty, locked=locked
      if locked ne -1 then begin
        ok = spd_ui_check_panel_layout(state)
        if ~ok then begin
          ; have to revert to initial state
          ;*state.cWindow->SetProperty, Panels=*state.panelsCopy
          ;ptr_free, state.panels
    
          ;this code should be replaced with a save/reset method
          state.origWindow->GetProperty, panels=origPanels, nRows=nRows, nCols=nCols, locked=locked
          state.cWindow->SetProperty, panels=origPanels, nRows=nRows, nCols=nCols, locked=locked
           
          state.cWindow->getProperty,settings=page_settings
          
          page_settings->reset
           
          state.info.drawObject->update,state.info.windowStorage,state.info.loadedData
          state.info.drawObject->draw
          state.info.scrollbar->update
    
          if obj_valid(state.priTree) then begin
            *state.treeCopyPtr = state.priTree->getCopy()
          endif
    
          ;Print, 'Layout Options widget cancelled. No changes made.'
          ;state.historywin->Update, 'SPD_UI_LAYOUT_OPTIONS: Layout Options window cancelled. No changes made.'
          Widget_Control, event.TOP, Set_UValue=state, /No_Copy
          Widget_Control, event.top, /destroy
          RETURN
        endif
      endif
      
;      ;make sure window shrinks to max rows/cols
;      if state.npanels eq 0 then begin
;        state.cWindow->SetProperty, nRows=nRows
;        state.cWindow->SetProperty, nCols=nCols
;      endif else begin
;      
;        maxrspan = 1
;        maxcspan = 1
;        
;        for i = 0,state.npanels-1 do begin
;          cpanel = (*state.panelObjs)[i]
;          cpanel->GetProperty, settings=panelSettings
;          panelSettings->GetProperty, rspan=rspan
;          totalspan = rspan + ((*state.panelLayout).row)[i] - 1
;          if totalspan gt maxrspan then maxrspan = totalspan
;        endfor
;        
;        for i = 0,state.npanels-1 do begin
;          cpanel = (*state.panelObjs)[i]
;          cpanel->GetProperty, settings=panelSettings
;          panelSettings->GetProperty, cspan=cspan
;          totalspan = cspan + ((*state.panelLayout).col)[i] - 1
;          if totalspan gt maxcspan then maxcspan = totalspan
;        endfor
;
;        if maxrspan lt state.initNRows then maxrspan = state.initNRows
;        if maxcspan lt state.initNCols then maxcspan = state.initNCols
;        
;        state.cWindow->SetProperty, nRows=maxrspan
;        state.cWindow->SetProperty, nCols=maxcspan
;
;      endelse

      spd_ui_layout_sync_traces, state
      spd_ui_layout_draw_update,event.top,state,/apply
      
      state.historywin->Update, 'SPD_UI_LAYOUT_OPTIONS: Changes applied.'
      state.statusbar->update, 'SPD_UI_LAYOUT_OPTIONS: Changes applied.'
    END
    'CANC': BEGIN

      ; have to revert to initial state
;      *state.cWindow->SetProperty, Panels=*state.panelsCopy
;      ptr_free, state.panels

      ;this code should be replaced with a save/reset method
      state.origWindow->GetProperty, panels=origPanels, nRows=nRows, nCols=nCols, locked=locked
      state.cWindow->SetProperty, panels=origPanels, nRows=nRows, nCols=nCols, locked=locked
      
      state.cWindow->getProperty,settings=page_settings
      
      page_settings->reset
       
      state.info.drawObject->update,state.info.windowStorage,state.info.loadedData
      state.info.drawObject->draw
      state.info.scrollbar->update

      state.info.statusBar->update,'Plot/Layout Options closed.'
      state.historywin->Update, 'SPD_UI_LAYOUT_OPTIONS: Layout Options window cancelled. No changes made.'
      
      if obj_valid(state.priTree) then begin
        *state.treeCopyPtr = state.priTree->getCopy()
      endif
      
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /destroy
      RETURN
    END
    'EDPAN': BEGIN
      ; edit selected panel
      
      pindex = widget_info(state.panelList, /list_select)
      cpanel_num = ptr_new(state.panel_sel)
      ctr_num = ptr_new(state.trace_sel)
                
      if (*state.panel_ValueInfo)[pindex].ispanel then begin
      ;temporarily comment out until we get panel options working
        state.historywin->Update, 'SPD_UI_LAYOUT_OPTIONS: Calling PANEL OPTIONS panel.'
        state.statusbar->update,'SPD_UI_LAYOUT_OPTIONS: Calling PANEL OPTIONS panel.'
        spd_ui_panel_options, state.tlb, state.info.windowStorage, $
                             state.info.loadedData, state.historywin, $
                             state.info.drawObject, state.template,$
                             panel_select=cpanel_num, ctr_num=ctr_num, state.info.statusbar
        state.panel_sel = state.npanels-1
        state.panel_sel = *cpanel_num
        state.trace_sel = -1
        istrace=0
      endif else begin

        if state.is_trace_spec eq 0 then begin
          state.historywin->Update, 'SPD_UI_LAYOUT_OPTIONS: Calling LINE OPTIONS panel.'
          state.statusbar->update, 'SPD_UI_LAYOUT_OPTIONS: Calling LINE OPTIONS panel.'
          spd_ui_line_options, state.tlb, state.info.windowStorage, $
                               state.info.loadedData, state.historywin, $
                               state.info.drawObject, state.template,cpanel_num=cpanel_num, $
                               ctr_num=ctr_num, state.info.statusbar

          state.panel_sel = *cpanel_num
          state.trace_sel = *ctr_num
        endif else begin
          state.historywin->Update, 'SPD_UI_LAYOUT_OPTIONS: Calling Z-AXIS OPTIONS panel.'
          state.statusbar->update, 'SPD_UI_LAYOUT_OPTIONS: Calling Z-AXIS OPTIONS panel.'
          spd_ui_zaxis_options, state.tlb, state.info.windowStorage, $
                               state.info.zaxisSettings, state.info.drawObject, $
                               state.info.loadedData, state.historywin,state.template, state.info.statusbar , state.panel_sel; , cpanel_num
          
;          state.panel_sel = *cpanel_num
;          state.trace_sel = 0
        endelse
        
        istrace=1      
      endelse

      ptr_free, cpanel_num & ptr_free, ctr_num
      
    ; begin "in case of cancel of child panel" code
      state.cWindow->GetProperty, Panels=panels, nRows=nrows, nCols=ncols;, locked=locked ;locked necessary?
      if ptr_valid(state.panels) then ptr_free, state.panels
      state.panels = ptr_new(panels)

      if ptr_valid(state.panelObjs) then ptr_free, state.panelObjs
      state.panelObjs = ptr_new(*state.panels->Get(/All))
    ; end "in case of cancel of child panel" code

    ; update page row/col number in case of panel span change
    
      widget_control, state.rowpagetext, set_value=nrows
      widget_control, state.colpagetext, set_value=ncols

      
      state.npanels = n_elements(*state.panelObjs)
      if ptr_valid(state.panelValue) then ptr_free, state.panelValue
      if ptr_valid(state.panel_ValueInfo) then ptr_free, state.panel_ValueInfo
      if ptr_valid(state.panelNames) then ptr_free, state.panelNames
        
      ; get panel/tracenames and panel layout
      spd_ui_update_panel_list, state=state, panelNames=panelNames, $
         panelValue=panelValue, panel_ValueInfo=panel_ValueInfo, $
         panelLayout=panelLayout, ntr=ntr

      if ptr_valid(state.panelLayout) then ptr_free, state.panelLayout
      state.panelLayout = ptr_new(panelLayout)
      state.panelValue = ptr_new(panelValue)
      state.panel_ValueInfo = ptr_new(panel_ValueInfo)
      state.panelNames = ptr_new(panelNames)
      ;state.panel_sel = state.npanels-1

      widget_control, state.panelList, set_value=*state.panelValue
      ;widget_control, state.panelList, set_list_select=state.panel_sel + ntr
      
      new_trace_ind = where(*state.panelValue eq (*state.panelNames)[state.panel_sel])
      widget_control, state.panelList, set_list_select=new_trace_ind

      widget_control, state.rowText, set_value=(*state.panelLayout)[state.panel_sel].row
      widget_control, state.colText, set_value=(*state.panelLayout)[state.panel_sel].col
      widget_control, state.rowSpan, set_value=(*state.panelLayout)[state.panel_sel].rspan
      widget_control, state.colSpan, set_value=(*state.panelLayout)[state.panel_sel].cspan

      if istrace then begin
      
        ;make sure correct trace is selected
        new_trace_ind = where(*state.panelValue eq (*state.panelNames)[state.panel_sel]) $
                        + state.trace_sel+1
        widget_control, state.panelList, set_list_select=new_trace_ind
        
        ;make sure widgets are appropriately sensitized
        if state.trace_sel eq 0 then widget_control, state.shiftupButton, sensitive=0 $
          else widget_control, state.shiftupButton, sensitive=1
          
        if state.trace_sel eq (ntr[state.panel_sel]-1) then widget_control, state.shiftdownButton, sensitive=0 $
          else widget_control, state.shiftdownButton, sensitive=1
          
        widget_control, state.rowText, set_value=(*state.panelLayout)[state.panel_sel].row
        widget_control, state.colText, set_value=(*state.panelLayout)[state.panel_sel].col
        widget_control, state.rowSpan, set_value=(*state.panelLayout)[state.panel_sel].rspan
        widget_control, state.colSpan, set_value=(*state.panelLayout)[state.panel_sel].cspan
      
      endif
      ;spd_ui_init_tree_widgets, state=state
      spd_ui_update_var_widget, state=state
    END
    
    'EDVAR': BEGIN
      ; edit selected variable in box     
      pindex = widget_info(state.panelList, /list_select)
      state.historywin->Update, 'SPD_UI_LAYOUT_OPTIONS: Calling VARIABLE OPTIONS panel.'
      state.statusbar->update, 'SPD_UI_LAYOUT_OPTIONS: Calling VARIABLE OPTIONS panel.'
      
      guiTree = ptr_new(state.priTree->getCopy()) 
      
      spd_ui_variable_options, state.tlb, state.info.loadeddata, $
                               state.info.windowstorage, state.info.drawObject, $
                               state.historywin, state.template,guiTree,panel_select=state.panel_sel
   
      ; if user cancels the variable options panel it will reset the cwindow.. resulting in a difference between the panels
      ; in state.panels and the panels in the state.cwindow
      ; This resets to make sure they match. Ultimately we need to look at why we have multiple references to something and
      ; perhaps reorganise the code.
      state.cWindow->GetProperty, Panels=panels
      if ptr_valid(state.panels) then ptr_free, state.panels
      state.panels = ptr_new(panels)
      if ptr_valid(state.panelObjs) then ptr_free, state.panelObjs
      state.panelObjs = ptr_new(*state.panels->Get(/All))
      spd_ui_update_var_widget, state=state
    END
    'LOCK_PAN': BEGIN
    
      ;this check prevents an accidental unlock of first panel created that can occur if lock clicked when no panels exist
      if state.npanels gt 0 then begin
        state.cWindow->setProperty, locked=state.panel_sel
      endif

      pindex = widget_info(state.panelList, /list_select)
      
      spd_ui_update_panel_list, state=state, panelNames=panelNames, $
         panelValue=panelValue, panel_ValueInfo=panel_ValueInfo, $
         panelLayout=panelLayout

      widget_control, state.panelList, set_value=panelValue, set_list_select=pindex
      if ptr_valid(state.panelValue) then ptr_free, state.panelValue
      state.panelValue = ptr_new(panelValue)
      if ptr_valid(state.panelNames) then ptr_free, state.panelNames
      state.panelNames = ptr_new(panelNames)
    END
    'UNLOCK_PAN': BEGIN
      state.cWindow->setProperty, locked=-1

      pindex = widget_info(state.panelList, /list_select)
      
      spd_ui_update_panel_list, state=state, panelNames=panelNames, $
         panelValue=panelValue, panel_ValueInfo=panel_ValueInfo, $
         panelLayout=panelLayout

      widget_control, state.panelList, set_value=panelValue, set_list_select=pindex
      if ptr_valid(state.panelValue) then ptr_free, state.panelValue
      state.panelValue = ptr_new(panelValue)
      if ptr_valid(state.panelNames) then ptr_free, state.panelNames
      state.panelNames = ptr_new(panelNames)
    END

    'OK': BEGIN
      ; Handle any invalid spinner entries
      ;cpanel = (*state.panelObjs)[state.panel_sel]
      ;cpanel->GetProperty, settings=panelSettings
      if state.npanels gt 0 then begin
        spd_ui_layout_options_check_spinners, *state.panelObjs,*state.panelLayout,state.cwindow,state.panel_sel,event.top
      endif
      ; should apply any changes made and then exit
      
      spd_ui_update_nrows_ncols,*state.panelObjs,state.cwindow,event.top
      ; make sure no panels overlap, reset if so
      if spd_ui_check_overlap(*state.panelobjs, state.cwindow[0]) then break
      state.cWindow->getProperty, locked=locked
      if locked ne -1 then begin
        ok = spd_ui_check_panel_layout(state)
        if ~ok then begin
          ; have to revert to initial state
          ;*state.cWindow->SetProperty, Panels=*state.panelsCopy
          ;ptr_free, state.panels
    
          ;this code should be replaced with a save/reset method
          state.origWindow->GetProperty, panels=origPanels, nRows=nRows, nCols=nCols, locked=locked
          state.cWindow->SetProperty, panels=origPanels, nRows=nRows, nCols=nCols, locked=locked
           
          state.cWindow->getProperty,settings=page_settings
          
          page_settings->reset
           
          state.info.drawObject->update,state.info.windowStorage,state.info.loadedData
          state.info.drawObject->draw
          state.info.scrollbar->update
          
          if obj_valid(state.priTree) then begin
            *state.treeCopyPtr = state.priTree->getCopy()
          endif
          ;Print, 'Layout Options widget cancelled. No changes made.'
          ;state.historywin->Update, 'SPD_UI_LAYOUT_OPTIONS: Layout Options window cancelled. No changes made.'
          Widget_Control, event.TOP, Set_UValue=state, /No_Copy
          Widget_Control, event.top, /destroy
          RETURN
        endif
      endif
      
;      ;make sure window shrinks to max rows/cols
;      if state.npanels eq 0 then begin
;        state.cWindow->SetProperty, nRows=nRows
;        state.cWindow->SetProperty, nCols=nCols
;      endif else begin
;
;      endelse
      spd_ui_layout_sync_traces, state
      spd_ui_layout_draw_update,event.top,state
      
      state.historywin->Update, 'SPD_UI_LAYOUT_OPTIONS: Layout updated.  Layout Options widget closed.'
      state.info.statusBar->update,'Plot/Layout Options closed.'
      if obj_valid(state.priTree) then begin
        *state.treeCopyPtr = state.priTree->getCopy()
      endif
      
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      RETURN
    END
    'PAGE_COL': BEGIN
      if event.valid then begin
        
        maxcspan = 1
      
        for i = 0,state.npanels-1 do begin
          cpanel = (*state.panelObjs)[i]
          cpanel->GetProperty, settings=panelSettings
          panelSettings->GetProperty, cspan=cspan
          totalspan = cspan + ((*state.panelLayout).col)[i] - 1
          if totalspan gt maxcspan then maxcspan = totalspan
        endfor
  
        if event.value lt maxcspan then begin
          state.historywin->Update,'Columns per page cannot be less than any of the individual column numbers.'
          state.statusbar->Update,'Columns per page cannot be less than any of the individual column numbers.'
          ; Delay handling till the user hits OK/apply or changes panel (to prevent overwriting as the user types)
          ;widget_control, event.id, set_value=maxcspan
          ;state.cWindow->setProperty, ncols=maxcspan
        endif else begin
          state.cWindow->setProperty, ncols=event.value
        endelse
      endif else if finite(event.value,/nan) then begin
        state.historywin->Update,'Illegal entry in column number spinner.'
        state.statusbar->Update,'Illegal entry in column number spinner.'
      endif else begin
        state.historywin->Update,'Columns per page cannot be less than any of the individual column numbers.'
        state.statusbar->Update,'Columns per page cannot be less than any of the individual column numbers.'
      endelse 
    END
    'PAGE_ROW': BEGIN
      if event.valid then begin
  
        maxrspan = 1
        
        for i = 0,state.npanels-1 do begin
          cpanel = (*state.panelObjs)[i]
          cpanel->GetProperty, settings=panelSettings
          panelSettings->GetProperty, rspan=rspan
          totalspan = rspan + ((*state.panelLayout).row)[i] - 1
          if totalspan gt maxrspan then maxrspan = totalspan
        endfor
        
        if event.value lt maxrspan then begin
          state.historywin->Update,'Rows per page cannot be less than any of the individual row numbers.'
          state.statusbar->Update,'Rows per page cannot be less than any of the individual row numbers.'
          ; Delay handling till the user hits OK/apply or changes panel (to prevent overwriting as the user types)
          ;widget_control, event.id, set_value=maxrspan
         ; state.cWindow->setProperty, nrows=maxrspan
        endif else begin
          state.cWindow->setProperty, nrows=event.value
        endelse
      endif else if finite(event.value,/nan) then begin
        state.historywin->Update,'Illegal entry in row number spinner.'
        state.statusbar->Update,'Illegal entry in row number spinner.'
      endif else begin
        state.historywin->Update, 'Rows per page cannot be less than any of the individual row numbers.'
        state.statusbar->Update, 'Rows per page cannot be less than any of the individual row numbers.'
      endelse 

    END
    'PANEL': BEGIN
      ; show list of panels
      if state.npanels gt 0 then begin
        spd_ui_layout_options_check_spinners,*state.panelObjs, *state.panelLayout,state.cwindow,state.panel_sel,event.top
      endif
      if event.clicks eq 1 then begin
        ;state.panel_sel = widget_info(state.panelList, /list_select)
        pindex = widget_info(state.panelList, /list_select)
        
        if (*state.panel_ValueInfo)[pindex].ispanel then begin
        widget_control, state.editButton, sensitive=1; temp til panel options works
          
          widget_control, state.rowText, /sensitive
          widget_control, state.colText, /sensitive
          widget_control, state.rowSpan, /sensitive
          widget_control, state.colSpan, /sensitive
          widget_control, state.shiftupButton, /sensitive
          widget_control, state.shiftdownButton, /sensitive
          widget_control, state.shiftleftButton, /sensitive
          widget_control, state.shiftrightButton, /sensitive
          state.trace_sel = -1 
        
          state.panel_sel = where((*state.panelNames) eq (*state.panelValue)[pindex])
          widget_control, state.rowText, set_value=(*state.panelLayout)[state.panel_sel].row
          widget_control, state.colText, set_value=(*state.panelLayout)[state.panel_sel].col
          widget_control, state.rowSpan, set_value=(*state.panelLayout)[state.panel_sel].rspan
          widget_control, state.colSpan, set_value=(*state.panelLayout)[state.panel_sel].cspan
          
          
          ; get variables for current panel
          cpanel = (*state.panelObjs)[state.panel_sel]
          cpanel->getProperty, variables=variablescontainer
          variablesobjects=variablescontainer->get(/all)
          if obj_valid(variablesobjects[0]) then begin
          
            variablesobjects[0]->GetProperty,text=textobject
            textobject->GetProperty,value=ctextvalues
            nvo= n_elements(variablesobjects)
            
            if nvo gt 1 then begin
              for j=1,nvo-1 do begin
                variablesobjects[j]->GetProperty,text=textobject
                textobject->GetProperty,value=ctextvalue
                ctextvalues=[ctextvalues, ctextvalue]
              endfor
            endif
          endif else ctextvalues=['']
          
          widget_control, state.variableText, set_value=ctextvalues ;*state.varList
        
        endif else begin
        ;widget_control, state.editButton, sensitive=1; temp til panel options works
          panelids = (*state.panel_ValueInfo).panelid
          panelids = panelids[uniq(panelids)]
          state.panel_sel = where(panelids eq (*state.panel_ValueInfo)[pindex].panelid)

          cpanel = (*state.panelObjs)[state.panel_sel]
          cpanel->GetProperty, tracesettings=tracesettings
          ntraces = tracesettings->Count()
          traces = traceSettings->get(/all) ; get traces to check for spectra/line type
          
          widget_control, state.rowText, sensitive=0
          widget_control, state.colText, sensitive=0
          widget_control, state.rowSpan, sensitive=0
          widget_control, state.colSpan, sensitive=0
          widget_control, state.shiftleftButton, sensitive=0
          widget_control, state.shiftrightButton, sensitive=0
                    
          state.trace_sel = (*state.panel_ValueInfo)[pindex].traceid
          
          ; check whether selected trace is line or spectra
          if obj_isa(traces[state.trace_sel], 'spd_ui_spectra_settings') then $
            state.is_trace_spec = 1 else state.is_trace_spec = 0

          if state.trace_sel eq 0 then widget_control, state.shiftupButton, sensitive=0 $
            else widget_control, state.shiftupButton, sensitive=1
            
          if state.trace_sel eq (ntraces-1) then widget_control, state.shiftdownButton, sensitive=0 $
            else widget_control, state.shiftdownButton, sensitive=1

          widget_control, state.rowText, set_value=(*state.panelLayout)[state.panel_sel].row
          widget_control, state.colText, set_value=(*state.panelLayout)[state.panel_sel].col
          widget_control, state.rowSpan, set_value=(*state.panelLayout)[state.panel_sel].rspan
          widget_control, state.colSpan, set_value=(*state.panelLayout)[state.panel_sel].cspan

        endelse
      endif
      ;spd_ui_init_tree_widgets, state=state
      spd_ui_update_var_widget, state=state
    END
    'PAN_COL': BEGIN
      if event.valid then begin
        value = event.value
        ;pindex = widget_info(state.panelList, /list_select)

        if value lt 1 then begin ; make sure col lt 1 isn't acceptable
          state.historywin->Update, 'Column number must be greater than 1.'
          state.statusbar->Update,'Column number must be greater than 1.'
          ;Delay handling this case until the user clicks Apply/OK or changes panels
          ;value = ((*state.panelLayout).col)[state.panel_sel]
          ;widget_control,event.id,set_value=value
        endif else begin
        
          cpanel = (*state.panelObjs)[state.panel_sel]
          
          cpanel->GetProperty, settings=panelSettings
          panelSettings->GetProperty, cspan=cspan
          
          cpanel->SetLayoutStructure,col=value
          state.cWindow->getProperty,ncols=current_cols
  
          if (value + cspan - 1) gt current_cols then begin
            current_cols = value + cspan - 1
            state.cWindow->SetProperty, nCols=current_cols
            id = widget_info(state.tlb, find_by_uname='page_col')
            widget_control, id, set_value=current_cols
            ;set the spinner minimum so that user can't set number of columns per page less than any of the column numbers
            ;spd_ui_spinner_set_min_value, id, current_cols
;          endif else if (value + cspan -1) lt current_cols then begin
;            ; check if instead we can decrease the min column per page value
;            maxcspan = 1
;            for i = 0,state.npanels-1 do begin
;              cpanel_temp = (*state.panelObjs)[i]
;              cpanel_temp->GetProperty, settings=panelSettings_temp
;              panelSettings_temp->GetProperty, cspan=cspan_temp
;              panelLayout = cPanel_temp->getLayoutStructure()
;              totalspan = cspan_temp + panelLayout.col - 1
;              if totalspan gt maxcspan then maxcspan = totalspan
;            endfor
;            if (value + cspan -1) eq maxcspan then begin
;              id = widget_info(state.tlb, find_by_uname='page_col')
;              spd_ui_spinner_set_min_value, id, (value+cspan-1)
;            endif
          endif
          ;spd_ui_layout_options_update_spinner_min, *state.panelObjs, state.tlb
    
          if ptr_valid(state.panelObjs) then ptr_free, state.panelObjs
          state.panelObjs = ptr_new(*state.panels->Get(/All))
          
          state.npanels = n_elements(*state.panelObjs)
          if ptr_valid(state.panelValue) then ptr_free, state.panelValue
          if ptr_valid(state.panel_ValueInfo) then ptr_free, state.panel_ValueInfo
          if ptr_valid(state.panelNames) then ptr_free, state.panelNames
    
          ; get panel/tracenames and panel layout
          spd_ui_update_panel_list, state=state, panelNames=panelNames, $
             panelValue=panelValue, panel_ValueInfo=panel_ValueInfo, $
             panelLayout=panelLayout
  
          if ptr_valid(state.panelLayout) then ptr_free, state.panelLayout
          state.panelLayout = ptr_new(panelLayout)
          state.panelValue = ptr_new(panelValue)
          state.panel_ValueInfo = ptr_new(panel_ValueInfo)
          state.panelNames = ptr_new(panelNames)
          widget_control, state.panelList, set_value=*state.panelValue
          widget_control, state.panelList, $
                          set_list_select=where((*state.panelNames)[state.panel_sel] eq *state.panelValue)
          
          spd_ui_layout_resize_page, state, /col
          
          state.historywin->Update, 'SPD_UI_LAYOUT_OPTIONS: Column set to ' + $
                                          strcompress(string(uint(value)),/remove_all) + '.'
          state.statusbar->update,'SPD_UI_LAYOUT_OPTIONS: Column set to ' + $
                                          strcompress(string(uint(value)),/remove_all) + '.'
        endelse
      endif else if finite(event.value, /nan) then begin
        state.historywin->Update,'Illegal entry in column selection spinner.'
        state.statusbar->Update,'Illegal entry in column selection spinner.'
      endif else begin
        ; This handles the case where the user uses the spinner buttons to click down when column is already minimum
        state.historywin->Update, 'Column number must be greater than 1.'
        state.statusbar->Update,'Column number must be greater than 1.'
      endelse 
      
    END 
    'PAN_ROW': BEGIN
      ; change row of selected panel
      if event.valid then begin
        value = event.value
        ;pindex = widget_info(state.panelList, /list_select)
        
        if value lt 1 then begin ; make sure row lt 1 isn't acceptable
          state.historywin->Update, 'Row number must be greater than 1.'
          state.statusbar->Update,'Row number must be greater than 1.'
          ;Delay handling till user changes panel or clicks OK/Apply
          ;value = ((*state.panelLayout).row)[state.panel_sel]
          ;widget_control,event.id,set_value=value
        endif else begin
        
          cpanel = (*state.panelObjs)[state.panel_sel]
          
          cpanel->GetProperty, settings=panelSettings
          panelSettings->GetProperty, rspan=rspan
          
          cpanel->SetLayoutStructure,row=value
          cwindow = state.cWindow
          cwindow->getProperty,nrows=current_rows
  
          if (value + rspan - 1) gt current_rows then begin
            current_rows = value + rspan - 1
            state.cWindow->SetProperty, nRows=current_rows
            id = widget_info(state.tlb, find_by_uname='page_row')
            widget_control, id, set_value=current_rows
            ;set the spinner minimum so that user can't set number of rows per page less than any of the row numbers
            spd_ui_spinner_set_min_value, id, current_rows
          endif else if (value + rspan -1) lt current_rows then begin
            ; check if instead we can decrease the min row per page value
            maxrspan = 1
            for i = 0,state.npanels-1 do begin
              cpanel_temp = (*state.panelObjs)[i]
              cpanel_temp->GetProperty, settings=panelSettings_temp
              panelSettings_temp->GetProperty, rspan=rspan_temp
              panelLayout = cPanel_temp->getLayoutStructure()
              totalspan = rspan_temp + panelLayout.row - 1
              if totalspan gt maxrspan then maxrspan = totalspan
            endfor
            if (value + rspan -1) eq maxrspan then begin
              id = widget_info(state.tlb, find_by_uname='page_row')
              spd_ui_spinner_set_min_value, id, (value+rspan-1)
            endif
          endif
          if ptr_valid(state.panelObjs) then ptr_free, state.panelObjs
          state.panelObjs = ptr_new(*state.panels->Get(/All))
          
          state.npanels = n_elements(*state.panelObjs)
          if ptr_valid(state.panelValue) then ptr_free, state.panelValue
          if ptr_valid(state.panel_ValueInfo) then ptr_free, state.panel_ValueInfo
          if ptr_valid(state.panelNames) then ptr_free, state.panelNames
    
          ; get panel/tracenames and panel layout
          spd_ui_update_panel_list, state=state, panelNames=panelNames, $
             panelValue=panelValue, panel_ValueInfo=panel_ValueInfo, $
             panelLayout=panelLayout
  
          if ptr_valid(state.panelLayout) then ptr_free, state.panelLayout
          state.panelLayout = ptr_new(panelLayout)
          state.panelValue = ptr_new(panelValue)
          state.panel_ValueInfo = ptr_new(panel_ValueInfo)
          state.panelNames = ptr_new(panelNames)
          widget_control, state.panelList, set_value=*state.panelValue
          widget_control, state.panelList, $
                          set_list_select=where((*state.panelNames)[state.panel_sel] eq *state.panelValue)
          
          spd_ui_layout_resize_page, state, /row
          
          state.historywin->Update, 'SPD_UI_LAYOUT_OPTIONS: Row set to ' + $
                                         strcompress(string(uint(value)),/remove_all) + '.'
          state.statusbar->Update, 'SPD_UI_LAYOUT_OPTIONS: Row set to ' + $
                                         strcompress(string(uint(value)),/remove_all) + '.'
        endelse
      endif else if finite(event.value, /nan) then begin
        state.historywin->Update,'Illegal entry in row selection spinner..'
        state.statusbar->Update,'Illegal entry in row selection spinner.'
      endif else begin
        state.historywin->Update, 'Row number must be greater than 1.'
        state.statusbar->Update,'Row number must be greater than 1.'
      endelse   
    END
    'COL_SPAN': BEGIN
      if event.valid then begin
        value = event.value

        if value lt 1 then begin ; make sure col lt 1 isn't acceptable
          state.historywin->Update, 'Column span must be greater than 1.'
          state.statusbar->Update,'Column span must be greater than 1.'
        endif else begin
        
          cpanel = (*state.panelObjs)[state.panel_sel]
          cpanel->GetProperty, settings=panelSettings                    
          cpanel->SetLayoutStructure,cspan=value

          state.cWindow->getProperty,ncols=current_cols
  
          if value gt current_cols then begin
            current_cols = value
            state.cWindow->SetProperty, nCols=current_cols
            id = widget_info(state.tlb, find_by_uname='page_col')
            widget_control, id, set_value=current_cols
          endif
    
          if ptr_valid(state.panelObjs) then ptr_free, state.panelObjs
          state.panelObjs = ptr_new(*state.panels->Get(/All))
          
          state.npanels = n_elements(*state.panelObjs)
          if ptr_valid(state.panelValue) then ptr_free, state.panelValue
          if ptr_valid(state.panel_ValueInfo) then ptr_free, state.panel_ValueInfo
          if ptr_valid(state.panelNames) then ptr_free, state.panelNames
    
          ; get panel/tracenames and panel layout
          spd_ui_update_panel_list, state=state, panelNames=panelNames, $
             panelValue=panelValue, panel_ValueInfo=panel_ValueInfo, $
             panelLayout=panelLayout
  
          if ptr_valid(state.panelLayout) then ptr_free, state.panelLayout
          state.panelLayout = ptr_new(panelLayout)
          state.panelValue = ptr_new(panelValue)
          state.panel_ValueInfo = ptr_new(panel_ValueInfo)
          state.panelNames = ptr_new(panelNames)
          widget_control, state.panelList, set_value=*state.panelValue
          widget_control, state.panelList, $
                          set_list_select=where((*state.panelNames)[state.panel_sel] eq *state.panelValue)
          
          spd_ui_layout_resize_page, state, /col
          
          state.historywin->Update, 'SPD_UI_LAYOUT_OPTIONS: Column span to ' + $
                                          strcompress(string(uint(value)),/remove_all) + '.'
          state.statusbar->update,'SPD_UI_LAYOUT_OPTIONS: Column span to ' + $
                                          strcompress(string(uint(value)),/remove_all) + '.'
        endelse
      endif else if finite(event.value, /nan) then begin
        state.historywin->Update,'Illegal entry in column span selection spinner.'
        state.statusbar->Update,'Illegal entry in column span selection spinner.'
      endif else begin
        ; This handles the case where the user uses the spinner buttons to click down when column is already minimum
        state.historywin->Update, 'Column span must be greater than 1.'
        state.statusbar->Update,'Column span must be greater than 1.'
      endelse 
      
    END 
    'ROW_SPAN': BEGIN
      ; change row span of selected panel
      if event.valid then begin
        value = event.value
        
        if value lt 1 then begin ; make sure row lt 1 isn't acceptable
          state.historywin->Update, 'Row span must be greater than or equal to 1.'
          state.statusbar->Update,'Row span must be greater than or equal to 1.'
        endif else begin
        
          cpanel = (*state.panelObjs)[state.panel_sel]
          cpanel->GetProperty, settings=panelSettings
          cpanel->SetLayoutStructure,rspan=value

          cwindow = state.cWindow
          cwindow->getProperty,nrows=current_rows
 
          if value gt current_rows then begin
            current_rows = value
            state.cWindow->SetProperty, nRows=current_rows
            id = widget_info(state.tlb, find_by_uname='page_row')
            widget_control, id, set_value=current_rows
            ;set the spinner minimum so that user can't set number of rows per page less than any of the row numbers
            spd_ui_spinner_set_min_value, id, current_rows
          endif else if value lt current_rows then begin
            ; check if instead we can decrease the min row per page value
            maxrspan = 1
            for i = 0,state.npanels-1 do begin
              cpanel_temp = (*state.panelObjs)[i]
              cpanel_temp->GetProperty, settings=panelSettings_temp
              panelSettings_temp->GetProperty, rspan=rspan_temp
              panelLayout = cPanel_temp->getLayoutStructure()
              totalspan = rspan_temp + panelLayout.row - 1
              if totalspan gt maxrspan then maxrspan = totalspan
            endfor
            if value eq maxrspan then begin
              id = widget_info(state.tlb, find_by_uname='page_row')
              spd_ui_spinner_set_min_value, id, value
            endif
          endif
          if ptr_valid(state.panelObjs) then ptr_free, state.panelObjs
          state.panelObjs = ptr_new(*state.panels->Get(/All))
          
          state.npanels = n_elements(*state.panelObjs)
          if ptr_valid(state.panelValue) then ptr_free, state.panelValue
          if ptr_valid(state.panel_ValueInfo) then ptr_free, state.panel_ValueInfo
          if ptr_valid(state.panelNames) then ptr_free, state.panelNames
    
          ; get panel/tracenames and panel layout
          spd_ui_update_panel_list, state=state, panelNames=panelNames, $
             panelValue=panelValue, panel_ValueInfo=panel_ValueInfo, $
             panelLayout=panelLayout
  
          if ptr_valid(state.panelLayout) then ptr_free, state.panelLayout
          state.panelLayout = ptr_new(panelLayout)
          state.panelValue = ptr_new(panelValue)
          state.panel_ValueInfo = ptr_new(panel_ValueInfo)
          state.panelNames = ptr_new(panelNames)
          widget_control, state.panelList, set_value=*state.panelValue
          widget_control, state.panelList, $
                          set_list_select=where((*state.panelNames)[state.panel_sel] eq *state.panelValue)
          
          spd_ui_layout_resize_page, state, /row
          
          state.historywin->Update, 'SPD_UI_LAYOUT_OPTIONS: Row span set to ' + $
                                         strcompress(string(uint(value)),/remove_all) + '.'
          state.statusbar->Update, 'SPD_UI_LAYOUT_OPTIONS: Row span set to ' + $
                                         strcompress(string(uint(value)),/remove_all) + '.'
        endelse
      endif else if finite(event.value, /nan) then begin
        state.historywin->Update,'Illegal entry in row span selection spinner..'
        state.statusbar->Update,'Illegal entry in row span selection spinner.'
      endif else begin
        state.historywin->Update, 'Row span number must be greater than 1.'
        state.statusbar->Update,'Row span number must be greater than 1.'
      endelse   
    END
    'PAN_UP': BEGIN
      ; shift selected panel/trace up
      if ((*state.panelLayout).row)[state.panel_sel] gt 1 || $
            state.trace_sel ne -1 then begin
        spd_ui_layout_shift, state, /up
        spd_ui_layout_resize_page, state, /row, /single
      endif
    END
    'PAN_DOWN': BEGIN
      ; shift selected panel/trace down
      spd_ui_layout_shift, state, /down
    END
    'PAN_LEFT': BEGIN
      ; shift selected panel left
      if ((*state.panelLayout).col)[state.panel_sel] gt 1 then begin
        spd_ui_layout_shift, state, /left
        spd_ui_layout_resize_page, state, /col, /single
      endif
    END
    'PAN_RIGHT': BEGIN
      ; shift selected panel right
      spd_ui_layout_shift, state, /right
    END
    'ROW_SPAN': BEGIN
      
    END
    'ROW_SPAN': BEGIN
      
    END
    'REMPAN': BEGIN ;This is a misnomer, actually removes panel or trace

      pindex = state.panel_sel
      remlocked=0
      
      ;remove panel
      if state.trace_sel eq -1 then begin
        
        ; detect if panel that was removed is locked
        state.cWindow->GetProperty, locked=locked

        if state.panel_sel eq locked then begin
          ; flag to be reset later
          remlocked=1 
        endif else begin
          ; adjust index if needed, set later
          if locked gt state.panel_sel then locked=locked-1 ;
        endelse

        (*state.panelObjs)[pindex]->getProperty, id=panelNum
        *state.panels->Remove, (*state.panelObjs)[pindex] ; cpanel

        wastrace=0
        state.historywin->Update, 'SPD_UI_LAYOUT_OPTIONS: Removed Panel ' + $
                                       strcompress(string(panelNum+1),/remove_all)
        state.statusbar->Update, 'SPD_UI_LAYOUT_OPTIONS: Removed Panel ' + $
                                       strcompress(string(panelNum+1),/remove_all)
      endif else begin ;Remove trace
          
        cpanel = (*state.panelObjs)[pindex]
        
        cpanel->GetProperty, tracesettings=traceSettings, xaxis=xaxissettings, $
                             yaxis=yaxissettings, zaxis=zaxissettings
        xaxissettings->GetProperty, labels=xlabelsObj
        yaxissettings->GetProperty, labels=ylabelsObj
        
        tracesettings->Remove, position=state.trace_sel
        xlabelsObj->Remove, position=state.trace_sel
        ylabelsObj->Remove, position=state.trace_sel      
        
        cpanel->SetProperty, tracesettings=traceSettings
        orig_trace_sel = state.trace_sel
        
        ntraces = tracesettings->count()
        
        ; check to see if any spectra exist, if not, then reset z-axis
        if ntraces eq 0 then begin
          state.trace_sel=-1
          wastrace = 1
          ;if zaxis exists then get rid of it
          if obj_valid(zaxissettings) then zaxissettings->setProperty,placement=4,touchedPlacement=0
        endif else begin
        
          traces = traceSettings->get(/all)
          isspec = 0
          
          for i=0,ntraces-1 do begin
            if obj_isa(traces[i],'spd_ui_spectra_settings') then isspec=1
          endfor
          
          if ~isspec then begin
            if obj_valid(zaxissettings) then zaxissettings->setProperty,placement=4,touchedPlacement=0
          endif
        endelse
        
        if state.trace_sel gt (ntraces-1) then state.trace_sel = ntraces-1
        cpanel->getProperty, id=panelNum
        state.historywin->Update, 'SPD_UI_LAYOUT_OPTIONS: Removed trace ' + $
                               strcompress(string(orig_trace_sel+1),/remove_all) $
                               + ' from Panel ' + strcompress(string(panelNum+1),/remove_all)
        state.statusBar->update, 'SPD_UI_LAYOUT_OPTIONS: Removed trace ' + $
                               strcompress(string(orig_trace_sel+1),/remove_all) $
                               + ' from Panel ' + strcompress(string(panelNum+1),/remove_all)
      endelse
      
    ; begin "in case of cancel of child panel" code
      state.cWindow->GetProperty, Panels=panels, nRows=nrows, nCols=ncols;, locked=locked ;locked necessary?
      if ptr_valid(state.panels) then ptr_free, state.panels
      state.panels = ptr_new(panels)
    ; end "in case of cancel of child panel" code

      if ptr_valid(state.panelObjs) then ptr_free, state.panelObjs
      state.panelObjs = ptr_new(*state.panels->Get(/All))
      
      if obj_valid((*state.panelObjs)[0]) then begin
      
        state.npanels = n_elements(*state.panelObjs)
        if ptr_valid(state.panelValue) then ptr_free, state.panelValue
        if ptr_valid(state.panel_ValueInfo) then ptr_free, state.panel_ValueInfo
        if ptr_valid(state.panelNames) then ptr_free, state.panelNames
  
        ; set the "locked" panel
        ; if the locked panel was removed then lock to the next panel in the list
        ; othewise, adjust locked index for removed panel (determined above) 

        if remlocked then begin
          state.cwindow->SetProperty, locked= pindex-1 > 0
        endif else begin
          state.cwindow->SetProperty, locked=locked
        endelse
        
        ; get panel/tracenames and panel layout
        spd_ui_update_panel_list, state=state, panelNames=panelNames, $
           panelValue=panelValue, panel_ValueInfo=panel_ValueInfo, $
           panelLayout=panelLayout, ntr=ntr
        
        if ptr_valid(state.panelLayout) then ptr_free, state.panelLayout
        state.panelLayout = ptr_new(panelLayout)
        state.panelValue = ptr_new(panelValue)
        state.panel_ValueInfo = ptr_new(panel_ValueInfo)
        state.panelNames = ptr_new(panelNames)
        ;state.panel_sel = state.npanels-1
        widget_control, state.panelList, set_value=*state.panelValue

        if state.trace_sel eq -1 then begin
          
          if ~wastrace and state.panel_sel eq state.npanels then state.panel_sel = state.npanels-1
         
          rowvalue = ((*state.panelLayout).row)[state.panel_sel]
          colvalue = ((*state.panelLayout).col)[state.panel_sel]
          rspanvalue = ((*state.panelLayout).rspan)[state.panel_sel]
          cspanvalue = ((*state.panelLayout).cspan)[state.panel_sel]
        
          widget_control, state.panelList, $
                          set_list_select=where((*state.panelNames)[state.panel_sel] eq *state.panelValue)

          widget_control, state.shiftleftButton, sensitive=1
          widget_control, state.shiftrightButton, sensitive=1
          widget_control, state.shiftupButton, sensitive=1
          widget_control, state.shiftdownButton, sensitive=1
          widget_control, state.rowtext, set_value=rowvalue, sensitive=1
          widget_control, state.coltext, set_value=colvalue, sensitive=1
          widget_control, state.rowSpan, set_value=rspanvalue, sensitive=1
          widget_control, state.colSpan, set_value=cspanvalue, sensitive=1

        endif else begin

          rowvalue = ((*state.panelLayout).row)[state.panel_sel]
          colvalue = ((*state.panelLayout).col)[state.panel_sel]
          
          new_trace_ind = where(*state.panelValue eq (*state.panelNames)[state.panel_sel]) $
                            + state.trace_sel + 1
          
          widget_control, state.panelList, set_list_select=new_trace_ind        
  
          if state.trace_sel eq 0 then widget_control, state.shiftupButton, sensitive=0 $
            else widget_control, state.shiftupButton, sensitive=1
            
          if state.trace_sel eq (ntr[state.panel_sel]-1) then widget_control, state.shiftdownButton, sensitive=0 $
            else widget_control, state.shiftdownButton, sensitive=1
        endelse
        
      endif else begin

        if ptr_valid(state.panelLayout) then ptr_free, state.panelLayout
        state.npanels = 0
        state.panelLayout = ptr_new()
        state.panelValue = ptr_new()
        state.panel_ValueInfo = ptr_new()
        state.panelNames = ptr_new()
        state.panel_sel = state.npanels-1
        widget_control, state.panelList, set_value='';*state.panelValue

        widget_control, state.shiftleftButton, sensitive=0
        widget_control, state.shiftrightButton, sensitive=0
        widget_control, state.shiftupButton, sensitive=0
        widget_control, state.shiftdownButton, sensitive=0
        widget_control, state.rowtext, sensitive=0
        widget_control, state.coltext, sensitive=0
        id = widget_info(state.tlb, find_by_uname='rempan')
        widget_control, id, sensitive=0
        id = widget_info(state.tlb, find_by_uname='edvar')
        widget_control, id, sensitive=0
        id = widget_info(state.tlb, find_by_uname='lock_pan')
        widget_control, id, sensitive=0
        id = widget_info(state.tlb, find_by_uname='unlock_pan')
        widget_control, id, sensitive=0
        widget_control, state.editButton, sensitive=0

      endelse
      spd_ui_update_var_widget, state=state
;      spd_ui_init_tree_widgets, state=state ; no longer needed, was only for updating var widget?
    END
    'REMVAR': BEGIN
      ; remove variables from variable box
    END
    'SHOWCOMP': BEGIN
            
      if widget_info(state.priBase, /valid_id) then begin
        id = widget_info(state.tlb, find_by_uname='pritree')
        widget_control, id, get_value=val
        state.pritree_copy = val->getCopy()
      endif    
      
      ; copy x-axis tree
      if widget_info(state.terBase, /valid_id) then begin
        id = widget_info(state.tlb, find_by_uname='tertree')
        widget_control, id, get_value=val
        state.xtree_copy = val->getCopy()
      endif
      
      ;copy y-axis tree from spec-component mode
      if state.compviewmode then begin
        id = widget_info(state.tlb, find_by_uname='sectree')
        widget_control, id, get_value=val
        state.secTree_copy = val->getCopy()
      endif
       
      state.compviewmode = event.select
      
      spd_ui_init_tree_widgets, state=state
    END
    'VARDOWN': BEGIN
      ; move variable down in box
    END
    'VAR_LIST': BEGIN
      if event.clicks eq 1 then begin
        pindex = widget_info(state.variableText, /list_select)
      endif else begin
        pindex = widget_info(state.variableText, /list_select)
      endelse
    END
    'VARUP': BEGIN
      ; move variable up in box
    END
    Else:
  ENDCase
  ; Update the rows per page and columns per pages spinner minimums - this doesn't need to happen for every event,
  ; only for events where a column or row number is changed. But this includes delete/add as well as move.
  ; Could put this code in each case instead.
  if state.npanels gt 0 then begin
     spd_ui_layout_options_update_spinner_min, *state.panelObjs,  state.tlb
  endif
  
  Widget_Control, event.TOP, Set_UValue=state, /No_Copy
  
RETURN
END ;--------------------------------------------------------------------------------



PRO spd_ui_layout_options, info

  compile_opt idl2

  windowStorage = info.windowStorage
  zaxisSettings = info.zaxisSettings
  loadedData = info.loadedData
  drawObject = info.drawObject
  
  screen_size = get_screen_size()
  tree_size = min([350,floor((screen_size[0]/4.5))])
  
  def_colors = [[0,0,0],[255,0,0],[0,255,0],[0,0,255],[110,110,110]]
  lockPrefix = '(L)  '
  isspec = 0

    ; top level and base widgets

  ; in case of error
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx Ne 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output=err_msg
    FOR j = 0, N_Elements(err_msg)-1 DO begin
      Print, err_msg[j]
      info.historywin->update,err_msg[j]
    endfor
    Print, 'Error in Layout Panel--See history'
    
    Widget_Control,tlb,/destroy
    ok = error_message('An unknown error occured while starting Plot/Layout Options', $
                       traceback=0, /center, /noname, title='Error in Plot/Layout Options')
    spd_gui_error, info.master, info.historywin
    RETURN
  ENDIF
    
  tlb = Widget_Base(/Col, Title='Plot/Layout Options', Group_Leader=info.master, $
                    /Modal, /Floating, /tlb_kill_request_events, tab_mode=1) 

  toprowBase = Widget_Base(tlb, /Row, /Align_Left, space=200)
    traceBase = Widget_Base(toprowBase, /Row, /NonExclusive, /Align_Left)
    titleBase = Widget_Base(toprowBase, /Row, /Align_Center)
  topBase = Widget_Base(tlb, /Row, /Align_Center)
    dataBase = Widget_Base(topBase, /Row, /Align_Center)
      tabBase = Widget_Tab(dataBase, location=0)
        priBase = Widget_Base(tabBase, Title='Dependent Variable', /Col) ; primary base
      plusBase = Widget_Base(topBase, /Col, YPad=150)
    rightBase = Widget_Base(topBase, /Row)
      panelvarBase = Widget_Base(rightbase, /Col, /align_bottom)
        panelBase = Widget_Base(panelvarBase, /Row)
        variableBase=Widget_Base(panelvarBase, /Row)
          varTextBoxBase = Widget_Base(variableBase, /Row)
          varButtonsBase = Widget_Base(variableBase, /Col)
            varLabelBase = Widget_Base(varButtonsBase, /Row)
      topButtonBase = Widget_Base(rightBase, /Col)
        tbuttonBase = Widget_Base(topButtonBase, /Align_Center, /Col)
        arrowBase = Widget_Base(topButtonBase, /Align_Center, /Row)
          leftArrowBase = Widget_Base(arrowBase, /Align_Center)
          updownArrowBase = Widget_Base(arrowBase, /Align_Center, /Col)
          rightArrowBase = Widget_Base(arrowBase, /Align_Center)
        rcTextBase = Widget_Base(topButtonBase, /Align_Center, /Col)
          rowTextBase = Widget_Base(rcTextBase, /Align_Center, /Col)
          colTextBase = Widget_Base(rcTextBase, /Align_Center, /Col)
          rowSpanBase = Widget_Base(rcTextBase, /Align_Center, /Col)
          colSpanBase = Widget_Base(rcTextBase, /Align_Center, /Col)
          rowPageTextBase = Widget_Base(rcTextBase, /Align_Center, /Col)
          colPageTextBase = Widget_Base(rcTextBase, /Align_Center, /Col)
  buttonBase = Widget_Base(tlb, /Row, /Align_Center, YPad=5) 
  statusBase = Widget_Base(tlb, /Row, /Align_Center, YPad=5) 

      ;retrieve data and panel info for display
  ;dataNames = info.loadedData->GetAll()
  dataNames = info.loadedData->GetAll(/child)
  IF is_num(dataNames) THEN dataNames=''
  cWindow = info.windowStorage->GetActive()
  origWindow = cWindow->Copy()
  IF NOT Obj_Valid(cWindow) THEN BEGIN
     panelNames=[''] 
  ENDIF ELSE BEGIN
     cWindow->GetProperty, Panels=panels, nRows=nRows, nCols=nCols, locked=locked
     initNRows = nRows
     initNCols = nCols
;     cwindow->GetProperty, variables=variablescontainer
;     variablesobjects = variablescontainer->get(/all)
     IF NOT Obj_Valid(panels) THEN panelObjs=[''] ELSE panelObjs = panels->Get(/All)
  ENDELSE


  if obj_valid(panelObjs[0]) then begin
  
    npanels = n_elements(panelObjs)
    panelNames = strarr(npanels)
  
    for i = 0,npanels-1 do begin ; loop over panels
    
      cPanel = panelObjs[i]
      
      panelNames[i] = cPanel->constructPanelName()
      
      cwindow->GetProperty, locked=locked
      if i eq locked then panelNames[i] = lockPrefix + panelNames[i]
      
      if i eq 0 then panelValue = panelNames[i] $
        else panelValue = [panelValue, panelNames[i]]
        
      if i eq 0 then panelLayout = cPanel->getLayoutStructure() $
        else panelLayout = [panelLayout, cPanel->getLayoutStructure()]
      
      if i eq 0 then panel_ValueInfo = {panelListInfo, ispanel:1, istrace:0, $
                                       panelid:panelLayout[i].id, traceid:-1} $
        else panel_ValueInfo = [panel_ValueInfo, {panelListInfo, ispanel:1, istrace:0, $
                                                panelid:panelLayout[i].id, traceid:-1}]
      
      cPanel->getProperty,traceSettings=traceSettings
      traces = traceSettings->get(/all)
      
      if obj_valid(traces[0]) then begin
        ntr = n_elements(traces)
        trNames = cPanel->constructTraceNames()
        
        for j = 0,ntr-1 do begin
          panelValue = [panelValue, trNames[j]]
          panel_ValueInfo = [panel_ValueInfo, {panelListInfo, ispanel:0, istrace:1, $
                                             panelid:panelLayout[i].id, traceid:j}]          
          traces[j]->getProperty,dataX=dx, dataY=dy
          if obj_isa(traces[j],'spd_ui_spectra_settings') then begin
              traces[j]->getProperty,dataZ=dz
          endif else dz = ''
        endfor        
      endif
    endfor
  
  endif else begin
    npanels=0
    panelNames=''
  endelse

  ctextvalues=['']

  plotTypeTitle = Widget_Label(titleBase, Value='  - CREATE PLOTS -  ', uname='plottypetitle')
  
  compviewButton = Widget_Button(traceBase, Value='Show Data Components', UValue='SHOWCOMP', $
                              uname='showcomp', sensitive=1, tooltip='Show Components of ' + $
                              'data variables in widget trees')
  compviewmode = 0

  autopanelbutton = widget_button(traceBase, value='Automatic Panels', $
                     uval='autopanel', uname='AUTOPANEL', tooltip= $
                     'Automatically create a new panel for each new variable.')
  widget_control, autopanelbutton, set_button=1

  ;Primary Axis Tree
  priTree = obj_new('spd_ui_widget_tree',priBase,'PRITREE',loadedData, XSize=tree_size, $
                    YSize=425,mode=3,multi=1,leafonly=1, uname='pritree',/showdatetime, $
                    from_copy=long(*info.guiTree))

  if ~array_equal(datanames, '', /no_typeconv) then begin
    xSelect = dataNames[0]
    ySelect = dataNames[1]
  endif else begin
    xSelect = ''
    ySelect = ''
  endelse
  
  add_label = widget_label(plusbase,value=' Add: ')

  plusButtonSens = is_string(xSelect) && is_string(ySelect)
  plusButton = Widget_Button(plusBase, Value=' Line -> ', UValue='ADDLINE', $
    Tooltip='Add Lines to the selected panel', sensitive=plusButtonSens)

  if isspec then begin

  endif else begin
    specButton = Widget_Button(plusBase, Value=' Spec -> ', UValue='ADDSPEC', $
                 Tooltip='Add Spectrograms to selected panel', sensitive=plusButtonSens)
  endelse
  
  panelLabel = Widget_Label(tbuttonBase, Value='Panels', /Align_Center)

  panelList = Widget_List(panelBase, Value=panelValue, UValue='PANEL', /Align_Left, $
                          YSize=24, xsize=70)
  if npanels gt 0 then  widget_control, panelList, $
                           set_list_select=where(panelNames[npanels-1] eq panelValue)
  trace_sel=-1

  lockBase = Widget_Base(topButtonBase, /Col, /Align_Left)
  lockAxesButton = Widget_Button(lockBase, Value='Lock To Panel', UValue='LOCK_PAN', $
                                 uname='lock_pan', $
                                 tooltip='Lock panel axes to currently selected panel. ' + $
                                         'Notated by an (L).',sensitive=(npanels gt 0))
  unlockAxesButton = Widget_Button(lockBase, Value='Unlock Panels', UValue='UNLOCK_PAN', $
                                   uname='unlock_pan', tooltip='Unlock Panel Axes.',sensitive=(npanels gt 0))
  
  
  addButton = Widget_Button(tbuttonBase, Value=' Add ', UValue='ADDPAN', uname='addpan', $
    Tooltip='Add a new panel')

  removeButton = Widget_Button(tbuttonBase, Value=' Remove ', UValue='REMPAN', uname='rempan', $
    Tooltip='Removes the selected panel/trace', sensitive=(npanels gt 0))

  editButton = Widget_Button(tbuttonBase, Value=' Edit ', UValue='EDPAN', uname='edpan', $
    Tooltip='Edit panel/trace (opens Panel, Line, or Z-Axis Options window)', sensitive=(npanels gt 0))
  
  getresourcepath,rpath
  leftArrow = read_bmp(rpath + 'arrow_180_medium.bmp', /rgb)
  rightArrow = read_bmp(rpath + 'arrow_000_medium.bmp', /rgb)
  upArrow = read_bmp(rpath + 'arrow_090_medium.bmp', /rgb)
  downArrow = read_bmp(rpath + 'arrow_270_medium.bmp', /rgb)
  
  spd_ui_match_background, tlb, leftArrow
  spd_ui_match_background, tlb, rightArrow
  spd_ui_match_background, tlb, upArrow
  spd_ui_match_background, tlb, downArrow
  
  shiftupButton = Widget_Button(updownArrowBase, Value=upArrow, /Bitmap, UValue='PAN_UP', $
    Tooltip='Move this panel/trace up by one', sensitive=(npanels gt 0))
  shiftdownButton = Widget_Button(updownArrowBase, Value=downArrow, /Bitmap, $
    UValue='PAN_DOWN', Tooltip='Move this panel/trace down by one', sensitive=(npanels gt 0))
  shiftleftButton = Widget_Button(leftArrowBase, Value=leftArrow, /Bitmap, $
                                  UValue='PAN_LEFT', Tooltip='Move this panel left by one', $
                                  sensitive=(npanels gt 0))
  shiftrightButton = Widget_Button(rightArrowBase, Value=rightArrow, /Bitmap, $
                                   UValue='PAN_RIGHT', Tooltip='Move this panel right by one', $
                                   sensitive=(npanels gt 0))
  rowLabel = Widget_Label(rowTextBase, Value='Row:')
  
  if npanels gt 0 then $
    rowText = spd_ui_spinner(rowTextBase, Increment=1, Value=panelLayout[npanels-1].row, $
                               UValue='PAN_ROW',uname='pan_row', min_value=1) $
    else $
    rowText = spd_ui_spinner(rowTextBase, Increment=1, Value=1, UValue='PAN_ROW', uname='pan_row',sensitive=0, min_value=1)
                               
  colLabel = Widget_Label(colTextBase, Value='Column:')

  if npanels gt 0 then $
    colText = spd_ui_spinner(colTextBase, Increment=1, Value=panelLayout[npanels-1].col, $
                             UValue='PAN_COL', uname='pan_col',min_value=1) $
    else $
    colText = spd_ui_spinner(colTextBase, Increment=1, Value=1, UValue='PAN_COL',uname='pan_col', sensitive=0, min_value=1)

  rowSpanLabel = Widget_Label(rowSpanBase, Value='Row Span:')
  
  if npanels gt 0 then $
    rowSpan = spd_ui_spinner(rowSpanBase, Increment=1, Value=panelLayout[npanels-1].rspan, $
                               UValue='ROW_SPAN',uname='row_span', min_value=1) $
    else $
    rowSpan = spd_ui_spinner(rowSpanBase, Increment=1, Value=1, UValue='ROW_SPAN', uname='row_span',sensitive=0, min_value=1)
                               
  colSpanLabel = Widget_Label(colSpanBase, Value='Col Span:')
  
  if npanels gt 0 then $
    colSpan = spd_ui_spinner(colSpanBase, Increment=1, Value=panelLayout[npanels-1].cspan, $
                               UValue='COL_SPAN',uname='col_span', min_value=1) $
    else $
    colSpan = spd_ui_spinner(colSpanBase, Increment=1, Value=1, UValue='COL_SPAN', uname='col_span',sensitive=0, min_value=1)
                               
    
  rowspace = Widget_Label(rowPageTextBase, Value='')
  rowPageLabel = Widget_Label(rowPageTextBase, Value='Rows Per Page:')
  colPageLabel = Widget_Label(colPageTextBase, Value='Cols Per Page:')
  ; initialise the minimum values for rows per page and columns per page
  maxcspan=1
  maxrspan=1
  for i = 0,npanels-1 do begin
    cPanel = panelObjs[i]
    cpanel->GetProperty, settings=panelSettings
    panelSettings->GetProperty, cspan=cspan_temp, rspan=rspan_temp
    totalspan_c = cspan_temp + panelLayout[i].col - 1
    totalspan_r = rspan_temp + panelLayout[i].row -1
    if totalspan_c gt maxcspan then maxcspan = totalspan_c
    if totalspan_r gt maxrspan then maxrspan = totalspan_r
  endfor 

  rowPageText = spd_ui_spinner(rowPageTextBase, Increment=1, Value=nrows, $
                                 UValue='PAGE_ROW', uname='page_row',min_value=maxrspan)
                               
  colPageText = spd_ui_spinner(colPageTextBase, Increment=1, Value=ncols, $
                                 UValue='PAGE_COL', uname='page_col',min_value=maxcspan)


; VARIABLES WIDGETS ------------------------------------------------------------
  variableLabel =  Widget_Label(varLabelBase, Value='Variables: ')
  variableText = WIDGET_TEXT(varTextBoxBase, Value=ctextvalues, XSize=40, YSize=8, $
                             UValue='VAR_LIST',/wrap)
  varEditButton = Widget_Button(varButtonsBase, Value=' Add/Edit ', UValue='EDVAR', uname='edvar',$
                                tooltip='Open Variable Options panel',sensitive=(npanels gt 0))              


; MAIN BUTTON WIDGETS ----------------------------------------------------------
  okButton = Widget_Button(buttonBase, Value=' OK ', UValue='OK', XSize=80, $
    Tooltip='Applies the changes to the layout and closes the window')
  applyButton = Widget_Button(buttonBase, Value=' Apply ', UValue='APPLY', $
    Tooltip='Applies the changes to the layout', XSize=80)
  cancelButton = Widget_Button(buttonBase, Value=' Cancel ', UValue='CANC', XSize=80, $
    Tooltip='Cancels the operation and closes the window')

  

  cWindow->getProperty,settings=psettings
  psettings->save
  
; SETUP EVENT HISTORY
  numEvents = 5
  uvalHist = strarr(numEvents) ; init array of last 5 uvals
  eventHist = ptrarr(numEvents, /allocate_heap)
  for i=0,numEvents-1 do *eventHist[i]=''
  
; REPORT WINDOW OPENING TO GUI STATUS BAR
  info.statusBar->update,'Plot/Layout Options opened.'
  
  StatusBar = Obj_New('SPD_UI_MESSAGE_BAR', $
                       Value='Status information is displayed here.', $
                        statusBase, XSize=150, YSize=1)
  
  
  state = {tlb:tlb, info:info, uvalHist:uvalHist, eventHist:eventHist, $
           tree_size:tree_size, compviewmode:compviewmode, $
           def_colors:def_colors, lockPrefix:lockPrefix, $
           variableText:variableText, panelList:panelList, $
           xselect:Ptr_New(xselect), yselect:Ptr_New(yselect), zselect:Ptr_New(), $
           y_ind:Ptr_New(), z_ind:Ptr_New(), $
           dataNames:dataNames, $
           rowtext:rowtext, coltext:coltext, rowspan:rowspan, colspan:colspan, $
           rowPageText:rowPageText, colPageText:colPageText, $
           editButton:editButton, plusButton:plusButton, $
           shiftleftButton:shiftleftButton, shiftrightButton:shiftrightButton, $
           shiftupButton:shiftupButton, shiftdownButton:shiftdownButton, $
           panels:ptr_new(panels), panelObjs:ptr_new(panelObjs), panelValue:ptr_new(panelValue), $
           initNRows:initNRows, initNCols:initNCols, $
           varList:Ptr_New(), $
           panelLayout:Ptr_New(panelLayout), npanels:npanels, panel_sel:(npanels-1), $
           panel_ValueInfo:Ptr_New(panel_ValueInfo), panelNames:ptr_new(panelNames), $
           trace_sel:trace_sel, is_trace_spec:0, $
           tabBase:tabBase, priBase:priBase, secBase:0, terBase:0, $
           priTree:priTree, secTree:obj_new(), terTree:obj_new(), $
           xtree_copy:-1l, priTree_copy:long(*info.guiTree), secTree_copy:-1l, $
           specButton:specButton, plusBase:plusBase, autopanel:autopanelbutton, $
           cWindow:cWindow, origWindow:origWindow, template:info.template_object,$
           windowStorage:windowStorage, loadedData:loadedData, drawObject:drawObject, $
           zaxisSettings:zaxisSettings,treeCopyPtr:info.guiTree, $
           historywin:info.historywin,statusbar:statusbar}
 
  cWindow->getProperty,locked=locked
  spd_ui_update_var_widget, state=state

  CenterTlb, tlb
  Widget_Control, tlb, Set_UValue=state, /No_Copy
  Widget_Control, tlb, /Realize

 ; spd_ui_init_tree_widgets, tlb

  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif
  
  XManager, 'spd_ui_layout_options', tlb, /No_Block
  
RETURN
END
