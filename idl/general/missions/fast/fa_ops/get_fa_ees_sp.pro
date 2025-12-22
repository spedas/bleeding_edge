;+
;FUNCTION:	get_fa_ees_sp(time,START=start,EN=en,ADVANCE=advance,RETREAT=retreat,CALIB=calib)
;INPUT:
;	time:	real		This argument gives a time handle from which
;				to take data from.  It may be either a string
;				with the following possible formats:
;					'MM-DD-YY/HH:MM:SS.MSC'  or
;					'HH:MM:SS'     (use reference date)
;				or a number, which will represent seconds
;				since 1970 (must be a double > 94608000.D), or
;				a hours from a reference time, if set.
;				Time will always be returned as a double
;				representing the actual data time found in
;				seconds since 1970.
;;KEYWORDS:
;	START:			If non-zero, get data from the start time
;				of the data instance in the SDT buffers
;	EN:			If non-zero, get data at the end time
;				of the data instance in the SDT buffers
;	ADVANCE:		If non-zero, advance to the next data point
;				following the time input
;	RETREAT:		If non-zero, retreat (reverse) to the previous
;				data point before the time input
;	CALIB:			If non-zero, use the esa calibration array
;	VARARR			If non-zero, program will not convert to 48 Energy
;				by 32 angle arrays.
;PURPOSE:
;	To generate fast eesa survey data structures averaged over one spin.
;;NOTES:
;	Program calls get_fa_ees_c.pro multiple times to generate spin averaged data.
;	Data is averaged starting at the first "spin phase"=0 after "time".
;	Program checks for header changes, returns dat.valid=2 if less than 1 spin averaged.
;	Program only return 48 Energies x 32 Angles, will average if in 96 E or 64 A mode.
;	See get_fa_ees_c.pro
;CREATED BY:
;	J.McFadden	96-7-2	
;LAST MODIFICATION:  97/03/04
;MOD HISTORY:
;		97/03/04	CALIB keyword added
;		97/07/23	uses get_fa_ees_c.pro now
;-

FUNCTION get_fa_ees_sp,time,START=start,EN=en,ADVANCE=advance,RETREAT=retreat,CALIB=calib,VARARR=vararr

;	Get first 2 samples

dat = get_fa_ees_c(time,START=start,EN=en,ADVANCE=advance,RETREAT=retreat,CALIB=calib)
	if (not dat.valid) then return,dat
dat2 = get_fa_ees_c(time,/ad,CALIB=calib)
	if (not dat2.valid) then return,dat2

hdr = eiesa_unpack_surv_hdr(dat)
hdr2 = eiesa_unpack_surv_hdr(dat2)

;	Need to check the following lines for the 24 energy case!!!!!
;	Check for the start of a spin

niter=0
while ((hdr.spin_phase gt 8) or ((hdr2.spin_phase gt 8) and ((64-hdr.nangle)*(96-hdr.nenergy) ne 0)) $
	or (hdr.spin_number ne hdr2.spin_number)) do begin

	dat=dat2
	hdr=hdr2
	dat2 = get_fa_ees_c(time,/ad,CALIB=calib)
	if (not dat2.valid) then return,dat2
	hdr2 = eiesa_unpack_surv_hdr(dat2)

	if niter gt 32 then begin
		print,'Attempt to get by bad data segment, skipping ahead 5 sec, at: ',time_to_str(time)
		time=time+5.
		niter=0
	endif 
	if niter gt 120 then begin
		print,'Bad data segment in sdt memory, exitting get_fa_ees_sp.pro'
		dat2.valid=2
		return,dat2
	endif
	niter=niter+1

endwhile

;	Average the data over 1 spin

hdr_ind=[6,7,8]
dat = sum3d_hdr(dat,dat2,HDR_IND=hdr_ind,/spin)
avgs_spin = 12288/(hdr.nenergy*hdr.sweeps_per_avg*hdr.accum)
navg = 2
while dat.valid eq 1 and navg lt avgs_spin do begin
	dat=sum3d_hdr(dat,get_fa_ees_c(time,/ad,CALIB=calib),HDR_IND=hdr_ind,/spin)
	navg = navg + 1
endwhile

;	Force data into 48 energies x 32 angles

if not keyword_set(vararr) and dat.nenergy eq 96 then begin
;	print,'Converting to 48 energy bins'

	ind1=2*indgen(48)
	ind2=ind1+1
	integ_t2=2.*dat.integ_t
	nbins2=dat.nbins
	nenergy2=dat.nenergy/2
	data2=dat.data(ind1,*)+dat.data(ind2,*)
	energy2=(dat.energy(ind1,*)+dat.energy(ind2,*))/2.
	theta2=(dat.theta(ind1,*)+dat.theta(ind2,*))/2.
	if ndimen(dat.geom) eq 1 then geom2=dat.geom
	if ndimen(dat.geom) eq 2 then geom2=(dat.geom(ind1,*)+dat.geom(ind2,*))/2.
	denergy2=dat.denergy(ind1,*)+dat.denergy(ind2,*)
	dtheta2=dat.dtheta
	eff2=(dat.eff(ind1,*)+dat.eff(ind2,*))/2.

	datastr={data_name:dat.data_name,valid:dat.valid, $
	project_name:dat.project_name,units_name:dat.units_name, $
	units_procedure:dat.units_procedure,time:dat.time, $
	end_time:dat.end_time,integ_t:integ_t2,nbins:nbins2, $
	nenergy:nenergy2,data:data2,energy:energy2,theta:theta2, $
	geom:geom2,denergy:denergy2,dtheta:dtheta2,eff:eff2, $
	mass:dat.mass,geomfactor:dat.geomfactor,header_bytes:dat.header_bytes}
	dat=datastr 

endif

if not keyword_set(vararr) and dat.nbins eq 64 then begin
;	print,'Converting to 32 angle bins'

	ind1=2*indgen(32)
	ind2=ind1+1
	ind1=shift(ind1,-1)
	integ_t2=2.*dat.integ_t
	nbins2=dat.nbins/2
	nenergy2=dat.nenergy
	data2=dat.data(*,ind1)+dat.data(*,ind2)
	energy2=(dat.energy(*,ind1)+dat.energy(*,ind2))/2.
	theta2=((dat.theta(*,ind1)+dat.theta(*,ind2) + (dat.theta(*,ind1) gt dat.theta(*,ind2))*360.))/2. mod 360.
	if ndimen(dat.geom) eq 1 then geom2=(dat.geom(ind1)+dat.geom(ind2))/2.
	if ndimen(dat.geom) eq 2 then geom2=(dat.geom(*,ind1)+dat.geom(*,ind2))/2.
	denergy2=(dat.denergy(*,ind1)+dat.denergy(*,ind2))/2.
	dtheta2=dat.dtheta(*,ind1)+dat.dtheta(*,ind2)
	eff2=dat.eff

	datastr={data_name:dat.data_name,valid:dat.valid, $
	project_name:dat.project_name,units_name:dat.units_name, $
	units_procedure:dat.units_procedure,time:dat.time, $
	end_time:dat.end_time,integ_t:integ_t2,nbins:nbins2, $
	nenergy:nenergy2,data:data2,energy:energy2,theta:theta2, $
	geom:geom2,denergy:denergy2,dtheta:dtheta2,eff:eff2, $
	mass:dat.mass,geomfactor:dat.geomfactor,header_bytes:dat.header_bytes}
	dat=datastr 
endif

return,dat

end



