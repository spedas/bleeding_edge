;+
;NAME:
;   icon_netcdf2tplot
;
;PURPOSE:
;   Load files into tplot
;
;KEYWORDS:
;   filenames: array of filenames
;
;HISTORY:
;$LastChangedBy: nikos $
;$LastChangedDate: 2020-02-21 13:53:53 -0800 (Fri, 21 Feb 2020) $
;$LastChangedRevision: 28326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/icon/load/icon_netcdf2tplot.pro $
;
;-------------------------------------------------------------------

pro icon_netcdf2tplot, filenames

  files = []
  for i=0, n_elements(filenames)-1 do begin
    f = filenames[i]
    result = file_test(f, /read)
    if result then begin
      files = [files, f]
    endif else begin
      dprint, "File cannot be found: " + f
    endelse
  endfor

  if n_elements(files) gt 0 then begin
    netcdf_struct = icon_netcdf_load_vars(files)
    cdf_struct = icon_struct_to_cdfstruct(netcdf_struct)
    cdf_info_to_tplot, cdf_struct, verbose = verbose, prefix=prefix, suffix=suffix
  endif

end