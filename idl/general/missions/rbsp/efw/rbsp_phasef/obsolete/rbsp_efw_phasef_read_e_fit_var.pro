;+
; Read vars to calculate e_fit.
;
; time.
; time. The time range in unix time.
; probe=. 'a' or 'b'.
; local_root=. The local root directory for saving rbsp data.
; remote_root=. The URL for grabing rbsp data.
; version=. 'v??'.
;-

pro rbsp_efw_phasef_read_e_fit_var, time, probe=probe, version=version, $
    local_root=local_root, remote_root=remote_root

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 0
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([rbsp_efw_phasef_local_root()])
    if n_elements(remote_root) eq 0 then remote_root = join_path([rbsp_efw_phasef_get_server()])
    if n_elements(version) eq 0 then version = 'v02'

;---Init settings.
    valid_range = time_double(['2012','2020'])
    rbspx = 'rbsp'+probe
    base_name = rbspx+'_efw_e_fit_var_%Y_'+version+'.cdf'
    local_path = [local_root,'efw_phasef','e_fit_var_'+version,rbspx]
    remote_path = [remote_root,'efw_phasef','e_fit_var_'+version,rbspx]

    request = dictionary($
        'pattern', dictionary($
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,'']), $
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file()])), $
        'valid_range', time_double(valid_range), $
        'cadence', 'year', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', rbspx+'_'+[['b','e','emod','v','r','omega','ex_dotb']+'_mgse','flag_25'], $
                'time_var_name', 'epoch', $
                'time_var_type', 'epoch')))

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time, nonexist_files=nonexist_files)
    if n_elements(nonexist_files) ne 0 then begin
        foreach file, request.nonexist_files do begin
            file_time = file.file_time
            local_file = file.local_file
            year = fix(time_string(file_time,tformat='YYYY'))
            tr = time_double(string(year+[0,1],format='(I04)'))
            rbsp_efw_phasef_read_e_fit_var_gen_file, tr, probe=probe, filename=local_file
        endforeach
        files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
            file_times=file_times, time=time, nonexist_files=nonexist_files)
    endif


;---Read data from files and save to memory.
    read_files, time, files=files, request=request



;---Adjust the variables.
    prefix = 'rbsp'+probe+'_'

    ; Trim data.
    valid_tr = rbsp_efw_phasef_get_valid_range('e_spinfit', probe=probe)
    vars = prefix+[['b','e','v','r','omega','ex_dotb']+'_mgse','flag_25']
    get_data, vars[0], times
    index = lazy_where(times, ')(', valid_tr, count=count)
    if count ne 0 then begin
        index = lazy_where(times, '[]', valid_tr)
        foreach var, vars do begin
            get_data, var, times, data
            store_data, var, times[index], data[index,*]
        endforeach
    endif

    ; Calc vcoro_mgse and emod_mgse.
    get_data, prefix+'r_mgse', times, r_mgse
    get_data, prefix+'omega_mgse', times, omega_mgse
    vcoro_mgse = vec_cross(omega_mgse,r_mgse)*constant('re')
    var = prefix+'vcoro_mgse'
    store_data, var, times, vcoro_mgse
    add_setting, var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'km/s', $
        'short_name', 'Coro V', $
        'coord', 'MGSE', $
        'coord_labels', constant('xyz') )

    get_data, prefix+'b_mgse', times, b_mgse
    get_data, prefix+'v_mgse', times, v_mgse
    u_mgse = v_mgse-vcoro_mgse
    emod_mgse = vec_cross(u_mgse, b_mgse)*1e-3
    var = prefix+'emod_mgse'
    store_data, var, times, emod_mgse
    add_setting, var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'Model E', $
        'coord', 'MGSE', $
        'coord_labels', constant('xyz') )


    get_data, prefix+'e_mgse', times, e_mgse, limits=lim
    get_data, prefix+'ex_dotb_mgse', times, ex
    e_mgse[*,0] = ex
    store_data, prefix+'edotb_mgse', times, e_mgse, limits=lim

    dis = snorm(get_var_data(prefix+'r_mgse'))
    var = prefix+'dis'
    store_data, var, times, dis
    add_setting, var, /smart, dictionary($
        'display_type', 'scalar', $
        'unit', 'Re', $
        'short_name', '|R|' )

    flags = get_var_data(prefix+'flag_25')
    flags = flags[*,0]
    min_dis = 2.5
    nan_index = where(flags eq 1 or dis gt min_dis)
    fillval = !values.f_nan
    vars = prefix+['e','edotb']+'_mgse'
    foreach var, vars do begin
        get_data, var, times, data
        data[nan_index,*] = fillval
        store_data, var, times, data
    endforeach


end

time_range = time_double(['2012-09','2019-09'])
probes = ['a','b']
foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'

    rbsp_efw_phasef_read_e_fit_var, time_range, probe=probe

    e_mgse = get_var_data(prefix+'edotb_mgse', limits=lim)
    emod_mgse = get_var_data(prefix+'emod_mgse', times=times)
    store_data, prefix+'e_emod_angle', times, sang(e_mgse,emod_mgse,/deg)

    var = prefix+'e1_mgse'
    dif_data, prefix+'e_mgse', prefix+'emod_mgse', newname=var
    get_data, var, times, e1_mgse
    e1_mgse[*,0] = 0
    store_data, var, times, e1_mgse, limits=lim
    xyz = constant('xyz')
    vars = var+'_'+xyz
    stplot_split, var, newnames=vars
    ylim, vars[1:2], [-1,1]*6
    options, vars, 'ytitle', 'RBSP-'+strupcase(probe)+'!C(mV/m)'
endforeach

stop

sgopen, 0, xsize=10, ysize=5
poss = sgcalcpos(1,2)
e_mag = snorm(e_mgse)
emod_mag = snorm(emod_mgse)
index = where(finite(e_mag) and finite(emod_mag))

tpos = poss[*,0]
plot, e_mgse[*,1], emod_mgse[*,1], psym=3, /iso, position=tpos, noerase=1
oplot, [-1,1]*400,[-1,1]*400, linestyle=0, color=sgcolor('red')
resy = linfit(e_mgse[index,1], emod_mgse[index,1])
print, resy

tpos = poss[*,1]
plot, e_mgse[*,2], emod_mgse[*,2], psym=3, /iso, position=tpos, noerase=1
oplot, [-1,1]*400,[-1,1]*400, linestyle=0, color=sgcolor('red')
resz = linfit(e_mgse[index,2], emod_mgse[index,2])
print, resz

end
