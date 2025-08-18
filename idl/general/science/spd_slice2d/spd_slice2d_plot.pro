
;+
;Procedure:
;  spd_slice2d_plot
;
;Purpose:
;  Create plots for 2D particle slices.
;
;Calling Sequence:
;  spd_slice2d_plot, slice
;
;Arguments:
;  SLICE: 2D array of values to plot 
;
;Plotting Keywords:
;  LEVELS: Number of color contour levels to plot (default is 60)
;  OLINES: Number of contour lines to plot (default is 0)
;  CONTOURS_OPLOT: Boolean indicating to only plot contours, not the data.
;           this is especially useful if you're interested in plotting 
;           2-d or 3-d interpolated contours onto plots using geometric
;           interpolation; requires an already existing 2d slice plot
;  ZLOG: Boolean indicating logarithmic contour scaling (on by default)
;  ECIRCLE: Boolean to plot circle(s) designating min/max energy 
;           from distribution (on by default)
;  SUNDIR: Boolean to plot the projection of scaled sun direction (black line).
;          Requires GET_SUN_DIRECTION set with spd_dist_array. 
;  PLOTAXES: Boolean to plot x=0 and y=0 axes (on by default)
;  PLOTBULK: Boolean to plot projection of bulk velocity vector (red line).
;            (on by default)
;  PLOTORIGIN: Boolean to plot a new origin at the bulk velocity and/or sun location
;              instead of plotting the projection
;  PLOTBFIELD: Boolean to plot projection of scaled B field (cyan line).
;              Requires B field data to be loaded and specified to
;              spd_slice2d with mag_data keyword.
;            
;  TITLE: String used as plot's title
;  SHORT_TITLE: Flag to only use time range and # of samples for title
;  CLABELS: Boolean to annotate contour lines.
;  CHARSIZE: Specifies character size of annotations (1 is normal)
;  [XYZ]RANGE: Two-element array specifying x/y/z axis range.
;  [XYZ]TICKS: Integer(s) specifying the number of ticks for each axis 
;  [XYZ]PRECISION: Integer specifying annotation precision (sig. figs.).
;                  Set to zero to truncate printed values to integers.
;  [XYZ]STYLE: Integer specifying annotation style:
;             Set to 0 (default) for style to be chosen automatically. 
;             Set to 1 for decimal annotations only ('0.0123') 
;             Set to 2 for scientific notation only ('1.23e-2')
;  [B,V,SUN]_COLOR: Specify the color of the corresponding support vector.
;                   (e.g. "b_color=0", see IDL graphics documentation for options)
;  [B,V,SUN]_THICK: Specify the line thickness of the corresponding support vector
;  [B,V,SUN]_LINESTYLE: Specify the linestyle of the corresponding support vector
;  NOCOLORBAR: Suppress z axis color bar.
;
;  WINDOW:  Index of plotting window to be used.
;  PLOTSIZE: The size of the plot in device units (usually pixels)
;            (Not implemented for postscript).
;
;  CUSTOM:  Flag that to disable automatic window creation and allow
;           user-controlled plots.
;  
;  BACKGROUND_COLOR_INDEX: Integer (0-255) specifying a custom background color
;           where data = 0.0
;           
;  BACKGROUND_COLOR_RGB: 3D array of integers (0-255) representing RGB values
;            of the background color where data == 0.0; this keyword modifies the 
;            current color table to include this color at index = 7
;
;Exporting keywords:
;  EXPORT: String designating the path and file name of the desired file. 
;          The plot will be exported to a PNG image by default.
;  EPS: Boolean indicating that the plot should be exported to 
;       encapsulated postscript.
;
;
;Created by: 
;  Aaron Flores, based on work by Bryan Kerr and Arjun Raj
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2019-01-08 15:44:16 -0800 (Tue, 08 Jan 2019) $
;$LastChangedRevision: 26442 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/spd_slice2d_plot.pro $
;
;-

pro spd_slice2d_plot, slice, $
                     ; Range options
                       xrange=xrange, yrange=yrange, zrange=zrange, $
                     ; Basic plotting options
                       title=title, ztitle=ztitle, $ 
                       xtitle=xtitle, ytitle=ytitle, $
                       xticks=x_ticks, yticks=y_ticks, zticks=z_ticks, $
                       xminor=x_minor, yminor=y_minor, $
                       charsize=charsize_in, plotsize=plotsize, $
                       zlog=zlog, $
                       window=window, $
                     ; Annotations 
                       xstyle=xstyle, xprecision=xprecision, $
                       ystyle=ystyle, yprecision=yprecision, $
                       zstyle=zstyle, zprecision=zprecision, $
                       short_title=short_title, $
                     ; Contours
                       olines=olines, levels=levels, nlines=nlines, clabels=clabels, $
                       contours_oplot=contours_oplot, $
                     ; Other plotting options
                       plotaxes=plotaxes, ecircle=ecircle, sundir=sundir, $ 
                       plotbulk=plotbulk, plotbfield=plotbfield, $
                       plotorigin=plotorigin, $
                       b_color=b_color, v_color=v_color, sun_color=sun_color, $
                       b_thick=b_thick, b_linestyle=b_linestyle, $
                       v_thick=v_thick, v_linestyle=v_linestyle, $
                       sun_thick=sun_thick, sun_linestyle=sun_linestyle, $
                       custom=custom, nocolorbar=nocolorbar, $
                       background_color_index=background_color_index, $
                       background_color_rgb=background_color_rgb, $
                     ; Eport
                       export=export, eps=eps, $
                       _extra=_extra

    compile_opt idl2


  ; Return if variables are not set
  if ~is_struct(slice) then begin
    fail = 'No data structure provided.'
    dprint, dlevel=0, fail
    ;esnure there is some output (for loops and multi-plot formats)
    contour, [[0,0],[0,0]], title='Invalid input'
    return
  endif
  


  ; Defaults
  if keyword_set(nlines) and ~keyword_set(levels) then levels = nlines ;backward comp.
  if ~keyword_set(levels) then levels=60
  if slice.type ne 0 then begin
    if undefined(olines)then olines = 8
  endif
  
  if undefined(zlog) then zlog=1b
  if undefined(plotaxes) then plotaxes=1b
  if undefined(plotbulk) then plotbulk=1b

  if undefined(xstyle) then xstyle=0
  if undefined(xprecision) then xprecision=4
  if undefined(ystyle) then ystyle=0
  if undefined(yprecision) then yprecision=4
  if undefined(zstyle) then zstyle=0
  if undefined(zprecision) then zprecision=2

  if ~keyword_set(plotsize) then plotsize = 500.
  plotsize = 100. > plotsize ;min size
  
  ;large charsize values cause draw_color_scale to corrupt "data coordinate system"
  if ~undefined(charsize_in) then charsize = charsize_in < 4

  ;supplementary vector colors (asumes standard rainbow table)
  if undefined(b_color) then b_color = !d.table_size-165  ;cyan
  if undefined(v_color) then v_color = !d.table_size-9  ;red
  if undefined(sun_color) then sun_color = 0  ;black
  
  if undefined(v_thick) then v_thick = 1
  if undefined(b_thick) then b_thick = 1
  if undefined(sun_thick) then sun_thick = 1
  if undefined(v_linestyle) then v_linestyle = 2
  if undefined(b_linestyle) then b_linestyle = 2
  if undefined(sun_linestyle) then sun_linestyle = 2

  ; X,Y,Z ranges
  if keyword_set(xrange) && ~keyword_set(slice.rlog) then begin
    xrange = minmax(xrange)
  endif else begin
    xrange = minmax(slice.xgrid)
  endelse

  if keyword_set(yrange) && ~keyword_set(slice.rlog) then begin
    yrange = minmax(yrange)
  endif else begin
    yrange = minmax(slice.ygrid)
  endelse

  if keyword_set(zrange) then begin
    zrange = minmax(zrange)    
  endif else begin
    ; The default range is the nonnegative, nonzero 
    ; min/max of the pre-interpolated data
    zrange = slice.zrange * [0.999,1.001] ;padding, # in thm_ui_slice2d should match this
  endelse
  if zrange[1] eq zrange[0] then begin
    dprint, dlevel=1,'Slice at '+time_string(slice.trange[0])+' has no data.'
    title = 'Error: No data in range!'
    zrange = [1,10.]
  endif 

  
  ; Set color contour levels
  if keyword_set(zlog) then begin
    colorlevels = 10.^(lindgen(levels)/float(levels)*(alog10(zrange[1]) - alog10(zrange[0])) + alog10(zrange[0]))
  endif else begin
    colorlevels = (lindgen(levels)/float(levels)*(zrange[1]-zrange[0])+zrange[0])
  endelse
  
  
  ; Set colors
  thecolors = round((lindgen(levels)+1)*(!d.table_size-9)/levels)+7


  ; Get general annotations
  spd_slice2d_getinfo, slice, $
                       title=title, $
                       short_title=short_title, $
                       xtitle=xtitle, $
                       ytitle=ytitle, $
                       ztitle=ztitle


  ; Get the (rough) dimensions of the plot
  ; The values here were largely determined by trial and error
  plotxcsize = plotsize / !d.x_ch_size
  plotycsize = plotsize / !d.y_ch_size
  
  xmargin = [11,15 + (zprecision-3 > 0)]
  ymargin = [4,2]
  
  tsize = strlen(title) * 1.25 ;title always 1.25 larger than other text

  xcsize = (total(xmargin) + plotxcsize) > tsize
  ycsize = (total(ymargin) + plotycsize) 
  
  xsize = xcsize * !d.x_ch_size
  ysize = ycsize * !d.y_ch_size

  if undefined(contours_oplot) then begin

    ;Open postscript file
    ; -specify aspect ratio to keep output on non-windows systems
    ;  from appearing clipped in that system's viewer
    if keyword_set(export) && keyword_set(eps) then begin
      popen, export, encapsulated = 1, $
             aspect = ysize/xsize, $
             _extra=_extra
    endif
  
  
    ;Format the plotting window
    if !d.name eq 'WIN' or !d.name eq 'X' and ~keyword_set(custom) then begin
  
      device, window_state = wins
      
      ;ensure a free window is used if possible
      if undefined(window) then begin
        wn = !d.window le 1 or !d.window ge 32  ?  $
              min( where(wins eq 0) ) > 2 : !d.window
      endif else begin
        wn = window
      endelse
    
      window, wn, xsize = xcsize * !d.x_ch_size, $
              ysize = ycsize * !d.y_ch_size, $
              title = title
  
      xmargin[0] = xmargin[0] > 0.5*(xcsize - plotxcsize)
    endif
  
    
    ; Get tick annotations after window has been initialized, 
    ; this will avoid an extra window from being created by AXIS.
    if keyword_set(slice.rlog) then begin
    
      ; Get ticks for radial log plots
      spd_slice2d_getticks_rlog, range=slice.rrange, grid=slice.xgrid, $
                                 style=xstyle, precision=xprecision, nticks=x_ticks, $
                                 ticks=xticks, tickv=xtickv, tickname=xtickname
                             
      yticks = xticks
      ytickv = xtickv
      ytickname = xtickname
          
    endif else begin 
    
      ; Get x ticks & annotations
      spd_slice2d_getticks, nticks=x_ticks, range=xrange, style=xstyle, precision=xprecision, $
                            ticks=xticks, tickv=xtickv, tickname=xtickname, log=0
      
      ; x minor ticks, simulate default if not set
      ; use new name to avoid mutating input
      xminor = undefined(x_minor) ? 10 : (round(x_minor)+1 > 0)
    
      ; Get y ticks & annotations
      spd_slice2d_getticks, nticks=y_ticks, range=yrange, style=ystyle, precision=yprecision, $
                            ticks=yticks, tickv=ytickv, tickname=ytickname, log=0
      
      ; y minor ticks, simulate default if not set
      ; use new name to avoid mutating input
      yminor = undefined(y_minor) ? 10 : (round(y_minor)+1 > 0)
    
    endelse
      ; allow users to set a custom background color
      if ~undefined(background_color_rgb) then begin
        ; the user specified RGB values for the background color
        if n_elements(background_color_rgb) ne 3 then begin
          dprint, dlevel = 0, 'Error, background_color_rgb should have 3 components - Red, Green, Blue'
          return
        endif
        ; modify element 7 of the colortable to include the user's color
        tvlct, red, green, blue, /get
        red[7]=background_color_rgb[0]  ; choose index after 6th to preserve black axes, ticks, and text
        green[7]=background_color_rgb[1]
        blue[7]=background_color_rgb[2]
        tvlct, red, green, blue
        background_color_index = 7
      endif
      if ~undefined(background_color_index) then begin
        colorlevels_new = fltarr(n_elements(colorlevels)+1)
        colorlevels_new[0] = 0.0
        thecolors_new = intarr(n_elements(thecolors)+1)
        thecolors_new[0] = background_color_index
        colorlevels_new[1:*] = colorlevels
        thecolors_new[1:*] = thecolors
        colorlevels = colorlevels_new
        thecolors = thecolors_new
      endif
      ; Plot
      contour, slice.data, slice.xgrid, slice.ygrid, $
          levels = colorlevels, c_color = thecolors, charsize=charsize, $
          /isotropic, /closed, /follow, $
    ;      /cell_fill,  $     ; Cell fill does not appear necessary here
          /fill, $
          title = title, $
          xmargin = xmargin, $
          ymargin = ymargin, $
          xstyle = 1, $    ; Force range
          ystyle = 1, $    ;
          ticklen = 0.01,$
          xtickname = xtickname,$  ; 2012-June: Annotations now controled by 
          ytickname = ytickname,$  ;            formatannotation
          xminor = xminor,$   ; Allow minor ticks to persist
          yminor = yminor,$   ; when specifying # of major ticks
          xtickv = xtickv,$  ; 2013-April: Specify values to avoid inconsistencies
          ytickv = ytickv,$  ;             
          xticks = xticks, $  ; Number of ticks must be passed in with values 
          yticks = yticks, $  ; for them to be placed correctly
          xrange = xrange,$
          yrange = yrange,$
          xtitle = xtitle,$
          ytitle = ytitle, $
          _extra = _extra
  
    ; Get z axis ticks
    spd_slice2d_getticks,nticks=z_ticks, range=zrange, log=zlog, $
                         style=zstyle, precision=zprecision, $
                         ticks=zticks, tickv=ztickv, tickname=ztickname
                               
    
    ; Draw z axis color bar.c
    ;  - both the number of ticks and the tick values must 
    ;    be passed in for them to be placed correctly
    if ~keyword_set(nocolorbar) then begin
      draw_color_scale,range=zrange, log=zlog,title=ztitle, charsize=charsize, $
                       yticks=zticks, ytickv=ztickv, ytickname=ztickname
    endif

  endif


  ;Other Plotting Options
  ;----------------------

  ;length of direction vectors
  ;use max energy if possible, otherwise use shortest axis
  vector_length = slice.rrange[1] gt 0 ? slice.rrange[1] : min( abs( [xrange,yrange] ) )

  ; Plot contour lines
  if keyword_set(olines) && slice.type ne 0 then begin

    ; set contour levels
    if keyword_set(zlog) then begin
      linelevels = 10.^(indgen(olines)/float(olines)*(alog10(zrange[1]) - alog10(zrange[0])) + alog10(zrange[0]))
    endif else begin
      linelevels = (indgen(olines)/float(olines)*(zrange[1]-zrange[0])+zrange[0])
    endelse

    contour, slice.data, slice.xgrid, slice.ygrid, $
        levels = linelevels, charsize=charsize,  $
        /overplot, /closed, /isotropic, $
        follow = clabels, _extra=_extra

  endif


  ; Plot axes
  if keyword_set(plotaxes) then begin
    oplot, [0.,0.], yrange, linestyle=2, thick = 1
    oplot, xrange, [0.,0.], linestyle=2, thick = 1
  endif
  

  ; Plot circle for minimum/maximum velocity 
  ; (based off energy limits) 
  if keyword_set(ecircle) and ~keyword_set(slice.shift) then begin
    degrees = findgen(360)*!dtor
    
    ocircy=sin(degrees) * slice.rrange[1]
    ocircx=cos(degrees) * slice.rrange[1]
    icircy=sin(degrees) * slice.rrange[0]
    icircx=cos(degrees) * slice.rrange[0]
    
    if slice.rrange[1] gt 0 then $
      oplot,ocircx,ocircy,thick = 1
    if slice.rrange[0] gt (yrange[1]-yrange[0])*0.015 then $
      oplot,icircx,icircy,thick = 1
  endif
  
  
  ; Plot the bulk velocity
  ; (on by default so don't warn if cannot be plotted)
  if keyword_set(plotbulk) and ~keyword_set(slice.shift) then begin
    if n_elements(slice.bulk) eq 3 and finite(total(slice.bulk))  then begin
    ; bulk velocity should already be in the coords defined for the slice plane
      if keyword_set(plotorigin) then begin
        oplot, [slice.bulk[0],slice.bulk[0]], yrange, linestyle=v_linestyle, thick=v_thick, color=v_color
        oplot, xrange, [slice.bulk[1],slice.bulk[1]], linestyle=v_linestyle, thick=v_thick, color=v_color
      endif else oplot, [0,slice.bulk[0]], [0,slice.bulk[1]], color=v_color, linestyle=v_linestyle, thick=v_thick
    endif
  endif


  ; Plot sun direction
  if keyword_set(sundir) then begin
    if n_elements(slice.sunvec) eq 3 and finite(total(slice.sunvec)) then begin
      ;sun vector is normalized & in slice plane's coords
      ;make total length equal to the smallest axis limit and plot projection
      sunvec = slice.sunvec * vector_length
      if keyword_set(plotorigin) then begin
        oplot, [sunvec[0],sunvec[0]], yrange, linestyle=sun_linestyle, thick=sun_thick, color=sun_color
        oplot, xrange, [sunvec[1],sunvec[1]], linestyle=sun_linestyle, thick=sun_thick, color=sun_color
      endif else oplot, [0,sunvec[0]],[0,sunvec[1]], color=sun_color, linestyle=sun_linestyle, thick=sun_thick
    endif else begin
      dprint, dlevel=1, 'No valid sun direction to plot.' 
    endelse
  endif


  ; Plot B field
  if keyword_set(plotbfield) then begin
    if n_elements(slice.bfield) eq 3 and finite(total(slice.bfield)) then begin
      ;bfield is in nT in the slice plane's coords
      ;plot direction as dotted line ending at max energy circle 
      ;and in-plane component as proportional solid line
      bfield = slice.bfield / sqrt(total(slice.bfield^2)) * vector_length
      bdir = slice.bfield[0:1] / sqrt(total(slice.bfield[0:1]^2)) * vector_length
      oplot, [0,bdir[0]],[0,bdir[1]], color=b_color, linestyle=v_linestyle, thick=v_thick
      oplot, [0,bfield[0]],[0,bfield[1]], color=b_color, linestyle=v_linestyle, thick=v_thick
    endif else begin
      dprint, dlevel=1, 'To plot the B field vector the mag_data keyword must'+ $ 
                        ' be specified in call to spd_slice2d.' 
    endelse
  endif



  ; Finish export:  write .png or close postscript file 
  if keyword_set(export) then begin
    if keyword_set(eps) then begin
      pclose
    endif else begin
      makepng, export, /mkdir, _extra=_extra
    endelse
  endif


end
