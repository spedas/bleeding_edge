
;+
;Procedure:
;  thm_part_slice1d_plot.pro
;
;Purpose:
;  Draw the plots for thm_part_slice1d
;  
;Calling Sequence:
;  thm_part_slice1d_plot, x, y [,overplot=overplot] [,xrange=xrange] [,yrange=yrange]
;                   [,title=title] [,xtitle=xtitle] [,ytitle=ytitle] [,window=window]
;
;Input:
;         x: data's x axis values (km/s, eV, degrees)
;         y: data's y axis values (slice's units)
;  overplot: flag to add the trace to the previous plot 
;    xrange: range to force the x axis to
;    yrange: range to force the y axis to
;    window: index of the plotting window to be used
;     title: plot title
;    xtitle: x axis title
;    ytitle: y axis title
;  
;  *IDL graphics keywords passed through _extra were supercede any
;   keywords explicitly set in the calls to plot and oplot.
;   Depending on the circumstance one may wish to:
;     -add the keyword to this routine to allow it to be filtered
;     -strip the option from the _extra structure 
;
;Output:
;  None, produces plot.
;
;Notes:
;   
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-04 18:05:22 -0800 (Fri, 04 Mar 2016) $
;$LastChangedRevision: 20331 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/plotting/thm_part_slice1d_plot.pro $
;
;-

pro thm_part_slice1d_plot, x, y, $
                           overplot=overplot, $
                           xrange=xrange, $
                           yrange=yrange, $
                           xtitle=xtitle, $
                           ytitle=ytitle, $
                           title=title, $
                           window=window, $
                           _extra=_extra

    compile_opt idl2, hidden


  if undefined(xstyle) then xstyle=0
  if undefined(xprecision) then xprecision=4
  if undefined(ystyle) then ystyle=0
  if undefined(yprecision) then yprecision=4
  

  ;Format window and plotting area
  if ~keyword_set(overplot) then begin     
  
    ;Set up plot area if not exporting to postscript
    if !d.name ne 'PS' then begin
  
      plotsize = 500.
  
      plotxcsize = plotsize / !d.x_ch_size
      plotycsize = plotsize / !d.y_ch_size
      
      xmargin = [11,6]
      ymargin = [4,3]
      
      tsize = strlen(title) * 1.25
    
      xcsize = (total(xmargin) + plotxcsize) > tsize
      ycsize = (total(ymargin) + plotycsize) 
      
      if undefined(window) then begin
        wn = !d.window > 0
      endif else begin
        wn = window
      endelse
      
      window, wn, xsize = xcsize * !d.x_ch_size, $
                  ysize = ycsize * !d.y_ch_size, $
                  title = title
  
      xmargin[0] = xmargin[0] > 0.5*(xcsize - plotxcsize)
      
    endif
  
    
    ;Filter any plotting keywords that we do not want overwritten
    ;by _extra when drawing the axes and annotations.
    if is_struct(_extra) then begin
      
      ex = _extra
      tn = strlowcase(tag_names(ex))
      
      ;keep axes and annotation from being drawn in the color of the data
      if in_set(tn,'color') then begin
        str_element, ex, 'color', /delete
        if ~is_struct(ex) then ex = {dummy:0}
      endif
      
    endif
  
  
    ;Add plot axes and annotations
    plot, [0,0], $
          /ylog, $
          xstyle = 1, $
          ystyle = 1, $
          xrange = keyword_set(xrange) ? xrange:minmax(x), $
          yrange = keyword_set(yrange) ? yrange:minmax(y)*[.5,2], $
          xmargin = xmargin, $
          ymargin = ymargin, $
          ytitle = ytitle, $
          xtitle = xtitle, $ 
          title = title, $
          _extra=ex

  endif 


  ;Add the data
  oplot, x, y, _extra=_extra
  
  
end