;+
; PROGRAM: erg_crib_isee_vlf
;   This is an example crib sheet that will load ISEE ELF/VLF data.
;   Open this file in a text editor and then use copy and paste to copy
;   selected lines into an idl window.
;   Or alternatively compile and run using the command:
;     .run erg_crib_isee_vlf
;
; NOTE: See the rules of the road.
;       For more information, see http://stdb2.isee.nagoya-u.ac.jp/vlf/
;
; Written by: S. Kurita, Nov 24, 2017
;             Center for Integrated Data Science, ISEE, Nagoya Univ.
;             erg-sc-core at isee.nagoya-u.ac.jp
;;
;   $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
;   $LastChangedRevision: 26838 $
;-

; initialize
thm_init

; specify 3 hour periods from 2017-03-30/12:00:00
timespan,'2017-03-30/12:00:00',3,/h

; load ISEE ELF/VLF data for ATH and KAP (uncalibrated)
erg_load_isee_vlf,site='ath kap'
; plot uncalibrated VLF data for ATH and KAP
tplot,['isee_vlf_ath_ch1','isee_vlf_ath_ch2','isee_vlf_kap_ch1','isee_vlf_kap_ch2'],$
      title='ISEE ELF/VLF data (Uncalibrated)'
stop

; load ISEE ELF/VLF data for ATH and KAP. Calibration is performed in this case.
erg_load_isee_vlf,site='ath kap',/cal_gain
; plot calibrated VLF data for ATH and KAP
tplot,['isee_vlf_ath_ch1','isee_vlf_ath_ch2','isee_vlf_kap_ch1','isee_vlf_kap_ch2'],$
      title='ISEE ELF/VLF data (Calibrated)'
stop

; change color scale and frequency range
ylim,['isee_vlf_ath_ch1','isee_vlf_ath_ch2','isee_vlf_kap_ch1','isee_vlf_kap_ch2'],0,1e4,0
zlim,['isee_vlf_ath_ch1','isee_vlf_ath_ch2','isee_vlf_kap_ch1','isee_vlf_kap_ch2'],1e-12,1e-7,1
tplot

end
