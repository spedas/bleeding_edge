pro psp_load_scm, files = files

  if n_elements(files) GT 0 then begin

    cdf2tplot, files, prefix = 'psp_fld_scm_', verbose=4, /get_support
    options, 'psp_fld_scm_B_SCM', 'colors', 'rgb'
    options, 'psp_fld_scm_B_SCM', 'labels', ['X','Y','Z']
    options, 'psp_fld_scm_B_SCM', 'max_points', 10000

  end

end