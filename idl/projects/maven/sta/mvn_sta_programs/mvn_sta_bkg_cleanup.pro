;+
;PROCEDURE:	mvn_sta_bkg_cleanup
;PURPOSE:	
;	For small number backgrounds, consolidates mvn_id_dat.bkg to match with mvn_id_dat.data 
;INPUT:		
;
;KEYWORDS:
;	save_bkg	0/1	if set, will save the current value of bkg in an intermediate array -- for testing
;	restore_bkg	0/1	if set, will restore value of bkg in an intermediate array created by save_bkg -- for testing
;	no_digitize	0/1	if set, mvn_id_dat.bkg is NOT digitized to a value equal to mvn_id_dat.data if they are statistically equivalent
;					no_digitize keyword is only used for testing
;
;CREATED BY:	J. McFadden 20/09/01
;VERSION:	1
;LAST MODIFICATION:  21/05/11		
;MOD HISTORY:
;		21/05/10	; modified so digitize will not act on C+ outside the solar wind so faint C+ signal is not removed 
;		21/05/11	; changed "digitize" keyword to "no_digitize" so that normal operations don't require this keyword to be set
;
;NOTES:	  
; 	This routine should be run after all backgrounds are calculated and added to the mvn_id_dat.bkg arrays
;	For small number background in a 4 sec measurement - calculated background removal fails unless averaged over long periods
;	This routine consolidates the calculated fractional count background into nearby time and mass bins where actual counts are measured
;	The net effect doesn't change the overall time averaged background
;	The routine will further set mvn_id_dat.bkg=mvn_id_dat.data if mvn_id_dat.bkg is within 2 sigma of mvn_id_dat.data
;		this feature of setting mvn_id_dat.bkg=mvn_id_dat.data for statistically equivalent values is refered to as "digitize"
;	This results in small changes in background that are statistically insignificant on long time scales and accurate background removal on 4 sec time scales
;	This digitize feature can be turned off with the "no_digitize" keyword - primarily for testing
;-

pro mvn_sta_bkg_cleanup,save_bkg=save_bkg,restore_bkg=restore_bkg,no_digitize=no_digitize,a_value=a_value,$
	no_c0=no_c0,no_c8=no_c8,no_ca=no_ca,no_d0=no_d0,no_d1=no_d1, no_mass=no_mass

starttime = systime(1)

common mvn_c0,mvn_c0_ind,mvn_c0_dat 
common mvn_c6,mvn_c6_ind,mvn_c6_dat 
common mvn_c8,mvn_c8_ind,mvn_c8_dat 
common mvn_ca,mvn_ca_ind,mvn_ca_dat 
common mvn_d0,mvn_d0_ind,mvn_d0_dat 
common mvn_d1,mvn_d1_ind,mvn_d1_dat 

common mvn_d8,mvn_d8_ind,mvn_d8_dat 
common mvn_d9,mvn_d9_ind,mvn_d9_dat 
common mvn_da,mvn_da_ind,mvn_da_dat 
common mvn_db,mvn_db_ind,mvn_db_dat 

; check if required c6 data is loaded

if size(mvn_c6_dat,/type) ne 8 then begin
	print,'Error - c6 data not loaded'
	return
endif

if max(total(mvn_c6_dat.bkg[*,*,56:63],3)) lt 1. then begin
	print,'Error - it appears that coincident background is not loaded, run mvn_sta_bkg_load.pro'
	return
endif

if not keyword_set(a_value) then a_value=0.03			; this determines insignificant bkg and sets them to zero

; the following is used to turn off digitize for C+ outside the solar wind (solar wind defined as cnt_h>10*cnt_o) 
;	high O+/O2+ bkg can mask a weak C+ signal, so turn off digitize in that mass range for c6,d0,d1
;	C+ bkg removal still requires 
if not keyword_set(no_mass) then no_mass=[9.9,13.7]		; this range of mass turns off digitize since it results in increased bkg at C+ for c6
no_mass2=no_mass*0.8						; this corrects the no_mass range needed for d0 and d1

; these are for testing

if keyword_set(save_bkg) then begin
	common bkg_c0_cleanup,bkg_c0_arr_old
	common bkg_c6_cleanup,bkg_c6_arr_old
	common bkg_c8_cleanup,bkg_c8_arr_old
	common bkg_ca_cleanup,bkg_ca_arr_old
	common bkg_d0_cleanup,bkg_d0_arr_old
	common bkg_d1_cleanup,bkg_d1_arr_old
	if size(mvn_c0_dat,/type) eq 8 then bkg_c0_arr_old=mvn_c0_dat.bkg
	if size(mvn_c6_dat,/type) eq 8 then bkg_c6_arr_old=mvn_c6_dat.bkg
	if size(mvn_c8_dat,/type) eq 8 then bkg_c8_arr_old=mvn_c8_dat.bkg
	if size(mvn_ca_dat,/type) eq 8 then bkg_ca_arr_old=mvn_ca_dat.bkg
	if size(mvn_d0_dat,/type) eq 8 then bkg_d0_arr_old=mvn_d0_dat.bkg
	if size(mvn_d1_dat,/type) eq 8 then bkg_d1_arr_old=mvn_d1_dat.bkg
endif

if keyword_set(restore_bkg) then begin
	common bkg_c0_cleanup,bkg_c0_arr_old
	common bkg_c6_cleanup,bkg_c6_arr_old
	common bkg_c8_cleanup,bkg_c8_arr_old
	common bkg_ca_cleanup,bkg_ca_arr_old
	common bkg_d0_cleanup,bkg_d0_arr_old
	common bkg_d1_cleanup,bkg_d1_arr_old
	if size(mvn_c6_dat,/type) eq 8 and size(bkg_c6_arr_old,/type) eq 4 then mvn_c6_dat.bkg=bkg_c6_arr_old
	if size(mvn_c0_dat,/type) eq 8 and size(bkg_c0_arr_old,/type) eq 4 then mvn_c0_dat.bkg=bkg_c0_arr_old
	if size(mvn_c8_dat,/type) eq 8 and size(bkg_c8_arr_old,/type) eq 4 then mvn_c8_dat.bkg=bkg_c8_arr_old
	if size(mvn_ca_dat,/type) eq 8 and size(bkg_ca_arr_old,/type) eq 4 then mvn_ca_dat.bkg=bkg_ca_arr_old
	if size(mvn_d0_dat,/type) eq 8 and size(bkg_d0_arr_old,/type) eq 4 then mvn_d0_dat.bkg=bkg_d0_arr_old
	if size(mvn_d1_dat,/type) eq 8 and size(bkg_d1_arr_old,/type) eq 4 then mvn_d1_dat.bkg=bkg_d1_arr_old
	print,'Background restored'
	return
endif

cols=get_colors()

;****************************************************************************
; use apid c6 for the time base

print,'Cleanup being run on c6'
for ii=0,31 do begin

 print,ii
	npts = n_elements(mvn_c6_dat.time)
	att = mvn_c6_dat.att_ind
	mode = mvn_c6_dat.mode
	ind_p = where(mode ne shift(mode, 1) or att ne shift(att, 1))
	ind_m = where(mode ne shift(mode,-1) or att ne shift(att,-1))

	bkg = reform(mvn_c6_dat.bkg[*,ii,*])
	cnt = reform(mvn_c6_dat.data[*,ii,*])
	bkg0 = bkg

	for jj=0,100 do begin	

		
		bkg_tp = shift(bkg, 1, 0) & bkg_tp[ind_p,*]=bkg[ind_p,*] & bkg_tp[0,*]=bkg[0,*]
		bkg_tm = shift(bkg,-1, 0) & bkg_tm[ind_m,*]=bkg[ind_m,*] & bkg_tm[npts-1,*]=bkg[npts-1,*]
		bkg_mp = shift(bkg, 0, 1) & bkg_mp[*, 0]=bkg[*, 0]
		bkg_mm = shift(bkg, 0,-1) & bkg_mm[*,63]=bkg[*,63]

		cnt_tp = shift(cnt, 1, 0) & cnt_tp[ind_p,*]=cnt[ind_p,*] & cnt_tp[0,*]=cnt[0,*]
		cnt_tm = shift(cnt,-1, 0) & cnt_tm[ind_m,*]=cnt[ind_m,*] & cnt_tm[npts-1,*]=cnt[npts-1,*]
		cnt_mp = shift(cnt, 0, 1) & cnt_mp[*, 0]=cnt[*, 0]
		cnt_mm = shift(cnt, 0,-1) & cnt_mm[*,63]=cnt[*,63]

		tmp = bkg - ((bkg-cnt)>0) + .25*((bkg_tp-cnt_tp)>0) + .25*((bkg_tm-cnt_tm)>0) + .25*((bkg_mp-cnt_mp)>0) + .25*((bkg_mm-cnt_mm)>0)

;		if jj eq 10 eq 0 then print,'     ',minmax(abs(bkg-tmp)),minmax(abs(bkg0-tmp))
;		if jj eq 100 eq 0 then print,'     ',minmax(abs(bkg-tmp)),minmax(abs(bkg0-tmp))
		bkg = tmp

	endfor
	mvn_c6_dat.bkg[*,ii,*] = bkg
endfor

	; digitize the data
	if not keyword_set(no_digitize) then begin
		bkg_c6 = mvn_c6_dat.bkg
		bkg2 = bkg_c6 + 2.*bkg_c6^.5			; not sure which one is better
;		bkg2 = bkg_c6 + 2.*(bkg_c6^.5 < bkg_c6)		; not sure which one is better
		cnt_c6 = mvn_c6_dat.data
		cnt_h = total(cnt_c6[*,*,0:15],3)
		cnt_o = total(cnt_c6[*,*,32:47],3)
		mass_arr = mvn_c6_dat.mass_arr[mvn_c6_dat.swp_ind,*,*]

		ignore = (mass_arr gt no_mass[0]) and (mass_arr lt no_mass[1])
		ignore1 = reform(reform((cnt_h lt 10.*cnt_o),32l*npts)#replicate(1.,64),npts,32,64)
		ignore2 = (ignore and ignore1) or (cnt_c6 gt bkg2)
		ignore[*] = 1
		bkg_tmp = (ignore - ignore2)*cnt_c6 + ignore2*bkg_c6 
;		bkg_tmp = (cnt_c6 le bkg2)*cnt_c6 + (cnt_c6 gt bkg2)*bkg_c6 
		if keyword_set(a_value) then begin
			ind = where(bkg_tmp lt a_value*cnt_c6^.5)
			bkg_tmp(ind)=0.
		endif
		mvn_c6_dat.bkg = bkg_tmp
	endif

;****************************************************************************
; cleanup c0 background

if size(mvn_c0_dat,/type) eq 8 and (not keyword_set(no_c0)) then begin

print,'Cleanup being run on c0'
for ii=0,63 do begin

 print,ii
	npts = n_elements(mvn_c0_dat.time)
	att = mvn_c0_dat.att_ind
	mode = mvn_c0_dat.mode
	ind_p = where(mode ne shift(mode, 1) or att ne shift(att, 1))
	ind_m = where(mode ne shift(mode,-1) or att ne shift(att,-1))

	bkg = reform(mvn_c0_dat.bkg[*,ii,*])
	cnt = reform(mvn_c0_dat.data[*,ii,*])
	bkg0 = bkg

	for jj=0,100 do begin	

		bkg_tp = shift(bkg, 1, 0) & bkg_tp[ind_p,*]=bkg[ind_p,*] & bkg_tp[0,*]=bkg[0,*]
		bkg_tm = shift(bkg,-1, 0) & bkg_tm[ind_m,*]=bkg[ind_m,*] & bkg_tm[npts-1,*]=bkg[npts-1,*]

		cnt_tp = shift(cnt, 1, 0) & cnt_tp[ind_p,*]=cnt[ind_p,*] & cnt_tp[0,*]=cnt[0,*]
		cnt_tm = shift(cnt,-1, 0) & cnt_tm[ind_m,*]=cnt[ind_m,*] & cnt_tm[npts-1,*]=cnt[npts-1,*]

		tmp = bkg - ((bkg-cnt)>0) + .5*((bkg_tp-cnt_tp)>0) + .5*((bkg_tm-cnt_tm)>0)

;		if jj eq 10 eq 0 then print,'     ',minmax(abs(bkg-tmp)),minmax(abs(bkg0-tmp))
;		if jj eq 100 eq 0 then print,'     ',minmax(abs(bkg-tmp)),minmax(abs(bkg0-tmp))
		bkg = tmp

	endfor
	mvn_c0_dat.bkg[*,ii,*] = bkg
endfor

	; digitize the data
	if not keyword_set(no_digitize) then begin
		bkg_c0 = mvn_c0_dat.bkg
		bkg2 = bkg_c0 + 2.*bkg_c0^.5
;		bkg2 = bkg_c0 + 2.*(bkg_c0^.5 < bkg_c0)
		cnt_c0 = mvn_c0_dat.data
		bkg_tmp = (cnt_c0 le bkg2)*cnt_c0 + (cnt_c0 gt bkg2)*bkg_c0 
		if keyword_set(a_value) then begin
			ind = where(bkg_tmp lt a_value*cnt_c0^.5)
			bkg_tmp(ind)=0.
		endif
		mvn_c0_dat.bkg = bkg_tmp
	endif

endif

;****************************************************************************
; correct c8 background

if size(mvn_c8_dat,/type) eq 8 and (not keyword_set(no_c8)) then begin

print,'Cleanup being run on c8'
for ii=0,31 do begin

 print,ii
	npts = n_elements(mvn_c8_dat.time)
	att = mvn_c8_dat.att_ind
	mode = mvn_c8_dat.mode
	ind_p = where(mode ne shift(mode, 1) or att ne shift(att, 1))
	ind_m = where(mode ne shift(mode,-1) or att ne shift(att,-1))

	bkg = reform(mvn_c8_dat.bkg[*,ii,*])
	cnt = reform(mvn_c8_dat.data[*,ii,*])
	bkg0 = bkg

	for jj=0,100 do begin	

		bkg_tp = shift(bkg, 1, 0) & bkg_tp[ind_p,*]=bkg[ind_p,*] & bkg_tp[0,*]=bkg[0,*]
		bkg_tm = shift(bkg,-1, 0) & bkg_tm[ind_m,*]=bkg[ind_m,*] & bkg_tm[npts-1,*]=bkg[npts-1,*]

		cnt_tp = shift(cnt, 1, 0) & cnt_tp[ind_p,*]=cnt[ind_p,*] & cnt_tp[0,*]=cnt[0,*]
		cnt_tm = shift(cnt,-1, 0) & cnt_tm[ind_m,*]=cnt[ind_m,*] & cnt_tm[npts-1,*]=cnt[npts-1,*]

		tmp = bkg - ((bkg-cnt)>0) + .5*((bkg_tp-cnt_tp)>0) + .5*((bkg_tm-cnt_tm)>0)

;		if jj eq 10 eq 0 then print,'     ',minmax(abs(bkg-tmp)),minmax(abs(bkg0-tmp))
;		if jj eq 100 eq 0 then print,'     ',minmax(abs(bkg-tmp)),minmax(abs(bkg0-tmp))
		bkg = tmp

	endfor
	mvn_c8_dat.bkg[*,ii,*] = bkg
endfor

	; digitize the data
	if not keyword_set(no_digitize) then begin
		bkg_c8 = mvn_c8_dat.bkg
		bkg2 = bkg_c8 + 2.*bkg_c8^.5
;		bkg2 = bkg_c8 + 2.*(bkg_c8^.5 < bkg_c8)
		cnt_c8 = mvn_c8_dat.data
		bkg_tmp = (cnt_c8 le bkg2)*cnt_c8 + (cnt_c8 gt bkg2)*bkg_c8 
		if keyword_set(a_value) then begin
			ind = where(bkg_tmp lt a_value*cnt_c8^.5)
			bkg_tmp(ind)=0.
		endif
		mvn_c8_dat.bkg = bkg_tmp
	endif

endif

;****************************************************************************
; correct ca background

if size(mvn_ca_dat,/type) eq 8 and (not keyword_set(no_ca)) then begin

print,'Cleanup being run on ca'
for ii=0,15 do begin

 print,ii
	npts = n_elements(mvn_ca_dat.time)
	att = mvn_ca_dat.att_ind
	mode = mvn_ca_dat.mode
	ind_p = where(mode ne shift(mode, 1) or att ne shift(att, 1))
	ind_m = where(mode ne shift(mode,-1) or att ne shift(att,-1))

	bkg = reform(mvn_ca_dat.bkg[*,ii,*])
	cnt = reform(mvn_ca_dat.data[*,ii,*])
	bkg0 = bkg

	for jj=0,100 do begin	

		bkg_tp = shift(bkg, 1, 0) & bkg_tp[ind_p,*]=bkg[ind_p,*] & bkg_tp[0,*]=bkg[0,*]
		bkg_tm = shift(bkg,-1, 0) & bkg_tm[ind_m,*]=bkg[ind_m,*] & bkg_tm[npts-1,*]=bkg[npts-1,*]

		cnt_tp = shift(cnt, 1, 0) & cnt_tp[ind_p,*]=cnt[ind_p,*] & cnt_tp[0,*]=cnt[0,*]
		cnt_tm = shift(cnt,-1, 0) & cnt_tm[ind_m,*]=cnt[ind_m,*] & cnt_tm[npts-1,*]=cnt[npts-1,*]

		tmp = bkg - ((bkg-cnt)>0) + .5*((bkg_tp-cnt_tp)>0) + .5*((bkg_tm-cnt_tm)>0)

;		if jj eq 10 eq 0 then print,'     ',minmax(abs(bkg-tmp)),minmax(abs(bkg0-tmp))
;		if jj eq 100 eq 0 then print,'     ',minmax(abs(bkg-tmp)),minmax(abs(bkg0-tmp))
		bkg = tmp

	endfor
	mvn_ca_dat.bkg[*,ii,*] = bkg
endfor

	; digitize the data
	if not keyword_set(no_digitize) then begin
		bkg_ca = mvn_ca_dat.bkg
		bkg2 = bkg_ca + 2.*bkg_ca^.5
;		bkg2 = bkg_ca + 2.*(bkg_ca^.5 < bkg_ca)
		cnt_ca = mvn_ca_dat.data
		bkg_tmp = (cnt_ca le bkg2)*cnt_ca + (cnt_ca gt bkg2)*bkg_ca 
		if keyword_set(a_value) then begin
			ind = where(bkg_tmp lt a_value*cnt_ca^.5)
			bkg_tmp(ind)=0.
		endif
		mvn_ca_dat.bkg = bkg_tmp
	endif

endif

;****************************************************************************
; correct d0 background 

if size(mvn_d0_dat,/type) eq 8 and (not keyword_set(no_d0)) then begin

print,'Cleanup being run on d0'
for ii=0,31 do begin

 print,ii
	npts = n_elements(mvn_d0_dat.time)
	att = mvn_d0_dat.att_ind
	mode = mvn_d0_dat.mode
	ind_p = where(mode ne shift(mode, 1) or att ne shift(att, 1))
	ind_m = where(mode ne shift(mode,-1) or att ne shift(att,-1))

	bkg = reform(mvn_d0_dat.bkg[*,ii,*,*])
	cnt = reform(mvn_d0_dat.data[*,ii,*,*])
	bkg0 = bkg

	for jj=0,25 do begin	

		bkg_tp = shift(bkg, 1, 0, 0) & bkg_tp[ind_p,*,*]=bkg[ind_p,*,*] & bkg_tp[0,*,*]=bkg[0,*,*]
		bkg_tm = shift(bkg,-1, 0, 0) & bkg_tm[ind_m,*,*]=bkg[ind_m,*,*] & bkg_tm[npts-1,*,*]=bkg[npts-1,*,*]

		cnt_tp = shift(cnt, 1, 0, 0) & cnt_tp[ind_p,*,*]=cnt[ind_p,*,*] & cnt_tp[0,*,*]=cnt[0,*,*]
		cnt_tm = shift(cnt,-1, 0, 0) & cnt_tm[ind_m,*,*]=cnt[ind_m,*,*] & cnt_tm[npts-1,*,*]=cnt[npts-1,*,*]

		tmp = bkg - ((bkg-cnt)>0) + .5*((bkg_tp-cnt_tp)>0) + .5*((bkg_tm-cnt_tm)>0)


;		if jj eq 10 eq 0 then print,'     ',minmax(abs(bkg-tmp)),minmax(abs(bkg0-tmp))
;		if jj eq 100 eq 0 then print,'     ',minmax(abs(bkg-tmp)),minmax(abs(bkg0-tmp))
		bkg = tmp

	endfor
	mvn_d0_dat.bkg[*,ii,*,*] = bkg
endfor

	; digitize the data
	if not keyword_set(no_digitize) then begin
		bkg_d0 = mvn_d0_dat.bkg
		bkg2 = bkg_d0 + 2.*bkg_d0^.5
;		bkg2 = bkg_d0 + 2.*(bkg_d0^.5 < bkg_d0)
		cnt_d0 = mvn_d0_dat.data
		cnt_h = total(cnt_d0[*,*,*,0:1],4)
		cnt_o = total(cnt_d0[*,*,*,4:5],4)
		mass_arr = mvn_d0_dat.mass_arr[mvn_d0_dat.swp_ind,*,*,*]

		ignore = (mass_arr gt no_mass2[0]) and (mass_arr lt no_mass2[1])
		ignore1 = reform(reform((cnt_h lt 10.*cnt_o),32l*64*npts)#replicate(1.,8),npts,32,64,8)
		ignore2 = (ignore and ignore1) or (cnt_d0 gt bkg2)
		ignore[*] = 1
		bkg_tmp = (ignore - ignore2)*cnt_d0 + ignore2*bkg_d0 
;		bkg_tmp = (cnt_d0 le bkg2)*cnt_d0 + (cnt_d0 gt bkg2)*bkg_d0 
		if keyword_set(a_value) then begin
			ind = where(bkg_tmp lt a_value*cnt_d0^.5)
			bkg_tmp(ind)=0.
		endif
		mvn_d0_dat.bkg = bkg_tmp
	endif

endif


;****************************************************************************
; correct d1 background

if size(mvn_d1_dat,/type) eq 8 and (not keyword_set(no_d1)) then begin

print,'Cleanup being run on d1'
for ii=0,31 do begin

 print,ii
	npts = n_elements(mvn_d1_dat.time)
	att = mvn_d1_dat.att_ind
	mode = mvn_d1_dat.mode
	ind_p = where(mode ne shift(mode, 1) or att ne shift(att, 1))
	ind_m = where(mode ne shift(mode,-1) or att ne shift(att,-1))

	bkg = reform(mvn_d1_dat.bkg[*,ii,*,*])
	cnt = reform(mvn_d1_dat.data[*,ii,*,*])
	bkg0 = bkg

	for jj=0,100 do begin	

		bkg_tp = shift(bkg, 1, 0, 0) & bkg_tp[ind_p,*,*]=bkg[ind_p,*,*] & bkg_tp[0,*,*]=bkg[0,*,*]
		bkg_tm = shift(bkg,-1, 0, 0) & bkg_tm[ind_m,*,*]=bkg[ind_m,*,*] & bkg_tm[npts-1,*,*]=bkg[npts-1,*,*]

		cnt_tp = shift(cnt, 1, 0, 0) & cnt_tp[ind_p,*,*]=cnt[ind_p,*,*] & cnt_tp[0,*,*]=cnt[0,*,*]
		cnt_tm = shift(cnt,-1, 0, 0) & cnt_tm[ind_m,*,*]=cnt[ind_m,*,*] & cnt_tm[npts-1,*,*]=cnt[npts-1,*,*]

		tmp = bkg - ((bkg-cnt)>0) + .5*((bkg_tp-cnt_tp)>0) + .5*((bkg_tm-cnt_tm)>0)


;		if jj eq 10 eq 0 then print,'     ',minmax(abs(bkg-tmp)),minmax(abs(bkg0-tmp))
;		if jj eq 100 eq 0 then print,'     ',minmax(abs(bkg-tmp)),minmax(abs(bkg0-tmp))
		bkg = tmp

	endfor
	mvn_d1_dat.bkg[*,ii,*,*] = bkg
endfor

	; digitize the data
	if not keyword_set(no_digitize) then begin
		bkg_d1 = mvn_d1_dat.bkg
		bkg2 = bkg_d1 + 2.*bkg_d1^.5
;		bkg2 = bkg_d1 + 2.*(bkg_d1^.5 < bkg_d1)
		cnt_d1 = mvn_d1_dat.data
		cnt_h = total(cnt_d1[*,*,*,0:1],4)
		cnt_o = total(cnt_d1[*,*,*,4:5],4)
		mass_arr = mvn_d1_dat.mass_arr[mvn_d1_dat.swp_ind,*,*,*]

		ignore = (mass_arr gt no_mass2[0]) and (mass_arr lt no_mass2[1])
		ignore1 = reform(reform((cnt_h lt 10.*cnt_o),32l*64*npts)#replicate(1.,8),npts,32,64,8)
		ignore2 = (ignore and ignore1) or (cnt_d1 gt bkg2)
		ignore[*] = 1
		bkg_tmp = (ignore - ignore2)*cnt_d1 + ignore2*bkg_d1 
;		bkg_tmp = (cnt_d1 le bkg2)*cnt_d1 + (cnt_d1 gt bkg2)*bkg_d1 
		if keyword_set(a_value) then begin
			ind = where(bkg_tmp lt a_value*cnt_d1^.5)
			bkg_tmp(ind)=0.
		endif
		mvn_d1_dat.bkg = bkg_tmp
	endif

endif


; print out the run time

	print,'mvn_sta_bkg_cleanup run time = ',systime(1)-starttime

end
