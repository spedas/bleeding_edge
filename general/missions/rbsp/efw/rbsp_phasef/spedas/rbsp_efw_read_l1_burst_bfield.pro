;+
; Read EFW burst data. Save data in rbspx_efw_mscb1_<coord>.
;
; datatype can be 'mscb1','mscb2'.
;
; coord=. A lower case string sets the coordinate of the output data. 'mgse' by default.
;-


pro rbsp_efw_read_l1_burst_bfield, tr, probe=probe, $
    datatype=datatype, trange=trange, $
    level=level, verbose=verbose, downloadonly=downloadonly, $
    cdf_data=cdf_data,get_support_data=get_support_data, $
    tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $
    varformat=varformat, valid_names=valid_names, files=files, $
    type=type, _extra=_extra

    rbsp_efw_init
    vb = keyword_set(verbose) ? verbose : 0
    vb = vb > !rbsp_efw.verbose

    if n_elements(coord) eq 0 then coord = 'mgse'
    if n_elements(datatype) eq 0 then datatype = 'mscb1-split'

    data_types = ['mscb1','mscb2','mscb1-split']
    data_type = datatype[0]
    index = where(data_types eq data_type, count)
    if count eq 0 then begin
        dprint, 'Invalid datatype: '+data_type+' ...', verbose=vb
        return
    endif
    if data_type eq 'mscb1-split' then begin
        rbsp_efw_read_l1_burst_split, tr, probe=probe, $
            datatype=data_type, trange=trange, $
            level=level, verbose=verbose, downloadonly=downloadonly, $
            cdf_data=cdf_data,get_support_data=get_support_data, $
            tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $
            varformat=varformat, valid_names=valid_names, files=files, $
            type=type, _extra=_extra
    endif else begin
        rbsp_efw_read_l1, tr, probe=probe, $
            datatype=data_type, trange=trange, $
            level=level, verbose=verbose, downloadonly=downloadonly, $
            cdf_data=cdf_data,get_support_data=get_support_data, $
            tplotnames=tns, make_multi_tplotvar=make_multi_tplotvar, $
            varformat=varformat, valid_names=valid_names, files=files, $
            type=type, _extra=_extra
    endelse


;---Calbirate B field.
    prefix = 'rbsp'+probe+'_'
    if data_type eq 'mscb2' then begin
        data_type2 = 'mscb2'
    endif else begin
        data_type2 = 'mscb1'
    endelse
    in_var = prefix+'efw_'+data_type2
    get_data, in_var, data=dd
    if size(dd,/type) ne 8 then begin
        errmsg = 'No data ...'
        return
    endif
    store_data, in_var, dlimits={data_att:{units:'ADC'}}
    time_range = time_double(tr)
    timespan, time_range[0], total(time_range*[-1,1]), second=1
    rbsp_efw_cal_waveform, probe=probe, datatype=data_type2, trange=time_range


;---Convert vector from UVW to wanted coord.
    rgb = [6,4,2]
    xyz = ['x','y','z']
    get_data, in_var, times, vec, limits=lim
    vec = cotran(vec, times, 'uvw2'+coord[0], probe=probe, use_orig_quaternion=1)
    out_var = in_var+'_'+coord[0]
    store_data, out_var, times, vec, limits={$
        ytitle:prefix+'burst_bfield!C[nT]', $
        labels:strupcase(coord)+' B'+xyz, $
        colors:rgb }

end


; Set the time and probe for loading data.
time_range = ['2013-06-10/05:57:20','2013-06-10/05:59:40']
probe = 'b'

; Load the burst data.
rbsp_efw_read_l1_burst_efield, time_range, probe=probe, datatype='vb1', coord='mgse'
rbsp_efw_read_l1_burst_bfield, time_range, probe=probe, datatype='mscb1', coord='mgse'

prefix = 'rbsp'+probe+'_efw_'
vars = prefix+[$

    ; The E and B fields in mgse.
    ['eb1','mscb1']+'_mgse' ]

; Plot the variables.
tplot_options, 'labflag', -1
tplot, vars, trange=time_range
end
