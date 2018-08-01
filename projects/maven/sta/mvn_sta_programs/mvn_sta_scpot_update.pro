;+
;PROCEDURE:       mvn_sta_scpot_update
;
;PURPOSE:         Overwrites STATIC spacecraft potentials with the
;                 composite potential from mvn_scpot.  Most of this
;                 code is taken from mvn_sta_scpot_load.
;
;                 This procedure generally does not affect STATIC-
;                 derived potentials in the EUV shadow, since STATIC
;                 is the primary source of potentials in this region.
;                 It does provide better estimates in other regions,
;                 replacing the STATIC-default 0 V with real estimates
;                 in many cases.
;
;INPUTS:
;      none:      All information obtained from and written to common
;                 blocks.
;
;KEYWORDS:
;
;CREATED BY:      D. L. Mitchell.
;
;LAST MODIFICATION:
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2018-07-31 10:54:21 -0700 (Tue, 31 Jul 2018) $
; $LastChangedRevision: 25527 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/mvn_sta_programs/mvn_sta_scpot_update.pro $
;
;-
pro mvn_sta_scpot_update

; STATIC science data product common blocks (where the potential is stored)
 
  common mvn_c0, mvn_c0_ind, mvn_c0_dat
  common mvn_c6, mvn_c6_ind, mvn_c6_dat
; common mvn_c2, mvn_c2_ind, mvn_c2_dat 
; common mvn_c4, mvn_c4_ind, mvn_c4_dat 
  common mvn_c8, mvn_c8_ind, mvn_c8_dat 
  common mvn_cc, mvn_cc_ind, mvn_cc_dat 
  common mvn_cd, mvn_cd_ind, mvn_cd_dat 
  common mvn_ce, mvn_ce_ind, mvn_ce_dat 
  common mvn_cf, mvn_cf_ind, mvn_cf_dat 
  common mvn_d0, mvn_d0_ind, mvn_d0_dat 
  common mvn_d1, mvn_d1_ind, mvn_d1_dat 
  common mvn_d2, mvn_d2_ind, mvn_d2_dat 
  common mvn_d3, mvn_d3_ind, mvn_d3_dat 
  common mvn_d4, mvn_d4_ind, mvn_d4_dat 

; First get the composite potential

  if (size(mvn_c6_dat,/type) ne 8) then begin
    print,'MVN_STA_SCPOT_UPDATE: no STATIC data loaded.'
    return
  endif

  time = (mvn_c6_dat.time + mvn_c6_dat.end_time)/2D
  pot_all = mvn_get_scpot(time)
  pot_valid = where(finite(pot_all), ngud, ncomplement=nbad)

  fbad = float(nbad)/float(n_elements(mvn_c6_dat.time))
  if (fbad gt 0.25) then begin
    pct = strtrim(string(round(100.*fbad)),2)
    print,'MVN_STA_SCPOT_UPDATE: Warning! ',pct,'% of potentials are invalid.'
  endif

; The following code is almost verbatim from mvn_sta_scpot_load:

  mvn_c6_dat.sc_pot = pot_all
  mvn_c6_dat.quality_flag = (mvn_c6_dat.quality_flag and 30719) or fix(round(2^11*(1-pot_valid)))

  msg = 'c6'

  if size(mvn_c0_dat,/type) eq 8 then begin
    pot_c0 = interp(pot_all,time,(mvn_c0_dat.time+mvn_c0_dat.end_time)/2.) & mvn_c0_dat.sc_pot = pot_c0
    pot_valid_c0 = fix(round(interp(pot_valid,time,(mvn_c0_dat.time+mvn_c0_dat.end_time)/2.))) & mvn_c0_dat.quality_flag = (mvn_c0_dat.quality_flag and 30719) or 2^11*(1-pot_valid_c0)
    msg += ' c0'
  endif

  if size(mvn_ca_dat,/type) eq 8 then begin
    pot_ca = interp(pot_all,time,(mvn_ca_dat.time+mvn_ca_dat.end_time)/2.) & mvn_ca_dat.sc_pot = pot_ca
    pot_valid_ca = fix(round(interp(pot_valid,time,(mvn_ca_dat.time+mvn_ca_dat.end_time)/2.))) & mvn_ca_dat.quality_flag = (mvn_ca_dat.quality_flag and 30719) or 2^11*(1-pot_valid_ca)
    msg += ' ca'
  endif

  if size(mvn_c8_dat,/type) eq 8 then begin
    pot_c8 = interp(pot_all,time,(mvn_c8_dat.time+mvn_c8_dat.end_time)/2.) & mvn_c8_dat.sc_pot = pot_c8
	pot_valid_c8 = fix(round(interp(pot_valid,time,(mvn_c8_dat.time+mvn_c8_dat.end_time)/2.))) & mvn_c8_dat.quality_flag = (mvn_c8_dat.quality_flag and 30719) or 2^11*(1-pot_valid_c8)
    msg += ' c8'
  endif

  if size(mvn_d4_dat,/type) eq 8 then begin
	pot_d4 = interp(pot_all,time,(mvn_d4_dat.time+mvn_d4_dat.end_time)/2.) & mvn_d4_dat.sc_pot = pot_d4
	pot_valid_d4 = fix(round(interp(pot_valid,time,(mvn_d4_dat.time+mvn_d4_dat.end_time)/2.))) & mvn_d4_dat.quality_flag = (mvn_d4_dat.quality_flag and 30719) or 2^11*(1-pot_valid_d4)
    msg += ' d4'
  endif

  if size(mvn_cc_dat,/type) eq 8 then begin
	pot_cca = interp(pot_all,time,mvn_cc_dat.time+2.)
	pot_ccb = interp(pot_all,time,mvn_cc_dat.end_time-2.)
	pot_ccc = interp(pot_all,time,(mvn_cc_dat.time+mvn_cc_dat.end_time)/2.)
	mvn_cc_dat.sc_pot = (pot_cca+pot_ccb+2.*pot_ccc)/4.
	ind = where(mvn_cc_dat.sc_pot eq 0.,count)
	mvn_cc_dat.quality_flag = mvn_cc_dat.quality_flag and 30719
	mvn_cc_dat.quality_flag[ind] = mvn_cc_dat.quality_flag[ind] or 2^11
    msg += ' cc'
  endif
  if size(mvn_cd_dat,/type) eq 8 then begin
	pot_cda = interp(pot_all,time,mvn_cd_dat.time+2.)
	pot_cdb = interp(pot_all,time,mvn_cd_dat.end_time-2.)
	pot_cdc = interp(pot_all,time,(mvn_cd_dat.time+mvn_cd_dat.end_time)/2.)
	mvn_cd_dat.sc_pot = (pot_cda+pot_cdb+2.*pot_cdc)/4.
	ind = where(mvn_cd_dat.sc_pot eq 0.,count)
	mvn_cd_dat.quality_flag = mvn_cd_dat.quality_flag and 30719
	mvn_cd_dat.quality_flag[ind] = mvn_cd_dat.quality_flag[ind] or 2^11
    msg += ' cd'
  endif
  if size(mvn_ce_dat,/type) eq 8 then begin
	pot_cea = interp(pot_all,time,mvn_ce_dat.time+2.)
	pot_ceb = interp(pot_all,time,mvn_ce_dat.end_time-2.)
	pot_cec = interp(pot_all,time,(mvn_ce_dat.time+mvn_ce_dat.end_time)/2.)
	mvn_ce_dat.sc_pot = (pot_cea+pot_ceb+2.*pot_cec)/4.
	ind = where(mvn_ce_dat.sc_pot eq 0.,count)
	mvn_ce_dat.quality_flag = mvn_ce_dat.quality_flag and 30719
	mvn_ce_dat.quality_flag[ind] = mvn_ce_dat.quality_flag[ind] or 2^11
    msg += ' ce'
  endif
  if size(mvn_cf_dat,/type) eq 8 then begin
	pot_cfa = interp(pot_all,time,mvn_cf_dat.time+2.)
	pot_cfb = interp(pot_all,time,mvn_cf_dat.end_time-2.)
	pot_cfc = interp(pot_all,time,(mvn_cf_dat.time+mvn_cf_dat.end_time)/2.)
	mvn_cf_dat.sc_pot = (pot_cfa+pot_cfb+2.*pot_cfc)/4.
	ind = where(mvn_cf_dat.sc_pot eq 0.,count)
	mvn_cf_dat.quality_flag = mvn_cf_dat.quality_flag and 30719
	mvn_cf_dat.quality_flag[ind] = mvn_cf_dat.quality_flag[ind] or 2^11
    msg += ' cf'
  endif
  if size(mvn_d0_dat,/type) eq 8 then begin
	pot_d0a = interp(pot_all,time,mvn_d0_dat.time+2.)
	pot_d0b = interp(pot_all,time,mvn_d0_dat.end_time-2.)
	pot_d0c = interp(pot_all,time,(mvn_d0_dat.time+mvn_d0_dat.end_time)/2.)
	mvn_d0_dat.sc_pot = (pot_d0a+pot_d0b+2.*pot_d0c)/4.
	ind = where(mvn_d0_dat.sc_pot eq 0.,count)
	mvn_d0_dat.quality_flag = mvn_d0_dat.quality_flag and 30719
	mvn_d0_dat.quality_flag[ind] = mvn_d0_dat.quality_flag[ind] or 2^11
    msg += ' d0'
  endif
  if size(mvn_d1_dat,/type) eq 8 then begin
	pot_d1a = interp(pot_all,time,mvn_d1_dat.time+2.)
	pot_d1b = interp(pot_all,time,mvn_d1_dat.end_time-2.)
	pot_d1c = interp(pot_all,time,(mvn_d1_dat.time+mvn_d1_dat.end_time)/2.)
	mvn_d1_dat.sc_pot = (pot_d1a+pot_d1b+2.*pot_d1c)/4.
	ind = where(mvn_d1_dat.sc_pot eq 0.,count)
	mvn_d1_dat.quality_flag = mvn_d1_dat.quality_flag and 30719
	mvn_d1_dat.quality_flag[ind] = mvn_d1_dat.quality_flag[ind] or 2^11
    msg += ' d1'
  endif
  if size(mvn_d2_dat,/type) eq 8 then begin
	pot_d2a = interp(pot_all,time,mvn_d2_dat.time+2.)
	pot_d2b = interp(pot_all,time,mvn_d2_dat.end_time-2.)
	pot_d2c = interp(pot_all,time,(mvn_d2_dat.time+mvn_d2_dat.end_time)/2.)
	mvn_d2_dat.sc_pot = (pot_d2a+pot_d2b+2.*pot_d2c)/4.
	ind = where(mvn_d2_dat.sc_pot eq 0.,count)
	mvn_d2_dat.quality_flag = mvn_d2_dat.quality_flag and 30719
	mvn_d2_dat.quality_flag[ind] = mvn_d2_dat.quality_flag[ind] or 2^11
    msg += ' d2'
  endif
  if size(mvn_d3_dat,/type) eq 8 then begin
	pot_d3a = interp(pot_all,time,mvn_d3_dat.time+2.)
	pot_d3b = interp(pot_all,time,mvn_d3_dat.end_time-2.)
	pot_d3c = interp(pot_all,time,(mvn_d3_dat.time+mvn_d3_dat.end_time)/2.)
	mvn_d3_dat.sc_pot = (pot_d3a+pot_d3b+2.*pot_d3c)/4.
	ind = where(mvn_d3_dat.sc_pot eq 0.,count)
	mvn_d3_dat.quality_flag = mvn_d3_dat.quality_flag and 30719
	mvn_d3_dat.quality_flag[ind] = mvn_d3_dat.quality_flag[ind] or 2^11
    msg += ' d3'
  endif

  print,' sc_pot updated in STATIC structures: ' + msg

  return

end
