;+
;PROCEDURE: contour2d,data
;PURPOSE:
;	Produces contour plots of pitch angle dist.s from 2D data structures.
;INPUTS:
;   data   - structure containing 2d data  (obtained from get_fa_???() routine)
;		e.g. "get_fa_ees, get_fa_ies, etc."
;KEYWORDS:
;	LIMITS - A structure containing limits and display options.
;             see: "options", "xlim" and "ylim", to change limits
;	UNITS  - convert to given data units before plotting
;	MSEC - Subtitle will include milliseconds
;	TITLE - Title to be plotted, 
;		- set title=' ' for NO Title!
;		- set title='1' for just the time in the title
;	XTITLE - xtitle to be plotted, 
;		- set xtitle=' ' for NO xtitle!, default determined by VEL keyword
;	YTITLE - ytitle to be plotted, 
;		- set ytitle=' ' for NO ytitle!, default=data.units_name
;	ZTITLE - ztitle to be plotted, 
;		- set ztitle=' ' for NO ytitle!, default='Log!D10!N('+y_units+')'
;	RETRACE - set to number of retrace steps removed, 
;		- typically set to 1 for FAST esas
;		- minus number will remove -(retrace) steps from end of sweep
;	VEL - If set, x-axis is velocity km/s  -- Default is Energy (eV) 
;
;	NCONT - Number of contours to be plotted, default = 8
;	LEVELS - Explicit contour levels, default levels spaced down
;	         from max by 10^.5 
;	FILL - If set, contours are filled with solid color or gray scale
;	BW - If set, contours are white, no affect on fill plots
;	PURE - If set, 6 pure colors are cycled through for levels
;	POLAR - Makes a polar plot
;	ROTATE - Exchanges x and y axes for non-polar plots
;	LABEL - Labels the contour levels
;       LAB_0 - Puts 0 in center of plot (default is 90). Labels pitch angles with 90 degree increments.
;       LAB_90 - Puts 90 in center of plot (default is 90). Labels pitch angles with 90 degree increments.
;       LAB_180 - Puts 180 in center of plot (default is 90). Labels pitch angles with 90 degree increments.
;       XMARGIN - Change xmargin from default
;	YMARGIN - Change ymargin from default
;
;See "pitch2d" for another means of plotting data.
;See "conv_units" to change units.
;
;
;CREATED BY:	J. McFadden  96-8-31
;FILE:  contour2d.pro
;VERSION 1.
;MODIFICATIONS: 
;		McFadden 	96-9-3		More keywords added
;		Delory				Polar keyword
;		McFadden	97-11-20	Lab_0,LAB_180 keywords
;		McFadden	98-3-3		xmargin, ymargin keywords
;		
;-
pro contour2d,tempdat,   $
	LIMITS = limits, $
	UNITS = units,   $         
	MSEC = msec, $
	TITLE = title, $ 
	YTITLE = ytitle, $ 
	XTITLE = xtitle, $ 
	ZTITLE = ztitle, $ 
	RETRACE = retrace,   $
	VEL = vel, $
	NCONT = ncont, $
	LEVELS = levels, $
	FILL = fill, $
	BW = bw, $
	PURE = pure, $
	POLAR = polar, $
	ROTATE = rotate, $
	LABEL = label, $
	LAB_180 = lab_180, $
	LAB_90 = lab_90, $
	LAB_0 = lab_0, $
	XMARGIN = xmargin, $
	YMARGIN = ymargin, $
	POINTS = points

if data_type(tempdat) ne 8 or tempdat.valid eq 0 then begin
    print,'Invalid Data'
    return
endif

!y.omargin =[2,3]               ; temporary fix

if not keyword_set(units) then str_element,limits,'units',value=units
;cnt = conv_units(tempdat,'counts')
;cnt.data(*,*) = .5
;err = conv_units(cnt,units)
data3d = conv_units(tempdat,units)
if ndimen(data3d.data) eq ndimen(data3d.bins) then data3d.data=data3d.data*data3d.bins

if not keyword_set(title) then begin
    title = data3d.project_name+'  '+data3d.data_name+' ' + $
      data3d.units_name 
    title = title + '!C'+trange_str(data3d.time, data3d.end_time, $
		MSEC=msec) 
endif else if title eq '1' then begin
	title = '' + '!C'+trange_str(data3d.time, data3d.end_time, $
		MSEC=msec) 
endif

nenergy = data3d.nenergy
nbins = data3d.nbins
ydat = data3d.theta
zdat = data3d.data

str_element,limits,'velocity',value=vel
if keyword_set(vel) then begin
    xdat = velocity(data3d.energy,data3d.mass)
    if keyword_set(polar) then begin
        if not keyword_set(ytitle) then ytitle = 'Perp. Velocity (km/s)'
        if not keyword_set(xtitle) then xtitle = 'Para. Velocity (km/s)'
    endif else begin
        if not keyword_set(ytitle) then ytitle = 'Pitch Angle (deg)'
        if not keyword_set(xtitle) then xtitle = 'Velocity (km/s)'
    endelse
endif else begin
    xdat = data3d.energy
    if keyword_set(polar) then begin
        xdat = alog10(xdat)
        if not keyword_set(ytitle) then ytitle = 'Log Perp. Energy (eV)'
        if not keyword_set(xtitle) then xtitle = 'Log Para. Energy (eV)'
    endif else begin
        if not keyword_set(ytitle) then ytitle = 'Pitch Angle (deg)'
        if not keyword_set(xtitle) then xtitle = 'Energy  (eV)'
    endelse
endelse

if keyword_set(retrace) then begin
        if retrace gt 0 then zdat(0:retrace-1,*)=0. $
                else zdat(nenergy+retrace:nenergy-1,*)=0.
endif

if keyword_set(lab_0) then begin
	ydat = ((360.*(ydat/360.-floor(ydat/360.))) mod 360.)
endif else if keyword_set(lab_180) then begin
	ydat = ((360.*(ydat/360.-floor(ydat/360.)) + 180.) mod 360.) -180.
endif else begin
	ydat = ((360.*(ydat/360.-floor(ydat/360.)) + 90.) mod 360.) -90.
endelse

minvar = min(reform(ydat(0,*)),indminvar)
if (indminvar gt 1) then begin
    if ydat(0,0) gt ydat(0,1) then indminvar=indminvar+1
endif else begin
    if ydat(0,2) gt ydat(0,3) then indminvar=indminvar+1
endelse

if 1 then begin
	xdat=transpose(xdat)
	ydat=transpose(ydat)
	zdat=transpose(zdat)
	xdat = shift(xdat,-indminvar,0)
	ydat = shift(ydat,-indminvar,0)
	zdat = shift(zdat,-indminvar,0)
	xdat=transpose(xdat)
	ydat=transpose(ydat)
	zdat=transpose(zdat)
endif else begin
	xdat = shift(xdat,0,-indminvar)
	ydat = shift(ydat,0,-indminvar)
	zdat = shift(zdat,0,-indminvar)
endelse

; Use the following if array order matters
;if ydat(0,0) gt ydat(0,1) then begin
;	xdat = reverse(xdat,1)
;	ydat = reverse(ydat,1)
;	ydat = reverse(ydat,1)
;endif
;if xdat(1,0) gt xdat(2,0) then begin
;	xdat = reverse(xdat,0)
;	ydat = reverse(ydat,0)
;	ydat = reverse(ydat,0)
;endif

if ydat(0,0) gt ydat(0,1) then begin
	if keyword_set(lab_0) then begin
		ydat(*,0) = ydat(*,0) + 360.*(ydat(*,0) lt 180.)
		ydat(*,1) = ydat(*,1) + 360.*(ydat(*,1) lt 180.)
		ydat(*,nbins-1) = ydat(*,nbins-1) - 360.*(ydat(*,nbins-1) gt 180.)
		ydat(*,nbins-2) = ydat(*,nbins-2) - 360.*(ydat(*,nbins-2) gt 180.)
	endif else if keyword_set(lab_180) then begin
		ydat(*,0) = ydat(*,0) + 360.*(ydat(*,0) lt 0.)
		ydat(*,1) = ydat(*,1) + 360.*(ydat(*,1) lt 0.)
		ydat(*,nbins-1) = ydat(*,nbins-1) - 360.*(ydat(*,nbins-1) gt 0.)
		ydat(*,nbins-2) = ydat(*,nbins-2) - 360.*(ydat(*,nbins-2) gt 0.)
	endif else begin
		ydat(*,0) = ydat(*,0) + 360.*(ydat(*,0) lt 0.)
		ydat(*,1) = ydat(*,1) + 360.*(ydat(*,1) lt 0.)
		ydat(*,nbins-1) = ydat(*,nbins-1) - 360.*(ydat(*,nbins-1) gt 0.)
		ydat(*,nbins-2) = ydat(*,nbins-2) - 360.*(ydat(*,nbins-2) gt 0.)
	endelse
endif else begin
	if keyword_set(lab_0) then begin
		ydat(*,0) = ydat(*,0) - 360.*(ydat(*,0) gt 180.)
		ydat(*,1) = ydat(*,1) - 360.*(ydat(*,1) gt 180.)
		ydat(*,nbins-1) = ydat(*,nbins-1) + 360.*(ydat(*,nbins-1) lt 180.)
		ydat(*,nbins-2) = ydat(*,nbins-2) + 360.*(ydat(*,nbins-2) lt 180.)
	endif else if keyword_set(lab_180) then begin
		ydat(*,0) = ydat(*,0) - 360.*(ydat(*,0) gt 0.)
		ydat(*,1) = ydat(*,1) - 360.*(ydat(*,1) gt 0.)
		ydat(*,nbins-1) = ydat(*,nbins-1) + 360.*(ydat(*,nbins-1) lt 0.)
		ydat(*,nbins-2) = ydat(*,nbins-2) + 360.*(ydat(*,nbins-2) lt 0.)
	endif else begin
		ydat(*,0) = ydat(*,0) - 360.*(ydat(*,0) gt 0.)
		ydat(*,1) = ydat(*,1) - 360.*(ydat(*,1) gt 0.)
		ydat(*,nbins-1) = ydat(*,nbins-1) + 360.*(ydat(*,nbins-1) lt 0.)
		ydat(*,nbins-2) = ydat(*,nbins-2) + 360.*(ydat(*,nbins-2) lt 0.)
	endelse
endelse

; Set plot limits

if keyword_set(polar) then begin
    xmax=max(xdat(*,0))
    xrange=[-xmax,xmax]
    yrange=[-xmax,xmax]
    xstyle=0
    ystyle=0
    
    ;r_excl = (xdat^2+ydat^2)^0.5
    ;nan_data = where(r_excl LE 0.1*max(r_excl))
    ;if nan_data(0) GE 0 then zdat(nan_data) = !values.f_nan
    
endif else begin
    xmin=min(xdat(*,0))-1. > .1
    xmax=max(xdat(*,0))
    xrange=[xmin,xmax]
    xstyle=1
    xlog=1
    ystyle=1
    ylog=0
endelse
    
ind=where(zdat ne 0.)
zmin=min(zdat(ind))
zmax=max(zdat)
zrange=[zmin,zmax]
zlog=1

if not keyword_set(polar) then begin
    	if max(tempdat.theta) gt 200. then begin
		yrange=[-100,280] 
		yticks = 4
		ytickv = [-90,0,90,180,270]
	endif else begin
		yrange=[-10,190]
		yticks = 2
		ytickv = [0,90,180]
	endelse
endif else begin
	yticks = 0
	ytickv = 0
endelse

if keyword_set(limits) then begin

    str_element,limits,'xrange',index=index
    if index ge 0 then xrange=limits.xrange
    str_element,limits,'xstyle',index=index
    if index ge 0 then xstyle=limits.xstyle
    str_element,limits,'xlog',index=index
    if index ge 0 then xlog=limits.xlog

    str_element,limits,'yrange',index=index
    if index ge 0 then begin
    	yrange=limits.yrange
    	yticks=0
    	ytickv=0
    endif
    str_element,limits,'ystyle',index=index
    if index ge 0 then ystyle=limits.ystyle
    str_element,limits,'ylog',index=index
    if index ge 0 then ylog=limits.ylog

    str_element,limits,'zrange',index=index
    if index ge 0 then begin
        zrange=limits.zrange
        if n_elements(limits.zrange) GT 1 then begin
            zmin = limits.zrange(0)
            zmax = limits.zrange(1)
        endif
    endif
    str_element,limits,'zlog',index=index
    if index ge 0 then zlog=limits.zlog

endif

if not keyword_set(levels) then begin
    if keyword_set(ncont) then begin
        if (ncont GT 29 or ncont LT 1) then begin
            print,'CONTOUR2D: Keyword NCONT must be in the range 1 to 29.'
            print,'Setting NCONT = 25'
            ncont=25
        endif
    endif
    if not keyword_set(ncont) then ncont=25
    if zlog eq 1 then begin
;        levels=zrange(1)*10.^(-.5*findgen(ncont))
        levels=zrange(1)*10.^(-(findgen(ncont)/ncont * (alog10(zmax) - $
                                                        alog10(zmin))))
        levels=reverse(levels)
    endif else begin
     levels=(zrange(1)-zrange(0))*findgen(ncont)/ncont + zrange(0)
    endelse
endif else ncont = dimen1(levels)

if keyword_set(bw) and not keyword_set(fill) then c_colors=[1000] else $
  begin 
;   if keyword_set(bw) then loadct2,42 else loadct2,39
    if keyword_set(pure) then c_colors=bytescale(pure=ncont) else $
      c_colors=bytescale(findgen(ncont))
endelse

if keyword_set(polar) then begin
    if not keyword_set(fill) then fill=0
    ydat=!pi*ydat/180.
;	Add donut hole
    rmin = 0.8 * min(xdat(*,0))
    thdim = dimen2(xdat)
    xdat = [fltarr(1,thdim),xdat]
    xdat(0,*) = rmin 
    ydat = [fltarr(1,thdim),ydat]
    ydat(0,*) = ydat(1,*)
    zdat = [fltarr(1,thdim),zdat]
    zdat(0,*) = 0.

	if not keyword_set(xmargin) then xmargin=[12,12]
	if not keyword_set(ymargin) then ymargin=[5,5]
    
    polar_contour, zdat, ydat, xdat, title=title, xtitle=xtitle, $
      ytitle=ytitle, c_colors=c_colors, levels=levels, fill=fill, $
      xrange=xrange, yrange=yrange, ystyle=ystyle, xstyle=xstyle, $
      xmargin=xmargin,ymargin=ymargin
	if keyword_set(points) then begin
		if keyword_set(xrange) and keyword_set(yrange) then begin
			ind=where(xdat*cos(ydat) gt xrange(0) and xdat*cos(ydat) lt xrange(1) and xdat*sin(ydat) gt yrange(0) and xdat*sin(ydat) lt yrange(1)) 
			xyouts,xdat(ind)*cos(ydat(ind)),xdat(ind)*sin(ydat(ind)),'.'
		endif else if keyword_set(xrange) then begin
			ind=where(xdat*cos(ydat) gt xrange(0) and xdat*cos(ydat) lt xrange(1)) 
			xyouts,xdat(ind)*cos(ydat(ind)),xdat(ind)*sin(ydat(ind)),'.'
		endif else if keyword_set(yrange) then begin
			ind=where(xdat*sin(ydat) gt yrange(0) and xdat*sin(ydat) lt yrange(1)) 
			xyouts,xdat(ind)*cos(ydat(ind)),xdat(ind)*sin(ydat(ind)),'.'
		endif else xyouts,xdat,ydat,'.'
	endif

endif else begin

	if not keyword_set(xmargin) then xmargin=[10,10]
	if not keyword_set(ymargin) then ymargin=[4,2]
    
    
    if keyword_set(rotate) then begin
        zdat=transpose(zdat)
        xdat=transpose(xdat)
        ydat=transpose(ydat)
        contour, zdat, ydat, xdat, title=title, xtitle=ytitle, ytitle=xtitle, $
          c_colors=c_colors, levels=levels, yrange=xrange, ystyle=xstyle, $
          ylog=xlog, xrange=yrange, xstyle=ystyle, xlog=ylog, $
	  fill=fill, xmargin=xmargin, ymargin=ymargin, xticks=yticks, xtickv=ytickv
    endif else begin
        contour, zdat, xdat, ydat, title=title, xtitle=xtitle, ytitle=ytitle, $
          c_colors=c_colors, levels=levels, yrange=yrange, ystyle=ystyle, $
          ylog=ylog, xrange=xrange, xstyle=xstyle, xlog=xlog, $
          fill=fill, xmargin=xmargin, ymargin=ymargin, yticks=yticks, ytickv=ytickv
    endelse
	if keyword_set(points) then begin
		if keyword_set(xrange) and keyword_set(yrange) then begin
			ind=where(xdat gt xrange(0) and xdat lt xrange(1) and ydat gt yrange(0) and ydat lt yrange(1)) 
			xyouts,xdat(ind),ydat(ind),'.'
		endif else if keyword_set(xrange) then begin
			ind=where(xdat gt xrange(0) and xdat lt xrange(1)) 
			xyouts,xdat(ind),ydat(ind),'.'
		endif else if keyword_set(yrange) then begin
			ind=where(ydat gt yrange(0) and ydat lt yrange(1)) 
			xyouts,xdat(ind),ydat(ind),'.'
		endif else xyouts,xdat,ydat,'.'
	endif
endelse

time_stamp

if keyword_set(label) then begin
    
    bar_levels = [[c_colors],[c_colors]]
                                
    bar_width = 0.03*(!x.window(1)-!x.window(0))
    bar_start = 0.01
    bar_pos1_norm = [!x.window(1)+bar_start, !y.window(0)]
    bar_height = !y.window(1) - !y.window(0)
    bar_pos1_dev = convert_coord(bar_pos1_norm(0), bar_pos1_norm(1), $
                                 /norm, /to_device) 
    bar_pos2_dev = convert_coord(bar_pos1_norm(0) + bar_width, $
                                 bar_pos1_norm(1) + bar_height, /norm, $
                                 /to_device) 
    x_size = -(bar_pos1_dev(0) - bar_pos2_dev(0))
    y_size = -(bar_pos1_dev(1) - bar_pos2_dev(1))
    bar_pos2_norm = convert_coord(bar_pos1_dev(0)+x_size, $
                                  bar_pos1_dev(1)+y_size, /device, $
                                  /to_norm) 
    bar_levels = transpose(congrid(bar_levels,y_size,x_size))
    
    if !d.name EQ 'PS' then bar_levels = $
      transpose(congrid([[c_colors],[c_colors]],200,50)) 
    
    tv, bar_levels, bar_pos1_norm(0), bar_pos1_norm(1), $
      xsize = bar_pos2_norm(0) - bar_pos1_norm(0), $
      ysize = bar_pos2_norm(1) - bar_pos1_norm(1), /norm
    
;    print,bar_pos1_norm
;    print,bar_pos2_norm
    
    bar_min = alog10(levels(0))
    bar_max = alog10(levels(ncont-1))
    
    y_units = strlowcase(units)
    case y_units of
        'eflux':y_units = 'eV/(cm!E2!N-s-sr-eV)'
        'rate':y_units = '#/sec'
        'crate':y_units = 'Deadtime Corrected #/sec'
        'flux':y_units = '#/(cm!E2!N-s-sr-eV)'
        'df':y_units = '#/(cm!E3!N-(km/sec)!E3!N)'
        else:y_units = units
    endcase
	if not keyword_set(ztitle) then ztitle='Log!D10!N('+y_units+')'
	if label eq 3 then ztitle=' '
    
    axis, bar_pos2_norm(0),0,0, yaxis=1, yrange=[bar_min,bar_max], $
      ystyle=1, yticks=4, ytitle=ztitle, $
      yticklen = 0.02, /norm
    
endif

!y.omargin = [0,0]

return
end
