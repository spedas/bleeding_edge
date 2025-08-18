;+
; Check if all CDFs in the given folder have the same variables.
; 
; The root_dir should have CDFs saved in the following hiarachy: <root_dir>/YYYY/*.cdf
;-

pro rbsp_efw_phasef_check_cdf_consistency, root_dir

    if file_test(root_dir) eq 0 then begin
        lprmsg, 'Input root_dir does not exist ...'
        return
    endif
    lprmsg, 'Checking data consistency in the directory :'+root_dir+' ...'
    
    files = file_search(root_dir+'/*/*.cdf')
    files = sort_uniq(files)
    nfile = n_elements(files)

;---Check for versions.
    version_list = list()
    foreach file, files do begin
        base = file_basename(file)
        pos = stregex(base,'v[0-9]{2}.cdf')
        version = strmid(base,pos+1,2)
        if version_list.where(version) eq !null then begin
            version_list.add, version
        endif
    endforeach
    print, version_list
    if version_list.length ne 1 then begin
;        stop
    endif else begin
        lprmsg, 'All files have the same version. Pass ...'
    endelse

;---Check for # of variables.
    nvar_list = list()
    foreach file, files do begin
        vars = cdf_vars(file)
        nvar = n_elements(vars)
        if nvar_list.where(nvar) eq !null then begin
            nvar_list.add, nvar
        endif
    endforeach
    print, nvar_list
    if nvar_list.length ne 1 then begin
;        stop
    endif else begin
        lprmsg, 'All files have the same # of var. Pass ...'
    endelse

;---Check for variable list.
    var_list = list()
    foreach file, files do begin
        vars = cdf_vars(file)
        vars = sort_uniq(vars)
        var = strjoin(vars,' ')
        if var_list.where(var) eq !null then begin
            var_list.add, var
        endif
    endforeach
    print, var_list
    if var_list.length ne 1 then begin
;        stop
    endif else begin
        lprmsg, 'All files have the same var list. Pass ...'
    endelse

end



probes = ['a','b']
local_root = rbsp_efw_phasef_local_root()

foreach type, ['fbk','spec'] do begin
    foreach probe, probes do begin
        rbspx = 'rbsp'+probe
        root_dir = join_path([local_root,rbspx,'l2',type])
        rbsp_efw_phasef_check_cdf_consistency, root_dir
    endforeach
endforeach
stop


probes = ['a','b']
foreach probe, probes do begin
    rbspx = 'rbsp'+probe
    root_dir = '/Volumes/Research/data/rbsp/'+rbspx+'/l1/vsvy'
    rbsp_efw_phasef_check_cdf_consistency, root_dir
endforeach

end
