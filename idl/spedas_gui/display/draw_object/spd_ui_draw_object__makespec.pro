;+
;
; spd_ui_draw_object method: makeSpec
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
;  xrange: x range of the desired output in data space
;  yrange: y range of the desired output in data space
;
;Output:
;   refz: The gridded z-axis array
;   refx: The x-values associated with the z-values
;   refy: The y-values associated with the z-values
;   
;   Notes:
;   1. This uses an alpha channel to make all NaNs transparent.
;   2. PixX and PixY are not totally necessary because object graphics can
;      stretch an image quite well, but selecting the resolution of the screen
;      with them prevents any inadvertent errors from showing up during interpolation.
;      It might actually be better to render the image at twice the screen resolution
;      to prevent aliasing errors.
;   3. May-2013: Code modified to create a spectrogram over the panel's range 
;                (xrange/yrange) rather than over the data's range. The pixx/pixy
;                variables should now contain the number of pixels across the
;                panel instead of those required to represent the entire dataset.
;   
;   
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__makespec.pro $
;-

pro spd_ui_draw_object::makeSpec,x,y,z,pixx,pixy,$
                                 zAlpha=zAlpha, $
                                 refz=refz,refx=refx,refy=refy, $
                                 xrange=xrange, yrange=yrange

  compile_opt idl2,hidden
  
  ;note, interpolation doesn't handle missing data quite correctly yet
  do_interp = 0
  
;  pal = obj_new('IDLgrPalette')
;  
;  getctpath,ctpath
;  
;  pal->loadct,palette,file=ctpath

  ;double check that data is valid
  idx = where(finite(y),c)
  
  if c eq 0 then begin
    self.statusBar->update,'Error: Unexpected invalid quantity'
    self.historyWin->update,'Error: Unexpected invalid quantity'
    return
  endif

  ;special case 1d Z
  if ndimen(reform(z)) eq 1 then begin
  
    if n_elements(y) eq 1 && n_elements(x) eq 1 then begin
      ;nothin can be done with one-and-ones
      return
    endif else if n_elements(y) eq 1 then begin
    
      ;refy = [0]
      dim = n_elements(z)
      xn = dim
      
      minx = min(x,/nan)
      maxx = max(x,/nan)
      
      xi = (x - x[0])/(x[xn-1]-x[0])
      
      ;create output values for x
      xstart = (xrange[0] - minx) / (maxx - minx)
      xend = (xrange[1] - minx) / (maxx - minx)
      refx = interpol( [xstart,xend], pixx )
;      refx = dindgen(pixx)/pixx
      
      refz = interpol(z,xi,refx) # replicate(1.,pixy)
      
      ;remove interpolated values outside the data's range
      outside = where(refx lt 0d or refx gt 1,cout) 
      if cout gt 0 then refz[outside,*] = !values.f_nan
      
      refy = replicate(y,pixy)
      
    endif else if n_elements(x) eq 1 then begin
    
      ;refy = [0]
      dim = n_elements(z)
      yn = dim
      
      miny = min(y,/nan)
      maxy = max(y,/nan)
      
      ystart = (yrange[0] - miny) / (maxy - miny)
      yend = (yrange[1] - miny) / (maxy - miny)
      refy = interpol( [ystart,yend], pixy )
      
      yi = (y - y[0])/(y[yn-1]-y[0])
      
      ;create output values for y
      ystart = (yrange[0] - miny) / (maxy - miny)
      yend = (yrange[1] - miny) / (maxy - miny)
      refy = interpol( [ystart,yend], pixy )
;      refy = dindgen(pixy)/pixy
      
      refz = replicate(1.,pixx) # interpol(z,yi,refy)
      
      ;remove interpolated values outside the data's range
      outside = where(refy lt 0d or refy gt 1,cout) 
      if cout gt 0 then refz[*,outside] = !values.f_nan
      
      refx = replicate(x,pixx)
    
    endif else begin
      return
    endelse
    
  ;  zout = bytscl(refz,/nan,min=zrange[0],max=zrange[1])
    
    zalpha = bytarr(pixx,pixy)
    
    idx = where(finite(refz),c)
    
    if c ne 0 then begin
      zalpha[idx] = 255
    endif
      
  ;1d y draw code
  endif else if ndimen(y) eq 1 then begin
    y = y[idx]
    z = z[*,idx]
  
    dim = dimen(z)
    
    xn = dim[0]
    yn = dim[1]
    
    alpha = dblarr(dim) + 255
    
    idx = where(~finite(z),c)
    
    if c ne 0 then alpha[idx] = 0
    
    ;sorting should maybe be dumped.
    ;it is really a preprocessing task
    idx = bsort(y)
    
    y = y[idx]
    alpha = alpha[*,idx]
    z = z[*,idx]
    
    idx = bsort(x)
    
    x = x[idx]
    alpha = alpha[idx,*]
    z = z[idx,*]
    
    minx = min(x,/nan)
    maxx = max(x,/nan)
    
    xi = (x - x[0])/(x[xn-1]-x[0])

    ;create output values for x
    xstart = (xrange[0] - minx) / (maxx - minx)
    xend = (xrange[1] - minx) / (maxx - minx)
    xo = interpol( [xstart,xend], pixx )
;    xo = dindgen(pixx)/(pixx-1)
     
    if xn le 1 then begin
      xin_vals = [0,1]
    endif else begin
      xin_vals = dindgen(xn)
    endelse
    
    idx = where(finite(xi),c)
     
    if c eq 0 then begin
      self.statusbar->update,'Warning: No valid x scaling data found.  Using proportional scaling.'
      self.historywin->update,'Warning: No valid x scaling data found.  Using proportional scaling.'
      refx = interpol(xin_vals,pixx)
    endif else begin
      refx = interpol(xin_vals,xi,xo)
    endelse
    
    if ~keyword_set(do_interp) then begin
      xpos = round(refx)
    endif else begin
      xpos = refx
    endelse
    
    ;because nans may be present, cannot use index to find min and max,
    ;despite sort
    miny = min(y,/nan)
    maxy = max(y,/nan)
    
    yi = (y - miny)/(maxy-miny)
    
    ;create output values for y
    ystart = (yrange[0] - miny) / (maxy - miny)
    yend = (yrange[1] - miny) / (maxy - miny)
    yo = interpol( [ystart,yend], pixy )
;    yo = dindgen(pixy)/(pixy-1)
    
    if yn le 1 then begin
      yin_vals = [0,1]
    endif else begin
      yin_vals = dindgen(yn)
    endelse
    
    idx = where(finite(yi),c)
     
    if c eq 0 then begin
      self.statusbar->update,'Warning: No valid y scaling data found. Using proportional scaling.'
      self.historywin->update,'Warning: No valid y scaling data found. Using proportional scaling.'
      refy = interpol(yin_vals,pixy)
    endif else begin
      refy = interpol(yin_vals,yi,yo)
    endelse
  
    if ~keyword_set(do_interp) then begin
      ypos = round(refy)
    endif else begin
      ypos = refy
    endelse
    
    refz = interpolate(z,xpos,ypos,/grid,missing=!VALUES.D_NAN)
  ;  zout = bytscl(refz,/nan,min=zrange[0],max=zrange[1])
    
    zalpha = interpolate(alpha,xpos,ypos,/grid,missing=0)
    
  endif else begin
  ;2d y code

    dim = dimen(z)
    
    minx = min(x,/nan)
    maxx = max(x,/nan)
    
    miny = min(y,/nan)
    maxy = max(y,/nan)
    
    ;normalized inputs
    xi = (temporary(x) - minx)/(maxx - minx)
    yi = (temporary(y) - miny)/(maxy - miny)
    
    ;normalized x output
;    xo = dindgen(pixx)/pixx
    xstart = (xrange[0] - minx) / (maxx - minx)
    xend = (xrange[1] - minx) / (maxx - minx)
    xo = interpol( [xstart,xend], pixx )
     
    ;index-wise scaling value
    refx = interpol(dindgen(dim[0]),temporary(xi),temporary(xo))
    
    ;rounded to prevent smoothing of the data
    if ~keyword_set(do_interp) then begin
      xpos = round(refx)
    endif else begin
      xpos = refx
    endelse  

  ;  xpos = refx
    
    ;now make it 2d
    xpos = xpos # replicate(1.,pixy)
  
    ;normalized y output
;    yo = dindgen(pixy)/pixy
    ystart = (yrange[0] - miny) / (maxy - miny)
    yend = (yrange[1] - miny) / (maxy - miny)
    yo = interpol( [ystart,yend], pixy )
    
    
    ;ensure that nothing is plotted outside the data's range
    ;this should keep the range limits of spectrograms produced
    ;with this code identical those from tplot
    idx = where(yo gt 1 or yo lt 0, c)
    if c gt 0 then begin
      yo[idx] = !values.f_nan
    endif
    
    ;allocate storage for index-wise scaling value
    refy = dblarr(pixx,pixy)
  
    ;now sample y values along x-axis
    ;note that this technique is subject to potential aliasing errors
    ;unless pixx, is twice the width of the plotting error in pixels
    ;this can be controlled by changing the self.specres value
    for i = 0,pixx-1 do begin
      ;calculate the index of this sample
      j = (xpos[i,0] > 0) < (dim[0]-1)
      y_sample = reform(yi[j,*])
      refy[i,*] = interp(dindgen(dim[1]),y_sample,yo) 
    endfor
    
  
    ;use an out of range value for non-in-range values
    ;these should have already been cleared in the case of the x-axis
    idx = where(~finite(refy),c)
    
    if c ne 0 then begin
      refy[idx] = -1
    endif
    
    ;now make sure we have only exact indexes
    if ~keyword_set(do_interp) then begin
      ypos = round(refy)
    endif else begin
      ypos = refy
    endelse      
    
    refz = interpolate(z,xpos,ypos,missing=!VALUES.D_NAN)
   ; zout = bytscl(refz,/nan,min=zrange[0],max=zrange[1])
    zalpha = bytarr(pixx,pixy)
    
    idx = where(finite(refz),c)
    
    if c ne 0 then begin
      zalpha[idx] = 255
    endif
  
  endelse
  
;  pal->getProperty,red_values=rv,green_values=gv,blue_values=bv
;  
; ; catch,err
;  
;  ;here to catch potential memory overallocation
; ; if err then begin
; ;   stop
; ; endif else begin
;  out = intarr(4,pixx,pixy)
; ; endelse
;  ;catch,/cancel
;  
;  out = reform(out,4,pixx,pixy)
;  
;  out[0,*,*] = rv[zout]
;  out[1,*,*] = gv[zout]
;  out[2,*,*] = bv[zout]
;  out[3,*,*] = zalpha
;   
;  ;grid the points and scale them into the range of color indices
;  ;return, floor(interpolate(z,xpos,ypos,/grid))
;  image=out
;  
;  ;IDL will remove any 1 element dimensions on this assignment
;  ;this fixes the problem
;  image = reform(image,4,pixx,pixy)

end
