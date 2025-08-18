;+
;
;spd_ui_draw_object method: getZoom
;
;This routine returns the current zoom of the destination object
; Used primarily for determining scaling values to be applied to
; text when drawn.  IDL doesn't properly correct for zoom, unless
; an object is already rendered.  If you initially draw while at
; non 1. zoom text will be mis-sized unless scaled by zoom factor.
;
; Doesn't really apply to non-IDLgrWindow, because they don't
; have associated zoom factors.
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__getzoom.pro $
;-
function spd_ui_draw_object::getZoom

  compile_opt idl2,hidden
  
  if obj_isa(self.destination,'IDLgrWindow') then begin
    self.destination->getProperty,current_zoom=cz
  endif else begin
    cz = 1D
  endelse
  
  return, cz
  
end
