;+
; Read L1 time tag irregularities over the whole mission.
; Save the results in rbspx_efw_l1_isolated_jumps and rbspx_efw_l1_paired_jumps.
; 
; To access the info related to the irregularities (jumps in time tag by +/-1 sec)
; isolated_jumps.current_times
; isolated_jumps.previous_times
; paired_jumps.section_start.current_times
; paired_jumps.section_start.previous_times
; paired_jumps.section_end.current_times
; paired_jumps.section_end.previous_times
; 
; This is to replace rbsp_efw_read_l1_time_tag_leap_second and 
; rbsp_efw_read_l1_time_tag_correction.
;-

pro rbsp_efw_read_l1_time_tag_irregularity, l1_type, probe=probe

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 0
    if n_elements(probe) eq 0 then message, 'No input probe ...'

;---Prepare the input file.
    rbspx = 'rbsp'+probe
    prefix = 'rbsp'+probe+'_'
    base = rbspx+'_l1_time_tag_irregularity.cdf'
    root_dir = srootdir()
    in_file = join_path([root_dir,base])
    if file_test(in_file) eq 0 then begin
        rbsp_efw_find_l1_time_tag_irregularity, probe=probe, filename=in_file
    endif


;    tformat = 'YYYY-MM-DD/hh:mm:ss.ffffff'
;    tab = '    '
;    foreach l1_type, ['esvy','vsvy'] do begin
;        msg = l1_type
;        print, rbspx+tab+msg
;        current_times = cdf_read_var(prefix+l1_type+'_current_times', filename=in_file)
;        previous_times = cdf_read_var(prefix+l1_type+'_previous_times', filename=in_file)
;        ntime = n_elements(current_times)
;        for ii=0,ntime-1 do begin
;            msg = tab
;            msg += time_string(previous_times[ii],tformat=tformat)+tab
;            msg += time_string(current_times[ii],tformat=tformat)+tab
;            msg += string(current_times[ii]-previous_times[ii],format='(F12.9)')
;            print, msg
;        endfor
;    endforeach

;---We've manually gone through all jumps.
;   There are several isolated ones and the rest are paired.
    target_isolated_jumps = list(['2015-07-01','2017-01-01'], /extract)
    if probe eq 'b' then target_isolated_jumps.add, '2015-06-12/10:39:25'
    nisolated_jump = target_isolated_jumps.length
    isolated_jump_index = intarr(nisolated_jump)
    target_isolated_jumps = time_double(target_isolated_jumps.toarray())
    
    
;---Separate the jumps into isolated and paired.
    l1_type = 'vsvy'    ; We've checked that vsvy contains all jumps in esvy.
    current_times = cdf_read_var(prefix+l1_type+'_current_times', filename=in_file)
    previous_times = cdf_read_var(prefix+l1_type+'_previous_times', filename=in_file)
    foreach target_time, target_isolated_jumps, target_id do begin
        dtime = current_times-target_time
        tmp = min(dtime, index, /absolute)
        isolated_jump_index[target_id] = index
    endforeach
    
    isolated_jumps = dictionary($
        'current_times', current_times[isolated_jump_index], $
        'previous_times', previous_times[isolated_jump_index])

    njump = n_elements(current_times)
    flags = intarr(njump)
    flags[isolated_jump_index] = 1
    paired_jump_index = where(flags eq 0, npaired_jump)
    paired_jumps = dictionary($
        'section_start', dictionary($
            'current_times', current_times[paired_jump_index[0:*:2]], $
            'previous_times', previous_times[paired_jump_index[0:*:2]]), $
        'section_end', dictionary($
            'current_times', current_times[paired_jump_index[1:*:2]], $
            'previous_times', previous_times[paired_jump_index[1:*:2]]) )
    section_durations = (paired_jumps.section_end.current_times-paired_jumps.section_start.current_times)/3600
    
    store_data, prefix+'efw_l1_paired_jumps', 0, paired_jumps
    store_data, prefix+'efw_l1_isolated_jumps', 0, isolated_jumps
    
end

foreach probe, ['a','b'] do begin
    rbsp_efw_read_l1_time_tag_irregularity, probe=probe
endforeach
end
