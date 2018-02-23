;+
; PROCEDURE iug_init
; 
; :DESCRIPTION:
;    Initialize the environment for loading IUGONET data 
;
; :NOTE:
;    This procedure is called automatically on executing most of 
;    iugonet_*.pro.   
; 
; :Examples:
; 
; iug_init
; 
; if !iugonet.data_policy.ear then iug_load_ear, ..... 
; 
; if ~(iugonet.data_policy.sdfit) then begin
;   print, 'Data is not loaded unless you acknowledge the data policy!'
;   return
; endif 
; 
; :AUTHOR: 
;   Tomo Hori (E-mail: horit@stelab.nagoya-u.ac.jp)
; :HISTORY: 
;   2011/12/21: Created
; 
;-
pro iug_init, reset=reset

defsysv,'!iugonet',exists=exists
if (not keyword_set(exists)) or (keyword_set(reset)) then begin

  defsysv,'!iugonet', $
    { $
      init: 0 $
      ,data_policy: { $
                  ask_nipr_syo:          0b, $
                  ask_nipr_ice:          0b, $ ;HUS, TJO
                  ask_nipr_nor:          0b, $ ;TRO, LYR
                  ask_nipr_spa:          0b, $ ;SPA
                  aws_rish_id:           0b, $ ;BIK,MND,PON
                  aws_rish_ktb:          0b, $ ;KTB
                  aws_rish_sgk:          0b, $ ;SGK
                  blr_rish_ktb:          0b, $
                  blr_rish_sgk:          0b, $
                  blr_rish_srp:          0b, $
                  eiscat:                0b, $
                  ear:                   0b, $
                  gmag_wdc_dst:          0b, $
                  gmag_wdc_ae_asy:       0b, $
                  gmag_wdc_wp:           0b, $
                  gmag_wdc:              0b, $
                  gmag_mm210_adl:        0b, $
                  gmag_mm210_bik:        0b, $
                  gmag_mm210_bsv:        0b, $
                  gmag_mm210_can:        0b, $
                  gmag_mm210_cbi:        0b, $
                  gmag_mm210_chd:        0b, $
                  gmag_mm210_dal:        0b, $
                  gmag_mm210_daw:        0b, $
                  gmag_mm210_ewa:        0b, $
                  gmag_mm210_gua:        0b, $
                  gmag_mm210_kag:        0b, $
                  gmag_mm210_kat:        0b, $
                  gmag_mm210_kot:        0b, $
                  gmag_mm210_ktb:        0b, $
                  gmag_mm210_ktn:        0b, $
                  gmag_mm210_lmt:        0b, $
                  gmag_mm210_lnp:        0b, $
                  gmag_mm210_mcq:        0b, $
                  gmag_mm210_mgd:        0b, $
                  gmag_mm210_msr:        0b, $
                  gmag_mm210_mut:        0b, $
                  gmag_mm210_onw:        0b, $
                  gmag_mm210_ppi:        0b, $
                  gmag_mm210_ptk:        0b, $
                  gmag_mm210_ptn:        0b, $
                  gmag_mm210_rik:        0b, $
                  gmag_mm210_tik:        0b, $
                  gmag_mm210_wep:        0b, $
                  gmag_mm210_wew:        0b, $
                  gmag_mm210_wtk:        0b, $
                  gmag_mm210_yap:        0b, $
                  gmag_mm210_ymk:        0b, $
                  gmag_mm210_zyk:        0b, $
                  gmag_isee_msr:         0b, $
                  gmag_isee_rik:         0b, $
                  gmag_isee_kag:         0b, $
                  gmag_isee_ktb:         0b, $
                  gmag_isee_mdm:         0b, $
                  gmag_isee_tew:         0b, $
                  gmag_nipr_syo:         0b, $ ;Syowa
                  gmag_nipr_ice:         0b, $ ;Iceland
                  gmag_magdas_ama:       0b, $
                  gmag_magdas_asb:       0b, $
                  gmag_magdas_daw:       0b, $
                  gmag_magdas_her:       0b, $
                  gmag_magdas_hln:       0b, $
                  gmag_magdas_hob:       0b, $
                  gmag_magdas_kuj:       0b, $
                  gmag_magdas_laq:       0b, $
                  gmag_magdas_mcq:       0b, $
                  gmag_magdas_mgd:       0b, $
                  gmag_magdas_mlb:       0b, $
                  gmag_magdas_mut:       0b, $
                  gmag_magdas_onw:       0b, $
                  gmag_magdas_ptk:       0b, $
                  gmag_magdas_wad:       0b, $
                  gmag_magdas_yap:       0b, $
                  gmag_icswse_aab:       0b, $
                  gmag_icswse_abj:       0b, $
                  gmag_icswse_abu:       0b, $
                  gmag_icswse_ama:       0b, $
                  gmag_icswse_anc:       0b, $
                  gmag_icswse_asb:       0b, $
                  gmag_icswse_asw:       0b, $
                  gmag_icswse_bcl:       0b, $
                  gmag_icswse_bik:       0b, $
                  gmag_icswse_bkl:       0b, $
                  gmag_icswse_can:       0b, $
                  gmag_icswse_cdo:       0b, $
                  gmag_icswse_ceb:       0b, $
                  gmag_icswse_cgr:       0b, $
                  gmag_icswse_chd:       0b, $
                  gmag_icswse_ckt:       0b, $
                  gmag_icswse_cmd:       0b, $
                  gmag_icswse_dav:       0b, $
                  gmag_icswse_daw:       0b, $
                  gmag_icswse_des:       0b, $
                  gmag_icswse_drb:       0b, $
                  gmag_icswse_dvs:       0b, $
                  gmag_icswse_eus:       0b, $
                  gmag_icswse_ewa:       0b, $
                  gmag_icswse_fym:       0b, $
                  gmag_icswse_gsi:       0b, $
                  gmag_icswse_her:       0b, $
                  gmag_icswse_hln:       0b, $
                  gmag_icswse_hob:       0b, $
                  gmag_icswse_hvd:       0b, $
                  gmag_icswse_ica:       0b, $
                  gmag_icswse_ilr:       0b, $
                  gmag_icswse_jrs:       0b, $
                  gmag_icswse_jyp:       0b, $
                  gmag_icswse_kpg:       0b, $
                  gmag_icswse_krt:       0b, $
                  gmag_icswse_ktn:       0b, $
                  gmag_icswse_kuj:       0b, $
                  gmag_icswse_lag:       0b, $
                  gmag_icswse_laq:       0b, $
                  gmag_icswse_lgz:       0b, $
                  gmag_icswse_lkw:       0b, $
                  gmag_icswse_lsk:       0b, $
                  gmag_icswse_lwa:       0b, $
                  gmag_icswse_mcq:       0b, $
                  gmag_icswse_mgd:       0b, $
                  gmag_icswse_mlb:       0b, $
                  gmag_icswse_mnd:       0b, $
                  gmag_icswse_mut:       0b, $
                  gmag_icswse_nab:       0b, $
                  gmag_icswse_onw:       0b, $
                  gmag_icswse_prp:       0b, $
                  gmag_icswse_ptk:       0b, $
                  gmag_icswse_ptn:       0b, $
                  gmag_icswse_roc:       0b, $
                  gmag_icswse_sbh:       0b, $
                  gmag_icswse_scn:       0b, $
                  gmag_icswse_sma:       0b, $
                  gmag_icswse_tgg:       0b, $
                  gmag_icswse_tik:       0b, $
                  gmag_icswse_tir:       0b, $
                  gmag_icswse_twv:       0b, $
                  gmag_icswse_wad:       0b, $
                  gmag_icswse_yak:       0b, $
                  gmag_icswse_yap:       0b, $
                  gmag_icswse_zgn:       0b, $
                  gps_ro_rish:           0b, $
                  imag_nipr_syo:         0b, $
                  imag_nipr_ice:         0b, $
                  imag_isee:             0b, $
                  hf_tohokuu:            0b, $
                  iprt:                  0b, $
                  irio_nipr_syo:         0b, $
                  irio_nipr_ice:         0b, $
                  ionosonde_rish:        0b, $
                  ltr_rish:              0b, $
                  lfrto:                 0b, $
                  meteor_rish_id:        0b, $ ;BIK,KTB,SRP
                  meteor_rish_sgk:       0b, $ ;SGK
                  mf_rish:               0b, $
                  mu:                    0b, $
                  radiosonde_rish_dawex: 0b, $ ;DRW,GPN,KTR
                  radiosonde_rish_sgk:   0b, $ ;SGK
                  sdfit_hok:             0b, $ ;HOK
                  sdfit_syo:             0b, $ ;SYE,SYS
                  wpr_rish_bik:          0b, $
                  wpr_rish_mnd:          0b, $
                  wpr_rish_pon:          0b, $
                  wpr_rish_sgk:          0b  $
                } $
    }
    
endif

if keyword_set(reset) then !iugonet.init=0

if !iugonet.init ne 0 then return


!iugonet.init = 1

return
end
