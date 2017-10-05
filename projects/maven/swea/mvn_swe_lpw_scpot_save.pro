;+
;PROCEDURE:   mvn_swe_lpw_scpot_save
;PURPOSE:
;
;USAGE:
;  mvn_swe_lpw_scpot_save, start_day=start_day, ndays=ndays
;
;INPUTS:
;       None
;
;KEYWORDS:
;       start_day:     Save data over this time range.  If not specified, then
;                      timerange() will be called
;
;       ndays:         Number of dates to process.
;                      Default = 7
;
;NOTES:
;       mvn_swe_lpw_scpot uses a long span of data.
;       For efficient processing, this save routine first loads the entire data,
;       and then split and save them into one-day files.
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2017-09-07 09:29:15 -0700 (Thu, 07 Sep 2017) $
; $LastChangedRevision: 23903 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_lpw_scpot_save.pro $
;
;CREATED BY:    Yuki Harada  03-04-16
;FILE: mvn_swe_lpw_scpot_save.pro
;-
pro mvn_swe_lpw_scpot_save, start_day=start_day, ndays=ndays, norbwin=norbwin, _extra=_extra, suffix=suffix

  if ~keyword_set(suffix) then suffix = ''

  dpath = root_data_dir() + 'maven/data/sci/swe/l3/swe_lpw_scpot/'
  froot = 'mvn_swe_lpw_scpot_'
  tname = ['mvn_lpw_swp1_IV_vinfl', $ ;'mvn_lpw_swp1_dIV_smo',
           'mvn_lpw_swp1_IV_vinfl_qflag', $
           'mvn_swe_lpw_scpot_lin_para', $
           'mvn_swe_lpw_scpot_pow_para', $
           'mvn_swe_lpw_scpot_pol_para', $
           'mvn_swe_lpw_scpot_Ndata', $
           'mvn_swe_lpw_scpot_lin', $
           'mvn_swe_lpw_scpot_pow', $
           'mvn_swe_lpw_scpot_pol', $
           'mvn_swe_lpw_scpot']
  maintname = 'mvn_swe_lpw_scpot'
  oneday = 86400D

;  if (size(interval,/type) eq 0) then interval = 1
  interval = 1
  if (size(ndays,/type) eq 0) then ndays = 7
  dt = double(interval)*oneday

  if size(start_day,/type) eq 0 then begin
     tr = timerange()
     start_day = tr[0]
     ndays = floor( (tr[1]-tr[0])/oneday )
  endif


  start_day2 = time_double(time_string(start_day,prec=-3))
  end_day = time_double(time_string(start_day2+ndays*oneday,prec=-3))

  if keyword_set(norbwin) then nd = ceil(4.5*norbwin/24+2) $
  else nd = 9
  timespan, [start_day2-long(nd/2)*oneday, end_day+long(nd/2)*oneday]

  ;;; load and process
  s = execute( 'mvn_swe_lpw_scpot, norbwin=norbwin, _extra=_extra' )
  if ~s then begin
     dprint,'mvn_swe_lpw_scpot failed'
     return
  endif


  ;;; trim data and save
  for itn=0,n_elements(tname)-1 do tplot_rename,tname[itn],tname[itn]+'_all'
  for i=0L,(ndays - 1L) do begin
    tstart = start_day2 + double(i)*dt

    opath = dpath + time_string(tstart,tf='YYYY/MM/')
    file_mkdir2, opath, mode='0775'o  ; create directory structure, if needed
    ofile = opath + froot + time_string(tstart,tf='YYYYMMDD') + suffix

    get_data,maintname+'_all',data=dmain,dtype=dmaintype ;- skip if no main data
    if dmaintype eq 0 then continue
    w = where( dmain.x ge tstart and dmain.x lt tstart+oneday , nw)
    if nw eq 0 then continue

    store_data,tname,/del
    for itn=0,n_elements(tname)-1 do begin
       get_data,tname[itn]+'_all',data=d,dlim=dlim,dtype=dtype
       if dtype eq 0 then continue
       w = where( d.x ge tstart and d.x lt tstart+oneday , nw)
       if nw eq 0 then continue
       if tag_exist(d,'v') then begin
          if size(d.v,/n_dimen) eq 2 then newd = {x:d.x[w],y:d.y[w,*],v:d.v[w,*]} else newd = {x:d.x[w],y:d.y[w,*],v:d.v}
       endif else begin
          if size(d.y,/n_dimen) eq 2 then newd = {x:d.x[w],y:d.y[w,*]} else newd = {x:d.x[w],y:d.y[w]}
       endelse
       store_data,tname[itn],data=newd,dlim=dlim
    endfor
    validtname = tnames(tname,n)
    if n gt 0 then begin
       tplot_save,validtname,file=ofile,/compress
       file_chmod,ofile+'.tplot','664'o
    endif
 endfor

  for itn=0,n_elements(tname)-1 do tplot_rename,tname[itn]+'_all',tname[itn]
  if size(tr,/type) ne 0 then timespan,tr else timespan, start_day, ndays

  return

end

