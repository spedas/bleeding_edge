;+
; Procedure: kyoto_dst_load
; loads kyoto DST data into tplot format
; Davin Larson  Apr 2008
;-
pro kyoto_dst_load,trange=trange,data=data,alldst=alldst,alltime=alltime

message,/info,'This routine will only return realtime data from the Kyoto service.' + $
' Data that has been promoted to provisional or final status will not be returned.' + $
' Please consider using kyoto_load_dst instead -- it will query all three statuses.'
 
;  Get the file(s)
if not keyword_set(source) then begin
  source = file_retrieve(/struct)
  source.min_age_limit= 900   ; allow 15 minutes between updates.
  source.local_data_dir = root_data_dir() + 'geom_indices/kyoto/'
  source.remote_data_dir = 'http://swdcwww.kugi.kyoto-u.ac.jp/'
endif

;htmlformat = 'dst_realtime/YYYYMM/index.html'
htmlformat = 'dst_provisional/YYYYMM/index.html'
relhtmlnames = file_dailynames(file_format=htmlformat,trange=trange,/unique,times=times)
basedate =  time_string(times,tformat='YYYY-MM-01')
htmlfiles = file_retrieve(relhtmlnames,_extra=source)

;plotformat = 'dst_realtime/YYYYMM/dstyyMM.jpg'
htmlformat = 'dst_provisional/YYYYMM/dstyyMM.jpg'
relplotnames = file_dailynames(file_format=plotformat,trange=trange,/unique)
plotfiles = file_retrieve(relplotnames,_extra=source)


; Read the files

;file_format= {day:0, DST:intarr(24) }
;data = read_asc(files,format=file_format,nheader=37,/verbose)
s=''
alltime=0
alldst = 0
for i=0,n_elements(htmlfiles)-1 do begin
    file= htmlfiles[i]
    if file_test(/regular,file) then  dprint,'Loading DST file: ',file else begin
         dprint,'DST file ',file,' not found. Skipping'
         continue
    endelse
    openr,lun,file,/get_lun
    basetime = time_double(basedate[i])
    while(not eof(lun)) do begin
      readf,lun,s
      if strmid(s,0,1) eq '<' then ok=0
      if keyword_set(ok) && keyword_set(s) then begin
         dprint,s ,dlevel=5
         day = fix ( strmid(s,0,2))
         dst = fix ( strmid(s, indgen(24)*4 + indgen(24) /8 +3 ,4) )
         append_array,alldst,dst
         append_array,alltime,basetime + ((day-1)*24d + dindgen(24))*3600d + 3600d
         dprint,' ',s,dlevel=5
         dprint,dlevel=3,day,dst,format='(25i4)'
         continue
      endif

      if s eq 'DAY' then ok=1
    endwhile
    free_lun,lun
endfor

if keyword_set(alldst) then begin
  alldst = float(alldst)
  wbad = where(alldst ge 9000,nbad)
  if nbad gt 0 then alldst[wbad] = !values.f_nan
  store_data,'kyoto_dst',data={x:alltime, y:alldst},dlimit={constant:0.,datagap:6000.}
endif

end
