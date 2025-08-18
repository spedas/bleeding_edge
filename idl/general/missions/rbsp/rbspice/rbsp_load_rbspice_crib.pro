;+
; RBSP RBSPICE crib sheet
; 
;  prime RBSPICE scientific products are: 
;    TOFxEH proton spectra
;    TOFxEnonH helium spectra
;    TOFxEnonH oxygen spectra
;    TOFxPHHHELT proton spectra
;    TOFxPHHHELT oxygen spectra
;  
;  
;$LastChangedBy: egrimes $
;$LastChangedDate: 2023-05-04 12:46:31 -0700 (Thu, 04 May 2023) $
;$LastChangedRevision: 31828 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/rbspice/rbsp_load_rbspice_crib.pro $
;-

probe = 'a'
prefix = 'rbsp'+probe
trange = ['2015-10-16', '2015-10-17']
level = 'l3'
tplot_options, 'xmargin', [20, 15]


; load TOFxEH (proton) data:
rbsp_load_rbspice, probe=probe, trange=trange, datatype='TOFxEH', level = level 

; plot the H+ flux for all channels
tplot, '*TOFxEH_proton_omni_spin'
stop

; calculate the PAD for 48-106keV protons
rbsp_rbspice_pad, probe=probe, trange = trange, datatype='TOFxEH', energy=[48, 106], bin_size = 15, level = level

; calculate the PAD for 105-250 keV protons
rbsp_rbspice_pad, probe=probe, trange = trange, datatype='TOFxEH', energy=[105, 250], bin_size = 15, level = level

; plot the PAD for 48-106keV (top), 105-250 keV (bottom) protons 
tplot, '*TOFxEH_proton_omni_*keV_pad' 
stop

; load TOFxEnonH (helium and oxygen) data:
rbsp_load_rbspice, probe=probe, trange=trange, datatype='TOFxEnonH', level = level

; plot the He++ flux for all channels
tplot, '*TOFxEnonH_helium_omni_spin'
stop

; plot the O+ flux for all channels
tplot, '*TOFxEnonH_oxygen_omni_spin'

stop

; load TOFxPHHHELT (proton and oxygen) data:
rbsp_load_rbspice, probe=probe, trange=trange, datatype='TOFxPHHHELT', level = level 

; plot the TOFxPHHHELT proton spectra
tplot, '*_TOFxPHHHELT_proton_omni_spin'
stop

; plot the TOFxPHHHELT oxygen spectra
tplot, '*_TOFxPHHHELT_oxygen_omni_spin'
stop

; calculate the TOFxPHHHELT PAD for protons
rbsp_rbspice_pad, probe=probe, trange=trange, datatype='TOFxPHHHELT', energy=[0, 30], bin_size = 15, level = level

tplot, ['*TOFxPHHHELT_proton_omni_spin', $
        '*TOFxPHHHELT_proton_omni_0-30keV_pad_spin']
stop

end