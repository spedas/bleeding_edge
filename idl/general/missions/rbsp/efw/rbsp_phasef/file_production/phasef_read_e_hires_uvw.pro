;+
; Read e_hires_uvw related vars.
; Adopted from rbsp_efw_make_l2_esvy_uvw.
;
; date. A string or double (unix time) for the wanted date.
; probe=. A string 'a' or 'b'.
;-

pro rbsp_efw_make_l2_esvy_uvw_remove_offset, data, winlen=winlen, $
    icomp=icomp, offset=offset_out
    compile_opt idl2, hidden

    ; winlen -- smoothing window length in seconds
    if n_elements(winlen) eq 0 then winlen = 220d   ; default is 220 seconds

    ; icomp -- component indices for which the removal is done.
    if n_elements(icomp) eq 0 then icomp = [0,1]

    rbsp_btrange, data, /structure, btr = btr, nb = nb, tind = tind

    dt = median(data.x[1:*] - data.x)
    seglen = winlen / dt

    offset_out = data.y

    for i = 0, n_elements(icomp) - 1 do begin
        ic = icomp[i]
        for ib = 0, nb - 1 do begin
            ista = tind[ib, 0]
            iend = tind[ib, 1]
            tlen = btr[ib, 1] - btr[ib, 0]
            arr = data.y[ista:iend, ic]
            narr = n_elements(arr)

            if tlen le winlen * 2d then begin
                offset = arr * 0d + median(arr)
                arr = arr - offset
            endif else begin
                nseg = long(narr / seglen)
                offset = arr * 0d + !values.f_nan
                for iseg = 0L, nseg - 1 do begin
                    ista_tmp = iseg * seglen
                    if iseg eq nseg - 1 then iend_tmp = narr - 1 else $
                    iend_tmp = ista_tmp + seglen - 1
                    imid = (ista_tmp + iend_tmp) / 2
                    offset[imid] = median(arr[ista_tmp:iend_tmp])
                    if iseg eq 0 then offset[0] = offset[imid]
                    if iseg eq nseg-1 then offset[nseg-1] = offset[imid]
                endfor
                offset = interp(offset, findgen(narr), findgen(narr), /ignore_nan)
                arr = arr - offset
            endelse
            data.y[ista:iend, ic] = arr
            offset_out[ista:iend, ic] = offset
        endfor
    endfor

end

pro phasef_read_e_hires_uvw, date, probe=probe, errmsg=errmsg, log_file=log_file

    errmsg = ''

;---Check input.
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

    data_type = 'e_hires_uvw'
    valid_range = phasef_get_valid_range(data_type, probe=probe)
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
    secofday = 86400d
    time_range = date+[0,secofday]
    timespan, date, secofday, /second
    rbsp_load_efw_waveform, probe=probe, datatype='esvy', coord='uvw'
    e_uvw_raw_var = prefix+'efw_esvy'
    if ~spd_check_tvar(e_uvw_raw_var) then begin
        errmsg = e_uvw_raw_var+' is not available. Exit processing ...'
        lprmsg, errmsg, log_file
        return
    endif
    get_data, e_uvw_raw_var, times, e_uvw_raw

    ; Remove NaNs. (ignore spin-axis data)
    index = where(finite(times) and finite(e_uvw_raw[*,0]) and finite(e_uvw_raw[*,1]), count)
    if count eq 0 then begin
        errmsg = 'No valid data. Abort ...'
        lprmsg, errmsg, log_file
        return
    endif
    store_data, e_uvw_raw_var, times[index], e_uvw_raw[index,*]

    ; Remove offsets in spin-plane boom components.
    dd = {x:temporary(times), y:temporary(e_uvw_raw)}
    rbsp_efw_make_l2_esvy_uvw_remove_offset, dd, winlen=220d, icomp=[0,1], offset=offset
    e_uvw_var = prefix+'efw_esvy_no_offset'
    store_data, e_uvw_var, data=dd

    get_data, e_uvw_var, times
    get_data, e_uvw_raw_var, tmp
    if n_elements(times) ne n_elements(tmp) then begin
        interp_time, e_uvw_raw_var, to=e_uvw_var
    endif

end


probe = 'a'
date = '2012-01-01'
date = '2012-09-25'
;date = '2019-10-13'
phasef_read_e_hires_uvw, date, probe=probe
end
