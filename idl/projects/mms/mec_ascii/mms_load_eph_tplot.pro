;+
; PROCEDURE:
;         mms_load_eph_tplot
;
; PURPOSE:
;         Loads ASCII ephemeris files into tplot variables
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-03-16 16:11:23 -0700 (Fri, 16 Mar 2018) $
;$LastChangedRevision: 24897 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/mec_ascii/mms_load_eph_tplot.pro $
;-
pro mms_load_eph_tplot, filenames, tplotnames = tplotnames, prefix = prefix, level = level, $
    probe=probe, datatypes = datatypes, trange = trange, suffix = suffix

    ; print a warning about how long this takes so user's do not
    ; assume the process is frozen after a few seconds
    ;dprint, dlevel = 1, 'Loading ephemeris files can take some time; please be patient...'
    if undefined(prefix) then prefix = 'mms'
    if undefined(datatype) then datatype = 'def'
    if undefined(suffix) then suffix = ''

    for file_idx = 0, n_elements(filenames)-1 do begin
        ; load the data from the ASCII file
        new_eph_data = mms_read_eph_file(filenames[file_idx])
        ;    this_start = new_eph_data.time[0]
        ;    this_end = new_eph_data.time[n_elements(new_eph_data.time)-1]
        if is_struct(new_eph_data) then begin
            ; note on time format in this file:
            ; date/time values are stored in the format: YYYY-DOYThh:mm:ss.fff
            ; so to convert the first time value to a time_double,
            ;    time_values = time_double(new__att_data.time, tformat='YYYY-DOYThh:mm:ss.fff')
            append_array, time_values, time_double(new_eph_data.time[0:n_elements(new_eph_data.time)-2], tformat='YYYY-DOY/hh:mm:ss.fff')
            if where(datatypes EQ 'pos') NE -1 then append_array, eph_data_pos, new_eph_data.pos[0:n_elements(new_eph_data.time)-2,*]
            if where(datatypes EQ 'vel') NE -1 then append_array, eph_data_vel, new_eph_data.vel[0:n_elements(new_eph_data.time)-2,*]
        endif
    endfor

    ; sort and find unique time_values since predicted files overlap each other
    idx=[uniq(time_values, sort(time_values))]
    time_values = time_values[idx]
    if ~undefined(eph_data_pos) then eph_data_pos = eph_data_pos[idx,*]
    if ~undefined(eph_data_vel) then eph_data_vel = eph_data_vel[idx,*]

    ; check that some data was actually loaded in
    if undefined(time_values) then begin
        dprint, dlevel = 0, 'Error loading ephemeris data - no data was loaded.'
        return
    endif else begin
        ; warn user if only partial data was loaded
        if time_values[0] GT time_double(trange[0]) OR time_values[n_elements(time_values)-1] LT time_double(trange[1]) then $
            dprint, dlevel = 1, 'Warning, not all data in the requested time frame was loaded.'
    endelse

    default_colors = [2, 4, 6]
    data_att = {coord_sys:'', st_type:'', units:''}
    dl = {filenames:filenames, colors:default_colors, data_att:data_att}
    ; Populate dlimits.colors to match tplot defaults
    ; for pos and vel variables.
    ;add labels indicating whether data is pos, vel, or neither
    if where(datatypes EQ 'pos') NE -1 then begin
        pos_name =  prefix + '_' + level + 'eph_pos' + suffix
        str_element,dl,'data_att.st_type','pos',/add_replace
        str_element,dl,'data_att.coord_sys','j2000', /add_replace
        ;str_element,dl,'data_att.coord_sys','unknown', /add_replace
        str_element,dl,'data_att.units','km', /add_replace
        str_element,dl,'labels',['x','y','z'], /add
        str_element,dl,'vname',pos_name, /add
        str_element,dl,'ysubtitle','[km]', /add
        store_data, pos_name, data={x: time_values, y: eph_data_pos}, dlimits=dl, l=0
        append_array, tplotnames, [pos_name]
        dprint, dlevel = 1, 'Tplot variable created: ' + pos_name
    endif
    dl = {filenames:filenames, colors:default_colors, data_att:data_att}
    if where(datatypes EQ 'vel') NE -1 then begin
        vel_name =  prefix + '_' + level + 'eph_vel' + suffix
        str_element,dl,'data_att.st_type','vel',/add_replace
        str_element,dl,'data_att.coord_sys','j2000', /add_replace
        str_element,dl,'data_att.units','km/s', /add_replace
        str_element,dl,'labels',['vx','vy','vz'], /add
        str_element,dl,'vname',vel_name, /add
        str_element,dl,'ysubtitle','[km/s]', /add
        store_data, vel_name, data={x: time_values, y: eph_data_vel}, dlimits=dl, l=0
        append_array, tplotnames, [vel_name]
        dprint, dlevel = 1, 'Tplot variable created: '+ vel_name
    endif
end