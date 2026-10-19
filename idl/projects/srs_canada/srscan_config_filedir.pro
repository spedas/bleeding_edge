;+
;FUNCTION:
;   srscan_config_filedir
;
;PURPOSE:
;   Get the directory of the srs_canada configuration file
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2026-10-14 09:44:38 -0700 (Wed, 14 Oct 2026) $
;$LastChangedRevision: 34972 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/srs_canada/srscan_config_filedir.pro $
;-
function srscan_config_filedir, app_query=app_query, _extra=_extra

  readme_txt = ['Directory for configuration files for use by srs_canada']

  if keyword_set(app_query) then begin
    tdir = app_user_dir_query('srs_canada', 'srscan_config', /restrict_os)
    if n_elements(tdir) eq 1 then tdir = tdir[0]
    return, tdir
  endif else begin
    return, app_user_dir('srs_canada', 'srs_canada Configuration', $
                         'srscan_config', $
                         'srs_canada configuration Directory', $
                         readme_txt, 1, /restrict_os)
  endelse

end
