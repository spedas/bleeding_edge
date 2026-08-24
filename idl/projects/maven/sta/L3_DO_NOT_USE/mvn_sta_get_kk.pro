;+
;FUNCTION:	mvn_sta_get_kk(dat)
;PURPOSE:
;	Returns the geometric factor correction array, "corr", that corrects for ion suppression
;	Ions suppression is a de-tuning of the STATIC ESA due to exposure to the atmosphere - probably atomic oxygen
;	Detuning reduces the ion throughput at low energies
;	Ion suppression is modeled as follows  corr = exp(-(kk/energy)^2), where kk depends on the anode 
;	kk is largest in the sector that measures ram ions, and fall off rapidly away from this sector
;	nominal kk values are 1.5eV to 3.5eV for the ram sector, although values reached as high as 7eV in July 2015
;	kk is attenuator dependent with calibrated time dependent values stored in mvn_sta_get_kk1.pro
;INPUT:	
;	dat:	structure	data structure		
;NOTES:	
;	This function is normally called by static moment routines - nbc_4d.pro, jbc_4d.pro, etc
;	Returns an array with dimension of dat.gf 
; 	Implement the correction factor as follows: dat.gf=dat.gf/corr
;	For products like c6 where nbin=1, it uses "ca" data products to determine the anode distribution
;
;CREATED BY:
;	J.McFadden	19-06-14	
;LAST MODIFICATION:
;-
function mvn_sta_get_kk,dat2

common mvn_sta_kk1,kk1,kk1_trange

def_corr = 1.

	if dat2.valid eq 0 then begin
		print,'Invalid Data'
		return, def_corr
	endif

	if (dat2.quality_flag and 195) gt 0 then return, def_corr

; don't use ion suppression corrections when the s/c potential is not determined
	if dat2.sc_pot ge 0. then begin
		return, def_corr
	endif


time = (dat2.time+dat2.end_time)/2.

; load kk1 into the common if needed
	if not keyword_set(kk1) then kk1=mvn_sta_get_kk1(time) 
	if time lt kk1_trange[0] or time gt kk1_trange[1] then kk1=mvn_sta_get_kk1(time) 

kk4 = kk1[dat2.att_ind]
nb = dat2.nbins
energy = dat2.energy
dat=dat2

; this sets the maximum correction factor for ion supression
	corr_max=30.

; this anode dependence could eventually be made a function of time 

;	if dat.time gt time_double('2016-05-29') then scale2 = [0.0,0.0,0.0,0.0,0.1,0.2,0.4,1.0,0.5,0.3,0.1,0.0,0.0,0.0,0.0,0.0]		; good for att=1 on 20160529				
	scale2 = [0.0,0.0,0.0,0.0,0.1,0.2,0.4,1.0,0.5,0.3,0.1,0.0,0.0,0.0,0.0,0.0]		; good for att=1 on 20160529				

; anode dependent ion supression correction formula varies with data product - only works for c6, c6e, d0, d1
;    note that d0,d1 with nb=1 occurs if you sum over anodes with omni4d.pro before operating - used for testing purposes

	  if ((dat2.data_name eq 'd0 32e4d16a8m' or dat2.data_name eq 'd1 32e4d16a8m') and nb eq 1) then begin
		dat_ca = mvn_sta_get('ca',tt=[dat.time,dat.end_time]-4.)
		ca = reform(replicate(1.,2)#reform(total(reform(dat_ca.cnts,16,4,16),2),16*16),32,16)
		corr2 = exp((kk4*(replicate(1.,32)#scale2)/(reform(energy[*,0])#replicate(1.,16)))^2) < corr_max
		corr3 = (total(corr2*ca,2)/(total(ca,2)+.001)) > 1.
		corr = corr3#replicate(1.,8)
	  endif 
	  if ((dat2.data_name eq 'd0 32e4d16a8m' or dat2.data_name eq 'd1 32e4d16a8m') and nb eq 64) then begin
		scale2 = reform(replicate(1.,4)#scale2,64)
		corr2 = exp((kk4*(replicate(1.,32)#scale2)/(reform(energy[*,0,0])#replicate(1.,64)))^2) < corr_max
		corr3 = reform(corr2,32*64)
		corr = reform(corr3#replicate(1.,8),32,64,8)
	  endif 
	  if (dat2.data_name eq 'c6 32e64m') then begin
		dat_ca = mvn_sta_get('ca',tt=[dat.time,dat.end_time]-4.)
		ca = reform(replicate(1.,2)#reform(total(reform(dat_ca.cnts,16,4,16),2),16*16),32,16)
		corr2 = exp((kk4*(replicate(1.,32)#scale2)/(reform(energy[*,0])#replicate(1.,16)))^2) < corr_max
		corr3 = (total(corr2*ca,2)/(total(ca,2)+.001)) > 1.
		corr = corr3#replicate(1.,64)
	  endif 
	  if (dat2.data_name eq 'c6e 64e64m') then begin		dat_ca = mvn_sta_get_ca(dat.time)
		dat_ca = mvn_sta_get('ca',tt=[dat.time,dat.end_time]-4.)
		ca = reform(replicate(1.,4)#reform(total(reform(dat_ca.cnts,16,4,16),2),16*16),64,16)
		corr2 = exp((kk4*(replicate(1.,64)#scale2)/(reform(energy[*,0])#replicate(1.,16)))^2) < corr_max
		corr3 = (total(corr2*ca,2)/(total(ca,2)+.001)) > 1.
		corr = corr3#replicate(1.,64)
	  endif


;***********************************************************************

; the following line turns off ion suppression corrections for light ions when nb=1 since they are not centered on the ram anode
	if nb eq 1 then begin
		ind = where(dat2.mass_arr lt 8.,count)
		if count gt 0 then corr(ind) = 1.
	endif

; the following line turns off ion suppression corrections for ions greater than 11 eV since these corrections should be small and can't be modeled
	ind = where(dat2.energy gt 11.,count)
	if count gt 0 then corr(ind) = 1.

; implement the correction factor as follows: dat.gf=dat.gf/corr

return, corr

end
