;+
; Procedure:
;         hdf2tplot
;
; Purpose:
;         Load HDF-5/netCDF-4 files into tplot
;
; Input:
;         filenames: files to be loaded into tplot
;         varnames: load only these varnames (if not defined, empty, '*', 'all': load all)
;         verbose: the verbose level
;         prefix, suffix: these are passed to cdf_info_to_tplot
;         gatt2istp: dictionary, mapping of HDF global attributes to ISTP global attributes
;         vatt2istp: dictionary, mapping of HDF variable attributes to ISTP variable attributes
;         coord_list: coordinate list, if set we get the coordinate system from the variable name;
;         time_var: name of the time variable
;                   default is 'time'
;         time_offset: time offset in miliseconds
;                   default is time_double('2000-01-01/12:00:00.000')
;
; Notes:
;     This format is used by GOES 16 and 17 and reprocessed files for GOES 8-15.
;     Uses the HDF5 IDL library.
;     HELP, 'hdf5', /DLM
;     https://www.l3harrisgeospatial.com/docs/hdf5_overview.html
;
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2024-06-08 13:38:44 -0700 (Sat, 08 Jun 2024) $
; $LastChangedRevision: 32690 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/hdf/hdf2tplot.pro $
;-

function hdf_merge_cdf_struct, cdf_struct, final_cdf_struct
  ; Merge cdf_struct into final_cdf_struct
  compile_opt idl2

  CATCH, err
  IF err NE 0 THEN BEGIN
    CATCH, /CANCEL
    PRINT, !ERROR_STATE.MSG
    RETURN, final_cdf_struct
  ENDIF

  if ~is_struct(final_cdf_struct) then begin
    return, cdf_struct
  endif
  if ~is_struct(cdf_struct) then begin
    return, final_cdf_struct
  endif

  a = final_cdf_struct
  a.filename = a.filename + "," + cdf_struct.filename

  for i=0,n_elements(a.vars)-1 do begin
    v = cdf_struct.vars[i]
    av = a.vars[i]
    if av.DATAPTR eq ptr_new() then continue else d1 = *(av.DATAPTR)
    if v.DATAPTR eq ptr_new() then continue else d2 = *(v.DATAPTR)
    if n_elements(d1.dim) eq 0 then d = d1
    if n_elements(d1.dim) eq 1 then d = [d1, d2]
    if n_elements(d1.dim) eq 2 then begin
      dd = d1.dim
      if dd[0] gt dd[1] then d = [d1, d2] else d = [[d1], [d2]]
    endif
    if n_elements(d1.dim) eq 3 then d = [[[d1]], [[d2]]]
    a.vars[i].dataptr = ptr_new(d)
  endfor

  return, a
end

pro hdf2tplot, filenames, tplotnames=tplotnames, varnames=varnames, merge=merge, prefix=prefix, suffix=suffix, verbose=verbose, $
  gatt2istp=gatt2istp, vatt2istp=vatt2istp, coord_list=coord_list, time_offset=time_offset, time_var=time_var, _extra=_extra

  compile_opt idl2
  ; Set verbose.
  vbs = keyword_set(verbose) ? verbose : 0

  ; Check if this is a valid file.
  if ~keyword_set(filenames) then begin
    msg = "hdf2tplot: No filename to load."
    dprint, dlevel=1, verbose=verbose, msg
    return
  endif

  filenames = filenames[sort(filenames)]

  ; Either merge multiple files or use the last available.
  if ~keyword_set(merge) then begin
    merge = 1
  endif

  ; Find which varnames to load.
  final_cdf_struct = ''
  if ~keyword_set(varnames) || varnames eq '' || varnames eq '*' || varnames eq 'all' then begin
    varnames = '*'
    if vbs ge 6 then dprint, verbose=verbose, dlevel=6, 'hdf2tplot: Will load all variables into an IDL structure.'
  endif

  foreach fname, filenames do begin
    ; load the HDF-5 file into an IDL structure
    hdfi = hdf_load_vars(fname, varnames=varnames, verbose=verbose, _extra=_extra)
    if size(hdfi, /type) ne 7 then begin
      msg = 'hdf2tplot: Cannot load HDF-5 file into an IDL structure: hdfi was invalid.'
      dprint, dlevel=1, verbose=verbose, msg
      continue
    endif

    ; Change the previously created struct into a struct readable by cdf_info_to_tplot.
    cdf_struct = hdf_to_cdfstruct(hdfi, fname, varnames=varnames, verbose=verbose, gatt2istp=gatt2istp, vatt2istp=vatt2istp, $
      coord_list=coord_list, time_offset=time_offset, time_var=time_var, _extra=_extra)
    if size(cdf_struct, /type) ne 8 then begin
      msg = 'hdf2tplot: Cannot convert the HDF-5 IDL structure into a CDF structure: cdf_struct was invalid.'
      dprint, dlevel=1, verbose=verbose, msg
      continue
    endif else if merge eq 1 then begin
      ; Merge all files
      final_cdf_struct = hdf_merge_cdf_struct(cdf_struct, final_cdf_struct)
    endif else begin
      final_cdf_struct = cdf_struct
    endelse

  endforeach

  ; Create tplot variables from the structure.
  if size(final_cdf_struct, /type) eq 8 then begin
    cdf_info_to_tplot, final_cdf_struct, verbose = verbose, tplotnames=tplotnames, prefix=prefix, suffix=suffix
  endif
end