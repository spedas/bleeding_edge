;+
; Coerce the labeling of L2 data for the whole mission.
;
; probes. By default ['a','b']
; data_types=. By default ['e-spinfit-mgse','esvy_despun','vsvy-hires'].
; years=. By default is ['2012',...,'2019'].
; version=. By default 1 higher than the old CDF.
; test=. Set to do coersion for 2 files per year.
; in_root_dir=. The root directory for the input CDFs.
; out_root_dir=. The root directory for the output CDFs.
; delete_unused_var=. Set to remove empty data and unused support_data and metadata.
; delete_unwanted_var=. Set to remove unwanted data.
;-

pro phasef_coerce_l2_labeling, probes, data_types=data_types, $
    years=years, version=version0, test=test, $
    in_root_dir=in_root_dir, out_root_dir=out_root_dir, $
    delete_unused_var=delete_unused_var, delete_unwanted_var=delete_unwanted_var

    if n_elements(probes) eq 0 then probes = ['a','b']

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


    if n_elements(data_types) eq 0 then begin
        data_types = ['e-spinfit-mgse','esvy_despun','vsvy-hires']
    endif
    routines = hash($
        'e-spinfit-mgse', 'coerce_labeling_l2_e_spinfit_per_file', $
        'esvy_despun', 'coerce_labeling_l2_esvy_despun_per_file', $
        'e-hires-uvw', 'coerce_labeling_l2_e_hires_uvw_per_file', $
        'vsvy-hires', 'coerce_labeling_l2_vsvy_hires_per_file')


	if n_elements(years) eq 0 then $
		years = string(make_bins([2012,2019],1),format='(I04)')


    foreach probe, probes do begin
        rbspx = 'rbsp'+probe
        foreach data_type, data_types do begin
            routine = routines[data_type]
            foreach year, years do begin
                in_path = join_path([in_root_dir,rbspx,'l2',data_type,year])
                out_path = join_path([out_root_dir,rbspx,'l2',data_type,year])
                in_files = file_search(join_path([in_path,'*.cdf']))
                nfile = n_elements(in_files)
                out_files = strarr(nfile)
                for file_id=0,nfile-1 do begin
                    base_name = file_basename(in_files[file_id])
                    pos = stregex(base_name,'v[0-9]{2}.cdf')
                    if n_elements(version0) ne 0 then begin
                        new_version = version0[0]
                    endif else begin
                        old_version = strmid(base_name,pos+1,2)
                        new_version = string(fix(old_version)+1,format='(I02)')
                    endelse
                    base_name = strmid(base_name,0,pos+1)+new_version+'.cdf'
                    out_files[file_id] = join_path([out_path,base_name])
                endfor

                log_file = join_path([out_root_dir,rbspx,'l2',data_type,routine+'.log'])
                if file_test(log_file) eq 1 then file_delete, log_file
                ftouch, log_file
                for file_id=0,nfile-1 do begin
                    in_file = in_files[file_id]
                    out_file = out_files[file_id]
                    print, in_file
                    print, out_file
                    call_procedure, routine, $
                        in_file, out_file, $
                        log_file, $
                        delete_unused_var=delete_unused_var, $
                        delete_unwanted_var=delete_unwanted_var
                    if keyword_set(test) then if file_id eq 1 then break
                endfor
            endforeach
        endforeach
    endforeach

end


data_types = ['vsvy-hires']
;data_types = ['esvy_despun']
delete_unused_var = 1
delete_unwanted_var = 1
test = 0

phasef_coerce_l2_labeling, data_types=data_types, test=test, $
    delete_unused_var=delete_unused_var, delete_unwanted_var=delete_unwanted_var
end
