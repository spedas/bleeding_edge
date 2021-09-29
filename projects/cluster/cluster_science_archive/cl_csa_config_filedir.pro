Function cl_csa_config_filedir, app_query = app_query, _extra = _extra

  readme_txt = ['Directory for configuration files for use by cluster_csa']
  
  If(keyword_set(app_query)) Then Begin
    tdir = app_user_dir_query('cluster_csa', 'cl_csa_config', /restrict_os)
    If(n_elements(tdir) Eq 1) Then tdir = tdir[0]
    return, tdir
  Endif Else Begin
    return, app_user_dir('cluster_csa', $; AuthorDirname
      'cluster CSA Configuration Process', $; AuthorDesc
      'cl_csa_config', $; AppDirname
      'cluster CSA configuration Directory', $; AppDesc
      readme_txt, $; AppReadmeText
      1, $ ;AppReadmeVersion
      /restrict_os)
  Endelse
End