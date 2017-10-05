;+
; Procedure: tplotxy
;
; Purpose: Takes a tplot variable containing an array of 3-d(Nx3) 
;          vectors or and plots them using 2-d plots to help visualize 
;          them. It can also take a tplot variable storing an 
;          MxNx3 array.  This represents N times and M different 
;          sets of 3-d vectors. (For example M different magnetic
;          field lines during some interval)
;
;         This routine will check the current timespan and only
;         display values within the specified range(this entails
;         clipping on the N dimension).  If no range is specified
;         by argument or timespan it will use the entire interval.
;
;         If the noisotropic keyword is not used the plot will be made
;         so that one unit of x is the same length on the screen as
;         one unit of y
;
;         Can also accept an Nx2 or an MxNx2 element array(in a tvar)...if this
;         is done the versus argument should not use a custom
;         designation or the z-axis, as it assumes 2-d vectors are in
;         the x-y plane, and thus will distort the vectors upon projection.
;
;          
;         plotxy/tplotxy plots can be interleaved on the same window
;         with plotxyz plots
;
;         Calling tplotxy with no arguments to redraw the entire
;         window(including plotxyz plots)
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
;         plotting options.
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
;
;         An entire plot window must be filled in sequence, if you move
;         on to a new window you will not be able to go back to the
;         previous panel without restarting.
;         It is possible use a panel out of sequence by setting mpanel.
;         mpanel also allows you to create non symmetric layouts by
;         creating plots that take up more than one panel.
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
;         This program will also set some options using the dlimits
;         and limits of the tplot variable, if they have not already
;         been explicitly set by the user.
;
;         If the tag 'colorsxy' is set to a color index in either
;         the limits or dlimits of a tplot variable, it will be read
;         to set a default line color.
;
;         The 'ytitle' tag from a dlimits or limits structure will
;         be used as the plot title
;
;         If the 'ysubtitle' tag is set, it will be used as the units 
;         for the xtitle and ytitle of the tplotxy panel
;
;         If the 'labels' tag is set, then the appropriate dimension
;         lable will be used. For example 'Bx','By','Bz' labels for
;         FGM will be used if plotted
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
;Example: tplotxy,'thb_state_pos'
;         tplotxy,'thb_state_pos',versus='yzr'
;         tplotxy,'thb_state_pos',versus='cc',custom=transpose([[1,1,0],[0,0,1]])
;         tplotxy,'thb_state_pos',versus='xryz',xrange=[0,10],yrange=[0,10]
;
; NOTE: This procedure can accept arguments that are documented only
; in plotxy.  It will pass them through when it calls that routine
; using keyword inheritance.  So if you can't find a useful option
; here, I would recommend looking there.
;
; Inputs: vectors: The name of a tplot variable that stores the list of vectors
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
;         plot of the vectors passed into tplotxy when they are
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
;         The first element is cols left to right, the second rows
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
;         xmargin(optional):set this to a 2 element array to specify
;         the left and right margin for the plot
;         unlike tplot & plot this is specified in terms of the 
;         proportion of available space given the plot layout not
;         number of characters.  This also specified for each plot
;         in a panel individually, no for the whole panel to allow
;         the user more control over layout.
;
;         ymargin(optional):set this to a 2 element array to specify
;         the bottom and top margin for the plot
;         unlike tplot & plot this is specified in terms of the 
;         proportion of available space given the plot layout not
;         number of characters.  This also specified for each plot
;         in a panel individually, no for the whole panel to allow
;         the user more control over layout.
;
;         pstart(optional): set this keyword to a number representing
;         the symbol you would like to start lines with. (This works
;         like the idl psym keyword, but only for the first symbol
;         in a line being plotted)
;
;         pstop(optional): set this keyword to a number representing
;         the symbol you would like to end lines with. (This works
;         like the idl psym keyword, but only for the last symbol
;         in a line being plotted)
;
;         psym(optional): use this to plot using a symbol
;         rather than a line.
;
;         symsize(optional): specify the size of the start and end
;         symbol, or psym (default:1.0)
;
;         WARNING!!! Using any of the 4 windowing options
;         below will interfere with the creation of postscript
;         graphics
;
;         window(optional):specify the window for
;         output.  (default:current)
;
;         xsize(optional):specify the xsize of the window in
;         pixels(default: current)
;
;         ysize(optional):specify the ysize of the window in pixels
;         (default: current)
;
;         wtitle(optional):the title you would like the window to have
;
;         usetrange(optional):set this keyword(ie /usetrange) if you want it
;         to prompt for a timerange if one is not provided by timespan 
;
;         notrange(optional):set this keyword(ie /notrange) if you
;         want it to ignore the time range and use the entire sequence
;         of values regardless.
;
;         sort(optional): set this keyword(ie /sort) if you want it
;         to sort points on time
;
;         colors(optional): set this keyword to override the color
;         information stored in the limits or dlimits of the tplot
;         variable, if the tplot variable contains an Nx3 array
;         it should contain a single element, if it contains an
;         MxNx3 array it should contain one or M colors. If the
;         tplot variable contains wildcards or is composite
;         it will be ignored.
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
;         markends(optional): set this if you want to mark the very
;         edges of your plot axis with data labels. This means the
;         numerical values of the maximum x tick,minimum x tick,
;         maximum y tick, and minimum y tick will be marked.Note that
;         an extra blank page may be created in any postscripts you
;         generate when using this option. 
;
;         reverse_time(optional): set to have the function reverse
;         the data according to the time axis,this will only
;         really change which end is marked as stop and which as start
;
;         units(optional): set this if you want this unit label
;         appended to both axis titles.(This will be ignored if 
;         you set the xtitle or ytitle explictly) 
;         
;         xtick_get,ytick_get: These behave exactly as the plot
;         command versions, but they had to be identified explictly
;         to ensure they would be passed through correctly.
;
;
;         get_plot_pos=get_plot_pos: Return the normalized position of your plot.
;           Output will be a 4-element array [x1,y1,,x2,y2]
;           Where (x1,y1) is the lower-left corner of your plot and
;           (x2,y2) is the top right corner of your plot.
;           
;         This procedure also takes normal idl keywords that effect
;         plotting style
;
;  SEE ALSO:
;    plotxyz,plotxy,thm_crib_tplotxy,thm_crib_plotxy,thm_crib_plotxyz,
;    plotxylib,plotxyvec
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-10-27 14:27:21 -0700 (Thu, 27 Oct 2016) $
; $LastChangedRevision: 22223 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/tplotxy.pro $
;-

;main function
pro tplotxy, vectors, title=title,overplot=overplot,addpanel=addpanel,multi=multi,mmargin=mmargin, mtitle=mtitle,mpanel=mpanel, usetrange=usetrange,$
             notrange=notrange,sort=sort,colors=colors,units=units,reverse_time=reverse_time,xtick_get=xtick_get,$
             ytick_get=ytick_get,get_plot_pos=get_plot_pos,_extra = _extra

compile_opt idl2

@tplot_com.pro

;handle replot case
if ~keyword_set(vectors) then begin
   plotxy
   return
endif

;if(size(vectors, /type) ne 7) then message,'must be passed a valid tplot variable'

if not keyword_set(overplot) then overplot = 0

names = tnames(vectors)

if n_elements(names) eq 1 && names eq '' then message, 'tplot variable specified does not exist'

if n_elements(names) gt 1 then begin
   
   ;handle multiple variables stored as one tvar
   for i = 0,n_elements(names)-1 do begin

      if (i eq 0) && ~keyword_set(overplot) then begin 
         op = 0 
      endif else begin
         op = 1
      endelse

      if (i gt 0) && keyword_set(addpanel) then begin
         add = 0
      endif else if keyword_set(addpanel) then begin
         add = 1
      endif

      if (i gt 0) && keyword_set(multi) then begin
         
         if keyword_set(mlt) then temp = temporary(mlt) ;unset mlt
         
      endif else if keyword_set(multi) then begin
         mlt=multi
      endif

      
      if keyword_set(colors) then begin
         if n_elements(colors) ne 1 then begin
            cols = colors[i]
         endif else begin
            cols = colors
         endelse
      endif


       tplotxy, names[i], title=title,overplot=op,addpanel=add,multi=mlt,mmargin=mmargin,mtitle=mtitle,mpanel=mpanel,usetrange=usetrange,$
                notrange=notrange,sort=sort,colors=cols,units=units,reverse_time=reverse_time,$
                xtick_get=xtick_get,ytick_get=ytick_get,_extra = _extra

    endfor

    return

 endif

 get_data, vectors, data = d, limit=l,dlimit = dl

 if(size(d,/type) eq 7) then begin
    if n_elements(d) eq 1 then d = strsplit(d,' ',/extract)
          
     ;handle multiple variables stored as one tvar
    for i = 0,n_elements(d)-1 do begin

       if (i eq 0) && ~keyword_set(overplot) then begin 
          op = 0 
       endif else begin
          op = 1
       endelse
       
       if (i gt 0) && keyword_set(addpanel) then begin
          add = 0
       endif else if keyword_set(addpanel) then begin
          add = 1
       endif
       
       if (i gt 0) && keyword_set(multi) then begin
          
          if keyword_set(mlt) then temp = temporary(mlt) ;unset mlt
          
       endif else if keyword_set(multi) then begin
          mlt=multi
       endif

       
       if keyword_set(colors) then begin
          if n_elements(colors) ne 1 then begin
             cols = colors[i]
          endif else begin
             cols = colors
          endelse
       endif

       tplotxy, d[i], title=title,overplot=op,addpanel=add,multi=mlt,mmargin=mmargin,mtitle=mtitle,mpanel=mpanel, usetrange=usetrange,$
                notrange=notrange,sort=sort,colors=cols,reverse_time=reverse_time,xtick_get=xtick_get,$
                ytick_get=ytick_get,_extra = _extra
        
   endfor
   
   return

endif

if ((keyword_set(tplot_vars) && keyword_set(tplot_vars.options) && keyword_set(tplot_vars.options.trange)) $
    || keyword_set(usetrange)) && ~keyword_set(notrange) then begin

   tr =  timerange(/current)

   id = where(d.x ge tr[0] and d.x le tr[1])
   
   if(id[0] eq -1) then begin
     dprint, 'no data available in current timerange'
     return
   endif
   
   n =  size(d.y, /dimensions)

   tm = d.x[id]
   
   if(n_elements(n) eq 2) then vecs = d.y[id, *]
   
   if(n_elements(n) eq 3) then vecs = d.y[id,*, *]
   
endif else begin 
   vecs = d.y
   tm = d.x
endelse

if keyword_set(reverse_time) then begin
   sort = 1
endif

if keyword_set(sort) then begin

   s = size(vecs,/dimensions)
   
   if n_elements(tm) ne s[0] then message,'number of elements in tvar times does not match number of elements in tvar values'

   idx = sort(tm)
   
   tm = tm[idx]

   vecs = vecs[idx,*]
   
endif

if keyword_set(reverse_time) then begin

   vecs = reverse(vecs)

endif
   

if(keyword_set(colors)) then begin
   cols = colors 
endif else begin 

   if keyword_set(dl) then begin

      str_element,dl,'colorsxy',SUCCESS=s

      if s then cols = dl.colorsxy

   endif
   
   if keyword_set(l)  then begin 
   
      str_element,l,'colorsxy',SUCCESS=s

      if s then cols = l.colorsxy

   endif

endelse

;the tplot ytitle is typically more 
;appropriate as the tplotxy title
if(keyword_set(title)) then begin
   titl = title 
endif else begin 

   if keyword_set(dl) then begin

      str_element,dl,'ytitle',SUCCESS=s

      if s then titl = dl.ytitle

   endif
   
   if keyword_set(l)  then begin 
   
      str_element,l,'ytitle',SUCCESS=s

      if s then titl = l.ytitle

   endif

endelse


;the tplot ytitle is typically more 
;appropriate as the tplotxy title
if(keyword_set(units)) then begin
   uni = units 
endif else begin 

   if keyword_set(dl) then begin

      str_element,dl,'ysubtitle',SUCCESS=s

      if s then uni = dl.ysubtitle

   endif
   
   if keyword_set(l)  then begin 
   
      str_element,l,'ysubtitle',SUCCESS=s

      if s then uni = l.ysubtitle

   endif

endelse


if keyword_set(dl) then begin

   str_element,dl,'labels',SUCCESS=s

   if s then labels = dl.labels

endif
   
if keyword_set(l)  then begin 
   
   str_element,l,'labels',SUCCESS=s

   if s then labels = l.labels
   
endif

plotxy,vecs,overplot=overplot,addpanel=addpanel,multi=multi,mmargin=mmargin,mtitle=mtitle,mpanel=mpanel,title=titl,colors=cols,units=uni,labels=labels,$
  xtick_get=xtick_get,ytick_get=ytick_get,get_plot_pos=get_plot_pos,_extra=_extra

end
