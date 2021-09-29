Function elf_config_filedir, app_query = app_query, _extra = _extra

  readme_txt = ['Directory for configuration files for use by elf']

  If(keyword_set(app_query)) Then Begin
    tdir = app_user_dir_query('elf', 'elf_config', /restrict_os)
    If(n_elements(tdir) Eq 1) Then tdir = tdir[0]
    return, tdir
  Endif Else Begin
    return, app_user_dir('elf', $; AuthorDirname
      'elf Configuration Process', $; AuthorDesc
      'elf_config', $; AppDirname
      'elf configuration Directory', $; AppDesc
      readme_txt, $; AppReadmeText
      1, $ ;AppReadmeVersion
      /restrict_os)
  Endelse
End