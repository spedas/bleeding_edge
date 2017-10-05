;+
;
; Function: spd_ui_make_spec
;
; NOTE: This code has been incorporated into the draw object.  
; spd_ui_make_spec is no longer called directly
;
;Purpose:
;  helper routine for draw object.  It helps construct the image for spectrograms
;  very quickly.
;
;Inputs:
;  x: the 1-d x scaling values for the z components(x-axis)
;  y: the 1-d y scaling values for the z components
;  z: the 2-d z array of values for the image
;  pixx: the desired resolution of the output on the x-axis
;  pixy: the desired resolution of the output on the y-axis
;  palette: the palette number to be used when creating the image
;  zrange: the zrange for the whole panel(may be larger than the range of the z argument)
;
;Output:
;   An rgba image with dimensions: 4 x PixX x PixY
;   
;   Notes:
;   1. This uses an alpha channel to make all NaNs transparent.
;   2. PixX and PixY are not totally necessary because object graphics can
;      stretch an image quite well, but selecting the resolution of the screen
;      with them prevents any inadvertent errors from showing up during interpolation.
;      It might actually be better to render the image at twice the screen resolution
;      to prevent aliasing errors.
;   
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/spd_ui_make_spec.pro $
;-

pro spd_ui_make_spec,x,y,z,pixx,pixy,palette,zrange,image=image,refz=refz,refx=refx,refy=refy

  compile_opt hidden,idl2
  
  pal = obj_new('IDLgrPalette')
  
  getctpath,ctpath
  
  pal->loadct,palette,file=ctpath

  idx = where(finite(y),c)
  
  if c eq 0 then begin
    self.statusBar->update,'Error: Unexpected invalid quantity'
    self.historyWin->update,'Error: Unexpected invalid quantity'
  endif
  
  if ndimen(y) eq 1 then begin
    y = y[idx]
    z = z[*,idx]
  endif


  dim = dimen(z)
  
  xn = dim[0]
  yn = dim[1]
  
  alpha = dblarr(dim) + 255
  
  idx = where(~finite(z),c)
  
  if c ne 0 then alpha[idx] = 0
  
  idx = bsort(y)
  
  y = y[idx]
  alpha = alpha[*,idx]
  z = z[*,idx]
  
  idx = bsort(x)
  
  x = x[idx]
  alpha = alpha[idx,*]
  z = z[idx,*]
  
  xi = (x - x[0])/(x[xn-1]-x[0]) 
  xo = dindgen(pixx)/pixx
   
  refx = interpol(dindgen(xn),xi,xo)
  xpos = round(refx)
  
  ;because nans may be present, cannot use index to find min and max,
  ;despite sort
  miny = min(y,/nan)
  maxy = max(y,/nan)
  
  yi = (y - miny)/(maxy-miny)
  yo = dindgen(pixy)/pixy

  refy = interpol(dindgen(yn),yi,yo)
  ypos = round(refy)
  
  refz = interpolate(z,xpos,ypos,/grid,missing=!VALUES.D_NAN)
  zout = bytscl(refz,/nan,min=zrange[0],max=zrange[1])
  
  zalpha = interpolate(alpha,xpos,ypos,/grid,missing=0)
  
  pal->getProperty,red_values=rv,green_values=gv,blue_values=bv
  
 ; catch,err
  
  ;here to catch potential memory overallocation
 ; if err then begin
 ;   stop
 ; endif else begin
  out = intarr(4,pixx,pixy)
 ; endelse
  ;catch,/cancel
  
  out = reform(out,4,pixx,pixy)
  
  out[0,*,*] = rv[zout]
  out[1,*,*] = gv[zout]
  out[2,*,*] = bv[zout]
  out[3,*,*] = zalpha
   
  ;grid the points and scale them into the range of color indices
  ;return, floor(interpolate(z,xpos,ypos,/grid))
  image=out
  
  ;IDL will remove any 1 element dimensions on this assignment
  ;this fixes the problem
  image = reform(image,4,pixx,pixy)

end
