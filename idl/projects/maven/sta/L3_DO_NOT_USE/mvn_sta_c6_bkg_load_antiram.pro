;+
;PROCEDURE:	mvn_sta_c6_bkg_load_antiram
;PURPOSE:	
;	Loads backscattered ions into mvn_c6_dat.bkg for attenuator=2,3 and alt<500, leaves ions in anodes 5-9.
;INPUT:		
;
;KEYWORDS:
;	all_ions	0/1	if set, then all masses added to background, default is only ions in mass bins >23 (>6 amu)
;
;
;CREATED BY:	J. McFadden
;VERSION:	1
;LAST MODIFICATION:  20/03/16
;MOD HISTORY:
;
;NOTES:	  
;	Assume counts in anodes 0-4, 10-15, are backscattered if att=2-3, energy<10eV 
;-

pro mvn_sta_c6_bkg_load_antiram,all_ions=all_ions

	common mvn_c6,mvn_c6_ind,mvn_c6_dat 
	common mvn_d0,mvn_d0_ind,mvn_d0_dat 
	common mvn_d1,mvn_d1_ind,mvn_d1_dat 

; assume c6 data is loaded - otherwise print error

	if size(mvn_c6_dat,/type) ne 8 then begin
		print,'Error - c6 data not loaded'
		return
	endif

; assume d0,d1 might be loaded - if not load these data

	if size(mvn_d0_dat,/type) ne 8 and size(mvn_d1_dat,/type) ne 8 then begin
		mvn_sta_l2_load, sta_apid = ['d0 d1']
	endif else if size(mvn_d0_dat,/type) ne 8 then begin
		mvn_sta_l2_load, sta_apid = ['d0']
	endif else if size(mvn_d1_dat,/type) ne 8 then begin
		mvn_sta_l2_load, sta_apid = ['d1']
	endif

; if d0 and d1 data are not available - then print an error

	if size(mvn_d0_dat,/type) ne 8 and size(mvn_d1_dat,/type) ne 8 then begin
		print,'Error - no d0 and d1 data this day'
		return
	endif

; assume mvn_sta_dead_load.pro has been run with keyword_set make_common - not needed

;	tmp_dat = {time:time,dead:dead,droop:droop,rate:rate,valid:valid,anode:anode}
;	tmp_droop_test = {time:time,droop_1:droop_1,droop_2:droop_2,droop_3:droop_3}

;	common mvn_sta_dead,dat_dead	
;	common mvn_sta_droop_test,dat_droop_test

;	if size(dat_dead,/type) ne 8 then begin
;		print,'Error - must run mvn_sta_dead_load.pro with keyword make_common set'
;		return
;	endif


npts = n_elements(mvn_c6_dat.time)

; use d1 data if it exists 
	
if size(mvn_d0_dat,/type) eq 8 and size(mvn_d1_dat,/type) eq 8 then begin

	tc_d1 = (mvn_d1_dat.time + mvn_d1_dat.end_time)/2.
	tc_d0 = (mvn_d0_dat.time + mvn_d0_dat.end_time)/2.

	for i=0,npts-1 do begin
	    alt = total(mvn_c6_dat.pos_sc_mso[i]^2)^.5-3390.
	    if mvn_c6_dat.att_ind[i] ge 2 and alt lt 500. then begin
		
		tc = (mvn_c6_dat.time[i] + mvn_c6_dat.end_time[i])/2.
		min_d1 = min(abs(tc-tc_d1),ind_d1)
		min_d0 = min(abs(tc-tc_d0),ind_d0)

		if tc gt mvn_d1_dat.time[ind_d1] and tc lt mvn_d1_dat.end_time[ind_d1] then begin
			d0 = total(reform(mvn_d1_dat.data[ind_d1,*,*,*],32,4,16,8),2)
		endif else begin
			d0 = total(reform(mvn_d0_dat.data[ind_d0,*,*,*],32,4,16,8),2)
		endelse 
			ram_ratio = reform(total(d0[*,5:9,*],2)/(total(d0,2)+.00000001),32*8)#replicate(1.,8)
			ram_ratio = reform(transpose(reform(ram_ratio,32,8,8),[0,2,1]),32,64)
			bkg = reform((1.-ram_ratio)*reform(mvn_c6_dat.data[i,*,*]),32,64)
			if not keyword_set(all_ions) then bkg[*,0:23]=0.		; default should only remove antiram heavies
			mvn_c6_dat.bkg[i,*,*] = mvn_c6_dat.bkg[i,*,*] + bkg
	    endif
	endfor
endif

end