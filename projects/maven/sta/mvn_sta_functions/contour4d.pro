;+
;PROCEDURE: contour4d,data
;PURPOSE:
;	Produces contour plots of energy-mass distributions from 4D data structures.
;INPUTS:
;   data   - structure containing 4d data  (obtained from get_mvn_?() routine)
;		e.g. "get_mvn_c6, get_mvn_ce, etc."
;KEYWORDS:
;	LIMITS - A structure containing limits and display options.
;             see: "options", "xlim" and "ylim", to change limits
;	UNITS  - convert to given data units before plotting
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
;		- default set to 0
;	VEL - If set, x-axis is velocity km/s  -- Default is Energy (eV) 
;
;	NCONT - Number of contours to be plotted, default = 8
;	LEVELS - Explicit contour levels, default levels spaced down
;	         from max by 10^.5 
;	FILL - If set, contours are filled with solid color or gray scale
;	BW - If set, contours are white, no affect on fill plots
;	PURE - If set, 6 pure colors are cycled through for levels
;	ROTATE - Exchanges x and y axes for non-polar plots
;	LABEL - Labels the contour levels
;       XMARGIN - Change xmargin from default
;	YMARGIN - Change ymargin from default
;	POINTS - adds data points to plot
;
;See "conv_units" to change units.
;
;
;CREATED BY:	J. McFadden  14-02-07
;FILE:  contour4d.pro
;VERSION 1.
;MODIFICATIONS: 
;		
;-
pro contour4d,tempdat,   $
	LIMITS = limits, $
	UNITS = units,   $         
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
	ROTATE = rotate, $
	LABEL = label, $
	XMARGIN = xmargin, $
	YMARGIN = ymargin, $
	POINTS = points, $
	mass = mass, $
	zrange = zrange, $
	ylin = ylin, $
	xlin = xlin, $
	twt = twt, $
	tof = tof

if size(/type,tempdat) ne 8 or tempdat.valid eq 0 then begin
    print,'Invalid Data'
    return
endif

!y.omargin =[2,3]               ; temporary fix
!x.omargin =[0,5]               ; temporary fix

mdat = omni4d(tempdat)

mdat = conv_units(mdat,units)
nenergy = mdat.nenergy
nmass = mdat.nmass
b_ns  = 5.844 							; TOF bins/ns for TOF timing (not sure if this is 5.844 or 5.855 for flight unit) 

if not keyword_set(title) then begin
    title = mdat.project_name+'  '+mdat.data_name+' ' + $
      mdat.units_name 
;    title = title + '!C'+time_string((mdat.time+mdat.end_time)/2.)
    title = title + '!C'+time_string(mdat.time)+'-'+strmid(time_string(mdat.end_time),11,8)
endif else if title eq '1' then begin
	title = '' + time_string((mdat.time+mdat.end_time)/2.) 
endif

if keyword_set(mass) then begin
	ydat=mdat.mass_arr 
        if not keyword_set(ytitle) then ytitle = 'Mass/q (amu/q)'
	if not keyword_set(ylin) then ylog=1 else ylog=0
	yrange=[.5,max(ydat)+1]
endif else begin
	if keyword_set(tof) then begin
		ydat=mdat.tof_arr/b_ns 
        	if not keyword_set(ytitle) then ytitle = 'TOF (ns)'
		if not keyword_set(ylin) then ylog=1 else ylog=0
		if ylog then yrange=[3,200] else yrange=[0,200]
	endif else begin
		ydat=replicate(1.,mdat.nenergy)#findgen(mdat.nmass)
        	if not keyword_set(ytitle) then ytitle = 'Mass Bin'
		ylog=0
		yrange=[0,max(ydat)+1]
	endelse
endelse
	ystyle=1
	yticks = 0
	ytickv = 0

zdat = mdat.data
if keyword_set(twt) then zdat = zdat/mdat.twt_arr

if keyword_set(vel) then begin
;	str_element,limits,'velocity',value=vel
    xdat = velocity(mdat.energy,mdat.mass*mdat.mass_arr)
        if not keyword_set(xtitle) then xtitle = 'Velocity (km/s)'
endif else begin
    xdat = mdat.energy
        if not keyword_set(xtitle) then xtitle = 'Energy/q  (eV/q)'
endelse

;if keyword_set(retrace) then begin
;       if retrace gt 0 then zdat(0:retrace-1,*)=0. $
;                else zdat(nenergy+retrace:nenergy-1,*)=0.
;endif

; Set plot limits

    xmin=.9*min(xdat(*,0))-1. > .1
    xmax=1.1*max(xdat(*,0))
	if keyword_set(vel) then xmax = xmax > 100.
	if keyword_set(vel) then xmin = 1
    xrange=[xmin,xmax]
    xstyle=1
    if not keyword_set(xlin) then xlog=1 else xlog=0
if not keyword_set(zrange) then begin
	ind=where(zdat ne 0.,zcount)
	if zcount gt 1 then zmin=10.^fix(alog10(min(zdat(ind)))+.1) else zmin=1
	if zcount gt 1 then zmax=10.^fix(alog10(max(zdat))+.9) > 10.*zmin else zmax=10
	zrange=[zmin,zmax]
endif else begin
	zmax=max(zrange)
	Zmin=min(zrange)
endelse
zlog=1

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

if not keyword_set(units) then str_element,limits,'units',value=units

if not keyword_set(levels) then begin
    if keyword_set(ncont) then begin
        if (ncont GT 29 or ncont LT 1) then begin
            print,'contour4d: Keyword NCONT must be in the range 1 to 29.'
            print,'Setting NCONT = 25'
            ncont=25
        endif
    endif
    if not keyword_set(ncont) then ncont=25
    if zlog eq 1 then begin
        levels=zrange(1)*10.^(-(findgen(ncont)/(ncont-1) * (alog10(zmax) - $
                                                        alog10(zmin))))
        levels=reverse(levels)
    endif else begin
     levels=(zrange(1)-zrange(0))*findgen(ncont)/ncont + zrange(0)

    endelse
endif else ncont = dimen1(levels)

if keyword_set(bw) and not keyword_set(fill) then c_colors=[1000] else $
  begin 
    if keyword_set(pure) then c_colors=bytescale(pure=ncont) else $
      c_colors=bytescale(findgen(ncont))
endelse

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
    
    bar_min = alog10(levels(0))
    bar_max = alog10(levels(ncont-1))
    
    y_units = strlowcase(units)

  if keyword_set(twt) then begin
    case y_units of
        'counts':y_units = 'counts/tofbin'
        'eflux':y_units = 'eV/(cm!E2!N-s-sr-eV-tofbin)'
        'rate':y_units = '#/sec-tofbin'
        'crate':y_units = 'Deadtime Corrected #/sec-tofbin'
        'flux':y_units = '#/(cm!E2!N-s-sr-eV-tofbin)'
        'df':y_units = '#/(cm!E3!N-(km/sec)!E3!N/tofbin'
        else:y_units = units
    endcase
	if not keyword_set(ztitle) then ztitle='Log!D10!N('+y_units+')'
	if label eq 3 then ztitle=' '
  endif else begin
    case y_units of
        'counts':y_units = 'counts'
        'eflux':y_units = 'eV/(cm!E2!N-s-sr-eV)'
        'rate':y_units = '#/sec'
        'crate':y_units = 'Deadtime Corrected #/sec'
        'flux':y_units = '#/(cm!E2!N-s-sr-eV)'
        'df':y_units = '#/(cm!E3!N-(km/sec)!E3!N)'
        else:y_units = units
    endcase
	if not keyword_set(ztitle) then ztitle='Log!D10!N('+y_units+')'
	if label eq 3 then ztitle=' '
  endelse

    axis, bar_pos2_norm(0),0,0, yaxis=1, $
	yrange=[bar_min,bar_max], $
	ystyle=1, yticks=4, ytitle=ztitle, $
	yticklen = 0.02, /norm, ytickformat='(F5.1)',ylog=0
    
endif

!y.omargin = [0,0]

return
end