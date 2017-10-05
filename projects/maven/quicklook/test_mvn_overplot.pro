;file = '/disks/data/maven/data/sci/pfp/l0/mvn_pfp_svy_l0_20150803_v1.dat'
;set_plot,'z'   ; set_plot now done in thm_over_shell.pro
;device, set_resolution = [750, 800]
;mvn_swia_overplot, l0_input_file = file, /makepng, $
;  directory = '~/public_html/maven/test_overplot/', device = 'z'

;filex = '/disks/data/maven/data/sci/pfp/ATLO/mvn_ATLO_pfp_all_l0_20130508_v1.dat'

;mvn_swia_overplot, l0_input_file = filex, /makepng, /date_only, $
;  directory = '~/public_html/maven/test_overplot/', device = 'z'

;mvn_swe_overplot, l0_input_file = filex, /makepng,  /date_only, $
;  directory = '~/public_html/maven/test_overplot/', device = 'z'

;mvn_lpw_overplot, l0_input_file = filex, /makepng,  /date_only, $
;  directory = '~/public_html/maven/test_overplot/', device = 'z'

;filex = '/disks/data/maven/data/sci/pfp/ATLO/mvn_ATLO_pfp_all_l0_20130520_v1.dat'
;mvn_mag_overplot, l0_input_file = filex, /makepng,  /date_only, $
;  directory = '~/public_html/maven/test_overplot/', device = 'z'

;mvn_sta_overplot, l0_input_file = filex, /makepng,  /date_only, $
;  directory = '~/public_html/maven/test_overplot/', device = 'z'

;filex =
;'/disks/data/maven/data/sci/pfp/ATLO/mvn_ATLO_pfp_all_l0_20130508_v1.dat'

;filex = '/disks/data/maven/data/sci/pfp/l0/mvn_pfp_svy_l0_20150803_v2.dat'

;filex =
;'/disks/data/maven/data/sci/pfp/ATLO/mvn_ATLO_pfp_all_l0_20131109_v1.dat'

;filex = '/disks/data/maven/ITF/CruisePhase_SOCRealtime_LevelZero/20140205_212729_cruise_l0.dat'

;filex = '/disks/data/maven/data/sci/pfp/l0/mvn_pfp_all_l0_20131109_v1.dat'

;filex = '/disks/data/maven/ITF/CruisePhase_SOCRealtime_LevelZero/20140205_212729_cruise_l0.dat'

;filex = '/disks/data/maven/data/sci/pfp/l0/mvn_pfp_all_l0_20140310_v002.dat'
filex = '/disks/data/maven/data/sci/pfp/l0/mvn_pfp_all_l0_20160405_v003.dat'

mvn_over_shell, l0_input_file = filex, $
  directory = '~/public_html/maven/test_overplot/', $
  instr_to_process = ['over', 'lpw','mag','sep', 'sta','swe','swia'], /date_only

End
