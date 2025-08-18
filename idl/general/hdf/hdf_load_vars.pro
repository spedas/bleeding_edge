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
; $LastChangedDate: 2020-12-21 10:54:55 -0800 (Mon, 21 Dec 2020) $
; $LastChangedRevision: 29544 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/hdf/hdf_load_vars.pro $
;-

function hdf_load_vars, file, varnames=varnames, verbose=verbose, _extra=_extra

  compile_opt idl2
  ; Set verbose.
  vbs = keyword_set(verbose) ? verbose : 0
  ;file = 'C:\\work\\goes 16-17\\dn_magn-l2-hires_g16_d20200816_v1-0-1.nc'

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

  if ~keyword_set(varnames) || varnames eq '' || varnames eq '*' || varnames eq 'all' then begin
    H5_LIST, file, output=outlist
  endif else begin
    H5_LIST, file, filter=varnames, output=outlist
  endelse

  return, outlist
end