function calc_vcoro, r_var=r_var, probe=probe

    get_data, r_var, uts, r_vec, limits=limits
    coord = strlowcase(limits.coord)
    r_gei = cotran(r_vec, uts, coord+'2gei', probe=probe)

    omega = (2*!dpi)/86400d  ;Earth's rotation angular frequency
    re = constant('re')
    vcoro_gei = r_gei
    vcoro_gei[*,0] = -r_gei[*,1]*omega
    vcoro_gei[*,1] =  r_gei[*,0]*omega
    vcoro_gei[*,2] = 0.0
    vcoro_gei *= re
    vcoro_vec = cotran(vcoro_gei, uts, 'gei2'+coord, probe=probe)
    
    return, vcoro_vec
end