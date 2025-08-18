;+
;spd_ui_draw_object method: getSpecRef
;
;Generates a gridded and fully clipped spectragram during the update function.
;The output from this is used to generate the model for display and used directly
;as a reference for the legend
;
;Inputs:
;  xrange(2 element double):  The range([min,max]) of the panel on the x-axis.
;  yrange(2 element double):  The range([min,max]) of the panel on the y-axis.
;  xpanel_sz_pt(long):  The size of the panel in the x-direction.  Units are a multiple/fraction of screen pixels. 
;  ypanel_sz_pt(long):  The size of the panel in the y-direction.  Units are a multiple/fraction of screen pixels.
;  xscale(long):  x axis scaling mode. 0(linear),1(log10),2(logN)
;  yscale(long):  y axis scaling mode. 0(linear),1(log10),2(logN)
;  zscale(long):  z axis scaling mode. 0(linear),1(log10),2(logN)
;  dx(ptr to array): x data for this spectral plot
;  dy(ptr to array): y data for this spectral plot
;  dz(ptr to array): z data for this spectral plot
;Outputs:
;  refVar(double array):  Array containing final clipped, gridded data
;  plotData(struct) : structure containing information about range,position,scaling, and clipping of resulting quantity, for use with getSpecModel
;
;NOTES:
;  1. xrange,yrange may be different from the range of the data because not all spectragrams span the entire panel, and some span more than the entire panel.
;  2. xpanel_sz_pt,ypanel_sz_pt will be increased due to aliasing correction factor, but decreased because panel spans only a portion of the screen
;  3. May-2013: makeSpec now produces a spectrogram corresponding to the panel itself instead
;               of the input data; this code has been modified to accomodate that change.
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__getspecref.pro $
;-

pro spd_ui_draw_object::getSpecRef,xrange,yrange,xpanel_sz_pt,ypanel_sz_pt,xscale,yscale,zscale,dx,dy,dz,refvar=refvar,plotData=plotData

  compile_opt idl2
  
  ; a = systime(/seconds)
  
  polygon = obj_new()
  
  zstack = .05
 
  ;extract the data 
  x = (*dx)
  y = (*dy)
  z = (*dz)
  
  ;calculate data min/max
  xs = min(x,/nan)
  xe = max(x,/nan)
  ys = min(y,/nan)
  ye = max(y,/nan)
  
  if keyword_set(refVar) then begin
    tmp = temporary(refVar)
  endif
  
  ;0 width range gets special treatment
  if xs eq xe then begin

    ;if the quantity takes up the entire range, then we're in business
    if xrange[0] eq xrange[1] then begin
      xstart = 0
      xsize = 1
    endif else begin
    ;if not, there is no way to figure out how to scale the quantity proportionally
      self.historyWin->update,'Cannot determine how to x-scale zero x-width spectrogram, with non-zero width x-range. Try using auto-range.'
      self.statusBar->update,'Cannot determine how to x-scale zero x-width spectrogram, with non-zero width x-range. Try using auto-range.'
      return
    endelse
  
  endif else begin
  
    ;size of the spectral data relative to the visible range
    xstart = (xs - xrange[0])/(xrange[1]-xrange[0]) > 0
  
    ;xsize should remain < 1 as the spectrogram will not be drawn past
    ;the bounds of the panel
    xsize = (xe-xs)/(xrange[1]-xrange[0]) < 1
 
  endelse
  
  ;0 width range gets special treatment
  if ys eq ye then begin
  
    ;if the quantity takes up the entire range, then we're in business
    if yrange[0] eq yrange[1] then begin
      ystart = 0
      ysize = 1
    endif else begin
      self.historyWin->update,'Cannot determine how to y-scale zero y-width(single channel) spectrogram with non-zero width y-range. Try using auto-range.'
      self.statusBar->update,'Cannot determine how to y-scale zero y-width(single channel) spectrogram with non-zero width y-range. Try using auto-range.'
    ;if not, there is no way to figure out how to scale the quantity proportionally
      return
    endelse
  
  endif else begin
  
    ;panel normal z-starting position
    ystart = (ys - yrange[0])/(yrange[1]-yrange[0]) > 0
    
    ;ysize should remain < 1 as the spectrogram will not be drawn past
    ;the bounds of the panel
    ysize = (ye-ys)/(yrange[1]-yrange[0]) < 1
  
  endelse
  
  ;scale by spectral plot size
  xdata_sz_pt = ceil(xsize*xpanel_sz_pt,/l64)
  ydata_sz_pt = ceil(ysize*ypanel_sz_pt,/l64)
  
  ;less than 1 pixel means no plot.
  if xdata_sz_pt le 0 || ydata_sz_pt le 0 then begin
    return
  endif
  
  ;Note that is the long run, this limitation can probably be avoided by adding an algorithm to manually resample the image
  ;May-2013: This check should probably be removed or modified due to change in makeSpec behavior
  if xdata_sz_pt * ydata_sz_pt gt 2e7 then begin
  
    self.statusBar->update,'Error: Cannot generate spectrogram. The range may be too small.'
    return
    
  endif
  
  ;clip planes will cut off the image at borders
  cp = double([[-1,0,0,0],[1,0,0,-1],[0,-1,0,0],[0,1,0,-1]])
  
  refvar = dblarr(xpanel_sz_pt,ypanel_sz_pt)
  refvar[*] = !VALUES.D_NAN
  
  ;if very small scaling factors are used,
  ;refvar will sometimes lose a dimension
  if size(refvar,/n_dim) eq 1 then begin
    refvar = reform(refvar,1,1)
  endif
  
  ;This routine contains the more general gridding algorithm, now that parameters have been determined definitively
  self->makeSpec,x,y,z,xpanel_sz_pt,ypanel_sz_pt,zAlpha=zAlpha,refz=refz, $
                 xrange=xrange, yrange=yrange
  

  plotData = { $
    data:refz,$
    alpha:zAlpha,$
    xstart:0d,$
    ystart:0d,$
    xsize:1d,$
    ysize:1d,$
    zstack:zstack, $
    zscale:zscale,$
    pixx:xpanel_sz_pt,$
    pixy:ypanel_sz_pt,$
    clip:cp $
    }
  
  refvar = refz

  return


;  May-2013:  The clipping below should be unnecessary now that makeSpec creates
;             images corresponding to the panel itself.
;
;
;
;  plotData = { $
;    data:refz,$
;    alpha:zAlpha,$
;    xstart:xstart,$
;    ystart:ystart,$
;    xsize:xsize,$
;    ysize:ysize,$
;    zstack:zstack, $
;    zscale:zscale,$
;    pixx:xdata_sz_pt,$
;    pixy:ydata_sz_pt,$
;    clip:cp $
;    }
;    
;  ;This block performs necessary clipping, and fits the image into refvar
;  
;  ;determine indices of data in reference variable that
;  ;represents the entire panel
;  xStartIdx = floor(xstart*(size(refvar,/dimen))[0])
;  xStopIdx = xStartIdx+xdata_sz_pt-1
;  
;  if xStopIdx lt 0 || xStartIdx ge xpanel_sz_pt then return
;  
;  ;clip left
;  if xStartIdx lt 0 then begin
;    refz = refz[abs(xStartIdx):*,*]
;    xStartIdx = 0
;  endif
;  
;  ;clip right
;  if xStopIdx ge xpanel_sz_pt then begin
;    refz = refz[0:xpanel_sz_pt-xStartIdx-1,*]
;    xStopIdx = xpanel_sz_pt-1
;  endif
;  
;  yStartIdx = floor(ystart*(size(refvar,/dimen))[1])
;  yStopIdx = yStartIdx+ydata_sz_pt-1
;  
;  if yStopIdx lt 0 || yStartIdx ge ypanel_sz_pt then return
;  
;  ;clip bottom
;  if yStartIdx lt 0 then begin
;    refz = refz[*,abs(yStartIdx):*]
;    yStartIdx = 0
;  endif
;  
;  ;clip top
;  if yStopIdx ge ypanel_sz_pt then begin
;    refz = refz[*,0:ypanel_sz_pt-yStartIdx-1]
;    yStopIdx = ypanel_sz_pt-1
;  endif
;  
;  ;stick clipped data into panel sized reference var
;  refvar[xStartIdx:xStopIdx,yStartIdx:yStopIdx] = refz
  
  
  
;  model = obj_new('IDLgrModel')
  
  ; if ~keyword_set(self.postscript) then begin
  ;if 1 then begin
  
  ;using a plain image doesn't layer correctly in postscript, consider generating layer code so that this option can replace polygon method
  ; imageObj = obj_new('IDLgrImage',image,location=[xstart,ystart,zstack],dimensions=[xsize,ysize],depth_test_disable=2,blend_function=[3,4])
 ; imageObj = obj_new('IDLgrImage',image)
  
;  polygon = obj_new('IDLgrPolygon', $
;    [[xstart,ystart,zstack],[xstart+xsize,ystart,zstack],[xstart+xsize,ystart+ysize,zstack],[xstart,ystart+ysize,zstack]], $
;    texture_map=imageObj,$
;    texture_coord=[[0,0],[1,0],[1,1],[0,1]], $
;    ;  texture_coord=[[0,1],[1,1],[1,0],[0,0]], $
;    color=self->convertColor([255,255,255]),$
;    shading=1,$
;    clip_planes=cp ) ;,$
;linestyle=6)
    
;endif else begin
    
;NOTE this code below has been worked around, by kludging layering issues during postscript output
;generate polygon vertices for every pixel.
;This is needed for postscript output
;
;
    
;The system I'm using is a polygon mesh, a regular arrangement of 4-gons
;The IDL documentation indicates that this is an optimized polygon
;arrangement and thus should be quicker.
;That said, we should consider generating complex n-gons for each
;contiguous colo region in future versions
    
;1d
;    x_verts = xstart + xsize* (dindgen(xdata_sz_pt+1)/xdata_sz_pt)
;
;    ;X 2d
;    x_verts = reform(rebin(x_verts,xdata_sz_pt+1,ydata_sz_pt+1),(xdata_sz_pt+1)*(ydata_sz_pt+1))
;
;    ;1d
;    y_verts = ystart + ysize*(dindgen(ydata_sz_pt+1)/ydata_sz_pt)
;
;    ;Y 2d
;    y_verts = reform(transpose(rebin(y_verts,ydata_sz_pt+1,xdata_sz_pt+1)),(xdata_sz_pt+1)*(ydata_sz_pt+1))
;
;    ;Z 2d
;    z_verts = replicate(zstack,(xdata_sz_pt+1)*(ydata_sz_pt+1))
;
;    ;generate vertex permutations to define the polygons
;
;    ;vertex number per polygon
;    v_num = lonarr(xdata_sz_pt*ydata_sz_pt)+4 ;all polygons use 4 vertices
;
;    offset = lindgen(xdata_sz_pt*ydata_sz_pt)/xdata_sz_pt
;
;    ;the permutation for each vertex of each polygon
;    ;first vertex of each polygon
;    v1 = lindgen(xdata_sz_pt*ydata_sz_pt) + offset
;    ;second vertex of each polygon
;    v2 = lindgen(xdata_sz_pt*ydata_sz_pt) + 1 + offset
;    ;third vertex of each polygon
;    v3 = lindgen(xdata_sz_pt*ydata_sz_pt) + xdata_sz_pt + 1 + offset
;    ;fourth vertex of each polygon
;    v4 = lindgen(xdata_sz_pt*ydata_sz_pt) + xdata_sz_pt + 2 + offset
;
;    v_perm = transpose([[v_num],[v1],[v2],[v4],[v3]])
;
;    ;generate vertex colors of polygons
;
;    v_r_colors = bytarr((xdata_sz_pt+1),(ydata_sz_pt+1))
;    v_r_colors[0:xdata_sz_pt-1,0:ydata_sz_pt-1] = reform(image[0,*,*])
;    v_r_colors = reform(v_r_colors,(xdata_sz_pt+1)*(ydata_sz_pt+1))
;
;    v_g_colors = bytarr((xdata_sz_pt+1),(ydata_sz_pt+1))
;    v_g_colors[0:xdata_sz_pt-1,0:ydata_sz_pt-1] = reform(image[1,*,*])
;    v_g_colors = reform(v_g_colors,(xdata_sz_pt+1)*(ydata_sz_pt+1))
;
;    v_b_colors = bytarr((xdata_sz_pt+1),(ydata_sz_pt+1))
;    v_b_colors[0:xdata_sz_pt-1,0:ydata_sz_pt-1] = reform(image[2,*,*])
;    v_b_colors = reform(v_b_colors,(xdata_sz_pt+1)*(ydata_sz_pt+1))
;
;    v_a_colors = bytarr((xdata_sz_pt+1),(ydata_sz_pt+1))
;    v_a_colors[0:xdata_sz_pt-1,0:ydata_sz_pt-1] = reform(image[3,*,*])
;    v_a_colors = reform(v_a_colors,(xdata_sz_pt+1)*(ydata_sz_pt+1))
;
;
;    v_colors = transpose([[v_r_colors],[v_g_colors],[v_b_colors],[v_a_colors]])
;
;    polygon = obj_new('IDLgrPolygon',$
;                       x_verts,$
;                       y_verts,$
;                       z_verts,$
;                       vert_colors=v_colors,$
;                       shading=0,$
;                       style=2,$
;                       polygon=v_perm)
;
;  endelse
    
;print,systime(/seconds)-a
    
; return,polygon
    
    
end
