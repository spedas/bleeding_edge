;+
; PROCEDURE: AKB_LOAD_ORB
; A sample program to load the Akebono/orbit data in txt, distributed
; from ISAS.
;

PRO akb_load_orb, source=source, $
        downloadonly=downloadonly, no_server=no_server, no_download=no_download, $
        verbose=verbose, trange=trange, $
        get_support_data=get_support_data

  ;Set up the structure including the local/remote data directories.
  source = file_retrieve( /struct )
  source.local_data_dir = root_data_dir()+'exosd/orb/'
  source.remote_data_dir = $
   'http://darts.isas.jaxa.jp/stp/data/exosd/orbit/daily/'
  
  ;Relative path with wildcards for data files
  pathformat = 'YYYYMM/EDyyMMDD.txt'
  
  ;Expand the wildcards in the relative file paths for designated
  ;time range, which is set by "timespan".
  relpathnames = file_dailynames(file_format=pathformat)
  
  ;Check the time stamps and download data files if they are newer
  if keyword_set(downloadonly) then source.downloadonly=1
  if keyword_set(no_server)    then source.no_server=1
  if keyword_set(no_download)  then source.no_download=1
  if keyword_set(verbose) then source.verbose=verbose
  if keyword_set(trange) and n_elements(trange) eq 2 then timespan, time_double(trange)

  files = file_retrieve(relpathnames, _extra=source, /last_version)
  if keyword_set(downloadonly) then return 

  ;Exit unless data files are downloaded or found locally.
  idx = where( file_test(files) )
  if idx[0] eq -1 then begin
    message, /cont, 'No data file is found in the local repository for the designated time range!'
    return
  endif
  existing_files = files[idx] & files = existing_files 

  ; Read txt files and deduce data as tplot variables
  akb_str2tplot,files
   
;  cdf2tplot,file=files,verbose=source.verbose,prefix=prefix
  
  
  
  return
end

