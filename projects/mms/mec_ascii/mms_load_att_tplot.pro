;+
; PROCEDURE:
;         mms_load_att_tplot
;
; PURPOSE:
;         Loads ASCII attitude files into tplot variables
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-05-25 14:40:54 -0700 (Wed, 25 May 2016) $
;$LastChangedRevision: 21203 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/mec_ascii/mms_load_att_tplot.pro $
;-
pro mms_load_att_tplot, filenames, tplotnames = tplotnames, prefix = prefix, level = level, $
    probe=probe, datatypes = datatypes, trange = trange, suffix = suffix

    ; print a warning about how long this takes so user's do not
    ; assume the process is frozen after a few seconds
    dprint, dlevel = 1, 'Loading attitude files can take some time; please be patient...'
    if undefined(prefix) then prefix = 'mms'
    if undefined(level) then level = 'def'
    if undefined(suffix) then suffix = ''

    for file_idx = 0, n_elements(filenames)-1 do begin
        ; load the data from the ASCII file
        if level EQ 'def' then new_att_data = mms_read_def_att_file(filenames[file_idx]) $
        else new_att_data = mms_read_pred_att_file(filenames[file_idx])

        if is_struct(new_att_data) then begin
            ; note on time format in this file:
            ; date/time values are stored in the format: YYYY-DOYThh:mm:ss.fff
            ; so to convert the first time value to a time_double,
            ;    time_values = time_double(new__att_data.time, tformat='YYYY-DOYThh:mm:ss.fff')
            append_array, time_values, time_double(new_att_data.time[0:n_elements(new_att_data.time)-2], tformat='YYYY-DOYThh:mm:ss.fff')
            ; only load data products the user requested
            if where(datatypes EQ 'spinras') NE -1 then append_array, att_data_ras, new_att_data.LRA[0:n_elements(new_att_data.time)-2]
            if where(datatypes EQ 'spindec') NE -1 then append_array, att_data_dec, new_att_data.LDEC[0:n_elements(new_att_data.time)-2]
        endif
    endfor

    ; sort and find unique time_values since predicted files overlap each other
    idx=[uniq(time_values, sort(time_values))]
    time_values = time_values[idx]
    if ~undefined(att_data_ras) then att_data_ras = att_data_ras[idx]
    if ~undefined(att_data_dec) then att_data_dec = att_data_dec[idx]

    ; check that some data was actually loaded in
    if undefined(time_values) then begin
        dprint, dlevel = 0, 'Error loading attitude data - no data was loaded.'
        return
    endif else begin
        ; warn user if only partial data was loaded
        if time_values[0] GT time_double(trange[0]) OR time_values[n_elements(time_values)-1] LT time_double(trange[1]) then $
            dprint, dlevel = 1, 'Warning, not all data in the requested time frame was loaded.'
    endelse

    data_att = {coord_sys:'', st_type:'none', units:'deg'}
    dl = {filenames:filenames, data_att:data_att, ysubtitle:'[deg]'}
    if where(datatypes EQ 'spinras') NE -1 then begin
        spinras_name =  prefix + '_' + level + 'att_spinras' + suffix
        str_element,dl,'vname',spinras_name, /add
        store_data, spinras_name, data={x: time_values, y: att_data_ras}, dlimits=dl, l=0
        append_array, tplotnames, [spinras_name]
        dprint, dlevel = 1, 'Tplot variable created: '+ spinras_name
    endif
    if where(datatypes EQ 'spindec') NE -1 then begin
        spindec_name =  prefix + '_' + level + 'att_spindec' + suffix
        str_element,dl,'vname',spindec_name, /add_replace
        store_data, spindec_name, data={x: time_values, y: att_data_dec}, dlimits=dl, l=0
        append_array, tplotnames, [spindec_name]
        dprint, dlevel = 1, 'Tplot variable created: '+ spindec_name
    endif

end