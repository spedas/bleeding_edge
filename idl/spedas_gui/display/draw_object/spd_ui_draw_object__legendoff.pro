;+
;
;spd_ui_draw_object method: legendOff
;
;
;Stop drawing the legend
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__legendoff.pro $
;-
pro spd_ui_draw_object::legendOff

  compile_opt idl2,hidden
  
  self.legendOn = 0
  
  self->setCursor,self.cursorLoc 
  
 ; self->createInstance
  
  self->draw
  
end
