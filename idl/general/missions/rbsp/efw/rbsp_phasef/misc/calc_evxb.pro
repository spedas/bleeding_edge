;+
; Calculate the E_vxb due to Vsc x B.
; They need to be in the same coord.
;
; b_var=.
; v_var=.
; r_var=.
; save_to=.
; probe=.
;-
pro calc_evxb, b_var=b_var, v_var=v_var, save_to=e_var, probe=probe

    if n_elements(e_var) eq 0 then message, 'No output e_var ...'
    get_data, b_var, times, b_vec, limits=limits
    b_coord = strlowcase(limits.coord)
    get_data, v_var, uts, v_vec, limits=limits
    v_vec = sinterpol(v_vec, uts, times, /quadratic)
    coord = strlowcase(limits.coord)
    if coord ne b_coord then message, 'Inconsistent coord ...'

    evxb_vec = vec_cross(v_vec, b_vec)*1e-3
    store_data, e_var, times, evxb_vec
    add_setting, e_var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'VxB E', $
        'unit', 'mV/m', $
        'coord', strupcase(coord), $
        'coord_labels', limits.coord_labels )

end