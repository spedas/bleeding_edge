;+
;NAME:
;mvn_sta_l2_tclip_all
;PURPOSE:
;Clips all of the possible MAVEN STA data, saved in common blocks
;CALLING SEQUENCE:
;mvn_sta_tclip_all, time_range
;INPUT:
;time_range = the time range for clipping
;OUTPUT:
;No explicit output, data saved in common blocks is clipped
;HISTORY:
;9-sep-2025, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-
Pro mvn_sta_l2_tclip_all, time_range
  trange = time_double(time_range)
  If(n_elements(trange) Ne 2) Then Begin
     dprint, 'Bad time range input'
     Return
  Endif
  common mvn_2a, mvn_2a_ind, mvn_2a_dat
  common mvn_c0, mvn_c0_ind, mvn_c0_dat
  common mvn_c2, mvn_c2_ind, mvn_c2_dat
  common mvn_c4, mvn_c4_ind, mvn_c4_dat
  common mvn_c6, mvn_c6_ind, mvn_c6_dat
  common mvn_c8, mvn_c8_ind, mvn_c8_dat
  common mvn_ca, mvn_ca_ind, mvn_ca_dat
  common mvn_cc, mvn_cc_ind, mvn_cc_dat
  common mvn_cd, mvn_cd_ind, mvn_cd_dat
  common mvn_ce, mvn_ce_ind, mvn_ce_dat
  common mvn_cf, mvn_cf_ind, mvn_cf_dat
  common mvn_d0, mvn_d0_ind, mvn_d0_dat
  common mvn_d1, mvn_d1_ind, mvn_d1_dat
  common mvn_d2, mvn_d2_ind, mvn_d2_dat
  common mvn_d3, mvn_d3_ind, mvn_d3_dat
  common mvn_d4, mvn_d4_ind, mvn_d4_dat
  common mvn_d6, mvn_d6_ind, mvn_d6_dat
  common mvn_d7, mvn_d7_ind, mvn_d7_dat
  common mvn_d8, mvn_d8_ind, mvn_d8_dat
  common mvn_d9, mvn_d9_ind, mvn_d9_dat
  common mvn_da, mvn_da_ind, mvn_da_dat
  common mvn_db, mvn_db_ind, mvn_db_dat

  If(is_struct(mvn_2a_dat)) Then mvn_2a_dat = mvn_sta_cmn_tclip(mvn_2a_dat, trange)
  If(is_struct(mvn_c0_dat)) Then mvn_c0_dat = mvn_sta_cmn_tclip(mvn_c0_dat, trange)
  If(is_struct(mvn_c2_dat)) Then mvn_c2_dat = mvn_sta_cmn_tclip(mvn_c2_dat, trange)
  If(is_struct(mvn_c4_dat)) Then mvn_c4_dat = mvn_sta_cmn_tclip(mvn_c4_dat, trange)
  If(is_struct(mvn_c6_dat)) Then mvn_c6_dat = mvn_sta_cmn_tclip(mvn_c6_dat, trange)
  If(is_struct(mvn_c8_dat)) Then mvn_c8_dat = mvn_sta_cmn_tclip(mvn_c8_dat, trange)
  If(is_struct(mvn_ca_dat)) Then mvn_ca_dat = mvn_sta_cmn_tclip(mvn_ca_dat, trange)
  If(is_struct(mvn_cc_dat)) Then mvn_cc_dat = mvn_sta_cmn_tclip(mvn_cc_dat, trange)
  If(is_struct(mvn_cd_dat)) Then mvn_cd_dat = mvn_sta_cmn_tclip(mvn_cd_dat, trange)
  If(is_struct(mvn_ce_dat)) Then mvn_ce_dat = mvn_sta_cmn_tclip(mvn_ce_dat, trange)
  If(is_struct(mvn_cf_dat)) Then mvn_cf_dat = mvn_sta_cmn_tclip(mvn_cf_dat, trange)
  If(is_struct(mvn_d0_dat)) Then mvn_d0_dat = mvn_sta_cmn_tclip(mvn_d0_dat, trange)
  If(is_struct(mvn_d1_dat)) Then mvn_d1_dat = mvn_sta_cmn_tclip(mvn_d1_dat, trange)
  If(is_struct(mvn_d2_dat)) Then mvn_d2_dat = mvn_sta_cmn_tclip(mvn_d2_dat, trange)
  If(is_struct(mvn_d3_dat)) Then mvn_d3_dat = mvn_sta_cmn_tclip(mvn_d3_dat, trange)
  If(is_struct(mvn_d4_dat)) Then mvn_d4_dat = mvn_sta_cmn_tclip(mvn_d4_dat, trange)
  If(is_struct(mvn_d6_dat)) Then mvn_d6_dat = mvn_sta_cmn_tclip(mvn_d6_dat, trange)
  If(is_struct(mvn_d7_dat)) Then mvn_d7_dat = mvn_sta_cmn_tclip(mvn_d7_dat, trange)
  If(is_struct(mvn_d8_dat)) Then mvn_d8_dat = mvn_sta_cmn_tclip(mvn_d8_dat, trange)
  If(is_struct(mvn_d9_dat)) Then mvn_d9_dat = mvn_sta_cmn_tclip(mvn_d9_dat, trange)
  If(is_struct(mvn_da_dat)) Then mvn_da_dat = mvn_sta_cmn_tclip(mvn_da_dat, trange)
  If(is_struct(mvn_db_dat)) Then mvn_db_dat = mvn_sta_cmn_tclip(mvn_db_dat, trange)

End

