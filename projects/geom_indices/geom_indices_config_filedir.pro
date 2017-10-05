;+
;NAME: geom_indices_config_filedir
;
;DESCRIPTION: Get the applications user directory for SPEDAS
;
;REVISION HISTORY:
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2014-11-05 11:21:52 -0800 (Wed, 05 Nov 2014) $
;$LastChangedRevision: 16138 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/geom_indices/geom_indices_config_filedir.pro $
;-

function geom_indices_config_filedir, app_query = app_query, _extra=_extra

  readme_txt = ['Directory for configuration files for use by SPEDAS']

  if (keyword_set(app_query)) then begin
    tdir = app_user_dir_query('geom_indices', 'geom_indices_config', /restrict_os)
    if (n_elements(tdir) EQ 1) then tdir = tdir[0]
    RETURN, tdir
  endif else begin
    RETURN, app_user_dir('geom_indices', 'SPEDAS Configuration Process',$
      'geom_indices_config', $
      'THEMIS configureation directory',$
      readme_txt, 1, /restrict_os)
  endelse

END

