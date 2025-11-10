;+
;
; spp_fld_most_recent_mde
;
; short functon to find the most recent MDE file available
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2025-11-04 11:26:44 -0800 (Tue, 04 Nov 2025) $
; $LastChangedRevision: 33821 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/util/spp_fld_most_recent_mde.pro $
;-

function spp_fld_most_recent_mde
  compile_opt idl2

  spp_dir = getenv('MOC_SELECT_RSYNC_DIR') + '/'

  if spp_dir eq '/' then spp_dir = getenv('SSL_MOC_SERVER_DIR')

  if file_test(spp_dir) then begin
    cd, spp_dir + 'mission_design_events/', current = old_dir

    mde_file = file_search('*.mde.txt', /fully_qualify_path, count = n_mde_files)

    most_recent_mde = ''
    most_recent_mde_time = 0

    for i = 0, n_mde_files - 1 do begin
      if file_modtime(mde_file[i]) gt most_recent_mde_time then begin
        most_recent_mde = mde_file[i]

        most_recent_mde_time = file_modtime(mde_file[i])
      endif
    endfor

    ; print, most_recent_mde

    cd, old_dir
  endif else begin
    slash = path_sep()
    sep = path_sep(/search_path)

    dirs = ['.', strsplit(!path, sep, /extract)]

    csv_path = file_search(dirs + slash + 'spp.mde.txt')

    most_recent_mde = csv_path[0]
  endelse

  return, most_recent_mde
end
