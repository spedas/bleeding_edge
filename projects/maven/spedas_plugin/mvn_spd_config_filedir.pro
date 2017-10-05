;+
;Function: mvn_spd_config_filedir.pro 
;Purpose: Get the applications
;user directory for MAVEN SPD data analysis software
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2015-11-06 11:29:09 -0800 (Fri, 06 Nov 2015) $
;$LastChangedRevision: 19281 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/spedas_plugin/mvn_spd_config_filedir.pro $
;-

Function mvn_spd_config_filedir, app_query = app_query, _extra = _extra

  readme_txt = ['Directory for configuration files for use by ', $
                'the SPEDAS Software']

  If(keyword_set(app_query)) Then Begin
    tdir = app_user_dir_query('mvn_spd', 'mvn_spd_config', /restrict_os)
    If(n_elements(tdir) Eq 1) Then tdir = tdir[0] 
    Return, tdir
  Endif Else Begin
    Return, app_user_dir('mvn_spd', 'MAVEN SPD Configuration Process', $
                         'mvn_spd_config', $
                         'MAVEN SPD configuration Directory', $
                         readme_txt, 1, /restrict_os)
  Endelse

End
