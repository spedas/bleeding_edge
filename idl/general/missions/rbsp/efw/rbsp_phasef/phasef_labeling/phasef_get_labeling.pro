;+
; Return the default labeling.
;
; key.
;-

function phasef_get_labeling, key

    master_labeling = dictionary($
        'efield_in_corotation_frame_spinfit_mgse', dictionary(), $
        'efield_in_corotation_frame_spinfit_edotb_mgse', dictionary(), $
        'efield_in_inertial_frame_spinfit_mgse', dictionary(), $
        'efield_in_inertial_frame_spinfit_edotb_mgse', dictionary(), $
        'e_boom_length', dictionary(), $        ; Nothing to change.
        'e_shorting_factor', dictionary(), $    ; Nothing to change.
        'L_vector', dictionary($
            'VAR_NOTES', 'Unit vector of spin axis (w) in the GSE coordinate system, also the pointing direction defining the spacecraft angular velocity', $
            'UNITS', '#', $
            'labels', 'SpinAxis '+['x','y','z']+' GSE', $
            'LABL_PTR_1', 'metavar0' ), $
        'efw_qual', dictionary(), $     ; Nothing to change.
        'e_hires_uvw_efw_qual', dictionary(), $   ; Nothing to change.
        'e_hires_uvw', dictionary($
            'VAR_NOTES', 'DC electric field in the UVW coordinate system at 16 or 32 samples/sec', $
            'UNITS', 'mV/m', $
            'labels', 'E'+['u','v','w'], $
            'LABL_PTR_1', 'E_vector_labl' ), $
        'e_hires_uvw_raw', dictionary($
            'VAR_NOTES', 'DC electric field in the UVW coordinate system at 16 or 32 samples/sec, without spinning-frame offset removal', $
            'UNITS', 'mV/m', $
            'labels', 'E'+['u','v','w']+' raw', $
            'LABL_PTR_1', 'E_vector_labl' ), $
        'efield_spinfit_mgse', dictionary($
            'VAR_NOTES', 'Spinfit electric field in the MGSE coordinate system (Vsc x B and Omega x R x B subtracted)', $
            'UNITS', 'mV/m', $
            'CATDESC', 'efield_in_inertial_frame_spinfit_mgse', $
            'labels', 'E'+['x','y','z']+' MGSE', $
            'LABL_PTR_1', 'metavar0' ), $
        'VxB_mgse', dictionary($
            'VAR_NOTES', 'Electric field equals to Vsc x B in the MGSE coordinate system, where Vsc is spacecraft velocity and B is the measured magnetic field', $
            'UNITS', 'mV/m', $
            'labels', 'Evxb '+['x','y','z']+' MGSE', $
            'LABL_PTR_1', 'metavar3' ), $
        'efield_coro_mgse', dictionary($
            'VAR_NOTES', "Corotation efield equals to Omega x R x B in the MGSE coordinate system, where B is measured magnetic field, Omega is the Earth's spin axis angular frequency vector, and R is the vector from the Earth's center to the satellite", $
            'UNITS', 'mV/m', $
            'labels', 'Ecoro '+['x','y','z']+' MGSE', $
            'LABL_PTR_1', 'metavar2' ), $
        'corotation_efield_mgse', dictionary($
            'VAR_NOTES', "Corotation efield equals to Omega x R x B in the MGSE coordinate system, where B is measured magnetic field, Omega is the Earth's spin axis angular frequency vector, and R is the vector from the Earth's center to the satellite", $
            'UNITS', 'mV/m', $
            'labels', 'Ecoro '+['x','y','z']+' MGSE', $
            'LABL_PTR_1', 'metavar2' ), $
        'efield_mgse', dictionary($
            'VAR_NOTES', 'Electric field in the MGSE coordinate system (Vsc x B subtracted) at 16 or 32 samples/sec.', $
            'UNITS', 'mV/m', $
            'CATDESC', 'efield_in_inertial_frame_mgse', $
            'labels', 'E'+['x','y','z']+' MGSE', $
            'LABL_PTR_1', 'efield_mgse_LABL_1' ), $
        'spinaxis_gse', dictionary($
            'VAR_NOTES', 'Unit vector of spin axis (w) in the GSE coordinate system, also the pointing direction defining the spacecraft angular velocity', $
            'UNITS', '#', $
            'labels', 'SpinAxis '+['x','y','z']+' GSE', $
            'LABL_PTR_1', 'metavar5' ), $
        'bias_current', dictionary($
            'VAR_NOTES', 'Bias current (nA) applied to the antenna probes', $
            'UNITS', 'nA', $
            'labels', 'V'+['1','2','3','4','5','6'], $
            'LABL_PTR_1', 'bias_current_LABL_1' ), $
        'diagEx1', dictionary(), $
        'diagEx2', dictionary(), $
        'diagBratio', dictionary(), $
        'flags_all', dictionary(), $
        'vsvy', dictionary($
            'VAR_NOTES', 'Sigle-ended antenna potentials in Volts', $
            'UNITS', 'V', $
            'labels', 'V'+['1','2','3','4','5','6'], $
            'LABL_PTR_1', 'Vsvy_LABL_1' ), $
        'vsvy_vavg', dictionary($
            'VAR_NOTES', 'Average of opposing antenna potentials in Volts', $
            'UNITS', 'V', $
            'labels', ['(V1+V2)/2','(V3+V4)/2','(V5+V6)/2'], $
            'LABL_PTR_1', 'vsvy_vagv_LABL_1'), $
        'orbit_num', dictionary($
            'VAR_NOTES', 'orbit number', $
            'UNITS', '#'), $
        'velocity_gse', dictionary($
            'VAR_NOTES', 'Spacecraft velocity in km/s in the GSE coordinate system', $
            'UNITS', 'km/s', $
            'labels', 'Vel '+['x','y','z']+ ' GSE', $
            'LABL_PTR_1', 'vel_gse_LABL_1'), $
        'position_gse', dictionary($
            'VAR_NOTES', 'Spacecraft position in km in the GSE coordinate system', $
            'UNITS', 'km', $
            'labels', 'Pos '+['x','y','z']+' GSE', $
            'LABL_PTR_1', 'pos_gse_LABL_1'), $
        'vel_gse', dictionary($
            'VAR_NOTES', 'Spacecraft velocity in km/s in the GSE coordinate system', $
            'UNITS', 'km/s', $
            'labels', 'Vel '+['x','y','z']+ ' GSE', $
            'LABL_PTR_1', 'vel_gse_LABL_1'), $
        'pos_gse', dictionary($
            'VAR_NOTES', 'Spacecraft position in km in the GSE coordinate system', $
            'UNITS', 'km', $
            'labels', 'Pos '+['x','y','z']+' GSE', $
            'LABL_PTR_1', 'pos_gse_LABL_1'), $
        'mlt', dictionary($
            'VAR_NOTES', 'Spacecraft magnetic local time in hour', $
            'UNITS', 'h' ), $
        'mlat', dictionary($
            'VAR_NOTES', 'Spacecraft magnetic latitude in deg', $
            'UNITS', 'deg' ), $
        'lshell', dictionary($
            'VAR_NOTES', 'Spacecraft L-shell from simple dipole model', $
            'UNITS', '#' ) )

    if ~master_labeling.haskey(key) then begin
        message, 'Do not have labeling for '+key+' ...', /continue
        return, dictionary()
    endif
    return, master_labeling[key]

end
