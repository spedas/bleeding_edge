;+
;Function: omni_config_filedir.pro
;Purpose: Get the applications user directory for OMNI data
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-06-19 19:25:49 -0700 (Fri, 19 Jun 2015) $
;$LastChangedRevision: 17928 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/omni/omni_config_filedir.pro $
;-
Function omni_config_filedir, app_query = app_query, _extra = _extra

  readme_txt = ['Directory for configuration files for use by ', $
                'the SPEDAS Data Analysis Software']

  If(keyword_set(app_query)) Then Begin
    tdir = app_user_dir_query('omni', 'omni_config', /restrict_os)
    If(n_elements(tdir) Eq 1) Then tdir = tdir[0] 
    Return, tdir
  Endif Else Begin
    Return, app_user_dir('omni', 'OMNI Configuration', $
                         'omni_config', $
                         'omni configuration Directory', $
                         readme_txt, 1, /restrict_os)
  Endelse

End
