;+
;
; Procedure:  plotxyvec
;
; Purpose:  Plots a set of arrows on an image generated with
;         plotxy,tplotxy or, plotxyz this is a pretty simple wrapper
;         for the idl arrow routine.  The major difference is that
;         this routine stores a history so that you can autoreplot it
;         This routine will take any of the options that the normal
;         arrows routine takes, with one exception.  plotxyvec must
;         always use data coordinates.
;
;           
; Examples:
; 
;    plotxyvec,xy,dxy
;    plotxyvec,xy,dxy,/grid,multi='2,1'
;    plotxyvec,xy,dxy,/grid,/addpanel,xticks=5
;
; Arguments: xy: an Nx2 array that contains the starting coordinates of the arrows
;            dxy: an Nx2 array that contains the offset from each
;                 starting coordinate to the end of the arrow
;            (They argument can be MxNx2 or JxMxNx2 ... the main requirement is that the last
;            dimension be 2)
;
; Keywords:
; 
;      noisotropic:Set this keyword if you want the plot to not be isotropic
;       
;      overplot: set this keyword if you want to plot
;        on the last plot and panel that you plotted on
;
;      addpanel: set this keyword if you want to plot on a new
;         panel within the same plot window as where you last
;         plotted. This will go to the next column first and if it is
;         at the end of a row, to the next row.
;
;      multi: set this keyword to a string that 
;         specifies the layout of panels within a plotwindow.  Set
;         this keyword only the first time you call tplotxy for a 
;         given plotwindow.  Each time you set it, the previous
;         contents of the window will be erased. You can separate
;         the two elements with a variety of different delimiters
;         The first element is columns left to right, the second rows
;         top to bottom. Append an 'r' to the elements to have it
;         reverse the direction of panel application
;         Examples:  multi= '2 3' 
;                    multi= '5r,7'
;                    multi=' 1:6r'
;                     .....
;                     
;       mmargin(optional, can only be used if multi is also specified): 
;         set this keyword to a 4 element array specifying margins to be left
;         around a multipanel plot. Element order is bottom, left, top, right.
;         Margins are specified relative to the overall size of the window: 
;         0.0 is no margin, 1.0 is all margin. 
;             e.g. mmargin=[0.1,0.1,0.15.0.1]
;                    
;       mtitle(optional, can only be used if multi is also specified):
;         set this keyword to a string to display as a title for a multi panel
;         plot window. This is displayed in addition to any titles specified for
;         individual panels.
;         If the top mmargin = 0, or has not been set then it will be set at 0.05
;         to allow room for the title. 
;         It is not possible to set your own font size for the mtitle. The size is
;         chosen so that as much as possible the title fits in the top margin and 
;         is not too long for the window. Setting a larger top mmargin will
;         increase the font size. NB: Size is fixed you are saving your plot
;         to a postscript. If you require more control over the title format
;         try leaving space using mmargin and adding your own text with idl 
;         procedure XYOUTS.
;         
;       mpanel(optional, can only be used if multi is also specified):
;         set this keyword to a string to specify which panels in a multipanel window
;         to plot to. This allows you to create non symmetric plot layouts in a multi
;         panel window.
;         mpanel must contain two numbers separated by a comma (col, row) or two ranges
;         indicated with a colon, separated by a comma.
;         Panels are numbered starting at 0, from top to bottom and from
;         left to right. 
;             e.g. mpanel = '0,1' will plot to panel in the first column,
;                       second row; 
;                  mpanel = '0:1,0' will create a plot that takes up both the first
;                       and second columns in the first row.
;         You cannot plot to a panel if that panel has already been used.
;         Panels in a window are normally filled from left to right, top to bottom. You
;         can use mpanel to place a plot out of this standard sequence.
;  
;         xistime(optional): set this keyword if you want to treat the x-axis
;         as a time axis and use tplot-style time labels
;  
;       [xy]range: The desired range of your plot on a particular axis. By default
;       this routine will not display any arrows that start or end outside this range.
;       Use noclip, nostartclip, nostopclip, or clip. To display clipped arrows.
;       
;       [xy]margin: The desired margin for the plot on the left/right(x) axis
;           or the top/bottom(y) axis.  This is specified as a proportion of
;           the overall plot window.(ie from 0.0 to 1.0)
;        
;        grid:  Set this option to draw a grid on the output
;        
;        window: Set a specific window number to plot in.
;         
;        [xy]size: The size in pixels of the window you want to plot
;        
;        wtitle:  The title of the window
;        
;        uarrowside:  A string storing the side on which the unit arrow should be drawn.
;        Can be: 'left','right','top','bottom','none'
;        
;        uarrowoffset: The distance of the arrow from the edge of the plot.  This is 
;        specified as a proportion of the size of the plot. (By default it is .2 for left/right
;        arrows and .05 for top/bottom arrows
;        
;        uarrowtext:  Any text to be drawn after the number of data units the arrow represents.
;        This is usually used to indicate the units.
;        
;        uarrowdatasize: The number of data units that the unit arrow should represent.
;        
;        arrowscale: The ratio between the coordinate system of the
;        start points(xy) and the coordinate system of the offsets.(dxy)
;        (default:1.0)
;
;        xtick_get,ytick_get: These behave exactly as the plot
;        command versions, but they had to be identified explictly
;        to ensure they would be passed through correctly.
;        
;        hsize: This scales the head size of the arrow.  This is basically like the hsize argument
;        to arrow, except it is a normalized value instead of a fraction of !D.x_size.  
; 
;        clip: allows the user to set clipping to a particular bounding box.
;              either set /clip to clip to the current x,y range or set clip equal to q 
;              a 4 element array with elements [x0,y0,x1,x2] specifying the corners of 
;              the bounding box
;              
;        startclip: clip xy, but not dxy
;        
;        stopclip: clip dxy, but not xy
;              
;        color:  Set the color of the arrows.  Can use color indexes or letters('b','g'...)
;             This does not currently allow you to set separate colors for separate arrows in
;             a single call.
;        Replot:  For internal use only
;        All Other Keywords:  See IDL documentation for arrow.pro,plot.pro, this routine 
;        accepts most of the arguments to these routines through _extra
; 
;        get_plot_pos=get_plot_pos: Return the normalized position of your plot.
;             Output will be a 4-element array [x1,y1,,x2,y2]
;             Where (x1,y1) is the lower-left corner of your plot and
;             (x2,y2) is the top right corner of your plot.
; 
; Notes: If the arrows are overplotted, the routine will use the
;        x,y range of the previous plot, by default.
;        
;        The unit arrow will only be drawn automatically when using isotropic plots.
;        If you'd like the routine to draw two unit arrows when using nonisotropic plots,
;        to indicate the scaling in each direction, please request the feature.
;        
;        Arrows that start or end outside of the user defined xrange,yrange will be clipped
;        by default.  Use noclip, nostartclip, nostopclip, or clip. Clipping clips the apparent
;        range.  So if the arrows are enlarged by uarrowscale, they may be clipped; even if the
;        data values they represent are in range.
;        
;          ********************************
;         Plot windows and panels:
;         using, /overplot,/addpanel,/noisotropic and multi=
;
;         To put multiple panels in a window first call
;         plotxy with the multi keyword.  It will either
;         plot in which ever window is your current one, or
;         create a new one if no window exists or if you 
;         request the use of a nonexistent window.
;
;         During this first call you may want to specify things
;         like wtitle,xsize,ysize,window...in addition to your normal
;         plotting options. However,Calling window options will interfere with
;         the creation of postscripts. 
;
;         multi specifies the plot window panel layout.
;         So if you set multi='3,2' you will get 6 plots
;         in your window with a layout like:
;           -------
;           |x x x|
;           |x x x|      
;           -------
;
;         Each panel will have dimensions x number of pixels = 1/3 *
;         xsize of window and y number of pixels = 1/2 * ysize of window.
;
;         Your first call should also specify the layout of your 
;         first panel. To add to that panel use the /overplot keyword.
;         
;         When you use the /add keyword the program will move on to
;         the next panel within the plot window and you should add
;         options to specify the layout of that panel. 
; 
;         If you set the xmargin or ymargin keyword the margin will be
;         relative to the overall size of that panel. When using the
;         not using the noisotropic keyword the procedure will make
;         each axis vary over the same range AND make the
;         largest possible square window given the size of the panel
;         and the sizes of the margins you have provided, if possible.
;         In some cases when ranges are set explictly the plot must
;         be rectangular.
;
;         An entire plot window must be filled in sequence, if you move
;         on to a new window you will not be able to go back to the
;         previous window without restarting.
;
;         If you call plotxy with no arguments it will redraw the
;         entire window including all panels and overplots.  If you
;         resize the window before calling with new arguments it
;         will redraw the isotropic panels as the largest possible
;         squares.  This comes at a cost of storing copies of the 
;         commands and data you made in memory.  If you need to save
;         memory you can call the function with the /memsave argument,
;         but then redraws will be done using hardware and window resizes
;         can distort isotropic plots.
;
;         NOTE TO PROGRAMMERS:
;           Information about plotting for plotxy is stored in
;           the global variable !TPLOTXY, this includes
;           information about the layout of the plot window
;           which panel it is currently working on, and the 
;           sequence of commands used to generate current plot window
;           so that it can regenerate the plotwindow when called
;           with no arguments. This variable also stores information
;           used by the plotxyz function so spectrographic xyz plots 
;           can be interleaved with xy line plots. 
;
; See Also:
;   plotxy.pro,tplotxy.pro,plotxyz.pro,plotxylib.pro
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2013-08-23 17:25:01 -0700 (Fri, 23 Aug 2013) $
; $LastChangedRevision: 12887 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/plotxyvec.pro $
;
;-

;helper function
;draws the unit arrow 
;this indicates the scale
;of the arrows

pro makeunitarrow,dsize,ascale,isotropic,uarrowside,uarrowoffset,uarrowtext,charsize=charsize,charthick=charthick,font=font,_extra=ex

  compile_opt idl2

  ;uses the dimensions of whatever plot the arrows are being placed on
  ;if the dimensions of the particular call were used they might very different
  ;This would give distorted results
  pos = !tplotxy.pos
  xrange = !tplotxy.xrange
  yrange = !tplotxy.yrange

  side = 0

  if ~keyword_set(isotropic) then begin
    dprint,"Arrow scales not currently automatically drawn for nonisotropic plots. If you want this feature, please request it",dlevel=2
    return
  endif

  ;user can specify which side of the plot the arrow goes on
  if keyword_set(uarrowside) then begin
  
    if ~is_string(uarrowside) then begin
      dprint,"Error uarrowside must be type: string"
      return
    endif
  
    if strcompress(strlowcase(uarrowside),/remove_all) eq 'right' then begin
      side = 0
    endif else if strcompress(strlowcase(uarrowside),/remove_all) eq 'top' then begin
      side = 1
    endif else if strcompress(strlowcase(uarrowside),/remove_all) eq 'left' then begin
      side = 2
    endif else if strcompress(strlowcase(uarrowside),/remove_all) eq 'bottom' then begin
      side = 3
    endif else if strcompress(strlowcase(uarrowside),/remove_all) eq 'none' then begin
      return
    endif else begin
      dprint,"Error uarrowside is unrecognized string: " + strcompress(strlowcase(uarrowside),/remove_all)
      return
    endelse
  endif
  
  ;user can specify the offset from the edge of the plot at which the arrow is placed
  if undefined(uarrowoffset) then begin
    
    if side eq 0 || side eq 2 then begin
      offset = .25
    endif else begin
      offset = .05
    endelse
  endif else begin
    offset = uarrowoffset
  endelse
  
  ;user can specify the text that goes after the number of data units
  if ~keyword_set(uarrowtext) then begin
    text = ''
  endif else begin
    text = uarrowtext
  endelse
  
  if side eq 1 || side eq 3 then begin
  
    arrlen = ascale*dsize*(pos[2]-pos[0])/(xrange[1]-xrange[0])
    
    textorr = 0
    
  endif else begin
   
    arrlen = ascale*dsize*(pos[3]-pos[1])/(yrange[1]-yrange[0])
    
    textorr = 90
       
  endelse
  
  ;calculate arrow dimensions    
  p = pos
 
  if side eq 0 then begin
  
      p[0] = pos[2] + (pos[2]-pos[0])*offset
  
      p[2] = p[0]
      
      p[3] = p[1]+arrlen
      
      tp = [p[0],p[3]*1.05]
      
   endif else if side eq 1 then begin
   
      p[1] = pos[3] + (pos[3]-pos[1])*offset
      
      p[3] = p[1]
      
      p[2] = p[0] + arrlen
      
      tp = [p[2]*1.05,p[1]]
   
   endif else if side eq 2 then begin
   
      p[0] = pos[0] - (pos[2]-pos[0])*offset
  
      p[2] = p[0]
      
      p[3] = p[1]+arrlen
      
      tp = [p[0],p[3]*1.05]
      
   endif else if side eq 3 then begin
   
      p[1] = pos[1] - (pos[3]-pos[1])*offset
      
      p[3] = p[1]
      
      p[2] = p[0] + arrlen
      
      tp = [p[2]*1.05,p[1]]
      
    endif
    
    arrow,p[0],p[1],p[2],p[3],_extra=ex,/normalized
    
    xyouts,tp[0],tp[1],strcompress(string(dsize))+' '+text,orientation=textorr,/normal,charsize=charsize,charthick=charthick,font=font,_extra=ex
    
      
end

pro plotxyvec,xy,dxy,noisotropic=noisotropic,addpanel=addpanel, $
              overplot=overplot,multi=multi,mmargin=mmargin,mtitle=mtitle,mpanel=mpanel,xrange=xrange,yrange=yrange,$
              xmargin=xmargin,ymargin=ymargin,grid=grid,window=window,$ 
              xsize=xsize,ysize=ysize,wtitle=wtitle,uarrowside=uarrowside,$
              uarrowoffset=uarrowoffset,uarrowtext=uarrowtext,$
              uarrowdatasize=uarrowdatasize,arrowscale=arrowscale,$
              hsize=hsize,clip=clip,startclip=startclip,stopclip=stopclip,$
              color=color,replot=replot,xistime=xistime,$
              get_plot_pos=get_plot_pos,_extra=ex

  compile_opt idl2

  plotxylib

  if undefined(xy) && undefined(dxy) then begin

     pxy_replot

     return

  endif

  if undefined(xy) || undefined(dxy) then begin

     dprint,"x,y,dx,dy not set, Returning"

     return
     
  endif
  
  if ~undefined(color) then begin
    if is_string(color) then begin
      col = (get_colors(color))[0]
    endif else if is_num(color) then begin
      col = color
    endif else begin
      dprint,'Color set to illegal type'
      return
    endelse
  endif
  
  dimxy = dimen(xy)
  dimdxy = dimen(dxy)
  
  if (dimxy[n_elements(dimxy)-1] ne 2) || (dimdxy[n_elements(dimdxy)-1] ne 2) || (n_elements(dimxy) ne n_elements(dimdxy))$
    || (n_elements(xy) ne n_elements(dxy)) then begin
    dprint,'xy & dxy must be Nx2 arrays with same number of elements'
    
    return
  endif
  
  if n_elements(dimxy) ge 2 then begin
    d_new = product(dimxy[0:n_elements(dimxy)-2])
    
    xy_new = reform(xy,d_new,2)
    dxy_new = reform(dxy,d_new,2)
    
    dimxy = [d_new,2]
    dimdxy = [d_new,2]
  endif else if n_elements(dimxy eq 2) then begin
    xy_new = xy
    dxy_new = dxy
  endif else begin
    dprint,'Too few dimensions in xy/dxy'
    
    return
  endelse
    
  x = double(xy_new[*,0])
  y = double(xy_new[*,1])
  dx = double(dxy_new[*,0])
  dy = double(dxy_new[*,1])

  pxy_set_window,overplot,addpanel,replot,window,xsize,ysize,wtitle,multi,mmargin,mtitle,noisotropic,isotropic=isotropic
   
  if keyword_set(xrange) then begin
    xr = double(xrange)
     
    if n_elements(xr) ne 2 then begin
      dprint,"Xrange should have 2 elements"
      return
    endif
     
    if ~is_num(xr) then begin
      dprint,"Xrange should be numerical type"
      return
    endif
    
    if xr[0] ge xr[1] then begin
     
      xr2 = [xr[1],xr[0]]
     
    endif else begin
      xr2 = xr
    endelse
     
  endif else begin
  
     if keyword_set(overplot) then begin 
       xr = !tplotxy.xrange
     endif else begin
       x_max = max(x,/nan)
       x_min = min(x,/nan)

       xr = [x_min,x_max]
     endelse
     
       xr2 = xr
     
  endelse
  
  if keyword_set(yrange) then begin
    yr = double(yrange)
     
    if n_elements(yr) ne 2 then begin
      dprint,"Yrange should have 2 elements"
      return
    endif
     
    if ~is_num(yr) then begin
      dprint,"Yrange should be numerical type"
      return
    endif
    
    if yr[0] ge yr[1] then begin
   
     yr2 = [yr[1],yr[0]]
   
    endif else begin
     yr2 = yr
    endelse
     
  endif else begin
  
     if keyword_set(overplot) then begin
       yr = !tplotxy.yrange
     endif else begin
       y_max = max(y,/nan)
       y_min = min(y,/nan)

       yr = [y_min,y_max]
     endelse 
     
     yr2 = yr
      
  endelse

  ;user can specify the arrow length in data units
  if ~keyword_set(uarrowdatasize) then begin
    dxyrange = max(sqrt(dx^2+dy^2),/nan)
    datmag=alog10(dxyrange)
    datdif = datmag - floor(datmag)
   if datdif ge alog10(5) then begin
      dsize = 10.^floor(datmag)
   endif else if datdif le alog10(5) && $
      datdif ge alog10(2) then begin
      dsize = 10.^(floor(datmag)-1+alog10(5))
   endif else begin
      dsize = 10.^(floor(datmag)-1+alog10(2))
   endelse
  endif else begin
     dsize = double(uarrowdatasize)
  endelse

  if ~keyword_set(arrowscale) then begin
     ascale=1.0   
  endif else begin 
     ascale = double(arrowscale)
  endelse
  
 ; print,dsize,ascale,xyrange,dxyrange
  
  ;scale arrow length
  uplot = ascale*dx
  vplot = ascale*dy

  if keyword_set(grid) then begin
     ticklen = 1.0
  endif

  if keyword_set(addpanel) then begin
    noerase=1
  endif else begin
    noerase=0
  endelse
  
  if ~keyword_set(hsize) then begin
    head_size = .5
  endif else begin
    head_size = hsize
  endelse
  
  head_size *= !D.x_size/64 

  if ~keyword_set(overplot) then begin

     uarrowoffset=.1

     pos = pxy_get_pos(xr2,yr2,isotropic,xmargin,ymargin,mpanel)
   
   
     extract_tags,ex,{xrange:xr} ;xrange is now sent to plot through _extra
   
     if keyword_set(xistime) then begin
        x_time_setup = time_ticks(xr,x_time_offset,xtitle=xtitle)
        x_time_setup.xtickv+=x_time_offset
        extract_tags,ex,x_time_setup,/preserve ;merge time_settings into other settings
     endif
   
    plot,xr2,yr2,xrange=xr,yrange=yr,ticklen=ticklen,position=pos,thick=1.0,/nodata,$
        xtick_get=xtick_get,ytick_get=ytick_get,xstyle=1,ystyle=1,noerase=noerase,_extra=ex ;generate background labels etc...

    if arg_present(get_plot_pos) then begin
      get_plot_pos=pos
    endif

  endif
  
  if (keyword_set(multi) and keyword_set(mtitle)) then begin
    pxy_make_title
  endif
  if keyword_set(clip) || keyword_set(startclip) || keyword_set(stopclip) then begin  

    if keyword_set(clip) && n_elements(clip) eq 4 && is_num(clip) then begin
      x_min = min([clip[0],clip[2]],/nan)
      x_max = max([clip[0],clip[2]],/nan)
      
      y_min = min([clip[1],clip[3]],/nan)
      y_max = max([clip[1],clip[3]],/nan)
    endif else begin
      x_min = min(xr)
      x_max = max(xr)
      
      y_min = min(yr)
      y_max = max(yr)
    endelse
     
    if keyword_set(startclip) || ~keyword_set(stopclip) then begin
    ;clip x
      idx = where(x ge x_min and x le x_max)
      
      if idx[0] ne -1 then begin
        x = x[idx]
        y = y[idx]
        uplot = uplot[idx]
        vplot = vplot[idx]
      endif else begin
        dprint,'All data values start outside of clipping range'
        nodraw = 1
      endelse
        
      ;clip y
      idx = where(y ge y_min and y le y_max)
      
      if idx[0] ne -1 then begin
        x = x[idx]
        y = y[idx]
        uplot = uplot[idx]
        vplot = vplot[idx]
      endif else begin
        dprint,'All data values start outside of clipping range'
        nodraw = 1
      endelse
     
    endif
    
    if keyword_set(stopclip) || ~keyword_set(startclip) then begin

      ;clip u
      idx = where(x+uplot ge x_min and x+uplot le x_max)
    
      if idx[0] ne -1 then begin
        x = x[idx]
        y = y[idx]
        uplot = uplot[idx]
        vplot = vplot[idx]
      endif else begin
        dprint,'All data values stop outside of clipping range'
        nodraw = 1
      endelse
      
      ;clip v
      idx = where(y+vplot ge y_min and y+vplot le y_max)
    
      if idx[0] ne -1 then begin
        x = x[idx]
        y = y[idx]
        uplot = uplot[idx]
        vplot = vplot[idx]
      endif else begin
        dprint,'All data values stop outside of clipping range'
        nodraw = 1
      endelse
      
    endif
      
  endif
  
  idx = where(finite(x))
  
  if idx[0] eq -1 then begin
    dprint,'All input not finite'
    return
  endif else begin
    x=x[idx]
    y=y[idx]
    uplot = uplot[idx]
    vplot = vplot[idx]
  endelse
  
  idx = where(finite(y))
  
  if idx[0] eq -1 then begin
    dprint,'All input not finite'
    return
  endif else begin
    x=x[idx]
    y=y[idx]
    uplot = uplot[idx]
    vplot = vplot[idx]
  endelse
  
  idx = where(finite(uplot))
  
  if idx[0] eq -1 then begin
    dprint,'All input not finite'
    return
  endif else begin
    x=x[idx]
    y=y[idx]
    uplot = uplot[idx]
    vplot = vplot[idx]
  endelse
  
  idx = where(finite(vplot))
  
  if idx[0] eq -1 then begin
    dprint,'All input not finite'
    return
  endif else begin
    x=x[idx]
    y=y[idx]
    uplot = uplot[idx]
    vplot = vplot[idx]
  endelse
  
  if ~keyword_set(nodraw) then begin

    arrow,x,y,x+uplot,y+vplot,hsize=head_size,color=col,_extra=ex,/data
    
  endif
  
  makeunitarrow,dsize,ascale,isotropic,uarrowside,uarrowoffset,uarrowtext,hsize=head_size,color=col,_extra=ex

  if ~keyword_set(replot) then begin

     pxy_push_state,'plotxyvec',{xy:xy,dxy:dxy},noisotropic=noisotropic,addpanel=addpanel, $
              overplot=overplot,multi=multi,mmargin=mmargin,mtitle=mtitle,mpanel=mpanel,xrange=xrange,yrange=yrange,$
              xmargin=xmargin,ymargin=ymargin,grid=grid,uarrowside=uarrowside,$
              uarrowoffset=uarrowoffset,uarrowtext=uarrowtext,$
              uarrowdatasize=uarrowdatasize,arrowscale=arrowscale,hsize=hsize,$
              clip=clip,startclip=startclip,stopclip=stopclip,color=color,_extra=ex

  endif

end
