;+
; Read EFW L3 data.
;-

pro rbsp_efw_read_l3, tr, probe=probe, datatype=datatype, trange=trange, $
    level=level, verbose=verbose, downloadonly=downloadonly, $
     cdf_data=cdf_data,get_support_data=get_support_data, $
     tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $
     varformat=varformat, valid_names = valid_names, files=files, $
     type=type, _extra = _extra

    rbsp_efw_init
    vb = keyword_set(verbose) ? verbose : 0
    vb = vb > !rbsp_efw.verbose

    if n_elements(probe) eq 0 then probe = 'a'
    if n_elements(version) eq 0 then version = 'v04'
    if n_elements(trange) ne 0 then time_range = trange
    if n_elements(tr) ne 0 then time_range = tr
    if n_elements(time_range) eq 0 then time_range = timerange()
    if size(time_range[0],/type) eq 7 then time_range = time_double(time_range)


    rbspx = 'rbsp'+probe
    base = rbspx+'_efw-l3_YYYYMMDD_'+version+'.cdf'
    local_root = !rbsp_efw.local_data_dir
    local_path = [local_root,rbspx,'l3','efw','YYYY',base]
    remote_root = rbsp_efw_remote_root()
    remote_path = [remote_root,rbspx,'l3','efw','YYYY',base]
    local_files = file_dailynames(file_format=join_path(local_path), trange=time_range)
    remote_files = file_dailynames(file_format=join_path(remote_path), trange=time_range)


    local_files = rbsp_efw_read_xxx_download_files(local_files, remote_files)
    nfile = n_elements(local_files)
    if nfile eq 0 then return


    suffix = ''
    prefix = rbspx+'_efw_'
    cdf2tplot, file=local_files, all=0, prefix=prefix, suffix=suffix, verbose=vb, $
        tplotnames=tns, convert_int1_to_int2=1, get_support_data=0, load_labels=1

end



; Set the time and probe for loading data.
time_range = ['2013-01-01','2013-01-03']
probe = 'a'

; Load the spinfit data.
rbsp_efw_read_l3, time_range, probe=probe

prefix = 'rbsp'+probe+'_efw_'
vars = prefix+[$

    ; The spinfit E field with E_spinaxis = 0.
    'efield_in_corotation_frame_spinfit_mgse', $

    ; The spinfit E field with E_spinaxis calculated from E dot B = 0,
    ; when B is away from the spin plane by >15 deg.
    'efield_in_corotation_frame_spinfit_edotb_mgse', $

    ; The spacecraft potential.
    'spacecraft_potential', $

    ; The EFW density calibrated according to the upper-hybrid line.
    'density', $

    ; The ephemeris data.
    'position_gse', 'velocity_gse', 'mlt', 'mlat', 'lshell', 'orbit_num' ]

; Plot the variables.
tplot_options, 'labflag', -1
tplot, vars, trange=time_range
end
