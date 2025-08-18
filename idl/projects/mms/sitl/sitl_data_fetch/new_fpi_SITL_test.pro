; New FPI Test
; 
; Shows how to use the FPI moments wrapper for mms_load_fpi (and mms_sitl_get_fpi). Shows new variable names.

timespan, '2015-10-16/12:00:00', 2, /hours

sc_id = 'mms1'

mms_sitl_fpi_moments, sc_id = sc_id, /clean

; Plot the parameters

e_spectra = sc_id + '_fpi_electrons'
i_spectra = sc_id + '_fpi_ions'
i_vel = sc_id + '_fpi_ion_vel_dbcs'
e_vel = sc_id + '_fpi_elec_vel_dbcs'
dens = sc_id + '_fpi_density'
temp = sc_id + '_fpi_temp'
lowpad = sc_id + '_fpi_epad_lowen_fast'
midpad = sc_id + '_fpi_epad_miden_fast'
highpad = sc_id + '_fpi_epad_highen_fast'

tplot, [e_spectra, i_spectra, i_vel, e_vel, dens, temp, lowpad, midpad, highpad]

end