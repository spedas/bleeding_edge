;+
; MMS FEEPS crib sheet
; 
; do you have suggestions for this crib sheet? 
;   please send them to egrimes@igpp.ucla.edu
;   
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-09-14 13:50:10 -0700 (Thu, 14 Sep 2017) $
; $LastChangedRevision: 23979 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_load_feeps_crib.pro $
;-

xsize=600
ysize=850

mms_load_feeps, probes='1', trange=['2015-10-16', '2015-10-17'], datatype='electron', level='l2'
mms_feeps_pad,  probe='1', datatype='electron', energy=[70, 1000]

; plot the omni-directional spectra, spin-averaged spectra, PAD and spin-averaged PAD
window, 0, xsize=xsize, ysize=ysize
tplot, ['mms1_epd_feeps_srvy_l2_electron_intensity_omni', $
        'mms1_epd_feeps_srvy_l2_electron_intensity_omni_spin', $
        'mms1_epd_feeps_srvy_l2_electron_intensity_70-1000keV_pad', $
        'mms1_epd_feeps_srvy_l2_electron_intensity_70-1000keV_pad_spin'], window=0
stop

; plot the spectra for each individual telescope
window, 1, xsize=xsize, ysize=ysize
tplot, '*_clean_sun_removed', window=1
stop
end