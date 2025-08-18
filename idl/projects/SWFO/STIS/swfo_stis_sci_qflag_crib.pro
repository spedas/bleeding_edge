; swfo_stis_sci_qflag_crib.pro


; filename = 'SWFO_STIS_ioncal__combined_l0b.nc'
; filename = 'stis_e2e4_rfr_realtime_30min_combined_l0b.nc'
; filename = 'SWFO_STIS_xray_combined_l0b_decimation_factor_bits_2_3_5_6.nc'
; filename = 'SWFO_STIS_xray_combined_l0b_decimation_factor_bits_6_5_3_2.nc'
filename = 'STIS_L0B_SSL_Xray_upd.nc'
; filename = 'STIS_L0B_SSL_iongun_upd.nc'
; filename = 'gpa_generated_products/stis_realtime_s20250613T160000_e20250613T182958_p20250724T000929.143235_0b.nc'

; MR 3
; 6/10 start file - data rate change
; Day 1 (June 10): Earth-pointing to Sun-pointing and back -
; We started the day in our earth/off point configuration.
; The transition to sunpoint was commanded at DOY 161 20:15:03 UTC.
; We then commanded back to our earth/off point configuration at 20:33:13 UTC.
filename = 'MR3_RFR/gpa_generated_products/stis_realtime_s20250610T200009_e20250610T204459_p20250731T182621.729309_0b.nc'
; ; 6/11 mid file - biggest
; Day 2 (June 11):  large CCOR-2 rotational calibration maneuver, ~1600-1622 UTC
filename = 'MR3_RFR/gpa_generated_products/stis_realtime_s20250611T154501_e20250611T162959_p20250731T181415.096805_0b.nc'
; 6/13 end file - most angle changes
; Day 4 (June 13): two MAG maneuvers, ~1630-1709 UTC (10 rotations) and ~1730-1821 (5 rotations)
filename = 'MR3_RFR/gpa_generated_products/stis_realtime_s20250613T160000_e20250613T182958_p20250731T183403.166441_0b.nc'

; ; E2E5
; filename = 'E2E5_RFR/gpa_generated_products/stis_realtime_s20250625T200001_e20250625T235159_p20250731T191157.055653_0b.nc'


l0b = swfo_ncdf_read(filenames=filename, force_recdim=0)
l1a =   swfo_stis_sci_level_1a(l0b)

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
ylim, 'quality_bits', -1, 42

store_data, 'total6', data={x: l1a.time_unix, y: transpose(l1a.total6)}
options, 'total6', labels=['Ch1', 'Ch2', 'Ch3', 'Ch4', 'Ch5', 'Ch6'], ylog=1, labflag=1

store_data, 'noise_sigma', data={x: l1a.time_unix, y: transpose(l1a.noise_sigma)}
options, 'noise_sigma', labels=['Ch1', 'Ch2', 'Ch3', 'Ch4', 'Ch5', 'Ch6'], labflag=1

store_data, 'noise_histogram', data={x: l1a.time_unix, y: transpose(l1a.noise_histogram)}
options, 'noise_histogram', labels=['Ch1', 'Ch2', 'Ch3', 'Ch4', 'Ch5', 'Ch6'], labflag=1, spec=1,/no_interp,/zlog,constant=findgen(6)*10+5

tplot, ['quality_bits', 'total6', 'noise_sigma', 'noise_histogram']

; tplot, ['quality_bits']

end