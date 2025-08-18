Function cl_config_filedir, app_query = app_query, _extra = _extra

  readme_txt = ['Directory for configuration files for use by cluster']
  
  If(keyword_set(app_query)) Then Begin
    tdir = app_user_dir_query('cluster', 'cl_config', /restrict_os)
    If(n_elements(tdir) Eq 1) Then tdir = tdir[0]
    return, tdir
  Endif Else Begin
    return, app_user_dir('cluster', $; AuthorDirname
      'cluster Configuration Process', $; AuthorDesc
      'cl_config', $; AppDirname
      'cluster configuration Directory', $; AppDesc
      readme_txt, $; AppReadmeText
      1, $ ;AppReadmeVersion
      /restrict_os)
  Endelse
End