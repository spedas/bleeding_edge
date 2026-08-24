;+
;FUNCTION:	nbc_nolpw_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt)
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
;	MASS:	intarr(nm)	optional, 
;PURPOSE:
;	Returns the density array, n, 1/cm^3, corrects for spacecraft potential if dat.sc_pot exists
;NOTES:	
;	Function normally called by "get_4dt" to 
;	generate time series data for "tplot.pro".
;
;CREATED BY:
;	J.McFadden	15-12-01	
;LAST MODIFICATION:
;-
function nbc_nolpw_4d,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt,correct=correct,scale=scale

common mvn_sta_kk3_anode,kk3_anode			; if kk3_anode is set to 1, then kk3 has anode dependence
common mvn_sta_kk3,kk3

;def_den = !Values.F_NAN
def_den = 0.

if dat2.valid eq 0 then begin
  print,'Invalid Data'
  return, def_den
endif

if (dat2.quality_flag and 195) gt 0 then return, def_den

;*****************************************************************************************************************
; this was for testing purposes using program mvn_load_atomic_oxygen_exposure.pro to set kk5
; the idea was to correct for possible hysteresis due to exposure to atomic oxygen through a pass 
; the approach was abandoned

if 0 then begin

	common mvn_sta_kk5,kk5,o_time,o_expose

	if keyword_set(kk5) then begin
		min_kk5=min(abs(o_time-dat2.time),ind_kk5)
		kk6 = kk5*o_expose[ind_kk5]
	endif else kk6=0.

;kk4 = (kk3[dat2.att_ind])
kk4 = (kk3[dat2.att_ind]^2 + kk6^2)^.5

endif else kk4 = kk3[dat2.att_ind]
;*****************************************************************************************************************


dat = conv_units(dat2,"counts")		; initially use counts
n_e = dat.nenergy
nb = dat.nbins
nm = dat.nmass

; this is included for low energy beams because the GF is larger because the ESA exit posts and TOF entrance posts do not attenuate the beam
dat.geom_factor = dat.geom_factor * 1.235

data = dat.cnts 
bkg = dat.bkg
energy = dat.energy
denergy = dat.denergy
theta = dat.theta/!radeg
phi = dat.phi/!radeg
dtheta = dat.dtheta/!radeg
dphi = dat.dphi/!radeg
domega = dat.domega
	if ndimen(domega) eq 0 then domega=replicate(1.,dat.nenergy)#domega
mass = dat.mass*dat.mass_arr 
pot = dat.sc_pot

; determine how many energy bins to use around the peak count rate
if n_e eq 64 then nne=8 
if n_e eq 32 then nne=4
if n_e le 16 then nne=2
if n_e eq 48 then nne=6		; when does this happen? is this for swia?
if dat.mode eq 7 then nne=nne*2

; remove measurement angle sectors if "bins" keyword is set
if keyword_set(bins) and nb gt 1 then begin
	bins2 = transpose(reform(bins#replicate(1.,n_e*nm),nb,nm,n_e),[2,0,1])
	data=data*bins2
	bkg = bkg*bins2
endif

; remove energy sectors if "energy" keyword is set
en_min = min(energy)
en_max = max(energy)
if keyword_set(en) then begin
	ind = where(energy lt en[0] or energy gt en[1],count)
	if count ne 0 then data[ind]=0.
	if count ne 0 then bkg[ind]=0.
	en_min = en_min > en[0]
	en_max = en_max < en[1]
endif

; remove mass sectors if "mass" keyword is set
if keyword_set(ms) then begin
	ind = where(dat.mass_arr lt ms[0] or dat.mass_arr gt ms[1],count)
	if count ne 0 then data[ind]=0.
	if count ne 0 then bkg[ind]=0.
endif

; the following limits the energy range to a few bins around the peak for cruise phase solar wind measurements of apid c0
; only acts on data before mars injection orbit
if dat.nmass eq 1 then begin
	if dat.time lt time_double('14-10-1') then begin
		maxcnt = max(data,mind)
		if n_e eq 64 then nnne=4 else nnne=nne
		data[0:(mind-nnne>0)]=0.
		data[((mind+nnne)<(n_e-1)):(n_e-1)]=0.
		bkg[0:(mind-nnne>0)]=0.
		bkg[((mind+nnne)<(n_e-1)):(n_e-1)]=0.
	endif	
endif

; this sets the maximum correction factor for ion supression
corr_max=30.

; limit the energy range to near the peak 
; including the ion suppression correction appears to make little difference because a shift of bins only includes empty low energy bins
	data2 = data
	corr = exp((kk4/energy)^2) < corr_max

	if ndimen(data) eq 2 then begin
		maxcnt = max(total(data,2),mind) 
		maxcnt2 = max(total(data*corr,2),mind2)
;print,mind,mind2,energy[mind],energy[mind2]
		if 0 then mind = (mind2 < (mind+nne/2)) 	; this doesn't seem to be needed
;print,mind
		data[0:(mind-nne>0),*]=0.
		data[((mind+nne)<(n_e-1)):(n_e-1),*]=0.
		bkg[0:(mind-nne>0),*]=0.
		bkg[((mind+nne)<(n_e-1)):(n_e-1),*]=0.
		en_peak=energy[mind,0]

	endif else if ndimen(data) eq 3 then begin
		maxcnt = max(total(total(data,3),2),mind) 
		maxcnt2 = max(total(total(data*corr,3),2),mind2)
;print,mind,mind2,energy[mind],energy[mind2]
		if 0 then mind = (mind2 < (mind+nne/2)) 	; this doesn't seem to be needed
;print,mind
		data[0:(mind-nne>0),*,*]=0.
		data[((mind+nne)<(n_e-1)):(n_e-1),*,*]=0.
		bkg[0:(mind-nne>0),*,*]=0.
		bkg[((mind+nne)<(n_e-1)):(n_e-1),*,*]=0.
		en_peak=energy[mind,0]

	endif else begin
		maxcnt = max(data,mind)
		data[0:(mind-nne>0)]=0.
		data[((mind+nne)<(n_e-1)):(n_e-1)]=0.
		bkg[0:(mind-nne>0)]=0.
		bkg[((mind+nne)<(n_e-1)):(n_e-1)]=0.
		en_peak=energy[mind]
	endelse


; if the number of counts near the peak is less than 75% of total counts in the energy range, then it is not a beam
	if total(data) lt .75*total(data2) then return,def_den

;print,energy[*,0]
;print,total(data),total(data2),total(bkg)
;print,total(data,2)
;print,total(data2,2)

if dat.nmass gt 1 then begin
	if keyword_set(mi) then begin
		dat.mass_arr[*]=mi & mass=dat.mass*dat.mass_arr 
	endif else begin
		dat.mass_arr[*]=round(dat.mass_arr-.1)>1. & mass=dat.mass*dat.mass_arr	; the minus 0.1 helps account for straggling at low mass
	endelse
endif else mass = dat.mass

;if keyword_set(mincnt) then if total(data) lt mincnt then return,0
if keyword_set(mincnt) then if total(data-bkg) lt mincnt then return, !Values.F_NAN
if total(data-bkg) lt 1 then return, !Values.F_NAN

;if en_peak lt 1.5*en_min or en_peak gt en_max/1.5 then return,def_den


; correct the data for ion suppression

;***********************************************************************
; the following was an early version of ion supression no longer used

if 0 then begin
; this was used for testing - now obsolete

   kk2 = mvn_sta_get_kk2(dat.time)

   kk2_def = 3.0
   if dat.nbins eq 1 then begin
	dat_ca = mvn_sta_get_ca(dat.time)
	if size(dat_ca,/type) eq 8 and not keyword_set(correct) then begin
		ca = total(reform(dat_ca.data,16,4,16),2)						; assume dist of cnts on anode independent of deflectors
		ca0 = ca/(total(ca,2)#replicate(1.,16)+.001)
		ca1 = reform(replicate(1.,n_e/16)#reform(ca0,256),n_e,16)
		corr = ((reform(ca1[*,7])#replicate(1.,nm))*(exp((kk2/energy)^2) < 20.) $
			+ ((total(ca1,2)-reform(ca1[*,7]))#replicate(1.,nm))*(exp((kk2_def/energy)^2) < 20.) ) > 1.   
		if 1 then begin 
			kk3= kk2*[0.1,0.1,0.1,0.1,0.1,0.3,0.7,1.0,0.7,0.3,0.1,0.1,0.1,0.1,0.1,0.1]
			kk3= kk2*[0.1,0.1,0.1,0.2,0.4,0.6,0.9,1.0,0.9,0.6,0.4,0.2,0.1,0.1,0.1,0.1]
			corr = total(reform((reform(transpose(ca1),16*n_e)#replicate(1.,nm))*(exp((kk3#reform(1./energy,n_e*nm))^2) < 20.),16,n_e,nm),1)	 
		endif  
	endif else begin
		corr = exp((kk2/energy)^2) < 20.
	endelse
   endif else begin 
	corr = exp((kk2/energy)^2) < 20.
   endelse
;***********************************************************************

endif else begin
; this method works better

;	corr = exp((kk2/energy)^2) < 100.
;	if dat.att_ind eq 3 then kk2=kk2-.6
;	if dat.att_ind eq 1 then kk2=kk2-.3
;	corr = exp((kk2/energy)^2) < 100.
	corr = exp((kk4/energy)^2) < corr_max

; 	the following attempts to adjust "corr" based on the fraction of counts in anode 7 - only works for c6 data products
;	this could work much better using the d1 data product
    if (keyword_set(correct) or kk3_anode) then begin

		if keyword_set(scale) then begin
			if dimen1(scale) ne 16 then return,0
			scale2 = scale/kk4
		endif else begin
			scale2 = [0.1,0.1,0.1,0.1,0.1,0.1,0.3,1.0,0.4,0.1,0.1,0.1,0.1,0.1,0.1,0.1]				; 20160303 guess at the anode ion suppression dependence
;			if dat.time gt time_double('2016-05-29') then scale2 = [0.0,0.0,0.0,0.0,0.3,0.5,0.8,1.8,0.8,0.6,0.4,0.0,0.0,0.0,0.0,0.0]/kk4
;			if dat.time gt time_double('2016-05-29') then scale2 = [0.0,0.0,0.0,0.0,0.1,0.2,0.4,1.0,0.6,0.3,0.1,0.0,0.0,0.0,0.0,0.0]				
			if dat.time gt time_double('2016-05-29') then scale2 = [0.0,0.0,0.0,0.0,0.1,0.2,0.4,1.0,0.5,0.3,0.1,0.0,0.0,0.0,0.0,0.0]		; good for att=1 on 20160529				
		endelse

; anode dependent ion supression correction formula varies with data product - only works for c6, c6e, d0, d1
;    note that d0,d1 with nb=1 occurs if you sum over anodes before operating - used for testing purposes
	if 1 then begin
	  if ((dat.data_name eq 'd0 32e4d16a8m' or dat.data_name eq 'd1 32e4d16a8m') and nb eq 1) then begin
		dat_ca = mvn_sta_get('ca',tt=[dat.time,dat.end_time]-4.)
;		dat_ca = mvn_sta_get_ca(dat.time)
		ca = reform(replicate(1.,2)#reform(total(reform(dat_ca.cnts,16,4,16),2),16*16),32,16)
		corr2 = exp((kk4*(replicate(1.,32)#scale2)/(reform(energy[*,0])#replicate(1.,16)))^2) < corr_max
		corr3 = (total(corr2*ca,2)/(total(ca,2)+.001)) > 1.
		corr = corr3#replicate(1.,8)
	  endif 
	  if ((dat.data_name eq 'd0 32e4d16a8m' or dat.data_name eq 'd1 32e4d16a8m') and nb eq 64) then begin
		scale2 = reform(replicate(1.,4)#scale2,64)
		corr2 = exp((kk4*(replicate(1.,32)#scale2)/(reform(energy[*,0,0])#replicate(1.,64)))^2) < corr_max
		corr3 = reform(corr2,32*64)
		corr = reform(corr3#replicate(1.,8),32,64,8)
	  endif 
	  if (dat.data_name eq 'c6 32e64m') then begin
		dat_ca = mvn_sta_get('ca',tt=[dat.time,dat.end_time]-4.)
;		dat_ca = mvn_sta_get_ca(dat.time)
		ca = reform(replicate(1.,2)#reform(total(reform(dat_ca.cnts,16,4,16),2),16*16),32,16)
		corr2 = exp((kk4*(replicate(1.,32)#scale2)/(reform(energy[*,0])#replicate(1.,16)))^2) < corr_max
		corr3 = (total(corr2*ca,2)/(total(ca,2)+.001)) > 1.
		corr = corr3#replicate(1.,64)
	  endif 
	  if (dat.data_name eq 'c6e 64e64m') then begin		dat_ca = mvn_sta_get_ca(dat.time)
		dat_ca = mvn_sta_get('ca',tt=[dat.time,dat.end_time]-4.)
;		dat_ca = mvn_sta_get_ca(dat.time)
		ca = reform(replicate(1.,4)#reform(total(reform(dat_ca.cnts,16,4,16),2),16*16),64,16)
		corr2 = exp((kk4*(replicate(1.,64)#scale2)/(reform(energy[*,0])#replicate(1.,16)))^2) < corr_max
		corr3 = (total(corr2*ca,2)/(total(ca,2)+.001)) > 1.
		corr = corr3#replicate(1.,64)
	  endif
	endif

    endif

endelse
;***********************************************************************

; the following line turns off ion suppression corrections for light ions since they are not centered on the ram anode
	ind = where(dat.mass_arr lt 8.,count)
	if count gt 0 then corr(ind) = 1.

; don't use ion suppression corrections when the s/c potential is not determined
	if pot ge 0. then corr=1.

tmp=dat
dat.gf=dat.gf/corr

;this line was needed before L2 processing completed 20160228 to account for error in mechanical attenuation - attM
;if dat.att_ind ge 2 then dat.gf=dat.gf*1.3

dat.cnts=data
dat.bkg=bkg

;may want to remove this line in the future once bkg is working ????????????????????????
;dat.bkg[*]=0.

; convert units subtracts bkg
dat = conv_units(dat,"df")		; Use distribution function
tmp = conv_units(tmp,"df")		; Use distribution function
data=dat.data
tmp2=tmp.data

Const = (mass)^(-1.5)*(2.)^(.5)
charge=dat.charge
if keyword_set(q) then charge=q

; adjust energies for spacecraft potential - note that pot=!values.f_nan will result in a NAN - this routine requires valid sc_pot 
	energy=(dat.energy+charge*dat.sc_pot/abs(charge))>0.		; energy/charge analyzer, require positive energy

if dat.nbins eq 1 then begin
	density2 = total(Const*denergy*(energy^(.5))*tmp2*2.*cos(theta)*sin(dtheta/2.)*dphi,1)
	density = total(Const*denergy*(energy^(.5))*data*2.*cos(theta)*sin(dtheta/2.)*dphi,1)
endif else begin	
	density2 = total(total(Const*denergy*(energy^(.5))*tmp2*2.*cos(theta)*sin(dtheta/2.)*dphi,1),1)
	density = total(total(Const*denergy*(energy^(.5))*data*2.*cos(theta)*sin(dtheta/2.)*dphi,1),1)
endelse	

;print,total(density),total(density2)
;print,total(density)/(total(density2)+1.e-7) 

if total(density)/(total(density2)+1.e-7) gt 50. then return,!values.f_nan

if keyword_set(ms) then density=total(density)
if keyword_set(ms) then density2=total(density2)

; units are 1/cm^3

return, density
end
