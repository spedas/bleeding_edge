;+
; Make L2 vsvy-hires v02 data from v01.
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

pro phasef_make_l2_vsvy_hires_v02, time_range, probe=probe

    the_usrhost = susrhost()
    default_usrhost = 'kersten@xwaves7.space.umn.edu'
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


    wanted_vars = ['vsvy','vsvy_vavg',$
        'orbit_num','vel_gse','pos_gse',$
        'mlt','mlat','lshell']


end


in_file = '/Users/shengtian/Downloads/sample_l2/rbspa_efw-l2_vsvy-hires_20120906_v01.cdf'
out_file = '/Users/shengtian/Downloads/sample_l2/rbspa_efw-l2_vsvy-hires_20120906_v02.cdf'
file_copy, in_file, out_file, /overwrite
phasef_make_l2_vsvy_hires_v02_per_day, out_file
end
