;+
;Procedure: THM_LOAD_PSEUDOAE,
; thm_load_pseudoAE, datatype = datatype, trange = trange, $
;                verbose = verbose, $
;                varname_out = varname_out, $
;                downloadonly = downloadonly, $
;                no_download=no_download,
;                relpathnames_all=relpathnames_all,$
;                files=files,$
;                valid_names = valid_names,$
;                suffix=suffix
;                
;Purpose:
;  loads pregenerated Pseudo AE,AU,AL from CDF.  These are called "Pseudo" because
;  while they use the same algorithm as the global AE,AU,AL, they are generated
;  only from THEMIS GMAGs and thus represent, only a sampling of the Northern Hemisphere
;  
;  
;keywords:
;  datatype = The type of data to be loaded. Can be 'al','au','ae', or 'all'
;  TRANGE= (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded
;   level = ignored, only one level for this datatype: L1
;  /VERBOSE : set to output some useful info
;  varname_out= a string array containing the tplot variable names for
;               the loaded data
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  /no_download: use only files which are online locally.
;  relpathnames_all: named variable in which to return all files that are
;          required for specified timespan, probe, datatype, and level.
;          If present, no files will be downloaded, and no data will be loaded.
;  files   named varible for output of pathnames of local files.
;  /valid_names, if set, then this will return the valid site, datatype
;                and/or level options in named variables, for example,
;                thm_load_gmag, site = xxx, /valid_names
;                will return the array of valid sites in the
;                variable xxx
;  suffix= suffix to add to output data quantity (not added to support data)

;Examples:
;   timespan,'2007-03-23'
;   thm_load_pseudoAE
;   thm_load_pseudoAE,datatype='AE',trange=['2007-01-22/00:00:00','2007-01-24/00:00:00']
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2015-04-30 15:28:49 -0700 (Thu, 30 Apr 2015) $
; $LastChangedRevision: 17458 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/ground/thm_load_pseudoae.pro $
;-

function thm_load_pseudoAE_relpath,trange=trange

  compile_opt idl2,hidden

  relpath = 'thg/l1/mag/idx/'
  prefix = 'thg_l1_idx_'
  ending = '_v01.cdf'
  return,file_dailynames(relpath,prefix,ending,/yeardir,trange=trange)

end

pro thm_load_pseudoAE, datatype = datatype, trange = trange, $
                verbose = verbose, $
                varname_out = tplotnames, $
                downloadonly = downloadonly, $
                no_download=no_download,$
                level=level,$
                relpathnames_all=relpathnames_all,$
                files=files,$
                valid_names = valid_names,$
                suffix=suffix
       
  compile_opt idl2
                
  if arg_present(relpathnames_all) then begin
     downloadonly=1
     no_download=1
  end
  
  if ~keyword_set(suffix) then suffix = ''
    
  vdatatypes = ['AE','AL','AU']
  vlevels = 'l1'
  
  
  if keyword_set(valid_names) then begin
    datatype = vdatatypes
    level = vlevels
    return
  endif
  
  if ~keyword_set(datatype) then begin
    datatype = 'all'
  endif
  
  datatype = strlowcase(ssl_check_valid_name(datatype,vdatatypes,/include_all,/ignore_case))
  
  if ~keyword_set(datatype) then return
    
  relpathnames_all = thm_load_pseudoAE_relpath(trange=trange) 
  
  if arg_present(relpathnames_all) then begin
    return
  endif
  
  names = 'thg_idx_'+datatype
  
 ;test for !themis, jmm, 6-aug-2009
  defsysv, '!themis', exists = exists
  if not keyword_set(exists) then thm_init

  params = !themis

  if n_elements(no_download) gt 0 then begin
    params.no_download = no_download
  endif
  
  if n_elements(downloadonly) gt 0 then begin
    params.downloadonly = downloadonly
  endif
  
  if n_elements(verbose) gt 0 then begin
    params.verbose = verbose
  endif
  
  files = spd_download(remote_file=relpathnames_all,_extra=params)

  if ~params.downloadonly then begin
    cdf2tplot,file=files,verbose=params.verbose,tplotnames=tplotnames,varformat=names
  endif
               
end
