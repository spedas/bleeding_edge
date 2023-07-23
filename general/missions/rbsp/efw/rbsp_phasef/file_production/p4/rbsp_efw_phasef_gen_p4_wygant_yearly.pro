;+
; Generate yearly files for Wygant.
;-


pro rbsp_efw_phasef_gen_p4_wygant_yearly, year, probe=probe, filename=file

    on_error, 0
    errmsg = ''

    msg = 'Processing '+file+' ...'
    lprmsg, msg, log_file


;---Check input.
    if n_elements(file) eq 0 then begin
        errmsg = 'cdf file is not set ...'
        lprmsg, errmsg, log_file
        return
    endif

    if n_elements(probe) eq 0 then begin
        errmsg = 'No input probe ...'
        lprmsg, errmsg, log_file
        return
    endif
    if probe ne 'a' and probe ne 'b' then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        lprmsg, errmsg, log_file
        return
    endif
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe


    if size(year,/type) eq 7 then year = fix(year)
    str_year = string(year,format='(I4)')
    if product(year-[2012,2019]) gt 0 then begin
        errmsg = 'Invalid year ...'
        lprmsg, errmsg, log_file
        return
    endif


;;---Prepare skeleton.
;    skeleton_base = prefix+'efw-p4_00000000_v04.cdf'
;    skeleton = join_path([srootdir(),skeleton_base])
;    if file_test(skeleton) eq 0 then begin
;        errmsg = 'Skeleton file is not found ...'
;        lprmsg, errmsg, log_file
;        return
;    endif
;    path = file_dirname(file)
;    if file_test(path,/directory) eq 0 then file_mkdir, path
;    file_copy, skeleton, file, overwrite=1


;---Settings.
    time_range = time_double(string(year+[0,1],format='(I4)'))


;;---Fix labeling.
;    foreach var, cdf_vars(file) do begin
;        labeling = phasef_get_labeling(var)
;        if n_elements(labeling) eq 0 then continue
;        cdf_save_setting, labeling, varname=var, filename=file
;
;        ; Check labels if needed.
;        the_key = 'labels'
;        if labeling.haskey(the_key) then begin
;            vatts = cdf_read_setting(var, filename=file)
;            label_var = vatts['LABL_PTR_1']
;            if cdf_has_var(label_var, filename=file) then begin
;                label_vatts = cdf_read_setting(label_var, filename=file)
;            endif else label_vatts = dictionary()
;            cdf_save_var, label_var, filename=file, $
;                value=transpose(labeling[the_key])
;            if n_elements(label_vatts) ne 0 then begin
;                cdf_save_setting, label_vatts, filename=file, varname=label_var
;            endif
;        endif
;    endforeach


;---Load L3 and L4 data.
;    time_range = time_double(['2012-10-01','2012-10-03'])
    rbsp_efw_read_l3, time_range, probe=probe
    rbsp_efw_read_p4, time_range, probe=probe
    rbsp_read_e_model, time_range, probe=probe, id='e_model_related'

    bp = rbsp_efw_phasef_get_boom_pair(time_range[0], probe=probe)
    
    model_suf = '_'+['t89','igrf']
    vars = prefix+['efw_'+['spacecraft_potential', 'density', 'flags_all', $
        'bfield_minus_model_mgse'+model_suf, 'bfield_magnitude_minus_model_magnitude'+model_suf, $
        'bfield_mgse', 'lshell', 'mlt', 'mlat', 'position_gse', 'velocity_gse', 'spinaxis_gse', $
        'efield_in_corotation_frame_spinfit_mgse_'+bp, $
        'orbit_num'], $
        ['evxb_mgse', 'ecoro_mgse'] ]
    foreach var, vars do if tnames(var) eq '' then print, var
    
    get_data, prefix+'efw_density', common_times
    ntime = n_elements(common_times)
    foreach var, vars do begin
        get_data, var, times, data
        if n_elements(times) ne ntime then begin
            data = sinterpol(data, times, common_times)
            store_data, var, times, data
        endif
    endforeach
    
    stplot2cdf, vars, time_var='epoch', istp=1, filename=file

end


probes = ['b','a']
years = ['2017']
root_dir = rbsp_efw_phasef_local_root()
foreach probe, probes do begin
    rbspx = 'rbsp'+probe
    foreach year, years do begin
        base = rbspx+'_efw-wygant_yearly_'+year+'.cdf'
        file = join_path([root_dir,rbspx,'wygant_yearly',base])
        rbsp_efw_phasef_gen_p4_wygant_yearly, year, probe=probe, filename=file
    endforeach
endforeach

stop

date = '2017'
probe = ['b','a']
file = join_path([homedir(),'test_year.cdf'])
if file_test(file) eq 1 then file_delete, file
foreach probe, probes do $
    rbsp_efw_phasef_gen_p4_wygant_yearly, date, probe=probe, filename=file
end
