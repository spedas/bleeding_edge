;+
;FUNCTION:	tbc_4d(dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,m_int=mi,q=q,mincnt=mincnt)
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
;	Returns the temperature of a beam in units of eV, assumes no s/c charging
;NOTES:	
;	Function normally called by "get_4dt" to
;	generate time series data for "tplot.pro".
;	Designed to be called in mvn_sta_ti_en, so references some common blocks 
;	that might cause other codes to break. 
;
;CREATED BY:
;	J.McFadden	2014-02-27
;LAST MODIFICATION:
; G. Hanley 2021-09-21
;-
function tbc_4dl3,dat2,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins,MASS=ms,$
  m_int=mi,q=q,mincnt=mincnt,nne=nne,lpw=lpw,wide=wide,scpot_mult=scpot_mult,no_error=no_error 

def_ti = 0.
def_ti = !values.f_nan

common mvn_sta_temp_error, sta_c6_errtime, sta_c6error, sta_c8_errtime, sta_c8error
common mvn_sta_vd_cmn, do_vd, sta_c6_vd, sta_c6_vd_errtime, sta_c6_vd_error, sta_c8_vd, sta_c8_vd_errtime, sta_c8_vd_error

;if size(sta_c6error,/type) eq 0 then sta_c6error = []

if dat2.valid eq 0 then begin
	print,'Invalid Data'
	  if size(sta_c6error,/type) ne 0 then begin
	   sta_c6error = [sta_c6error, def_ti] 
	   sta_c6_errtime=[sta_c6_errtime, dat2.time]
	   if do_vd then begin
	     sta_c6_vd = [sta_c6_vd, def_ti]
	     sta_c6_vd_errtime = [sta_c6_vd_errtime, def_ti]
	     sta_c6_vd_error = [sta_c6_vd_error, def_ti]
	   endif
	  endif
	return, def_ti
endif

if (dat2.quality_flag and 195) gt 0 then begin
     if size(sta_c6error,/type) ne 0 then begin
      sta_c6error = [sta_c6error, def_ti]
      sta_c6_errtime=[sta_c6_errtime, dat2.time]
     if do_vd then begin
       sta_c6_vd = [sta_c6_vd, def_ti]
       sta_c6_vd_errtime = [sta_c6_vd_errtime, def_ti]
       sta_c6_vd_error = [sta_c6_vd_error, def_ti]
     endif
     endif
  return, def_ti
endif

if keyword_set(mi) and keyword_set(en) then begin
	if mi le 5. and max(en) le 200. and dat2.att_ind ge 2 then begin
	    if size(sta_c6error,/type) ne 0 then begin
      sta_c6error = [sta_c6error, def_ti]
      sta_c6_errtime=[sta_c6_errtime, dat2.time]
     if do_vd then begin
       sta_c6_vd = [sta_c6_vd, def_ti]
       sta_c6_vd_errtime = [sta_c6_vd_errtime, def_ti]
       sta_c6_vd_error = [sta_c6_vd_error, def_ti]
     endif
     endif
	 return,def_ti
	endif
endif

common mvn_lpw_pot_c6,mvn_lpw_pot_c6_dat 		; this is used by c6 data to correct for LPW produces scpot changes during a STATIC energy sweep

; the following can be used to speed up calculations, function should only should be used at low altitudes
; if (total(dat2.pos_sc_mso^2) gt (3386+600.)^2) and dat2.data_name eq 'd1e 32e4d16a8m' then return,def_ti  
dat_nobg = dat2
dat_nobg.bkg[*,*,*] = 0.

dat = omni4d(dat2,bins=bins)
dat_nobg = omni4d(dat_nobg,bins=bins)

dat = conv_units(dat,"df")		; convert to distribution function
dat_nobg = conv_units(dat_nobg,"df")

n_e = dat.nenergy

gf_scale = (replicate(1.,n_e)#reform(dat.gf[0,*]))/dat.gf 	; this is just for testing, comparing calculations with df and cnts
cnts = dat.cnts						
data = dat.data
bkg  = dat.bkg 
dead = dat.dead
energy = dat.energy
 
data_nobg = dat_nobg.data

get_data, 'alt',data=altdat
altd=min(abs(altdat.x-dat.time),closest)
alt=altdat.y[closest]

; calculate correction for ion suppression

common mvn_sta_kk1,kk1,kk1_trange
corr = mvn_sta_get_kk(dat2)

; determine how many energy bins to use around the peak - may want to change this to a better method

;;;; NEW  -- FOR C6 USE THE MODE TO DECIDE HOW MANY BINS 

if not keyword_set(nne) then begin
	if n_e eq 64 then nne=6 
	if n_e eq 32 then begin
	 if dat2.mode eq 1 then nne=4
	 if dat2.mode ge 2 then nne=6 ;; this is the new part, it used to just be 4
	 wide=0
	 if keyword_set(wide) then nne = 20
	endif
	if n_e le 16 then nne=2
	if n_e eq 48 then nne=6		; when does this happen? is this for swia?
	if dat.mode eq 7 then nne=2*nne
endif

; limit energy range if explicitly input - for cold thermal ions generally want en=[0,11] so attenuator transitions don't matter

en_min = min(energy)
en_max = max(energy)
if keyword_set(en) then begin
	ind = where(energy lt en[0] or energy gt en[1],count)
	if count ne 0 then data[ind]=0.
	if count ne 0 then cnts[ind]=0.
	if count ne 0 then bkg[ind]=0.
	if count ne 0 then data_nobg[ind]=0.
	en_min = en_min > en[0]
	en_max = en_max < en[1]
endif

; limit the mass range to a single ion with explicit input - this should be used

if keyword_set(ms) then begin
	ind = where(dat.mass_arr lt ms[0] or dat.mass_arr gt ms[1],count)
	if count ne 0 then data[ind]=0.
	if count ne 0 then cnts[ind]=0.
	if count ne 0 then bkg[ind]=0.
	if count ne 0 then data_nobg[ind]=0.
endif

; the following limits the energy range to a few bins around the peak for cruise phase solar wind measurements

if dat.nmass eq 1 then begin
	if dat.time lt time_double('14-10-1') then begin
		maxcnt = max(data,mind)
		if n_e eq 64 then nnne=4 else nnne=nne
		data[0:(mind-nnne>0)]=0.
		data[((mind+nnne)<(n_e-1)):(n_e-1)]=0.
		cnts[0:(mind-nnne>0)]=0.
		cnts[((mind+nnne)<(n_e-1)):(n_e-1)]=0.
		bkg[0:(mind-nnne>0)]=0.
		bkg[((mind+nnne)<(n_e-1)):(n_e-1)]=0.
		data_nobg[0:(mind-nnne>0)]=0.
		data_nobg[((mind+nnne)<(n_e-1)):(n_e-1)]=0.
	endif	
endif

; limit the energy range to near the peak for nominal Mars data

	data2 = data
	cnts2 = cnts
	if ndimen(data) eq 2 then begin
		maxcnt = max(total(cnts,2),mind) 
		data[0:(mind-nne>0),*]=0.
		data[((mind+nne)<(n_e-1)):(n_e-1),*]=0.
		cnts[0:(mind-nne>0),*]=0.
		cnts[((mind+nne)<(n_e-1)):(n_e-1),*]=0.
		bkg[0:(mind-nne>0),*]=0.
		bkg[((mind+nne)<(n_e-1)):(n_e-1),*]=0.
		en_peak=energy[mind,0]
		data_nobg[0:(mind-nne>0),*]=0.
		data_nobg[((mind+nne)<(n_e-1)):(n_e-1),*]=0.
	endif else begin
		maxcnt = max(cnts,mind)
		data[0:(mind-nne>0)]=0.
		data[((mind+nne)<(n_e-1)):(n_e-1)]=0.
		cnts[0:(mind-nne>0)]=0.
		cnts[((mind+nne)<(n_e-1)):(n_e-1)]=0.
		bkg[0:(mind-nne>0)]=0.
		bkg[((mind+nne)<(n_e-1)):(n_e-1)]=0.
		en_peak=energy[mind]
		data_nobg[0:(mind-nne>0)]=0.
		data_nobg[((mind+nne)<(n_e-1)):(n_e-1)]=0.
	endelse

; if the number of counts near the peak is less than 75% of total counts in the energy range, then it is not a beam

	if total(cnts) lt .75*total(cnts2) then begin
	 if size(sta_c6error,/type) ne 0 then begin
      sta_c6error = [sta_c6error, def_ti]
      sta_c6_errtime=[sta_c6_errtime, dat2.time]
     if do_vd then begin
       sta_c6_vd = [sta_c6_vd, def_ti]
       sta_c6_vd_errtime = [sta_c6_vd_errtime, def_ti]
       sta_c6_vd_error = [sta_c6_vd_error, def_ti]
     endif
     endif
	 return,def_ti
	endif

; treat low energy outliers with only one count as noise 

	ind = where(cnts le 1.1 and energy lt 0.6*en_peak,count)
	if count gt 0 then data[ind]=0
	if count gt 0 then cnts[ind]=0
	if count gt 0 then bkg[ind]=0
  if count gt 0 then data_nobg[ind]=0

; correct for ion suppression

	data = data*corr
	data_nobg = data_nobg*corr



; print,en_peak,en_min,en_max

; get rid of low count measurements and those whose peak is too close to energy limits

if keyword_set(mincnt) then if total(cnts) lt mincnt then begin
   if size(sta_c6error,/type) ne 0 then begin
      sta_c6error = [sta_c6error, def_ti]
      sta_c6_errtime=[sta_c6_errtime, dat2.time]
     if do_vd then begin
       sta_c6_vd = [sta_c6_vd, def_ti]
       sta_c6_vd_errtime = [sta_c6_vd_errtime, def_ti]
       sta_c6_vd_error = [sta_c6_vd_error, def_ti]
     endif
     endif
  return,def_ti
 endif
if en_peak lt 1.5*en_min or en_peak gt en_max/1.5 then begin
   if size(sta_c6error,/type) ne 0 then begin
      sta_c6error = [sta_c6error, def_ti]
      sta_c6_errtime=[sta_c6_errtime, dat2.time]
     if do_vd then begin
       sta_c6_vd = [sta_c6_vd, def_ti]
       sta_c6_vd_errtime = [sta_c6_vd_errtime, def_ti]
       sta_c6_vd_error = [sta_c6_vd_error, def_ti]
     endif
     endif
  return,def_ti
endif
charge=dat.charge
if keyword_set(q) then charge=q
if keyword_set(scpot_mult) then dat.sc_pot = scpot_mult*dat.sc_pot 
sc_pot=dat.sc_pot



;if sc_pot eq 0. and keyword_set(mi) then if mi lt 5. then sc_pot = -1.1*energy[mind+1,0]  
;if keyword_set(mi) then if mi lt 5. then sc_pot = -1.1*energy[mind+1,0]  


; adjust energies for spacecraft potential - note that pot=!values.f_nan will result in a NAN - this routine requires valid sc_pot 
	energy=(dat.energy+charge*dat.sc_pot/abs(charge))>0.		; energy/charge analyzer, require positive energy

if size(mvn_lpw_pot_c6_dat,/type) eq 8 and dat.data_name eq 'c6 32e64m' and not keyword_set(lpw) then begin
	minval = min(abs(mvn_lpw_pot_c6_dat.time-dat.time),lpw_ind)
	offset_pot = mvn_lpw_pot_c6_dat.pot[lpw_ind,mind]
	lpw_pot = reform(mvn_lpw_pot_c6_dat.pot[lpw_ind,*]-offset_pot)#replicate(1.,64)
	energy=(dat.energy+charge*(dat.sc_pot-lpw_pot)/abs(charge))>0.
endif

;data[where(energy eq 0)] = 0.

; Note - we don't need to divide by mass

u = (2.*dat.energy*charge)^.5			; use this velocity for corrections to distribution function
v = (2.*energy*charge)^.5			; ESA measures energy/charge


v = v>0.001

; Notes	f ~ Counts/u^4 = C/u^4 
;	u^2 = v^2 + 2e*pot/m => 2udu = 2vdv => dv = du/u * (u^2/v)
; 	du/u = constant for logrithmic sweep
;	dv = d((2E/m)^.5) = (du/u)*(u^2/v)
;	vd = integral(fv dv)/integral(f dv) 
;	T/m = integral(f(v-vd)^2 dv)/integral(f dv)

if keyword_set(ms) then begin
	vd = total(data*u^2)/(total(data*u^2/v)>1.e-20)
	vd2 = total(cnts*corr*dead*gf_scale/u^2)/(total(cnts*corr*dead*gf_scale/u^2/v)>1.e-20)
	vd_nobg = total(data_nobg*u^2)/(total(data_nobg*u^2/v)>1.e-20)
;print,vd,vd2
;	if keyword_set(mi) then if mi lt 5. then vd=0				; not sure about how this is affected by lack of sc_pot
	tm  = total((v-vd)^2*data*u^2/v)/(total(data*u^2/v)>1.e-20)
	tm2  = total((v-vd)^2*cnts*corr*dead*gf_scale/u^2/v)/(total(cnts*corr*dead*gf_scale/u^2/v)>1.e-20)
	tm_nobg = total((v-vd_nobg)^2*data_nobg*u^2/v)/(total(data_nobg*u^2/v)>1.e-20)
;print,tm,tm2
endif else begin
	vd = total(data*u^2,1)/(total(data*u^2/v,1)>1.e-20)
	vd = replicate(1.,n_e)#reform(vd,n_elements(vd))
	tm  = total((v-vd)^2*data*u^2/v,1)/(total(data*u^2/v,1)>1.e-20)
endelse

;tmold = sta_c6error
;sta_c6error = tm

engyplot = energy[*,0]
o2mass = 32. * 938d6 / (3d5)^2 
cntsplot = total(data,2)
cntsplot_nobg = total(data_nobg,2)
mxplot = max(cntsplot)*exp(- o2mass*(v-vd)^2 /tm)


;;;;;; end of jim's code, begin gwen's code


;;;;;;;;;;;;;; UNCERTAINTY CALCULATION 
; the only reason to have valid=1 is to stop IDL from attempting to index mvn_sta_c6temp_staterr as a variable
if ~keyword_set(no_error) then begin
  errdat = omni4d(dat2,bins=bins)
errdat.units_name=dat.units_name
;errdat.energy = energy
errdat.sc_pot = sc_pot
errdat.data = data
errdat.cnts = cnts
errdat.bkg = bkg
;if tm lt 0.03 then stop
tm_unc = mvn_sta_c6temp_staterr(errdat,vd,tm,corr,valid=1)
if size(sta_c6error,/type) ne 0 then sta_c6error = [sta_c6error, tm_unc] & sta_c6_errtime=[sta_c6_errtime, dat2.time] 
endif else begin
   if size(sta_c6error,/type) ne 0 then sta_c6error = [sta_c6error, def_ti] & sta_c6_errtime=[sta_c6_errtime, dat2.time]
endelse

; if the temp is tiny then something went wrong so return NaN
if tm le 1d-5 then tm = !values.F_NAN

if do_vd then sta_c6_vd = [sta_c6_vd,vd/sqrt(mi*938d6/(3d5)^2)]  
return, tm

;return, tm				; Eavg (eV) = integral(.5mv^2 f dv)/integral(f dv);   vth^2 = 2T/m ; Eavg=T/2

end
