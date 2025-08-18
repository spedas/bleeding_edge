;+
;
;Name:
;KYOTO_LOAD_AE
;
;Purpose:
;  Queries the Kyoto servers for AE, AL, AO, AU, and AX data and loads data into
;  tplot format.  Highly modified from KYOTO_AE_LOAD.
;  Note: Only provisional data is available. Kyoto does not make realtime AE indices available in this
;  form due to the possible problems with the data (plots of realtime AE can be found on their website).
;  Provisional data is usually available for up to few months before the present. Exact dates of availability
;  can be checked at https://wdc.kugi.kyoto-u.ac.jp/ae_provisional/index.html.
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

compile_opt idl2

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
  remote_data_dir = remote_data_dir
  
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


if ~size(fns,/type) then begin
  for i=0,n_elements(datatype)-1 do begin

    ;Get files for ith datatype:
    ;***************************
    file_names = file_dailynames( $
      file_format='YYYYMM/a'+strmid(datatype[i],1,1)+ $
      'yyMMDD',trange=t,times=times,/unique)+'.for.request

    ;Define FILE_RETRIEVE structure:
    ;===============================
    source = file_retrieve(/struct)
    source.verbose=verbose
    source.local_data_dir = local_data_dir + 'kyoto/a'+ $
      strmid(datatype[i],1,1)+'/'
    source.remote_data_dir = $
      remote_data_dir + 'a'+ $
    ;    strmid(datatype[i],1,1)+ $
      'e'+ $
      '_provisional/'
    if keyword_set(no_server) then source.no_server=1
    
    ;Get files and local paths, and concatenate local paths:
    ;=======================================================
    local_paths=spd_download(remote_file=file_names,_extra=source)
    local_paths_all = ~(~size(local_paths_all,/type)) ? $
      [local_paths_all, local_paths] : local_paths

  endfor
  if ~(~size(local_paths_all,/type)) then local_paths=local_paths_all
endif else file_names=fns

;basedate=time_string(times,tformat='YYYY-MM-01')
;baseyear=strmid(basedate,0,4)



;Read the files:
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


;Loop on files:
;==============
for i=0,n_elements(local_paths)-1 do begin
    file= local_paths[i]
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
         basetime = time_double('20'+year+'-'+month+'-'+day+'/'+hour)
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


;==============================
;Store data in TPLOT variables:
;==============================
acknowledgstring = 'The provisional AE data are provided by the World Data Center for Geomagnetism, Kyoto,'+ $
  ' and are not for redistribution (https://wdc.kugi.kyoto-u.ac.jp/). Furthermore, we thank'+ $
  ' AE stations (Abisko [SGU, Sweden], Cape Chelyuskin [AARI, Russia], Tixi [IKFIA and'+ $
  ' AARI, Russia], Pebek [AARI, Russia], Barrow, College [USGS, USA], Yellowknife,'+ $
  ' Fort Churchill, Sanikiluaq (Poste-de-la-Baleine) [CGS, Canada], Narsarsuaq [DMI,'+ $
  ' Denmark], and Leirvogur [U. Iceland, Iceland]) as well as the RapidMAG team for'+ $
  ' their cooperations and efforts to operate these stations and to supply data for the provisional'+ $
  ' AE index to the WDC, Kyoto. (Pebek is a new station at geographic latitude of 70.09N'+ $
  ' and longitude of 170.93E, replacing the closed station Cape Wellen.)'

if keyword_set(allae) then begin
  allae= float(allae)
  wbad = where(allae eq 99999,nbad)
  if nbad gt 0 then allae[wbad] = !values.f_nan
  dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring))
  str_element, dlimit, 'data_att.units', 'nT', /add
  store_data,'kyoto_ae',data={x:allaetime, y:allae},dlimit=dlimit
  options,'kyoto_ae','ytitle','Kyoto!CProv. AE!C[nT]'
endif
;
if keyword_set(allal) then begin
  allal= float(allal)
  wbad = where(allal eq 99999,nbad)
  if nbad gt 0 then allal[wbad] = !values.f_nan
  dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring))
  str_element, dlimit, 'data_att.units', 'nT', /add
  store_data,'kyoto_al',data={x:allaltime, y:allal},dlimit=dlimit
  options,'kyoto_al','ytitle','Kyoto!CProv. AL!C[nT]'
endif
;
if keyword_set(allao) then begin
  allao= float(allao)
  wbad = where(allao eq 99999,nbad)
  if nbad gt 0 then allao[wbad] = !values.f_nan
  dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring))
  str_element, dlimit, 'data_att.units', 'nT', /add
  store_data,'kyoto_ao',data={x:allaotime, y:allao},dlimit=dlimit
  options,'kyoto_ao','ytitle','Kyoto!CProv. AO!C[nT]'
endif
;
if keyword_set(allau) then begin
  allau= float(allau)
  wbad = where(allau eq 99999,nbad)
  if nbad gt 0 then allau[wbad] = !values.f_nan
  dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring))
  str_element, dlimit, 'data_att.units', 'nT', /add
  store_data,'kyoto_au',data={x:allautime, y:allau},dlimit=dlimit
  options,'kyoto_au','ytitle','Kyoto!CProv. AU!C[nT]'
endif
;
if keyword_set(allax) then begin
  allax= float(allax)
  wbad = where(allax eq 99999,nbad)
  if nbad gt 0 then allax[wbad] = !values.f_nan
  dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring))
  str_element, dlimit, 'data_att.units', 'nT', /add
  store_data,'kyoto_ax',data={x:allaxtime, y:allax},dlimit=dlimit
  options,'kyoto_ax','ytitle','Kyoto!CProv. AX!C[nT]'
endif

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

