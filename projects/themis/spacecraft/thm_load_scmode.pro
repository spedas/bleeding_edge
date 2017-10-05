;+
;Procedure: THM_LOAD_SCMODE,
; thm_load_scmode, datatype = datatype, $
;                  probe = probe, $
;                  trange = trange, $
;                  verbose = verbose, $
;                  varname_out = varname_out, $
;                  downloadonly = downloadonly, $
;                  no_download=no_download,
;                  relpathnames_all=relpathnames_all,$
;                  files=files,$
;                  valid_names = valid_names,$
;                  suffix=suffix
;                
;Purpose:
;  Loads spacecraft mode data from CDF.  Quantities for each mode will have a 0 at the beginning
;  and end of each interval where a mode is off and a 1 at the beginning and end of each interval
;  where a mode is on.
;  
;keywords:
;  probe = The probe to be loaded. Can be 'a','b','c','d','e'
;  datatype = The type of data to be loaded. Can be 'ss','fs','pb','wb',or 'all'
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
;
;  no_time_clip=no_time_clip, unlike other routines, no_time_clip is set by default, because clipping causes errors due to the way
;             that scmode data is stored. To enable time clipping, call thm_load_scmode,no_time_clip=0
;
;Examples:
;   timespan,'2007-03-23'
;   thm_load_scmode
;   thm_load_scmode,probe='a',trange=['2007-01-22/00:00:00','2007-01-24/00:00:00']
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2015-04-30 15:28:49 -0700 (Thu, 30 Apr 2015) $
; $LastChangedRevision: 17458 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/thm_load_scmode.pro $
;-

function thm_load_scmode_relpath,trange=trange,probe=probe

  compile_opt idl2,hidden

  relpath = 'th'+probe+'/l1/scmode/'
  prefix = 'th'+probe+'_l1_scmode_'
  ending = '_v01.cdf'
  for i = 0,n_elements(probe)-1 do begin
    pathlist = array_concat(file_dailynames(relpath[i],prefix[i],ending,/yeardir,trange=trange),pathlist)
  endfor
  
  return,pathlist

end

pro thm_load_scmode, datatype = datatype,$
                trange = trange, $
                verbose = verbose, $
                probe=probe,$
                varname_out = tplotnames, $
                downloadonly = downloadonly, $
                no_download=no_download,$
                level=level,$
                relpathnames_all=relpathnames_all,$
                files=files,$
                valid_names = valid_names,$
                suffix=suffix, $
                no_time_clip = no_time_clip
       
  compile_opt idl2
                
  if arg_present(relpathnames_all) then begin
     downloadonly=1
     no_download=1
  end
  
  if ~keyword_set(suffix) then suffix = ''
    
  vprobes = ['a','b','c','d','e']
  vdatatypes = ['ss','fs','pb','wb','ufs']
  vlevels = 'l1'
  
  if keyword_set(valid_names) then begin
    datatype = vdatatypes
    level = vlevels
    probe = vprobes
    return
  endif
  
  if ~keyword_set(datatype) then begin
    datatype = 'all'
  endif
  
  if ~keyword_set(probe) then begin
    probe = 'all'
  endif
  
  if n_elements(no_time_clip) eq 0 then begin
    no_time_clip = 1
  endif
  
  dt = strlowcase(ssl_check_valid_name(datatype,vdatatypes,/include_all,/ignore_case))
  
  if ~keyword_set(dt) then return
  
  if is_num(probe) then begin
    prb = thm_probe_num(probe)
  endif else begin
    prb = strlowcase(ssl_check_valid_name(probe,vprobes,/include_all,/ignore_case))
  endelse
  
  if ~keyword_set(prb) then return
     
  if arg_present(relpathnames_all) then begin
    relpathnames_all = thm_load_scmode_relpath(trange=trange,probe=prb) 
    return
  endif
  
  for i = 0,n_elements(prb)-1 do begin
  
    names = 'th'+prb[i]+'_scmode_'+dt
    
    relpathnames_all = thm_load_scmode_relpath(trange=trange,probe=prb[i]) 
    
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
  
    if keyword_set(tplotnames) then begin
      options,tplotnames,yrange=[-1,2]
      if ~keyword_set(no_time_clip) then begin
        If(keyword_set(trange) && n_elements(trange) Eq 2) $
          Then tr = timerange(trange) Else tr = timerange()
        for ivar = 0, n_elements(tplotnames)-1 do begin
          if tnames(tplotnames[ivar]) eq '' then continue
          time_clip, tplotnames[ivar], min(tr), max(tr), /replace, error = tr_err
          if tr_err then del_data, tplotnames[ivar]
        endfor
      endif
    endif
  endfor
               
end
