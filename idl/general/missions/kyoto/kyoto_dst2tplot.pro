;+
;
;Name:
;KYOTO_DST2TPLOT
;
;Purpose:
;  Queries the Kyoto servers for DST data and loads data into
;  tplot format.  Adapted from KYOTO_AE2TPLOT.PRO.
;
;Syntax:
;  kyoto_dst2tplot [ ,TRANGE = TRANGE ]
;                  [ ,FILENAMES ]
;                  [ ,< and data keywords below > ]
;
;Keywords:
;  TRANGE (In):
;    Pass a time range a la TIME_STRING.PRO.
;  FILENAMES (In):
;    * PRESENTLY DISABLED * Pass user-defined file names (full paths to local data files).  These will
;      be read a la the Kyoto format, and the Kyoto server will not be queried.
;  DSTDATA, DSTTIME (Out):  Get 'dst' data, time basis.
;  ALDATA, ALTIME (Out):  Get 'al' data, time basis.
;  AODATA, AOTIME (Out):  Get 'ao' data, time basis.
;  AUDATA, AUTIME (Out):  Get 'au' data, time basis.
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
;    available even with /DOWNLOADONLY (yes), added acknowledgment and
;    warning banner, added 'ax' datatype, WMF, 5/19/2008.
;
;-

compile_opt idl2

pro kyoto_dst2tplot ,trange=trange, $
  real_time=real_time, $
  ;filenames=fns, $         ;Do not pounce on FILENAMES.
  dstdata=alldst, $
  dsttime=alldsttime;, $
;  datatype=datatype;, $     ;Input/output -- will clean inputs or show default.
  ;source=source


;**************************
;Load 'dst' data by default:
;**************************
if ~keyword_set(datatype) then datatype='dst'


;;*****************
;;Validate datypes:
;;*****************
;vns=['dst']
;if size(datatype,/type) eq 7 then begin
;  datatype=ssl_check_valid_name(datatype,vns,/include_all)
;  if datatype[0] eq '' then return
;endif else begin
;  message,'DATATYPE kw must be of string type.',/info
;  return
;endelse


;Get timespan and define FILE_NAMES:
;===================================
get_timespan,t
if ~size(fns,/type) then begin

  ;Get files for ith datatype:
  ;***************************
  file_names = file_dailynames( $
    file_format='YYYYMM/dst'+ $
    'yyMM',trange=t,times=times,/unique)+'.for.request

  ;Define FILE_RETRIEVE structure:
  ;===============================
  source = file_retrieve(/struct)
  source.downloadonly=1
  source.min_age_limit= 900   ; allow 15 minutes between updates.
  source.local_data_dir = root_data_dir() + 'geom_indices/kyoto/dst/'
  case 1 of
    ~keyword_set(real_time): source.remote_data_dir = $
      'https://wdc.kugi.kyoto-u.ac.jp/dst_provisional/'
    else: source.remote_data_dir = $
      'https://wdc.kugi.kyoto-u.ac.jp/dst_realtime/'
  endcase

  ;Get files and local paths, and concatenate local paths:
  ;=======================================================
  local_paths=spd_download(remote_file=file_names,_extra=source)

endif else file_names=fns

;basedate=time_string(times,tformat='YYYY-MM-01')
;baseyear=strmid(basedate,0,4)



;Read the files:
;===============
s=''
alldsttime=0
allaltime=0
allaotime=0
allautime=0
allaxtime=0
alldst= 0
allal= 0
allao= 0
allau= 0
allax= 0


;Loop on files:
;==============
for i=0,n_elements(local_paths)-1 do begin
    file= local_paths[i]
    if file_test(/regular,file) then  dprint,'Loading DST file: ',file $
    else begin
         dprint,'DST file ',file,' not found. Skipping'
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
         ;Append data by type (DST, AL, AO, AU or AX):
         ;===========================================
         case type of
           'DST': begin
	     append_array,alldst,kdata
	     append_array,alldsttime, basetime + dindgen(60)*60d
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


;Store data in TPLOT variables:
;==============================
if keyword_set(alldst) then begin
  alldst= float(alldst)
  wbad = where(alldst eq 99999,nbad)
  if nbad gt 0 then alldst[wbad] = !values.f_nan
  store_data,'kyoto_dst',data={x:alldsttime, y:alldst},dlimit={constant:0.}
endif
;
if keyword_set(allal) then begin
  allal= float(allal)
  wbad = where(allal eq 99999,nbad)
  if nbad gt 0 then allal[wbad] = !values.f_nan
  store_data,'kyoto_al',data={x:allaltime, y:allal},dlimit={constant:0.}
endif
;
if keyword_set(allao) then begin
  allao= float(allao)
  wbad = where(allao eq 99999,nbad)
  if nbad gt 0 then allao[wbad] = !values.f_nan
  store_data,'kyoto_ao',data={x:allaotime, y:allao},dlimit={constant:0.}
endif
;
if keyword_set(allau) then begin
  allau= float(allau)
  wbad = where(allau eq 99999,nbad)
  if nbad gt 0 then allau[wbad] = !values.f_nan
  store_data,'kyoto_au',data={x:allautime, y:allau},dlimit={constant:0.}
endif
;
if keyword_set(allax) then begin
  allax= float(allax)
  wbad = where(allax eq 99999,nbad)
  if nbad gt 0 then allax[wbad] = !values.f_nan
  store_data,'kyoto_ax',data={x:allaxtime, y:allax},dlimit={constant:0.}
endif

print,'**********************************************************************************
print,'Kyoto Provisional DST data.  Not for redistribution.'
print,'We thank DST stations (Abisko [SGU, Sweden], Cape Chelyuskin [AARI, Russia],
print,'Tixi [IKFIA and AARI, Russia], Pebek [AARI, Russia], Barrow, College [USGS,
print,'USA], Yellowknife, Fort Churchill, Sanikiluaq (Poste-de-la-Baleine) [CGS,
print,'Canada], Narsarsuaq [DMI, Denmark], and Leirvogur [U. Iceland, Iceland]) as
print,'well as the RapidMAG team for their cooperations and efforts to operate
print,'these stations and to supply data with us for the provisional DST index.
print,'(Pebek is a new station at geographic latitude of 70.09N and longitude of 170.93E,
print,'replacing the closed station Cape Wellen.)
print,'**********************************************************************************

end

