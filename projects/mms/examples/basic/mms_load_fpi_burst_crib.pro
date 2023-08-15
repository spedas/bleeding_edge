;+
; MMS FPI burst mode crib sheet
;
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2023-08-14 12:44:51 -0700 (Mon, 14 Aug 2023) $
; $LastChangedRevision: 31998 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_load_fpi_burst_crib.pro $
;-

trange = ['2015-10-16/13:05', '2015-10-16/13:10']
probe = '1'
datatype = ['des-moms', 'dis-moms']
level = 'l2'
data_rate = 'brst'

mms_load_fpi, probes=probe, trange=trange, datatype=datatype, level=level, data_rate=data_rate, min_version='2.2.0'

prefix = 'mms'+strcompress(string(probe), /rem)

; plot the electron pitch angle distribution
tplot, prefix+'_des_pitchangdist_avg'

; add the omni-directional electron spectra
tplot, prefix+'_des_energyspectr_omni_brst', /add

; add the electron compressionloss bar to the figure
tplot, prefix+'_des_compressionloss_brst_moms_flagbars', /add

; add the errorflag bars for electron data
tplot, prefix+'_des_errorflags_brst_moms_flagbars', /add
;tplot, prefix+'_des_errorflags_brst_moms_flagbars_full', /add

; zoom into the burst interval
tlimit, ['2015-10-16/13:05', '2015-10-16/13:08']
stop

; add the omni-directional ion spectra
tplot, prefix+'_dis_energyspectr_omni_brst', /add

; add the ion compressionloss bar to the figure
tplot, prefix+'_dis_compressionloss_brst_moms_flagbars', /add

; add the errorflag bars for ion data
tplot, prefix+'_dis_errorflags_brst_moms_flagbars', /add
;tplot, prefix+'_dis_errorflags_brst_moms_flagbars_full', /add
end
