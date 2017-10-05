;+
;Function: spedas_config_filedir.pro
;Purpose: Get the applications user directory for SPEDAS data analysis software
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-12-03 13:50:06 -0800 (Thu, 03 Dec 2015) $
;$LastChangedRevision: 19523 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/misc/spedas_config_filedir.pro $
;-
Function spedas_config_filedir, app_query = app_query, _extra = _extra

  readme_txt = ['Directory for configuration files for use by ', $
    'the SPEDAS Data Analysis Software']

  If(keyword_set(app_query)) Then Begin
    tdir = app_user_dir_query('spedas', 'spedas_config', /restrict_os)
    If(n_elements(tdir) Eq 1) Then tdir = tdir[0]
    Return, tdir
  Endif Else Begin
    Return, app_user_dir('spedas', 'SPEDAS Configuration Process', $
      'spedas_config', $
      'SPEDAS configuration Directory', $
      readme_txt, 1, /restrict_os)
  Endelse

End
