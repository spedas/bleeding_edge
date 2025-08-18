;+
;NAME:
;   icon_config_filedir
;
;PURPOSE:
;   Get the user directory for ICON
;
;KEYWORDS:
;
;
;HISTORY:
;$LastChangedBy: nikos $
;$LastChangedDate: 2018-05-10 10:41:33 -0700 (Thu, 10 May 2018) $
;$LastChangedRevision: 25192 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/icon/config/icon_config_filedir.pro $
;
;-------------------------------------------------------------------


function icon_config_filedir, app_query = app_query, _extra = _extra

  readme_txt = ['Directory for configuration files for use by ICON']

  If(keyword_set(app_query)) Then Begin
    tdir = app_user_dir_query('icon', 'icon_config', /restrict_os)
    If(n_elements(tdir) Eq 1) Then tdir = tdir[0] 
    Return, tdir
  Endif Else Begin
    Return, app_user_dir('icon', 'ICON Configuration', $
                         'icon_config', $
                         'ICON configuration Directory', $
                         readme_txt, 1, /restrict_os)
  Endelse

End


