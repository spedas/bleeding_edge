;+
;NAME:
;  spd_ui_lock_axes__define
;
;PURPOSE:
;  Object just organizes the locking routines.  It is more a way
;  or co-locating some related methods, than a data structure 
;  
;  Note that these methods are not guaranteed to work in the event that
;  a panel spans multiple columns, yet other panels in its column do not.
;
;CALLING SEQUENCE:
; obj = obj_new('spd_ui_lock_axes',window_storage,draw_object)
; 
;Methods:
;
;HISTORY:
;$LastChangedBy: nikos $
;$LastChangedDate: 2016-10-20 16:23:30 -0700 (Thu, 20 Oct 2016) $
;$LastChangedRevision: 22177 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/deprecated/spd_ui_lock_axes__define.pro $
;
;--------------------------------------------------------------------------------

;Call this to lock axes in the current window
pro spd_ui_lock_axes::lock,windowId=windowid

  compile_opt idl2

  self->update,windowId=windowId

end

;Call this to unlock axes in the current window
pro spd_ui_lock_axes::unlock,windowId=windowId
 
  compile_opt idl2

  self->update,/unlock,windowId=windowId

end

;Call this when a new panel is added
;Expects that the panel has already been added,
;but makes sure that the new panel and adjacent panels
;maintain the proper locked panel settings
pro spd_ui_lock_axes::add,panel

  compile_opt idl2

  self->panel_change,panel

end

;Call this when a panel is removed
;Expects that the panel has not yet been removed
;but makes sure that the adjacent panels to the removed
;panel maintain the proper locked panel settings
pro spd_ui_lock_axes::remove,panel

  compile_opt idl2
  
  self->panel_change,panel,/remove

end



;If lock axes is on, and a new panel is added,
;The defaults need to be modified, to reflect this.
pro spd_ui_lock_axes::panel_change,panel,remove=remove

  compile_opt idl2

  window = self.window_storage->getactive()
  
  window->getProperty,locked=locked,panels=panels
  
  if ~locked then return
  
  panel->getProperty,settings=settings
  
  if ~obj_valid(settings) then begin
    ok = error_message('Malformed panel',/traceback)
    return
  endif
  
  settings->getProperty,col=col,cspan=cspan
  
  panel_list = panels->get(/all)
  
  for i = 0,cspan-1 do begin
  
    col_list = window->getColumn(col+i)
    
    if is_num(col_list) then begin
      ok = error_message('Column invariant not maintained',/traceback)
      return  
    endif
    
    if n_elements(col_list) eq 1 then continue
    
    idx = where(panel eq col_list,c)
    
    ;something is wrong
    if c eq 0 then begin
      ok = error_message('Column invariant not maintained',/traceback)
      return  
    endif
    
    ;calculate the range without the current panel in the list
    range = self->get_range(col_list[ssl_set_complement([idx],indgen(n_elements(col_list)))],panel_list)
    
    if n_elements(range) eq 1 then begin
      ok = error_message('Could not properly calculate range, change failed',/traceback)
      return
    endif
    
    if idx eq 0 then begin
      ;new top panel
      if keyword_set(remove) then begin
        self->lock_middle,col_list[1],range,/unlock
        if n_elements(col_list) gt 2 then begin
          self->lock_top,col_list[1],range
        endif
      endif else begin
        self->lock_top,col_list[0],range
        self->lock_middle,col_list[1],range
      endelse
    endif else if idx eq n_elements(col_list)-1 then begin
      ;new bottom panel
      if keyword_set(remove) then begin
        self->lock_middle,col_list[n_elements(col_list)-2],range,/unlock
        if n_elements(col_list) gt 2 then begin
          self->lock_bottom,col_list[n_elements(col_list)-2],range
        endif
      endif else begin
        self->lock_bottom,col_list[n_elements(col_list)-1],range
        self->lock_middle,col_list[n_elements(col_list)-2],range
      endelse
    endif else begin
      self->lock_middle,col_list[idx],range
    endelse
  
  endfor

end

;helper method.  Locks the middle panel in a layout
pro spd_ui_lock_axes::lock_middle,panel,range,unlock=unlock
 
  compile_opt idl2
  
  panel->getProperty,xaxis=xaxis,settings=settings,markers=markers
  
  if keyword_set(unlock) then begin
    panel->setProperty,showvariables = 1
  endif else begin
    panel->setProperty,showvariables = 0
  endelse
  
  if obj_valid(xaxis) then begin
  
    
    if keyword_set(unlock) then begin
      xaxis->setProperty,showdate=1,$
                         showlabels=1,$
                         annotateAxis=1

    endif else begin
      xaxis->setProperty,tickStyle=0, $
                       showdate=0,$
                       showlabels=0,$
                       annotateAxis=0,$
                       rangeOption=2
                       
      if n_elements(range) eq 2 then begin
        xaxis->updateRange,range
      endif
      
    endelse
    
  endif
  
  if obj_valid(settings) then begin
    settings->getProperty,titleobj=title
   
    if obj_valid(title) then begin
      if keyword_set(unlock) then begin
        title->setProperty,show=1
      endif else begin
        title->setProperty,show=0
      endelse
    endif
  
  endif
  
  ;If marker title is below the axis, then move it to the middle
  if obj_valid(markers) && ~keyword_set(unlock) then begin
    marker_list = markers->get(/all)
    
    if ~is_num(marker_list[0]) then begin
      for i = 0,n_elements(marker_list)-1 do begin
      
        marker_list[i]->getProperty,settings=msettings
        
        if obj_valid(msettings) then begin
          msettings->getProperty,vertPlacement=vert
          
          if vert eq 6 || vert eq 0 then begin
            msettings->setProperty,vertPlacement=3
          endif
        endif
        
      endfor
    endif
  endif

end

;helper method.  Locks the top panel in a layout
pro spd_ui_lock_axes::lock_top,panel,range,unlock=unlock
 
  compile_opt idl2

  panel->getProperty,xaxis=xaxis,markers=markers
  
  if keyword_set(unlock) then begin
    panel->setProperty,showvariables = 1
  endif else begin
    panel->setProperty,showvariables = 0
  endelse
  
  if obj_valid(xaxis) then begin
  
    xaxis->getProperty,placeAnnotation=pa
    
    if keyword_set(unlock) then begin
      if ~pa then begin
        xaxis->setProperty,showlabels = 1
        xaxis->setProperty,annotateAxis = 1
      endif 
    
      xaxis->setProperty,showdate=1
    
    endif else begin
    
      if ~pa then begin
        xaxis->setProperty,showlabels = 0
        xaxis->setProperty,annotateAxis = 0
      endif 
    
      xaxis->setProperty,tickStyle=0, $
                         showdate=0,$
                         rangeoption=2
         
      if n_elements(range) eq 2 then begin                   
        xaxis->updateRange,range
      endif
      
    endelse
    
    
  endif
  
  ;If marker title is below the axis, then move it to the middle
  if obj_valid(markers) && ~keyword_set(unlock) then begin
    marker_list = markers->get(/all)
    
    if ~is_num(marker_list[0]) then begin
      for i = 0,n_elements(marker_list)-1 do begin
      
        marker_list[i]->getProperty,settings=msettings
        
        if obj_valid(msettings) then begin
          msettings->getProperty,vertPlacement=vert
          
          if vert eq 6 then begin
            msettings->setProperty,vertPlacement=3
          endif
        endif
        
      endfor
    endif
  endif

end

;helper method.  Locks the bottom panel in a layout
pro spd_ui_lock_axes::lock_bottom,panel,range,unlock=unlock

  compile_opt idl2
  
  panel->getProperty,xaxis=xaxis,settings=settings,markers=markers
  panel->setProperty,showvariables = 1
  
  if obj_valid(xaxis) && ~keyword_set(unlock) then begin
  
    xaxis->getProperty,placeAnnotation=pa
  
    if pa then begin
      xaxis->setProperty,placeAnnotation=0
    endif 
  
    xaxis->setProperty,tickStyle=0,rangeoption=2
    
    if n_elements(range) eq 2 then begin
      xaxis->updateRange,range
    endif
    
   ; xaxis->setProperty,
    xaxis->setProperty,annotateAxis = 1   
    xaxis->setProperty,showdate=1
    
  endif
  
  
  if obj_valid(settings) then begin
    settings->getProperty,titleobj=title
    
    if obj_valid(title) then begin
      if keyword_set(unlock) then begin
        title->setProperty,show=1
      endif else begin
        title->setProperty,show=0
      endelse
    endif
  
  endif
  
  ;If marker title is below the axis, then move it to the middle
  if obj_valid(markers) && ~keyword_set(unlock) then begin
    marker_list = markers->get(/all)
    
    if ~is_num(marker_list[0]) then begin
      for i = 0,n_elements(marker_list)-1 do begin
      
        marker_list[i]->getProperty,settings=msettings
        
        if obj_valid(msettings) then begin
          msettings->getProperty,vertPlacement=vert
          
          if vert eq 6 || vert eq 0 then begin
            msettings->setProperty,vertPlacement=3
          endif
        endif
        
      endfor
    endif
  endif
  
end

;helper function.
;This calculates the range of a column so that ranges
;can be synchronized during locking
;col is the list of panels in a column
;panels is the list of all panels in a window
function spd_ui_lock_axes::get_range,col,panels

  compile_opt idl2
  
 ; self.draw_object->update,self.window_Storage,self.loaded_Data
  
  range = 0
  
  for i = 0,n_elements(col)-1 do begin
  
    idx = where(col[i] eq panels)
  
    info = self.draw_object->getPanelInfo(idx)
    
    if ~is_struct(info) then return,0
    
    ;don't incorporate the range from a panel with no traces in the calculation
    if ~info.hasLine && ~info.hasSpec then continue
    
    if info.xscale eq 0 then begin
      panel_range = info.xrange
    endif else if info.xscale eq 1 then begin
      panel_range = 10 ^ info.xrange
    endif else if info.xrange eq 2 then begin
      panel_range = exp(info.xrange)
    endif
  
    if ~keyword_set(range) then begin
      range = panel_range
    endif else begin
      
      if panel_range[0] lt range[0] then begin
        range[0] = panel_range[0]
      endif
      
      if panel_range[1] gt range[1] then begin
        range[1] = panel_range[1]
      endif
      
    endelse
  
  endfor

  return,range

end

;the main workhorse, but not really meant
;to be called directly
pro spd_ui_lock_axes::update,unlock=unlock,windowId=windowId

  compile_opt idl2

  if keyword_set(windowid) then begin
    window = self.window_storage->getObjects(id=windowid)
    if ~obj_valid(window[0]) then begin
      ok = error_message('Illegal window id',/traceback)
      return
    endif
  endif else begin
    window = self.window_storage->getactive()
  endelse
  
  ;turn on locking
  
 ; if keyword_set(unlock) then begin
 ;   window->setProperty,locked=0
 ; endif else begin
 ;   window->setProperty,locked=1
 ; endelse
  
  window->getproperty,nrows=nrows,ncols=ncols,panels=panels,settings=page_settings
  
  if keyword_set(unlock) then begin
    page_settings->setProperty,ypanelspacing=60
  endif else begin
    page_settings->setProperty,ypanelspacing=5
  endelse

  panel_list = panels->get(/all)

  ;lock operation is once per column
  for i = 1,ncols do begin
  
    cols = window->getColumn(i)
    
    if is_num(cols) && $
      n_elements(cols) eq 1 then continue
     
    range = self->get_range(cols,panel_list)
    
   ; if n_elements(range) eq 1 then continue
    
    if n_elements(cols) eq 1 then begin
         self->lock_bottom,cols[0],/unlock
         self->lock_top,cols[0],/unlock
         
         cols[0]->getProperty,xaxis=xaxis
         
         if obj_valid(xaxis) then begin
           xaxis->setProperty,tickStyle=0,rangeoption=2
           
           if n_elements(range) eq 2 then begin
             xaxis->updateRange,range
           endif
         endif
         
         continue
    endif

    
    for j = 0,n_elements(cols)-1 do begin
    
      if j eq 0 then begin
        self->lock_top,cols[j],range,unlock=unlock
      endif else if j eq n_elements(cols)-1 then begin
        self->lock_bottom,cols[j],range,unlock=unlock
      endif else begin
        self->lock_middle,cols[j],range,unlock=unlock
      endelse
     
    endfor
  
  endfor
      
end

;init, requires draw object, window storage,loaded data object
function spd_ui_lock_axes::init,window_storage,draw_object,loaded_data

  compile_opt idl2

  if ~obj_valid(window_storage) then return,0
  if ~obj_valid(draw_object) then return,0
  if ~obj_valid(loaded_Data) then return,0

  self.window_storage = window_storage
  self.draw_object = draw_object
  self.loaded_data = loaded_data

  return,1

end

pro spd_ui_lock_axes__define

  compile_opt idl2

  struct = { spd_ui_lock_axes,     $
             loaded_data:obj_new(), $ ; the loaded data object
             window_storage:obj_new(), $  ;an array of ptrs to structs
             draw_object:obj_new() }  ; the draw object
      
end
