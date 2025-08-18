;+
;PROGRAM:	fu_spec2d,funct,dat 
;INPUT:	
;	funct:	string,		function that operates on structures generated 
;					by get_eesa_surv, get_eesa_burst, etc.
;				funct   = 'n_2d','j_2d','v_2d','p_2d','t_2d',
;					  'vth_2d','ec_2d', or 'je_2d'
;	dat:	structure,	2d data structures
;				example: dat = get_fa_ees(t)
;KEYWORDS
;	LIMITS - structure,	A structure containing limits and display options.
;				see: "options", "xlim" and "ylim", to change limits
;	TITLE - Title to be plotted, 
;		- set title=' ' for NO Title!
;		- set title='1' for just the time in the title
;	XTITLE - xtitle to be plotted, 
;		- set xtitle=' ' for NO xtitle!, default determined by VEL keyword
;	YTITLE - ytitle to be plotted, 
;		- set ytitle=' ' for NO ytitle!, default=data.units_name
;	ANGLE:	fltarr(2),	optional, min,max pitch angle range for integration
;	ARANGE:	fltarr(2),	optional, min,max angle bin numbers for integration
;	BINS:	bytarr(nb),	optional, angle bins array for integration
;					0,1=exclude,include,  
;					nb = dat.ntheta
;	INTEG_F:	0,1	if set, plot forward integral
;	INTEG_R:	0,1	if set, plot reverse integral
;	MPLOT:		0,1	if set, mplot is used with blue (diff_fu), green (integ_f), and red (integ_r)
;
;PURPOSE:
;	Plots the differential funct(dat) versus energy, funct(dat) is integrated over angle only
;
;CREATED BY:
;	J.McFadden	97/03/13
;LAST MODIFICATION:  97/03/13
;MOD HISTORY:	
;
;NOTES:	  
;	Current version only works for FAST
;-
pro fu_spec2d,funct,dat, $
	PSYM = psym, $
	LIMITS = limits, $
	TITLE = title, $ 
	YTITLE = ytitle, $ 
	XTITLE = xtitle, $ 
	ANGLE=an, $
	ARANGE=ar, $
	BINS=bins, $
	INTEG_F = integ_f, $
	INTEG_R = integ_r, $
	MPLOT = mplot
	
if n_params() lt 2 then begin
	print,'Wrong Format, Use: fu_spec2d,funct,dat,[ANGLE=angle,...]'
	return
endif

!y.omargin =[2,3]   ; temporary fix

nenergy=dat.nenergy
y=fltarr(nenergy)
for a=0,nenergy-1 do begin
	y(a) = call_function(funct,dat,ERANGE=[a,a],ANGLE=an,ARANGE=ar,BINS=bins)
endfor
x=reform(dat.energy(*,0))
if x(1) gt x(2) then begin
	y=reverse(y)
	x=reverse(x)
endif

if not keyword_set(title) then title = dat.project_name+'  '+dat.data_name+' '+funct
if not keyword_set(ytitle) then ytitle='Differential '+funct
if not keyword_set(xtitle) then xtitle='Energy (eV)'
plot={title:title, $
     xtitle:xtitle,x:x,xlog:1, $
     ytitle:ytitle,y:y,ylog:1  }

if keyword_set(limits) then limits2=limits
        str_element,limits2,'xrange',index=index
        if index lt 0 then add_str_element,limits2,'xrange',[(min(x(*))-1. > .1),max(x(*))]
        str_element,limits2,'xstyle',index=index
        if index lt 0 then add_str_element,limits2,'xstyle',1
        str_element,limits2,'xmargin',index=index
	if index lt 0 then add_str_element,limits2,'xmargin',[10,10]
if keyword_set(mplot) then begin
	mplot,data=plot,limits=limits2,colors=2
endif else pmplot,data=plot,limits=limits2
if keyword_set(psym) then oplot,x,y,psym=psym

if keyword_set(integ_f) or keyword_set(integ_r) then begin
	ar1=fltarr(nenergy,nenergy)
	ar2=fltarr(nenergy,nenergy)
	for a=0,nenergy-1 do begin
		ar1(a,a:nenergy-1)=1.
		ar2(a:nenergy-1,a)=1.
	endfor
	if keyword_set(integ_f) then begin
		y1=ar1#y
		plot1={title:title, $
		xtitle:xtitle,x:x,xlog:1, $
		ytitle:ytitle,y:y1,ylog:1  }
		if keyword_set(mplot) then begin
			mplot,data=plot1,overplot=1,colors=4	;green
		endif else pmplot,data=plot1,overplot=1
	endif
	if keyword_set(integ_r) then begin
		y2=ar2#y
		plot2={title:title, $
		xtitle:xtitle,x:x,xlog:1, $
		ytitle:ytitle,y:y2,ylog:1  }
		if keyword_set(mplot) then begin
			mplot,data=plot2,overplot=1,colors=6	;red
		endif else pmplot,data=plot2,overplot=1
	endif
endif 

!y.omargin = [0,0]

return
end

