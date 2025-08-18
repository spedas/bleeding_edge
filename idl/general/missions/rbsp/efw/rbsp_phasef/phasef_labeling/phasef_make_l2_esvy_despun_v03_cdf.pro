;+
; Make L2 esvy_despun v03 data from v01 or v02.
;
; v03 CDFs have the same format (data, support_data, metadata).
;-

pro phasef_make_l2_vsvy_hires_v02_per_day, file

    ; Internal program, do not check input.
    if file_test(file) eq 0 then message, 'File does not exist: '+file+' ...'

    ; Need to map varnames.
    old_vars = ['velocity_gse','position_gse']
    new_vars = ['vel_gse','pos_gse']
    foreach old_var, old_vars, var_id do begin
        if ~cdf_has_var(old_var, filename=file) then continue
        cdf_rename_var, old_var, to=new_vars[var_id], filename=file
    endforeach

    ; Check missing data.
    ; rbspx_efw-l2_vsvy-hires_yyyymmdd_vxx.cdf.
    base = file_basename(file)
    probe = strmid(base,4,1)
    date = time_double(strmid(base,24,8),tformat='YYYYMMDD')
    secofday = 86400d
    time_range = date+[0,secofday]

    settings = cdf_read_setting('pos_gse', filename=file)
    pos_gse = cdf_read_var('pos_gse', filename=file)

stop

    timespan, time_range[0], total(time_range*[-1,1]), /second
	rbsp_read_spice_var, time_range, probe=probe






end

pro phasef_make_l2_esvy_despun_v03_cdf


    the_usrhost = susrhost()
    default_usrhost = 'kersten@xwaves7.space.umn.edu'
    if the_usrhost ne default_usrhost then message, 'This routine only works on '+default_usrhost

    if n_elements(in_root_dir) eq 0 then begin
        if the_usrhost eq default_usrhost then begin
            in_root_dir = '/Volumes/UserA/user_volumes/kersten/data/rbsp'
        endif else message, 'No in_root_dir ...'
    endif
    if n_elements(out_root_dir) eq 0 then begin
        if the_usrhost eq default_usrhost then begin
            out_root_dir = '/Volumes/UserA/user_volumes/kersten/data_external/rbsp'
        endif else message, 'No out_root_dir ...'
    endif


;---Need to select the latest version, and add vars that do not exist.
    probes = ['a','b']
	years = string(make_bins([2012,2019],1),format='(I04)')

    secofday = 86400d
    data_type = 'esvy_despun'
    foreach probe, probes do begin
        rbspx = 'rbsp'+probe
        foreach year, years do begin
            in_path = join_path([in_root_dir,rbspx,'l2',data_type,year])
            out_path = join_path([out_root_dir,rbspx,'l2',data_type,year])
            time_range = time_double([year,string(float(year)+1,format='(I4)')])
            days = make_bins(time_range,secofday)
            foreach day, days do begin
                day_str = time_string(day,tformat='YYYYMMDD')
                v01_base = rbspx+'_efw-l2_'+data_type+'_'+day_str+'_v01.cdf'
                v02_base = rbspx+'_efw-l2_'+data_type+'_'+day_str+'_v02.cdf'
                v01_file = join_path([in_path,v01_base])
                v02_file = join_path([in_path,v02_base])

                if file_test(v01_file) eq 0 and file_test(v02_file) eq 0 then begin
                    print, v01_file
                    continue
                endif

                ;if file_test(v01_file) eq 1 and file_test(v02_file) then begin
                    ;stop
;
                ;endif else continue
                ;if file_test(v02_file) eq 0 then begin
                    ;stop
                    ;; Need spinaxis_gse, orbit_num, bias_current
                ;endif
            endforeach
        endforeach
    endforeach


end


phasef_make_l2_esvy_despun_v03_cdf
end
