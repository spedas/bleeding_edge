;+
;
;spd_ui_draw_object method: createInstance
;
;This routine creates an instance of the static components
;of any display, it also leaves only the dynamic components
;unhidden after it is complete, so the draw object is ready 
;for instance based drawing
;
;See IDL Help documentation on instances.  The short explanantion
;is that instances are used in object graphics to make draws,
;much much faster.
; 
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__createinstance.pro $
;-

pro spd_ui_draw_object::createInstance

  compile_opt idl2,hidden
  
  ;instancing should only be done on window objects,
  ;but since this method is called at the end of updates,
  ;we need to be certain we don't try to instance a printer or postscript
  if obj_isa(self.destination,'IDLgrWindow') then begin
 ; if 0 then begin
  
    ;hide only the dynamic components of the image
    self->setModelHide,self.staticViews,0
    self->setModelHide,self.dynamicViews,1
    self->setLegendHide
    
    self.destination->draw,self.scene,create_instance=1
    
    ;hide only the static components of the image
    self->setModelHide,self.dynamicViews,0
    self->setModelHide,self.staticViews,1
    self->setLegendHide,/dynamic
 
    self->setCursor,self.cursorLoc
    
   ; self->draw
  
  endif
  
end
