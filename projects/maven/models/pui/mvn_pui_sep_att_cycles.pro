;20170207 Ali
;counts the number of times each SEP attenuator actuates per day

pro mvn_pui_sep_att_cycles

  secinday=86400L ;number of seconds in a day
  timespan,['13-11-1','14-9-1']
  get_timespan,trange
  ndays=round((trange[1]-trange[0])/secinday) ;number of days

  s1c=replicate(0,ndays) ;sep1 att actuation counts
  s2c=replicate(0,ndays) ;sep2 att actuation counts
  
  for j=0,ndays-1 do begin ;loop over days

    tr=trange[0]+[j,j+1]*secinday ;one day
    timespan,tr

    file=mvn_pfp_file_retrieve('maven/data/sci/sep/l1/sav/YYYY/MM/mvn_sep_l1_YYYYMMDD_1day.sav',/daily) ;SEP L1 data
    if ~file_test(file) then continue
    restore,file
    if ~keyword_set(s1_svy) then continue

    nt1=n_elements(s1_svy)
    nt2=n_elements(s2_svy)

    for it1=1,nt1-1 do begin
      if (s1_svy[it1].att ne 0) and (s1_svy[it1-1].att ne 0) and (s1_svy[it1].att ne s1_svy[it1-1].att) then s1c[j]+=1
    endfor

    for it2=1,nt2-1 do begin
      if (s2_svy[it2].att ne 0) and (s2_svy[it2-1].att ne 0) and (s2_svy[it2].att ne s2_svy[it2-1].att) then s2c[j]+=1
    endfor

  endfor
  stop

end