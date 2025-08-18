;+
; Return the section times, in [n,2],
; for calculating the parameter for e_fit.
;
; The times are essentially the manuver times.
; Ensure that each section is long enough to contain >3 perigees.
;-

function rbsp_efw_phasef_read_e_fit_times, probe=probe, filename=txt_file

    if n_elements(txt_file) eq 0 then begin
        txt_file = join_path([srootdir(),'rbsp_efw_phasef_read_e_fit_times.txt'])
    endif
    if file_test(txt_file) eq 0 then message, 'Missing necessary files, please contact tianx138@umn.edu ...'

    prefix = 'rbsp'+probe+'_'
    the_var = prefix+'e_fit_times'
    if tnames(the_var) eq '' then begin
        mission_time_range = rbsp_efw_phasef_get_valid_range('spice', probe=probe)
        lines = read_all_lines(txt_file, skip_header=1)
        nline = n_elements(lines)
        maneuver_times = dblarr(nline,2)
        for ii=0,nline-1 do begin
            tline = lines[ii]
            the_probe = strlowcase(strmid(tline,5,1))
            if probe ne the_probe then continue
            tinfo = strsplit(tline,' ',/extract)
            maneuver_times[ii,*] = time_double(tinfo[1:2])
        endfor
        index = where(maneuver_times[*,0] ne 0, nsection)
        maneuver_times = maneuver_times[index,*]
        fit_times = dblarr(nsection+1,2)
        fit_times[*,0] = [mission_time_range[0],maneuver_times[*,1]]
        fit_times[*,1] = [maneuver_times[*,0],mission_time_range[1]]
        store_data, the_var, 0, fit_times
    endif

    return, get_var_data(the_var)

end

tmp = rbsp_efw_phasef_read_e_fit_times(probe='b')
end
