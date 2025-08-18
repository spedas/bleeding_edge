;+
; Some CDFs have 11 vars, find those out.
;-

probes = ['a','b']
foreach probe, probes do begin
    rbspx = 'rbsp'+probe
    root_dir = '/Volumes/UserA/user_volumes/kersten/data_external/rbsp/'+rbspx+'/l2/vsvy-hires'

    files = file_search(root_dir+'/*/*.cdf')
    files = sort_uniq(files)
    nfile = n_elements(files)

    nvar_list = intarr(nfile)
    foreach file, files, file_id do begin
        vars = cdf_vars(file)
        nvar = n_elements(vars)
        nvar_list[file_id] = nvar
    endforeach
    stop


    foreach file, bad_files do begin
        vars = cdf_vars(file)
        nvar = n_elements(vars)
        stop
    endforeach

endforeach

end
