;+
;
;spd_ui_draw_object method: hBarOff
;
;stop drawing the horizontal bar
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__hbaroff.pro $
;-

pro spd_ui_draw_object::hBarOff

  compile_opt idl2,hidden
  
  self.hBarOn = 0
  
  ;hide vbar
  
  if ptr_valid(self.panelInfo) then begin
  
    for i = 0,n_elements(*self.panelInfo)-1 do begin
    
    
      hBar = ((*self.panelInfo)[i]).hBar
      old = hBar->get(/all)
      if obj_valid(old) then obj_destroy,old
      hBar->remove,/all
      
    endfor
    
  endif
  
  self->draw
  
end
