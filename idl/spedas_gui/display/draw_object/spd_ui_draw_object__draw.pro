;+
;
;spd_ui_draw_object method: draw
;
;This routine actually draws the display, it should be called after
;any update to this function via another call.  It should also be
;called any time that there is damage to the window from opening a
;panel or after an expose_event
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__draw.pro $
;-
pro spd_ui_draw_object::draw,_extra=ex

  compile_opt idl2,hidden
  
  if ~obj_isa(self.destination,'IDLgrWindow') then begin
    self.destination->draw,self.scene,_extra=ex
  endif else begin
    self.destination->draw,self.scene,/draw_instance,_extra=ex
  endelse
  
end
