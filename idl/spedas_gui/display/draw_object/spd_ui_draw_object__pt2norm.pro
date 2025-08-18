;+
;
;spd_ui_draw_object method: pt2norm
;
;
;Convert pts into draw area normal coordinates.
;Inputs:
;  Value(numeric type, or array of numeric types): the point value(s) to be converted
;  xy(boolean):  0: convert for x-axis, 1 convert for y-axis.(because screen dims differ, axis must be specified)
;  
;Returns, the value in normalized coordinates
;
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2014-05-14 11:58:59 -0700 (Wed, 14 May 2014) $
;$LastChangedRevision: 15133 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__pt2norm.pro $
;-

function spd_ui_draw_object::pt2norm,value,xy

  compile_opt idl2,hidden
  
  pt2mm = 127D/360D
  mm2cm = .1D
  in2cm = 2.54
  
  v = value*pt2mm*mm2cm
  
  dim = self->getDim()
  
  ;Replacing with alternate conversion.  Normalizes based on notional canvas size.  
  ;Assumes we got it right.  Should get rid of zoom dependence and hopefully make our placements more rational
  ;self.destination->getProperty,resolution=r
  
  ;dim /= self->getZoom()

  ;return,v/(r[xy]*dim[xy])

  canvas_cm = self.currentpagesize[xy]*in2cm
 
  return,v/canvas_cm 
  

end
