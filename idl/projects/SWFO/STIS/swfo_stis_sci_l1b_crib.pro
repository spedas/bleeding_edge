; swfo_stis_sci_l1b_crib.pro


; filename = 'SWFO_STIS_ioncal__combined_l0b.nc'
; filename = 'stis_e2e4_rfr_realtime_30min_combined_l0b.nc'
; filename = 'SWFO_STIS_xray_combined_l0b_decimation_factor_bits_2_3_5_6.nc'
; filename = 'SWFO_STIS_xray_combined_l0b_decimation_factor_bits_6_5_3_2.nc'
filename = 'STIS_L0B_SSL_Xray_upd.nc'
; filename = 'STIS_L0B_SSL_iongun_upd.nc'
l0b = swfo_ncdf_read(filenames=filename, force_recdim=0)
cal = swfo_stis_inst_response_calval()
l1a =   swfo_stis_sci_level_1a(l0b, cal=cal)
l1b =   swfo_stis_sci_level_1b(l1a, cal=cal)

swfo_stis_hdr_tplot, l1b, /elec, /ion
; tplot, ['swfo_stis_l1b_eta', 'swfo_stis_ion_Ch1_flux', 'swfo_stis_ion_Ch3_flux', 'swfo_stis_ion_hdr_flux']
options, '*_flux', zrange=[1e-2, 1e5]

; Detector bits + sci_resolution/translate:
store_data, 'swfo_stis_detector_bits', data={x: l0b.time_unix, y: l0b.detector_bits}
detector_flag_labels = ['Det. 1 Enabled', 'Det. 2 Enabled', 'Det. 3 Enabled', 'Det. 4 Enabled', 'Det. 5 Enabled', 'Det. 6 Enabled', 'Linear', 'Decimate On']
options, 'swfo_stis_detector_bits', tplot_routine='bitplot', psyms=1, labels=detector_flag_labels
store_data, 'swfo_stis_sci_resolution', data={x: l0b.time_unix, y: l0b.sci_resolution}
store_data, 'swfo_stis_sci_translate', data={x: l0b.time_unix, y: l0b.sci_translate}

tplot, ['swfo_stis_elec_Ch1_flux', 'swfo_stis_elec_Ch3_flux', 'swfo_stis_elec_hdr_flux',$
        'swfo_stis_sci_translate', 'swfo_stis_detector_bits', 'swfo_stis_sci_resolution']
; stop


store_data, 'quality_bits', data={x: l1b.time_unix, y: l1b.quality_bits}
options, 'quality_bits', tplot_routine='bitplot', labels=cal.qflag_labels, psyms=1

store_data, 'total6', data={x: l1a.time_unix, y: transpose(l1a.total6)}
options, 'total6', labels=['Ch1', 'Ch2', 'Ch3', 'Ch4', 'Ch5', 'Ch6'], ylog=1, labflag=1

store_data, 'noise_sigma', data={x: l1a.time_unix, y: transpose(l1a.noise_sigma)}
options, 'noise_sigma', labels=['Ch1', 'Ch2', 'Ch3', 'Ch4', 'Ch5', 'Ch6'], labflag=1

store_data, 'noise_histogram', data={x: l1a.time_unix, y: transpose(l1a.noise_histogram)}
options, 'noise_histogram', labels=['Ch1', 'Ch2', 'Ch3', 'Ch4', 'Ch5', 'Ch6'], labflag=1, spec=1,/no_interp,/zlog,constant=findgen(6)*10+5

; tplot, ['quality_bits', 'total6', 'noise_sigma', 'noise_histogram']
tplot, ['swfo_stis_l1b_eta', 'swfo_stis_elec_Ch1_flux',$
        'swfo_stis_elec_Ch3_flux', 'swfo_stis_elec_hdr_flux',$
        'quality_bits']
; stop

; ; Test of contamination (electrons in ion) information:
; store_data, 'contam_inrange',$
;   data={x: l1b.time_unix, y: l1b.contam_inrange},$
;   dlimits={yrange: [-0.1, 1.1]}
; store_data, 'contam_elec_rate',$
;   data={x: l1b.time_unix, y: l1b.contam_elec_rate},$
;   dlimits={constant: cal.contam_min_electron_count_rate}
; store_data, 'contam_ion_rate',$
;   data={x: l1b.time_unix, y: l1b.contam_ion_rate},$
;   dlimits={constant: cal.contam_min_ion_count_rate}
; store_data, 'contam_elec_ion_ratio',$
;   data={x: l1b.time_unix, y: l1b.contam_elec_ion_ratio},$
;   dlimits={constant: cal.contam_min_ion_ratio, psym: 5, yrange: [0, 0.5]}
; store_data, 'contam_elec_ion_dev',$
;   data={x: l1b.time_unix, y: l1b.contam_elec_ion_dev},$
;   dlimits={constant: cal.contam_ion_max_deviation_power_law, psym: 5}

; tplot, ['swfo_stis_elec_hdr_flux', 'swfo_stis_ion_hdr_flux',$
;         'contam_inrange', 'contam_elec_rate', 'contam_ion_rate',$
;         'contam_elec_ion_ratio', 'contam_elec_ion_dev',$
;         'quality_bits']
; stop

store_data, 'swfo_stis_ion_pixel_ratio', data={x: l1b.time_unix, y: l1b.ion_pixel_ratio} 
store_data, 'swfo_stis_elec_pixel_ratio', data={x: l1b.time_unix, y: l1b.elec_pixel_ratio}
; store_data, 'swfo_stis_ion_pixel_ratio_error', data={x: l1b.time_unix, y: l1b.ion_pixel_ratio_error} 
; store_data, 'swfo_stis_elec_pixel_ratio_error', data={x: l1b.time_unix, y: l1b.elec_pixel_ratio_error}

store_data, 'swfo_stis_pixel_ratio', data=['swfo_stis_ion_pixel_ratio', 'swfo_stis_elec_pixel_ratio']
options, 'swfo_stis_pixel_ratio', labflag=1, labels=['ion', 'elec'], colors='rb'

; store_data, 'swfo_stis_pixel_ratio_error', data=['swfo_stis_ion_pixel_ratio_error', 'swfo_stis_elec_pixel_ratio_error']
; options, 'swfo_stis_pixel_ratio_error', labflag=1, labels=['ion', 'elec'], colors='rb'

tplot, ['swfo_stis_l1b_eta',$
        'swfo_stis_elec_Ch1_flux', 'swfo_stis_elec_Ch3_flux', 'swfo_stis_elec_hdr_flux',$
        'swfo_stis_ion_Ch1_flux', 'swfo_stis_ion_Ch3_flux', 'swfo_stis_ion_hdr_flux',$
        'quality_bits', 'swfo_stis_pixel_ratio']

ylim, 'swfo_stis_pixel_ratio', 0, 0.05

end