;+
;
;spd_ui_draw_object method: getPlotSize
;
;calculates the panel size for the purpose of spectral plot generation
;Inputs:
;  plotdim1(2-element double): The position of the panel/plot in x-direction [xstart,xstop]
;  plotdim2(2-element double): The position of the panel/plot in the y-direction [ystart,ystop]
;
;Returns:
;  2-element double
;  xpanel_sz in points(multiple of pixels scaled to dims *not* desktop publishing points) 
;  ypanel_sz in points(multiple of pixels scaled to dims *not* desktop publishing points)
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__getplotsize.pro $
;-
function spd_ui_draw_object::getPlotSize,plotdim1,plotdim2,res_factor

  compile_opt idl2
  
  dim = self->getDim()
  
  dim /= self->getZoom()
  
  if max(dim,sub) gt self.pointmax then begin
    if sub eq 0 then begin
      dim[1] = ceil(self.pointmax*dim[1]/dim[0])
      dim[0] = self.pointmax
    endif else begin
      dim[0] = ceil(self.pointmax*dim[0]/dim[1])
      dim[1] = self.pointmax
    endelse
  endif
  
  xpt = dim[0] * res_factor
  ypt = dim[1] * res_factor
  
  ;size of the panel in points
  xpanel_sz_pt = double(ceil(xpt * (plotdim1[1]-plotdim1[0])))
  ypanel_sz_pt = double(ceil(ypt * (plotdim2[1]-plotdim2[0])))
  
  return,[xpanel_sz_pt,ypanel_sz_pt]
  
end
