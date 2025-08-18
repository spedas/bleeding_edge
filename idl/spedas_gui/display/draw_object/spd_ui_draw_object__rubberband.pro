;+
;
;spd_ui_draw_object method: rubberBand
;
;for making a rubber band.  This thing actually manipulates the
;draw tree to move the rubber band around according to the current cursor position
;location is the location in draw-area normalized coordinates [x,y]
;dimensions is the dimensions in draw-area normalized coordinates [xsize,ysize]
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__rubberband.pro $
;-
function spd_ui_draw_object::rubberBand,location,dimensions,hide=hide

  compile_opt idl2,hidden
  
  ;default stacking height
  zstack=.7
  
  ;If no rubber band view exists, create one
  if ~obj_valid(self.rubberview) then begin
  
    rubberview = obj_new('IDLgrView')
    self.rubberview = rubberview
    rubberview->setProperty,units=3,viewplane_rect=[0.,0.,1.,1.],location=[0.,0.],dimensions=[1.,1.],zclip=[1.,-1.],eye=5,name="rubberview",/transparent,/double
    self.scene->add,rubberview
    
  endif
  
  ;remove all models from old view
  old = self.rubberview->get(/all)
  if obj_valid(old) then obj_destroy,old
  self.rubberview->remove,/all
  
  model = obj_new('IDLgrModel')
  
  self.rubberview->add,model
  
  ;create a new polyline at the requested location and add it to the model
  xlocs = [location[0],location[0]+dimensions[0],location[0]+dimensions[0],location[0],location[0]] > 0. < 1.
  ylocs = [location[1],location[1],location[1]+dimensions[1],location[1]+dimensions[1],location[1]] > 0. < 1.
  zlocs = replicate(zstack,5)
  
  rubberband = obj_new('IDLgrPolyline',xlocs,ylocs,zlocs,hide=hide,/double)
  
  model->add,rubberband
  
  return,1
  
end
