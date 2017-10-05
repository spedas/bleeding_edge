
;+
;NAME:
; spd_ui_scroll_bar__define.pro
;
;PURPOSE:
; Object created for data slider widget. Allows scrolling back
; and forth along the data range when panels are locked.
;
;CALLING SEQUENCE:
; sb = obj_new('SPD_UI_SCROLL_BAR', parentID, xScreenSize, windowStorage, loadedData, drawObject, statusbar, $
;                                   value = 500, range = [0,1000])
;
;ATTRIBUTES:
; id: slider widget's ID
; parent: parent widget's ID
; xsize: screen size, in pixels, of the slider bar
; range: the numerical integer range about which the slider can move, [0,1000] by default
; value: the current value of the slider, zero (fully left) in the absence of data
;
;PUBLIC METHODS:
; getValue: Allows retrieval of value, range, and xsize
; setValue: Allows setting of value and xsize, mainly for the purpose of gui resize events
; update: (Will be called most often) Update procedure to be called any time changes have 
;         been made to the locked status or the locked panel's range.
;
;NOTES:
; Created 7-13-09
; 
; Behavior:
;   No locked panels: Scroll bar should be zeroed and desensitized
;   Locked panels w/o valid data: Scroll bar should be centered and desensitized
;   Locked panel w/ valid data: Scroll bar should be sensitized, position will
;                               depend on the data and panel ranges.
;   
;
;HISTORY:
;
;
;-




;Wrapper to call object's handleEvent method which acts
;as the actual event handler.
;
pro spd_ui_scroll_bar_event, event

    compile_opt idl2, hidden

  widget_control, event.id, get_uvalue = object
  object->handleEvent, event
  widget_control, event.id, set_uvalue = object

end ;------------------------------------------


;Method for getting the current properties of the scroll bar.
;  value: The current value of the slider
;  range: The range of the slider (1000 by default)
;  xsize: The screen size, in pixels, of the slider
;
pro spd_ui_scroll_bar::getProperty, $
                      value = value, $
                      range = range, $
                      xsize = xsize

    compile_opt idl2

  widget_control, self.id, get_value = value

  range = self.range

  geo = widget_info(self.id, /geometry)
  xsize = geo.scr_xsize


end ;------------------------------------------


;Method to directly set the properties of the slider.
;This is mainly for changing the slider size for resize
;events. It probably should not be called elsewhere, instead
;the 'update' method should be used. 
;
pro spd_ui_scroll_bar::setProperty, $
                      value = value, $
                      xsize = xsize

    compile_opt idl2

  if n_elements(value) gt 0 then begin
    if (value ge self.range[0]) and (value le self.range[1]) then begin 
      widget_control, self.id, set_value=value
    endif
  endif

  if keyword_set(xsize) then begin
    widget_control, self.id, scr_xsize=xsize
  endif

end ;------------------------------------------

function spd_ui_scroll_bar::getDataRange,traces,panelinfo

  compile_opt idl2,hidden

  datarange=[!VALUES.d_nan,!VALUES.d_nan]
  
    ;Loop over traces on locked panel to get the total data range 
  for i=0, n_elements(traces)-1 do begin

    traces[i]->getproperty, datax=xname
    
    *self.loadeddata->getvardata, name=xname, data=d
    
    if ptr_valid(d) then begin
      if (panelinfo.xscale eq 0) then begin
        limits = minmax(*d,/nan)
      endif else if (panelinfo.xscale eq 1) then begin
        limits = minmax(alog10(*d),/nan)
      endif else begin
        limits = minmax(alog(*d),/nan)
      endelse
      datarange=minmax([datarange,limits],/nan)
    endif
 
  endfor

  return,datarange

end

;Method that acts as event handler for widget.
;Changes the range of the current display if panels
;are locked.
;
pro spd_ui_scroll_bar::handleEvent, event

    compile_opt idl2, hidden
  
  ;Get locked panel, x-axis, and traces 
  currentwindow = *self.windowstorage->getactive()
  currentwindow->GetProperty, panels=panels, locked=locked
  
  lockedpanel = panels->Get(position=locked)
  panelinfo = *self.drawObject->getPanelInfo(locked)
  
  ;if cannot query panel info then return unchanged.
  if ~is_struct(panelInfo) then begin
    *self.statusBar->update,"Unable to scroll at this time."
    return
  end
  
  lockedpanel->getproperty, tracesettings=tracesettings, xaxis=xaxis
  traces = tracesettings->get(/all)
  
  if is_num(traces) then begin
    *self.statusbar->update, 'Scrollbar: No valid data exists, cannot scroll.'
    return
  endif
  
  datarange=self->getDataRange(traces,panelinfo)

  if ~finite(datarange[0]) || ~finite(datarange[1]) then begin
    *self.statusbar->update, 'Scrollbar: No valid data exists with this scaling option, cannot scroll.'
    widget_control, self.id, set_value = (self.range[1]-self.range[0])/2
    return
  endif
  
  ;Center the slider and return if panel contains entire data range
  if (datarange[0] ge panelinfo.xrange[0]) and (datarange[1] le panelinfo.xrange[1]) then begin
    *self.statusbar->update, 'Scrollbar: Entire data range is already contained within the locked panel'
    widget_control, self.id, set_value = (self.range[1]-self.range[0])/2
    return
  endif
  
  ;logic now just adjusts the bottom bound for x-axis.
  selection_percent = double(event.value)/(self.range[1]-self.range[0])
  new_bottom = selection_percent*((datarange[1]-datarange[0])-(panelinfo.xrange[1]-panelinfo.xrange[0]))+datarange[0]
  new_top = new_bottom+(panelinfo.xrange[1]-panelinfo.xrange[0])
  newprange = [new_bottom,new_top]
  
  if panelinfo.xscale eq 1 then begin
    newprange=10^(newprange)
  endif else if panelinfo.xscale eq 2 then begin
    newprange=exp(newprange)
  endif
 
  ;newprange = [center - bottom, center + top]
  
  ;Set new properties and redraw
  xaxis->setproperty, rangeoption=2
  xaxis->updaterange, newprange    
  
  *self.drawobject->update, *self.windowstorage, *self.loadeddata
  *self.drawobject->draw

end ;------------------------------------------

;Update method to be called any time the panel range
;or locked status might be updated. Adjusts the slider
;and sensitizes the widget.
;
pro spd_ui_scroll_bar::update

    compile_opt idl2, hidden

  ;Get locked panel, x-axis, and traces 
  currentwindow = *self.windowstorage->getactive()
  currentwindow->GetProperty, panels=panels, locked=locked

  ;Desensitize and return if panels are not locked or no data exists
  if locked lt 0 then begin
    widget_control, self.id, sensitive=0, set_value=0
    return
  endif
  
  lockedpanel = panels->Get(position=locked)
  
  ;Desensitize and return of locked panel not valid
  if ~obj_valid(lockedpanel) then begin
    widget_control, self.id, sensitive=0, set_value=0
    return
  endif
  
  panelinfo = *self.drawObject->getPanelInfo(locked)

  ;if cannot query panel info then return unchanged.
  if ~is_struct(panelInfo) then begin
    *self.statusBar->update,"Unable to scroll at this time."
    return
  end

  lockedpanel->getproperty, tracesettings=tracesettings
  traces = tracesettings->get(/all)
  
  ;Center slider but desensitize if panel exits but contains no data
  if is_num(traces) then begin
    widget_control, self.id, set_value=(self.range[1]-self.range[0])/2, $
                             sensitive=0
    return
  endif
  
  datarange=self->getDataRange(traces,panelinfo)
  
  if ~finite(datarange[0]) || ~finite(datarange[1]) then begin
    widget_control, self.id, set_value = (self.range[1]-self.range[0])/2, $
                             sensitive = 0
    return
  endif
 
  ;Center slider and return if panel contains entire data range
  if (datarange[0] ge panelinfo.xrange[0]) and (datarange[1] le panelinfo.xrange[1]) then begin
    widget_control, self.id, set_value = (self.range[1]-self.range[0])/2, $
                    sensitive = 1
    return
  endif
  
  ;Calculate and the new slider position
  drange = (datarange[1] - datarange[0])-(panelinfo.xrange[1]-panelinfo.xrange[0])
  widget_control, self.id, set_value = ((panelinfo.xrange[0]-datarange[0])/drange)*(self.range[1]-self.range[0]) > self.range[0] < self.range[1], $
                           sensitive = 1

end ;------------------------------------------

pro spd_ui_scroll_bar::Cleanup
    ptr_free, self.windowstorage
    ptr_free, self.loadeddata
    ptr_free, self.drawobject
    ptr_free, self.statusbar
end

function spd_ui_scroll_bar::init, $
                          parent, $
                          xsize,   $
                          windowstorage, $
                          loadeddata, $
                          drawobject, $
                          statusbar, $
                          value=value, $
                          range=range

    compile_opt idl2

  m = 'Scroll Bar Object: '
  n = 'Scroll Bar Error: '

  if ~keyword_set(parent) then begin
    ok = error_message(m+'Missing parent widget',/center,title=n)
    return, 0
  endif
  
  if ~keyword_set(xsize) then begin
    ok = error_message(m+'Missing xsize value',/center,title=n)
    return, 0
  endif

  if ~obj_valid(drawobject) then begin
    ok = error_message(m+'Missing draw object reference',/center,title=n)
    return, 0
  endif

  if ~obj_valid(loadeddata) then begin
    ok = error_message(m+'Missing loaded data object reference',/center,title=n)
    return, 0
  endif

  if ~obj_valid(windowstorage) then begin
    ok = error_message(m+'Missing windows object reference',/center,title=n)
    return, 0
  endif

  if ~obj_valid(statusbar) then begin
    ok = error_message(m+'Missing status bar object reference',/center,title=n)
    return, 0
  endif

  if ~keyword_set(range) then range = [0,1000]
  
  if ~keyword_set(value) or (value lt range[0]) or (value gt range[1]) then $
    value = 0


  self.drawobject = ptr_new(drawobject)
  self.loadeddata = ptr_new(loadeddata)
  self.windowstorage = ptr_new(windowstorage)
  self.statusbar = ptr_new(statusbar)

  self.parent = parent
  self.range = range

  self.id = widget_slider(self.parent, $
                          max = self.range[1], $
                          min = self.range[0], $
                          scroll = 0.02*(self.range[1]-self.range[0]), $
                          value = value, $
                          uvalue = self, $
                          xsize = xsize, $
                          event_pro = 'spd_ui_scroll_bar_event', $
                          /suppress_value)

return, 1
end ;------------------------------------------



pro spd_ui_scroll_bar__define

    compile_opt idl2

  struct = {SPD_UI_SCROLL_BAR, $
    parent: 0,                 $ ;parent's widget ID
    id: 0,                     $ ;slider widget's ID
    range: [0,0],              $ ;range of the slider
    windowstorage: ptr_new(),  $ ;pointer to windows object
    loadeddata: ptr_new(),     $ ;pointer to loaded data object
    drawobject: ptr_new(),     $ ;pointer to draw object
    statusbar: ptr_new()       $ ;pointer to status bar object
    }

end
