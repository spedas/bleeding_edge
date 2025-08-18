;+
; PROGRAM: erg_crib_isee_riometer
;   This is an example crib sheet that will load ISEE riometer data.
;   Open this file in a text editor and then use copy and paste to copy
;   selected lines into an idl window.
;   Or alternatively compile and run using the command:
;     .run erg_crib_isee_riometer
;
; NOTE: See the rules of the road.
;       For more information, see http://stdb2.isee.nagoya-u.ac.jp/riometer/
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

; Specify time range for 1 day
timespan,'2017-03-30',1,/d

; load ISEE induction riometer data. Site is ATH.
erg_load_isee_brio,site='ath'

; plot CNA plot obtained at ATH
tplot,'isee_brio30_ath_64hz_cna'
stop

; merge two tplot variables into one to compare QDC with raw data
store_data,'isee_brio30_ath_64hz_raw_w_qdc',$
           data=['isee_brio30_ath_64hz_raw','isee_brio30_ath_64hz_qdc']

; change color for QDC plot
options,'isee_brio30_ath_64hz_qdc',color=1
tplot,'isee_brio30_ath_64hz_raw_w_qdc'

end
