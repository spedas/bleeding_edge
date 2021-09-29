;+
; NAME:
; 	spp_fld_statusplot
;
; PROCEDURE:
; 	spp_fld_statusplot, x, y, overplot = overplot, limits = lim, data = data
;
; INPUT:
; 	x: array of x values.
;	  y: array of y strings.
;
; PURPOSE:
; 	Procedure used to display status bars on a TPLOT.
;   SPP_FLD_STATUSPLOT uses the SPECPLOT routine to plot a TPLOT variable
;   that can take on one of several discrete STRING values.
;
; KEYWORDS:
;	DATA:		A structure containing the elements 'x' and 'y'.
;	LIMITS:		The limits structure for the TPLOT variable.
;	OVERPLOT:	If set, data is plotted over current plot.
;	STAT_VALS:	An array of strings containing possible
;			values for the 'y' variable.  If STAT_VALS is unset,
;			STATUSPLOT plots status bars for each unique
;			string contained in the 'y' variable.
;
; EXAMPLE:	
;	If 'Channel' is a TPLOT variable with possible values of
;	'Ch1', 'Ch2', and 'Off', then the following commands
;	will set up statusplot.
;	
;	options, 'Channel', 'tplot_routine', 'statusplot'
;	options, 'Channel', 'stat_vals', ['Off', 'Ch1', 'Ch2']
;	tplot, 'Channel'
;		
; MOD HISTORY:
; 	Original version, based on the STRPLOT procedure,
;	created 27 May 2009 by Marc Pulupa.  
;-

pro spp_fld_statusplot, x, y, overplot = overplot, $
                limits = lim, data = data, stat_vals = stat_vals
  
  if keyword_set(data) then begin
     x = data.x
     y = data.y
     extract_tags, stuff, data, except=['x','y']
  endif
  
  extract_tags, stuff, lim
  extract_tags, plotstuff, stuff, /plot
  extract_tags, xyoutstuff, stuff, /xyout

  labsize = 1.
  str_element, stuff, 'labsize', val = labsize

  chsize = !P.CHARSIZE
  if not keyword_set(chsize) then chsize = 1.

  if not keyword_set(stat_vals) then begin
     extract_tags, stat_vals_str, stuff, tags = ['stat_vals']
     if keyword_set(stat_vals_str) then stat_vals = stat_vals_str.stat_vals
  end

  if keyword_set(stat_vals) then $
     y_vals = stat_vals else $
        y_vals = strcompress(string(y[uniq(y, sort(y))]))
  
  n_x = n_elements(x)
  n_y = n_elements(y_vals)

  IF n_y GT 59 then begin
     PRINT, 'STATUSPLOT Error: Too many (>60) unique y values.'
  END

  IF !P.BACKGROUND GT !P.COLOR THEN BEGIN
     background = 1.
     foreground = 0.
  ENDIF ELSE BEGIN
     background = 0.
     foreground = 1.
  END

  z = fltarr(n_x, 2*n_y)+background

  for i = 0l, n_x-1 do begin
     status_index = where(y_vals EQ y[i])
     if status_index[0] GT -1 then begin
        z[i, 2*where(y_vals EQ y[i])] = foreground
        z[i, 2*where(y_vals EQ y[i])+1] = foreground
     end
  end

  delta = 0.00001

  y_spec_bottom = findgen(n_y)/n_y
  y_spec_top = y_spec_bottom+1./n_y-delta

  y_spec0 = [y_spec_bottom, y_spec_top]
  y_spec = y_spec0[sort(y_spec0)]

  yticks = n_elements(y_vals)+1
  ytickname = [' ', y_vals, ' ']
  yticknamelen = fltarr(n_elements(ytickname))
  ytickv = [0., (0.5+findgen(n_y))/n_y, 1.]

  for i = 0, n_elements(ytickname) -1 do yticknamelen[i] = strlen(ytickname[i])

  str_element, plotstuff, 'ytitle', val = ytitle

  cs = 1.0
  tplot_options, get_options = opt
  str_element, opt, 'charsize', cs

  blankyticks = [strmid(string(make_array(1,/string),format='(A20)'), $
                               0, max(yticknamelen) + 3 < 20), ' ']

  if not keyword_set(overplot) then $
     plot, /nodata, x, findgen(n_x)/n_x, $
           yrange = [0, 1], ystyle = 1, ytitle = ytitle, $
           yticks = 1, $
           ytickname = blankyticks, $
           _extra = plotstuff

  specplot, x, y_spec, z, $
            limits = {x_no_interp:1, y_no_interp:1, $
                      no_color_scale:1, xstyle:4, yticklen:-0.000001, $
                      yminor:1, yticks:yticks, $
                      ytickname:ytickname, ycharsize:cs, $
                      ytickv:ytickv, overplot:1, zrange:[0., 1.], $
                      bottom:0b, top:255b}

  if not keyword_set(overplot) then $
     plot, /noerase, /nodata, x, findgen(n_x)/n_x, $
           ystyle = 4, $
           _extra = plotstuff

end
