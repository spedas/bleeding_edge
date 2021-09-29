;+
;Procedure:
;           ts07_local_dir_check
;
;Purpose:
;           Check to see if SPEDAS configuration directory for downloaded TS07 coefficient files needs to be created
;
;
;           http://themis.ssl.berkeley.edu/data/themis/spedas/geopack/tailpar/
;           http://themis.ssl.berkeley.edu/data/themis/spedas/geopack/spdf/
;
;Keywords:
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2021-07-28 18:16:15 -0700 (Wed, 28 Jul 2021) $
; $LastChangedRevision: 30156 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/ts07/ts07_local_dir_check.pro $
;-

pro ts07_local_dir_create, dir=dir
  ; Create local directory for parameter files
  if ~keyword_set(dir) then begin
    cdfdir = !spedas.temp_cdf_dir
    if cdfdir eq '' then begin
      spedas_init, reset=1
      dir = !spedas.temp_cdf_dir
    endif else begin
      dir = spd_string_replacen(cdfdir, 'cdaweb', 'geopack_par')
      if strmid(dir, 0,1, /reverse_offset) ne path_sep() then dir += path_sep()
      if ~STRMATCH(dir, '*geopack_par*' , /FOLD_CASE ) then dir = dir + 'geopack_par' + path_sep()
    endelse
  endif
  FILE_MKDIR, dir
  !spedas.geopack_param_dir = dir
  spedas_write_config
end

pro ts07_local_dir_check,local_dir=local_dir
  ; Check if local geopack parameters dir is defined
  ; if it is not, then define it
  spedas_init
  
  if undefined(local_dir) then begin   
     local_dir=!spedas.geopack_param_dir
     if local_dir eq '' then begin
       print, 'Directory for Geopack parameters is not specified. It will be created.'
       ts07_local_dir_create
     endif 
  endif else begin
     result = FILE_TEST(local_dir, /DIRECTORY)
     if result ne 1 then begin
        print, 'Directory for Geopack parameters does not exist. It will be created.'
        ; Don't disturb any existing !spedas.geopack_param_dir setting
       file_mkdir,local_dir
     endif
  endelse

end
