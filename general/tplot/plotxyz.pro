;+
; Procedure: plotxyz
;
; Purpose: Generates an isotropic spectrographic plot.  It takes one
; 2-d array(Z) and plots it using the values in 2 1-d arrays(X,Y) to
; scale the data in Z.  The X and Y axes can be any kind of data,
; most specifically the X axis need not be time.  By default the
; plots, are scaled isotropically.  Meaning that a unit on the x axis
; will have the same length on the screen as a unit on the z axis.
;
; The plots can be interleaved with plotxy/tplotxy plots in the same
; panel/window. Calling plotxyz with no arguments will redraw the
; entire window(including plotxy/tplotxy plots)
;
; The most significant restiction to this function is that it will
; clip any negative(or 0) data(in X,Y or Z) if you select a
; logarithmic axis.  
;
; If one scaling axis is set to logarithmic and the other is not,
; but the plot is set to isotropic, 1 power unit on the logarithmic
; axis will take up the same space on screen as one normal unit on
; the normal axis.  Despite the capability to perform these mixed 
; x,y log plots, this is not recommended...but feel free to experiment.
;
;
;************************************
;       Detailed explanation of Plot windows and panels:
;         /addpanel,/noisotropic and multi=
;
;         To put multiple panels in a window first call
;         plotxyz with the multi keyword.  It will either
;         plot in which ever window is your current one, or
;         create a new one if no window exists or if you 
;         request the use of a nonexistent window.
;
;         During this first call you may want to specify things
;         like wtitle,xsize,ysize,window...in addition to your normal
;         plotting options, setting these windowing options will
;         interfere with the creation of postscript
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
;         If you wish to add an overall title and/or margins to your multi panel 
;         window your first call should also specify mtitle and/or mmargin.        
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
;         previous panel without restarting.
;         It is possible use a panel out of sequence by setting mpanel.
;         mpanel also allows you to create non symmetric layouts by
;         creating plots that take up more than one panel.      
;
;         If you call plotxyz with no arguments it will redraw the
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
;           Information about plotting for plotxyz is stored in
;           the global variable !TPLOTXY, this includes
;           information about the layout of the plot window
;           which panel it is currently working on, and the 
;           sequence of commands used to generate current plot window
;           so that it can regenerate the plotwindow when called
;           with no arguments. This variable also stores information
;           used by the plotxy function so line plots 
;           can be interleaved with xyz spectrographic plots.
;
; Required Inputs:
;       x: 1-d array specifying the scaling/spacing of the x axis
;          This array must have the same number of elements as the
;          1st dimension of Z. One can think of the x coordinates of
;          the centers of the Z array data
;          
;
;       y: 1-d array specifying the scaling/spacing of the y axis
;          This array must have the same number of elements as the
;          2nd dimension of Z. One can think of the y coordinates of
;          the centers of the Z array data
;
;       z: 2-d array specifying the intensity of each element, or the
;          height of the z-axis.  This will be represented by color
;          in the 2-d plot this procedure generates.
;
; Optional keywords:
;             interpolate: set this argument if you want the data to
;             be interpolated between z data.  This will give the 
;             appearance of smooth gradations, although this may not
;             exist in the data.  If your Z data has blanks(NaNs),
;             interpolation can give inaccurate results near the blanks.
;             
;             noisotropic: set this argument if you don't want
;             the plot to be isotropic. If this is set the plot
;             will fill the entire space available to it, 
;             regardless of data scaling.
;             
;             xistime: Set this argument to use tplot-style time formatting
;             for x-axis labels.  
;  
;             xlog,ylog,zlog: set any of these to create logarithmic
;             scaling on the appropriate axis.  It is recommended,
;             but not required that if you set xlog on an isotropic
;             plot you also set ylog.
;
;             multi: as explained above set this to a string
;             indicating the desired number of columns and rows
;             in your window. This string can must contain 2 numbers
;             delimited by any common delimiter character or space.
;             the numbers may optionally be followed by an r to
;             indicate a reversal in the direction that the plots
;             will be added to the window.
;             
;             mmargin(can only be used if multi is also specified): 
;             set this keyword to a 4 element array specifying margins to be left
;             around a multipanel plot. Element order is bottom, left, top, right.
;             Margins are specified relative to the overall size of the window: 
;             0.0 is no margin, 1.0 is all margin. 
;             e.g. mmargin=[0.1,0.1,0.15.0.1]
;                    
;             mtitle(can only be used if multi is also specified):
;             set this keyword to a string to display as a title for a multi panel
;             plot window. This is displayed in addition to any titles specified for
;             individual panels.
;             If the top mmargin = 0, or has not been set then it will be set at 0.05
;             to allow room for the title. 
;             It is not possible to set your own font size for the mtitle. The size is
;             chosen so that as much as possible the title fits in the top margin and 
;             is not too long for the window. Setting a larger top mmargin will
;             increase the font size. NB: Size is fixed you are saving your plot
;             to a postscript. ] If you require more control over the title format
;             try leaving space using mmargin and adding your own text with idl 
;             procedure XYOUTS.
;         
;             mpanel(can only be used if multi is also specified):
;             set this keyword to a string to specify which panels in a multipanel window
;             to plot to. This allows you to create non symmetric plot layouts in a multi
;             panel window.
;             mpanel must contain two numbers separated by a comma (col, row) or two ranges
;             indicated with a colon, separated by a comma.
;             Panels are numbered starting at 0, from top to bottom and from
;             left to right. 
;                 e.g. mpanel = '0,1' will plot to panel in the first column,
;                       second row; 
;                      mpanel = '0:1,0' will create a plot that takes up both the first
;                       and second columns in the first row.
;             You cannot plot to a panel if that panel has already been used.
;             Panels in a window are normally filled from left to right, top to bottom. You
;             can use mpanel to place a plot out of this standard sequence.
; 
;             addpanel: set this keyword to make the procedure
;             move on to the next plot in window, if you have
;             previously set multi. If this is not set, it will
;             generate a new plot in a clear window, if this is
;             set and there are no more available spaces for 
;             plots an error will be generated.
;
;             memsave: To allow replotting of the data when the 
;             procedure is called with no arguments, the copies of
;             the data are stored in memory.  If memsave is set
;             these copies will not be saved and you will be unable
;             to replot with a 0 argument call.
;
;             xmargin,ymargin:  Set these keyword to a 2 element
;             array to set extra space around the plot.  Margins are
;             measured proportionally(from 0.0 to 1.0) and are
;             separate for each plot(not global to the entire window).
;             The arrays store the [left,right] xmargin or
;             [bottom,top] ymargin. Default xmargin for xyz plots is
;             [.15,.15] and ymargin is [.1,.075]. 
;          
;             xrange,yrange,zrange: Set these keywords to a 2 element
;             array to control the range of values to be displayed
;             for each axis.
;
;             title: set this to a string indicating the title at
;             the top of the plot
;
;             xtitle,ytitle,ztitle: set this to a string indicating
;             the title of the appropriate axis.
;
;             charsize: set this to a number to scale the character
;             size of writing on the plot.  1.0 is the default,
;             less than 1.0 decreases charsize, greater increases.
;
;             WARNING setting window, xsize, ysize or wtitle will 
;             interfere with the creation of postscript 
;
;             window: specify the window in which the plots should be
;             made. The default is the current window. If the window
;             number does not exist one will be made
;
;             xsize,ysize: Specify the number of pixels of the window you are
;             plotting in. This can be done ahead by the user if they
;             like, or just by stretching the window.
; 
;             wtitle: Specify the title for the bar at the top of the
;             window as a string.
;
;             noticks: set this if you do not want ticks on the plot
;                      (mutually exclusive with grid)
;             
;             grid: set this if you want a grid on your plot
;                       (mutually exclusive with noticks)
;                       Use xticks and yticks to manipulate the
;                       spacing of your grid 
;
;             markends: This keyword is deprecated.  You can use
;             all the normal options for plot to manipulate the 
;             position of the ticks on the axes. 
;             
;             xtick_get,ytick_get: These behave exactly as the plot
;             command versions, but they had to be identified explictly
;             to ensure they would be passed through correctly.
;
;             zticks: this acts like the normal x,y ticks option in
;             idl plots.  Set it to some number greater than 1 to set
;             the number of tick marks of the z axis. It is available
;             because draw color scale will sometimes supress all the
;             tick marks on the z axis.
;
;             ps_resolution: set the resolution, if you are using
;             postscript (default is 150 pts/cm)
;          
;             no_color_scale: Set to not draw the z-axis color scale
;             
;             get_plot_pos=get_plot_pos: Return the normalized position of your plot.
;             Output will be a 4-element array [x1,y1,,x2,y2] 
;             Where (x1,y1) is the lower-left corner of your plot and
;             (x2,y2) is the top right corner of your plot.
;              
;          
;             You can also use many normal plot options.
;
; NOTES:
;   All NaN's & INFs in the x and y axes will be removed from the data. All
;   NaN's in the z data will be replaced by the minimum value.
;
;   bin2d is VERY useful for preparing data for use in this routine
;   
;   Be very careful when manually setting the ticks.  While some options like [xy]ticks
;   are quite safe, others can inadvertently produce inaccurate labels as idl will sometimes
;   make assumptions about positioning of axes, by rounding off.  If you plan on using [xy]tickv,
;   or [xy]style be careful to verify that the axis labeling is working correctly.  This can best be done by
;   testing on a data set where the axes are irregularly spaced and where some of the values at the axes are
;   irrational.
;   
;
; SEE ALSO:
;    plotxy,tplotxy,thm_crib_tplotxy,thm_crib_plotxy,thm_crib_plotxyz,bin2d,
;    plotxylib,plotxyvec
; 
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2008-01-16 16:54:40 -0800 (Wed, 16 Jan 2008) $
; $LastChangedRevision: 2283 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/ssl_general/trunk/tplot/tplotxy.pro $
;-

;helper for the data processing routine
;code to clip the x and y axes
pro pxyz_dim_clip,zp,ap,r1,r2,an,bn,znans


  ;the cases below determine if the data intersects with
  ;the xrange provided and decides how to fill the space
  ;between the data and the ranges

  id = where(r1 le ap and r2 ge ap)

  ;this case handles one element x
  if an eq 1 or id[0] eq -1 then begin

     ap = [r1,r2]

     an = 2

     if id[0] ne -1 then begin
  
        zp = [zp,zp]

        znans = [znans,znans]

     endif else begin
        
        zp = dblarr(2,bn)

        znans = dblarr(2,bn)

        znans[*] = 1

     endelse

  endif else begin 

     ;if the lower range is outside the data, pad the edge with black
     if r1 lt ap[0] then begin

        ;decide where to place the boundary point
        ;this decision is essentially aesthetic
        ;it should determine how far the data will
        ;extend until it reaches the filler color
        if abs(ap[1]-ap[0]) lt abs(ap[0]-r1) then begin

           ap = [r1,ap[0]-abs(ap[1]-ap[0]),ap]

           zp = [dblarr(2,bn),zp]

           znans_fill = dblarr(2,bn)

           znans_fill[*] = 1

           znans = [znans_fill,znans]

           an+=2
           
        endif else begin

           ap = [r1,ap]

           zp = [dblarr(1,bn),zp]
           
           znans_fill = dblarr(1,bn)

           znans_fill[*] = 1

           znans = [znans_fill,znans]

           an+=1

        endelse

     ;if the lower range is within the data
     ;clip to the data edge and interpolate to the range
     ;marker
     endif else if r1 gt ap[0] then begin

        idx = where(ap gt r1)           

        zp_edge = zp[(idx[0]-1):idx[0],*]

        znans_edge = znans[(idx[0]-1):idx[0],*]

        interp_loc = r1-ap[idx[0]-1]/(ap[idx[0]]-ap[idx[0]-1])

        zp_interp = interpolate(zp_edge,interp_loc,dindgen(bn),/grid)

        znans_interp = interpolate(znans_edge,interp_loc,dindgen(bn),/grid)

        zp = [zp_interp,zp[idx,*]]

        znans = [znans_interp,znans[idx,*]]

        ap = [r1,ap[idx]]

        an = n_elements(ap)

     endif

        ;if the upper range is outside the
        ;data then pad the edge with black
     if r2 gt ap[an-1] then begin

           ;decide where to place the boundary point
           ;this decision is essentially aesthetic
           ;it should determine how far the data will
           ;extend until it reaches the filler color
        if abs(ap[an-1]-ap[an-2]) lt abs(r2 - ap[an-1]) then begin

           ap = [ap,ap[an-1]+abs(ap[an-1]-ap[an-2]),r2]

           zp = [zp,dblarr(2,bn)]

           znans_fill = dblarr(2,bn)

           znans_fill[*] = 1

           znans = [znans,znans_fill]

           an+=2

        endif else begin

           ap = [ap,r2]

           zp = [zp,dblarr(1,bn)]

           znans_fill = dblarr(1,bn)

           znans_fill[*] = 1

           znans = [znans,znans_fill]

           an+=1
           
        endelse

        ;if the lower range is within the data
        ;clip to the data edge and interpolate to the range
        ;marker           
     endif else if r2 lt ap[an-1] then begin
        
        idx = where(ap lt r2)           

        n = n_elements(idx)
           
        zp_edge = zp[idx[n-1]:(idx[n-1]+1),*]

        znans_edge = znans[idx[n-1]:(idx[n-1]+1),*]

        interp_loc = r2-ap[idx[n-1]]/(ap[idx[n-1]+1]-ap[idx[n-1]])

        zp_interp = interpolate(zp_edge,interp_loc,dindgen(bn),/grid)
        
        znans_interp = interpolate(znans_edge,interp_loc,dindgen(bn),/grid)

        zp = [zp[idx,*],zp_interp]

        znans = [znans[idx,*],znans_interp]

        ap = [ap[idx],r2]

        an = n_elements(ap)

     endif

  endelse

end

;do log processing for the x and y dims with this function
;for negative values, it replaces the values with -abs(log(value))
;all 0s are removed
pro pxyz_dim_log,zp,ap,range,znans

  zdims = size(zp,/dimensions)

  idx = where(ap gt 0)

  if idx[0] eq -1 then begin

     message,'entire logarithmic dimension is <= 0'

  endif else begin

     ap = ap[idx]
 
     ;may need to reset the range because low end got clipped by log
     if range[0] lt range[1] then begin
       range[0] = min(ap)
     endif else begin
       range[1] = min(ap)
     endelse
     
     ap = alog10(ap)
 
     zp = zp[idx,*]

     znans = znans[idx,*]

  endelse

end

pro pxyz_process_data,xp,yp,zp,xrange,yrange,zrange,xlog,ylog,zlog,znans

  zdims = size(zp,/dimensions)

  xn = n_elements(xp)

  yn = n_elements(yp)

  if size(xp,/n_dim) ne 1 || size(yp,/n_dim) ne 1 then begin
     message,'x and y must be 1 dimensional'
  endif

  if n_elements(zdims) ne 2 then begin
     message,'z must be 2 dimensional'
  endif
  
  if zdims[0] ne xn then begin

     message,'dim 1 of z must equal number of elements in x'

  endif

  if zdims[1] ne yn then begin

     message,'dim 2 of z must equal number of elements in y'

  endif

  ;make rules to allow single elements...

  ;process infinities and nans
  fn_x = where(finite(xp))

  if fn_x[0] eq -1 then begin

     message,'no finite values in x'

  endif

  fn_y = where(finite(yp))

  if fn_y[0] eq -1 then begin

     message,'no finite values in y'

  endif
  
  ;jury rigging some code to deal with NaNs
  ;since original code just code rid of them
  ;NaN locations with be tracked in separate data
  ;structure, all modifications to the zp structure will
  ;also occur to the NaN structure
  ;(Infinities are treated like NaNs, but if we wanted to
  ;treat them separately the code below would be where to 
  ;do it)

  xp = double(xp[fn_x])

  yp = double(yp[fn_y])

  zt = zp[fn_x,*]

  zp = double(zt[*,fn_y])

  fn_znf = where(~finite(zp))
  fn_zf = where(finite(zp))
  
  ;all locations where there are nans end up 1s others are 0
  znans = dblarr(size(zp,/dimensions))

  if fn_zf[0] eq -1 then begin
     zp[*] = 0
     znans[*] = 1
  endif else begin

     if fn_znf[0] ne -1 then begin

        zp[fn_znf] = min(zp[fn_zf])
        znans[fn_znf] = 1

     endif

  endelse

  ;sort data

  xs = bsort(xp)

  ys = bsort(yp)

  xp = xp[xs]

  yp = yp[ys]

  zp = zp[xs,*]

  zp = zp[*,ys]

  znans = znans[xs,*]
  znans = znans[*,ys]

  ;set ranges(by either lengthening or shortening)
  if keyword_set(xrange) then begin

     if n_elements(xrange) ne 2 then begin

        message,'xrange must have exactly 2 elements if set'

     endif

     ;the calculations below are made simpler
     ;if we perform them while the data is
     ;monotic and ascending then reverse
     ;according to ranges later
     if xrange[0] gt xrange[1] then begin
        
        xr1 = xrange[1]
        xr2 = xrange[0]

     endif else begin
 
        xr1 = xrange[0]
        xr2 = xrange[1]

     endelse

     pxyz_dim_clip,zp,xp,xr1,xr2,xn,yn,znans

     if xrange[0] gt xrange[1] then begin
        
        xp = reverse(xp)

        zp = reverse(zp,1)

        znans = reverse(znans,1)

     endif

  endif else begin
  
    xrange = [min(xp),max(xp)]
    
  endelse  

  ;set ranges(by either lengthening or shortening)
  if keyword_set(yrange) then begin

     if n_elements(yrange) ne 2 then begin

        message,'yrange must have exactly 2 elements if set'

     endif

     ;the calculations below are made simpler
     ;if we perform them while the data is
     ;monotic and ascending then reverse
     ;according to ranges later
     if yrange[0] gt yrange[1] then begin
        
        yr1 = yrange[1]
        yr2 = yrange[0]

     endif else begin
 
        yr1 = yrange[0]
        yr2 = yrange[1]

     endelse

     ;to simplfy concatenations along the y dimension
     ;calculations will be done with a transposed z
     ;this means the clipping code for
     ;the x and y axes is now symmetric
     zp = transpose(zp)

     znans = transpose(znans)

     pxyz_dim_clip,zp,yp,yr1,yr2,yn,xn,znans

     zp = transpose(zp)

     znans = transpose(znans)

     if yrange[0] gt yrange[1] then begin
        
        yp = reverse(yp)

        zp = reverse(zp,2)

        znans = reverse(znans,2)

     endif

  endif else begin
  
    yrange = [min(yp),max(yp)]
    
  endelse

     ;handle zrange...
     ;clipping and reversal

     ;should clipped z data be filled with???
     ;filler or should it be max = to max???
     ;and min???

  if keyword_set(zrange) then begin

     if n_elements(zrange) ne 2 then begin

        message,'zrange must have exactly 2 elements if set'

     endif
     
     ;the calculations below are made simpler
     ;if we perform them while the data is
     ;monotic and ascending then reverse
     ;according to ranges later
     if zrange[0] gt zrange[1] then begin
        
        zr1 = zrange[1]
        zr2 = zrange[0]

     endif else begin
 
        zr1 = zrange[0]
        zr2 = zrange[1]

     endelse

     idx = where(zp lt zr1)

     if idx[0] ne -1 then begin

        zp[idx] = zr1

     endif
     
     idx = where(zp gt zr2)

     if idx[0] ne -1 then begin

        zp[idx] = zr2

     endif

     if zrange[0] gt zrange[1] then begin
     
        maxz = max(zp,min=minz)

        zp = minz + maxz - zp

     endif

  endif else begin
  
    zrange = [min(zp),max(zp)]
    
  endelse

  ;perform logarithms
  if keyword_set(xlog) then begin

     pxyz_dim_log,zp,xp,xrange,znans

  endif

  if keyword_set(ylog) then begin

     zp = transpose(zp)

     znans = transpose(znans)

     pxyz_dim_log,zp,yp,yrange,znans

     zp = transpose(zp)

     znans = transpose(znans)

  endif

  if keyword_set(zlog) then begin

    idx = where(zp le 0)
    idx2 = where(zp gt 0)

    if idx2[0] eq -1 then begin
       message,'all values in logarthimic z dimension are <= 0'
    endif

    if idx[0] ne -1 then begin
      
       dprint,'some values are <= 0 and are being removed'
     
       mn = min(zp[idx2])
         
       zp[idx] = mn
       znans[idx] = 1
       
       if zrange[0] lt zrange[1] then begin
         zrange[0] = mn
       endif else begin
         zrange[1] = mn
       endelse
         
    endif
    
    zp = alog10(zp)

  endif  

end

;this function tricks the interpolate function in idl
;to generate a grid of points for output with tv
function pxyz_grid,x,y,z,pixx,pixy,interp,znans,zrange

  compile_opt hidden,idl2

  xi = x
  yi = y

  xn = n_elements(xi)
  yn = n_elements(yi)

  if pixx lt 1. then begin
     message,'x dimension soooo small that plot is less than 1 pixel wide(You may want to consider setting /noiso keyword)'
  endif

  if pixy lt 1. then begin
     message,'y dimension soooo small that plot is less than 1 pixel high(You may want to consider setting /noiso keyword)'
  endif

  ;the proportional positions on the x-axis
  xi = (xi - xi[0])/(xi[xn-1]-xi[0])

  ;the positions to interpolate to on the x axis
  xpos = interpol(dindgen(xn),xi,dindgen(pixx)/pixx)

  ;the proportional positions on the y-axis
  yi = (yi - yi[0])/(yi[yn-1]-yi[0])

  ypos = interpol(dindgen(yn),yi,dindgen(pixy)/pixy)

  if ~keyword_set(interp) then begin

    xpos = round(xpos)

    ypos = round(ypos)

  endif

  z = bytscl(z,top=247,min=zrange[0],max=zrange[1])+7

  outz = floor(interpolate(z,xpos,ypos,/grid),/l64)
   
  outnulls = interpolate(znans,round(xpos,/l64),round(ypos,/l64),/grid)

  idx = where(outnulls eq 1.0)

  if idx[0] ne -1 then begin

     outz[idx] = !P.background

  endif

  ;grid the points and scale them into the range of color indices
  ;return, floor(interpolate(z,xpos,ypos,/grid))
  return,outz

end

;data must be processed as follows
;dimensions are already clipped and ordered
;pos of panel calculated
;all inputs are assigned
;values are logarithm'd(if requested)
;nans are reassigned to a default
pro pxyz_make_spec,x,y,z,pos,interp,znans,ps_resolution,zrange,zlog

  compile_opt hidden,idl2

  x_p_sz = pos[2]-pos[0]

  y_p_sz = pos[3]-pos[1]
  
  if keyword_set(zlog) then begin
    if zrange[0] le 0 || zrange[1] le 0 then begin
      message,'Logarithmic Z-range cannot contain values 0 or less'
    endif
    zr = alog10(zrange)
  endif else begin
    zr = zrange
  endelse

  if(!D.name eq 'PS') then begin
   
     ps_sz_x_cm = !D.x_size/!D.X_PX_CM

     ps_sz_y_cm = !D.y_size/!D.Y_PX_CM

     x_p_sz_cm = x_p_sz* ps_sz_x_cm

     y_p_sz_cm = y_p_sz* ps_sz_y_cm

     x_p_off_cm = pos[0]*ps_sz_x_cm

     y_p_off_cm = pos[1]*ps_sz_y_cm

     image = pxyz_grid(x,y,z,x_p_sz_cm*ps_resolution,y_p_sz_cm*ps_resolution,interp,znans,zr)

     tv,image,x_p_off_cm,y_p_off_cm,/CENTIMETERS,xsize=x_p_sz_cm,ysize=y_p_sz_cm

  endif else begin

     pxx = x_p_sz * !D.x_size
     
     pxy = y_p_sz * !D.y_size

     image = pxyz_grid(x,y,z,pxx,pxy,interp,znans,zr)

     tv,image,pos[0],pos[1],/normal

  endelse

  ;isotropic plot will often leave blank space in the plot area
  
end

;makes the labels for the plot since tv doesn't
pro pxyz_make_labels,xrange,yrange,zrange,pos,xlog,$
  ylog,zlog,charsize,xtitle,ytitle,ztitle,title,noticks,$
  grid,markends,zticks,xtick_get,ytick_get,xstyle=xstyle,$
  ystyle=ystyle,xistime=xistime,$
  no_color_scale=no_color_scale,$
  _extra=_extra

  compile_opt hidden,idl2

  x = dindgen(100)/99 * (xrange[1]-xrange[0]) + yrange[0]

  y = dindgen(100)/99 * (yrange[1]-yrange[0]) + yrange[0]
  
  if keyword_set(noticks) && keyword_set(grid) then begin
     message,'grid and noticks are mutually exclusive'
  endif

  if keyword_set(noticks) then begin
     ticklen=0
  endif

  if keyword_set(grid) then begin
     ticklen = 1.0
  endif

  if ~keyword_set(xstyle) then begin
    xstyle=1
  endif
  
  if ~keyword_set(ystyle) then begin
    ystyle=1
  endif
  
  if ~keyword_set(xtitle) then begin
    xtitle =''
  endif

  ;This option ay produce unreliable results so it has been disabled
  ;The user should be able to perform this operation manually if needed
  ;if keyword_set(markends) then begin
  if keyword_set(markends) then begin
    dprint,'Option: markends has been deprecated, you can control the placement of ticks using all the standard commands from plot.'
  endif

   ;merge xstyle into setting struct(since it is passed to this routine explicitly)
   extract_tags,_extra,{xstyle:xstyle,xrange:xrange}

   if keyword_set(xistime) then begin
     x_time_setup = time_ticks(xrange,xtitle=xtitle)
     extract_tags,_extra,x_time_setup,/preserve ;merge time_settings into other settings
   endif else begin
     extract_tags,_extra,{xtitle:xtitle}  
   endelse
   
   ;keyword xstyle,ystyle=1.0  is needed to control exact positioning of the axes. 
   ;Otherwise the spectrographic image and the ploted axes may not coincide
   plot,x,y,xlog=xlog,ylog=ylog,ticklen=ticklen,/normal,/noclip,position=pos,yrange=yrange,ystyle=ystyle,$
    charsize=charsize,/noerase,/nodata,ytitle=ytitle,title=title,xtick_get=xtick_get,ytick_get=ytick_get,_extra=_extra
        
  p = pos
  
  p[0] = pos[2] + (pos[2]-pos[0])*.05
  
  p[2] = pos[2] + (pos[2]-pos[0])*.1
  
  str_element,_extra,'zposition',zposition
  str_element,_extra,'zoffset',zoffset
  str_element,_extra,'zminor',zminor
  str_element,_extra,'zgridstyle',zgridstyle
  str_element,_extra,'zthick',zthick
  str_element,_extra,'ztickformat',ztickformat
  str_element,_extra,'ztickinterval',ztickinterval
  str_element,_extra,'zticklayout',zticklayout
  str_element,_extra,'zticklen',zticklen
  str_element,_extra,'ztickname',ztickname
  str_element,_extra,'ztickunits',ztickunits
  str_element,_extra,'ztickv',ztickv
  
  if keyword_set(zposition) then begin
    p=zposition
  endif
  
  if ~keyword_set(no_color_scale) then begin
    draw_color_scale,range=zrange,log=zlog,charsize=charsize,position=p,title=ztitle,yticks=zticks,brange=[7,254],$
      offset=zoffset,ygridstyle=zgridstyle,yminor=zminor,ythick=zthick,ytickformat=ztickformat,ytickinternal=ztickinterval,$
      yticklayout=zticklayout,yticklen=zticklen,ytickname=ztickname,ytickunits=ztickunits,ytickv=ztickv,ytitle=ztitle
      
  endif

  return

end

pro plotxyz,x,y,z,interpolate=interpolate,noisotropic=noisotropic,xlog=xlog,ylog=ylog,zlog=zlog,addpanel=addpanel,$
            multi=multi,mmargin=mmargin,mtitle=mtitle,mpanel=mpanel,memsave=memsave,xmargin=xmargin,ymargin=ymargin,xrange=xrange,yrange=yrange,zrange=zrange,$
            title=title,xtitle=xtitle,ytitle=ytitle,ztitle=ztitle,charsize=charsize,window=window,xsize=xsize,$
            ysize=ysize,wtitle=wtitle,replot=replot,noticks=noticks,grid=grid,markends=markends,zticks=zticks,$
            ps_resolution=ps_resolution,xtick_get=xtick_get,ytick_get=ytick_get,no_color_scale=no_color_scale,$
            get_plot_pos=get_plot_pos,_extra=_extra

  compile_opt idl2

  plotxylib


  if undefined(x) and undefined(y) and undefined(z) then begin
     pxy_replot
    
     return

  endif
  
  pxy_set_window,overplot,addpanel,replot,window,xsize,ysize,wtitle,multi,mmargin,mtitle,noisotropic,isotropic=isotropic

  if ~keyword_set(ps_resolution) then begin
     ps_resolution = 150
  endif

 ;the process data function
 ;mutates these variables
 ;so these are stored for use 
 ;in the state push... 
 ;and to prevent mutation
 ;of variables in parent env


  if undefined(x) || undefined(y) || undefined(z) then begin
     message,'x y & z must be set'
  endif

  xs = double(x)
  ys = double(y)
  zs = double(z)

  if keyword_set(xrange) then begin
     xr = xrange
  endif

  if keyword_set(yrange) then begin
     yr = yrange
  endif

  if keyword_set(zrange) then begin
     zr = zrange
  endif

  ;clear
  if ~keyword_set(addpanel) then begin
  
    plot,[1],[1],/nodata,color=!P.background
  
  endif
  if (keyword_set(multi) and keyword_set(mtitle)) then begin
    pxy_make_title
  endif

  pxyz_process_data,xs,ys,zs,xr,yr,zr,xlog,ylog,zlog,znans

  pos = pxy_get_pos([min(xs),max(xs)],[min(ys),max(ys)],isotropic,xmargin,ymargin,mpanel)

  ;isotropic calculation
  ;generate plot
  
  pxyz_make_spec,xs,ys,zs,pos,interpolate,znans,ps_resolution,zr,zlog
  
  pxyz_make_labels,xr,yr,zr,pos,xlog,ylog,zlog,charsize,xtitle,ytitle,ztitle,title,noticks,grid,markends,zticks,xtick_get,ytick_get,no_color_scale=no_color_scale,_extra=_extra
  
  if arg_present(get_plot_pos) then begin
    get_plot_pos=pos
  endif
  

 ;state push is called last
 ;to ensure that only successful
 ;plot operations are stored

  if ~keyword_set(replot) then begin

     pxy_push_state,'plotxyz',{x:x,y:y,z:z},interpolate=interpolate,noisotropic=noisotropic,xlog=xlog,ylog=ylog,zlog=zlog,$
                     addpanel=addpanel,multi=multi,mmargin=mmargin,mtitle=mtitle,mpanel=mpanel,memsave=memsave,xmargin=xmargin,ymargin=ymargin,xrange=xrange,$
                     yrange=yrange,zrange=zrange,title=title,xtitle=xtitle,ytitle=ytitle,ztitle=ztitle,$
                     charsize=charsize,noticks=noticks,grid=grid,markends=markends,zticks=zticks,ps_resolution=ps_resolution,$
                     xtick_get=xtick_get,ytick_get=ytick_get,_extra=_extra

  endif

end
