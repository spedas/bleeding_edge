;+
;Name:
;KYOTO_LOAD_DST
;
;Purpose:
;  Queries the Kyoto servers for DST data and loads data into
;  tplot format.  Adapted from KYOTO_AE2TPLOT.PRO.
;
;Syntax:
;  kyoto_load_dst [ ,TRANGE = TRANGE ]
;                  [ ,FILENAMES ]
;                  [ ,< and data keywords below > ]
;
;Keywords:
;  TRANGE (In):
;    Pass a time range a la TIME_STRING.PRO.
;  FILENAMES (In):
;    * PRESENTLY DISABLED * Pass user-defined file names (full paths to local data files).  These will
;      be read a la the Kyoto format, and the Kyoto server will not be queried.
;  DSTDATA, DSTTIME (Out):  Get 'dst' data, time basis in an array.
;  no_server: set this keyword to use only locally available data files (i.e. don't connect to Kyoto server)
;  dst_minutes: set the time for the hourly average at this time point. Default is 30.
;
;Code:
;W.M.Feuerstein, 5/15/2008.
;
;Modifications:
;  Changed file format of name (kyoto_dst_YYYY_MM.dat to kyoto_dst_YYYYMM.dat),
;    changed "DST" references to "DST", updated doc'n, WMF, 4/17/2008.
;  Saved new version under new name (old name was KYOTO_DST_LOAD), added
;    DATATYPE kw, validate and loop on datatypes, hardwired /DOWNLOADONLY,
;    up'd data kwd's, up'd doc'n, WMF, 5/15/2008.
;  Tested that the software defaults to local data when ther internet is not
;    available even with /DOWNLOADONLY (yes), added acknowledgement and
;    warning banner, added 'ax' datatype, WMF, 5/19/2008.
;  Changed name from KYOTO_DST2TPLOT.PRO to KYOTO_LOAD_DST.PRO, added
;    VERBOSE kw, added acknowledgement to DLIMITS structure, updated print, and
;    header acknowledgement, WMF, 7/23/08.
;  Changed acknowledgment as per Andreas Keiling, WMF, 8/4/2008.
;  YTITLE reflects whether Provisional or RT data, WMF, 8/12/2008.
;  YTITLE now set by file data (not kw), WMF, 8/15/2008.
;  Updated doc'n, WMF, 8/25/2008.
;  Adding final data, no_server keyword, apply_time_clip keyword, fixed problem with trange not working, lphilpott oct-2011
;
;Acknowledgment:
;  The DST data are provided by the World Data Center for Geomagnetism, Kyoto,  and
;  are not for redistribution (http://wdc.kugi.kyoto-u.ac.jp/). Furthermore, we thank
;  the geomagnetic observatories (Kakioka [JMA], Honolulu and San Juan [USGS], Hermanus
;  [RSA], Alibag [IIG]), NiCT, INTERMAGNET, and many others for their cooperation to
;  make the Dst index available.
;
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-

pro kyoto_load_dst ,trange=trange, $
  verbose=verbose, $
  ;filenames=fns, $         ;Do not pounce on FILENAMES.
  dstdata=alldst, $
  dsttime=alldsttime, $
  datatype=datatype, $     ;Input/output -- will clean inputs or show default.
  ;source=source
  no_server=no_server, $ ;This functions the same as a no_download (obsolete) keyword would 
  apply_time_clip=apply_time_clip, $ ; This clips the tplot variable to the time specified in trange (this is not necessary if time specified using timespan.
  dst_minutes=dst_minutes, $ ; The average is for a full hour, and the measurement point will be set at dst_minute. Default is 30.  
  local_data_dir=local_data_dir, $
  remote_data_dir = remote_data_dir
  
  
  compile_opt idl2

;**************************
;Load 'remote_data_dir' default:
;**************************
if ~keyword_set(remote_data_dir) then remote_data_dir='http://wdc.kugi.kyoto-u.ac.jp/'  
if STRLEN(remote_data_dir) gt 0 then if STRMID(remote_data_dir, STRLEN(remote_data_dir)-1, 1) ne "/" then remote_data_dir = remote_data_dir + "/"

;**************************
;Load 'local_data_dir' default:
;**************************
if ~keyword_set(local_data_dir) then local_data_dir=root_data_dir() + 'geom_indices' + path_sep()
if STRLEN(local_data_dir) gt 0 then if STRMID(local_data_dir, STRLEN(local_data_dir)-1, 1) ne path_sep() then local_data_dir = local_data_dir + path_sep()

;******************
;VERBOSE kw defaut:
;******************
if ~keyword_set(verbose) then verbose=2


;**************************
;Load 'dst' data by default:
;**************************
if ~keyword_set(datatype) then datatype='dst'

; Minutes for the tplot time of the dst measurements.
if ~keyword_set(dst_minutes) then dst_minutes = '30'
if dst_minutes gt 59 || dst_minutes lt 0 then dst_minutes = '30' 
dst_minutes = strmid('00' + strtrim(string(dst_minutes), 2), 1, 2, /reverse_offset)


;*****************
;Validate dataypes:
;*****************
vns=['dst']
if size(datatype,/type) eq 7 then begin
  dt = datatype
  if(size(datatype, /n_dim) ne 0) then dt = strcompress(dt, /remove_all) 
  vn = ['all',vns]
  otp = strfilter(vn, dt, delimiter = ' ', /string)
  if (size(otp, /type)) EQ 0 then return
  all = where(otp Eq 'all')
  if (all[0] ne -1) then datatype = vns else datatype = otp 
  if datatype[0] eq '' then return
endif else begin
  message,'DATATYPE kw must be of string type.',/info
  return
endelse


;Get timespan and define FILE_NAMES:
;===================================
If (keyword_set(trange) && n_elements(trange) Eq 2) then begin
  t = trange
endif else get_timespan,t

if ~size(fns,/type) then begin

  ;Get files for ith datatype:
  ;***************************
  file_names = file_dailynames(file_format='YYYYMM/',trange=t,times=times,/unique)+'index.html'
    
  source = file_retrieve(/struct)
  source.verbose=verbose  
  if keyword_set(no_server) then source.no_server=1
    
  ;Define FILE_RETRIEVE structure for Final data:
  ;====================================================
  source.local_data_dir = local_data_dir+ 'dst/'
  source.remote_data_dir = remote_data_dir + 'dst_final/'

  ;Get files and local paths, and concatenate local paths:
  ;=======================================================
  local_paths0=file_retrieve(file_names,_extra=source)

  ;Define FILE_RETRIEVE structure for Provisional data:
  ;====================================================
  source.remote_data_dir = remote_data_dir + 'dst_provisional/'

  ;Get files and local paths, and concatenate local paths:
  ;=======================================================
  local_paths1=file_retrieve(file_names,_extra=source)

  ;Redefine FILE_RETRIEVE structure for Real Time data:
  ;====================================================
  source.remote_data_dir = remote_data_dir + 'dst_realtime/'

  ;Get files and local paths, and concatenate local paths:
  ;=======================================================
  local_paths2=file_retrieve(file_names,_extra=source)

  ;Concatenate and unique possible file names from Final, Provisional and RT data:
  ;========================================================================
  local_paths=[local_paths0,local_paths1,local_paths2]

  ; prevent data from loading twice on Windows machines due to having the same file
  ; path in local_paths with different path separators
  ;     e.g., 'c:\data\dst\datafile.for.request' and 'c:/data/dst/datafile.for.request'
  ; we're simply replacing '\' with '/' in all paths before sending to uniq() 
  ; - works on *nix, Windows 7 - not sure about older Windows machines - egrimes 5/15/2014
  for lpath_idx = 0, n_elements(local_paths)-1 do local_paths[lpath_idx] = strlowcase(strjoin(strsplit(local_paths[lpath_idx], '\', /extract), '/'))
  local_paths=local_paths[uniq(local_paths,sort(local_paths))]
endif else file_names=fns

;Read the files:
;===============
s=''
alldsttime=0
alldst= 0
alldstversion = 0


;Loop on files:
;==============

; Define arrays for time and data
all_dst_time = [] ;time array for all files
all_dst_data = [] ;data array for all files
dst_data_nan = make_array(24,value=!values.f_nan) ;empty data for a day

; Open and parse each index.html file 
; Each file contains dst data for one month
for file_i=0,n_elements(local_paths)-1 do begin
  file= local_paths[file_i]
  if file_test(/regular,file) then  dprint,'Loading DST file: ',file $
    else begin
      dprint,'DST file ',file,' not found. Skipping'
      continue
    endelse
    
    ; Parse filename to find year and month (eg, 201703/index.html)
    ; If it is not possible to parse the filename, then skip the file    
    dst_year = '0'
    dst_month = '0'
    dst_day = '0'
    if strlen(file) ge 17 then begin
      f0 = strmid(file, 16, 6, /reverse_offset) ;this should be like 201703
      digs=['0','1','2','3','4','5','6','7','8','9']
      mynumberisinteger = 1
      for i=0,5 do begin
        if where(digs eq strmid(f0, i, 1)) lt 0 then begin
          mynumberisinteger = 0
          break
        endif        
      endfor
      if mynumberisinteger eq 1 then begin
        dst_year = strmid(f0, 0, 4)
        dst_month = strmid(f0, 4, 2)
      endif  
    endif
    if dst_year eq '0' || dst_month eq '0' then begin 
      ; could not find month or year
      printd, 'There is a problem with the dst file: ' + file
      continue
    endif    
    
    openr,lun,file,/get_lun

    ;Loop on lines (format documented at
    ;http://wdc.kugi.kyoto-u.ac.jp/dstae/format/dstformat.html):
    ; 2019-04-26: this formatting is no longer valid, now we parse an HTML file
    ;===========================================================
    find_units = 0
    find_day = 0
    find_eof = 0 
    while(not eof(lun)) do begin
      readf,lun,s
      s = strtrim(s,2)
      
      ; Parse html file
      if strlowcase(s) eq '' then continue ; if empty, continue
      if strlen(s) ge 7 && strlowcase(strmid(s,0,7)) eq 'unit=nt' then find_units = 1
      if find_units eq 0 then continue ; continue till find units
      if strlowcase(strtrim(s,2)) eq 'day' then begin 
        find_day = 1
        continue
      endif
      if find_day eq 0 then continue ; continue till skip date
      
      ; find end of data, <!--
      if strlen(s) ge 4 then begin
        if strmid(s, 0, 4) eq '<!--' then break  ;break reading file
      endif
      
      ; Parse one line of data      
      s0 = ''
      for i=0, strlen(s)-1 do begin
        char0 = strmid(s, i, 1)
        ; Add spaces before minus sign 
        ; This is needed for cases when the index is <-100, fdr example 1968-04-05/22:00:00
        if char0 eq '-' then char0 = ' -' 
        s0 = s0 + char0
      endfor
      
      d = strsplit(s0, /extract)      
      if n_elements(d) eq 25 then begin
        dst_day = d[0]
        dst_data = fix(d[1:24])
      endif else begin
        ;if the line is different, we fill the day with NaN values
        print, 'Found a line of dst data that has length different than expected. Filled with NaN.'
        dst_day = strtrim(string(fix(dst_day) + 1), 2)
        dst_data = dst_data_nan
      endelse
      dst_day2 = strmid('0'+ strtrim(string(dst_day),2), 1, 2, /reverse_offset)
      for i = 0, 23 do begin
        dst_hour = strmid('0'+ strtrim(string(i), 2), 1, 2, /reverse_offset)
        all_dst_time = [all_dst_time, dst_year + '-' + dst_month + '-' + dst_day2 + '/' + dst_hour + ':' + dst_minutes + ':00']
        all_dst_data = [all_dst_data, dst_data[i]]
      endfor
   
    endwhile
    free_lun,lun
endfor 

acknowledgestring = 'The DST data are provided by the World Data Center for Geomagnetism, Kyoto, and'+ $
  ' are not for redistribution (http://wdc.kugi.kyoto-u.ac.jp/). Furthermore, we thank'+ $
  ' the geomagnetic observatories (Kakioka [JMA], Honolulu and San Juan [USGS], Hermanus'+ $
  ' [RSA], Alibag [IIG]), NiCT, INTERMAGNET, and many others for their cooperation to'+ $
  ' make the Dst index available.'

if n_elements(all_dst_time) lt 1 then begin
  dprint, 'No data found.'
endif else begin
  dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgestring))
  str_element, dlimit, 'data_att.units', 'nT', /add
  store_data,'kyoto_dst',data={x:time_double(all_dst_time), y:all_dst_data},dlimit=dlimit  
endelse

; Clip the data to the user requested time range
; ONLY if they have passed the keyword apply_time_clip. This is to ensure these changes don't
; disrupt existing code and tests.
if keyword_set(apply_time_clip) then begin
  if tnames('kyoto_dst') eq 'kyoto_dst' then begin;first check this tplot variable exists
    If (keyword_set(trange) && n_elements(trange) Eq 2) $
      Then tr = timerange(trange) $
      else tr = timerange()
    tr = time_double(tr) + [-0.1, 0.1] 
    time_clip, 'kyoto_dst', min(tr), max(tr), /replace, error=tr_err
    if tr_err then del_data, 'kyoto_dst'
  endif
endif
;

print,'**************************************************************************************
print,  'The DST data are provided by the World Data Center for Geomagnetism, Kyoto, and'
print,  ' are not for redistribution (http://wdc.kugi.kyoto-u.ac.jp/). Furthermore, we thank'
print,  ' the geomagnetic observatories (Kakioka [JMA], Honolulu and San Juan [USGS], Hermanus'
print,  ' [RSA], Alibag [IIG]), NiCT, INTERMAGNET, and many others for their cooperation to'
print,  ' make the Dst index available.'
print,'**************************************************************************************


end

