;+
; Function:
;         hdf_load_vars
;
; Purpose:
;         Load HDF-5 files into an IDL structure
;
; Input:
;         filename: file to be loaded
;
;
; Note: to browse a HDF-5 file, use:
;       r = H5_BROWSER(file)
;
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2026-10-15 18:38:10 -0700 (Thu, 15 Oct 2026) $
; $LastChangedRevision: 34986 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/hdf/hdf_load_vars.pro $
;-

function hdf_load_vars, file, varnames=varnames, verbose=verbose, _extra=_extra

  compile_opt idl2
  ; Set verbose.
  vbs = keyword_set(verbose) ? verbose : 0

  if file_test(file) eq 0 then begin
    msg = "Error hdf_load_vars: File not found: " + file
    dprint, dlevel=1, verbose=verbose, msg
    return, 0
  endif

  if ~H5F_IS_HDF5(file) then begin
    msg = "Error hdf_load_vars: This file is not a valid HDF-5 file: " + file
    dprint, dlevel=1, verbose=verbose, msg
    return, 0
  endif else begin
    msg = "Loading HDF-5 file: " + file
    dprint, dlevel=1, verbose=verbose, msg
  endelse

  if ~keyword_set(time_offset) then begin
    time_offset = time_double('2000-01-01/12:00:00.000')
  endif

  ; Parse once and select the union of patterns, preserving order and avoiding
  ; duplicate entries. Keep the file header even when no datasets match.
  load_all = n_elements(varnames) eq 0
  if ~load_all then load_all = total((varnames eq '') or (varnames eq '*') or (varnames eq 'all')) gt 0
  if load_all then begin
    H5_LIST, file, output=outlist
  endif else if n_elements(varnames) eq 1 then begin
    ; Preserve H5_LIST's existing scalar-filter semantics.
    H5_LIST, file, filter=varnames, output=outlist
  endif else begin
    H5_LIST, file, output=outlist
    keep = bytarr(n_elements(outlist[0, *]))
    keep[0] = 1b
    foreach pattern, varnames do keep = keep or strmatch(outlist[1, *], pattern)
    idx = where(keep, count)
    outlist = outlist[*, idx]
  endelse

  return, outlist
end