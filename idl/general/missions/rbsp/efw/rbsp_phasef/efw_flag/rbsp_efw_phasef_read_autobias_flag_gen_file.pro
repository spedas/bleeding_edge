;+
; Generate daily flag for autobias.
;
; AutoBias starts actively controlling the bias currents at V12 = -1.0 V,
; ramping down the magnitude of the bias current so that when V12 = 0.0 V,
; the bias current is very near to zero after starting out around -20
; nA/sensor.
;
; For V12 > 0.0 V, the bias current continues to increase (become more
; positive), although at a slower rate, 0.2 nA/V or something like that.
;
; Auto Bias flag values. From 'rbsp?_efw_hsk_idpu_fast_TBD'
; Bit   Value   Meaning
; 3     8       Toggles off and on every other cycle when AutoBias is active.
; 2     4       One when AutoBias is controlling the bias, Zero when AutoBias is not controlling the bias.
; 1     2       One when BIAS3 and BIAS4 can be controlled by AUtoBias, zero otherwise.
; 0     1       One when BIAS1 and BIAS2 can be controlled by AUtoBias,	zero otherwise.
;-

pro rbsp_load_efw_hsk_idpu_fast, probe=probe, trange=trange

    rbsp_efw_init
    if (keyword_set(probe)) then p_var = strlowcase(probe)

    rbspx = 'rbsp'+probe
    rbsppref = rbspx + '/l1'

    ;---------------------------------------------------------------
    ;Find out what IDPU fast files are online
    format = rbsppref + '/hsk_idpu_fast/YYYY/'+rbspx+'_l1_hsk_idpu_fast_YYYYMMDD_v*.cdf'
    relpathnames = file_dailynames(file_format=format,trange=trange,addmaster=addmaster)

    ;...and load them
    file_loaded = []
    for ff=0, n_elements(relpathnames)-1 do begin
        undefine,lf
        localpath = file_dirname(relpathnames[ff])+'/'
        locpath = !rbsp_efw.local_data_dir+localpath
        remfile = !rbsp_efw.remote_data_dir+relpathnames[ff]
        tmp = spd_download(remote_file=remfile, local_path=locpath, local_file=lf,/last_version)
        locfile = locpath+lf
        if file_test(locfile) eq 0 then locfile = file_search(locfile)
        if locfile[0] ne '' then file_loaded = [file_loaded,locfile]
    endfor

    suf=''
    prefix=rbspx+'_efw_hsk_idpu_fast_'
    cdf2tplot,file=file_loaded,varformat=varformat,all=0,prefix=prefix,suffix=suf,verbose=vb, $
         tplotnames=tns,/convert_int1_to_int2,get_support_data=1 ; load data into tplot variables
end

pro rbsp_efw_phasef_read_autobias_flag_gen_file, date, probe=probe, filename=data_file

    if n_elements(date) eq 0 then message, 'No date ...'
    if n_elements(probe) eq 0 then message, 'No probe ...'
    if n_elements(data_file) eq 0 then message, 'No data_file ...'

    ;if file_test(data_file) eq 1 then return    ; Avoid reload.
    secofday = 86400.
    date = date-(date mod secofday) ; make sure this is the start of the day.
    date = date[0]
    time_range = date+[0.,secofday]
    rbsp_load_efw_hsk_idpu_fast, probe=probe, trange=time_range

    ; Find times when auto biasing is active.
    prefix = 'rbsp'+probe+'_'
    tbd_var = prefix+'efw_hsk_idpu_fast_TBD'
    get_data, tbd_var, times, tbd
    ntime = n_elements(times)
    ab_flag = intarr(ntime)


    ; Possible flag values for on and off
    ab_off = [1,2,3,8,10,11]
    ab_on = [4,5,6,7,12,13,14,15]
    foreach ab_val, ab_on do begin
        index = where(tbd eq ab_val, count)
        if count eq 0 then continue
        ab_flag[index] = 1
    endforeach

    common_time_step = 60.
    common_times = make_bins(time_range,common_time_step)
    ab_flag = ceil(interpol(ab_flag, times, common_times))
    ab_var = prefix+'ab_flag'
    store_data, ab_var, common_times, ab_flag, limits={yrange:[-0.2,1.2], ystyle:1}

    ;vars = prefix+['efw_hsk_idpu_fast_TBD','ab_flag']
    ;tplot, vars, trange=time_range


;---Save to cdf.
    print, 'Save data to '+data_file+' ...'
    data_dir = file_dirname(data_file)
    if file_test(data_dir) eq 0 then file_mkdir, data_dir
    if file_test(data_file) eq 1 then file_delete, data_file
    cdf_id = cdf_create(data_file)

    ; Time.
    time_var = 'time'
    data = stoepoch(common_times, 'unix')
    settings = dictionary($
        'FIELDNAM', 'epoch', $
        'VAR_TYPE', 'support_data', $
        'UNITS', 'sec' )
    cdf_save_var, time_var, value=data, filename=cdf_id, cdf_type='CDF_EPOCH'
    cdf_save_setting, varname=time_var, filename=cdf_id, settings

    ; AB flag.
    varname = ab_var
    data = fix(ab_flag)
    settings = dictionary($
        'DEPEND_0', time_var, $
        'FIELDNAM', 'autobias flag', $
        'VAR_TYPE', 'data', $
        'LABLAXIS', 'AB flag', $
        'UNITS', '#')
    cdf_save_var, varname, value=data, filename=cdf_id
    cdf_save_setting, varname=varname, filename=cdf_id, settings


    ; TBD.
    get_data, tbd_var, times, tbd

    ; Time.
    time_var = 'time_tbd'
    data = stoepoch(times, 'unix')
    settings = dictionary($
        'FIELDNAM', 'epoch', $
        'VAR_TYPE', 'support_data', $
        'UNITS', 'sec' )
    cdf_save_var, time_var, value=data, filename=cdf_id, cdf_type='CDF_EPOCH'
    cdf_save_setting, varname=time_var, filename=cdf_id, settings

    varname = tbd_var
    data = float(tbd)
    settings = dictionary($
        'DEPEND_0', time_var, $
        'FIELDNAM', 'EFW HSK IDPU fast TBD', $
        'VAR_TYPE', 'data', $
        'LABLAXIS', 'IDPU TBD', $
        'UNITS', '#' )
    cdf_save_var, varname, value=data, filename=cdf_id
    cdf_save_setting, varname=varname, filename=cdf_id, settings

    cdf_close, cdf_id
end




;date = time_double('2015-06-01')
;probe = 'a'
;data_file = join_path([homedir(),'test.cdf'])
;rbsp_efw_phasef_read_autobias_flag_gen_file, date, probe=probe, filename=data_file


stop
probes = ['a','b']
secofday = constant('secofday')
local_root = join_path([rbsp_efw_phasef_local_root(),'rbsp'])
foreach probe, probes do begin
    rbspx = 'rbsp'+probe
    local_path = [local_root,'efw_flag','autobias_flag','YYYY']
    valid_range = rbsp_info('flags_all', probe=probe)
    days = make_bins(valid_range+[0,-1], secofday, /inner)
    foreach day, days do begin
        lprmsg, 'Processing '+time_string(day)+' ...'
        base_name = rbspx+'_efw_autobias_flag_YYYYMMDD_v01.cdf'
        data_file = time_string(day, tformat=join_path([local_path,base_name]))

        old_name = rbspx+'efw_autobias_flag_YYYYMMDD_v01.cdf'
        old_file = time_string(day, tformat=join_path([local_path,old_name]))
        if file_test(old_file) eq 1 then begin
            file_copy, old_file, data_file
            file_delete, old_file
        endif
        ;if file_test(data_file) eq 1 then file_delete, data_file
        if file_test(data_file) eq 1 then continue
        rbsp_efw_phasef_read_autobias_flag_gen_file, day, probe=probe, filename=data_file
    endforeach
endforeach
end
