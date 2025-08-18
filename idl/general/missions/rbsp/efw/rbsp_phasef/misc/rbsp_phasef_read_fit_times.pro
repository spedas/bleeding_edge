;+
; Read the section times to do fit, in [n,2].
; Ensure that each section is long enough to contain >3 perigees.
;-

function rbsp_phasef_read_fit_times, probe=probe, filename=txt_file

    if n_elements(txt_file) eq 0 then $
        txt_file = '/Volumes/GoogleDrive/My Drive/works/works/rbsp_phasef/data/rbsp_maneuver_list_manual_for_perigee_correction.txt'
    if file_test(txt_file) eq 0 then message, 'Need this file, contact tianx138@umn.edu ...'
    
    prefix = 'rbsp'+probe+'_'
    the_var = prefix+'fit_times'
    if tnames(the_var) eq '' then begin
        start_time = '2012-09-08/00:00'
        end_time = (probe eq 'a')? '2019-10-14/24:00': '2019-07-16/24:00'
        mission_time_range = time_double([start_time,end_time])
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
    
;    if tnames(the_var) eq '' then begin
;        start_time = '2012-09-08/00:00'
;        end_time = (probe eq 'a')? '2019-10-14/24:00': '2019-07-16/24:00'
;        mission_time_range = time_double([start_time,end_time])
;        times = make_bins(mission_time_range,constant('secofday'),/inner)
;        dates = time_string(times,tformat='YYYY-MM-01')
;        dates = sort_uniq(dates)
;        times = time_double(dates)
;        index = lazy_where(times,'()', mission_time_range, count=count)
;        fit_times = [mission_time_range[0], times[index], mission_time_range[1]]
;        store_data, the_var, 0, fit_times
;    endif

    return, get_var_data(the_var)

end

tmp = rbsp_phasef_read_fit_times(probe='b')
end