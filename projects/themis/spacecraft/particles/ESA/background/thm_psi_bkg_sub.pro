;+
;FUNCTION:	thm_psi_bkg_sub(dat)
;INPUT:	
;	dat:	data structure (n,3)	vector arrays dimension (n,3) or (3)
;PURPOSE:
;	returns psi data structure with background subtracted, run thm_psi_bkg_set.pro first
;
;
;Assumptions
;	Assumes thm_psi_bkg_set.pro has been run
;	Assumes input distribution is in counts
;	Output distribution will have no negative numbers
;
;CREATED BY:
;	J.McFadden	08-12-30
;Modifications
;	mcfadden	09-02-03	modified to work for both atten on and off
;		 
;-
function thm_psi_bkg_sub,dat2

dat=dat2

sc = strlowcase(strmid(dat.project_name,7,1))
dt = dat.end_time-dat.time

; set up commons

	if sc eq 'a' then begin
		common tha_psi_bkg,tha_psir1_on,tha_psir6_on,tha_psif_on,tha_psir1_off,tha_psir6_off,tha_psif_off,dt_ar1_on,dt_ar6_on,dt_af_on,dt_ar1_off,dt_ar6_off,dt_af_off
	endif else if sc eq 'b' then begin
		common thb_psi_bkg,thb_psir1_on,thb_psir6_on,thb_psif_on,thb_psir1_off,thb_psir6_off,thb_psif_off,dt_br1_on,dt_br6_on,dt_bf_on,dt_br1_off,dt_br6_off,dt_bf_off
	endif else if sc eq 'c' then begin
		common thc_psi_bkg,thc_psir1_on,thc_psir6_on,thc_psif_on,thc_psir1_off,thc_psir6_off,thc_psif_off,dt_cr1_on,dt_cr6_on,dt_cf_on,dt_cr1_off,dt_cr6_off,dt_cf_off
	endif else if sc eq 'd' then begin
		common thd_psi_bkg,thd_psir1_on,thd_psir6_on,thd_psif_on,thd_psir1_off,thd_psir6_off,thd_psif_off,dt_dr1_on,dt_dr6_on,dt_df_on,dt_dr1_off,dt_dr6_off,dt_df_off
	endif else if sc eq 'e' then begin
		common the_psi_bkg,the_psir1_on,the_psir6_on,the_psif_on,the_psir1_off,the_psir6_off,the_psif_off,dt_er1_on,dt_er6_on,dt_ef_on,dt_er1_off,dt_er6_off,dt_ef_off
	endif else if sc eq 'f' then begin
		common thf_psi_bkg,thf_psir1_on,thf_psir6_on,thf_psif_on,thf_psir1_off,thf_psir6_off,thf_psif_off,dt_fr1_on,dt_fr6_on,dt_ff_on,dt_fr1_off,dt_fr6_off,dt_ff_off
	endif

; subtract the background
; the factor dt/dt_xr accounts for any changes in spin rate or data averaging

bkg=0.

if dat2.atten eq 5 then begin
	if dat.nbins eq 1 then begin
		case sc of 
			'a' : bkg = tha_psir1_on*dt/dt_ar1_on
			'b' : bkg = thb_psir1_on*dt/dt_br1_on
			'c' : bkg = thc_psir1_on*dt/dt_cr1_on
			'd' : bkg = thd_psir1_on*dt/dt_dr1_on
			'e' : bkg = the_psir1_on*dt/dt_er1_on
			'f' : bkg = thf_psir1_on*dt/dt_fr1_on
		endcase		
	endif else if dat.nbins eq 6 then begin
		case sc of 
			'a' : bkg = tha_psir6_on*dt/dt_ar6_on
			'b' : bkg = thb_psir6_on*dt/dt_br6_on
			'c' : bkg = thc_psir6_on*dt/dt_cr6_on
			'd' : bkg = thd_psir6_on*dt/dt_dr6_on
			'e' : bkg = the_psir6_on*dt/dt_er6_on
			'f' : bkg = thf_psir6_on*dt/dt_fr6_on
		endcase
	endif else if dat.nbins eq 64 then begin
		case sc of 
			'a' : bkg = tha_psif_on*dt/dt_af_on
			'b' : bkg = thb_psif_on*dt/dt_bf_on
			'c' : bkg = thc_psif_on*dt/dt_cf_on
			'd' : bkg = thd_psif_on*dt/dt_df_on
			'e' : bkg = the_psif_on*dt/dt_ef_on
			'f' : bkg = thf_psif_on*dt/dt_ff_on
		endcase
	endif
endif else begin
	if dat.nbins eq 1 then begin
		case sc of 
			'a' : bkg = tha_psir1_off*dt/dt_ar1_off
			'b' : bkg = thb_psir1_off*dt/dt_br1_off
			'c' : bkg = thc_psir1_off*dt/dt_cr1_off
			'd' : bkg = thd_psir1_off*dt/dt_dr1_off
			'e' : bkg = the_psir1_off*dt/dt_er1_off
			'f' : bkg = thf_psir1_off*dt/dt_fr1_off
		endcase		
	endif else if dat.nbins eq 6 then begin
		case sc of 
			'a' : bkg = tha_psir6_off*dt/dt_ar6_off
			'b' : bkg = thb_psir6_off*dt/dt_br6_off
			'c' : bkg = thc_psir6_off*dt/dt_cr6_off
			'd' : bkg = thd_psir6_off*dt/dt_dr6_off
			'e' : bkg = the_psir6_off*dt/dt_er6_off
			'f' : bkg = thf_psir6_off*dt/dt_fr6_off
		endcase
	endif else if dat.nbins eq 64 then begin
		case sc of 
			'a' : bkg = tha_psif_off*dt/dt_af_off
			'b' : bkg = thb_psif_off*dt/dt_bf_off
			'c' : bkg = thc_psif_off*dt/dt_cf_off
			'd' : bkg = thd_psif_off*dt/dt_df_off
			'e' : bkg = the_psif_off*dt/dt_ef_off
			'f' : bkg = thf_psif_off*dt/dt_ff_off
		endcase
	endif
endelse



; determine whether there are bad sectors where the bkg subtraction dominates in psif
; assume no more than 4 sectors in a row are NANs

if dat.nbins eq 64 then begin


	data  = dat.data

	id=total(data,1)
		if id(55) eq 0 then begin
			data(*,54) = 2.*data(*,54)
			data(*,55) = !values.f_nan
			data(*,56) = !values.f_nan
		endif
		if id(47) eq 0 then begin
			data(*,46) = 2.*data(*,46)
			data(*,47) = !values.f_nan
			data(*,32) = !values.f_nan
		endif

	data = data - bkg

	ind = where((data+1. lt bkg/3.) or (data+1. lt 2.*bkg^.5) ,count)

	if count ne 0 then data[*,ind]=!values.f_nan

	if dat.project_name eq 'THEMIS D' and total(data[*,34]) gt 2.*total(data[*,35]) then begin
		data[*,34]=!values.f_nan
		count=count+1
	endif

; 	replace bad sectors

	ind = where(~finite(data),count)
count=0
	if count ne 0 then begin

		ind1 = indgen(16*64)
		aind = ind1/16
		eind = ind1 - aind*16
		pind = ((aind - (aind mod 16)) + ((aind+1 ) mod 16))*16 + eind
		mind = ((aind - (aind mod 16)) + ((aind+15) mod 16))*16 + eind

		rind = where(~finite(data) and finite(data[pind]) and finite(data[mind]),count)
		if count ne 0 then data[rind] = (data[pind[rind]]+data[mind[rind]])/2.
		rind = where(~finite(data) and finite(data[pind]) and ~finite(data[mind]),count)
		if count ne 0 then data[rind] = data[pind[rind]]
		rind = where(~finite(data) and finite(data[mind]) and ~finite(data[pind]),count)
		if count ne 0 then data[rind] = data[mind[rind]]

		ind = where(~finite(data),count)
		if count ne 0 then begin

			rind = where(~finite(data) and finite(data[pind]) and finite(data[mind]),count)
			if count ne 0 then data[rind] = (data[pind[rind]]+data[mind[rind]])/2.
			rind = where(~finite(data) and finite(data[pind]) and ~finite(data[mind]),count)
			if count ne 0 then data[rind] = data[pind[rind]]
			rind = where(~finite(data) and finite(data[mind]) and ~finite(data[pind]),count)
			if count ne 0 then data[rind] = data[mind[rind]]
		
		endif

	endif

	ind = where(~finite(data),count)
	if count ne 0 then print,' Error in background subtraction, psif: ',time_string(dat.time),'  index=',ind
	dat.data = data > 0.

endif else begin

	dat.data = dat.data - bkg
 	dat.data = dat.data>0.
endelse

; add bkg to data structure

	str_element,dat,'bkg',bkg,/add_replace

return,dat
end

