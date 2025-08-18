;+
;PROCEDURE specplot,x,y,z
;NAME:
;   specplot
;PURPOSE:
;   Creates a spectrogram plot.
;   All plot limits and plot positions are handled by the keyword LIMITS.
;INPUT:
;   x:  xaxis values:  dimension N.
;   y:  yaxis values:  dimension M.  (Future update will allow (N,M))
;   Z:  color axis values:  dimension (N,M).
;
;   All options are passed in through a single structure.
;KEYWORDS:
;   LIMITS:  A structure that may contain any combination of the following
;       elements:
;       X_NO_INTERP:   Prevents interpolation along the x-axis.
;       Y_NO_INTERP:   Prevents interpolation along the y-axis.
;       NO_INTERP:     Prevents interpolation along either axis
;       NO_COLOR_SCALE: Prevents drawing of color bar scale.
;       BOTTOM, TOP:   Sets the bottom and top colors for byte-scaling
;       ALL plot keywords such as:
;       XLOG,   YLOG,   ZLOG,
;       XRANGE, YRANGE, ZRANGE,
;       XTITLE, YTITLE,
;       TITLE, POSITION, REGION  etc. (see IDL documentation for a description)
;         The following elements can be included in LIMITS to effect DRAW_COLOR_SCALE:
;       ZTICKS, ZRANGE, ZTITLE, ZPOSITION, ZOFFSET
;   DATA:  A structure that provides an alternate means of supplying
;       the data and options.  This is the method used by "TPLOT".
;   X_NO_INTERP:   Prevents interpolation along the x-axis.
;   Y_NO_INTERP:   Prevents interpolation along the y-axis.
;   OVERPLOT:      If non-zero then data is plotted over last plot.
;   OVERLAY:       If non-zero then data is plotted on top of data from last
;        last plot.
;   PS_RESOLUTION: Post Script resolution.  Default is 150.
;   NO_INTERP:     If set, do no x or y interpolation.
;   IGNORE_NAN:    If nonzero, ignore data points that are not finite.
;   DX_GAP_SIZE = Maximum time gap over which to interpolate the plot. Use this
;     keyword when overlaying spectra plots, allowing the underlying spectra to
;     be shown in the data gaps of the overlying spectra.  Overrides value set
;     by DATAGAP in dlimits.  Note: if either DX_GAP_SIZE or DATAGAP is set to
;     less than zero, then the 20 times the smallest delta x is used.
;
;Notes:
;  - The arrays x and y MUST be monotonic!  (increasing or decreasing)
;  - The default is to interpolate in both the x and y dimensions.
;  - Data gaps can be included by setting the z values to NAN  (!values.f_nan).
;  - If ZLOG is set then non-positive zvalues are treated as missing data.
;
;See Also:  "XLIM", "YLIM", "ZLIM",  "OPTIONS",  "TPLOT", "DRAW_COLOR_SCALE"
;Author:  Davin Larson,  Space Sciences Lab
; $LastChangedBy: jimm $
; $LastChangedDate: 2025-02-18 14:05:52 -0800 (Tue, 18 Feb 2025) $
; $LastChangedRevision: 33138 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/specplot.pro $
;-
pro specplot,x,y,z,limits=lim,data=data,overplot=overplot,overlay=overlay,$
    ps_resolution=ps_res,x_no_interp=x_no_interp,y_no_interp=y_no_interp, $
        no_interp=no_interp, ignore_nan=ignore_nan, $
        dx_gap_size=dx_gap_size
        
compile_opt idl2 ;forces array indexing with brackets.  integer constants without type labels default to 32 bit int
                 ;note that array indexing with brackets should be considered mandatory for all future code,
                 ;As IDL 8+ implements parenthetical array indexes very very inefficiently

opt = {xrange:[0.,0.],yrange:[0.,0.],zrange:[1.,1.]}

if keyword_set(dx_gap_size) then dg=dx_gap_size else str_element,lim,'datagap',dg
str_element,lim,'no_interp',no_interp

if keyword_set(data) then begin
  x = struct_value(data,'x')
  y = struct_value(data,'v')
  z = struct_value(data,'y')
  if not keyword_set( y ) and size(/n_dimen,y) eq 0 then begin
       y = struct_value(data,'v2')    ;bp
       if ~keyword_set(y) then begin
         dim2 = size(/dimen,z)
         ndim2 = size(/n_dimen,z)
         if ndim2 eq 1 then y = [1.] else y= findgen(dim2[1])
       endif else   z = total(z,2)
  endif
  extract_tags,opt,data,except=['x','y','v']
  if keyword_set(dx_gap_size) then dg=dx_gap_size else str_element,lim,'datagap',dg
  ;str_element,lim,'datagap',dg ; old way
  ;if keyword_set(dg) then makegap,dg,x,z,v=y   ;bpif keyword_set(dg)
  if size(/n_dimen,z) eq 1 then begin    ; this is a kluge!
     dprint,dlevel=2,'Warning! One dimensional array provided. Kludging by increasing dimension.'
     z = [[z],[z]]
     y =  [y-.5,y+.5] 
;     printdat,z,y
  endif
endif

if keyword_set(no_interp) then begin
   x_no_interp=1
   y_no_interp=1
endif


; Find where gaps are
if keyword_set(dg) then begin

   ;dg = max_gap_interp
   ;dt = median(x[1:*]-x)
   if n_elements(x) lt 2 then begin
    dprint, dlevel=1, 'Error! Single x point.'
    tdif = [0]
   endif else tdif = [x[1:*]-x[0:n_elements(x)-2]]

   ; set minimum gap interp to twice median sampling rate in current trange
   ;if dg lt 2*dt then dg = 2*dt

   ; set dg to 20 times the smallest dx if datagap and/or dx_gap_size is negative
   if dg lt 0 then begin
      posindx = where(tdif gt 0,poscnt)
      dg = 20d*min(tdif[posindx])
   endif

   dprint,dlevel=3,verbose=verbose,'No plot interpolation for data gaps longer than ', $
          strcompress(dg,/remove_all),' seconds.'

   gapindx = where(tdif gt dg, gapcnt)

   if gapcnt gt 0 then begin
      ; create separate vars
      seg0 = lonarr(gapcnt+1) ; index numbers of start of each data segment
      seg1 = seg0             ; index numbers of end of each data segment
      seg1[gapcnt] =  n_elements(x)-1
      for i=0L,gapcnt-1 do begin
      ;TODO: Need to account for "consecutive gaps" to reduce # of segments
      ;      (gapcnt) and speed up the main loop for time windows with lots of
      ;      data with sample intervals greater than DATAGAP flag and/or
      ;      DX_GAP_SIZE.
         seg0[i+1] = gapindx[i]+1
         seg1[i] = gapindx[i]
      endfor

   endif else begin
      ; prepare for only single iteration in for loop
      seg0 = 0L
      seg1 = n_elements(x)-1
   endelse

endif else begin
   ; prepare for only single iteration in for loop
   gapcnt = 0
   seg0 = 0L
   seg1 = n_elements(x)-1
endelse

;copy to temp variable
xtemp = x
ytemp = y
ztemp = z

;Copy settings in the opt struct
extract_tags,opt,lim

;read settings from opt struct
str_element,opt,'xlog',value=xlog
str_element,opt,'ylog',value=ylog 
str_element,opt,'zlog',value=zlog

str_element,opt,'gifplot',value=gifplot
if keyword_set(gifplot) then begin
  x_no_interp = 1
  y_no_interp = 1
  no_color_scale = 1
endif

str_element,opt,'x_no_interp',value=x_no_interp
str_element,opt,'y_no_interp',value=y_no_interp
str_element,opt,'no_interp',value=no_interp
if keyword_set(no_interp) then begin
  x_no_interp=1
  y_no_interp=1
endif

str_element,opt,'max_value',value=mx
str_element,opt,'min_value',value=mn

;if keyword_set(mx) then print,'max_value= ', mx

str_element,opt,'bottom',value=bottom
str_element,opt,'top',   value=top

; Check for contour overplot option, jmm, 2023-01-23
str_element, opt, 'overplot_contour', success = conplt
if keyword_set(conplt) then begin ;extract contour options
   str_element, opt, 'contour_options', value = c_options
endif

;Check for panel label, jmm, 2024-02-18
str_element, opt, 'panel_label', success = plabel

;If autoscaling is on, make sure to autoscale outside the gap segment loop.
;Otherwise each gap segment will autoscale to a different range when datagap is set.
;(task# 4724)
;pcruce 2012-10-10

;modified to autoscale only to visible data set, rather than to entire time range of input variable
;(task #5304)
;pcruce 2016-01-22
trg = opt.xrange
if opt.zrange[0] eq opt.zrange[1] then begin

  ;restrict to visible time range
  goodx = where(finite(x) and x lt trg[1] and x ge trg[0],goodxcnt)
 
  if goodxcnt gt 0 then begin
    
    if keyword_Set(zlog) then begin
      good = where(finite(alog(z[goodx,*])),goodcnt)  ;log axis only calculates range over valid log output
      if goodcnt gt 0 then begin
        zrange = minmax((z[goodx,*])[good],min_value=mn,max_value=mx) ;restrict over time and valid log
      endif else begin
        zrange = [0.,0.]
      endelse
    endif else begin ;linear z axis
      zrange = minmax(z[goodx,*],min_value=mn,max_value=mx)
    endelse
  
  endif else begin
    zrange = [0.,0.]
  endelse
 
 ;Multiple alternative implementations below
 ;The version above tries to accomplish the goals of both
 ;#1 Don't autoscale each gap segment independently, use a "global" scale that is consistent for all gaps
 ;#2 Only autoscale based on displayed data, not on data outside of displayed range
 ;#3 Make sure NANs, Infinities, and non-positive integers(log axes) don't break range calculation
 ; 
 ;DL implementation
  ;  zrange=[0.,1.]
  ;  good = where(finite(total(z,2)) and finite(x) and x lt trg[1] and x ge trg[0],goodcnt)
  ;  if goodcnt gt 0 then zrange = minmax(z[good,*],positive=zlog,min_value=mn,max_value=mx)
  
;  printdat,zrange,good
  ;;;; NOTE by Eric Grimes (egrimes@igpp.ucla.edu):
  ;;;; r19691 broke spectra plots for THEMIS and MMS
  ;;;; reverted back on 1/14/2016:
  ;;;; commented out the above code, uncommented the below code
;  if keyword_set(zlog) then begin
;    good = where(finite(alog(z)),goodcnt)
;    if goodcnt gt 0 then begin
;      zrange = minmax(z[good],min_value=mn,max_value=mx)
;    endif else begin
;      zrange = [0,0]
;    endelse
;  endif else begin
;    zrange = minmax(z,/nan,min_value=mn,max_value=mx)
;  endelse
  
endif else begin
  zrange = opt.zrange
endelse

ydim = size(y,/n_dim)

no_color_scale=1

for j=0L,gapcnt do begin

   x = xtemp[seg0[j]:seg1[j]]
   if ydim eq 1 then y=ytemp else y=ytemp[seg0[j]:seg1[j],*]
   z = ztemp[seg0[j]:seg1[j],*]

   if n_params() eq 1 then begin
     dim = dimen(x)
     specplot,findgen(dim[0]),findgen(dim[1]),x,limits=lim,overplot=overplot,$
          overlay=overlay,ps_resolution=ps_res, $
          x_no_interp=x_no_interp,y_no_interp=y_no_interp
     return
   endif

   if opt.xrange[0] eq opt.xrange[1] then opt.xrange = minmax(x)
   if opt.yrange[0] eq opt.yrange[1] then opt.yrange = minmax(y)

   ;str_element,opt,'ytype',value=ylog   ; obsolete keywords
   ;str_element,opt,'xtype',value=xlog
   ;str_element,opt,'ztype',value=zlog



   if not keyword_set(overplot) then box,opt     ; Sets plot parameters.
   
   
   ;moved this line outside this loop to fix the zrange bug
   ;zrange = opt.zrange
   y1 = y
   if keyword_set(ylog) then begin
     bad = where( finite(y1) eq 0, c)
     if c ne 0 then y1[bad] = 0.
     bad = where(y1 le 0,c)
     if c ne 0 then y1[bad] = !values.f_nan
     y1 = alog10(y1)
   endif
   
   if keyword_set(xlog) then x1 = alog10(x) else x1 = x

   str_element,opt,'minzlog',value=minzlog
   z1 = z
   if keyword_set(zlog) then begin
      bad = where( finite(z1) eq 0, cbad)
      if cbad ne 0 then z1[bad] = !values.f_nan
      neg = where(z1 le 0,cneg)
      if keyword_set(minzlog) then begin
          posrange = minmax(z1,/pos)
          negvals = posrange[0]/10.
      endif else negvals = 0   ; !values.f_nan
      if cneg ne 0 then z1[neg] = negvals
      z1 = alog10(z1)
      zrange_new = alog10(zrange) ;so that we don't mess up the original zrange, make a copy
   endif else begin
     zrange_new = zrange ;copy zrange even if it isn't modified in this case so that it is defined for following code, no matter what
   endelse
   
   ;replicates edge data to make plots pretty if option set
   ;Wait until after final range is set to add spurious data
   ;Specifically, estimates bin width from bin centers and attempts to draw to bin edge. 
   ;If this keyword isn't set, top and bottom bins are drawn half width
   str_element,lim,'extend_y_edges',value=extend_y_edges,success=success
   if success && extend_y_edges then begin
     dprint,dlevel=4,'extending_y_edge'
     extend_y_dim = dimen(y1)

     ;need 2 or more y-components for this to work
     if n_elements(extend_y_dim) eq 1 && extend_y_dim[0] gt 1 then begin
       y_diff_low = (y1[1]-y1[0])/2.
       y_diff_high = (y1[extend_y_dim-1] - y1[extend_y_dim-2])/2.
       
       ;if difference is ever zero we can't extrapolate
       if y_diff_low ne 0 or y_diff_high ne 0 then begin
         ;replicate z data
         z1=[[z1[*,0]],[z1],[z1[*,extend_y_dim-1]]]
         ;use differences +- edges to generate new edges
         y1=[y1[0]-y_diff_low,y1,y1[extend_y_dim-1]+y_diff_high]
       endif
       
     endif else if n_elements(extend_y_dim) gt 1 && extend_y_dim[1] gt 1 then begin
     
       ;difference between lowest 2 and highest 2 rows of y for y-extrapolation
       y_diff_low = (y1[*,1]-y1[*,0])/2.
       y_diff_high = (y1[*,extend_y_dim[1]-1] - y1[*,extend_y_dim[1]-2])/2.
       
       ;if difference is ever zero we can't extrapolate
       idx = where(y_diff_low eq 0 or y_diff_high eq 0,c)
       
       if c eq 0 then begin
         ;replicate z data
         z1=[[z1[*,0]],[z1],[z1[*,extend_y_dim[1]-1]]]
         ;use differences +- edges to generate new edges
         y1=[[y1[*,0]-y_diff_low],[y1],[y1[*,extend_y_dim[1]-1]+y_diff_high]]
       endif
       
     endif
     
   endif

   xwindow=!x.window
   ywindow=!y.window
   xcrange=!x.crange
   ycrange=!y.crange

   ;str_element,opt,'overlay',value=overlay
   overlay = struct_value(opt,'overlay',default=1)

   ; need to be in overlay mode if stitching multiple segments together
   if gapcnt gt 0 then overlay=1

   if keyword_set(overlay) then begin
    ;modified check to use data in log space so it won't get confused when extend_y_edges is set
      ;But convert coord needs to be run in non-log space.  Hench the delog operation below
      x_minmax = keyword_set(xlog) ? 10.^minmax(x1) : minmax(x1) 
      y_minmax = keyword_set(ylog) ? 10.^minmax(y1) : minmax(y1)  
      winpos = convert_coord(x_minmax,y_minmax,/data,/to_norm)
      xwr = minmax(winpos[0,*])
      ywr = minmax(winpos[1,*])
   ;   xwindow(0) = xwindow(0) > xwr(0)
   ;   xwindow(1) = xwindow(1) < xwr(1)
      xwindow = xwindow > xwr[0]
      xwindow = xwindow < xwr[1]
      ywindow[0] = ywindow[0] > ywr[0]
      ywindow[1] = ywindow[1] < ywr[1]
      datpos = convert_coord(xwindow,ywindow,/norm,/to_data)
      xcrange = reform(datpos[0,*])
      ycrange = reform(datpos[1,*])
      
      if !x.type then xcrange = alog10(xcrange)
      if !y.type then ycrange = alog10(ycrange)
   endif


   pixpos = round(convert_coord(xwindow,ywindow,/norm,/to_device))
   npx = pixpos[0,1]-pixpos[0,0]+1
   npy = pixpos[1,1]-pixpos[1,0]+1
   xposition = pixpos[0,0]
   yposition = pixpos[1,0]

   if npx gt 0 and npy gt 0 then begin

      str_element,opt,'ignore_nan',ignore_nan
      if keyword_set(ignore_nan) then begin
         wg = where(finite(total(z1,2)),c)
         if c gt 0 then begin
           z1 = z1[wg,*]
           y1 = y1[wg,*]
           x1 = x1[wg]
         endif
      endif

      if !d.flags and 1 then begin   ; scalable pixels (postscript)
         if keyword_set(ps_res) then ps_resolution=ps_res else  ps_resolution = 150.  ; Postscript defaults to 150 dpi
         str_element,opt,'ps_resolution',value=ps_resolution
         dprint,dlevel=4,ps_resolution
         scale = ps_resolution/!d.x_px_cm/2.54
      endif else scale = 1.

      yd = ndimen(y1)
      if yd eq 1 then begin            ; Typical, y does not vary with time
        nypix = round(scale*npy)
        ny = n_elements(y1)
        yp = findgen(nypix)*(ycrange[1]-ycrange[0])/(nypix-1) + ycrange[0]
        ys = interp(findgen(ny),y1,yp)
        if keyword_set(y_no_interp) then  ys = round(ys)

        nxpix = round(scale*npx)
        if nxpix Le 1 then begin;changed from nxpix ne 0 to le 1, since nxpix=1 causes xp=NaN and no plot, jmm, 13-oct-2010
           dprint, verbose=verbose, dlevel=4,'WARNING: Data segment ',strcompress(j,/remove_all),' is too small along the  x-axis';,string(13B),$
;           '   for the given time window or is not within the given window.  Nothing will be',string(13B),$
;           '   plotted.  Try making the x-axis window smaller, or if creating a postscript',string(13B),$
;           "   file, try increasing the 'ps_resolution' value using the OPTIONS command."
;  This debug statement is trivial and much too long - fix the code if it is needed!!!
           continue
        endif else begin
          no_color_scale=0
        endelse
        nx = n_elements(x1)
        xp = findgen(nxpix)*(xcrange[1]-xcrange[0])/(nxpix-1) + xcrange[0]
        xs = interp(findgen(nx),x1,xp )
        if keyword_set(x_no_interp) then  xs = round(xs)
;test for auto_downsample
        str_element,opt,'auto_downsample',value=a_downsample
        if keyword_set(a_downsample) then begin
           if keyword_set(zlog) then begin
              z11 = 10.0^(z1)
              z11 = auto_downsample(z11, findgen(nx), xs)
              z1 = alog10(temporary(z11))
           endif else begin
              z11 = auto_downsample(z1, findgen(nx), xs) & z1 = temporary(z11)
           endelse
        endif
        image = interpolate(float(z1),xs,ys,missing = !values.f_nan,/grid)  ; using float( ) to fix IDL bug.

      ;  str_element,opt,'roi',roi
      ;  if keyword_set(roi) then begin
      ;     xp_ = xp # replicate(1.,nypix)
      ;     yp_ = replicate(1.,nxpix) # yp
      ;     roi_x = keyword_set(xlog) ? alog10(roi[*,0]) : roi[*,0]
      ;     roi_y = keyword_set(ylog) ? alog10(roi[*,1]) : roi[*,1]
      ;     dummy = enclosed(xp_,yp_,roi_x,roi_y,ncircs=ncirc)
      ;     image[where(ncirc eq 0)] = !values.f_nan
      ;  endif

      endif else begin
      ;  starttime = systime(1)
      ;  message,'y is 2 dimensional.  Please be patient...',/info

        nypix = round(scale*npy)
        ny = dimen2(y1)
        yp = findgen(nypix)*(ycrange[1]-ycrange[0])/(nypix-1) + ycrange[0]
        nxpix = round(scale*npx)
        if nxpix Le 1 then begin;changed from nxpix ne 0 to le 1, since nxpix=1 causes xp=NaN and no plot, jmm, 13-oct-2010
           dprint, verbose=verbose, dlevel=4,'WARNING: Data segment ',strcompress(j,/remove_all),' is too small along the  x-axis';,string(13B),$
;           '   for the given time window or is not within the given window.  Nothing will be',string(13B),$
;           '   plotted.  Try making the x-axis window smaller, or if creating a postscript',string(13B),$
;           "   file, try increasing the 'ps_resolution' value using the OPTIONS command."
;  See see debug statement above.
           continue
        endif else begin
          no_color_scale=0
        endelse
        
        nx = n_elements(x1)
        xp = findgen(nxpix)*(xcrange[1]-xcrange[0])/(nxpix-1) + xcrange[0]
        xs = interp(findgen(nx),x1,xp)
        xs = xs # replicate(1.,nypix)
        bad = where(finite(xs) eq 0,c)
        if c ne 0 then xs[bad]=-1
        if keyword_set(x_no_interp) then  xs = round(xs)

        ys = replicate(-1.,nxpix,nypix)
        ny1 = dimen1(y1)
        y_ind = findgen(ny)
        xi = round(xs)
        for i=0l,nxpix-1 do begin
          ;in this line it will generate a -1 which gets turned into 0
          m = (xi[i] > 0) < (ny1-1)
          yt1 = reform(y1[m,*])
          ys[i,*] = interp(y_ind,yt1,yp)
        endfor
      ;dtime = systime(1)-starttime
      ;dprint,string(dtime)+' seconds.'

        bad = where(finite(ys) eq 0,c)
        if c ne 0 then ys[bad]=-1
        if keyword_set(y_no_interp) then  ys = round(ys)
        image = interpolate(float(z1),xs,ys,missing = !values.f_nan)

      endelse

      if not keyword_set(gifplot) then begin
         image = bytescale(image,bottom=bottom,top=top,range=zrange_new)
         ;bytescale contour levels if passed in, jmm, 2023-01-23
         if keyword_set(conplt) && keyword_set(c_options) then begin
            str_element, c_options, 'levels', value = clevels
            if keyword_set(clevels) then begin
               if keyword_set(zlog) then clevels = alog10(clevels)
               clevels = bytescale(clevels,bottom=bottom,top=top,range=zrange_new)
               str_element, c_options, 'levels', clevels, /add_replace
            endif
         endif
      endif

      ;fill color code provided by Tomo Hori (E-mail: horit@stelab.nagoya-u.ac.jp)
      ;installed by pcruce on Jan,25,2011
      ;if fill_color defined, fill all pixels with the same color specified by fill_color
      str_element,opt,'fill_color',value=fill_color
      if ~keyword_set(fill_color) then fill_color = -1
      if fill_color ge 0 then begin
        idx = where(image lt 255) & if idx[0] ne -1 then image[idx]=fill_color
        no_color_scale = 1
      endif

      ;printdat,image,xposition,yposition
      if xposition ge 0 and yposition ge 0 and xposition lt !d.x_size and yposition lt !d.y_size then begin
        if fill_color lt 0 then begin
          ; On Macs using XQuartz, plotting to a pixmap and using DEVICE to
          ; write to the plot window is faster than using tv directly on the
          ; plot window. Not sure about how to implement this if contours are
          ; desired, jmm, 2021-01-23, so if coutours are desired, revert to tv
          ; to the plot window
          if !D.NAME EQ 'X' and !VERSION.OS_NAME EQ 'Mac OS X' and $
              ~keyword_set(conplt) then begin
            plot_win = !D.WINDOW
            window, /free, xsize = npx, ysize = npy, /pixmap
            pix_win = !D.WINDOW
            wset, pix_win
            tv,image
            wset, plot_win
            device, copy = [0,0,npx,npy,xposition,yposition,pix_win]
            wdelete, pix_win
          endif else begin
             tv,image,xposition,yposition,xsize=npx,ysize=npy
             ;overlot contour if requested
             if keyword_set(conplt) then begin
                xx = !x & yy = !y ;to reset tickmarks 
                !x.ticks = 1 & !x.tickname = replicate(' ', 30)
                !y.ticks = 1 & !y.tickname = replicate(' ', 30)
                contour, image, xstyle = 1, ystyle = 1, /noerase, /dev, $         
                         position = [xposition, yposition, xposition+npx, yposition+npy], $
                         _extra = c_options
                !x = xx & !y = yy
             endif
          endelse
        endif else begin
          idx = where( image eq fill_color )
          if idx[0] ne -1 then begin
            for i=0L, n_elements(idx)-1 do begin
              ind = array_indices(image, idx[i] )
              polyfill, xposition+ round( (ind[0]+[0,1,1,0])/scale ), $
                         yposition+ round( (ind[1]+[0,0,1,1])/scale ), color=fill_color, /device
            endfor
          endif
        endelse
      endif

      ;redraw the axes
      str_element,/add,opt,'noerase',1
      str_element,/add,opt,'overplot',/delete
      str_element,/add,opt,'ytitle',/delete
      str_element,/add,opt,'position',reform(transpose([[!x.window],[!y.window]]),4)
      ;help,opt,/st
      box,opt

   ; No data exists in within the given x/y axes
   endif else begin
      msg = (npx le 0 and npy le 0) ?  'x/y' : (npx le 0) ? 'x':'y'
      dprint, dlevel=3, 'Warning, data is outside the current '+msg+' axis range.'
   endelse

endfor ; loop over data segments

str_element,opt,'constant',constant
if n_elements(constant) ne 0 then begin
  str_element,opt,'const_color',const_color
  if n_elements(const_color) ne 0 then ccols = get_colors(const_color) else ccols=!p.color
  str_element,opt,'const_line',const_line
  if n_elements(const_line) ne 0 then cline = const_line[0] else cline = 3
  ncc = n_elements(constant)
  for i=0,ncc-1 do $
    oplot,opt.xrange,constant[i]*[1,1],color=ccols[i mod n_elements(ccols)],linestyle=cline
endif

zcharsize=!p.charsize
str_element,opt,'charsize',zcharsize
str_element,opt,'zcharsize',zcharsize ;specific setting overrides general/global setting

str_element,opt,'font',zfont
str_element,opt,'zfont',zfont

str_element,opt,'charthick',zcharthick
str_element,opt,'zcharthick',zcharthick

str_element,opt,'no_color_scale',no_color_scale


str_element,opt,'zposition',zposition
str_element,opt,'zoffset',zoffset
str_element,opt,'zminor',zminor
str_element,opt,'zgridstyle',zgridstyle
str_element,opt,'zthick',zthick
str_element,opt,'ztickformat',ztickformat
str_element,opt,'ztickinterval',ztickinterval
str_element,opt,'zticklayout',zticklayout
str_element,opt,'zticklen',zticklen
str_element,opt,'ztickname',ztickname
str_element,opt,'zticks',zticks
str_element,opt,'ztickunits',ztickunits
str_element,opt,'ztickv',ztickv
str_element,opt,'ztitle',ztitle

if not keyword_set(no_color_scale) then begin
  if keyword_set(bottom) and keyword_set(top) then begin
    draw_color_scale,brange=[bottom,top],range=zrange,log=zlog,title=ztitle, $
      charsize=zcharsize,yticks=zticks,position=zposition,offset=zoffset,$
      ygridstyle=zgridstyle,yminor=zminor,ythick=zthick,ytickformat=ztickformat,ytickinterval=ztickinterval,$
      yticklayout=zticklayout,yticklen=zticklen,ytickname=ztickname,ytickunits=ztickunits,$
      ytickv=ztickv,ytitle=ztitle,font=zfont,charthick=zcharthick
  endif else begin
    dprint, dlevel=0, 'Cannot draw color scale.  Either the data is out of '+ $
                      'range or top/bottom options must be set in tplot.'
  endelse
endif

;Apply panel_label last
if plabel && is_struct(opt.panel_label) then begin
   tplot_apply_panel_label, opt.panel_label
endif

;copy from temp variable back to input variables
x = xtemp
y = ytemp
z = ztemp

end
