;+
;FUNCTION: fu_fit2d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,...)
;
;   Select energy/angle range and perform functional fit to data
;   (default Maxwellian) 
;INPUTS:
;   	dat   	- data structure containing 2d data 
;		- e.g. "get_fa_ees, get_fa_ies, etc."
;KEYWORDS:
;	NFITF	integer		optional number of functions for the
;	                        fit, default = 1 
;	FITF	string		optional function for the fit, default
;	                        = maxwellian 
;	AUTO	0/1		if set, defaults are used and peak
;	                        energy determined from the data
;	ENERGY:	fltarr(2),	optional, min,max energy range for fit
;	ERANGE:	fltarr(2),	optional, min,max energy bin numbers
;	                        for fit 
;	EBINS:	bytarr(na),	optional, energy bins array for fit
;					0,1=exclude,include,  
;					na = dat.nenergy
;	ANGLE:	fltarr(2),	optional, min,max pitch angle range
;	                        for fit 
;	ARANGE:	fltarr(2),	optional, min,max angle bin numbers
;	                        for fit 
;	BINS:	bytarr(nb),	optional, angle bins array for fit
;					0,1=exclude,include,  
;					nb = dat.ntheta
;	BINS:	bytarr(na,nb),	optional, energy/angle bins array for
;	                        fit 0,1=exclude,include
;	LIMITS 	- A structure containing limits and display options.
;             	see: "options", "xlim" and "ylim", to change limits
;	UNITS  	- convert to given data units before plotting
;	F_UNITS - convert dat.data to given data units before 
;			passing to function "FITF"
;	COLOR  	- array of colors to be used for each bin
;	LABEL  	- Puts bin labels on the plot if set.
;	SUMPLT - redraws the summed data and the fit after
;	         completion. 
;	MSEC - Subtitle will include milliseconds
;
;NOTES:
;	This program still has bugs and may not weight the points
;	properly !!!!! 
;
;	See "spec2d" for another means of plotting data.
;	See "conv_units" to change units.
;	See "time_stamp" to turn time stamping on and off.
;	 Future changes: fitfunct.pro, tempfit.pro, tempfit2.pro
;
;
;CREATED BY:	J. McFadden  96-11-14
;FILE:  funct_fit3d.pro
;VERSION 1.
;LAST MODIFICATION: Ver 1.1 GTDelory 97-07-30
;-
function fu_fit2d,dat, $
;                NFUNCT = nfitf, $
;                FITF = fitf, $
;                AUTO = auto, $
                ENERGY = en, $
                ERANGE = er, $
                EBINS = ebins, $
                ANGLE = an, $
                ARANGE = ar, $
                BINS = bins, $
                LIMITS = limits, $
                UNITS = units, $ 
;                F_UNITS = f_units, $       
;                COLOR = col, $
                LABEL = label, $
;                SUMPLT = sumplt, $
;                EBARS = ebars, $
                MSEC = msec

common fit_mass,mass

; Exit if no data
;
if data_type(dat) ne 8 or dat.valid eq 0 then begin
    print,'Invalid Data'
    return,[0,0,0,0]
endif
!y.omargin =[2,3]               ; temporary fix
mass=dat.mass*1.6e-22
;	dat.mass is a scaler with units of eV/(km/s)^2. Use 1.6e-12erg/eV * (km/1.e5cm)^2 to convert

; Determine angle range for fit
; default angle range is all bins
;
nb=dat.nbins
bins2=replicate(1b,nb)
if keyword_set(an) then begin
    if ndimen(an) gt 1 then begin
        print,'Error - angle keyword must be fltarr(n)'
    endif else begin
        if dimen1(an) eq 1 then bins2=angle_to_bins(dat,[an,an])
        if dimen1(an) eq 2 then bins2=angle_to_bins(dat,an)
        if dimen1(an) gt 2 then begin 
            ibin=angle_to_bin(dat,an)
            bins2(*)=0 & bins2(ibin)=1
        endif
    endelse
endif
if keyword_set(ar) then begin
    bins2(*)=0
    if ar(0) gt ar(1) then begin
        bins2(ar(0):nb-1)=1
        bins2(0:ar(1))=1
    endif else begin
        bins2(ar(0):ar(1))=1
    endelse
endif
if keyword_set(bins) then bins2=bins

; Start the plot
;
if not keyword_set(units) then units='eflux'
spec2d,dat, units=units, limits=limits, color=color, label=label, $
  msec=msec

; Determine energy range for fit
;	if keywords 'erange' or 'energy' not used then use crosshairs
;
energy = dat.energy(*,0)
if keyword_set(en) or keyword_set(er) then begin
    if keyword_set(en) then xx=en else xx=energy(er)
endif else begin
    crosshairs,xx,yy
endelse
nxx = dimen1(xx)
print,'nxx=',nxx
; If maxwellian include the acceleration
if not keyword_set(fitf) then begin
    print,'Maxwellian Fit with potential drop - default function fit'
    epeak = xx(0)
    etmp = min(abs(energy - xx(0)),epeak_ind)
    print,'epeak=',epeak
    if nxx le 2 then begin
        er_ind = intarr(2)
        etmp = min(abs(energy - xx(0)),tmpindex)
        er_ind(0) = tmpindex
        if nxx eq 2 then begin
            if xx(1) gt xx(0) then begin
                etmp = min(abs(energy - xx(1)),tmpindex)
                er_ind(1) = tmpindex
            endif else er_ind(1) = 0
        endif else er_ind(1) = 0 
        nxx = 3
        print,'FLAG!'
    endif else begin
        er_ind = intarr(nxx-1)
        n=0
        while n lt nxx-1 do begin
            etmp = min(abs(energy - xx(n+1)),tmpindex)
            er_ind(n)=tmpindex
            if n then begin
                if er_ind(n) gt er_ind(n-1) then begin
                    tmpindex = er_ind(n)
                    er_ind(n) = er_ind(n-1)
                    er_ind(n-1) = tmpindex
                endif
            endif
            n=n+1
        endwhile
    endelse
endif else begin
    print,' Fitting function = ',fitf
    er_ind = intarr(nxx-1)
    n=0
    while n lt nxx-1 do begin
        etmp = min(abs(energy - xx(n+1)),tmpindex)
        er_ind(n)=tmpindex
        if n then begin
            if er_ind(n) gt er_ind(n-1) then begin
                tmpindex = er_ind(n)
                er_ind(n) = er_ind(n-1)
                er_ind(n-1) = tmpindex
            endif
        endif
        n=n+1
    endwhile
endelse

; Determine the fitting routine
;
if keyword_set(nfitf) then begin
    if fix(nxx/2) lt nfitf then nfitf = fix(nxx/2)
endif else nfitf=fix(nxx/2)
print, 'Number of functions = ',nfitf
tfmaxwellian = 0
if not keyword_set(fitf) then begin
    fitf = 'maxwellian_'+ strcompress(string(nfitf),/remove_all)
    print,' Default function = ',fitf
    f_units='eflux'
    print,'FUNCT_FIT2d: Default units are '+f_units
    tfmaxwellian = 1
endif else begin
    print,'Use function = ',fitf
    f_units='df'
    tfmaxwellian = 0
endelse

; Get data for the fit
if dat.nbins ne 1 then tmpdat = omni2d(dat,bins=bins2) else tmpdat=dat
tmpdat = conv_units(tmpdat,f_units)
xvar = tmpdat.energy
yvar = tmpdat.data
maxind=max(er_ind)
minind=min(er_ind)
xfit=reverse(xvar(minind:maxind))
yfit=reverse(yvar(minind:maxind))

; Weighted fit according to IDL, and using ".ddata" structure returned
; from routine OMNI2D. Tends to hang CURVEFIT when .ddata is squared.
wvar = (1./tmpdat.ddata)^2
wfit=reverse(wvar(minind:maxind))

; Now fit the data
;
call_procedure, fitf, xvar, afit, yvar, pder, index=er_ind, units=f_units 
print,'Initial guess : afit=',afit
cfit = curvefit(xfit, yfit, wfit, afit, sigmaa, function_name=fitf, $
                iter=iter, chi2=chi2)
print,'Final fit     : afit=',afit

; Print out fit information
;
print,'iter=',iter
print,'curvefit chi2=',chi2
chi2_2 = total((yfit-cfit)^2*wfit)/(n_elements(yfit) - $
                                    N_elements(afit))
print,'FUNCT_FIT2d: CHI2 = '+strcompress(string(chi2_2), /remove_all)
if tfmaxwellian then begin
    for m=0,nfitf-1 do begin
        print,' Population',m
        print,' T  = ',-1./afit(2*m+1)
        print,' f0 = ',afit(2*m)	& f0=afit(2*m)
        print,' source density =', $
          afit(2*m)*exp(afit(2*m+1)*xx(0))*1.e-15 * $
          (-1.*2.*3.1416*1.6e-12/(afit(2*m+1)*(mass)))^1.5 
	T0 =-1./afit(2*m+1)
	f0 = afit(2*m)
	n0 = afit(2*m)*exp(afit(2*m+1)*xx(0))*1.e-15 * $
          (-1.*2.*3.1416*1.6e-12/(afit(2*m+1)*(mass)))^1.5 
    endfor
endif
if fitf eq 'maxwellian_beam' then print,'Vo = ',afit(2)
; Add the fit to the plot
;
xfit=dat.energy(*,0)
xfit=reverse(xfit)

call_procedure, fitf, xfit, afit, yfit_max, pder, units=f_units

chi2_2 = total((yfit_max-yvar)^2*wvar)/(N_elements(yvar) - $
                                        N_elements(afit))
print,'Total data-to-fit chi2 = '+strcompress(string(chi2_2), $
                                              /remove_all)

if keyword_set(sumplt) then begin
    sumdat=omni2d(dat,bins=bins2)
    spec2d,sumdat
endif else begin
    spec2d,dat, units=f_units, limits=limits, color=color, label=label, $
      msec=msec, angle=an, arange=ar, bins=bins
endelse

if keyword_set(ebars) then begin
    error_high = tmpdat.data + tmpdat.ddata
    error_low = tmpdat.data - tmpdat.ddata
    errplot, tmpdat.energy, error_low, error_high, width=0
endif

oplot,xfit,yfit_max

return,[T0,n0,epeak,f0]
end

