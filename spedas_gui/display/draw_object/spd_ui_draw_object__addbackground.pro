;+
;
;spd_ui_draw_object method: addBackground
;
;Adds the main page background to the target view
;
;view(object reference): IDLgrView to which the background is being added
;color(3 element byte array):  The color of the background.
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__addbackground.pro $
;-
pro spd_ui_draw_object::addBackground,view,color

  compile_opt idl2,hidden
  
  ;the lowest object in the layering
  zstack=0.0
  
  ;a simple polygon.
  grBackground = obj_new('IDLgrPolygon',[0,1,1,0], $
    [0,0,1,1], $
    [zstack,zstack,zstack,zstack],$
    color=self->convertColor(color),$
    /double)
    
  grBModel = obj_new('IDLgrModel')
  
  grBModel->add,grBackground
  
  view->add,grBModel
  
end
