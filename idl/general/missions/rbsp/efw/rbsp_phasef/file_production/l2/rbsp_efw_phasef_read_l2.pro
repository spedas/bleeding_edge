;+
; Read EFW L2 data.
;
; datatype can be 'e-hires-uvw','e-spinfit-mgse','esvy_despun','fbk','spec','vsvy-hires'
;-
pro rbsp_efw_phasef_read_l2, time_range, probe=probe, datatype=datatype, level=level


    if size(time_range[0],/type) eq 7 then time_range = time_double(time_range)
    if n_elements(datatype) eq 0 then begin
        dprint, 'No datatype ...', verbose=vb
        return
    endif
    case datatype[0] of
        'e-hires-uvw': version = 'v02'
        'e-spinfit-mgse': version = 'v04'
        'esvy_despun': version = 'v03'
        'fbk': version = 'v02'
        'spec': version = 'v02'
        'vsvy-hires': version = 'v04'
        else: message, 'Invalid datatype ...'
    endcase


    rbspx = 'rbsp'+probe
    base = rbspx+'_efw-l2_'+datatype+'_YYYYMMDD_'+version+'.cdf'
    local_root = rbsp_efw_phasef_local_root()
    local_path = [local_root,rbspx,'l2',datatype+'_'+version,'YYYY',base]
    local_files = file_dailynames(file_format=join_path(local_path), trange=time_range)


    suffix = ''
    prefix = rbspx+'_efw_'
    cdf2tplot, file=local_files, all=0, prefix=prefix, suffix=suffix, verbose=vb, $
        tplotnames=tns, /convert_int1_to_int2, get_support_data=0

end


time_range = time_double(['2012-09','2019-11'])
probes = ['a','b']
foreach probe, probes do $
    rbsp_efw_phasef_read_l2, time_range, probe=probe, datatype='e-spinfit-mgse'
sgopen, 0, xsize=15, ysize=5
vars = 'rbsp'+probes+'_efw_efield_spinfit_mgse'
ylim, vars, -10, 10
options, vars, 'colors', constant('rgb')
tplot, vars, trange=time_range
end
