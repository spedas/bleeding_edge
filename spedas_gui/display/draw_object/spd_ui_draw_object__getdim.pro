;+
;
;spd_ui_draw_object method: getDim
;
;gets dimensions in pixels,
;abstracts some unit fuss
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__getdim.pro $
;-
function spd_ui_draw_object::getDim

  compile_opt idl2,hidden
  
  self.destination->getProperty,units=un
  self.destination->setProperty,units=0
  self.destination->getProperty,dimensions=dim
  self.destination->setProperty,units=un
  
  return,float(dim)
  
end
