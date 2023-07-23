;+
; Get the 25-element flag_all for a certain boom pair.
;-

pro rbsp_efw_phasef_read_flag_25, time_range, probe=probe, boom_pair=boom_pair


    if n_elements(boom_pair) eq 0 then boom_pair = '12'

    prefix = 'rbsp'+probe+'_'
    flag_var = prefix+'efw_phasef_flags'
    rbsp_efw_read_flags, time_range, probe=probe

    all_flags = get_var_data(flag_var, times=common_times)
    flag_names = strtrim(get_setting(flag_var, 'labels'),2)

    wanted_flag_names = [$
        'global_flag',$
        'eclipse',$
        'maneuver',$
        'efw_sweep',$
        'efw_deploy',$
        'v1_saturation',$
        'v2_saturation',$
        'v3_saturation',$
        'v4_saturation',$
        'v5_saturation',$
        'v6_saturation',$
        'Espb_magnitude',$
        'Eparallel_magnitude',$
        'magnetic_wake',$
        'autobias',$
        'charging',$
        'charging_extreme',$
        'density',$
        'boom_flag'+['1','2','3','4','5','6'],$
        'undefined']
    nwanted_flag = n_elements(wanted_flag_names)
    ncommon_time = n_elements(common_times)
    wanted_flags = fltarr(ncommon_time,nwanted_flag)

    ; Some are common to all boom pairs.
    foreach flag_name, wanted_flag_names, flag_id do begin
        index = where(flag_names eq flag_name, count)
        if count ne 0 then wanted_flags[*,flag_id] = all_flags[*,index]
    endforeach

    ; Wake flag: 1 if both 12 and 34 are flagged.
    wake_flag = all_flags[*,where(flag_names eq 'magnetic_wake_12')] and all_flags[*,where(flag_names eq 'magnetic_wake_34')]
    wanted_flags[*,where(wanted_flag_names eq 'magnetic_wake')] = wake_flag

    ; Charging flag depends on boom pair.
    foreach flag_type, ['charging','charging_extreme'] do begin
        index = where(flag_names eq flag_type+'_'+boom_pair, count)
        if count eq 0 then message, 'flag_name is not found ...'
        wanted_flags[*,where(wanted_flag_names eq flag_type)] = all_flags[*,index]
    endforeach

    ; Boom flag: 1 if any of the spin plane boom is flagged.
    foreach boom, ['1','2','3','4'] do begin
        boom_flag = all_flags[*,where(flag_names eq 'boomflag'+boom)]
        wanted_flags[*,where(wanted_flag_names eq 'boom_flag'+boom)] = boom_flag gt 0
    endforeach


    ; Global flag, c.f. phase F book chapter on data flags.
    bps = [strmid(boom_pair,0,1),strmid(boom_pair,1,1)]
    trigger_index = []
    trigger_flags = ['eclipse','maneuver','efw_sweep','efw_deploy',$
        'charging','charging_extreme','boom_flag'+['1','2','3','4'],$
        'v'+bps+'_saturation']
    foreach flag_name, trigger_flags do begin
        trigger_index = [trigger_index, where(wanted_flag_names eq flag_name)]
    endforeach
    wanted_flags[*,where(wanted_flag_names eq 'global_flag')] = total(wanted_flags[*,trigger_index],2) gt 0

    var = prefix+'flag_25'
    store_data, var, common_times, wanted_flags, limits={labels:wanted_flag_names}
    add_setting, var, /smart, dictionary($
        'display_type', 'stack', $
        'yrange', [-0.2,1.2], $
        'labels', wanted_flag_names )

end


; Test flags.
time_range = time_double(['2017-09-07','2017-09-08'])
probe = 'a'
prefix = 'rbsp'+probe+'_'
rbsp_efw_read_flags, time_range, probe=probe
flag_var = prefix+'efw_phasef_flags'
get_data, flag_var, times, all_flags, limits=lim
flag_names = lim.labels
all_flags[*] = 0
step = floor(n_elements(times)/n_elements(flag_names))
foreach flag_name, flag_names, flag_id do begin
    i0 = flag_id*step
    i1 = (flag_id+1)*step-1
    all_flags[i0:i1,flag_id] = 1
endforeach
store_data, flag_var, times, all_flags
rbsp_efw_phasef_read_flag_25, time_range, probe=probe, boom_pair='34'
get_data, prefix+'flag_25', times, flag_25
store_data, prefix+'flag_25_global_flag', times, flag_25[*,0], limits={ystyle:1, yrange:[-0.2,1.2]}

stop



time_range = time_double(['2017-09-07','2017-09-08'])
probe = 'a'
rbsp_efw_phasef_read_flag_25, time_range, probe=probe


end
