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
; $LastChangedDate: 2021-10-05 12:01:41 -0700 (Tue, 05 Oct 2021) $
; $LastChangedRevision: 30336 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/hdf/hdf2tplot.pro $
;-

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

  ; Either merge multiple files or use the last available.
  if ~keyword_set(merge) then begin
    merge = 0
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
    endif else begin
      final_cdf_struct = cdf_struct
    endelse

  endforeach

  ; Create tplot variables from the structure.
  if size(final_cdf_struct, /type) eq 8 then begin
    cdf_info_to_tplot, final_cdf_struct, verbose = verbose, tplotnames=tplotnames, prefix=prefix, suffix=suffix
  endif
end