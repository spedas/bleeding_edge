;+
; Procedure: plotxy
;
; Purpose: Takes an array of 3-d(Nx3) vectors or tplot variable
;          and plots them using 2-d plots to help visualize them. 
;          It can also take an MxNx3 array tplot variable storing 
;          an MxNx3 array which represents a set of M lines with N
;          points 
;
;         Can also accept an Nx2 or an MxNx2 element array...if this
;         is done the versus argument should not use a custom
;         designation or the z-axis, as it assumes 2-d vectors are in
;         the x-y plane, and thus will distort the vectors upon projection.
;
;          
;         plotxy/tplotxy plots can be interleaved on the same window
;         with plotxyz & plotxyvec plots
;
;         Calling tplotxy with no arguments to redraw the entire
;         window(including plotxyz,plotxyvec plots)
;
;         ***************************************************
;
;         Using custom axes:  If you use two vectors to define custom
;         axes, the procedure will generate a plot of the data vectors
;         projected into a plane defined by the span of the two custom
;         vectors.  The x-axis will be the first vector, the y axis
;         will be the second vector.  This means that if the custom
;         vectors are not orthogonal the plot will show a distortion.
;         You can think of this as plotting along a plane that slices
;         though the 3-d space.
; 
;         ********************************
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
;         An entire plot window is filled in sequence, if you move
;         on to a new window you will not be able to go back to the
;         previous panel without restarting.
;         It is possible use a panel out of sequence by setting mpanel.
;         mpanel also allows you to create non symmetric layouts by
;         creating plots that take up more than one panel.
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
;
;Example: a = [[dindgen(10)],[dindgen(10)],[dindgen(10)]]
;         get_data,'thb_state_pos',data=d
;         dat=d.y
;         plotxy
;         plotxy,a
;         plotxy,a,versus='yzr'
;         plotxy,dat,versus='cc',custom=transpose([[1,1,0],[0,0,1]])
;         plotxy,dat,versus='xryz',xrange=[0,10],yrange=[0,10]
;
;Note: Recommend using the keyword /noiso if you're wondering why your plot has a weird aspect ratio.
;
; Inputs: vectors(optional): an Nx3,MxNx3,Nx2, or MxNx2 list
;
; Keywords:
;
;         versus(optional): specify the projection to be used, can be
;         'xx','xy','xz','yx','yy','yz','zx','zy','zz','cc' you can also
;         follow a letter with an 'r' to reverse the axis(goes from
;         positive to negative instead of from negative to positive) 
;         if you specify 'cc','crc'...that indicate you want to use a
;         custom projection
;         example: 'xry' will be an xy plot with the maximum x value
;         listed on the left and the minimum on the right 
;         (default:'xy')
;
;         custom(optional): set this variable to a
;         2x3 matrix whose columns define a plane in 3-d space, to define a
;         custom projection. In other words the 2-d plot will be a
;         plot of the vectors passed into plotxy when they are
;         projected into a plane defined by
;         span(custom[0,*],custom[1,*]). (span is defined as the set
;         of all the linear combinations of two vectors, or 
;         span(x,y) = {mx+ny:m = element of the reals, n = element of
;         the reals} The vectors used to define this plane will be
;         relative to whatever 3-d coordinate system the input vector
;         data is in.
;         So if the call:
;         tplotxy,'somedata',versus='cc',custom=transpose([[1,1,0],[0,0,1])
;         is made, the plot generated will be of the vectors closest
;         to the data vectors that are inside a vertical plane whose
;         intersection with the x-y plane forms a line y=x.
;         tplotxy,'somedata',versus='cc',custom=transpose([[1,0,0],[0,1,0])
;         is effectively the same as:
;         tplotxy,'somedata',versus='xy'
;  
;         overplot(optional): set this keyword if you want to plot
;         on the last plot and panel that you plotted on
;
;         addpanel(optional): set this keyword if you want to plot on a new
;         panel within the same plot window as where you last
;         plotted. This will go to the next column first and if it is
;         at the end of a row, to the next row.
;
;         multi(optional): set this keyword to a string that 
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
;         mmargin(optional, can only be used if multi is also specified): 
;         set this keyword to a 4 element array specifying margins to be left
;         around a multipanel plot. Element order is bottom, left, top, right.
;         Margins are specified relative to the overall size of the window: 
;         0.0 is no margin, 1.0 is all margin. 
;             e.g. mmargin=[0.1,0.1,0.15.0.1]
;                    
;         mtitle(optional, can only be used if multi is also specified):
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
;         mpanel(optional, can only be used if multi is also specified):
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
;         noisotropic(optional): set this keyword if you don't want the
;         scaling of both axes to be the same and the space to
;         be perspective corrected so that a cm of y unit takes
;         up the same space on the screen as a cm of x unit
;         
;         xistime(optional): set this keyword if you want to treat the x-axis
;         as a time axis and use tplot-style time labels
;
;         memsave(optional): set this keyword to request command
;         copies not be saved and redraws be done without maintaining
;         square isotropic plots.  Setting this option can potentially
;         save quite a lot of memory.
;
;         linestyle(optional):set this to change the linestyle used
;         0 = default,1=dotted=,2=dashed,3=dash dot,4=dash dot
;         dot,5=long dashes
;
;         xrange(optional): set this to a 2 element array to specify
;         the min and max for the first axis(x) of the 2-d plot
;
;         yrange(optional): set this to a 2 element array to specify
;         the min and max for the second axis(y) of the 2-d plot
;
;         pstart(optional): set this keyword to a number representing
;         the symbol you would like to start lines with. (This works
;         like the idl psym keyword, but only for the first symbol
;         in a line being plotted)
;       
;         startsymcolor(optional): Set this keyword to a color table number
;         or letter(e.g. 'm') to control the color of the pstart symbol separately
;         from the color= keyword
;
;         pstop(optional): set this keyword to a number representing
;         the symbol you would like to end lines with. (This works
;         like the idl psym keyword, but only for the last symbol
;         in a line being plotted)
;
;;        stopsymcolor(optional): Set this keyword to a color table number
;         or letter(e.g. 'm') to control the color of the pstop symbol separately
;         from the color= keyword
;
;         psym(optional): use this to plot the line using a symbol
;         rather than a line.
;
;         symsize(optional): specify the size of the start and end
;         symbol or psym. (default:1.0)
;
;         WARNING: setting any of the 4 windowing options below
;         will interfere with postscripts
;
;         window(optional):specify the window for
;         output, if overplot is not specified, it will
;         always recreate the window so it can attempt to make
;         the window square (default:current)
;
;         xsize(optional):specify the xsize of the window in
;         pixels(default: current)
;
;         ysize(optional):specify the ysize of the window in pixels
;         (default: current)
;
;         wtitle(optional):the title you would like the window to have
;
;         colors(optional): if vectors in Nx3 colors should contain a
;         single element(name like 'r' or index like 2), if vectors is
;         an MxNx3 then it can contain a single element or M elements
;
;         xmargin(optional): set this option to a two element array
;         specifing the size of the margin of the current panel
;         relative to the size of overall panel on the x dimension.
;         Values range from 0.0(no margin) to 1.0(all margin)
;         The first element of the array is the left margin
;         The second element is the right margin
;
;         ymargin(optional): set this option to a two element array
;         specifing the size of the margin of the current panel
;         relative to the size of overall panel on the y dimension.
;         Values range from 0.0(no margin) to 1.0(all margin)
;         The first element of the array is the bottom margin and
;         The second element of the array is the top margin
;
;         xlog(optional): set the x scale to be logarithmic
;
;         ylog(optional): set the y scale to be logarithmic
;
;         xtitle(optional): set the xtitle for the plot
;
;         ytitle(optional): set the ytitle for the plot
;
;         grid(optional): set this to 1 to have the procedure
;         generate a grid rather than normal tickmarks
;
;         units(optional): set this if you want this unit label
;         appended to both axis titles.(This will be ignored if 
;         you set the xtitle or ytitle explictly) 
;
;         labels(optional): set this if you want to use the axis
;         labels array from limits/dlimits of a tvar.(This will be 
;         ignored if you set the xtitle or ytitle explictly) 
;
;;        markends: This keyword is deprecated.  You can use
;         all the normal options for plot to manipulate the 
;         position of the ticks on the axes. 
; 
;         xtick_get,ytick_get: These behave exactly as the plot
;         command versions, but they had to be identified explictly
;         to ensure they would be passed through correctly.
;             
;         replot(internal): this option is used in recursive calls
;         by the routine to itself and should never be set by the
;         user  
;       
;         This function also takes normal idl keywords that effect
;         plotting style(things like xtitle,ytitle....etc..)
;         
;         get_plot_pos=get_plot_pos: Return the normalized position of your plot.
;             Output will be a 4-element array [x1,y1,,x2,y2]
;             Where (x1,y1) is the lower-left corner of your plot and
;             (x2,y2) is the top right corner of your plot.
;
;  SEE ALSO:
;    plotxyz,tplotxy,thm_crib_tplotxy,thm_crib_plotxy,thm_crib_plotxyz
;    plotxylib,plotxyvec
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2008-01-16 16:54:40 -0800 (Wed, 16 Jan 2008) $
; $LastChangedRevision: 2283 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/ssl_general/trunk/tplot/tplotxy.pro $
;-

;HELPER FUNCTION
;takes a matrix whose columns define a plane
;and an Nx3 series of points
;returns an Nx2 series of points generated by projecting x into a
function p3p_project, a, x

compile_opt hidden, idl2

dims = size(x, /dimensions)

out = make_array(dims[0], 2, /double, value = !values.d_nan)

idx1 = where(finite(x[*, 0]))
idx2 = where(finite(x[*, 1]))
idx3 = where(finite(x[*, 2]))

;if NaN's are not distributed symmetrically among x,y,z
;intersection is calculated, to identify vectors that contain no NaNs
idxt = ssl_set_intersection(idx1, idx2)

idxt = ssl_set_intersection(idx3, idxt)

;if there are no vectors that contain no NaNs return a vector of all NaNs
if idxt[0] eq -1 then return, out

;calculate the matrix that will project into specified plane
p = invert(transpose(a) ## a) ## transpose(a)

;perform projection
vals = p ## x[idxt, *]

out[idxt, *] = vals

return, out

end

;HELPER FUNCTION
;takes a plot axis string and gets the elements corresponding to the
;letter in the string,passes back the requested axis in ele, the
;default title, whether there was an error, and whether axis reversal
;was requested
pro p3p_parse_elements,string, element, vectors, custom, ele = ele, title = title, error = error,$
                       reverse = reverse, unit=unit, label=label,dimtitle = dimtitle

  compile_opt hidden,idl2

  error = 1

  reverse = 0

  dimtitle = ''

  if(element eq 1) then begin

    char = strmid(string, 0, 1)
    if strmid(string, 1, 1) eq 'r' then reverse = 1

  endif else if element eq 2 then begin

    len = strlen(string)
    char = strmid(string, len-1, 1)

    if(char eq 'r') then begin
      reverse = 1
      char = strmid(string, len-2, 1)
    endif

  endif

  title = string

  if(char eq 'x') then begin 
     ele = vectors[*, *, 0] 

     if keyword_set(label) && n_elements(label) eq 3 then begin
        dimtitle = label[0]
     endif else begin
        dimtitle = 'X'
     endelse

  endif else if(char eq 'y') then begin 
    ele = vectors[*, *, 1] 
  
    if keyword_set(label) && n_elements(label) eq 3 then begin
       dimtitle = label[1]
    endif else begin
       dimtitle = 'Y'
    endelse


  endif else if(char eq 'z') then begin 
    ele = vectors[*, *, 2] 
  
    if keyword_set(label)  && n_elements(label) eq 3 then begin
       dimtitle = label[2]
    endif else begin
       dimtitle = 'Z'
    endelse


  endif else if(char eq 'c') then begin
    
    if not keyword_set(custom) then begin
      dprint, 'custom axes not set where custom axes specified'
      return
    endif

    dims =  size(vectors, /dimensions)

    ele = dblarr(dims[0], dims[1])
    
    for i = 0, dims[0]-1 do begin

      vs = p3p_project(custom, reform(vectors[i, *, *]))

      ele[i, *] = reform(vs[*, element-1])

    endfor

    title = strcompress('[' + strjoin(reform(string(custom[0, *])), ',') + $
            '] vs!C[' +  strjoin(reform(string(custom[1, *])), ',') + ']')

    dimtitle = strcompress('[' +  strjoin(reform(string(custom[element-1, *])), ',') + ']')

  endif else begin 
    dprint, 'Illegal plot axis string passed to plot3project'
    return
  endelse

  if keyword_set(unit) then begin
    dimtitle += ' ' + unit
  endif   


  error = 0

  return

 end

;main function
pro plotxy, vectors, versus=versus, symsize=symsize, custom = custom,title=title,overplot=overplot,$
 addpanel=addpanel,multi=multi,mmargin=mmargin,mtitle=mtitle,mpanel=mpanel,memsave=memsave,noisotropic=noisotropic,linestyle=linestyle, xrange = xrange,$
 yrange = yrange, pstart=pstart,pstop=pstop, startsymcolor=startsymcolor,stopsymcolor=stopsymcolor, window = window, xsize = xsize, ysize = ysize, xmargin = xmargin, ymargin = ymargin,$
 wtitle=wtitle,xtitle=xtitle,ytitle=ytitle,colors=colors,replot=replot,xlog=xlog,ylog=ylog,units=units,labels=labels, $
 grid=grid,markends=markends,marks=marks,xtick_get=xtick_get,ytick_get=ytick_get,xistime=xistime,$
 get_plot_pos=get_plot_pos,_extra = _extra

compile_opt idl2

plotxylib

;adds a margin
;plotsize = 1.0D/8.0D

;set defaults and check some input invariants
if ~keyword_set(symsize) then symsize=1.0D

if ~keyword_set(versus) then versus = 'xy'

if keyword_set(xrange) && n_elements(xrange) ne 2 then message, 'xrange must have two elements'

if keyword_set(yrange) && n_elements(yrange) ne 2 then message, 'yrange must have two elements'

if keyword_set(overplot) && keyword_set(addpanel) then begin

   message,'cannot set addpanel and overplot at the same time'

endif
if keyword_set(overplot) && keyword_set(mpanel) then begin
    message, 'cannot set overplot and mpanel at the same time: overplot can only overlay a plot over the last panel used'
endif

if keyword_set(noisotropic) then begin
  isotropic = 0
endif else begin
  isotropic = 1
endelse

if keyword_set(marks) then begin
  dprint,'marks keyword has been replaced. please use pstart/pstop keywords instead'
endif  

;replot call
if ~keyword_set(vectors) then begin

   pxy_replot

   return

endif

;first call, do general setup stuff

pxy_set_window,overplot,addpanel,replot,window,xsize,ysize,wtitle,multi,mmargin,mtitle,noisotropic,isotropic=isotropic
   
if(size(vectors, /type) eq 7) then $
   message,'cannot take a string argument, use tplotxy instead' $
else $
   vecs=double(vectors)

dims = size(vecs, /dimensions)

if(n_elements(dims) ne 2 && n_elements(dims) ne 3) then message, 'vector argument must be a 2 or 3 dimensional array'

;if a list of 2-d points is passed in turn it into
;a list of 3-d points so all cases can be handled using the same code
if(dims[n_elements(dims)-1]) eq 2 then begin
   dims[n_elements(dims)-1] = 3
   temp = dblarr(dims)

   if(n_elements(dims) eq 2) then begin
      temp[*,0] = vecs[*,0]
      temp[*,1] = vecs[*,1]
   endif else begin
      temp[*,*,0] = vecs[*,*,0]
      temp[*,*,1] = vecs[*,*,1]
   endelse

   vecs = temp
endif

;if(dims[n_elements(dims)-1] ne 3) then message, 'last dimension of vector argument must be size 3'

;if a 2-d argument is passed, make it 3-d so all cases can be handled
;using the same code
if(n_elements(dims) eq 2) then vecs = reform(vecs, [1, dims])

;get the axes as requested using the versus and custom arguments
if not keyword_set(title) then $
  p3p_parse_elements, versus, 1, vecs, custom, ele = ele1, title = title, error = error, reverse = rev1, unit=units, label=labels,dimtitle = dt $
 else $
  p3p_parse_elements, versus, 1, vecs, custom, ele = ele1, error = error, reverse = rev1, unit=units, label=labels,dimtitle = dt

if not keyword_set(xtitle) then begin
   
      xtitle = dt

endif


dt = 0

if error then return 
  
p3p_parse_elements, versus, 2, vecs, custom, ele = ele2, error = error, reverse = rev2, unit=units, label=labels,dimtitle = dt

if not keyword_set(ytitle) then begin
   
      ytitle = dt

endif

if error then return 

;either set range automatically or manually
if keyword_set(xrange) then begin
  
   min_x = xrange[0]
   max_x = xrange[1]
  
   if(min_x gt max_x) then begin
      message,'Illegal x range, min gt max'
   endif

endif else begin
  
   max_x = max(ele1,/nan)
   min_x = min(ele1,/nan)

endelse

if keyword_set(yrange) then begin
  
   min_y = yrange[0]
   max_y = yrange[1]
  
endif else begin

   max_y = max(ele2,/nan)
   min_y = min(ele2,/nan)

   if(min_y gt max_y) then begin
      message,'Illegal y range, min gt max'
   endif
   
endelse

;switch min and max if reversal of axis was requested
if rev1 then begin
   t = min_x
   min_x = max_x
   max_x = t
endif

if rev2 then begin
   t = min_y
   min_y = max_y
   max_y = t
endif

dims = size(ele1, /dimensions)

if keyword_set(colors) then $
   if n_elements(colors) ne dims[0] then begin
   if n_elements(colors) ne 1 then $
      message,'number of colors does not match number of dimensions' $
   else $
      cols = replicate(get_colors(colors),dims[0]) 
endif else $
   cols = get_colors(colors)
  
if keyword_set(addpanel) then begin

   noerase=1

endif

;create blank plot
if ~keyword_set(overplot) then begin

   pos = pxy_get_pos([min_x,max_x],[min_y,max_y],isotropic,xmargin,ymargin,mpanel)

   if keyword_set(grid) then begin
      ticklen = 1.0
   endif
      
   if keyword_set(markends) then begin
     dprint,'Option: markends is deprecated, you can control the placement of ticks using all the standard commands from plot.'
   endif
   
   if is_struct(_extra) then begin
     _extra_plot=_extra
   endif
   
   ;xrange is now sent to plot through _extra
   ;helps make it so we can use time_ticks
   ;but since this mutates _extra, we need to use a copy(so we correctly preserve replotting) 
   extract_tags,_extra_plot,{xrange:[min_x,max_x]} 
   
   if keyword_set(xistime) then begin
      x_time_setup = time_ticks([min_x,max_x],x_time_offset,xtitle=xtitle)
      x_time_setup.xtickv+=x_time_offset
      extract_tags,_extra_plot,x_time_setup,/preserve ;merge time_settings into other settings
   endif
      
   plot,[min_x,max_x],[min_y,max_y],yrange=[min_y,max_y],title=title,xtitle=xtitle,ytitle=ytitle, pos=pos,$
           _extra = _extra_plot,/nodata,noerase=noerase,xlog=xlog,ylog=ylog,isotropic=0,ticklen=ticklen,xstyle=1,ystyle=1,xtick_get=xtick_get,$
           ytick_get=ytick_get
           
   if arg_present(get_plot_pos) then begin
     get_plot_pos=pos
   endif       


endif
if (keyword_set(multi) and keyword_set(mtitle)) then begin
    pxy_make_title
endif

for i = 0, dims[0]-1 do begin

;identify NaNs
   plot1 = reform(ele1[i, *])

   idx1 = where(finite(plot1))
    
   plot2 = reform(ele2[i, *])
   
   idx2 = where(finite(plot2))
    
   idxt = ssl_set_intersection(idx1, idx2)

   if(idxt[0] eq -1) then begin 
      dprint, 'cannot plot an line composed entirely of NaNs, skipping line'
    
      continue
   endif

;filter NaNs
   plot1 = plot1[idxt]
    
   plot2 = plot2[idxt]

   if keyword_set(cols) then begin
     co = cols[i]
   endif

   oplot, plot1, plot2, linestyle = linestyle,color=co,symsize=symsize, _extra = _extra
     
   
   if keyword_set(pstart) then begin

     if undefined(startsymcolor) then begin
       if ~undefined(cols) then begin
         pstartco=cols[i]
       endif
     endif else begin
       pstartco = get_colors(startsymcolor)
     endelse

      ;mark start
      oplot, make_array(1, value = plot1[0]), make_array(1, value = plot2[0]), psym = pstart, symsize = symsize,color=pstartco

   endif
   
   if keyword_set(pstop) then begin
        
    if undefined(stopsymcolor) then begin
      if ~undefined(cols) then begin
        pstopco=cols[i]
      endif
    endif else begin
      pstopco = get_colors(stopsymcolor)
    endelse


    ;mark stop
    oplot, make_array(1, value = plot1[n_elements(plot1)-1]), make_array(1, value = plot2[n_elements(plot2)-1]),$
           psym = pstop, symsize = symsize,color=pstopco
  
   endif

endfor

;push the state
;push only at the end so we can be sure
;command succeeded
if ~keyword_set(replot) and ~keyword_set(memsave) then begin

   pxy_push_state,'plotxy',{vectors:vectors}, versus=versus, symsize=symsize, custom = custom,title=title,overplot=overplot,$
                   addpanel=addpanel,multi=multi,mmargin=mmargin,mtitle=mtitle,mpanel=mpanel,memsave=memsave,noisotropic=noisotropic,linestyle=linestyle,$
                   xrange = xrange, yrange = yrange, pstart=pstart,pstop=pstop,psymcolor=psymcolor,  xmargin = xmargin, ymargin = ymargin, $
                   xtitle=xtitle,ytitle=ytitle,colors=colors,xlog=xlog,ylog=ylog,units=units,$
                   labels=labels,grid=grid,markends=markends,marks=marks,xtick_get=xtick_get,ytick_get=ytick_get,$
                   _extra=_extra

endif


end
