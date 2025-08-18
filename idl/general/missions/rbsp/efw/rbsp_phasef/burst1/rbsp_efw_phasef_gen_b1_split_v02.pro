;+
; Generate v02 burst1 vb1 and mscb1 split files.
; In v02 files, we move the epochs to the correct times when data are measured,
;   and we remove data outside the known times, identified by rbsp_efw_phasef_gen_b1_time_rate_v01.
;
; This file should be used by EFW to batch process the data over the whole mission.
;-

pro rbsp_efw_phasef_gen_b1_split_v02, v01_file, v02_file

    if n_elements(v01_file) eq 0 then return
    if file_test(v01_file) eq 0 then return
    if n_elements(v02_file) eq 0 then return
    file_copy, v01_file, v02_file, overwrite=1, allow_same=0

    vars = cdf_vars(v01_file)
    foreach b1_var, ['vb1','mscb'] do begin
        index = where(vars eq b1_var, count)
        if count ne 0 then break
    endforeach
    index = where(vars eq b1_var, count)
    if count eq 0 then begin
        lprmsg, 'no b1 var in v01 file: '+v01_file+' ...'
        return
    endif

    ; Prepare settings.
    base = file_basename(v01_file)
    prefix = strmid(base, 0,6)
    probe = strmid(base, 5,1)

    ; Load time rate and sampling rate.
    b1_time_rate_var = prefix+'efw_'+b1_var+'_time_rate'
    if check_if_update(b1_time_rate_var) then rbsp_efw_phasef_read_b1_time_rate, probe=probe, datatype=b1_var
    get_data, b1_time_rate_var, tmp, b1_trs, b1_srs


    ; Read epoch and data.
    cdf2tplot, v02_file
    stop

end



; Settings on m472e, need to download all B1 data first.
spawn, 'hostname', host
case host of
    'm472e.space.umn.edu': begin
        in_local_root = '/Volumes/data/rbsp'
        out_local_root = in_local_root
        end
    'xwaves7.space.umn.edu': begin
        in_local_root = '/Volumes/DataA/RBSP/data/rbsp'
        out_local_root = '/Volumes/UserA/user_volumes/kersten/data_external/rbsp'
        end
endcase
probes = ['a','b']
years = string(make_bins([2012,2019],1),format='(I04)')

b1_types = ['vb1','mscb1']
foreach b1_type, b1_types do begin
    foreach probe, probes do begin
        rbspx = 'rbsp'+probe
        data_dir = join_path([root_dir,rbspx,'l1',b1_type+'_split'])
    endforeach
endforeach

end