
compile_opt idl2

; Helper routine to extract sort keys from AE data filenames

pro make_ae_sort_keys,files=files,keys=keys
   keys = []
   for i=0,n_elements(files)-1 do begin
      bn = file_basename(files[i])
      yy = strmid(bn,2,2)
      mm = strmid(bn,4,2)
      dd = strmid(bn,6,2)
      if uint(yy) ge 90 then key='19'+yy+mm+dd else key='20'+yy+mm+dd
      keys=[keys,key]
   endfor
end   
   

; This helper routine does most of the work of downloading and reading the Kyoto data files.
; The provisional and realtime data are organized a little differently, so this routine takes a 'realtime' keyword
; which controls how the URLs and local data directory paths are constructed, and also takes a string prefix value so we can
; distinguish between provisional and realtime tplot variable names, in order to merge them after they're loaded.
; The other arguments have the same interpretation as the master kyoto_load_ae routine below.

pro kyoto_load_ae_helper ,trange=trange, $
;  filenames=fns, $         ;Do not pounce on FILENAMES.
  aedata=allae, $
  aetime=allaetime, $
  aldata=allal, $
  altime=allaltime, $
  aodata=allao, $
  aotime=allaotime, $
  audata=allau, $
  autime=allautime, $
  axdata=allax, $
  axtime=allaxtime, $
  verbose=verbose, $
  datatype=datatype, $     ;Input/output -- will clean inputs or show default.
  no_server=no_server, $ ; use only locally available data, ie don't download data
  local_data_dir=local_data_dir, $
  remote_data_dir = remote_data_dir, $
  skip_realtime=skip_realtime, $
  skip_provisional=skip_provisional, $
  return_vars = return_vars, $
  prefix = prefix

if n_elements(prefix) eq 0 then prefix = ''
if n_elements(skip_realtime) eq 0 then skip_realtime=0
if n_elements(skip_provisional) eq 0 then skip_provisional=0

   
;**************************
;Load 'remote_data_dir' default:
;**************************
if ~keyword_set(remote_data_dir) then remote_data_dir='https://wdc.kugi.kyoto-u.ac.jp/' 
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
;Load 'ae' data by default:
;**************************
if ~keyword_set(datatype) then datatype='ae'


;*****************
;Validate datypes:
;*****************
;vns=['ae','al','ao','au','ax']
;if size(datatype,/type) eq 7 then begin
;stop
;  datatype=ssl_check_valid_name(datatype,vns,/include_all)
;stop
;  if datatype[0] eq '' then return
;endif else begin
;  message,'DATATYPE kw must be of string type.',/info
;  return
;endelse

vns=['ae','al','ao','au','ax']
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


;Get timespan, define FILE_NAMES, and load data:
;===============================================
If (keyword_set(trange) && n_elements(trange) Eq 2) then begin
  t = trange
endif else get_timespan,t

; Initialize the merged data arrays
;===============
s=''
allaetime=0
allaltime=0
allaotime=0
allautime=0
allaxtime=0
allae= 0
allal= 0
allao= 0
allau= 0
allax= 0

acknowledgstring = 'The provisional AE data are provided by the World Data Center for Geomagnetism, Kyoto,'+ $
  ' and are not for redistribution (https://wdc.kugi.kyoto-u.ac.jp/). Furthermore, we thank'+ $
  ' AE stations (Abisko [SGU, Sweden], Cape Chelyuskin [AARI, Russia], Tixi [IKFIA and'+ $
  ' AARI, Russia], Pebek [AARI, Russia], Barrow, College [USGS, USA], Yellowknife,'+ $
  ' Fort Churchill, Sanikiluaq (Poste-de-la-Baleine) [CGS, Canada], Narsarsuaq [DMI,'+ $
  ' Denmark], and Leirvogur [U. Iceland, Iceland]) as well as the RapidMAG team for'+ $
  ' their cooperations and efforts to operate these stations and to supply data for the provisional'+ $
  ' AE index to the WDC, Kyoto. (Pebek is a new station at geographic latitude of 70.09N'+ $
  ' and longitude of 170.93E, replacing the closed station Cape Wellen.)'



  for i=0,n_elements(datatype)-1 do begin
    rt_ff = 'YYYY/MM/DD/'+datatype[i]+'yyMMDD'
    prov_ff = 'YYYYMM/'+datatype[i]+'yyMMDD'
    rt_file_names = file_dailynames(file_format=rt_ff,trange=t, times=times, /unique)
    prov_file_names = file_dailynames(file_format=prov_ff,trange=t, times=times, /unique)
    prov_file_names = prov_file_names + '.for.request'

    source = file_retrieve(/struct)
    source.verbose=verbose
    if keyword_set(no_server) then source.no_server=1    
    ; download realtime
    rt_paths = []
    source.local_data_dir = local_data_dir + 'kyoto/ae_realtime/data_dir/' + datatype[i] + '/'
    source.remote_data_dir = remote_data_dir + 'ae_realtime/data_dir/'
    if ~skip_realtime then rt_paths=spd_download(remote_file=rt_file_names,/valid_only,_extra=source)
      
    ; download provisional
    prov_paths = []
    source.local_data_dir = local_data_dir + 'kyoto/ae_provisional/'+ datatype[i] + '/' 
    source.remote_data_dir = remote_data_dir + 'ae_provisional/'
    if ~skip_provisional then prov_paths=spd_download(remote_file=prov_file_names,/valid_only,_extra=source)

    ; We need to sort and de-duplicate the two sets of files using a date key.
    make_ae_sort_keys,files=rt_paths,keys=rt_keys
    make_ae_sort_keys,files=prov_paths,keys=prov_keys
    
    ; Remove any filenames and keys from the realtime list if they are present in the provisional list
    rt_paths_thinned = []
    rt_keys_thinned =  []
    for j=0, n_elements(rt_keys)-1 do begin
      idx=where(prov_keys eq rt_keys[j], count)
      if count eq 0 then begin
        rt_paths_thinned = [rt_paths_thinned, rt_paths[j]]
        rt_keys_thinned = [rt_keys_thinned, rt_keys[j]]
      endif
    endfor
 
    ; Sort the pathnames using the keys as the sort order   
    unsorted_paths=[prov_paths, rt_paths_thinned]
    unsorted_keys=[prov_keys, rt_keys_thinned]
    sort_idx = sort(unsorted_keys)
    sorted_paths = unsorted_paths[sort_idx]   
    
    ;Loop on files:
    ;==============
    for k=0,n_elements(sorted_paths)-1 do begin
        file= sorted_paths[k]
        if file_test(/regular,file) then  dprint,'Loading AE file: ',file $
        else begin
             dprint,'AE file ',file,' not found. Skipping'
             continue
        endelse
        openr,lun,file,/get_lun
        ;basetime = time_double(basedate[i])
        ;
        ;Loop on lines:
        ;==============
        while(not eof(lun)) do begin
          readf,lun,s
          ok=1
          if strmid(s,0,1) eq '[' then ok=0
          if ok && keyword_set(s) then begin
             dprint,s ,dlevel=5
             year = (strmid(s,12,2))
             month = (strmid(s,14,2))
             day = (strmid(s,16,2))
             hour = (strmid(s,19,2))
             type = strmid(s,21,2)
             ; Check that the 2-digit year is reasonable before prepending '20' to it!
             if fix(year) ge 90 then yyyy='19'+year else yyyy='20'+year
             basetime = time_double(yyyy+'-'+month+'-'+day+'/'+hour)
             ;
             kdata = fix ( strmid(s, indgen(60)*6 +34 ,6) )
             ;
             ;Append data by type (AE, AL, AO, AU or AX):
             ;===========================================
             case type of
               'AE': begin
    	     append_array,allae,kdata
    	     append_array,allaetime, basetime + dindgen(60)*60d
    	     dprint,' ',s,dlevel=5
    	   end
    	   'AL': begin
    	     append_array,allal,kdata
    	     append_array,allaltime, basetime + dindgen(60)*60d
    	     dprint,' ',s,dlevel=5
    	   end
    	   'AO': begin
    	     append_array,allao,kdata
    	     append_array,allaotime, basetime + dindgen(60)*60d
    	     dprint,' ',s,dlevel=5
    	   end
    	   'AU': begin
    	     append_array,allau,kdata
    	     append_array,allautime, basetime + dindgen(60)*60d
    	     dprint,' ',s,dlevel=5
    	   end
               'AX': begin
    	     append_array,allax,kdata
    	     append_array,allaxtime, basetime + dindgen(60)*60d
    	     dprint,' ',s,dlevel=5
    	   end
             endcase
             continue
          endif
    
          ;if s eq 'DAY' then ok=1
        endwhile
        free_lun,lun
     endfor 
  endfor

tvars = []

;==============================
;Store data in TPLOT variables:
;==============================

if keyword_set(allae) then begin
  allae= float(allae)
  wbad = where(allae eq 99999,nbad)
  if nbad gt 0 then allae[wbad] = !values.f_nan
  dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring))
  str_element, dlimit, 'data_att.units', 'nT', /add
  store_data,prefix+'kyoto_ae',data={x:allaetime, y:allae},dlimit=dlimit
  options,prefix+'kyoto_ae','ytitle','Kyoto!CProv. AE!C[nT]'
  tvars=[tvars,prefix+'kyoto_ae']
endif
;
if keyword_set(allal) then begin
  allal= float(allal)
  wbad = where(allal eq 99999,nbad)
  if nbad gt 0 then allal[wbad] = !values.f_nan
  dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring))
  str_element, dlimit, 'data_att.units', 'nT', /add
  store_data,prefix+'kyoto_al',data={x:allaltime, y:allal},dlimit=dlimit
  options,prefix+'kyoto_al','ytitle','Kyoto!CProv. AL!C[nT]'
  tvars=[tvars,prefix+'kyoto_al']
endif
;
if keyword_set(allao) then begin
  allao= float(allao)
  wbad = where(allao eq 99999,nbad)
  if nbad gt 0 then allao[wbad] = !values.f_nan
  dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring))
  str_element, dlimit, 'data_att.units', 'nT', /add
  store_data,prefix+'kyoto_ao',data={x:allaotime, y:allao},dlimit=dlimit
  options,prefix+'kyoto_ao','ytitle','Kyoto!CProv. AO!C[nT]'
  tvars=[tvars,prefix+'kyoto_ao']

endif
;
if keyword_set(allau) then begin
  allau= float(allau)
  wbad = where(allau eq 99999,nbad)
  if nbad gt 0 then allau[wbad] = !values.f_nan
  dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring))
  str_element, dlimit, 'data_att.units', 'nT', /add
  store_data,prefix+'kyoto_au',data={x:allautime, y:allau},dlimit=dlimit
  options,prefix+'kyoto_au','ytitle','Kyoto!CProv. AU!C[nT]'
  tvars=[tvars,prefix+'kyoto_au']

endif
;
if keyword_set(allax) then begin
  allax= float(allax)
  wbad = where(allax eq 99999,nbad)
  if nbad gt 0 then allax[wbad] = !values.f_nan
  dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring))
  str_element, dlimit, 'data_att.units', 'nT', /add
  store_data,prefix+'kyoto_ax',data={x:allaxtime, y:allax},dlimit=dlimit
  options,prefix+'kyoto_ax','ytitle','Kyoto!CProv. AX!C[nT]'
  tvars=[tvars,prefix+'kyoto_ax']
endif
return_vars = tvars

end

;+
;
;Name:
;KYOTO_LOAD_AE
;
;Purpose:
;  Queries the Kyoto servers for AE, AL, AO, AU, and AX data and loads data into
;  tplot format.  Highly modified from KYOTO_AE_LOAD.
;  
;  Kyoto now makes realtime data available in numeric format.  The directory structure and filenames are
;  a little different from the provisional data, so there is now a helper routine that gets called once
;  for provisional data, and once for realtime data, then merges them if necessary.
;  
;  There does not appear to be realtime data for the AX index.
;  
;  At this writing (2026-02-10), the cutoff point between provisional and realtime data is 2021-01-01.
;  
;  Exact dates of availability can be checked at https://wdc.kugi.kyoto-u.ac.jp/ae_provisional/index.html.
;  Note that there are no final AE indices produced.
;  See also thm_crib_make_ae.pro for information on generating THEMIS pseudo AE indices.
;
;Syntax:
;  KYOTO_LOAD_AE [ ,DATATYPE = string ]
;                 [ ,TRANGE = [min,max] ]
;                 [ ,FILENAMES = string scalar or array ]
;                 [ ,<and data keywords below> ]
;
;Keywords:
;  DATATYPE (I/O):
;    Set to 'ae', 'al', 'ao', 'au', 'ax', or 'all'.  If not set, 'ae' is
;      assumed.  Returns cleaned input, or shows default.
;  TRANGE (In):
;    Pass a time range a la TIME_STRING.PRO.
;  FILENAMES (In):
;    *PRESENTLY DISABLED* Pass user-defined file names (full paths to local data files).  These will
;      be read a la the Kyoto format, and the Kyoto server will not be queried.
;  AEDATA, AETIME (Out):  Get 'ae' data, time basis.
;  ALDATA, ALTIME (Out):  Get 'al' data, time basis.
;  AODATA, AOTIME (Out):  Get 'ao' data, time basis.
;  AUDATA, AUTIME (Out):  Get 'au' data, time basis.
;  VERBOSE (In): [1,...,5], Get more detailed (higher number) command line output.
;  no_server (in) Use only data available locally (same as deprecated no_download keyword).
;Code:
;W.M.Feuerstein, 5/15/2008.
;
;Modifications:
;  Changed file format of name (kyoto_ae_YYYY_MM.dat to kyoto_ae_YYYYMM.dat),
;    changed "DST" references to "AE", updated doc'n, WMF, 4/17/2008.
;  Saved new version under new name (old name was KYOTO_AE_LOAD), added
;    DATATYPE kw, validate and loop on datatypes, hardwired /DOWNLOADONLY,
;    up'd data kwd's, up'd doc'n, WMF, 5/15/2008.
;  Tested that the software defaults to local data when ther internet is not
;    available even with /DOWNLOADONLY (yes), added acknowledgment and
;    warning banner, added 'ax' datatype, WMF, 5/19/2008.
;  Put acknowledment in header, upd'd doc'n, added ytitles, created
;    DLIMITS.DATA_ATT.ACKNOWLEDGEMENT, WMF, 5/20/2008.
;  Multiline ytitles, changed acknowledgment, WMF, 5/21/2008.
;  Changed name from KYOTO_AE2TPLOT.PRO to KYOTO_LOAD_AE.PRO, WMF, 6/4/2008.
;  Removed SOURCE.DOWNLOADONLY and SOURCE.MIN_AGE_LIMIT references, added
;    VERBOSE kw per D. Larson, WMF, 7/8/2008.
;  Default for VERBOSE kw, WMF, 7/24/2008.
;  Fixed use of trange keyword, added no_server keyword. lphilpott 17-oct-2011
;
;Acknowledgment:
;  The provisional AE data are provided by the World Data Center for Geomagnetism, Kyoto,
;  and are not for redistribution (https://wdc.kugi.kyoto-u.ac.jp/). Furthermore, we thank
;  AE stations (Abisko [SGU, Sweden], Cape Chelyuskin [AARI, Russia], Tixi [IKFIA and
;  AARI, Russia], Pebek [AARI, Russia], Barrow, College [USGS, USA], Yellowknife,
;  Fort Churchill, Sanikiluaq (Poste-de-la-Baleine) [CGS, Canada], Narsarsuaq [DMI,
;  Denmark], and Leirvogur [U. Iceland, Iceland]) as well as the RapidMAG team for
;  their cooperations and efforts to operate these stations and to supply data for the provisional
;  AE index to the WDC, Kyoto. (Pebek is a new station at geographic latitude of 70.09N
;  and longitude of 170.93E, replacing the closed station Cape Wellen.)
;
; $LastChangedBy:  $
; $LastChangedDate:  $
; $LastChangedRevision:  $
; $URL $
;-


; This is the new top level routine that, if necessary, makes two calls to kyoto_load_ae_helper to
; load provisional and realtime data separately, then merges them to create the final tplot variables
; and time/data arrays.

pro kyoto_load_ae ,trange=trange, $
  ;  filenames=fns, $         ;Do not pounce on FILENAMES.
  aedata=allae, $
  aetime=allaetime, $
  aldata=allal, $
  altime=allaltime, $
  aodata=allao, $
  aotime=allaotime, $
  audata=allau, $
  autime=allautime, $
  axdata=allax, $
  axtime=allaxtime, $
  verbose=verbose, $
  datatype=datatype, $     ;Input/output -- will clean inputs or show default.
  no_server=no_server, $ ; use only locally available data, ie don't download data
  local_data_dir=local_data_dir, $
  remote_data_dir = remote_data_dir, $
  realtime = realtime

  ;**************************
  ;Load 'remote_data_dir' default:
  ;**************************
  if ~keyword_set(remote_data_dir) then remote_data_dir='https://wdc.kugi.kyoto-u.ac.jp/'
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
  ;Load 'ae' data by default:
  ;**************************
  if ~keyword_set(datatype) then datatype='ae'


  ;*****************
  ;Validate datypes:
  ;*****************
  ;vns=['ae','al','ao','au','ax']
  ;if size(datatype,/type) eq 7 then begin
  ;stop
  ;  datatype=ssl_check_valid_name(datatype,vns,/include_all)
  ;stop
  ;  if datatype[0] eq '' then return
  ;endif else begin
  ;  message,'DATATYPE kw must be of string type.',/info
  ;  return
  ;endelse

  vns=['ae','al','ao','au','ax']
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


  ;Get timespan, define FILE_NAMES, and load data:
  ;===============================================
  If (keyword_set(trange) && n_elements(trange) Eq 2) then begin
    t = trange
  endif else get_timespan,t


  ; At this writing (2026-02-12), there's a small island of provsional data for 2024-05-10 through 2025-05-15.
  ; Except for that window, the provisional data ends at 2021-01-01, then all realtime.
  ; This should be checked periodically to see if more provisional data is available.
  
  prov_cutoff_dbl = time_double('2021-01-01/00:00:00')
  latest_mixed_date = '2024-05-15/00:00:00'
  latest_provisional_only = '2021-01-01/00:00:00'
  skip_realtime = 0
  skip_provisional = 0

  ; Try to minimize queries to the remote server, by identifying times we know are only provisional,
  ; or only realtime.
  
  if time_double(t[1]) le time_double(latest_provisional_only) then begin
    skip_realtime = 1
  endif
  if time_double(t[0]) ge time_double(latest_mixed_date) then begin
    skip_provisional = 1
  endif

    kyoto_load_ae_helper, trange=t, $
      ;  filenames=fns, $         ;Do not pounce on FILENAMES.
      aedata=allae, $
      aetime=allaetime, $
      aldata=allal, $
      altime=allaltime, $
      aodata=allao, $
      aotime=allaotime, $
      audata=allau, $
      autime=allautime, $
      axdata=allax, $
      axtime=allaxtime, $
      verbose=verbose, $
      datatype=datatype, $     ;Input/output -- will clean inputs or show default.
      no_server=no_server, $ ; use only locally available data, ie don't download data
      local_data_dir=local_data_dir, $
      remote_data_dir = remote_data_dir, $
      skip_realtime=skip_realtime, $
      skip_provisional=skip_provisional

      

  print,'**********************************************************************************
  print,'The provisional AE data are provided by the World Data Center for Geomagnetism, Kyoto,
  print,'and are not for redistribution (https://wdc.kugi.kyoto-u.ac.jp/). Furthermore, we thank
  print,'AE stations (Abisko [SGU, Sweden], Cape Chelyuskin [AARI, Russia], Tixi [IKFIA and
  print,'AARI, Russia], Pebek [AARI, Russia], Barrow, College [USGS, USA], Yellowknife,
  print,'Fort Churchill, Sanikiluaq (Poste-de-la-Baleine) [CGS, Canada], Narsarsuaq [DMI,
  print,'Denmark], and Leirvogur [U. Iceland, Iceland]) as well as the RapidMAG team for
  print,'their cooperations and efforts to operate these stations and to supply data for the provisional
  print,'AE index to the WDC, Kyoto. (Pebek is a new station at geographic latitude of 70.09N
  print,'and longitude of 170.93E, replacing the closed station Cape Wellen.)
  print,'**********************************************************************************


end

