;+
;Procedure:
;           ts07_download
;
;Purpose:
;           Downloads all parameter files
;
;           http://themis.ssl.berkeley.edu/data/themis/spedas/geopack/tailpar/
;           http://themis.ssl.berkeley.edu/data/themis/spedas/geopack/spdf/
;
;Keywords:
;          dir (optional): the directory where the files will be stored
;          year (optional): the year of
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2021-07-28 18:16:15 -0700 (Wed, 28 Jul 2021) $
; $LastChangedRevision: 30156 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/ts07/ts07_download.pro $
;-

pro ts07_get_files, local_dir=local_dir, years=years
  ; Return a list of ts07 parameter filenames

  if ~keyword_set(local_dir) then local_dir=!spedas.geopack_param_dir

  ; 1. Download all files from
  ; http://themis.ssl.berkeley.edu/data/themis/spedas/geopack/tailpar/
  remote_data_dir = "http://themis.ssl.berkeley.edu/data/themis/spedas/geopack/tailpar/"
  relpathnames = "*"
  files = spd_download(remote_file=relpathnames, remote_path=remote_data_dir,local_path = local_dir)

  ;  Disabling this code for now.  The year files cannot be used until code exists to generate the time-varying parameter files
  ;  from them.  JWL 2021-06-25 
  if 0 then begin
    ; 2. Download year files from
    ; http://themis.ssl.berkeley.edu/data/themis/spedas/geopack/spdf/

    remote_data_dir = "http://themis.ssl.berkeley.edu/data/themis/spedas/geopack/spdf/"
    if ~keyword_set(years) then begin
      relpathnames = "*"
      files2 = spd_download(remote_file=relpathnames, remote_path=remote_data_dir,local_path = local_dir)
    endif else begin
      for i=0, n_elements(years)-1 do begin
        relpathnames = "*" + strtrim(years[i],2) + "*"
        files2 = spd_download(remote_file=relpathnames, remote_path=remote_data_dir,local_path = local_dir)
      endfor
    endelse
    all_files = [files, files2]
  endif

  print, "Files downloaded: ", files
  
end



pro ts07_download, local_dir=local_dir, years=years

  COMPILE_OPT IDL2, hidden
  
  if ts07_supported() eq 0 then return

  ; Check if local directory exists
  ts07_local_dir_check,local_dir=local_dir

  ; Get a list of parameter filenames
  ts07_get_files, local_dir=local_dir, years=years

end