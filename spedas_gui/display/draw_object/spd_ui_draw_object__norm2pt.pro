;+
;
;spd_ui_draw_object method: norm2pt
;
;converts back from the normalized value into points,
;While the normalized value is dependent on screen dimensions
;zoom, & resolution.  The value in points should be an
;absolute quantity
;
;Inputs:
;  Value(numeric or array of numerics):  A value in screen normal coords
;  xy(boolean) 0 : convert from x-axis, 1:convert from y-axis(because screen dims differ, axis must be specified)
;
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2014-05-14 11:58:59 -0700 (Wed, 14 May 2014) $
;$LastChangedRevision: 15133 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__norm2pt.pro $
;-
function spd_ui_draw_object::norm2pt,value,xy

  compile_opt idl2,hidden
  
  pt2mm = 127D/360D
  mm2cm = .1D
  in2cm = 2.54
  
  dim = self->getDim()
  
  ;Replacing with alternate conversion.  Normalizes based on notional canvas size.
  ;Should get rid of zoom dependence and hopefully make our placements more rational
;  self.destination->getProperty,resolution=r
;  
;  dim /= self->getZoom()
;  
;  v = value*r[xy]*dim[xy]

  v= value*self.currentpagesize[xy]*in2cm
  
  return,v/(pt2mm*mm2cm)
  
end
