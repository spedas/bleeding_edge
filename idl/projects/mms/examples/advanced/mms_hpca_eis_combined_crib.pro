;+
;
; mms_hpca_eis_combined_crib
;
; This crib sheet shows how to create a spectra plot with EIS and HPCA data
; on the same panel
;
; ***** WARNING ON USING THIS CRIB SHEET *****
; The EPD and HPCA instrument teams have not fully investigated the 
; cross-calibration of these instruments; combining these spectra 
; should be done on a case-by-case basis. Please contact the instrument 
; teams before combining data from the EPD and plasma instruments.
;
;
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2023-08-14 12:51:35 -0700 (Mon, 14 Aug 2023) $
; $LastChangedRevision: 31999 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_hpca_eis_combined_crib.pro $
;-

mms_load_hpca, trange=['2015-10-16', '2015-10-17'], datatype='ion', probe=1

mms_hpca_calc_anodes, fov=[0, 360]
mms_hpca_spin_sum, probe='1'

mms_load_eis, trange=['2015-10-16', '2015-10-17'], datatype='extof', probe=1

get_data, 'mms1_epd_eis_srvy_l2_extof_proton_flux_omni_spin', data=d, dlimits=dl

; convert the EIS data to eV so the 2 data products are on the same scale
d.V = d.V*1000d 

; resave the EIS proton flux in eV
store_data, 'mms1_epd_eis_srvy_l2_extof_proton_flux_omni_spin', data=d

store_data, 'combined_flux', data='mms1_epd_eis_srvy_l2_extof_proton_flux_omni_spin mms1_hpca_hplus_flux_elev_0-360_spin'

; be sure to set the plot metadata on the combined spectra
options, 'combined_flux', ylog=1, yrange=[1, 1e7], ystyle=1, yticks=7, zrange=[0.1, 1e7]
options, 'combined_flux', ztitle='H+ Flux (cm!U2!N s sr eV)!U-1!N', ytitle='EIS - HPCA', ysubtitle='[eV]'

; potential cross-calibration issue here; please contact the instrument teams before trusting these results
tplot, 'combined_flux'

stop

end
