;+
;FUNCTION:	vb_pot_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt)
;INPUT:	
;	dat:	structure,	4d data structure filled by themis routines mvn_sta_c6.pro, mvn_sta_d0.pro, etc.
;KEYWORDS
;	ENERGY:	fltarr(2),	optional, min,max energy range for integration
;	ERANGE:	fltarr(2),	optional, min,max energy bin numbers for integration
;	EBINS:	bytarr(na),	optional, energy bins array for integration
;					0,1=exclude,include,  
;					na = dat.nenergy
;	ANGLE:	fltarr(2,2),	optional, angle range for integration
;				theta min,max (0,0),(1,0) -90<theta<90 
;				phi   min,max (0,1),(1,1)   0<phi<360 
;	ARANGE:	fltarr(2),	optional, min,max angle bin numbers for integration
;	BINS:	bytarr(nb),	optional, angle bins array for integration
;					0,1=exclude,include,  
;					nb = dat.ntheta
;	BINS:	bytarr(na,nb),	optional, energy/angle bins array for integration
;					0,1=exclude,include
;	mass:	fltarr(2)	optional, min,max 	mass range for integration
;	m_int:	flt		optional, assumed 	mass used for entire mass range
;	mincnt:	flt		optional, if total counts in energy-mass-angle range is <mincnt, then returns !Values.F_NAN
;	no_co2:	0,1		if set, will not use pot_co2_avg or pot_co2, will instead use dat.sc_pot
;	no_min:	0,1		if set, will allow use of sc_pot>-.01V - for testing purposes
;
;PURPOSE:
;	Returns the velocity of a beam in units of km/s -- needs modification for ion suppression correction accounting for anode variations
;NOTES:	
;	Function normally called by "get_4dt" to
;	generate time series data for "tplot.pro".
;	Modified to only be valid below 500 km
;
;CREATED BY:
;	J.McFadden	2014-02-27
;LAST MODIFICATION:
;	J.McFadden	2019-01-18		added gaussfit 
;
;-
function vb_pot_4d,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt,no_co2=no_co2,no_min=no_min,plot=plot,win=win,oplot=oplot

def = !Values.F_NAN
if dat2.valid eq 0 then begin
	print,'Invalid Data'
	return, def
endif

if (dat2.quality_flag and 195) gt 0 then begin
	print,'Data quality flag'
	return,def
endif

; only use this function with c6 data

if dat2.apid ne 'c6 avg' and dat2.apid ne 'c6' then begin
	print,' This routine only works on c6 and c6 avg apids'
	return,def
endif

; the following attempts to restrict use of this program to below 500 km

orb_rad = total(dat2.pos_sc_mso^2)^.5
if orb_rad gt (3386.+500.) then return,def
if orb_rad eq 0. then begin
	get_data,'alt',data=tmp95
	if size(tmp95,/type) eq 8 then begin
		alt = interp(tmp95.y,tmp95.x,dat2.time+2.)
		if alt gt 500. then return,def
	endif
endif

; ion suppression corrections with kk3 are only used if mvn_sta_get_kk3.pro has been run 
common mvn_sta_kk3,kk3

; sc_pot determined from o2-co2 energy difference used if mvn_sta_scpot_co2_avg_load2.pro or mvn_sta_scpot_co2_load2.pro has been run
;	only operates if STATIC mode 1 or 7, and if no_co2 is 0
;	pot_co2_avg takes precidence over pot_co2
common mvn_sta_c6_pot_co2,time_co2,pot_co2
common mvn_sta_c6_pot_co2_avg,time_co2_avg,pot_co2_avg


dat = conv_units(dat2,"counts")		; initially use counts

dat = omni4d(dat)
n_e = dat.nenergy
if dat.nmass gt 1 then mass = dat.mass*dat.mass_arr else mass = dat.mass

; this change was needed to get the dead time and efficiency corrected peaks
;data = dat.cnts 
;bkg = dat.bkg
data = dat.cnts*dat.dead
bkg = dat.bkg*dat.dead
cnts = dat.cnts

energy = dat.energy	
if n_e eq 64 then nne=4 else nne=3
if n_e eq 48 then nne=5

; we restrict co2 to a narrower energy range to prevent problems with o2 background subtraction noise

if dat2.data_name eq 'c6 32e64m co2' then nne=2
if dat2.data_name eq 'c6 avg 32e64m co2' then nne=2
;if dat2.data_name eq 'c6 avg 32e64m' then nne=2			; not sure this is needed
;nne=2

; when using co2 mode with double the energy resolution, use twice as many points

if dat.mode eq 7 then nne=2*nne

	nne1=nne & nne2=nne

; due to co2 data requiring background subtraction, we need to carefully restrict the energy range to reduce noise

if dat.mode eq 7 and (dat.data_name eq 'c6 32e64m co2' or dat.data_name eq 'c6 avg 32e64m co2') and dat.sc_pot lt -2. then begin
	nne=3 & nn1=3 & nn2=3
	tdata = total(data,2)
	maxcnt = max(tdata,mind)
	if tdata[(mind-1)>0] gt .8*tdata[mind] and tdata[(mind+1)<(n_e-1)] lt .8*tdata[mind] then nn2=2
	if tdata[(mind-1)>0] lt .8*tdata[mind] and tdata[(mind+1)<(n_e-1)] gt .8*tdata[mind] then nn1=2
endif

if keyword_set(en) then begin
	ind = where(energy lt en[0] or energy gt en[1],count)
	if count ne 0 then data[ind]=0.
	if count ne 0 then bkg[ind]=0.
	if count ne 0 then cnts[ind]=0.
endif


if keyword_set(ms) then begin
	ind = where(dat.mass_arr lt ms[0] or dat.mass_arr gt ms[1],count)
	if count ne 0 then data[ind]=0.
	if count ne 0 then bkg[ind]=0.
	if count ne 0 then cnts[ind]=0.
endif else return,def				; ms keyword required to be set

; limit the energy range to near the peak 
	data2 = data

	if ndimen(data) eq 2 then begin
		maxcnt = max(total(data,2),mind)
;		mind = 2>mind<(n_e-3)						; this forced peak to not be near edge of measurement
		if (mind eq 0) or (mind eq n_e-1) then return,def		; this works better, fitting won't work for peak at edge of measurement

		if nne eq 2 then begin							; this increases the number of points used
			if (mind lt 2) or (mind gt n_e-3) then return,def		; this works better, fitting won't work for peak at edge of measurement
			pkc = total(data[mind,*])
			pkp = total(data[mind+1,*])
			pkm = total(data[mind-1,*])
			pkpp = total(data[mind+2,*])
			pkmm = total(data[mind-2,*])
			if pkp gt .8*pkc and pkpp gt 15. then nne2=3
			if pkm gt .8*pkc and pkmm gt 15. then nne1=3
;			if nne1 eq 3 or nne2 eq 3 then print,pkmm,pkm,pkc,pkp,pkpp,nne1,nne2,'  ',time_string(dat.time)
		endif
		if 0 then begin
			mind_ini=mind
			pkc = total(data[mind,*])
			pkp = total(data[mind+1,*])
			pkpp = total(data[mind+2,*])
			pkm = total(data[mind-1,*])
			pkmm = total(data[mind-2,*])
			if pkpp gt 2.*pkm and pkc*.8 lt pkp then mind=mind+1
			if pkmm gt 2.*pkp and pkc*.8 lt pkm then mind=mind-1
			if mind_ini ne mind then print,pkmm,pkm,pkc,pkp,pkpp,mind_ini,mind,'  ',time_string(dat.time)
;			if pkc lt pkp and pkc lt pkm then nne=3
;			if nne eq 3 then print,'nne eq 3 '+time_string(dat.time)
;			if nne ne 3 and total(data[mind,*]) lt total(data[mind+1:mind+2,*]) then print,pkc,pkp,pkm,mind_ini,mind,mind+1,'    wrong peak high '+time_string(dat.time)
;			if nne ne 3 and total(data[mind,*]) lt total(data[mind-2:mind-1,*]) then print,pkc,pkp,pkm,mind_ini,mind,mind-1,'    wrong peak low  '+time_string(dat.time)
		endif 

	    if (mind-nne1) ge 0 then begin
		data[0:(mind-nne1>0),*]=0.
		bkg[0:(mind-nne1>0),*]=0.
		cnts[0:(mind-nne1>0),*]=0.
	    endif
	    if (mind+nne2) le (n_e-1) then begin
		data[((mind+nne2)<(n_e-1)):(n_e-1),*]=0.
		bkg[((mind+nne2)<(n_e-1)):(n_e-1),*]=0.
		cnts[((mind+nne2)<(n_e-1)):(n_e-1),*]=0.
	     endif
		en_peak=energy[mind,0]
	endif else if ndimen(data) eq 3 then begin			; this no longer occurs due to c6 data requirement
		maxcnt = max(total(total(data,3),2),mind) 
	    if (mind-nne1) ge 0 then begin
		data[0:(mind-nne>0),*,*]=0.
		bkg[0:(mind-nne>0),*,*]=0.
		cnts[0:(mind-nne>0),*,*]=0.
	    endif
	    if (mind+nne2) le (n_e-1) then begin
		data[((mind+nne)<(n_e-1)):(n_e-1),*,*]=0.
		bkg[((mind+nne)<(n_e-1)):(n_e-1),*,*]=0.
		cnts[((mind+nne)<(n_e-1)):(n_e-1),*,*]=0.
	     endif
		en_peak=energy[mind,0]
	endif else begin						; this will not occur due to c6 data requirement
		maxcnt = max(data,mind)
	    if (mind-nne1) ge 0 then begin
		data[0:(mind-nne>0)]=0.
		bkg[0:(mind-nne>0)]=0.
		cnts[0:(mind-nne>0)]=0.
	    endif
	    if (mind+nne2) le (n_e-1) then begin
		data[((mind+nne)<(n_e-1)):(n_e-1)]=0.
		bkg[((mind+nne)<(n_e-1)):(n_e-1)]=0.
		cnts[((mind+nne)<(n_e-1)):(n_e-1)]=0.
	     endif
		en_peak=energy[mind]
	endelse

; eliminate any energies where the total number of counts is not >1
	ind = where(total(cnts,2) lt 1.,count)
	if count gt 0 then begin
		data[ind,*]=0.
		bkg[ind,*]=0.
		cnts[ind,*]=0.
	endif
		
; if the number of counts near the peak is less than 75% of total counts in the energy range, then it is not a beam
	if total(data) lt .50*total(data2) then begin
		print,'Not enough counts to use vb_pot_4d - peak is too broad',total(data)
		return,def
	endif

if keyword_set(mincnt) then if total(data-bkg) lt mincnt then return, def
if total(data-bkg) lt 1 then return, def

charge=dat.charge
if keyword_set(q) then charge=q

att_nrg_corr=1.
if dat.att_ind eq 1 then att_nrg_corr = 1.04 
if dat.att_ind eq 3 then att_nrg_corr = 1.02

; these determine whether one assumes a constant pot of -0.12V or uses static determined scpot
; 	using static determined pot eliminates the possiblity of measuring ram velocity at periapsis
 
if 0 then begin
	energy=(att_nrg_corr*dat.energy+charge*(-0.12))>0.				; energy/charge analyzer, problems for low energy steps
;	energy=(dat.energy+charge*dat.sc_pot/abs(charge))>0.		; energy/charge analyzer, problems for low energy steps
endif else begin
;	pot = dat.sc_pot-.25		; an offset in pot when proton cutoff is used??, perhaps ion suppression causes overestimate of energy
	pot = dat.sc_pot		; use the measured potential, but make the energy correction below: en_corr
	if n_elements(pot_co2) gt 1 and ((dat.mode eq 1) or (dat.mode eq 7)) and (not keyword_set(no_co2)) then begin
		minval=min(abs((dat.time+dat.end_time)/2.-time_co2),ind)
		if pot_co2(ind) lt -.01 or keyword_set(no_min) then pot=pot_co2[ind]
	endif
	if n_elements(pot_co2_avg) gt 1 and ((dat.mode eq 1) or (dat.mode eq 7)) and (not keyword_set(no_co2)) then begin
		minval=min(abs((dat.time+dat.end_time)/2.-time_co2_avg),ind)
		if pot_co2_avg[ind] lt -.01 or keyword_set(no_min) then pot=pot_co2_avg[ind]
	endif
	en_offset = 0.
;	en_offset = +.15				; works for 20161005
;	en_offset = +.35				; works for 20160404
; adjust energies for spacecraft potential - note that pot=!values.f_nan will result in a NAN - this routine requires valid sc_pot 
	energy=(att_nrg_corr*dat.energy+charge*pot/abs(charge) + en_offset)		; energy/charge analyzer, require positive energy

; the following eliminates background counts at negative energies
	ind99 = where(energy lt dat.denergy/2.,count)
	if count ge 1 then begin
		data[ind99]=0
		bkg[ind99]=0
	endif

	en_jitter = 0.00
	de = dat.denergy > en_jitter
	ind = where(energy lt de/2.,nind)
;	if nind gt 0 then energy[ind] = (energy[ind]    + de[ind]/2.) > 0.
	if nind gt 0 then energy[ind] = (energy[ind]>0. + de[ind]/2.) > 0.		; this was changed 20180604, but should not matter because data is set to zero for energy<0.
endelse

en_corr = 1.


; the following ion suppression correction to energy is probably not needed
; assume a detuned pair of analyzers, only valid for ram sector

; FWHM * 2.355*sigma 	2*sigma^2 = th1^2    =>   th1 = 2^.5*FWHM/2.355 = 
; k/nrg = d/(th1/2^.5) 
; energy shift = d/2 = (1/2)*(th1/2^.5)*(k/nrg) = (1/2)*(FWHM/2.355)*(k/nrg)
; FWHM = ana_de_fwhm = [.13,.10,.09,.07]
; energy shift = (ana_de_fwhm[dat.att]/4.71)*(k/nrg)

ana_de_fwhm = [.13,.10,.09,.07]
if n_elements(kk3) gt 1 then begin
	en_corr = 1. - (ana_de_fwhm[dat.att_ind]/4.71)*(kk3[dat.att_ind]/dat.energy)		; ion suppression th deflection indicates a decrease in energy
endif else en_corr = 1.

if keyword_set(mi) then v = (2.*en_corr*energy/(dat.mass*mi))^.5 else v = (2.*en_corr*energy/mass)^.5	; km/s  note - mass=mass/charge, energy=energy/charge, charge cancels

v = v>.001			; eliminate values too close to zero

; Note 	f ~ Counts/v^4 = C/v^4 
; 	dv/v = constant for logrithmic sweep
;	vd = integral(fv v^2dv)/integral(f v^2dv) = sum(C/v^4 * v^4 *dv/v)/sum(C/v^4 * v^3 *dv/v) = sum(C)/sum(C/v)


	corr_max = 10.
	if n_elements(kk3) gt 1 then begin
		corr = exp((kk3[dat.att_ind]/dat.energy)^2) < corr_max
	endif else corr=1.

;print,minmax(data/v)
;print,total(data),total(data/v),total(data)/total(data/v),total(corr*data)/total(corr*data/v)


if keyword_set(ms) then begin
;	vd = total(corr*(data-bkg)>0.)/total(((corr*(data-bkg)>0.)/v)>1.e-20)
	vd = (total(corr*(data-bkg))/total(corr*(data-bkg)/v))>1.e-20
endif else begin
;	vd = total(corr*(data-bkg)>0.,1)/total(((corr*(data-bkg)>0.)/v)>1.e-20,1)
	vd = (total(corr*(data-bkg),1)/total(corr*(data-bkg)/v,1))>1.e-20
endelse

if dat.mode eq 1 or dat.mode eq 7 then begin			; use fitting for mode 1,7

	vel = v[*,0]
	v0 = (total(corr*(data-bkg))/total(corr*(data-bkg)/v))>1.e-20
	vth = .5									; good enough default for periapsis
	if not keyword_set(mi) then mi=1.						; good enough default since this is just a scale factor
	df = total(corr*(data-bkg),2)*(.5*dat.mass*mi*v0^2/dat.energy[*,0])^2 		; must use dat.energy w/o scpot correction
	ind = where(total(data,2) ne 0,nind2)
	Amp = max(df,indmax)

	if indmax eq min(ind) or indmax eq max(ind) then begin
		print,'Fitting requires peak of beam not be an endpoint of the fit: time='+time_string(dat.time)
		return,vd
	endif

	; the following was for testing
	if 0 then begin
	if dat2.data_name eq 'c6 avg 32e64m co2' then begin
		tmp = mvn_sta_get_c6_avg(dat.time)
		if (tmp.time - dat.time) gt 1. then print,'Error #7'
		measure_error = 1.> total(tmp.cnts*data/(data+.00001),2)^.5*dat.dead[*,0]*corr[*,0]*(.5*dat.mass*mi*v0^2/energy[*,0])^2
	endif else if dat2.data_name eq 'c6 32e64m co2' then begin
		tmp = mvn_sta_get_c6(dat.time)
		if (tmp.time - dat.time) gt 1. then print,'Error #8'
		measure_error = 1.> total(tmp.cnts*data/(data+.00001),2)^.5*dat.dead[*,0]*corr[*,0]*(.5*dat.mass*mi*v0^2/energy[*,0])^2
	endif else begin
		measure_error = 1.> total(dat.cnts*data/(data+.00001),2)^.5*dat.dead[*,0]*corr[*,0]*(.5*dat.mass*mi*v0^2/energy[*,0])^2
	endelse
	endif

	;measure_error  = 1.> ((total((data-bkg)/dat.dead,2)>0.)^.5*dat.dead[*,0]*corr[*,0]*(.5*dat.mass*mi*v0^2/energy[*,0])^2)
	;measure_error  = 1.> ((total(cnts,2)>0.)   *dat.dead[*,0]*corr[*,0]*(.5*dat.mass*mi*v0^2/energy[*,0])^2)
	measure_error  = 1.> ((total(cnts,2)>0.)^.5*dat.dead[*,0]*corr[*,0]*(.5*dat.mass*mi*v0^2/energy[*,0])^2)

	if nind2 lt 4 then begin
		print,'Not enough data points for a vb_pot_4d fit:'+time_string(dat.time),'   nind2=',nind2,' pot=',dat.sc_pot
		return, vd
	endif

	param = gaussfit(vel[ind],df[ind],fit_coef,estimates=[Amp,v0,vth],nterms=3,sigma=sigma,chisq=chisq,yerror=yerror,measure_error=measure_error[ind])
	; param = gaussfit(vel[ind],df[ind],fit_coef,estimates=[Amp,v0,vth],nterms=3,sigma=sigma,chisq=chisq,yerror=yerror)

	if not finite(chisq) then begin
		print,'Chisq not finite '+time_string(dat.time),' chisq=',chisq
		return,vd
	endif
	vd = fit_coef[1]

	if keyword_set(plot) then begin
		cols=get_colors()
		if not keyword_set(oplot) and keyword_set(win) then window,win 
		if not keyword_set(oplot)then plot,vel,df,xlog=1,ylog=1,xrange=[3,10],xstyle=1,yrange=[10,10000],psym=-1,xtitle='Velocity km/s',ytitle='Scaled Counts',$
			title='vb_pot3_4d.pro fitting '+time_string(dat2.time)+' to '+time_string(dat2.end_time)
		if keyword_set(oplot)then oplot,vel,df,color=cols.blue	
		oplot,vel,fit_coef[0]*exp(-(vel-fit_coef[1])^2/(2.*fit_coef[2]^2)),color=200,psym=-1
		if keyword_set(oplot) then oplot,vel,fit_coef[0]*exp(-(vel-fit_coef[1])^2/(2.*fit_coef[2]^2)),color=cols.green,psym=-1
		oplot,[fit_coef[1],fit_coef[1]],[1,10000],color=cols.red
		if keyword_set(oplot) then oplot,[fit_coef[1],fit_coef[1]],[1,10000],color=cols.green
		print,df
		print,measure_error
		print,total(cnts,2)
	endif

endif

return, vd
end