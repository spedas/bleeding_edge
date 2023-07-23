;+
; Read b1 time and rate. Adopted from Aaron's burst1_times_rates_RBSPx.txt.
; Fixed sections with non-standard sample rates, i.e., those are not 0.5,1,2,4,8,16k S/s.
; Also, Sections spanning two days are handled properly now.
;
; datatype=. Can be 'vb1' or 'mscb1'.
;-

pro rbsp_efw_phasef_read_b1_time_rate, tr, probe=probe, datatype=datatype, trange=trange, $
    level=level, verbose=verbose, downloadonly=downloadonly, $
    cdf_data=cdf_data,get_support_data=get_support_data, $
    tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $
    varformat=varformat, valid_names = valid_names, files=files, $
    type=type, _extra = _extra

    rbsp_efw_init
    vb = keyword_set(verbose) ? verbose : 0
    vb = vb > !rbsp_efw.verbose

    if n_elements(probe) eq 0 then probe = 'a'
    if n_elements(version) eq 0 then version = 'v*'
;    if n_elements(trange) ne 0 then time_range = trange
;    if n_elements(tr) ne 0 then time_range = tr
;    if n_elements(time_range) eq 0 then time_range = timerange()
;    if size(time_range[0],/type) eq 7 then time_range = time_double(time_range)
;    timespan, time_range[0], total(time_range*[-1,1]), /seconds
    if n_elements(datatype) eq 0 then datatype = 'vb1'
    data_types = ['vb1','mscb1']
    index = where(data_types eq datatype[0], count)
    if count eq 0 then begin
        dprint, 'Invalid datatype: '+datatype[0]+' ...', verbose=vb
        return
    endif
    datatype = 'vb1'    ; 'mscb1' is the same.

    rbspx = 'rbsp'+probe
    base = rbspx+'_efw_l1_'+datatype+'_time_rate_v01.cdf'
    base_remote = rbspx+'_l1_'+datatype+'_time_rate_v01.cdf'
    local_root = !rbsp_efw.local_data_dir
    local_path = [local_root,rbspx,'efw','l1',datatype+'-split',base]
    remote_root = rbsp_efw_remote_root()
;    remote_path = [remote_root,rbspx,(rbsp_efw_remote_sub_dirs(level='l1',datatype=datatype+'-split'))[0:-2],base]  ; remove YYYY.
    remote_path = [remote_root,'documents','efw',base_remote]  ; remove YYYY.
    local_file = join_path(local_path)
    remote_file = join_path(remote_path)

    url = remote_file
    spd_download_expand, url, last_version=1, $
        ssl_verify_peer=0, ssl_verify_host=0, _extra=_extra
    base = file_basename(url)
    local_file = join_path([file_dirname(local_file),base])
    tmp = spd_download_file(url=url, filename=local_file, ssl_verify_peer=0, ssl_verify_host=0)

    time_ranges = cdf_read_var('time_range', filename=local_file)
    sample_rate = cdf_read_var('median_sample_rate', filename=local_file)

    prefix = 'rbsp'+probe+'_'
    store_data, prefix+'efw_'+datatype+'_time_rate', time_ranges[*,0], time_ranges, float(sample_rate)

end

probes = ['a','b']
foreach probe, probes do rbsp_efw_phasef_read_b1_time_rate, probe=probe
end
