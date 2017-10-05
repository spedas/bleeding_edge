
;+
;NAME:
; thm_ui_slice2d_bar__define.pro
;
;PURPOSE:
; Object created for the 2d slices interface. Allows scrolling back
; and forth over a temporal series of slices.
;
;CALLING SEQUENCE:
; sb = obj_new('THM_UI_SLICE2D_BAR', parentID, xScreenSize, (windowStorage, loadedData, drawObject,) $
;                                   statusbar=statusbar, value = 500, range = [0,1000])
;
;ATTRIBUTES:
; id: slider widget's ID
; parent: parent widget's ID
; xsize: screen size, in pixels, of the slider bar
; range: the numerical integer range about which the slider can move (in sec), [0,1000] by default
; value: the current value of the slider, zero (fully left) in the absence of data
; ok:  flag indicating whether the slider should be sensitized
;
;PUBLIC METHODS:
; getValue: Allows retrieval of value, range, and xsize
; setValue: Allows setting of value and xsize, mainly for the purpose of gui resize events
; update: Update procedure to be called when:
;             -new plots have been generated (after setValue)
;             -there was an error (after setValue)
;             -events are processed (w/ EVENT keyword)
;
;NOTES:
; 
;
;HISTORY:
; Initial version: 4-02-10
; Added title 3-5-12
;
;-




;Wrapper to call object's "handleEvent" method which acts
;as the actual event handler.
;
pro thm_ui_slice2d_bar_event, event

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
pro thm_ui_slice2d_bar::getProperty, $
                      value = value, $
                      range = range, $
                      xsize = xsize

    compile_opt idl2, hidden

  widget_control, self.id, get_value = value
  range = self.range
  xsize = self.xsize


end ;------------------------------------------


;Method to directly set the properties of the slider.
;See Update method as well.
;
pro thm_ui_slice2d_bar::setProperty, $
                      value = value, $
                      xsize = xsize, $
                      range = range, $
                      ok = ok

    compile_opt idl2, hidden

  if keyword_set(xsize) then begin
    widget_control, self.id, xsize=xsize
  endif

  if keyword_set(range) and n_elements(range) eq 2 then begin
    ;setting a zero range will fail on mac/linux 
    ; (slider isn't needed for single slice in any case)
    if range[0] eq range[1] then begin
      self.ok = 0b
      self.single = 1b
      return
    endif else begin
      self.single = 0b
    endelse
    widget_control, self.id, set_slider_min=range[0], set_slider_max=range[1]
    self.range = range
  endif

  if n_elements(value) gt 0 then begin
    if (value ge self.range[0]) and (value le self.range[1]) then begin 
      widget_control, self.id, set_value=value
    endif
  endif
 
  if keyword_set(ok) then self.ok = ok
end ;------------------------------------------


;Method that acts as event handler for widget.
;
pro thm_ui_slice2d_bar::handleEvent, event

    compile_opt idl2, hidden

  self->updateTitle

end ;------------------------------------------


;Method to update title with # of plots.
;
pro  thm_ui_slice2d_bar::updateTitle

    compile_opt idl2, hidden

  ;if sensitized, check if only 1 plot
  if ~self.ok then begin
    if self.single then begin
      widget_control, self.title, set_value = 'Plot 1 of 1.'
    endif else begin
      widget_control, self.title, set_value = 'No slices loaded.'
    endelse
  ;otherwise, list number of plots
  endif else begin
    widget_control, self.id, get_value = value
    widget_control, self.title, set_value = $
        'Plot '+strtrim(value+1,2)+' of '+strtrim(self.range[1]+1,2)+'.'
  endelse

end ;------------------------------------------


;Update method to be called after new slices are generated
;
pro thm_ui_slice2d_bar::update, event=event

    compile_opt idl2, hidden

  
  ;Zero slider and desensitize
  if ~self.ok then begin
    widget_control, self.id, set_value = self.range[0], sensitive = 0
    self->updateTitle
    return
  endif
  
  ;Zero slider if not from event and return 
  if self.ok then begin
    if ~keyword_set(event) then begin
      widget_control, self.id, set_value = self.range[0], sensitive = 1
    endif
    self->updateTitle
    return
  endif


end ;------------------------------------------


function thm_ui_slice2d_bar::init, $
                          parent, $
                          xsize,   $
                          statusbar=statusbar, $
                          value=value, $
                          range=range, $
                          ok=ok

    compile_opt idl2

  m = 'Scroll Bar Object: '
  n = 'Scroll Bar Error: '

  if ~keyword_set(parent) then begin
    dummy = error_message(m+'Missing parent widget',/center,title=n)
    return, 0
  endif
  
  if ~keyword_set(xsize) then begin
    dummy = error_message(m+'Missing xsize value',/center,title=n)
    return, 0
  endif

  if ~keyword_set(range) then range = [0,1000]
  
  if ~keyword_set(value) then value = 0
  
  if (value lt range[0]) or (value gt range[1]) then value = range[0]

  if obj_valid(statusbar) then self.statusbar = ptr_new(statusbar)
  
  if ~keyword_set(ok) then ok = 0b

  self.parent = parent
  self.range = range
  self.xsize = xsize
  self.single = 0b
  self.ok = ok

  self.title = widget_label(self.parent, value='No slices loaded.');, xsize=self.xsize);trying without specifying size as label and slider size don't seem to match

  self.id = widget_slider(self.parent, $
                          max = self.range[1], $
                          min = self.range[0], $
                          scroll = 1, $
                          value = value, $
                          uvalue = 'SLIDERBAR', $
                          xsize = self.xsize, $
;                          event_pro = 'thm_ui_slice2d_bar_event', $
                          /suppress_value)

return, 1
end ;------------------------------------------



pro thm_ui_slice2d_bar__define

    compile_opt idl2

  struct = {THM_UI_SLICE2D_BAR, $
    parent: 0,                 $ ;parent's widget ID
    id: 0,                     $ ;slider widget's ID
    xsize: 0,                  $ ;screen size, in pixels, of the slider
    range: [0,0],              $ ;range of the slider
    statusbar: ptr_new(),      $ ;pointer to status bar object
    title: 0,                  $ ;id of title widget
    single: 0b,                $ ;internal flag indicating if single plot exists,
                                 ;helps update title on linux where range cannot = 0
    ok: 0b                     $ ;flag indicating where bar should be usable
    }

end