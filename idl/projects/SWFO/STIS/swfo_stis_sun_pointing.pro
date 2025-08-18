; swfo_stis_sun_pointing.pro


; filename = 'SWFO_STIS_ioncal__combined_l0b.nc'
filename = 'stis_e2e4_rfr_realtime_30min_combined_l0b.nc'
; filename = 'SWFO_STIS_xray_combined_l0b_decimation_factor_bits_2_3_5_6.nc'
; filename = 'SWFO_STIS_xray_combined_l0b_decimation_factor_bits_6_5_3_2.nc'
filename = 'STIS_L0B_SSL_Xray_upd.nc'
filename = 'STIS_L0B_SSL_iongun_upd.nc'
; MR 3
; 6/10 start file - data rate change
; Day 1 (June 10): Earth-pointing to Sun-pointing and back -
; We started the day in our earth/off point configuration.
; The transition to sunpoint was commanded at DOY 161 20:15:03 UTC.
; We then commanded back to our earth/off point configuration at 20:33:13 UTC.
filename = 'MR3_RFR/gpa_generated_products/stis_realtime_s20250610T200009_e20250610T204459_p20250731T182621.729309_0b.nc'
; ; 6/11 mid file - biggest
; Day 2 (June 11):  large CCOR-2 rotational calibration maneuver, ~1600-1622 UTC
; filename = 'MR3_RFR/gpa_generated_products/stis_realtime_s20250611T154501_e20250611T162959_p20250731T181415.096805_0b.nc'
; 6/13 end file - most angle changes
; Day 4 (June 13): two MAG maneuvers, ~1630-1709 UTC (10 rotations) and ~1730-1821 (5 rotations)
filename = 'MR3_RFR/gpa_generated_products/stis_realtime_s20250613T160000_e20250613T182958_p20250731T183403.166441_0b.nc'

; ; E2E5
; filename = 'E2E5_RFR/gpa_generated_products/stis_realtime_s20250625T200001_e20250625T235159_p20250731T191157.055653_0b.nc'


l0b = swfo_ncdf_read(filenames=filename, force_recdim=0)
l1a =   swfo_stis_sci_level_1a(l0b)


; From email from Mike Head:
; There is a not a quaternion that is relative to the sun as they all
; report body to ECI. We do have vectors of the sun location that are useful.
; There is ADSCSUNX/Y/Z which is the modeled sun in ECI and can be rotated into the
; body frame using the body frame attitude quaternion (ADBFAQ#).
; This is what is used for sun truth when in Point state.
; Or there is the measured sun as reported by the CSS which is already
; in the body frame (ADMSUNVX,Y,Z), but does have some added errors due to the coarse nature of the sensor. 

; ADSCSUNVX[Y,Z] / modeled_spacecraft_sun_vxyz is the modeled sun vector is in ECI coordinates
model_sun_vec_eci = l0b.modeled_spacecraft_sun_vxyz

; ADMSUNVX[Y,Z] / measured_sun_vector_xyz is the measured sun vector in SC coordinates
; this is the only vector simulated in MR3
meas_sun_vec_sc = l0b.measured_sun_vector_xyz

; test unchanging:
; total_dv_model = total(abs(model_sun_vec_eci[*, 1:-1] - model_sun_vec_eci[*, 0:-2]))
; total_dv_meas = total(abs(meas_sun_vec_sc[*, 1:-1] - meas_sun_vec_sc[*, 0:-2]))

; this is the quaternion that converts from EGI to s/c coordinates
q = l0b.BODY_FRAME_ATTITUDE_Q1234

; Put the modeled sun vector into s/c body coordinates:
model_sun_vec_sc = quaternion_rotation(model_sun_vec_eci, q, last_index=1)

store_data, 'swfo_quat_eci2sc', data={x: l0b.time_unix, y: transpose(q)}, dl={labflag: 1, labels: ['q1', 'q2', 'q3', 'q4']}


store_data, 'swfo_sun_model_eci', data={x: l0b.time_unix, y: transpose(model_sun_vec_eci)}, dl={labflag: 1, labels: ['X', 'Y', 'Z']}
tplot, 'swfo_sun_model_eci'
ylim, 'swfo_sun_model_eci', -1.5, 1.5

store_data, 'swfo_sun_model_sc', data={x: l0b.time_unix, y: transpose(model_sun_vec_sc)}, dl={labflag: 1, labels: ['X', 'Y', 'Z']}
tplot, 'swfo_sun_model_sc'
ylim, 'swfo_sun_model_sc', -1.5, 1.5

store_data, 'swfo_sun_meas_sc', data={x: l0b.time_unix, y: transpose(meas_sun_vec_sc)}, dl={labflag: 1, labels: ['X', 'Y', 'Z']}
tplot, 'swfo_sun_meas_sc'
ylim, 'swfo_sun_meas_sc', -1.5, 1.5


tplot, ['swfo_quat_eci2sc', 'swfo_sun_model_eci', 'swfo_sun_model_sc', 'swfo_sun_meas_sc']

; ; Show data by mnemonic:
; store_data, 'swfo_ADSCSUNXYZ', data={x: l0b.time_unix, y: transpose(l0b.modeled_spacecraft_sun_vxyz)}, dl={labflag: 1, labels: ['X', 'Y', 'Z']}
; store_data, 'swfo_ADISUNXYZ', data={x: l0b.time_unix, y: transpose(l0b.modeled_intertial_sun_vxyz)}, dl={labflag: 1, labels: ['X', 'Y', 'Z']}
; store_data, 'swfo_ADMSUNXYZ', data={x: l0b.time_unix, y: transpose(l0b.measured_sun_vector_xyz)}, dl={labflag: 1, labels: ['X', 'Y', 'Z']}
; store_data, 'swfo_ADSCSUNDIST', data={x: l0b.time_unix, y: l0b.MODELED_SPACECRAFT_SUN_DIST}, dl={labflag: 1, labels: ['X', 'Y', 'Z']}
; tplot, ['swfo_quat_eci_sc', 'swfo_ADSCSUNXYZ', 'swfo_ADISUNXYZ', 'swfo_ADMSUNXYZ', 'swfo_ADSCSUNDIST']

; stop




; tplot, ['swfo_sun_eci', 'swfo_quat_eci2sc', 'swfo_sun_sc']
; stop

sun_sc = l0b.measured_sun_vector_xyz
store_data, 'swfo_sun_sc', data={x: l0b.time_unix, y: transpose(sun_sc)}, dl={labflag: 1, labels: ['X', 'Y', 'Z']}
ylim, 'swfo_sun_sc', -1.5, 1.5

; check sun vector magnitude
; close but not always 1:
sun_vec_mag = sqrt(sun_sc[0, *]^2 + sun_sc[1, *]^2 + sun_sc[2, *]^2)

print, min(sun_vec_mag)
print, max(sun_vec_mag)

; Spacecraft coordinates:
; - X_sc:
;		HGA aligned with -X_sc, +X_sc along coronagraph / solar panel
; - +Z_sc: mounted on STIS side of s/c 
; - +Y_sc: every instrument on the top of s/c
; so assume STIS is pointed along [sin(45), 0, sin(45)]

stis_sun_angle = 50
stis_sc_pointing = [cos(stis_sun_angle * !dtor), 0, sin(stis_sun_angle * !dtor)]
stis_fov = stis_sc_pointing

; Angle between X_sc and sun (nominally should be close to 0):
sun_sc_angle = acos(reform(sun_sc[0, *])) / !dtor

; Angle between STIS FOV and sun:
sun_stis_dp = reform(stis_fov[0] * sun_sc[0, *] + stis_fov[1] * sun_sc[1, *] + stis_fov[2] * sun_sc[2, *])
sun_stis_angle = acos(sun_stis_dp) / !dtor

; Store the translate and res (only varied in the Xray test)
store_data, 'swfo_stis_l0b_sci_translate', data={x: l0b.time_unix, y: l0b.sci_translate}, dl={ylog: 1, yrange: [1, 2e4]}
store_data, 'swfo_stis_l0b_sci_resolution', data={x: l0b.time_unix, y: l0b.sci_resolution}
store_data, 'swfo_stis_l0b_sci_counts', data={x: l0b.time_unix, y: transpose(l0b.sci_counts)}, dl={zlog: 1, ylog: 0, spec: 1}
; offpointing s/c flag: 15 deg earth pointing, 0 deg sun pointing
; - set flag if earth pointing?  +/-5 deg?
store_data, 'swfo_stis_l1a_sun_sc_angle', data={x: l0b.time_unix, y: sun_sc_angle}
; sun in stis fov flag: angle subtended by fov 60 x 80 deg, angle of
; sun relative to center of boresight between 30-40
; - set flag if under 40
store_data, 'swfo_stis_l1a_sun_fov_angle', data={x: l0b.time_unix, y: sun_stis_angle}

iru_bits = l0b.iru_bits

iru_bit_labels = ['IRU Misalignment Bypass', 'IRU Memory Effect Error',$
				  'IRU X Health', 'IRU Y Health', 'IRU Z Health',$
				  'IRU X Valid', 'IRU Y Valid', 'IRU Z Valid']

iru = iru_bits[0, *] + ishft(iru_bits[1, *], 1) + ishft(iru_bits[2, *], 2) +$
	 ishft(iru_bits[3, *], 3) + ishft(iru_bits[4, *], 4) +$
	 ishft(iru_bits[5, *], 5) + ishft(iru_bits[6, *], 6) + ishft(iru_bits[7, *], 7)

store_data, 'swfo_stis_l0b_iru_bits', data={x: l0b.time_unix, y: iru}
options, 'swfo_stis_l0b_iru_bits', tplot_routine='bitplot', labels=iru_bit_labels, psyms=1

tplot, ['swfo_quat_eci_sc', 'swfo_sun_sc', 'swfo_stis_l0b_sci_counts', 'swfo_stis_l1a_sun_sc_angle', 'swfo_stis_l1a_sun_fov_angle', 'swfo_stis_l0b_iru_bits']

end