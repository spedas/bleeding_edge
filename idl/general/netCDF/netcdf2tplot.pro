;+
; Procedure:    netcdf2tplot
; 
; Input:
;         files: netCDF files to be loaded
;
; Keywords:
;         prefix:  GOES spacecraft prefix, typically g[sc #], i.e., g15 for GOES-15
;         suffix: string to append to the end of the loaded tplot variables
;         verbose: request more verbose output
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2014-02-06 12:12:12 -0800 (Thu, 06 Feb 2014) $
; $LastChangedRevision: 14177 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/netCDF/netcdf2tplot.pro $
;-

pro netcdf2tplot, files, prefix = prefix, suffix = suffix, verbose = verbose
    ; check that netCDF is supported
    if ncdf_exists() eq 0 then begin
      dprint, 'netCDF not supported by the current IDL installation.'
      return
    endif
    
    ; load the netCDF file into an IDL struct
    ; this routine should work with any netCDF file,
    ; regardless of the format of the data
    netCDFi = netcdf_load_vars(files)
    if size(netCDFi, /type) ne 8 then begin
      dprint, dlevel = 0, 'netCDFi was invalid. Trouble loading the netCDF file into an IDL structure.'
      return
    endif
    
    ; change the previously created struct into
    ; a struct readable by cdf_info_to_tplot
    cdf_struct = GOESstruct_to_cdfstruct(netCDFi)
    if size(cdf_struct, /type) ne 8 then begin
      dprint, dlevel = 0, 'cdf_struct was invalid. Trouble converting the netCDF IDL structure into a standard CDF structure.'
      return
    endif
    
    ; create tplot variables from the struct
    cdf_info_to_tplot, cdf_struct, verbose = verbose, prefix=prefix, suffix=suffix
    
end
