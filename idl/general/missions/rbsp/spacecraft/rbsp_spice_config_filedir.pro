;+
;Function: rbsp_spice_config_filedir.pro
;Purpose: Get the applications user directory for RBSP SPICE data analysis software
;
;$LastChangedBy: peters $
;$LastChangedDate: 2012-11-07 15:36:17 -0800 (Wed, 07 Nov 2012) $
;$LastChangedRevision: 11202 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/spacecraft/rbsp_spice_config_filedir.pro $
;-

Function rbsp_spice_config_filedir, app_query = app_query, _extra = _extra

  readme_txt = ['Directory for configuration files for use by ', $
                'the RBSP SPICE Data Analysis Software']

  If(keyword_set(app_query)) Then Begin
    tdir = app_user_dir_query('rbsp_spice', 'rbsp_spice_config', /restrict_os)
    If(n_elements(tdir) Eq 1) Then tdir = tdir[0] 
    Return, tdir
  Endif Else Begin
    Return, app_user_dir('rbsp_spice', 'RBSP SPICE Configuration Process', $
                         'rbsp_spice_config', $
                         'RBSP SPICE configuration Directory', $
                         readme_txt, 1, /restrict_os)
  Endelse

End
