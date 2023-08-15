;+
; MMS HPCA crib sheet
; 
; This crib sheet shows basic usage of the HPCA routines in SPEDAS; it shows how to 
;   load the data and creates the following figures:
;       1) H+, O+, He+ number density
;       2) H+, O+ and He+ scalar temperature
;       3) H+, O+ and He+ bulk velocity
;       4) H+, O+, He+, He++ flux averaged over full FoV (0-360)
;       5) H+, O+, He+, He++ flux averaged anodes 0 and 15
;       6) H+, O+, He+, He++ spin summed flux averaged over full FoV 
; 
; 
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;     
;   
; $LastChangedBy: egrimes $
; $LastChangedDate: 2023-08-14 12:44:51 -0700 (Mon, 14 Aug 2023) $
; $LastChangedRevision: 31998 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_load_hpca_crib.pro $
;-

; set some reasonable margins
tplot_options, 'xmargin', [20, 15]

; load the moments data
mms_load_hpca, probes='1', trange=['2016-10-16', '2016-10-17'], datatype='moments', data_rate='srvy', level='l2'

; show H+, O+ and He+ density
tplot, ['mms1_hpca_hplus_number_density', $
        'mms1_hpca_oplus_number_density', $
        'mms1_hpca_heplus_number_density']
stop

; show H+, O+ and He+ temperature
tplot, ['mms1_hpca_hplus_scalar_temperature', $
        'mms1_hpca_oplus_scalar_temperature', $
        'mms1_hpca_heplus_scalar_temperature']
stop

; show H+, O+ and He+ flow velocity
tplot, ['mms1_hpca_hplus_ion_bulk_velocity', $
        'mms1_hpca_oplus_ion_bulk_velocity', $
        'mms1_hpca_heplus_ion_bulk_velocity']
stop

; load the ion data
mms_load_hpca, probes='1', trange=['2016-10-16', '2016-10-17'], datatype='ion', level='l2', data_rate='srvy'

; average the flux over the full field of view (0-360)
mms_hpca_calc_anodes, fov=[0, 360], probe='1'
flux_elev = ['mms1_hpca_hplus_flux_elev_0-360', $
             'mms1_hpca_oplus_flux_elev_0-360', $
             'mms1_hpca_heplus_flux_elev_0-360', $
             'mms1_hpca_heplusplus_flux_elev_0-360']
                
; show spectra for H+, O+ and He+, He++
tplot, flux_elev
stop

; repeat above, average anodes 0 and 15
mms_hpca_calc_anodes, anodes=[0, 15], probe='1'
flux_anodes = ['mms1_hpca_hplus_flux_anodes_0_15', $
                       'mms1_hpca_oplus_flux_anodes_0_15', $
                       'mms1_hpca_heplus_flux_anodes_0_15', $
                       'mms1_hpca_heplusplus_flux_anodes_0_15']

; show spectra for H+, O+ and He+, He++
tplot, flux_anodes
stop

; now sum the fluxes for each spin
mms_hpca_spin_sum, probe='1'

tplot, ['mms1_hpca_hplus_flux_elev_0-360_spin', $
        'mms1_hpca_oplus_flux_elev_0-360_spin', $
        'mms1_hpca_heplus_flux_elev_0-360_spin', $
        'mms1_hpca_heplusplus_flux_elev_0-360_spin']

stop

; The following is an example of extracting and working with the HPCA data
; in IDL structures

; to extract data from a tplot variable, use get_data:
get_data, 'mms1_hpca_hplus_phase_space_density', data=hpca_psd, dlimits=hpca_dlimits

; to see the format of the data in the IDL structure, use help, /structure:
help, hpca_psd, /structure

; Note that the indices may be different from what you're 
; expecting; to find which each dimension of Y represents 
; in the IDL data structure, use print_tinfo:
print_tinfo, 'mms1_hpca_hplus_phase_space_density'
stop

; With some higher dimensional products, the array indices can be ambiguous
get_data, 'mms1_hpca_azimuth_angles_per_ev_degrees', data=azimuth_angles

; e.g., the azimuth angles variable has 2 dimensions with 16 elements (16 anodes, 16 azimuths):
help, azimuth_angles, /structure
;** Structure <2283cae0>, 5 tags, length=624902264, data length=624902262, refs=1:
;X               DOUBLE    Array[4843]
;Y               DOUBLE    Array[4843, 63, 16, 16]
;V1              UINT      Array[16]
;V2              DOUBLE    Array[16]
;V3              UINT      Array[63]

; to find which index represents azimuth and which represents anodes,
; use print_tinfo again:
print_tinfo, 'mms1_hpca_azimuth_angles_per_ev_degrees'
;*** Variable: mms1_hpca_azimuth_angles_per_ev_degrees
;<Expression>    DOUBLE    = Array[4843, 63, 16, 16]
;Data format: [Epoch_Angles, mms1_hpca_energy_step_number, mms1_hpca_polar_anode_number, mms1_hpca_azimuth_index]

end