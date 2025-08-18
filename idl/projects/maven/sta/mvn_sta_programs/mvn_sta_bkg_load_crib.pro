pro mvn_sta_bkg_load_crib

; this is round 1 crib
; these need to be compiled
; or rename them and put them in the working directory
;	.r vb_pot3_4d			; version of vb_pot_4d;
;	.r mvn_sta_scpot_load_8		; version of mvn_sta_scpot_load
;	.r mvn_sta_dead_load1a		; version mvn_sta_dead_load

;; Select Test Time
	timespan,'2016-04-01',1			

	mvn_sta_l2_load, sta_apid = ['2a c0 c6 c8 ca d0 d1 d6 d7 d8 d9 da db']

; these might need to be run
	loadct2,43
	cols=get_colors()

	common mvn_sta_dead,dat_dead	
	mvn_sta_dead_load,/make_common,/test

	mvn_sta_bkg_load		

	mvn_sta_scpot_load

; save the cdfs to a new directory
; only c0 c6 c8 ca d0 d1 are modified

; save dat_dead in the common block to a file
	
end

; make a retrieve program that gets that file and loads it into the common block mvn_sta_dead
; this retrieve program will be used by round 2
