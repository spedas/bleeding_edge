;+
;Function: goes_config_filedir.pro
;Purpose: Get the applications user directory for SPEDAS
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2014-03-20 14:33:46 -0700 (Thu, 20 Mar 2014) $
;$LastChangedRevision: 14616 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/goes/goes_config_filedir.pro $
;-

Function goes_config_filedir, app_query = app_query, _extra = _extra

  readme_txt = ['Directory for configuration files for use by ', $
                'the SPEDAS']

  If(keyword_set(app_query)) Then Begin
    tdir = app_user_dir_query('goes', 'goes_config', /restrict_os)
    If(n_elements(tdir) Eq 1) Then tdir = tdir[0] 
    Return, tdir
  Endif Else Begin
    Return, app_user_dir('goes', 'SPEDAS Configuration', $
                         'goes_config', $
                         'SPEDAS configuration Directory', $
                         readme_txt, 1, /restrict_os)
  Endelse

End
