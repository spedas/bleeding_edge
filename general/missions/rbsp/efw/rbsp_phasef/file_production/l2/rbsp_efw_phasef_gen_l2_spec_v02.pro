;+
; Generate L2 spec v02 cdfs.
;   v01 files are not in the same format. v02 cdfs will be in the same format.
; Needs to save v01 files in a folder spec_v01, which is two levels up the file hierachy from the v02 file.
;-

pro rbsp_efw_phasef_gen_l2_spec_v02_skeleton, file

    if file_test(file) eq 0 then return

    base = file_basename(file)
    if strmid(base,0,4) ne 'rbsp' then return

    probe = strmid(base,4,1)
    rbspx = 'rbsp'+probe
    prefix = 'rbsp'+probe+'_'

    gatts = dictionary( $
        'HTTP_LINK', 'http://rbsp.space.umn.edu http://athena.jhuapl.edu', $
        'LINK_TITLE', 'Daily Summary Plots and additional data', $
        'Data_version', 'v02', $
        'Generation_date', time_string(systime(1),tformat='YYYY:MM:DDThh:mm:ss'), $
        'Logical_source', prefix+'efw-l2_spec', $
        'Logical_file_id', strmid(base,0,strlen(base)-4), $
        'MODS', '', $
        'LINK_TEXT', 'EFW home page at Minnesota with Van Allen Probes', $
        'Acknowledgement', "This work was supported by Van Allen Probes (RBSP) EFW funding provided by JHU/APL Contract No. 922613 under NASA's Prime Contract No. NNN06AA01C; EFW PI, J. R. Wygant, UMN.", $
        'Project', 'RBSP>Radiation Belt Storm Probes' )

    foreach key, gatts.keys() do begin
        cdf_save_setting, key, gatts[key], filename=file
    endforeach

    keys = ['Inst_mod','Inst_settings','Caveats','Validity','Validator','Parents','Software_version']
    foreach key, keys do cdf_del_setting, key, filename=file

    vars = ['epoch','epoch_qual']
    var_notes = 'Epoch tagged at the center of each interval, resolution is '+['4','10']+' sec'
    foreach var, vars, var_id do begin
        cdf_save_setting, 'VAR_NOTES', var_notes[var_id], filename=file, varname=var
        cdf_save_setting, 'UNITS', 'ps (pico-second)', filename=file, varname=var
    endforeach


end

pro rbsp_efw_phasef_gen_l2_spec_v02_per_day, date, probe=probe, filename=file, log_file=log_file

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

    data_type = 'spec'
    valid_range = rbsp_efw_phasef_get_valid_range(data_type, probe=probe)
    if n_elements(date) eq 0 then begin
        errmsg = 'No input date ...'
        lprmsg, errmsg, log_file
        return
    endif
    if size(date,/type) eq 7 then date = time_double(date)
    if product(date-valid_range) gt 0 then begin
        errmsg = 'Input date: '+time_string(date,tformat='YYYY-MM-DD')+' is out of valid range ...'
        lprmsg, errmsg, log_file
        return
    endif

;---Load data.
    str_year = time_string(date,tformat='YYYY')
    l1_path = join_path([sparentdir(file,level=3),'spec_v01',str_year])
    l1_file = join_path([l1_path,prefix+'efw-l2_spec_'+time_string(date,tformat='YYYYMMDD')+'_v01.cdf'])
    if file_test(l1_file) eq 0 then begin
        lprmsg, 'L1 file does not exist ...', log_file
        return
    endif


;---Copy v01 file to v02.
    path = file_dirname(file)
    if file_test(path) eq 0 then file_mkdir, path
    file_copy, l1_file, file, /overwrite


;---Use the phase F flags.
    rbsp_efw_phasef_read_efw_qual, date, probe=probe, errmsg=errmsg, log_file=log_file
    var = 'efw_qual'
    var_setting = cdf_read_setting(var, filename=file)
    time_var = var_setting['DEPEND_0']
    time_var_setting = cdf_read_setting(time_var, filename=file)
    secofday = constant('secofday')
    get_data, prefix+var, times, flags
    epochs = convert_time(times, from='unix', to='epoch16')
    cdf_del_var, time_var, filename=file
    cdf_save_var, time_var, value=epochs, filename=file
    cdf_save_setting, time_var_setting, filename=file, varname=time_var
    cdf_del_var, var, filename=file
    cdf_save_var, var, value=flags, filename=file
    cdf_save_setting, var_setting, filename=file, varname=var
    rbsp_efw_phasef_save_efw_qual_to_file, date, probe=probe, filename=file


;---Remove dummy variables.
    cdf_del_unused_vars, file


;---Fix labeling for spec??_scm??.
    unit = 'nT^2/Hz'
    all_vars = cdf_vars(file)
    foreach var, all_vars do begin
        if (strpos(var, 'scm'))[0] ne -1 then begin
            cdf_save_setting, 'UNITS', unit, filename=file, varname=var
        endif
    endforeach


;---Fix time tag offset.
    time_tag_offset = -4d
    time_var = 'epoch'
    epoch = cdf_read_var(time_var, filename=file)
    times = convert_time(epoch, from='epoch16', to='unix')+time_tag_offset
    epoch = convert_time(times, from='unix', to='epoch16')
    cdf_save_data, time_var, value=epoch, filename=file


;---ISTP format.
    rbsp_efw_phasef_gen_l2_spec_v02_skeleton, file

end

stop
probes = ['a','b']
root_dir = join_path([rbsp_efw_phasef_local_root()])
secofday = constant('secofday')
foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe
    time_range = rbsp_efw_phasef_get_valid_range('spec', probe=probe)
    days = make_bins(time_range+[0,-1]*secofday, secofday)
    foreach day, days do begin
        str_year = time_string(day,tformat='YYYY')
        path = join_path([root_dir,rbspx,'l2','spec_v02',str_year])
        base = prefix+'efw-l2_spec_'+time_string(day,tformat='YYYYMMDD')+'_v02.cdf'
        file = join_path([path,base])
        ;if file_test(file) eq 1 then continue
        print, file
        rbsp_efw_phasef_gen_l2_spec_v02_skeleton, file
    endforeach
endforeach
stop


stop
probes = ['a','b']
root_dir = join_path([rbsp_efw_phasef_local_root()])
secofday = constant('secofday')
foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe
    time_range = rbsp_efw_phasef_get_valid_range('spec', probe=probe)
    days = make_bins(time_range+[0,-1]*secofday, secofday)
    foreach day, days do begin
        str_year = time_string(day,tformat='YYYY')
        path = join_path([root_dir,rbspx,'l2','spec_v02',str_year])
        base = prefix+'efw-l2_spec_'+time_string(day,tformat='YYYYMMDD')+'_v02.cdf'
        file = join_path([path,base])
;if file_test(file) eq 1 then continue
        print, file
        rbsp_efw_phasef_gen_l2_spec_v02_per_day, day, probe=probe, filename=file
    endforeach
endforeach
stop

date = time_double('2015-05-28')
probe = 'b'
file = join_path([homedir(),'test_level2_spec.cdf'])
rbsp_efw_phasef_gen_l2_spec_v02_per_day, date, probe=probe, file=file
end
