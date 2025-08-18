;+
;
;Name:
;KYOTO_AE_LOAD
;
;Purpose:
; Loads kyoto AE, AL, AO, and AU data into tplot format.
; Heavily modified from Davin Larson's KYOTO_DST_LOAD (Apr 2008).
;
;Syntax:
; kyoto_ae_load [, DATATYPE (!! NOT YET IMPLEMENTED !!) ]
;
;Keywords:
;  Use DATATYPE to give any combination of AE, AL, AO, or AU.  NOT YET
;    IMPLEMENTED!  For now, routine loads all by default.
;
;Code:
;W.M.Feuerstein, 4/16/2008.
;
;Modifications:
;  Changed file format of name (kyoto_ae_YYYY_MM.dat to kyoto_ae_YYYYMM.dat),
;    changed "DST" references to "AE", updated doc'n, WMF, 4/17/2008.
;
;-
pro kyoto_ae_load,trange=trange,data=data, $
  filenames=filenames, $
  allae=allae, $
  allaetime=allaetime, $
  allal=allal, $
  allaltime=allaltime, $
  allao=allao, $
  allaotime=allaotime, $
  allau=allau, $
  allautime=allautime


;Get timespan and define file names:
;===================================
get_timespan,t
if ~size(filenames,/type) then begin
  file_names = file_dailynames( $
    file_format='YYYY/kyoto_ae_YYYYMM.dat',trange=t,times=times,/unique)
endif else file_names=filenames
basedate=time_string(times,tformat='YYYY-MM-01')
baseyear=strmid(basedate,0,4)


;Define FILE_RETRIEVE structure:
;===============================
if not keyword_set(source) then begin
  source = file_retrieve(/struct)
  source.min_age_limit= 900   ; allow 15 minutes between updates.
  source.local_data_dir = root_data_dir() + 'geom_indices/kyoto/ae/'
  source.remote_data_dir = $
    'http://themis.ssl.berkeley.edu/data/geom_indices/kyoto/ae/'
endif


;Get files and local paths:
;==========================
ae_local_paths=file_retrieve(file_names,_extra=source)


;Read the files:
;===============
s=''
allaetime=0
allaltime=0
allaotime=0
allautime=0
allae= 0
allal= 0
allao= 0
allau= 0


;Loop on files:
;==============
for i=0,n_elements(ae_local_paths)-1 do begin
    file= ae_local_paths[i]
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
      ;if strmid(s,0,1) eq '<' then ok=0
      ok=1
      if keyword_set(ok) && keyword_set(s) then begin
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
         ;Append data by type (AE, AL, AO, or AU):
         ;========================================
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
         endcase
         continue
      endif

      ;if s eq 'DAY' then ok=1
    endwhile
    free_lun,lun
endfor


;Store data in TPLOT variables:
;==============================
if keyword_set(allae) then begin
  allae= float(allae)
  wbad = where(allae eq 99999,nbad)
  if nbad gt 0 then allae[wbad] = !values.f_nan
  store_data,'kyoto_ae',data={x:allaetime, y:allae},dlimit={constant:0.}
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

end

