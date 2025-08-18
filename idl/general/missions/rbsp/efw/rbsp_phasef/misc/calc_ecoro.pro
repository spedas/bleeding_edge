;+
; Calculate the E_coro from r_coord and b_coord.
; They need to be in the same coord.
;
; b_var=.
; r_var=.
; save_to=.
; probe=.
;-
pro calc_ecoro, b_var=b_var, r_var=r_var, save_to=e_var, probe=probe

    if n_elements(e_var) eq 0 then message, 'No output e_var ...'
    get_data, b_var, times, b_vec, limits=limits
    b_coord = strlowcase(limits.coord)
    get_data, r_var, uts, r_vec, limits=limits
    r_vec = sinterpol(r_vec, uts, times, /quadratic)
    coord = strlowcase(limits.coord)
    if coord ne b_coord then message, 'Inconsistent coord ...'
    r_gei = cotran(r_vec, times, coord+'2gei', probe=probe)

    omega = (2*!dpi)/86400d  ;Earth's rotation angular frequency
    re = constant('re')
    vcoro_gei = r_gei
    vcoro_gei[*,0] = -r_gei[*,1]*omega
    vcoro_gei[*,1] =  r_gei[*,0]*omega
    vcoro_gei[*,2] = 0.0
    vcoro_gei *= re
    vcoro_vec = cotran(vcoro_gei, times, 'gei2'+coord, probe=probe)
    ecoro_vec = -vec_cross(vcoro_vec, b_vec)*1e-3

    store_data, e_var, times, ecoro_vec
    add_setting, e_var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'Coro E', $
        'unit', 'mV/m', $
        'coord', strupcase(coord), $
        'coord_labels', limits.coord_labels )

end
