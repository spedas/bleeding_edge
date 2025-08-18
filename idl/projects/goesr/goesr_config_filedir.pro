;+
; Function:
;       goesr_config_filedir.pro
;
; Purpose:
;       Get the applications user directory for SPEDAS
;
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2020-12-21 10:57:20 -0800 (Mon, 21 Dec 2020) $
; $LastChangedRevision: 29545 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/goesr/goesr_config_filedir.pro $
;-

function goesr_config_filedir, app_query = app_query, _extra = _extra

  compile_opt idl2

  readme_txt = ['Directory for configuration files for use by SPEDAS']

  if (keyword_set(app_query)) then begin
    tdir = app_user_dir_query('goesr', 'goesr_config', /restrict_os)
    if (n_elements(tdir) Eq 1) then tdir = tdir[0]
    return, tdir
  endif else begin
    return, app_user_dir('goesr', 'SPEDAS Configuration', 'goesr_config', 'SPEDAS configuration Directory', readme_txt, 1, /restrict_os)
  endelse

end
