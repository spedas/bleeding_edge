;+
; MMS EIS crib sheet
; 
;  prime EIS scientific products are: 
;    ExTOF proton spectra
;    ExTOF He spectra
;    ExTOF Oxygen spectra
;    PHxTOF proton spectra
;    
;  
; do you have suggestions for this crib sheet? 
;   please send them to egrimes@igpp.ucla.edu
;   
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-05-19 10:51:27 -0700 (Thu, 19 May 2016) $
; $LastChangedRevision: 21138 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_load_eis_crib.pro $
;-
probe = '1'
prefix = 'mms'+probe
trange = ['2015-10-16', '2015-10-17']
tplot_options, 'xmargin', [20, 15]
level = 'l2'

; load ExTOF data:
mms_load_eis, probes=probe, trange=trange, datatype='extof', level = level 

; plot the H+ flux for all channels
tplot, '*_extof_proton_flux_omni_spin'
stop

; calculate the PAD for 48-106keV protons
mms_eis_pad, probe=probe, species='ion', datatype='extof', ion_type='proton', data_units='flux', energy=[48, 106], level = level

; calculate the PAD for 105-250 keV protons
mms_eis_pad, probe=probe, species='ion', datatype='extof', ion_type='proton', data_units='flux', energy=[105, 250], level = level

; plot the PAD for 48-106keV (top), 105-250 keV (bottom) protons
tplot, '*_epd_eis_extof_*keV_proton_flux_omni_pad_spin'
stop

; plot the He++ flux for all channels
tplot, '*extof_alpha_flux_omni_spin'

stop

; plot the O+ flux for all channels
tplot, '*_extof_oxygen_flux_omni_spin'

stop

; load PHxTOF data:
mms_load_eis, probes=probe, trange=trange, datatype='phxtof', level = level

; plot the PHxTOF proton spectra
tplot, '*_phxtof_proton_flux_omni_spin'
stop

; calculate the PHxTOF PAD for protons
mms_eis_pad, probe=probe, species='ion', datatype='phxtof', ion_type='proton', data_units='flux', energy=[0, 30], level = level

tplot, ['*_epd_eis_phxtof_proton_flux_omni_spin', $
        '*_epd_eis_phxtof_0-30keV_proton_flux_omni_pad_spin']
stop

; load some electron data; note that the datatype for electron data is "electronenergy"
mms_load_eis, probes=probe, trange=trange, datatype='electronenergy', level = level
mms_eis_pad, probe=probe, species='electron', datatype='electronenergy', data_units='flux', level = level

; plot the electron spectra
tplot, ['*_epd_eis_electronenergy_electron_flux_omni_spin', '*_epd_eis_electronenergy_*keV_electron_flux_omni_pad_spin']

stop
end