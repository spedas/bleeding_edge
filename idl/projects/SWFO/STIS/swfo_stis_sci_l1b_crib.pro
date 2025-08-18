; swfo_stis_sci_l1b_crib.pro


; filename = 'SWFO_STIS_ioncal__combined_l0b.nc'
; filename = 'stis_e2e4_rfr_realtime_30min_combined_l0b.nc'
filename = 'SWFO_STIS_xray_combined_l0b_decimation_factor_bits_2_3_5_6.nc'
; filename = 'SWFO_STIS_xray_combined_l0b_decimation_factor_bits_6_5_3_2.nc'
; filename = 'STIS_L0B_SSL_Xray_upd.nc'
; filename = 'STIS_L0B_SSL_iongun_upd.nc'
l0b = swfo_ncdf_read(filenames=filename, force_recdim=0)
l1a =   swfo_stis_sci_level_1a(l0b)
l1b =   swfo_stis_sci_level_1b(l1a)

swfo_stis_hdr_tplot, l1b, /elec, /ion
; tplot, ['swfo_stis_l1b_eta', 'swfo_stis_ion_Ch1_flux', 'swfo_stis_ion_Ch3_flux', 'swfo_stis_ion_hdr_flux']
options, '*_flux', zrange=[1e-2, 1e5]


qflag_labels = ['Playback', 'P1 Enabled', 'P2 Enabled', 'P3 Enabled', 'P4 Enabled', 'P5 Enabled', 'P6 Enabled', $
                '1: High Nse Sigma', '2: High Nse Sigma', '3: High Nse Sigma', $
                '4: High Nse Sigma', '5: High Nse Sigma', '6: High Nse Sigma', $
                'Disabled detectors', '2: Dec On', $
                '3: Dec on', '5: Dec on', '6: Dec on', $
                '1: Rate > Thr.', '2: Rate > Thr.', '3: Rate > Thr.', $
                '4: Rate > Thr.', '5: Rate > Thr.', '6: Rate > Thr.', $
                'Sus pixel merge', 'E- Contam', 'T > Tlim', $
                '', '', '', 'Nonstand. config', '', $
                'RxWh 1', 'RxWh 2', 'RxWh 3', 'RxWh 4', '', '', $
                'any IRU invalid', 'Offpoint', 'Sun in FOV']

store_data, 'quality_bits', data={x: l1a.time_unix, y: l1a.quality_bits}
options, 'quality_bits', tplot_routine='bitplot', labels=qflag_labels, psyms=1

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

end