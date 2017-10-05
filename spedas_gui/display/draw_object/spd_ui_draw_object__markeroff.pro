;+
;
;spd_ui_draw_object method: markerOff
;
;stops drawing the marker
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__markeroff.pro $
;-

pro spd_ui_draw_object::markerOff

  compile_opt idl2,hidden
  
  self.markerOn = 0
  
  if ptr_valid(self.panelInfo) then begin
  
    panels = *self.panelInfo
    
    for i = 0,n_elements(panels)-1 do begin
    
      self->drawMarker,[0,1],panels[i],obj_new(),/remove
      
    endfor
    
  endif
  
;hide marker
  
end
