; swfo_stis_l1a_coincidence_crib.pro


; filename = 'SWFO_STIS_ioncal__combined_l0b.nc'
filename = 'stis_e2e4_rfr_realtime_30min_combined_l0b.nc'
; filename = 'SWFO_STIS_xray_combined_l0b_decimation_factor_bits_2_3_5_6.nc'
; filename = 'SWFO_STIS_xray_combined_l0b_decimation_factor_bits_6_5_3_2.nc'
filename = 'STIS_L0B_SSL_Xray_upd.nc'
; filename = 'STIS_L0B_SSL_iongun_upd.nc'
; filename = 'gpa_generated_products/stis_realtime_s20250613T160000_e20250613T182958_p20250724T000929.143235_0b.nc'

l0b = swfo_ncdf_read(filenames=filename, force_recdim=0)
l1a =   swfo_stis_sci_level_1a(l0b)

; Make a plot of level 1a spectra, assuming the y_axis is:
; 0 - bin indices (48)
; 1 - ADC values
; 2 - energy values
y_axis = 1

dl_all = dictionary()
dl_all.bin_index = {zlog: 1, ylog: 0, spec: 1}
dl_all.ADC = {zlog: 1, ylog: 1, spec: 1} ;, yrange: [1, 1e4]}
dl_all.energy = {zlog: 1, ylog: 1, spec: 1};, yrange: [1, 7e4]}

; Store the translate and res (only varied in the Xray test)
store_data, 'swfo_stis_l0b_sci_translate', data={x: l0b.time_unix, y: l0b.sci_translate}, dl={ylog: 1, yrange: [1, 2e4]}
store_data, 'swfo_stis_l0b_sci_resolution', data={x: l0b.time_unix, y: l0b.sci_resolution}
store_data, 'swfo_stis_l0b_sci_counts', data={x: l0b.time_unix, y: transpose(l0b.sci_counts)}, dl={zlog: 1, ylog: 0, spec: 1}

; Now make plots for the detector coincidences:
triple_coincidence = ['F123', 'O123']
double_coincidence = ['F12', 'O12', 'F13', 'O13', 'F23', 'O23']
single_coincidence = ['F1', 'O1', 'F2', 'O2', 'F3', 'O3']

time_array = l1a.time_unix

foreach coincidence_array, [single_coincidence, double_coincidence, triple_coincidence] do begin
    foreach coincidence, coincidence_array do begin

        ; get spectra:
        str_element, l1a, 'SPEC_' + coincidence, spectra_i

        if y_axis eq 0 then begin
            v = findgen(48)
            dl = dl_all.bin_index
        endif else  if y_axis eq 1 then begin
            str_element, l1a, 'SPEC_' + coincidence + '_ADC', v
            dl = dl_all.ADC
        endif else if y_axis eq 2 then begin
            str_element, l1a, 'SPEC_' + coincidence + '_NRG', v
            dl = dl_all.energy
        endif

        v_dim = size(v, /dim)

        if v_dim[0] ne n_elements(time_array) then v = transpose(v)

        store_data, 'swfo_stis_l1a_spec_' + coincidence, data={x: time_array, v: v, y: transpose(spectra_i)}, dl=dl

    endforeach
endforeach

tplot, ['swfo_stis_l0b_sci_counts']
tplot, 'swfo_stis_l1a_spec_' + single_coincidence
; tplot, 'swfo_stis_l1a_spec_' + double_coincidence
; tplot, 'swfo_stis_l1a_spec_' + triple_coincidence
tplot, ['swfo_stis_l0b_sci_translate', 'swfo_stis_l0b_sci_resolution'], /add

end