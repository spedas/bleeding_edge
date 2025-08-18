FUNCTION mms_bss_history_cat, bsh, category, wt
  compile_opt idl2
  wcat = lonarr(n_elements(wt)); output
  s = mms_bss_query(bss=bsh, category=category)
  if n_tags(s) eq 0 then return, wcat
  imax = n_elements(s.FOM); number of filtered-out segments
  for i=0,imax-1 do begin; For each segment
    ndx = where( (s.UNIX_CREATETIME[i] le wt) and (wt le s.UNIX_FINISHTIME[i]), ct); extract pending period
    wcat[ndx] += s.SEGLENGTHS[i]; count segment size
  endfor
  return, wcat
END

FUNCTION mms_bss_history_threshold, wt
  compile_opt idl2
  hard_limit = 24576L
  nmax=n_elements(wt)
  wthres = lonarr(nmax)

  ; DEFAULT VALUE
  wthres[0:nmax-1] = hard_limit-0L;18000L

  ; MANUALLY CHANGED VALUES
  mmax = 100L
  change_date = strarr(mmax)
  change_val  = lonarr(mmax)
  m=0 & change_date[m] = '2015-08-04'       & change_val[m] = 15000L
  m=1 & change_date[m] = '2016-01-18/17:30' & change_val[m] = 14000L
  m=2 & change_date[m] = '2016-01-26/23:00' & change_val[m] = 13000L
  m=3 & change_date[m] = '2016-02-01/16:50' & change_val[m] = 12000L
  m=4 & change_date[m] = '2016-02-08/17:45' & change_val[m] = 11000L
  m=5 & change_date[m] = '2016-02-21/16:06' & change_val[m] = 10000L
  m=6 & change_date[m] = '2016-03-14/17:00' & change_val[m] = 11500L
  m=7 & change_date[m] = '2016-03-25/20:25' & change_val[m] = 12500L
  m=8 & change_date[m] = '2016-03-28/15:16' & change_val[m] = 13000L
  m=9 & change_date[m] = '2016-04-04/16:40' & change_val[m] = 14000L
  m=10 & change_date[m] = '2016-04-11/17:30' & change_val[m] = 15000L
  m=11 & change_date[m] = '2016-12-05/00:00' & change_val[m] = 14000L
  m=12 & change_date[m] = '2016-12-12/00:00' & change_val[m] = 13000L
  m=13 & change_date[m] = '2016-12-19/00:00' & change_val[m] = 12000L
  m=14 & change_date[m] = '2016-12-26/00:00' & change_val[m] = 11000L
  m=15 & change_date[m] = '2017-01-02/00:00' & change_val[m] = 10000L
  m=16 & change_date[m] = '2017-03-01/00:00' & change_val[m] = 11000L
  m=17 & change_date[m] = '2017-03-09/00:00' & change_val[m] = 12000L
  m=18 & change_date[m] = '2017-03-13/00:00' & change_val[m] = 13000L
  m=19 & change_date[m] = '2017-03-20/00:00' & change_val[m] = 14000L
  m=20 & change_date[m] = '2017-03-27/00:00' & change_val[m] = 15000L
  m=21 & change_date[m] = '2017-04-03/00:00' & change_val[m] = 16000L
  m=22 & change_date[m] = '2017-04-10/00:00' & change_val[m] = 18000L
  m=23 & change_date[m] = '2017-04-19/00:00' & change_val[m] = 19150L
  m=24 & change_date[m] = '2017-09-11/00:00' & change_val[m] = 17350L
  m=25 & change_date[m] = '2018-12-17/00:00' & change_val[m] = 16500L
  m=26 & change_date[m] = '2019-04-26/00:00' & change_val[m] = 18000L
  m=27 & change_date[m] = '2020-06-24/00:00' & change_val[m] = 16576L



  idx=where(change_val gt 0,ct)
  mmax = ct

  ; MAIN LOOP
  for m=0,mmax-1 do begin
    stime = time_double(change_date[m])
    etime = systime(/utc,/seconds)
    idx=where(stime le wt and wt lt etime, ct)
    if ct gt 0 then begin
      wthres[idx] = hard_limit - change_val[m]
    endif
  endfor

  return, wthres
END

PRO mms_bss_history, tplot=tplot, csv=csv, dir=dir, trange=trange, interval=interval
  compile_opt idl2
  mms_init
  clock=tic('mms_bss_history')
  if undefined(dir) then dir = '' else dir = spd_addslash(dir)
  if undefined(interval) then interval=60.0d
  print,'--------'
  print,'mms_bss_history3'
  print,'--------'
  
  ;----------------
  ; CATCH
  ;----------------
  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    eva_error_message, error_status
    message, /reset
    return
  endif

  ;----------------
  ; TIME
  ;----------------
  tnow = systime(/utc,/seconds)
  tlaunch = time_double('2015-03-13/00:00');time_double('2015-03-12/22:44')
  t3m = tnow - 180.d0*86400.d0; 180 days
  tr = [t3m,tnow]
  if not undefined(trange) then begin
    if trange[0] lt tlaunch then trange[0] = tlaunch
     tr = trange
  endif
  trange = time_string(tr)
  

  ; time grid to be used for Pending buffer history
  ;mmax = 4320L ; extra data point for displaying grey-shaded region
  ;dt = 60.d0
  dt = interval
  nmax = floor((tr[1]-tr[0])/dt)
  wt = tr[0]+ dindgen(nmax)*dt

  ; time grid to be used for daily values
  day_start = time_double(strmid(trange[0],0,10))
  dt = 86400.d0
  rmax = floor((tr[1]-day_start)/dt)
  wtday = day_start+dindgen(rmax+1)*dt

  fomrng = mms_bss_fomrng(wt)
  ;----------------
  ; LOAD DATA
  ;----------------
  RESTORE=0
  case RESTORE of
    0:begin
      if n_elements(bss) eq 0 then begin
        print, '.... loading bss data ....'
        bss = mms_bss_query(trange=trange)
      endif
      save,bss,filename='bss.sav'
      end
    1:restore,filename='bss.sav'
    else:
  endcase
  
  ;---------------------------
  ; MAIN LOOP
  ;---------------------------
  ; For each segment (except bad segments and DELETED segments)
  ; find its category and status
  ;    0: Overwritten
  ;    1: Complete+Finished (Transmitted)
  ;    2: Held
  ;    3: New
  iHeld = 0
  iOver = 1
  iNew  = 2
  iTrns = 3
  iDiff = 4
  
  pmax = 5; category
  qmax = 5; output type
  wcat = lonarr(nmax,pmax,qmax); The main output
  imax = n_elements(bss.FOM); number of filtered-out segments
  wNewA = lonarr(nmax); The secondary output
  wNewP = lonarr(nmax)
  wNewO = lonarr(nmax)
  wNewT = lonarr(nmax)
  
  for i=0,imax-1 do begin; For each segment
    
    ; timestamps
    ndx = where( (bss.UNIX_CREATETIME[i] le wt) and (wt lt bss.UNIX_FINISHTIME[i]), ct); extract pending period
    if ct gt 0 then begin

      ; location in wt of the created time
      result = min(wt-bss.UNIX_CREATETIME[i],Ncre, /nan,/abs)
      ; location in wt of the finished day
      str_day_start = strmid(time_string(bss.UNIX_FINISHTIME[i]),0,10)
      ts = time_double(str_day_start) & te = ts + 86400.d0
      mdx = where( (ts le wt) and (wt lt te), ct)
      ; location in wt of the created day
      str_day_start = strmid(time_string(bss.UNIX_CREATETIME[i]),0,10)
      ts = time_double(str_day_start) & te = ts + 86400.d0
      odx = where( (ts le wt) and (wt lt te), ct)
  
      ;Find the category
      cat = 4
      for p=0,pmax-1 do begin
        if (fomrng[p,0,Ncre] le bss.FOM[i]) and (bss.FOM[i] lt fomrng[p,1,Ncre]) then begin
          cat = p
        endif
      endfor
      wcat[ndx,cat,iHeld] += bss.SEGLENGTHS[i]
      wcat[odx,cat,iNew]  += bss.SEGLENGTHS[i]
      wNewA[odx] += bss.SEGLENGTHS[i]
      
      if not strmatch(bss.STATUS[i],'*INCOMPLETE*') then begin
        
        ; Overwritten?
        if strmatch(bss.STATUS[i],'*DERELICT*') or strmatch(bss.STATUS[i],'*DEMOTED*') then begin
          wcat[mdx,cat,iOver] += bss.SEGLENGTHS[i]
          wNewO[odx] += bss.SEGLENGTHS[i]
        endif
      
        ; Transmission completed segments
        if (strmatch(bss.STATUS[i],'*COMPLETE*') and strmatch(bss.STATUS[i],'*FINISHED*')) then begin
          wNewT[odx] += bss.SEGLENGTHS[i]
        endif
      endif
  
      wNewP[odx] = wNewA[odx]-(wNewT[odx]+wNewO[odx])
    endif
  endfor
  
  
  ; Find the start and stop points of the day (in wt)
  hts = time_double(strmid(time_string(wt),0,10))
  hte = hts+86400.d0
  nts = lonarr(nmax)
  nte = lonarr(nmax)
  for n=0,nmax-1 do begin
    result = min(wt-hts[n],nns, /nan,/abs)
    nts[n] = nns
    result = min(wt-hte[n],nne, /nan,/abs)
    nte[n] = nne
  endfor
  
  for p=0,pmax-1 do begin; for each category
  for n=0,nmax-1 do begin; for each time stamp
    ;if(n mod 1000 eq 0) then print, 100.*float(n)/float(nmax)," %"
    wcat[n,p,iDiff] = wcat[nte[n],p,iHeld]-wcat[nts[n],p,iHeld]; Difference of the day
    wcat[n,p,iTrns] = wcat[n,p,iNew] - wcat[n,p,iOver] - wcat[n,p,iDiff]
  endfor     
  endfor
  
  wthres = mms_bss_history_threshold(wt)
  
  ;------------------
  ; TPLOT
  ;------------------
  if keyword_set(tplot) then begin
  
    ; HELD segments
    wout  = lonarr(nmax,6)
    wout[*,5] = mms_bss_history_threshold(wt); Threshold
    wout[*,0] = wcat[*,0,iHeld]            ; Category 0
    wout[*,1] = wcat[*,1,iHeld]; + wout[*,0]; Category 0 + 1
    wout[*,2] = wcat[*,2,iHeld]; + wout[*,1]; Category 0 + 1 + 2
    wout[*,3] = wcat[*,3,iHeld]; + wout[*,2]; Category 0 + 1 + 2 + 3
    wout[*,4] = wcat[*,4,iHeld]; + wout[*,3]; Category 0 + 1 + 2 + 3 + 4
    store_data,'mms_bss_history',data={x:wt, y:wout, v:[0,1,2,3,4,5]}
    options,'mms_bss_history',colors=[1,6,5,4,2,3],ytitle='HELD Buffers',$
      title='MMS Burst Memory Management',labels=['Cat 0','Cat 1',$
      'Cat 2','Cat 3','Cat 4','Thres'],labflag=-1

    ; Overwritten segments of the day
    wovr  = lonarr(nmax,5)
    wovr[*,0] = wcat[*,0,iOver]            ; Category 0
    wovr[*,1] = wcat[*,1,iOver]; + wovr[*,0]; Category 0 + 1
    wovr[*,2] = wcat[*,2,iOver]; + wovr[*,1]; Category 0 + 1 + 2
    wovr[*,3] = wcat[*,3,iOver]; + wovr[*,2]; Category 0 + 1 + 2 + 3
    wovr[*,4] = wcat[*,4,iOver]; + wovr[*,3]; Category 0 + 1 + 2 + 3 + 4
    store_data,'mms_bss_overwritten',data={x:wt, y:wovr, v:[0,1,2,3,4]}
    options,'mms_bss_overwritten',colors=[1,6,5,4,2],ytitle='Overwritten',$
      labels=['Cat 0','Cat 1','Cat 2','Cat 3','Cat 4'],labflag=-1

    ; New segments of the day
    wout  = lonarr(nmax,5)
    wout[*,0] = wcat[*,0,iNew]            ; Category 0
    wout[*,1] = wcat[*,1,iNew]; + wout[*,0]; Category 0 + 1
    wout[*,2] = wcat[*,2,iNew]; + wout[*,1]; Category 0 + 1 + 2
    wout[*,3] = wcat[*,3,iNew]; + wout[*,2]; Category 0 + 1 + 2 + 3
    wout[*,4] = wcat[*,4,iNew]; + wout[*,3]; Category 0 + 1 + 2 + 3 + 4
    store_data,'mms_bss_new',data={x:wt, y:wout, v:[0,1,2,3,4]}
    options,'mms_bss_new',colors=[1,6,5,4,2],ytitle='NEW Buffers',$
      labels=['Cat 0','Cat 1','Cat 2','Cat 3','Cat 4'],labflag=-1

    ; Transmitted segments of the day
    wout  = lonarr(nmax,5)
    wout[*,0] = wcat[*,0,iTrns]            ; Category 0
    wout[*,1] = wcat[*,1,iTrns] + wout[*,0]; Category 0 + 1
    wout[*,2] = wcat[*,2,iTrns] + wout[*,1]; Category 0 + 1 + 2
    wout[*,3] = wcat[*,3,iTrns] + wout[*,2]; Category 0 + 1 + 2 + 3
    wout[*,4] = wcat[*,4,iTrns] + wout[*,3]; Category 0 + 1 + 2 + 3 + 4
    store_data,'mms_bss_trns',data={x:wt, y:wout, v:[0,1,2,3,4]}
    options,'mms_bss_trns',colors=[1,6,5,4,2],ytitle='Transmitted Buffers',$
      labels=['Cat 0','Cat 1','Cat 2','Cat 3','Cat 4'],labflag=-1

    ; NEW SEGMENTS and their status
    wnew = lonarr(nmax,3)
    wnew[*,2] = wNewT ;   Finished
    wnew[*,1] = wnew[*,2] + wNewO ; Finished + Overwritten
    wnew[*,0] = wnew[*,1] + wNewP ; Finished + Overwritten + Pending
    store_data,'mms_new_segs',data={x:wt, y:wnew, v:[0,1,2]}
    options,'mms_new_segs',colors=[2,6,4],ytitle='New Segs',labels=['Pending','Overwritten','Finished'],$
      labflag=-1
      
    ; PLOT
    timespan,time_string(tr[0]),tr[1]-tr[0]+3.d0*86400.d0,/seconds
    tplot,['mms_bss_'+['history','overwritten','new','trns'],'mms_new_segs']
  endif

  ;------------------
  ; CSV
  ;------------------
  if keyword_set(csv) then begin

    print,'n_elements(wt)=', n_elements(wt)
    ; HELD
    write_csv, dir+'mms_bss_history_held.txt', time_string(wt),$
      wcat[*,0,iHeld],wcat[*,1,iHeld],wcat[*,2,iHeld],wcat[*,3,iHeld],wcat[*,4,iHeld],wthres,$
      HEADER=['time','Category 0','Category 1','Category 2','Category 3','Category 4','Thres']
      
    ; Overwritten, New, Trns
    wname = ['over','new','trns']
    for s=1,3 do begin
      write_csv, dir+'mms_bss_history_'+wname[s-1]+'.txt', time_string(wt),$
      wcat[*,0,s],wcat[*,1,s],wcat[*,2,s],wcat[*,3,s],wcat[*,4,s],$
      HEADER=['time','Category 0','Category 1','Category 2','Category 3','Category 4']
    endfor
    
    ; New and their status
    write_csv, dir+'mms_bss_history_status.txt',time_string(wt),wNewA, wNewO, wNewP, wNewT,$
      HEADER=['time','wNewA','wNewO','wNewP','wNewT']

  endif

  toc, clock

END
