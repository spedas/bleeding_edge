;+
;Function: rbsp_efw_config_filedir.pro
;Purpose: Get the applications user directory for RBSP EFW data analysis software
;
;$LastChangedBy: peters $
;$LastChangedDate: 2011-12-28 10:26:47 -0800 (Wed, 28 Dec 2011) $
;$LastChangedRevision: 9477 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_efw_config_filedir.pro $
;-

Function rbsp_efw_config_filedir, app_query = app_query, _extra = _extra

  readme_txt = ['Directory for configuration files for use by ', $
                'the RBSP EFW Data Analysis Software']

  If(keyword_set(app_query)) Then Begin
    tdir = app_user_dir_query('rbsp_efw', 'rbsp_efw_config', /restrict_os)
    If(n_elements(tdir) Eq 1) Then tdir = tdir[0] 
    Return, tdir
  Endif Else Begin
    Return, app_user_dir('rbsp_efw', 'RBSP EFW Configuration Process', $
                         'rbsp_efw_config', $
                         'RBSP EFW configuration Directory', $
                         readme_txt, 1, /restrict_os)
  Endelse

End
