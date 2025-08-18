;+
;
;spd_ui_draw_object method: markerOn
;
;
;starts drawing a new marker at the current location
;'default' is a marker object from which the marker defaults will be copied
;'all' indicates that markers should be drawn on all panels
;note that markerOn can fail if the current location isn't within the
;boundaries of a panel.  The 'fail' keyword indicates this
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__markeron.pro $
;-

pro spd_ui_draw_object::markerOn,default=default,all=all,fail=fail

  compile_opt idl2,hidden
  
  fail = 1
  
  self.markerStart = self.cursorLoc
  
  if ~ptr_valid(self.panelInfo) then return
  
  panels = *self.panelInfo
  
  inBounds = 0
  
  ;only activate if the start location is in bounds of the panel
  for i = 0,n_elements(panels)-1 do begin
  
    if self->inBounds(panels[i]) then begin
      inbounds = 1
      panel = i
    endif
    
  endfor
  
  if ~inBounds then return
  
  if ~keyword_set(all) then begin
    self.markerOn = 1
    
    ;create the new marker, if no default settings are specified, uses spd_ui_marker
    
    if ~keyword_set(default) || ~obj_valid(default) then begin
      marker = [obj_new('spd_ui_marker')]
    endif else begin
      marker = [default->copy()]
    endelse
    
    panelIdx = [panel]
  endif else begin
  
    self.markerOn = 2
    marker = objarr(n_elements(*self.panelInfo))
    
    panelIdx = indgen(n_elements(*self.panelInfo))
    
    ;create new markers for each panel, if no default settings are specified, uses spd_ui_marker for determining defaults
    for i = 0,n_elements(marker)-1 do begin
      if ~keyword_set(default) || ~obj_valid(default) then begin
        marker[i] = obj_new('spd_ui_marker')
      endif else begin
        marker[i] = default->copy()
      endelse
    endfor
    
  endelse
  
  ;destroy old markers
  if ptr_valid(self.currentMarkers) then begin
    obj_destroy,*self.currentMarkers
    ptr_free,self.currentMarkers
    ptr_free,self.markerIdx
  endif
  
  ;replace with new values
  self.currentMarkers = ptr_new(marker)
  self.markerIdx = ptr_new(panelIdx)
  
  fail = 0
  
end
