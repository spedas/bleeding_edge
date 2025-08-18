;+
;Function: rbsp_emfisis_config_filedir.pro
;Purpose: Get the applications user directory for RBSP EMFISIS data analysis software
;
;$LastChangedBy: peters $
;$LastChangedDate: 2012-05-15 11:57:32 -0700 (Tue, 15 May 2012) $
;$LastChangedRevision: 10429 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/emfisis/rbsp_emfisis_config_filedir.pro $
;-

Function rbsp_emfisis_config_filedir, app_query = app_query, _extra = _extra

  readme_txt = ['Directory for configuration files for use by ', $
                'the RBSP EMFISIS Data Analysis Software']

  If(keyword_set(app_query)) Then Begin
    tdir = app_user_dir_query('rbsp_emfisis', 'rbsp_emfisis_config', /restrict_os)
    If(n_elements(tdir) Eq 1) Then tdir = tdir[0] 
    Return, tdir
  Endif Else Begin
    Return, app_user_dir('rbsp_emfisis', 'RBSP EMFISIS Configuration Process', $
                         'rbsp_emfisis_config', $
                         'RBSP EMFISIS configuration Directory', $
                         readme_txt, 1, /restrict_os)
  Endelse

End
