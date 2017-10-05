;+
;spd_ui_draw_object method: getSpecModel
;
;Purpose:  This procedure finishes the creation of a spectral image.
;          It uses the newly calculated range and the information in plotdata
;
;Inputs: 
;  plotData(struct):  The plotData struct that was returned from getSpecRef, contains plotting information, like scaling, data position and clipping
;  zrange(2 element double):  The z range of the panel, after recalculating for closer autorange fit, if necessary.
;  palette(long): The number of the palette that will be used to draw this spectral plot
;Outputs:
;  model(IDLgrModel):  The model that the result is stored in.
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__getspecmodel.pro $
;-
pro spd_ui_draw_object::getSpecModel,plotData,zrange,palette,model=model

  compile_opt idl2
  
  model = obj_new('IDLgrModel')
  
  pal = obj_new('IDLgrPalette')
  
  getctpath,ctpath
  
  pal->loadct,palette,file=ctpath
 
  pal->getProperty,red_values=rv,green_values=gv,blue_values=bv
  
  ;Turn refvar into a 4xMxN for each color channel
  out = reform(intarr(4,(*plotData).pixx,(*plotdata).pixy),4,(*plotData).pixx,(*plotdata).pixy)
  
  ;Identify values that should be transparent
  if (*plotData).zscale eq 1 ||  (*plotData).zscale eq 2 then begin
  
    idx = where(finite((*plotData).data,/infinity,sign=-1),c)
    
    if c gt 0 then begin
      (*plotData).alpha[idx] = 255
      (*plotData).data[idx] = zrange[0]
    endif
  
  endif
  
  zval = bytscl((*plotData).data,/nan,min=zrange[0],max=zrange[1])
  
  ;store appropriate color channels
  out[0,*,*] = rv[zval]
  out[1,*,*] = gv[zval]
  out[2,*,*] = bv[zval]
  out[3,*,*] = (*plotdata).alpha 

  out = reform(out,4,(*plotData).pixx,(*plotData).pixy)
  
  ;Generate image object
  imageObj = obj_new('IDLgrImage',out,$
    location=[(*plotData).xstart,(*plotData).ystart,(*plotData).zstack],$
    dimensions=[(*plotData).xsize,(*plotData).ysize],$
    depth_test_disable=2,$
    blend_function=[3,4])
  
  ;Map image object onto the surface of a polygon, as a texture map to allow precise control of position
  polygon = obj_new('IDLgrPolygon', $
    [[(*plotData).xstart,(*plotData).ystart,(*plotData).zstack],$
    [(*plotData).xstart+(*plotData).xsize,(*plotData).ystart,(*plotData).zstack],$
    [(*plotData).xstart+(*plotData).xsize,(*plotData).ystart+(*plotData).ysize,(*plotData).zstack],$
    [(*plotData).xstart,(*plotData).ystart+(*plotData).ysize,(*plotData).zstack]], $
    texture_map=imageObj,$
    texture_coord=[[0,0],[1,0],[1,1],[0,1]], $
    ;  texture_coord=[[0,1],[1,1],[1,0],[0,0]], $
    color=self->convertColor([255,255,255]),$
    shading=1,$
    clip_planes=(*plotData).clip,$
    /double ) 
    
  model->add,polygon

end
