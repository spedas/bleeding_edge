pro spp_swp_gse_pressure_file_read,files,dat=dat,last_version=last_version,time_offset=time_offset
  if n_elements(last_version) eq 0 then last_version=1

  ; files =  spp_file_retrieve( 'spp/data/sci/sweap/prelaunch/gsedata/realtime/cal/chamberpressure/Vacuum_201610??.dat' )
  if ~keyword_set(files) then   files =  spp_file_retrieve( 'spp/data/sci/sweap/prelaunch/gsedata/realtime/cal/chamberpressure/Vacuum_????????.dat',last_version=last_version )
  dat = dynamicarray(name='vacuumpressure')
  if n_elements(time_offset) eq 0 then   time_offset= 7*3600d   ; cluge for local time shift
  for i=0,n_elements(files)-1 do begin

    file_open,'r',files[i],unit=lun
    s=''
    while ~eof(lun) do begin
      readf,lun,s
      ss = strsplit(s,' ',/extract)
      fst=fstat(lun)
      dprint,dlevel=3,dwait=10,'Percent completion: ',fst.cur_ptr*100./fst.size
      ;    printdat,ss
      if n_elements(ss) eq 6 then begin
        m_d_y = strsplit(/extract,ss[0],'/')
        h_m_s = strsplit(/extract,ss[1],':')
        if h_m_s[0] eq  '12' then h_m_s[0] ='00'
        tstring = strjoin([ m_d_y[[2,0,1]],h_m_s ] ,' ')
        ;     printdat,tstring,/value
        time = time_double(tstring,is_local_time=0)
        if ss[2] eq 'PM' then time += 3600d*12
        time += time_offset
        ;      printdat, time_string(time),/value
        pressures=float(ss[[3,4,5]])
        if pressures[0] gt 1000 then pressures[0] = !values.f_nan
        if pressures[1] gt 1000 then pressures[1] = !values.f_nan
        if pressures[2] gt 1000 then pressures[2] = !values.f_nan
        if pressures[1] eq 0 then pressures[1] = .0001
        best = finite(pressures[0]) ? pressures[0] : pressures[1]
        dat.append , {time:time, all: pressures,combined:best,gap:0b}
      endif
    endwhile
    free_lun,lun
  endfor
  store_data,'Pressure_',data=dat.array,tagnames='*',gap_tag='GAP'
  ylim,'Pressure_*',1,1,1,/default
end