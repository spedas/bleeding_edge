;+
;NAME: barrel_config_filedir
;
;DESCRIPTION: Get the applications user directory for SPEDAS
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2014-10-29 11:36:02 -0700 (Wed, 29 Oct 2014) $
;$LastChangedRevision: 16081 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/barrel/barrel_config_filedir.pro $
;
;-


function barrel_config_filedir, app_query = app_query, _extra=_extra

  readme_txt = ['Directory for configuration files for use by SPEDAS']

  if (keyword_set(app_query)) then begin
    tdir = app_user_dir_query('barrel', 'barrel_config', /restrict_os)
    if (n_elements(tdir) EQ 1) then tdir = tdir[0]
    RETURN, tdir
  endif else begin
    RETURN, app_user_dir('barrel', 'SPEDAS Configuration',$
      'barrel_config', $
      'SPEDAS configureation directory',$
      readme_txt, 1, /restrict_os)
  endelse

END

