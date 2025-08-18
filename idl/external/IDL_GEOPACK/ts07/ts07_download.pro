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
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2023-02-03 10:40:56 -0800 (Fri, 03 Feb 2023) $
; $LastChangedRevision: 31468 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/ts07/ts07_download.pro $
;-

pro ts07_get_files, local_dir=local_dir
  ; Return a list of ts07 parameter filenames

  if ~keyword_set(local_dir) then local_dir=!spedas.geopack_param_dir

  ; 1. Download all files from
  ; http://themis.ssl.berkeley.edu/data/themis/spedas/geopack/tailpar/
  remote_data_dir = "http://themis.ssl.berkeley.edu/data/themis/spedas/geopack/tailpar/"
  relpathnames = "*"
  files = spd_download(remote_file=relpathnames, remote_path=remote_data_dir,local_path = local_dir)

  print, "Files downloaded: ", files
  
end



pro ts07_download, local_dir=local_dir

  COMPILE_OPT IDL2, hidden
  
  if ts07_supported() eq 0 then return

  ; Check if local directory exists
  ts07_local_dir_check,local_dir=local_dir

  ; Get a list of parameter filenames
  ts07_get_files, local_dir=local_dir

end