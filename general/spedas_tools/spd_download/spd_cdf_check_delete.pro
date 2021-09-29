;+
;NAME:
;   spd_cdf_check_delete
;
;PURPOSE:
;   Renames or deletes cdf or netcdf files, if they can't be opened.
;   This fuction can be used to cleanup downloaded files with problems.
;   By default, the files are renamed to: filename + '.todelete'
;
;INPUT:
;   filenames: Array of cdf or netcdf filenames (full path).
;   (filename extension is expected to be '.nc' for netcdf and '.cdf' for cdf files)
;
;KEYWORDS:
;   iscdf: Force cdf check.
;   isnetcdf: Force netcdf check.
;   (if both keywords are used, netcdf will be prefered)
;   delete_file: The file will be deleted.
;
;OUTPUT:
;   Array of renamed or deleted files.
;   Renamed files have the file extension '.todelete'.
;
;EXAMPLES:
;   deleted_files = spd_cdf_check_delete(["file1.cdf", "file2.nc"], /delete)
;
;
;HISTORY:
;$LastChangedBy: nikos $
;$LastChangedDate: 2021-06-10 14:39:13 -0700 (Thu, 10 Jun 2021) $
;$LastChangedRevision: 30039 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/spd_download/spd_cdf_check_delete.pro $
;
;-------------------------------------------------------------------

function spd_cdf_check_delete, filenames, iscdf=iscdf, isnetcdf=isnetcdf, delete_file=delete_file

  compile_opt idl2

  ; output is the list of renamed or deleted files
  deleted_files = []

  ; if 'iscdf' is set, force cdf check
  if keyword_set(iscdf) then cdfornetcdf=1
  if keyword_set(isnetcdf) then cdfornetcdf=2

  for fileindex = 0, n_elements(filenames)-1 do begin

    nfile = filenames[fileindex]

    ; check if file exists
    if ~file_test(nfile , /read) then begin
      dprint, dlevel=1, 'spd_cdf_check_delete: Cannot find file: ', nfile
      continue
    endif

    ; check if filename is .cdf or .nc
    if ~keyword_set(cdfornetcdf) && (strlen(nfile) ge 4) then begin
      last3let = strlowcase(strmid(nfile, 2, 3, /reverse_offset))
      last4let = strlowcase(strmid(nfile, 3, 4, /reverse_offset))
      if last3let eq '.nc' then begin
        cdfornetcdf = 2
      endif else if last4let eq '.cdf' then begin
        cdfornetcdf = 1
      endif
    endif

    ; handle file opening errors
    count = 0
    catch, ferror
    if ferror ne 0 then begin
      count++;
      if count ge 2 then begin
        deleted_files = [deleted_files, nfile]
        dprint, dlevel=1, 'spd_cdf_check_delete: ', !ERROR_STATE.MSG
        catch, /cancel
        continue
      endif
      dprint, dlevel=1, 'spd_cdf_check_delete: Error while attempting to open file: ', !ERROR_STATE.MSG
      if keyword_set(delete_file) then begin
        ; delete file
        if float(!version.release) ge float('8.4') then begin ;for newer versions, move to recycle bin
          file_delete, nfile, /allow_nonexistent, /quiet, /recycle, /noexpand_path, /verbose
        endif else file_delete, nfile, /allow_nonexistent, /quiet, /noexpand_path, /verbose
      endif else begin
        ; rename file
        nfile_renamed = nfile + '.todelete'
        file_move, nfile, nfile_renamed, /overwrite, /noexpand_path, /verbose
        nfile = nfile_renamed
      endelse
      dprint, dlevel=1, 'spd_cdf_check_delete: The following file was removed and you need to download it again: ', nfile
      deleted_files = [deleted_files, nfile]
      catch, /cancel
      continue
    endif

    ; check if file can be opened (cdf or netcdf)
    if ~keyword_set(cdfornetcdf) then begin
      dprint, dlevel=5, 'spd_cdf_check_delete: Warning. Could not determine if this is cdf or netcdf file: ', nfile
    endif else begin
      if cdfornetcdf eq 1 then begin
        ; cdf file
        id = cdf_open(nfile, /readonly)
        cdf_close, id
      endif else if cdfornetcdf eq 2 then begin
        ; netcdf file
        id = ncdf_open(nfile, /nowrite)
        ncdf_close, id
      endif
    endelse

  endfor

  return, deleted_files
end