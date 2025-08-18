;+
;
;spd_ui_draw_object method: setZoom
;
;Set the zoom factor on the current destination object
;Only works if the destination is an IDLgrWindow
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__setzoom.pro $
;-
pro spd_ui_draw_object::setZoom,zoom

  compile_opt idl2,hidden
  
  if obj_isa(self.destination,'IDLgrWindow') then begin
    ;I suspect that there is a bug(feature?) in IDL's recompute_dimensions routine
    ;This is causing the routine to incorrectly recalculate dimensions of some of the
    ;IDLgrText based upon the current hide value of the model in which it resides.
    ;This may also be based upon whether the text has been drawn yet.    
    self->setLegendHide,hide=1
    self->draw
 
    self->setLegendHide,hide=0
    self.destination->setCurrentZoom,zoom
    self->createInstance
    
  ;  if self.legendOn eq 1 then begin
  ;  self->setLegendHide,hide=0
 ;   self->draw
   ; endif
    
    self->setCursor,self.cursorLoc
    
  endif
  
end
