;+
; Fix spin tone and other artificial signals in UVW2GSE.
; The assumption is that, attitude evovles slowly in time, except during eclipse and maneuver.
;
; time_range. The time range in sec.
; probe=.
; restore_eclipse=. Set to restore attitude during eclipse.
; restore_maneuver=. Set to restore attitude during maenuver.
;-

pro rbsp_fix_q_uvw2gse, time_range, probe=probe, test=test, $
    restore_eclipse=restore_eclipse, restore_maneuver=restore_maneuver

    prefix = 'rbsp'+probe+'_'
    q_var = prefix+'q_uvw2gse'
; To be stricter, do not auto load quaternion.
;    if check_if_update(q_var, time_range) then rbsp_read_quaternion, time_range, probe=probe


;---Read matrix.
    q_uvw2gse = get_var_data(q_var, times=common_times)
    ncommon_time = n_elements(common_times)
    common_time_step = total(common_times[0:1]*[-1,1])

    m_uvw2gse = qtom(q_uvw2gse)
    ndim = 3
    uvw = constant('uvw')
    xyz = constant('xyz')
    for ii=0,ndim-1 do begin
        vec_gse = reform(m_uvw2gse[*,*,ii])
        vec_var = prefix+'r'+uvw[ii]+'_gse'
        store_data, vec_var, common_times, vec_gse
        add_setting, vec_var, /smart, dictionary($
            'display_type', 'vector', $
            'short_name', strupcase(uvw[ii]), $
            'unit', '#', $
            'coord', 'GSE', $
            'coord_labels', xyz )
        if keyword_set(test) then begin
            for jj=0,ndim-1 do begin
                store_data, prefix+uvw[ii]+xyz[jj]+'_gse', common_times, vec_gse[*,jj]
            endfor
        endif
    endfor


;---Convert to DSC.
    rad = constant('rad')
    spin_phase_var = prefix+'spin_phase'
    rbsp_read_spin_phase, time_range, probe=probe, times=common_times
    spin_phase = get_var_data(spin_phase_var)*rad
    cost = cos(spin_phase)
    sint = sin(spin_phase)
    u_gse = get_var_data(prefix+'ru_gse')
    v_gse = get_var_data(prefix+'rv_gse')
    w_gse = get_var_data(prefix+'rw_gse')
    vec = dblarr(ncommon_time,ndim)
    foreach component, xyz do begin
        vec_var = prefix+component+'_dsc'
        case component of
            'x': for ii=0,ndim-1 do vec[*,ii] = u_gse[*,ii]*cost-v_gse[*,ii]*sint
            'y': for ii=0,ndim-1 do vec[*,ii] = u_gse[*,ii]*sint+v_gse[*,ii]*cost
            'z': vec = w_gse
        endcase
        store_data, vec_var, common_times, vec
        add_setting, vec_var, /smart, dictionary($
            'display_type', 'vector', $
            'short_name', strupcase(component), $
            'unit', '#', $
            'coord', 'DSC', $
            'coord_labels', xyz )
    endforeach


;---Load attitude changes: eclipse and maneuver.
    rbsp_read_eclipse_flag, time_range, probe=probe
    flags = get_var_data(prefix+'eclipse_flag', times=flag_times)
    flag_time_step = total(flag_times[0:1]*[-1,1])
    nflag_time = n_elements(flag_times)
    index = where(flags eq 1, count)
    eclipse_time_ranges = (count eq 0)? !null: $
        time_to_range(flag_times[index], time_step=flag_time_step)
    neclipse = n_elements(eclipse_time_ranges)*0.5
    flags = intarr(nflag_time)
    for ii=0,neclipse-1 do begin    ; eclipse time tend to be off?
        index = lazy_where(flag_times, '[]', eclipse_time_ranges[ii,*]+[-10,5]*flag_time_step, count=count)
        if count eq 0 then continue
        flags[index] = 1
    endfor
    store_data, prefix+'eclipse_flag', flag_times, flags

    ; Maneuver.
    maneuver_time_ranges = rbsp_read_maneuver_time(time_range, probe=probe)
    nmaneuver = n_elements(maneuver_time_ranges)*0.5
    flags = intarr(nflag_time)
    for ii=0,nmaneuver-1 do begin   ; pad a little to ensure exclusion.
        index = lazy_where(flag_times, '[]', maneuver_time_ranges[ii,*]+[-2,2]*flag_time_step, count=count)
        if count eq 0 then continue
        flags[index] = 1
    endfor
    store_data, prefix+'maneuver_flag', flag_times, flags

    ; Overall, update to high res.
    flags = get_var_data(prefix+'eclipse_flag'); or get_var_data(prefix+'maneuver_flag')
    index = where(flags eq 1, count)
    attitude_time_ranges = (count eq 0)? !null: time_to_range(flag_times[index], time_step=flag_time_step);, pad_time=2*flag_time_step)
    nattitude_time_range = n_elements(attitude_time_ranges)*0.5
    flags = intarr(ncommon_time)
    for ii=0,nattitude_time_range-1 do flags[lazy_where(common_times,'[]',attitude_time_ranges[ii,*])] = 1
    attitude_index = where(flags eq 1, attitude_count)
    store_data, prefix+'attitude_flag', common_times, flags
    options, prefix+'*_flag', 'yrange', [-0.2,1.2]



;---Correct in DSC.
    ; 1. Fix [x,z]_dsc: a) get a smooth version; b) unit vector.
    ; 2. Calc y and then fix x.
    section_window = 3600.    ; sec.
    maneuver_section_window = 300.   ; 5 min.
    section_times = make_bins(time_range, section_window)
    nsection = n_elements(section_times)-1
    two_colors = sgcolor(['blue','red'])
    fillval = !values.f_nan
    foreach component, ['x','z'] do begin
        ; Fix 3-components.
        foreach var, prefix+component+'_dsc' do begin
            ; Get the basic low-res sampling.
            vec = get_var_data(var)
            if keyword_set(test) then begin
                for ii=0,ndim-1 do begin
                    suffix = '_'+xyz[ii]
                    store_data, prefix+'vec'+suffix, common_times, vec[*,ii]
                    store_data, prefix+'dvec'+suffix, common_times, smooth(deriv(vec[*,ii]),11/common_time_step,/nan)
                endfor
            endif
            ; Remove attitude changes.
            if attitude_count ne 0 then vec[attitude_index,*] = fillval
            vec_interp = dblarr(nsection,ndim)+fillval
            interp_times = section_times[0:nsection-1]+0.5*section_window
            for jj=0,ndim-1 do begin
                for ii=0,nsection-1 do begin
                    index = lazy_where(common_times, '[]', section_times[ii:ii+1], count=count)
                    vec_interp[ii,jj] = median(vec[index,jj])
                endfor
            endfor

            ; Add maneuver back.
            vec = get_var_data(var)
            for maneuver_id=0, nmaneuver-1 do begin
                maneuver_time_range = reform(maneuver_time_ranges[maneuver_id,*])
                index = lazy_where(interp_times, '[]', maneuver_time_range, count=count)
                if count eq 0 then continue
                vec_interp[index,*] = fillval

                vec_maneuver_edge = dblarr(2,ndim)
                for ii=0,1 do begin
                    dtime = (ii eq 0)? [-1,0]: [0,1]
                    the_time_range = maneuver_time_range[ii]+dtime*section_window
                    index = lazy_where(common_times, '[]', the_time_range, count=count)
                    if count eq 0 then continue
                    for jj=0,ndim-1 do vec_maneuver_edge[ii,jj] = median(vec[index,jj])
                endfor

                maneuver_section_times = make_bins(maneuver_time_range,maneuver_section_window, /inner)
                nmaneuver_section = n_elements(maneuver_section_times)-1
                if nmaneuver_section gt 0 then begin
                    maneuver_interp_times = maneuver_section_times[0:nmaneuver_section-1]+maneuver_section_window*0.5
                    vec_maneuver = dblarr(nmaneuver_section,ndim)+fillval
                    for jj=0,ndim-1 do begin
                        for ii=0,nmaneuver_section-1 do begin
                            index = lazy_where(common_times,'[]',maneuver_section_times[ii:ii+1], count=count)
                            if count eq 0 then continue
                            vec_maneuver[ii,jj] = median(vec[index,jj])
                        endfor
                    endfor
                endif else begin
                    maneuver_interp_times = !null
                    vec_maneuver = !null
                endelse
                

                interp_times = [interp_times,maneuver_time_range,maneuver_interp_times]
                vec_interp = [vec_interp,vec_maneuver_edge,vec_maneuver]
                index = sort(interp_times)
                interp_times = interp_times[index]
                vec_interp = vec_interp[index,*]
            endfor

            vec_fix = sinterpol(vec_interp, interp_times, common_times)
            vec_var = var+'_fix'
            store_data, vec_var, common_times, vec_fix
            if keyword_set(test) then begin
                for ii=0,ndim-1 do begin
                    suffix = '_'+xyz[ii]
                    the_var = vec_var+suffix
                    store_data, the_var, common_times, $
                        [[vec[*,ii]],[vec_fix[*,ii]]], $
                        limits={colors:two_colors, labels:['orig','fix']}
                endfor
            endif
        endforeach
    endforeach


    ; Orthogonality.
    x_dsc = get_var_data(prefix+'x_dsc_fix')
    z_dsc = get_var_data(prefix+'z_dsc_fix')
    y_dsc = vec_cross(z_dsc, x_dsc)
    y_dsc = sunitvec(y_dsc)
    z_dsc = sunitvec(z_dsc)
    x_dsc = vec_cross(y_dsc, z_dsc)
    foreach component, xyz do begin
        vec_var = prefix+component+'_dsc_fix'
        case component of
            'x': vec = x_dsc
            'y': vec = y_dsc
            'z': vec = z_dsc
        endcase
        store_data, vec_var, common_times, vec
        add_setting, vec_var, /smart, dictionary($
            'display_type', 'vector', $
            'short_name', strupcase(component), $
            'unit', '#', $
            'coord', 'GSE', $
            'coord_labels', xyz )
    endforeach

;---Change back to UVW.
    vec = dblarr(ncommon_time,ndim)
    foreach component, uvw do begin
        vec_var = prefix+component+'_gse_fix'
        case component of
            'u': for ii=0,ndim-1 do vec[*,ii] = x_dsc[*,ii]*cost+y_dsc[*,ii]*sint
            'v': for ii=0,ndim-1 do vec[*,ii] =-x_dsc[*,ii]*sint+y_dsc[*,ii]*cost
            'w': vec = z_dsc
        endcase
        store_data, vec_var, common_times, vec
        add_setting, vec_var, /smart, dictionary($
            'display_type', 'vector', $
            'short_name', strupcase(component), $
            'unit', '#', $
            'coord', 'UVW', $
            'coord_labels', uvw )
    endforeach


;---Get m and q.
    m_uvw2gse = dblarr(ncommon_time,ndim,ndim)
    for ii=0,ndim-1 do m_uvw2gse[*,*,ii] = get_var_data(prefix+uvw[ii]+'_gse_fix')
    q_uvw2gse = mtoq(m_uvw2gse)
    store_data, prefix+'q_uvw2gse', common_times, q_uvw2gse, limits={spin_tone:'fixed'}


    two_colors = sgcolor(['blue','red'])
    if keyword_set(test) then begin
        for ii=0,ndim-1 do begin
            vec_gse = reform(m_uvw2gse[*,*,ii])
            for jj=0,ndim-1 do begin
                the_var = prefix+uvw[ii]+xyz[jj]+'_gse'
                vec_old = get_var_data(the_var)
                store_data, the_var, common_times, [[vec_old],[vec_gse[*,jj]]], $
                    limits={colors:two_colors, labels:['orig','fixed']}
            endfor
        endfor
    endif

end



time_range = time_double(['2013-01-01','2013-01-02'])
time_range = time_double(['2014-06-14','2014-06-15'])
;time_range = time_double(['2014-06-15','2014-06-16'])
time_range = time_double(['2014-06-14','2014-06-19'])   ; eclipse.
probe = 'b'


time_range = time_double(['2013-03-20','2013-03-21'])   ; maneuver.
probe = 'a'

time_range = time_double(['2014-08-28','2014-08-29'])   ; maneuver.
time_range = time_double(['2018-09-27','2018-09-28'])   ; E/B MGSE weird.
probe = 'b'

prefix = 'rbsp'+probe+'_'
rbsp_read_quaternion, time_range, probe=probe
rbsp_fix_q_uvw2gse, time_range, probe=probe, test=1;, restore_eclipse=1, restore_maneuver=1
end
