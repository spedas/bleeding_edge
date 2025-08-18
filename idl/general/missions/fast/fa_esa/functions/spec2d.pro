;+
;PROCEDURE: spec2d,data
;PURPOSE:
;   Plots 2d data as energy spectra.
;INPUTS:
;   data   - structure containing 2d data  (obtained from get_fa_??() routine)
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
;	RETRACE - set to number of retrace steps removed, 
;		- typically set to 1 for FAST esas
;		- minus number will remove -(retrace) steps from end of sweep
;	VEL - If set, x-axis is velocity km/s  -- Default is Energy (eV) 
;
;	COLOR - array of colors to be used for each bin
;	ANGLE:		intarr(n)		n=1 nearest angle to be plotted
;						n=2 angle range to be plotted
;						n>2 angle list to be plotted
;	ARANGE:		intarr(2)		angle bin range to be plotted
;	BINS - 		bytarr(dat.nbins)	bins to be plotted  
;	OVERPLOT - Overplots last plot if set.
;	LABEL - Puts bin labels on the plot if set.
;	LABSIZE - Change label size on plot.
;	NO_SORT - if set will prevent sorting by angle bin
;	ERROR_BARS - set to plot error bars 
;	XMARGIN - change xmargin from default
;	YMARGIN - change ymargin from default
;	THICK - line thickness
;	PSYM - plot symbol added to lineplot
;
;See "pitch2d", "contour2d" for another means of plotting data.
;See "conv_units" to change units.
;
;
;CREATED BY:	J. McFadden	96-11-21	(from spec3d.pro)
;FILE:  spec2d.pro
;VERSION 1
;LAST MODIFICATION: 97/02/24
;MOD HISTORY:
;		97/02/24	MSEC keyword added,
;		98/03/4		xmargin,ymargin,thick keywords added
;		98/06/10	psym keyword added
;-
pro spec2d,tempdat,   $
	LIMITS = limits, $
	UNITS = units,   $          
	MSEC = msec, $
	TITLE = title, $ 
	YTITLE = ytitle, $ 
	XTITLE = xtitle, $ 
	RETRACE = retrace, $
	VEL = vel, $
	COLOR = col,     $
	ANGLE = an, $
	ARANGE = ar, $
	BINS = bins,     $
	OVERPLOT = oplot, $
	LABEL = label,   $
	LABSIZE = labsize,   $
	NO_SORT = no_sort, $
	ERROR_BARS = error_bars, $
	XMARGIN = xmargin, $
	YMARGIN = ymargin, $
	THICK = thick, $
	PSYM = psym

if data_type(tempdat) ne 8 or tempdat.valid eq 0 then begin
  print,'Invalid Data'
  return
endif

!y.omargin =[2,3]   ; temporary fix

if not keyword_set(units) then str_element,limits,'units',value=units
data3d=tempdat 
if ndimen(data3d.data) eq ndimen(data3d.bins) then data3d.data=data3d.data*data3d.bins

; Rotate the data arrays when the sweep does not start at the beginning of the array
nbins=data3d.nbins
if nbins gt 1 then emin=min(data3d.energy(*,0),ind) else emin=min(data3d.energy(*),ind)
if data3d.energy(0) lt data3d.energy(1) then begin
	if ind ne 0 then begin
		if nbins gt 1 then begin
			data3d.data=shift(data3d.data,-ind,0)
			data3d.energy=shift(data3d.energy,-ind,0)
			data3d.theta=shift(data3d.theta,-ind,0)
			data3d.denergy=shift(data3d.denergy,-ind,0)
			print,'data array shifted by ',-ind
		endif
		if nbins eq 1 then begin
			data3d.data=shift(data3d.data,-ind)
			data3d.energy=shift(data3d.energy,-ind)
			data3d.denergy=shift(data3d.denergy,-ind)
			print,'data array shifted by ',-ind
		endif
	endif 
endif
nenergy=data3d.nenergy
if data3d.energy(0) gt data3d.energy(1) and data3d.energy(ind) ne data3d.energy(nenergy-1) then begin
	if ind ne nenergy-1 then begin
		if nbins gt 1 then begin
			data3d.data=shift(data3d.data,nenergy-1-ind,0)
			data3d.energy=shift(data3d.energy,nenergy-1-ind,0)
			data3d.theta=shift(data3d.theta,nenergy-1-ind,0)
			data3d.denergy=shift(data3d.denergy,nenergy-1-ind,0)
			print,'data array shifted by ',nenergy-1-ind
		endif
		if nbins eq 1 then begin
			data3d.data=shift(data3d.data,nenergy-1-ind)
			data3d.energy=shift(data3d.energy,nenergy-1-ind)
			data3d.denergy=shift(data3d.denergy,nenergy-1-ind)
			print,'data array shifted by ',nenergy-1-ind
		endif
	endif 
endif


if keyword_set(retrace) then begin
	if retrace gt 0 then data3d.data(0:retrace-1,*)=0. $
		else data3d.data(data3d.nenergy+retrace:data3d.nenergy-1,*)=0.
endif
str_element,data3d,'ddata',value =ddata
if keyword_set(error_bars) and not keyword_set(ddata) then begin
	data3d = conv_units(data3d,'counts')
	add_str_element,data3d,'ddata',(data3d.data)^.5
	data3d = conv_units(data3d,units)
endif else data3d = conv_units(data3d,units)

if not keyword_set(title) then begin
    title = data3d.project_name+'  '+data3d.data_name+' ' + $
      data3d.units_name 
    title = title + '!C'+trange_str(data3d.time, data3d.end_time, $
		MSEC=msec) 
endif else if title eq '1' then begin
	title = '' + '!C'+trange_str(data3d.time, data3d.end_time, $
		MSEC=msec) 
endif

if not keyword_set(ytitle) then ytitle = data3d.units_name
ydat = data3d.data
if keyword_set(error_bars) then dydat=data3d.ddata else dydat=data3d.data
if ndimen(data3d.theta) eq 2 then theta=reform(data3d.theta(fix(data3d.nenergy/2),*)) else theta=data3d.theta
	theta = ((360.*(theta/360.-floor(theta/360.)) + 45.) mod 360.) -45.

if not keyword_set(vel) then str_element,limits,'velocity',value=vel
if keyword_set(vel) then begin
	xdat = velocity(data3d.energy,data3d.mass)
	if not keyword_set(xtitle) then xtitle = "Velocity  (km/s)"
endif else begin
	xdat = data3d.energy
	if not keyword_set(xtitle) then xtitle = 'Energy  (eV)'
endelse

bins2=replicate(1b,data3d.nbins)
if keyword_set(an) then begin
	if ndimen(an) gt 1 then begin
		print,'Error - angle keyword must be fltarr(n)'
	endif else begin
		if dimen1(an) eq 1 then bins2=angle_to_bins(data3d,[an,an])
		if dimen1(an) eq 2 then bins2=angle_to_bins(data3d,an)
		if dimen1(an) gt 2 then begin 
			ibin=angle_to_bin(data3d,an)
			bins2(*)=0 & bins2(ibin)=1
		endif
	endelse
endif
if keyword_set(ar) then begin
	bins2(*)=0
	if ar(0) gt ar(1) then begin
		bins2(ar(0):data3d.nbins-1)=1
		bins2(0:ar(1))=1
	endif else begin
		bins2(ar(0):ar(1))=1
	endelse
endif
if keyword_set(bins) then bins2=bins

; Sort data so angle increases with index number
if not keyword_set(no_sort) and data3d.nbins gt 2 then begin
	minvar = min(theta,indminvar)
	if (indminvar gt 1) then begin
		if theta(0) gt theta(1) then begin
			xdat=reverse(xdat,2)
			ydat=reverse(ydat,2)
			dydat=reverse(dydat,2)
			bins2=reverse(bins2)
			theta=reverse(theta)
		endif
	endif else begin
		if theta(2) gt theta(3) then begin
			xdat=reverse(xdat,2)
			ydat=reverse(ydat,2)
			dydat=reverse(dydat,2)
			bins2=reverse(bins2)
			theta=reverse(theta)
		endif
	endelse
	minvar = min(theta,indminvar)
	xdat=transpose(xdat)
	ydat=transpose(ydat)
	dydat=transpose(dydat)
	xdat = shift(xdat,-indminvar,0)
	ydat = shift(ydat,-indminvar,0)
	dydat = shift(dydat,-indminvar,0)
	bins2 = shift(bins2,-indminvar)
	theta = shift(theta,-indminvar)
	xdat=transpose(xdat)
	ydat=transpose(ydat)
	dydat=transpose(dydat)
endif

i = where(bins2,count)
ydat = ydat(*,i)
dydat = dydat(*,i)
xdat = xdat(*,i)
; print,count,i

if keyword_set(limits) then limits2=limits
;if keyword_set(col) then shades  = col(0:count-1)
if keyword_set(label) then begin 
	labels = strcompress(fix(theta(i)))+' deg'
;	labels = strcompress(fix(theta(i)))
	add_str_element,limits2,'labels',labels
	add_str_element,limits2,'labflag',1
	if keyword_set(labsize) then add_str_element,limits2,'labsize',labsize
endif
if not keyword_set(xmargin) then xmargin=[10,10]
add_str_element,limits2,'xmargin',xmargin
if not keyword_set(ymargin) then ymargin=[4,2]
add_str_element,limits2,'ymargin',ymargin
if not keyword_set(thick) then thick=1
add_str_element,limits2,'thick',thick

; Set plot limit defaults

	str_element,limits2,'xrange',index=index
	if index lt 0 then add_str_element,limits2,'xrange',[(min(xdat(*,0))-1. > .1),max(xdat(*,0))]
	str_element,limits2,'xstyle',index=index
	if index lt 0 then add_str_element,limits2,'xstyle',1
	str_element,limits,'xlog',index=index
	if index lt 0 then add_str_element,limits2,'xlog',1
	str_element,limits,'ylog',index=index
	if index lt 0 then add_str_element,limits2,'ylog',1

plot={title:title, $
     xtitle:xtitle,x:xdat,xlog:1, $
     ytitle:ytitle,y:ydat,ylog:1  }

if keyword_set(error_bars) then add_str_element,plot,'dy',dydat

mplot,data=plot,limits=limits2,OVERPLOT=oplot,COLORS=col
;mplot,data=plot,limits=limits2,OVERPLOT=oplot,COLORS=shades
if keyword_set(psym) then oplot,xdat,ydat,psym=psym,COLOR=col

!y.omargin = [0,0]
time_stamp

return
end
