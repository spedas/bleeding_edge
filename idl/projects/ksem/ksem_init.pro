
function ksem_spc_met_to_unixtime,met
  epoch =  946771200d - 12L*3600   ; long(time_double('2000-1-1/12:00'))  ;Early SWEM definition
  epoch = 978307200  ; long(time_double('2001-1-1/00:00'))
  ;  epoch =  1262304000   ; long(time_double('2010-1-1/0:00'))  ; Correct SWEM use
  unixtime =  met +  epoch
 ; dprint,dlevel=4,time_string(unixtime),met
  return,unixtime
end



function ksem_thermistor_temp,R,parameter=p,b2252=b2252,L1000=L1000
  if not keyword_set(p) then begin
    p = {func:'ksem_thermistor_temp',note:'YSI 46006 (H10000)',R0:10000.,  $
      T0:24.988792d, t1:-24.809236d, t2:1.6864476d, t3:-0.12038317d, $
      t4:0.0081576555d, t5:-0.00057545026d ,t6:3.1337558d-005}
    if keyword_set(B2252) then p={func:'ksem_thermistor_temp',note:'YSI (B2252)',R0:2252.,  $
      T0:24.990713d, t1:-22.808501d, t2:1.5334736d, t3:-0.10485403d, $
      t4:0.0076653446d, t5:-0.00084656440d ,t6:6.1095571d-005}
    if keyword_set(L1000) then p={func:'ksem_thermistor_temp',note:'YSI (L1000)',R0:1000.,  $
      T0:25.00077d, t1:-27.123102d, t2:2.2371834d, t3:-0.20295066d, $
      t4:0.022239779d, t5:-0.0024144851d ,t6:0.00013611146d}
    ;    if keyword_set(YSI4908) then p = {func:'ksem_thermistor_temperature_ysi4908',note:'YSI4908'}
  endif
  if n_params() eq 0 then return,p

  x = alog(R/p.r0)
  T = p.t0 + p.t1*x + p.t2*x^2 + p.t3*x^3 + p.t4*x^4 +p.t5*x^5 +p.t6*x^6
  return,t

end




function ksem_therm_temp,dval,parameter=p
  if not keyword_set (p) then begin
    ;    p = {func:'mvn_sep_therm_temp2',R1:10000d, xmax:1023d, Rv:1d8, thm:ksem_thermistor_temp()}
    p = {func:'ksem_therm_temp',R1:10000d, xmax:1023d, Rv:1d7, thm:'thermistor_resistance_ysi4908'}
  endif

  if n_params() eq 0 then return,p

  ;print,dval
  x = dval/p.xmax
  rt = p.r1*(x/(1-x*(1+p.R1/p.Rv)))
  tc = thermistor_resistance_ysi4908(rt,/inverse)
  ; print,dval,x,rt,tc
  return,float(tc)
end


;coeff = [0.00E+00,  0.00E+00,  -5.76E-20, 5.01E-15,  -1.68E-10, 2.69E-06,  -2.33E-02, 9.33E+01]



function ksem_swp_word_decom,buffer,n,signed=signed
  return,   swap_endian(/swap_if_little_endian,  uint(buffer,n) )
end

function ksem_swp_int4_decom,buffer,n
  return,   swap_endian(/swap_if_little_endian,  long(buffer,n) )
end

function ksem_swp_float_decom,buffer,n
  return,   swap_endian(/swap_if_little_endian,  float(buffer,n) )
end




function ksem_log_message_decom,ccsds, ptp_header=ptp_header, apdat=apdat
  ;  printdat,ccsds
  ;  time=ccsds.time
  ;  printdat,ptp_header
  ;  hexprint,ccsds.data
  time = ptp_header.ptp_time
  msg = string(ccsds.data[10:*])
  dprint,dlevel=2,time_string(time)+  ' "'+msg+'"'
  str={time:time,seq:ccsds.seq_cntr,size:ccsds.size,msg:msg}
  return,str
end


function ksem_power_supply_decom,ccsds,ptp_header=ptp_header,apdat=apdat
  ;  str = create_struct(ptp_header,ccsds)
  str = 0
  ;  dprint,format="('Generic routine for ',Z04)",ccsds.apid
  size = ccsds.size+7
  b = ccsds.data[12:*]
  if debug(3) then begin
    dprint,dlevel=2,'power supply',ccsds.size+7, n_elements(ccsds.data),'  ',time_string(ccsds.time,/local)
    hexprint,ccsds.data
  endif
  case size of
    22: begin
      b = [ b , byte( ['80'x,'00'x] ) ]  ;; correct error of truncation of data array
      ;     hexprint,b
      ;     dprint,ksem_swp_float_decom(b,4),ksem_swp_float_decom(b,8)
      str= { time: ptp_header.ptp_time, $
        gun_v: ksem_swp_float_decom(b,4), $
        gun_i: ksem_swp_float_decom(b,8), $
        gap: 0}
    end
    60:
    else: dprint,'Unknown size'
  endcase
  ;  printdat,time_string(ptp_header.ptp_time,/local)
  ; printdat,str
  return,str
end





function ksem_generic_decom,ccsds,ptp_header=ptp_header,apdat=apdat
  ;  ccsds.time = ptp_header.ptp_time
  str = create_struct(ptp_header,ccsds)

  ;  dprint,format="('Generic routine for ',Z04)",ccsds.apid
  if debug(3) && 1 then begin
    dprint,dlevel=2,'generic',ccsds.size+7, n_elements(ccsds.data),  ccsds.apid
    hexprint,ccsds.data
  endif
  return,str
end



function  ksem_find_peak,d,cbins,window = wnd,threshold=threshold
  nan = !values.d_nan
  peak = {a:nan, x0:nan, s:nan}
  if n_params() eq 0 then return,peak
  if not keyword_set(cbins) then cbins = dindgen(n_elements(d))

  if keyword_set(wnd) then begin
    mx = max(d,b)
    i1 = (b-wnd) > 0
    i2 = (b+wnd) < (n_elements(d)-1)
    ;    dprint,wnd
    pk = ksem_find_peak(d[i1:i2],cbins[i1:i2],threshold=threshold)
    return,pk
  endif
  if keyword_set(threshold) then begin
    dprint,'not functioning'
  endif

  t = total(d)
  avg = total(d * cbins)/t
  sdev = sqrt(total(d*(cbins-avg)^2)/t)
  peak.a=t
  peak.x0=avg
  peak.s=sdev
  return,peak
end




function ksem_noise_decom,ccsds,ptp_header=ptp_header,apdat=apdat

  if debug(3) && 1 then begin
    dprint,dlevel=2,'noise',ccsds.size+7, n_elements(ccsds.data),  ccsds.apid,' ',time_string(ccsds.time)
    ;    hexprint,ccsds.data
  endif

  if ccsds.size+7 ne 180 then begin
    if debug(1) then begin
      dprint,dlevel=2,'noise',ccsds.size+7, n_elements(ccsds.data),  ccsds.apid
      hexprint,ccsds.data
    endif
    return,0
  endif

  dat = swap_endian(/swap_if_little_endian,  uint(ccsds.data[20:*],0,80) )

  ;  if debug(3)  then dprint,time_string(ccsds.time)
  t = ccsds.time

  ;printdat,apdat.last_ccsds
  if ptr_valid(apdat.usr_ptr) && keyword_set(*apdat.usr_ptr) then begin
    delta_data = uint(dat - *apdat.usr_ptr)
    delta_seq_cntr = (ccsds.seq_cntr - (*apdat.last_ccsds).seq_cntr) and '3fff'x
    ;    printdat,delta_seq_cntr
    ddata = float(delta_data)/delta_seq_cntr

    p= replicate(ksem_find_peak(),8)

    noise_res = 3  ; temporary fix - needs to be obtained from hkp packets

    x = (dindgen(10)-4.5) * ( 2d ^ (noise_res-3))
    d = reform(ddata,10,8)
    for j=0,7 do begin
      ;     p[j] = ksem_find_peak(d[*,j],x)
      p[j] = ksem_find_peak(d[0:8,j],x[0:8])   ; ignore end channel
    endfor
    ;    printdat,p

    str = { $
      time: t, $
      seq_cntr: ccsds.seq_cntr, $
      ddata: ddata, $
      num: p.a,   $
      baseline : p.x0,  $
      sigma: p.s,  $
      gap:0 }
  endif else     str = 0
  *apdat.usr_ptr = dat

  return,str
end


function ksem_labels
  lbls =  strsplit('.... ...O ..U. ..UO .T.. .T.O .TU. .TUO F... F..O F.U. F.UO FT.. FT.O FTU. FTUO',/extract)
  lbls =  strsplit('X O U UO T TO TU TUO F FO FU FUO FT FTO FTU FTUO',/extract)
  return, lbls
end



function ksem_hkp_decom,ccsds,ptp_header=ptp_header,apdat=apdat

  ;  ccsds.time = ptp_header.ptp_time
  ;  str = create_struct(ptp_header,ccsds)

  ;  dprint,format="('Generic routine for ',Z04)",ccsds.apid
  if debug(3) && 1 then begin
    dprint,dlevel=2,'hkp',ccsds.size+7, n_elements(ccsds.data),  ccsds.apid,' ',time_string(ccsds.time)
    hexprint,ccsds.data[0:31]
  endif

  if n_elements(ccsds.data) ne 76 then begin
    dprint,dlevel=2,'HKP Packet size error ', n_elements(ccsds.data)
    return, 0
  endif

  t = ccsds.time
  b = ccsds.data[20:*]


  d = swap_endian(/swap_if_little_endian,  uint(ccsds.data[20:*],0,56/2) )
  err1 = d[24]
  err1s = [ishft(err1,-12),ishft(err1,-8),ishft(err1,-4),err1] and 'f'x
  err2 = d[25]
  err2s = [ishft(err2,-8),err2] and 'ff'x
  rates = d[16:23]
  ;  rates = rates[[0,1,3,2,4,5,7,6]]     ; remove this line when Jianxin fixes order
  noise_resolution= ishft(d[12],-8) and 7
  noise_rate= d[12] and 'ff'x
  str = {time:t ,$
    seq_cntr: ccsds.seq_cntr, $
    MON:  fix(d[0:7]),  $
    MAPID:  b[16],  $
    REV:    b[17], $
    vcmd_cntr: b[18], $
    icmd_cntr: b[19], $
    FTUO_flags: d[10],   $
    DETEN_flags: d[11], $
    NOISE_flags: d[12], $
    noise_res:  noise_resolution, $
    noise_rate:  noise_rate, $
    maddr: d[13], $
    chksum:  b[27], $
    pps:  b[28], $
    rates: rates, $
    err1: err1s , $
    err2: err2s , $
    gap:0 }
  if debug(3) then   printdat,str
  return,str
end



function ksem_science_decom,ccsds,ptp_header=ptp_header,apdat=apdat
  ;  ccsds.time = ptp_header.ptp_time
  ;  str = create_struct(ptp_header,ccsds)
  ;  dprint,format="('Generic routine for ',Z04)",ccsds.apid
  if debug(3) && 1 then begin
    dprint,dlevel=2,'science',ccsds.size+7, n_elements(ccsds.data),  ccsds.apid,' ',time_string(ccsds.time)

    hexprint,ccsds.data[0:31]
    ;    printdat,ccsds
  endif

  t = ptp_header.ptp_time
  t = ccsds.time

  if n_elements(ccsds.data) ne 532 then begin
    dprint,'Incorrect science packet size'
    dprint,phelp=2,ccsds
    return, 0
  endif

  d = swap_endian(/swap_if_little_endian,  uint(ccsds.data[20:*],0,256) )
  str = {time:t ,$
    seq_cntr: ccsds.seq_cntr, $
    data:  float(d) , $
    gap:0 }
  ;  hexprint,d
  ;  str={
  ;    time:ccsds.time
  ;    data = c
  return,str
end



function ksem_ccsds_decom,buffer             ; buffer should contain bytes for a single ccsds packet, header is contained in first 3 words (6 bytes)
  buffer_length = n_elements(buffer)
  if buffer_length lt 12 then begin
    dprint,'Invalid buffer length: ',buffer_length,dlevel=2
    return, 0
  endif
  header = swap_endian(uint(buffer[0:11],0,6) ,/swap_if_little_endian )
  MET = (header[3]*2UL^16 + header[4] + (header[5] and 'fffc'x)  / 2d^16) +( (header[5] ) mod 4) * 2d^15/150000

  utime = ksem_spc_met_to_unixtime(MET)
  ccsds = { $
    version_flag: byte(ishft(header[0],-8) ), $
    apid: header[0] and '7FF'x , $
    seq_group: ishft(header[1] ,-14) , $
    seq_cntr: header[1] and '3FFF'x , $
    size : header[2]   , $
    time: utime,  $
    MET:  MET,   $
    ;    time_diff: cmnblk.time - time, $   ; time to get transferred from PFDPU to GSEOS
    data:  buffer[0:*], $
    gap : 0b }

  if MET lt -1e5 then begin
    dprint,dlevel=1,'Invalid MET: ',MET,' For packet type: ',ccsds.apid
    ccsds.time = !values.d_nan
  endif

  ;  if ccsds.size ne (n_elements(ccsds.data))-7 then begin
  ;    dprint,dlevel=3,format='(a," x",z04,i7,i7)','CCSDS size error',ccsds.apid,ccsds.size,n_elements(ccsds.data)
  ;  endif

  return,ccsds

end






pro ksem_apid_data,apid,name=name,clear=clear,reset=reset,save=save,finish=finish,apdata=apdat,tname=tname,tfields=tfields,rt_tags=rt_tags,routine=routine,increment=increment,rt_flag=rt_flag
  common ksem_swp_raw_data_block_com, all_apdat
  if keyword_set(reset) then begin
    ptr_free,ptr_extract(all_apdat)
    all_apdat=0
    reset = 0
    return
  endif

  if ~keyword_set(all_apdat) then begin
    apdat0 = {  apid:-1 ,name:'',counter:0uL,nbytes:0uL, maxsize: 0,  routine:   '',   tname: '',  tfields: '',  rt_flag:0b, rt_tags: '', save:0b, $
      ;       status_ptr: ptr_new(), $
      last_ccsds: ptr_new(),  dataptr:  ptr_new(),   dataindex: ptr_new() , dlimits:ptr_new() , usr_ptr: ptr_new(Null)}
    all_apdat = replicate( apdat0,2^11 )
  endif
  if keyword_set(finish) then begin
    for i=0,n_elements(all_apdat)-1 do begin
      ap = all_apdat[i]
      if ptr_valid(ap.dataptr) then append_array,*ap.dataptr,index = *ap.dataindex
      if keyword_set(ap.tfields) then store_data,ap.tname,data= *ap.dataptr,tagnames=ap.tfields
    endfor
  endif

  if n_elements(apid) ne 0 then begin
    apdat = all_apdat[apid]
    if n_elements(name)     ne 0 then apdat.name = name
    if n_elements(routine)  ne 0 then apdat.routine=routine
    if n_elements(rt_flag)  ne 0 then apdat.rt_flag = rt_flag
    if n_elements(tname)    ne 0 then apdat.tname = tname
    if n_elements(tfields)  ne 0 then apdat.tfields = tfields
    if n_elements(save)     ne 0 then apdat.save   = save
    if n_elements(rt_tags)  ne 0 then apdat.rt_tags=rt_tags
    if keyword_set(increment) then apdat.counter += 1
    for i=0,n_elements(apdat)-1 do begin
      if apdat[i].apid lt 0 then begin
        if ~ptr_valid(apdat[i].last_ccsds) then apdat[i].last_ccsds = ptr_new(/allocate_heap)
        if ~ptr_valid(apdat[i].dataptr)    then apdat[i].dataptr    = ptr_new(/allocate_heap)
        if ~ptr_valid(apdat[i].dataindex)  then apdat[i].dataindex  = ptr_new(/allocate_heap)
        if ~ptr_valid(apdat[i].dlimits)    then apdat[i].dlimits    = ptr_new(/allocate_heap)
      endif
    endfor
    apdat.apid = apid
    all_apdat[apid] = apdat    ; put it all back in
  endif  else begin            ; all
    w= where(all_apdat.apid ge 0,nw)
    if nw ne 0 then begin
      if n_elements(rt_flag) ne 0 then all_apdat[w].rt_flag=rt_flag
      if n_elements(save) ne 0 then all_apdat[w].save=save
      apdat = all_apdat[w]
    endif else apdat=0
  endelse

  if keyword_set(clear) and keyword_set(apdat) then begin
    ptrs = ptr_extract(apdat,except=apdat.dlimits)
    for i=0,n_elements(ptrs)-1 do undefine,*ptrs[i]
    all_apdat.counter = 0   ; this is clearing all counters - not just the subset.
  endif
end


pro ksem_tplot_init
  tplot_options,'no_interp',1
  tplot_options,'wshow',0
  tplot_options,'lazy_ytitle',1
  options,'ksem?_noise_DDATA',spec=1,panel_size=3,yrange=[0,80],zrange=[0,100],constant=findgen(8)*10+5
  options,'ksem?_science_DATA',spec=1,panel_size=7
  ylim,'ksem?_science_DATA',-1,256,0
  zlim,'ksem?_science_DATA',.8,200,1
  options,'*FLAGS',tplot_routine='bitplot'
  ylim,'ksem?_hkp_RATES',.8,1e5 ,1
  options,'ksem?_hkp_RATES',psym=-1
  tplot,'ksem?_hkp_MON ksem?_hkp_RATES ksem?_hkp_MADDR ksem?_hkp_FTUO_FLAGS ksem?_science_DATA ksem?_noise_DDATA ksem?_noise_BASELINE ksem?_noise_SIGMA'
end


pro ksem_apid_data_init,save=save,rt_flag=rt_flag,reset=reset

  if keyword_set(reset) then ksem_apid_data,/reset
  if n_elements(rt_flag) eq 0 then   rt_flag=1
  ksem_apid_data,'36a'x ,routine='ksem_noise_decom',tname='ksem1_noise_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
  ksem_apid_data,'360'x ,routine='ksem_science_decom',tname='ksem1_science_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
  ksem_apid_data,'36e'x ,routine='ksem_hkp_decom',tname='ksem1_hkp_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag

  ksem_apid_data,'37a'x ,routine='ksem_noise_decom',tname='ksem2_noise_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
  ksem_apid_data,'370'x ,routine='ksem_science_decom',tname='ksem2_science_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
  ksem_apid_data,'37e'x ,routine='ksem_hkp_decom',tname='ksem2_hkp_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag

  ksem_apid_data,'38a'x ,routine='ksem_noise_decom',tname='ksem4_noise_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
  ksem_apid_data,'380'x ,routine='ksem_science_decom',tname='ksem4_science_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag
  ksem_apid_data,'38e'x ,routine='ksem_hkp_decom',tname='ksem4_hkp_',tfields='*',rt_tags='*', save=save,rt_flag=rt_flag

  ksem_apid_data,'7c0'x,routine='ksem_log_message_decom',tname='log_',tfields='MSG',save=save,rt_tags='MSG',rt_flag=1
  ksem_apid_data,'7c1'x,routine='ksem_power_supply_decom',tname='HV_',rt_tags='*_?',rt_flag=1,tfields='*'

  ksem_apid_data,apdat=ap
  print_struct,ap

end





pro ksem_ccsds_pkt_handler,buffer,ptp_header=ptp_header

  ccsds=ksem_ccsds_decom(buffer)
  
  ;hexprint,buffer

  if ~keyword_set(ccsds) then begin
    dprint,dlevel=2,'Invalid CCSDS packet'
    dprint,dlevel=2,time_string(ptp_header.ptp_time)
    ;    hexprint,buffer
    return
  endif

  bad_time_flag = ccsds.time lt 1451606400
  ;bad_time_flag = 1    ; Set to 1 if the MISG is working incorrectly
  ;bad_time_flag = 0    ; Set to 0 if the MISG is working correctly
  if bad_time_flag then begin     ; set to 1 to use MISG time
    dprint,dlevel=2,'Bad time detected. defaulting to MISG time',dwait=20
    ccsds.time = ptp_header.ptp_time  
  endif

  if 1 then begin
    ksem_apid_data,ccsds.apid,apdata=apdat,/increment
    if (size(/type,*apdat.last_ccsds) eq 8)  then begin    ; look for data gaps
      dseq = (( ccsds.seq_cntr - (*apdat.last_ccsds).seq_cntr ) and '3fff'x) -1
      if dseq ne 0  then begin
        ccsds.gap = 1
        dprint,dlevel=3,format='("Lost ",i5," ", Z03, " packets")',dseq,apdat.apid
      endif
    endif
    if keyword_set(apdat.routine) then begin
      strct = call_function(apdat.routine,ccsds,ptp_header=ptp_header,apdat=apdat)
      if  apdat.save && keyword_set(strct) then begin
        if ccsds.gap eq 1 then append_array, *apdat.dataptr, fill_nan(strct), index = *apdat.dataindex
        append_array, *apdat.dataptr, strct, index = *apdat.dataindex
      endif
      if apdat.rt_flag && apdat.rt_tags then begin
        if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
        store_data,apdat.tname,data=strct, tagnames=apdat.rt_tags, /append
      endif
    endif
    *apdat.last_ccsds = ccsds
  endif

end



function ptp_pkt_add_header,buffer,time=time,spc_id=spc_id,path=path,source=source

  if ~keyword_set(time) then time=systime(1)
  if ~keyword_set(spc_id) then spc_id = 187
  if ~keyword_set(path) then path = 'a200'x
  if ~keyword_set(source) then source = 'a0'x
  size = n_elements(buffer)

  st = time_struct(time)
  day1958 = uint(st.daynum -714779)
  msec =  ulong(st.sod * 1000)
  usec = 0U

  b_size    = byte( swap_endian(/swap_if_little_endian, uint(size+17)), 0 ,2)
  b_sc_id   = byte( swap_endian(/swap_if_little_endian, uint(spc_id)), 0 ,2)
  b_day1958 = byte( swap_endian(/swap_if_little_endian, uint(day1958)), 0 ,2)
  b_msec    = byte( swap_endian(/swap_if_little_endian, ulong(msec)), 0 ,4)
  b_usec    = byte( swap_endian(/swap_if_little_endian, uint(usec)), 0 ,2)
  b_source  = byte(source)
  b_spare   = byte(0)
  b_path    = byte( swap_endian(/swap_if_little_endian, uint(path)), 0 ,2)

  hdr = [b_size, 3b, b_sc_id, b_day1958, b_msec, b_usec, b_source, b_spare, b_path]
  return, size ne 0 ? [hdr,buffer] : hdr
end



;+
;ksem_ptp_pkt_handler
; :Description:
;    Processes a single PTP packet
;
; :Params:
;    buffer - Array of bytes
;
; :Keywords:
;    time
;    size
;
; :Author: davin  Jan 1, 2015
;
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;
;-
pro ksem_ptp_pkt_handler,buffer,time=time,size=ptp_size
  if n_elements(buffer) le 2 then begin
    dprint,'buffer too small!'
    return
  endif
  ptp_size = swap_endian( uint(buffer,0) ,/swap_if_little_endian)   ; first two bytes provide the size
  if ptp_size ne n_elements(buffer) then begin
    dprint,time_string(time,/local_time),' PTP size error- size is ',ptp_size
    ;    hexprint,buffer
    ;    savetomain,buffer,time
    ;    stop
    return
  endif
  ptp_code = buffer[2]
  if ptp_code eq 0 then begin
    dprint,'End of Transmission Code'
    printdat,buffer
    return
  endif
  if ptp_code eq 'ff'x then begin
    dprint,'PTP Message ',ptp_size
    dprint,string(buffer[3:*])
    return
  endif
  if ptp_code ne 3 then begin
    dprint,'Unknown PTP code: ',ptp_code
    return
  endif
  ga   = buffer[3:16]
  sc_id = swap_endian(/swap_if_little_endian, uint(ga,0))
  days  = swap_endian(/swap_if_little_endian, uint(ga,2))
  ms    = swap_endian(/swap_if_little_endian, ulong(ga,4))
  us    = swap_endian(/swap_if_little_endian, uint(ga,8))
  source   =    ga[10]
  spare    =    ga[11]
  path  = swap_endian(/swap_if_little_endian, uint(ga,12))
  utime = (days-4383L) * 86400L + ms/1000d
  if utime lt   1425168000 then utime += us/1d4   ;  correct for error in pre 2015-3-1 files
  if keyword_set(time) then dt = utime-time  else dt = 0
  ;  dprint,dlevel=4,time_string(utime,prec=3),ptp_size,sc_id,days,ms,us,source,path,dt,format='(a,i6," x",Z04,i6,i9,i6," x",Z02," x",Z04,f10.2)'
  if ptp_size le 17 then begin
    dprint,dlevel=2,dwait=60.,'PTP size error - not enough bytes: '+strtrim(ptp_size,2)+ ' '+time_string(utime)
    if debug(3) then hexprint,buffer
    return
  endif
  ptp_header ={ ptp_time:utime, ptp_scid: sc_id, ptp_source:source, ptp_spare:spare, ptp_path:path, ptp_size:ptp_size }
  ksem_ccsds_pkt_handler, buffer[17:*],ptp_header = ptp_header
  ; printdat,time_string(ptp_header.ptp_time)
  return
end




pro ksem_msg_pkt_handler,buffer,time=time
  source = 0b
  spare = 0b
  ptp_scid = 0u
  path =  0u
  ptp_size = 0u
  utime = time
  ptp_header ={ ptp_time:utime, ptp_scid: 0u, ptp_source:source, ptp_spare:spare, ptp_path:path, ptp_size:ptp_size }
  ksem_ccsds_pkt_handler,buffer,ptp_header = ptp_header
  return
end


function ksem_swemulator_time_status,buffer   ;  decoms 12 Word time and status message from SWEMulator
  v = swap_endian( uint(buffer,0,12) ,/swap_if_little_endian)
  f0 = v[0]
  time = V[1] * 2d^16 + V[2]  + V[3]/(2d^16)

  ts = { f0: f0,  MET:time, revnum:buffer[8],  power_flag: buffer[9], fifo_cntr:buffer[10], fifo_flag: buffer[11], $
    sync: v[6], counts:v[7]  , parity_frame: v[8],  command:v[9],  telem_fifo:v[10],  inst_power_flag:v[11]  }
  return,ts
end







pro ksem_recorders
  exec,exec_text = ['tplot,verbose=0,trange=systime(1)+[-1,.05]*300','timebar,systime(1)']

  ;host = 'ABIAD-SW'
  ;host = 'localhost'
  ;host = '128.32.98.101'  ;  room 160 Silver
  ;host = '163.180.171.55'  ; 
  ;host = '128.32.13.37'   ;  room 133 addition
  recorder,title='KSEM @ SSL-160',port=4040,host='128.32.98.101' ,exec_proc='ksem_msg_stream_read',destination='ksem_YYYYMMDD_hhmmss_{HOST}.{PORT}.dat';,/set_proc,/set_connect,get_filename=filename
  ;recorder,title='KSEM @ KHU',port=4040,host='163.180.171.55' ,exec_proc='ksem_msg_stream_read',destination='ksem_YYYYMMDD_hhmmss_{HOST}.{PORT}.dat';,/set_proc,/set_connect,get_filename=filename
end



pro ksem_msg_stream_read,buffer, info=info  ;,time=time   ;,   fileunit=fileunit   ,ptr=ptr
common ksem_msg_stream_read_com2, time_status,utc,c,dd

  bsize= n_elements(buffer)
  time = info.time_received
;  dprint,time_string(time)
  
if n_elements( *info.exec_proc_ptr ) ne 0 then begin   ; Handle remainder of buffer from previous call
  remainder =  *info.exec_proc_ptr
  dprint,dlevel=2,'Using remainder buffer from previous call'
  dprint,dlevel=2,/phelp, remainder
  undefine , *info.exec_proc_ptr
  if bsize gt 0 then  ksem_msg_stream_read, [remainder,buffer],info=info
  return
endif
  
  
  if 0 && debug(3) then dprint,/phelp,time_string(time),buffer,dlevel=3
  ptr=0L
  while ptr lt bsize do begin
    if ptr gt bsize-6 then begin
      dprint,dlevel=0,'SWEMulator MSG stream size error ',ptr,bsize
      return
    endif
    msg_header = swap_endian( uint(buffer,ptr,3) ,/swap_if_little_endian)
    sync  = msg_header[0]
    code  = msg_header[1]
    psize = msg_header[2]*2
    if 0 then begin
      dprint,ptr,psize,bsize
      hexprint,msg_header
      ;    hexprint,buffer,nbytes=32
    endif

    if sync ne 'a829'x then begin
      ;     printdat,ptr,sync,code,psize
      ;      dprint,ptr,sync,code,psize,dlevel=0,    ' Sync not recognized'
      dprint,format='(i,z,z,i,a)',ptr,sync,code,psize,dlevel=0,    ' Sync not recognized'
      ;      hexprint,buffer
      return
    endif

    if psize lt 12 then begin
      dprint,format="('Bad MSG packet size',i,' in file: ',a,' at file position: ',i)",psize,'???',0
      break
    endif
    
    if ptr+6+psize gt bsize then begin   ; Buffer doesn't have complete pkt.
      dprint,dlevel=2,'Buffer has incomplete packet. Saving ',n_elements(buffer)-ptr,' bytes for next call.'
      *info.exec_proc_ptr = buffer[ptr:*]                   ; store remainder of buffer to be used on the next call to this procedure
      return
      break
    endif
    

    if 0 && debug(3) then begin
      dprint,format='(i,i,z,z,i)',ptr,bsize,sync,code,psize,dlevel=2
      hexprint,buffer[ptr+6:ptr+6+psize-1] ;,nbytes=32
    endif

    if keyword_set(utc) then  time = utc

    case code of
      'c1'x :begin
         time_status = ksem_swemulator_time_status(buffer[ptr+6:ptr+6+psize-1])
         if keyword_set(time_status) then  utc = ksem_spc_met_to_unixtime(time_status.MET)
;         if debug(2) then hexprint,buffer[ptr+6:ptr+6+psize-1]
          if debug(4) then begin
            dprint,time_string(time),' ',time_string(utc), '  ', time-utc
            dprint,phelp=2,time_status,dlevel=3
          endif
         end
      'c2'x : dprint,dlevel=2,"Can't deal with C2 messages now'
      'c3'x :begin
        ksem_msg_pkt_handler,buffer[ptr+6:ptr+6+psize-1],time=time
      end
      else:  dprint,dlevel=1,'Unknown code'
    endcase
    ptr += ( psize+6)
  endwhile
  if ptr ne bsize then dprint,'MSG buffer size error?'
  return
end






pro ksem_msg_file_read,files

  ;  common spp_msg_file_read, time_status
  t0 = systime(1)
  ksem_apid_data_init
  ksem_apid_data,/clear,rt_flag=1
  info={ time_received:t0, exec_proc_ptr:ptr_new(null) }

  for i=0,n_elements(files)-1 do begin
    file = files[i]
    file_open,'r',file,unit=lun,dlevel=4
    sizebuf = bytarr(6)
    fi = file_info(file)
    dprint,dlevel=1,'Reading file: '+file+' LUN:'+strtrim(lun,2)+'   Size: '+strtrim(fi.size,2)
    while ~eof(lun) do begin
      point_lun,-lun,fp
      readu,lun,sizebuf
      msg_header = swap_endian( uint(sizebuf,0,3) ,/swap_if_little_endian)
      sync  = msg_header[0]
      code  = msg_header[1]
      psize = msg_header[2]*2
      if sync ne 'a829'x then begin
        hexprint,msg_header
        dprint,sync,code,psize,fp   ,  ' Sync not recognized'
        point_lun,lun, fp+2
        continue
      endif

      if psize lt 12 then begin
        dprint,format="('Bad MSG packet size',i,' in file: ',a,' at file position: ',i)",psize,file,fp
        hexprint,msg_header
        ;        continue
      endif
      if psize gt 2L^13 then begin
        dprint,format="('Large MSG packet size',i,' in file: ',a,' at file position: ',i)",psize,file,fp
        hexprint,msg_header
      endif

      buffer = bytarr(psize)
      readu,lun,buffer

      ksem_msg_stream_read,[sizebuf,buffer] ,info=info    ; read only a single message and pass it on

      if 0 then begin
        w= where(buffer ne 0,nw)
        if code eq 'c1'x then begin
          time_status = ksem_swemulator_time_status(buffer)
          dprint,dlevel=3,time_status
          ;        hexprint,buffer
          ;        v = swap_endian( uint(buffer,0,12) ,/swap_if_little_endian)
          ;        dprint,v
          continue
        endif

        ;      hexprint,buffer
        ksem_msg_pkt_handler,[sizebuf,buffer]   ;,time=systime(1)   ;,size=ptp_size
        if nw lt 20000 then begin
          dprint,dlevel=1,code,psize,nw,fp
        endif
      endif
    endwhile
    free_lun,lun
  endfor
  dt = systime(1)-t0
  dprint,format='("Finished loading in ",f0.1," seconds")',dt
  ksem_apid_data,/finish,rt_flag=1
end


pro ksem_init,files

if keyword_set(files) then begin
  ksem_msg_file_read,files
endif else ksem_apid_data_init

ksem_recorders
ksem_tplot_init


end



