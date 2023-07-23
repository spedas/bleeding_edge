;+
; Read EFW L1 data.
;
; datatype can be 'esvy','vsvy',
; 'eb1','vb1','mscb1','eb2','vb2','mscb2',
; 'vb1-split','mscb1-split'.
;-

pro rbsp_efw_read_l1, tr, probe=probe, datatype=datatype, trange=trange, $
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
    if n_elements(datatype) eq 0 then begin
        dprint, 'No datatype ...', verbose=vb
        return
    endif
    data_types = ['esvy','vsvy',$
        'eb1','eb2','mscb1','mscb2','vb1','vb2']
    index = where(data_types eq datatype[0], count)
    if count eq 0 then begin
        split_data_types = ['vb1-split','mscb1-split']
        index = where(split_data_types eq datatype[0], count)
        if count ne 0 then begin
            rbsp_efw_read_l1_burst_split, tr, probe=probe, $
                datatype=datatype, trange=trange, $
                level=level, verbose=verbose, downloadonly=downloadonly, $
                cdf_data=cdf_data,get_support_data=get_support_data, $
                tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $
                varformat=varformat, valid_names = valid_names, files=files, $
                type=type, _extra = _extra
        endif else begin
            dprint, 'Invalid datatype: '+datatype[0]+' ...', verbose=vb
        endelse
        return
    endif

    rbspx = 'rbsp'+probe
    base = rbspx+'_l1_'+datatype+'_YYYYMMDD_'+version+'.cdf'
    if datatype eq 'mscb1-split' or datatype eq 'vb1-split' then begin
        base = rbspx+'_efw_l1_'+datatype+'_YYYYMMDDthhmmss_'+version+'.cdf'
    endif
    local_root = !rbsp_efw.local_data_dir
    local_path = [local_root,rbspx,'l1','efw',datatype,'YYYY',base]
    remote_root = rbsp_efw_remote_root()
    remote_path = [remote_root,rbspx,'l1','efw',datatype,'YYYY',base]
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
probe = 'b'

; Load the spinfit data.
rbsp_efw_read_l1, time_range, probe=probe, datatype='esvy'
rbsp_efw_read_l1, time_range, probe=probe, datatype='vsvy'

prefix = 'rbsp'+probe+'_efw_'
vars = prefix+[$

    ; The E field in UVW.
    'esvy', $

    ; The single-ended boom potential.
    'vsvy' ]

; Plot the variables.
tplot, vars, trange=time_range
end
