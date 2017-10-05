
pro mvn_sta_tplot_restore,trange=trange,create=create,verbose=verbose,append=append

tplt_format = 'maven/data/sci/sta/tplot/YYYY/MM/mvn_sta_l2_c6-32e64m_YYYYMMDD.tplot'
; http://sprg.ssl.berkeley.edu/data/maven/data/sci/sta/l2/2014/11/mvn_sta_l2_c6-32e64m_20141129_v00.cdf
ts_format = 'maven/data/sci/sta/l2/YYYY/MM/mvn_sta_l2_c6-32e64m_YYYYMMDD_v??_r??.cdf'
;ts_format = 'maven/data/sci/sta/l2/YYYY/MM/mvn_sta_l2_c6-32e64m_YYYYMMDD_v??.cdf'
tpltnames_format = 'mvn_sta_*c6*'

tr = timerange(trange)
day = 86400L
tr2 = day * floor(tr / day + [0,.999])
ndays = round((tr2[1]-tr2[0])/day)  > 1

if ~keyword_set(create) then begin
  tplt_files = mvn_pfp_file_retrieve(tplt_format,trange=tr2,/daily_names)  
  nf = n_elements(tplt_files) * keyword_set(tplt_files)
  for i=0,nf-1 do begin
    f = tplt_files[i]
    if file_test(/regular,f) ne 0 then  begin
      dprint,dlevel=2,verbose=verbose,'Loading '+f
      tplot_restore,file=f,append = append
      append = 1
    endif
  endfor
  return
endif


if keyword_set(create) then begin
  ndays = round((tr2[1]-tr2[0])/day)  > 1
  nf = n_elements(tplt_files) * keyword_set(tplt_files)
  for i=0,ndays-1 do begin
    t = tr2[0] + i * day
    ts_file = mvn_pfp_file_retrieve(ts_format,trange=t,/daily_names)
    ts_file_info = file_info(ts_file)
    ts_time = min(ts_file_info.mtime)
    if ts_time le 0 then begin
      dprint,dlevel=3,verbose=verbose,'File not found: '+ts_file
      continue
    endif
    tplt_file = mvn_pfp_file_retrieve(tplt_format,trange=t,/daily_names,/create)
    tplt_file_info = file_info(tplt_file)
    if tplt_File_info.mtime ge ts_time then continue
    mvn_sta_l2_load,trange = t+[0,1]*day                          ; loads STATIC L2 data files into common blocks
    mvn_sta_l2_tplot                                              ; loads STATIC L2 common blocks into tplot variables,
    tn = tnames(tpltnames_format)
    tplot_save,file=tplt_file,tn,/no_add_extension
    dprint,verbose=verbose,dlevel=1,'Created: '+tplt_file
  endfor  
endif

end
