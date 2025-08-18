;+
;
; spd_ui_draw_object method: aggregateSpecplots
;
;A special kluge function to get around an IDL bug, that causes improper layering in eps
;Generates a composite image from a series of spectral plots to preserve layering when exporting to eps
;
;Inputs: 
;  spec_list(Object Ref): an IDL_Container with each spec_plot model
;  panel_sz_pt(2 element numerical):  The number of points to be used for the x and y dimensions of the output, respectively
;  bg_color(3 element byte array):  The background color for the panel, used to properly simulate transparency
;  
;Outputs:
;  aggregated model
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__aggregatespecplots.pro $
;-

function spd_ui_draw_object::aggregateSpecplots,spec_list,panel_sz_pt,bg_color

  compile_opt idl2,hidden
  
  zstack = .05
  
  ;clip planes will cut off the image at borders
  cp = double([[-1,0,0,0],[1,0,0,-1],[0,-1,0,0],[0,1,0,-1]])
  
  ;create a dummy view
  view = obj_new('IDLgrView',units=3, $
    VIEWPLANE_RECT=[0.,0.,1.,1.], $
    zclip=[1,-1], eye=5.,color=bg_color,$
    /double)
    
  model_list = spec_list->get(/all)
  
  ;add specplot models to the view 
  for i = 0,n_elements(model_list)-1 do begin
  
    view->add,model_list[i]
    
  endfor

  ;create a buffer and draw models on the view  
  buffer = obj_new('IDLgrBuffer',dimensions=panel_sz_pt)
  
  buffer->draw,view
  
  ;get the image data from the buffer after draw
  buffer->getProperty,image_data=image_data
  
  ;create a new composite image, using the output
  image = obj_new('IDLgrImage',image_data,depth_test_disable=2,clip_planes=cp,location=[0.,0.,zstack],dimensions=[1.,1.])
  
  model = obj_new('IDLgrModel')
  
  model->add,image
  
  return,model
end
