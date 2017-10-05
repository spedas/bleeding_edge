;+
;FUNCTION: IUG_LOAD_GMAG_WDC_QDDAYS
; function iug_load_gmag_wdc_qddays, $
;    trange=trange, $
;    verbose=verbose, $
;    downloadonly=downloadonly, $
;    no_download=no_download
;
;Purpose:
;  Load date list of International 5/10 quietest days
;  and International 5 disturbed days from WDC Kyoto.
;
;Keywords:
;  trange= (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full month, a full
;          month's data is loaded
;  /verbose : set to output some useful info
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  no_download: use only files which are online locally.
;
;Example:
;  THEMIS> timespan, '2001-1-1'
;  THEMIS> qdays = iug_load_gmag_wdc_qddays(/no_download)
;  THEMIS> help, qdays, /str
;  QDAYS            INT       = Array[12, 12]
;  THEMIS> print, qdays[0,*]
;   2001       1       1      30       6       2      19      18      27       7       5       9
;
;Notes:
;  International Q-Days and D-Days are now derived by
;  GeoForschungsZentrum (GFZ) Potsdam from Kp index.
;  reference: http://wdc.kugi.kyoto-u.ac.jp/qddays/index.html
;
;Written by:  Daiki Yoshida,  Aug 2010
;Last Updated:  Daiki Yoshida,  Jan 11, 2010
; 
;-

function iug_load_gmag_wdc_qddays, $
   trange=trange, $
   verbose=verbose, $
   downloadonly=downloadonly, $
   no_download=no_download
    
  if ~keyword_set(verbose) then verbose=2
  
  ; bad data
  missing_value = 9999
  
  
  relpathnames = $
     file_dailynames('day/qddays/', 'qd', file_format='YYYY', trange=trange, /unique)
  print,relpathnames

    ; define remote and local path information
  source = file_retrieve(/struct)
  source.verbose = verbose
  source.local_data_dir = root_data_dir() + 'iugonet/wdc_kyoto/geomag/'
  source.remote_data_dir = 'http://wdc-data.iugonet.org/data/'
  if (keyword_set(no_download)) then source.no_server = 1
    
  ; download data
  local_files = spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir, local_path=source.local_data_dir, _extra=source, /last_version)
  print, local_files
  if keyword_set(downloadonly) then return, 0
    
    
  ; clear data and time buffer
  buf = 0

  elemlist = ''
  elemnum = -1
  elemlength = 0
    
  ; scan data length
  for j=0l, n_elements(local_files)-1 do begin
     file = local_files[j]
      
     if file_test(/regular,file) then begin
        dprint, 'Loading data file: ', file
        fexist = 1
     endif else begin
        dprint, 'Data file ', file, ' not found. Skipping'
        continue
     endelse
      
     ; read data
     openr, lun, file,/get_lun
     while (not eof(lun)) do begin
        line=''
        readf,lun,line
        
        if ~ keyword_set(line) then continue
        ;dprint,line,dlevel=5
        
        year = fix(strmid(line,0,4))
        month = fix(strmid(line,5,2))
        qd1 = fix(strmid(line, indgen(5)*2 + 8, 2))
        qd2 = fix(strmid(line, indgen(5)*2 + 19 ,2))
        dds = fix(strmid(line, indgen(5)*2 + 30 ,2))

        ;dprint, year,month,qd1,qd2,dds
        append_array, buf, [year,month,qd1,qd2]

     endwhile
     free_lun,lun
  endfor
    
  n = n_elements(buf) / 12 
  if n ne 0 then begin
     return, reform(buf, 12, n)
  endif else begin
     dprint, 'no qddata found.'
     return, 0
  endelse

end
