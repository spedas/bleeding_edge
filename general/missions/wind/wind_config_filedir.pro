;+
;Function: wind_config_filedir.pro
;Purpose: Get the applications user directory for THEMIS data analysis software
;
;$LastChangedBy: lphilpott $
;$LastChangedDate: 2012-06-21 16:18:22 -0700 (Thu, 21 Jun 2012) $
;$LastChangedRevision: 10610 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/wind/wind_config_filedir.pro $
;-
Function wind_config_filedir, app_query = app_query, _extra = _extra

  readme_txt = ['Directory for configuration files for use by ', $
                'the THEMIS Data Analysis Software']

  If(keyword_set(app_query)) Then Begin
    tdir = app_user_dir_query('wind', 'wind_config', /restrict_os)
    If(n_elements(tdir) Eq 1) Then tdir = tdir[0] 
    Return, tdir
  Endif Else Begin
    Return, app_user_dir('wind', 'WIND Configuration Process', $
                         'wind_config', $
                         'WIND configuration Directory', $
                         readme_txt, 1, /restrict_os)
  Endelse

End