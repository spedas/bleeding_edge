;+
; MMS FPI crib sheet
; mms_load_fpi_crib.pro
; 
; 
;  This version is meant to work with v3.0.0+ of the FPI CDFs
;  
;  
; do you have suggestions for this crib sheet?  
;   please send them to egrimes@igpp.ucla.edu
; 
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-02-16 09:46:56 -0800 (Thu, 16 Feb 2017) $
; $LastChangedRevision: 22802 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_load_fpi_crib.pro $
;-

timespan, '2015-10-16', 1, /day
probe = '1'
datatype = ['des-moms', 'dis-moms'] ; DES/DIS moments file (contains moments, as well as spectra and pitch angle distributions)
level = 'l2'
data_rate = 'fast'

mms_load_fpi, probes = probe, datatype = datatype, level = level, data_rate = data_rate, min_version='2.2.0'

prefix = 'mms'+strcompress(string(probe), /rem)

; plot the pitch angle distribution
tplot, prefix+'_des_pitchangdist_avg'

; add the omni-directional electron spectra
tplot, prefix+'_dis_energyspectr_omni_fast', /add

; add the ion density
tplot, prefix+'_dis_numberdensity_fast', /add

; add the errorflag bars for ion data
tplot, prefix+'_dis_errorflags_fast_moms_flagbars', /add
;tplot, prefix+'_dis_errorflags_fast_moms_flagbars_full', /add

; and the electron density...
tplot, prefix+'_des_numberdensity_fast', /add

; add the errorflag bars for electron data
tplot, prefix+'_des_errorflags_fast_moms_flagbars', /add
;tplot, prefix+'_des_errorflags_fast_moms_flagbars_full', /add

stop

end
