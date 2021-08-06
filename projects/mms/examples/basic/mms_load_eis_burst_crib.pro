;+
; MMS EIS burst data crib sheet
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2021-08-05 09:24:59 -0700 (Thu, 05 Aug 2021) $
; $LastChangedRevision: 30176 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_load_eis_burst_crib.pro $
;-
probe = '1'
trange = ['2015-10-16/13', '2015-10-16/13:10']
prefix = 'mms'+probe
level = 'l2'

tplot_options, 'xmargin', [20, 15]

; load ExTOF burst data:
mms_load_eis, probes=probe, trange=trange, datatype='extof', data_rate='brst', level=level

mms_eis_pad, probe=probe, trange=trange, datatype='extof', species='proton', data_rate='brst', level=level

; plot the proton flux spectra
tdegap, prefix+'_epd_eis_brst_l2_extof_*keV_proton_flux_omni_pad_spin', /overwrite

tplot, prefix+['_epd_eis_brst_l2_extof_proton_flux_omni_spin', $
               '_epd_eis_brst_l2_extof_54-897keV_proton_flux_omni_pad_spin']
               
stop

; load phxtof burst data
mms_load_eis, probes=probe, trange=trange, datatype='phxtof', data_rate='brst', level=level

mms_eis_pad, probe=probe, trange=trange, datatype='phxtof', species='proton', data_rate='brst', level=level

; plot the spectra
tdegap, prefix+'_epd_eis_brst_l2_phxtof_*keV_proton_flux_omni_pad_spin', /overwrite

tplot, prefix+['_epd_eis_brst_l2_phxtof_proton_flux_omni_spin', $
    '_epd_eis_brst_l2_phxtof_54-76keV_proton_flux_omni_pad_spin']

stop

; load the burst mode electron data
; note: different time range from above examples; this is
; because there is no brst mode L2 electronenergy data 
; for October 2015
mms_load_eis, probes=probe, trange=['2016-04-23', '2016-04-24'], datatype='electronenergy', data_rate='brst', level='l2'

; calculate the electron PAD
mms_eis_pad, probe=probe, species='electron', datatype='electronenergy', data_units='flux', data_rate='brst', level='l2'

tplot, ['mms1_epd_eis_brst_l2_electronenergy_electron_flux_omni_spin', $
        'mms1_epd_eis_brst_l2_electronenergy_54-841keV_electron_flux_omni_pad_spin'], $
        trange=['2016-04-23', '2016-04-24'] ; trange required to reset the trange of the plot (default set above to October 2015)

; list tplot variables that were loaded
tplot_names
stop

end