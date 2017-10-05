;+
; PROCEDURE:
;         mms_mec_fix_metadata
;
; PURPOSE:
;         Helper routine for setting metadata of MEC variables
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-05-01 13:00:22 -0700 (Mon, 01 May 2017) $
;$LastChangedRevision: 23255 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/mec/mms_mec_fix_metadata.pro $
;-

pro mms_mec_fix_metadata, probe, suffix = suffix
    if undefined(suffix) then suffix = ''
    probe = strcompress(string(probe), /rem)
    position_vars = tnames('mms'+probe+'_mec_r_*')
    velocity_vars = tnames('mms'+probe+'_mec_v_*')

    for pos_idx = 0, n_elements(position_vars)-1 do begin
        options, position_vars[pos_idx], colors=[2, 4, 6]
    endfor
    for vel_idx = 0, n_elements(velocity_vars)-1 do begin
        options, velocity_vars[vel_idx], colors=[2, 4, 6]
    endfor
    
    ; the coordinate system for the ECI variables in the MEC files
    ; is set to 'gei'; this represents J2000 GEI, not MOD GEI (which
    ; is what SPEDAS assumes 'gei' is)
    eci_vars = 'mms'+probe+['_mec_r_eci', '_mec_v_eci', $ 
                            '_defatt_spinras', '_defatt_spindec', $; all on this line and below were added 5/1/2017
                            '_mec_L_vec', '_mec_Z_vec', '_mec_P_vec', $
                            '_mec_L_phase', '_mec_Z_phase', '_mec_P_phase', $
                            '_mec_r_moon_de421_eci', $
                            '_mec_r_sun_de421_eci', '_mec_quat_eci_to_bcs', $
                            '_mec_quat_eci_to_dbcs', '_mec_quat_eci_to_dmpa', $
                            '_mec_quat_eci_to_smpa', '_mec_quat_eci_to_dsl', $
                            '_mec_quat_eci_to_ssl', '_mec_quat_eci_to_gsm', $
                            '_mec_quat_eci_to_geo', '_mec_quat_eci_to_sm', $
                            '_mec_quat_eci_to_gse', '_mec_quat_eci_to_gse2000']+suffix
    
    ; split_vars adds the suffix before _0 and _1
    append_array, eci_vars, 'mms'+probe+'_mec_L_vec'+suffix+['_0', '_1']
    for eci_var=0, n_elements(eci_vars)-1 do begin
        get_data, eci_vars[eci_var], data=d, dlimits=dl, limits=l
        if is_struct(d) then begin
          cotrans_set_coord, dl, 'j2000'
          store_data, eci_vars[eci_var], data=d, dlimits=dl, limits=l
        endif
    endfor
end