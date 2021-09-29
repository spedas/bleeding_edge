;+
;PROCEDURE:	mvn_sta_l2_gf_update,current_scale=current_scale,gf_scale=gf_scale,gf_old=gf_old
;PURPOSE:	
;	Used to update the geom_factor in data structures based on inflight calibrations, assumes c6 data is loaded for gf_old keyword
;INPUT:		
;
;KEYWORDS:
;	gf_scale	flt		scale factor multiplied by original geom_factor 
;	gf_old  	0/1		if set will transform geom_factor back to the value estimated at launch, 
;
;CREATED BY:	J. McFadden	2019/04/19
;VERSION:	1
;LAST MODIFICATION:  2019/04/19
;MOD HISTORY:
;
;NOTES
;	A minimal gf_scale=1.3 is needed to match LPW fp measurements on 20180531 (-3.0V) with no ion suppression
; 	Default gf_scale=1.5 determined from 20190405 transition from fly-Z (-0.3) to fly-Y (-2.0V) to get kk3 = [3.1,2.8,3.0,2.4]
;		combined with LPW waves calibraton on 20190331
;-
pro mvn_sta_l2_gf_update,gf_scale=gf_scale,gf_old=gf_old,current_scale=current_scale


;declare all the common block arrays

	common mvn_c0,mvn_c0_ind,mvn_c0_dat 
	common mvn_c2,mvn_c2_ind,mvn_c2_dat 
	common mvn_c4,mvn_c4_ind,mvn_c4_dat 
	common mvn_c6,mvn_c6_ind,mvn_c6_dat 
	common mvn_c8,mvn_c8_ind,mvn_c8_dat 
	common mvn_ca,mvn_ca_ind,mvn_ca_dat 
	common mvn_cc,mvn_cc_ind,mvn_cc_dat 
	common mvn_cd,mvn_cd_ind,mvn_cd_dat 
	common mvn_ce,mvn_ce_ind,mvn_ce_dat 
	common mvn_cf,mvn_cf_ind,mvn_cf_dat 
	common mvn_d0,mvn_d0_ind,mvn_d0_dat 
	common mvn_d1,mvn_d1_ind,mvn_d1_dat 

	common mvn_d2,mvn_d2_ind,mvn_d2_dat 
	common mvn_d3,mvn_d3_ind,mvn_d3_dat 
	common mvn_d4,mvn_d4_ind,mvn_d4_dat 
	common mvn_d6,mvn_d6_ind,mvn_d6_dat 
	common mvn_d7,mvn_d7_ind,mvn_d7_dat 
	common mvn_d8,mvn_d8_ind,mvn_d8_dat 
	common mvn_d9,mvn_d9_ind,mvn_d9_dat 
	common mvn_da,mvn_da_ind,mvn_da_dat 
	common mvn_db,mvn_db_ind,mvn_db_dat 

	common mvn_c6_avg,mvn_c6_avg_ind,mvn_c6_dat_avg

gf_c6_original = 0.000195673

if size(mvn_c6_dat,/type) ne 8 then begin
	print,'Error - c6 data must be loaded'
	return
endif

if keyword_set(current_scale) then begin
	print,mvn_c6_dat.geom_factor/gf_c6_original
	return
endif

if keyword_set(gf_old) then gf_scale = gf_c6_original/mvn_c6_dat.geom_factor

if keyword_set(gf_scale) and (not keyword_set(gf_old)) then gf_scale = gf_scale*gf_c6_original/mvn_c6_dat.geom_factor

; default gf_scale=1.13 from 20170901 scenario 1 from sun-V (-0.6) to fly-Y (-2.4V) to get kk3=1.5 values
;	and LPW waves calibraton on 20170901
; note that this is the increase in average GF for a broad angle, high energy beam
; for narrow beams centered on an anode, an additional (1./0.9)^2=1.235 factor is needed since there is no attenuation by ESA exit posts or TOF entrance posts
; this additional factor should be included in the density calculation, i.e. nb_4d.pro or nbc_4d.pro

if (not keyword_set(gf_scale)) and (not keyword_set(gf_old)) then gf_scale = 1.13*gf_c6_original/mvn_c6_dat.geom_factor


	if size(mvn_c0_dat,/type) eq 8 then mvn_c0_dat.geom_factor = gf_scale*mvn_c0_dat.geom_factor
	if size(mvn_c2_dat,/type) eq 8 then mvn_c2_dat.geom_factor = gf_scale*mvn_c2_dat.geom_factor
	if size(mvn_c4_dat,/type) eq 8 then mvn_c4_dat.geom_factor = gf_scale*mvn_c4_dat.geom_factor
	if size(mvn_c6_dat,/type) eq 8 then mvn_c6_dat.geom_factor = gf_scale*mvn_c6_dat.geom_factor
	if size(mvn_c8_dat,/type) eq 8 then mvn_c8_dat.geom_factor = gf_scale*mvn_c8_dat.geom_factor
	if size(mvn_ca_dat,/type) eq 8 then mvn_ca_dat.geom_factor = gf_scale*mvn_ca_dat.geom_factor
	if size(mvn_cc_dat,/type) eq 8 then mvn_cc_dat.geom_factor = gf_scale*mvn_cc_dat.geom_factor
	if size(mvn_cd_dat,/type) eq 8 then mvn_cd_dat.geom_factor = gf_scale*mvn_cd_dat.geom_factor
	if size(mvn_ce_dat,/type) eq 8 then mvn_ce_dat.geom_factor = gf_scale*mvn_ce_dat.geom_factor
	if size(mvn_cf_dat,/type) eq 8 then mvn_cf_dat.geom_factor = gf_scale*mvn_cf_dat.geom_factor

	if size(mvn_d0_dat,/type) eq 8 then mvn_d0_dat.geom_factor = gf_scale*mvn_d0_dat.geom_factor
	if size(mvn_d1_dat,/type) eq 8 then mvn_d1_dat.geom_factor = gf_scale*mvn_d1_dat.geom_factor
	if size(mvn_d2_dat,/type) eq 8 then mvn_d2_dat.geom_factor = gf_scale*mvn_d2_dat.geom_factor
	if size(mvn_d3_dat,/type) eq 8 then mvn_d3_dat.geom_factor = gf_scale*mvn_d3_dat.geom_factor
	if size(mvn_d4_dat,/type) eq 8 then mvn_d4_dat.geom_factor = gf_scale*mvn_d4_dat.geom_factor

	if size(mvn_c6_dat_avg,/type) eq 8 then mvn_c6_dat_avg.geom_factor = mvn_c6_dat.geom_factor

	tt=timerange()
	string_gf_scale = strmid(string(round(gf_scale*100.)/100.),5,5)
	store_data,'mvn_sta_gf_scale',data={x:tt,y:[gf_scale,gf_scale]}
		options,'mvn_sta_gf_scale',ytitle='sta!Cgf!Cscale',yrange=[0,2],labels='c6',labpos=1

	print,mvn_c6_dat.geom_factor/gf_c6_original

end


