;+
; Generate v03 burst1 vb1 and mscb1 split files.
; In v03 files, we move the epochs to the correct times when data are measured,
;   and we remove data outside the known times, identified by rbsp_efw_phasef_gen_b1_time_rate_v01.
;
; This file should be used by EFW to batch process the data over the whole mission.
;-

pro rbsp_efw_phasef_gen_b1_split_v03_skeleton, file

    if file_test(file) eq 0 then return

    base = file_basename(file)
    if strmid(base,0,4) ne 'rbsp' then return

    probe = strmid(base,4,1)
    rbspx = 'rbsp'+probe
    prefix = 'rbsp'+probe+'_'

    ; base: rbspx_efw_l1_xb1-split
    logical_source = strjoin((strsplit(base,'_',/extract))[0:3],'_')
    gatts = dictionary( $
        'Logical_source', logical_source, $
        'Data_version', 'v03', $
        'MODS', '', $
        'Acknowledgement', "This work was supported by Van Allen Probes (RBSP) EFW funding provided by JHU/APL Contract No. 922613 under NASA's Prime Contract No. NNN06AA01C; EFW PI, J. R. Wygant, UMN.", $
        'Generation_date', time_string(systime(1),tformat='YYYY:MM:DDThh:mm:ss'), $
        'Logical_file_id', strmid(base,0,strlen(base)-4), $
        'Project', 'RBSP>Radiation Belt Storm Probes', $
        'HTTP_LINK', 'http://rbsp.space.umn.edu http://athena.jhuapl.edu', $
        'PI_name', 'J. R. Wygant', $
        'PI_affiliation', 'University of Minnesota', $
        'Instrument_type', 'Electric Fields (space)', $
        'Time_resolution', 'UTC' )

    foreach key, gatts.keys() do begin
        cdf_save_setting, key, gatts[key], filename=file
    endforeach

    keys = ['LINK_TITLE','TEXT','LINK_TEXT','Logical_source_description']
    foreach key, keys do cdf_del_setting, key, filename=file

    vars = ['epoch']
    var_notes = 'Epoch tagged at the center of each interval, resolution can be from 1/16,384 to 1/512 sec'
    foreach var, vars, var_id do begin
        cdf_save_setting, 'VAR_NOTES', var_notes[var_id], filename=file, varname=var
        cdf_save_setting, 'UNITS', 'ps (pico-second)', filename=file, varname=var
    endforeach

end

pro rbsp_efw_phasef_gen_b1_split_v03, old_file, new_file

    if n_elements(old_file) eq 0 then return
    if file_test(old_file) eq 0 then return
    if n_elements(new_file) eq 0 then return


    vars = cdf_vars(old_file)
    foreach b1_var, ['vb1','mscb1'] do begin
        index = where(vars eq b1_var, count)
        if count ne 0 then break
    endforeach
    index = where(vars eq b1_var, count)
    if count eq 0 then begin
        lprmsg, 'no b1 var in v01 file: '+old_file+' ...', log_file
        return
    endif

    ; Prepare settings.
    base = file_basename(old_file)
    prefix = strmid(base, 0,6)
    probe = strmid(base, 4,1)

    ; Load time rate and sampling rate.
    b1_time_rate_var = prefix+'efw_'+b1_var+'_time_rate'
    if check_if_update(b1_time_rate_var) then rbsp_efw_phasef_read_b1_time_rate, probe=probe, datatype=b1_var
    get_data, b1_time_rate_var, tmp, b1_trs, b1_srs


    ; Read epoch and data in old file to check time ranges.
    cdf2tplot, old_file
    b1_data = get_var_data(b1_var, times=b1_time)
    print, time_string(minmax(b1_time))

    index = where(b1_trs[*,0] lt max(b1_time) and $
        b1_trs[*,1] gt min(b1_time), ntr)
    if ntr eq 0 then begin
        lprmsg, 'Should have times in b1_trs ...', log_file
        return
    endif


;---Copy data over and perform adjustments on time tag and labeling.
    new_path = file_dirname(new_file)
    if file_test(new_path,/directory) eq 0 then file_mkdir, new_path
    file_copy, old_file, new_file, overwrite=1, allow_same=0

    the_trs = b1_trs[index,*]
    the_dts = 1d/b1_srs[index,0]
    new_time = []
    new_data = []
    for ii=0,ntr-1 do begin
        index = lazy_where(b1_time,'[]',the_trs[ii,*], count=count)
        if count eq 0 then continue
        ; Adjust the time tag to the actual measured time.
        new_time = [new_time,b1_time[index]-the_dts[ii]]
        new_data = [new_data,b1_data[index,*]]
    endfor

    time_var = 'epoch'
    new_epoch = convert_time(new_time, from='unix', to='epoch16')
    cdf_save_data, time_var, value=new_epoch, filename=new_file
    cdf_save_data, b1_var, value=transpose(new_data), filename=new_file

    ; Fix labeling.
    rbsp_efw_phasef_gen_b1_split_v03_skeleton, new_file


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

b1_types = ['mscb1']
old_version = 'v02'
new_version = 'v03'
foreach b1_type, b1_types do begin
    foreach probe, probes do begin
        rbspx = 'rbsp'+probe
        prefix = 'rbsp'+probe+'_'

        old_dir = join_path([out_local_root,rbspx,'l1',b1_type+'_split'])
        new_dir = join_path([out_local_root,rbspx,'l1',b1_type+'-split_v03'])

        var = prefix+'efw_'+b1_type+'_time_rate'
        if check_if_update(var) then begin
            base = prefix+'l1_'+b1_type+'_time_rate_v01.cdf'
            file = join_path([old_dir,base])
            time_ranges = cdf_read_var('time_range', filename=file)
            sample_rate = cdf_read_var('median_sample_rate', filename=file)
            store_data, var, time_ranges[*,0], time_ranges, float(sample_rate)
        endif

        old_files = file_search(join_path([old_dir,'*','*'+old_version+'.cdf']))
        foreach old_file, old_files do begin
            old_base = file_basename(old_file)
            ;pos = strpos(old_base, old_version)
            pos = (b1_type eq 'mscb1')? 15: 13
            time_str = strmid(old_base,pos,13)+'00'
            time_str = strjoin(strsplit(time_str,'_',/extract),'T')
            new_base = rbspx+'_efw_l1_'+b1_type+'-split_'+time_str+'_'+new_version+'.cdf'
            year = strmid(file_dirname(old_file),3, /reverse)
            new_file = join_path([new_dir,year,new_base])
            rbsp_efw_phasef_gen_b1_split_v03, old_file, new_file
        endforeach
    endforeach
endforeach

end
