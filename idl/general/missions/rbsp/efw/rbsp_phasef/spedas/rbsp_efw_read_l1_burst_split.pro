;+
; Read EFW burst split data.
;
; datatype can be 'vb1-split','mscb1-split'.
;-

pro rbsp_efw_read_l1_burst_split, tr, probe=probe, $
    datatype=datatype, trange=trange, $
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
    if n_elements(trange) ne 0 then time_range = trange
    if n_elements(tr) ne 0 then time_range = tr
    if n_elements(time_range) eq 0 then time_range = timerange()
    if size(time_range[0],/type) eq 7 then time_range = time_double(time_range)
    timespan, time_range[0], total(time_range*[-1,1]), /seconds
    if n_elements(datatype) eq 0 then datatype = 'vb1'
    data_types = ['vb1','mscb1']+'-split'
    index = where(data_types eq datatype[0], count)
    if count eq 0 then begin
        dprint, 'Invalid datatype: '+datatype[0]+' ...', verbose=vb
        return
    endif


    rbspx = 'rbsp'+probe
    base = rbspx+'_efw_l1_'+datatype+'_YYYYMMDDthhmm00_'+version+'.cdf'
    local_root = !rbsp_efw.local_data_dir
    local_path = [local_root,rbspx,'l1','efw',datatype,'YYYY',base]
    remote_root = rbsp_efw_remote_root()
    remote_path = [remote_root,rbspx,'l1','efw',datatype,'YYYY',base]
    resolution = 15*60d ; sec.
    local_files = file_dailynames(file_format=join_path(local_path), trange=time_range, resolution=resolution)
    remote_files = file_dailynames(file_format=join_path(remote_path), trange=time_range, resolution=resolution)


    local_files = rbsp_efw_read_xxx_download_files(local_files, remote_files)
    nfile = n_elements(local_files)
    if nfile eq 0 then return


    suffix = ''
    prefix = rbspx+'_efw_'
    cdf2tplot, file=local_files, all=0, prefix=prefix, suffix=suffix, verbose=vb, $
        tplotnames=tns, /convert_int1_to_int2, get_support_data=0

end


; Set the time and probe for loading data.
time_range = ['2013-06-10/05:57:20','2013-06-10/05:59:40']
probe = 'b'

; Load the burst data.
rbsp_efw_read_l1_burst_split, time_range, probe=probe, datatype='vb1-split'

prefix = 'rbsp'+probe+'_efw_'
vars = prefix+[ 'vb1' ]

; Plot the variables.
tplot, vars, trange=time_range

end
