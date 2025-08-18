;+
; Read EFW L3 data.
;-

pro rbsp_efw_phasef_read_l3, time_range, probe=probe, version=version

    if n_elements(version) eq 0 then version = 'v04'
    if size(time_range[0],/type) eq 7 then time_range = time_double(time_range)

    rbspx = 'rbsp'+probe
    base = rbspx+'_efw-l3_YYYYMMDD_'+version+'.cdf'
    local_root = rbsp_efw_phasef_local_root()
    local_path = [local_root,rbspx,'l3','YYYY',base]
    local_files = file_dailynames(file_format=join_path(local_path), trange=time_range)

    suffix = ''
    prefix = rbspx+'_efw_'
    cdf2tplot, file=local_files, all=0, prefix=prefix, suffix=suffix, verbose=vb, $
        tplotnames=tns, /convert_int1_to_int2, get_support_data=0
end

time_range = time_double(['2012-09','2019-11'])
probes = ['a','b']
foreach probe, probes do $
    rbsp_efw_phasef_read_l3, time_range, probe=probe
sgopen, 0, xsize=15, ysize=5
vars = 'rbsp'+probes+'_efw_efield_in_corotation_frame_spinfit_mgse'
ylim, vars, -10, 10
options, vars, 'colors', constant('rgb')
tplot, vars, trange=time_range
end