;+
;Function: 
;    secs_config_filedir.pro
;    
;Purpose: 
;    Get the directory of the Spherical Elementary Currents SECS configuration file
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2014-09-18 13:30:13 -0700 (Thu, 18 Sep 2014) $
;$LastChangedRevision: 15821 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/eic/eic_config_filedir.pro $
;-
Function secs_config_filedir, app_query = app_query, _extra = _extra

  readme_txt = ['Directory for configuration files for use by SECS']

  If(keyword_set(app_query)) Then Begin
    tdir = app_user_dir_query('secs', 'secs_config', /restrict_os)
    If(n_elements(tdir) Eq 1) Then tdir = tdir[0] 
    Return, tdir
  Endif Else Begin
    Return, app_user_dir('secs', 'secs Configuration', $
                         'secs_config', $
                         'secs configuration Directory', $
                         readme_txt, 1, /restrict_os)
  Endelse

End