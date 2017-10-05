;+
;PROCEDURE: pitch2d,data
;PURPOSE:
;	Plots 2d data as pitch angle distributions.
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
;		- set title=1 for just the time in the title
;	XTITLE - xtitle to be plotted, 
;		- set xtitle=' ' for NO xtitle!, default determined by VEL keyword
;	YTITLE - ytitle to be plotted, 
;		- set ytitle=' ' for NO ytitle!, default=data.units_name
;	RETRACE - set to number of retrace steps removed, 
;		- typically set to 1 for FAST esas
;		- minus number will remove -(retrace) steps from end of sweep
;	COLOR  - array of colors to be used for each bin
;	ENERGY:		fltarr(2)		energy range to be plotted
;	ERANGE:		intarr(2)		energy bin range to be plotted
;	EBINS:		bytarr(dat.nenergy)	energy bins to be plotted
;	OVERPLOT  - Overplots last plot if set.
;	LABEL  - Puts bin labels on the plot if set.
;	ERROR_BARS - set to plot error bars 
;       PSYM - plot symbol added to lineplot
;
;See "spec2d", "contour2d" for another means of plotting data.
;See "conv_units" to change units.
;
;
;CREATED BY:	J. McFadden  96-8-26
;FILE:  pitch2d.pro
;VERSION 1.
;LAST MODIFICATION:  97/02/24
;MOD HISTORY:
;		97/02/24	MSEC keyword added,
;		98/08/19	PSYM keyword added,
;-
pro pitch2d,tempdat,   $
	LIMITS = limits, $
  	UNITS = units,   $         
	MSEC = msec, $
	TITLE = title, $ 
	YTITLE = ytitle, $ 
	XTITLE = xtitle, $ 
	RETRACE = retrace, $
  	COLOR = col,     $
	ENERGY = en, $
	ERANGE = er, $
	EBINS = ebins,     $
  	OVERPLOT = oplot, $
  	LABEL = label,   $
  	ERROR_BARS = error_bars, $
	THICK = thick, $
	PSYM = psym

if data_type(tempdat) ne 8 or tempdat.valid eq 0 then begin
  print,'Invalid Data'
  return
endif

!y.omargin =[2,3]   ; temporary fix

if not keyword_set(units) then str_element,limits,'units',value=units
data3d=tempdat
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
endif else if title eq 1 then begin
	title = '' + '!C'+trange_str(data3d.time, data3d.end_time, $
		MSEC=msec) 
endif

if not keyword_set(ytitle) then ytitle = data3d.units_name
ydat = data3d.data
if keyword_set(error_bars) then dydat=data3d.ddata else dydat=data3d.data
energy=data3d.energy(*,0)
xdat = data3d.theta
if not keyword_set(xtitle) then xtitle = 'Pitch Angle (deg)'

if data3d.nenergy eq 1 and ndimen(data3d.data) eq 1 then begin
	xdat = ((360.*(xdat/360.-floor(xdat/360.)) + 90.) mod 360.) -90.
	minvar = min(xdat,indminvar)
	if (indminvar gt 1) and xdat(0) gt xdat(1) then indminvar=indminvar+1
	if (indminvar le 1) and xdat(2) gt xdat(3) then indminvar=indminvar+1
	ydat = shift(ydat,-indminvar)
	xdat = shift(xdat,-indminvar)
	if keyword_set(limits) then limits2=limits
	add_str_element,limits2,'xmargin',[10,10]
	plot={title:title, $
	     xtitle:xtitle,x:xdat,xlog:0, $
	     ytitle:ytitle,y:ydat,ylog:1  }
	if keyword_set(error_bars) then add_str_element,plot,'dy',dydat
	if not keyword_set(thick) then thick=1
	add_str_element,limits2,'thick',thick

	mplot,data=plot,limits=limits2,OVERPLOT=oplot
	if keyword_set(psym) then oplot,xdat,ydat,psym=psym
	!y.omargin = [0,0]
	time_stamp
	return
endif

ebins2=replicate(1b,data3d.nenergy)
if keyword_set(en) then begin
	ebins2(*)=0
	ebin=energy_to_ebin(data3d,en)
	if dimen1(ebin) eq 2 then begin
		if ebin(0) gt ebin(1) then ebin=reverse(ebin)
		ebins2(ebin(0):ebin(1))=1 
	endif else ebins2(ebin)=1
endif
if keyword_set(er) then begin
	ebins2(*)=0
	if er(0) gt er(1) then er=reverse(er)
	ebins2(er(0):er(1))=1
endif
if keyword_set(ebins) then ebins2=ebins

i = where(ebins2,count)
ydat = ydat(i,*)
dydat = dydat(i,*)
xdat = xdat(i,*)

ydat=transpose(ydat)
dydat=transpose(dydat)
xdat=transpose(xdat)
xdat = ((360.*(xdat/360.-floor(xdat/360.)) + 90.) mod 360.) -90.

for j=0,n_elements(i)-1 do begin
	minvar = min(reform(xdat(*,j)),indminvar)
	if (indminvar gt 1) and xdat(0,j) gt xdat(1,j) then indminvar=indminvar+1
	if (indminvar le 1) and xdat(2,j) gt xdat(3,j) then indminvar=indminvar+1
	ydat(*,j) = shift(ydat(*,j),-indminvar)
	dydat(*,j) = shift(dydat(*,j),-indminvar)
	xdat(*,j) = shift(xdat(*,j),-indminvar)
endfor

if keyword_set(limits) then limits2=limits
if keyword_set(col) then shades  = col(i)
if keyword_set(label) then begin 
	labels = strcompress(fix(energy(i)))+' eV'
;	labels = strcompress(fix(energy(i)))
	add_str_element,limits2,'labels',labels
	add_str_element,limits2,'labflag',1
endif
add_str_element,limits2,'xmargin',[10,10]

; Set plot limit defaults

	str_element,limits2,'xrange',index=index
	if index lt 0 then add_str_element,limits2,'xrange',[-100,280]
	str_element,limits2,'xstyle',index=index
	if index lt 0 then add_str_element,limits2,'xstyle',1
	str_element,limits,'xlog',index=index
	if index lt 0 then add_str_element,limits2,'xlog',0
	str_element,limits,'ylog',index=index
	if index lt 0 then add_str_element,limits2,'ylog',1

plot={title:title, $
     xtitle:xtitle,x:xdat,xlog:0, $
     ytitle:ytitle,y:ydat,ylog:1  }

if keyword_set(error_bars) then add_str_element,plot,'dy',dydat

mplot,data=plot,limits=limits2,OVERPLOT=oplot,COLORS=shades
if keyword_set(psym) then oplot,xdat,ydat,psym=psym

!y.omargin = [0,0]
time_stamp

return
end
