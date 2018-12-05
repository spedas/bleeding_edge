; $LastChangedBy: davin-mac $
; $LastChangedDate: 2018-12-04 12:31:25 -0800 (Tue, 04 Dec 2018) $
; $LastChangedRevision: 26231 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/spp_swp_functions.pro $




;function spp_swp_word_decom,buffer,n,signed=signed
;   return,   swap_endian(/swap_if_little_endian,  uint(buffer,n) )
;end


;function spp_swp_int4_decom,buffer,n
;   return,   swap_endian(/swap_if_little_endian,  long(buffer,n) )
;end


;function spp_swp_float_decom,buffer,n
;   return,   swap_endian(/swap_if_little_endian,  float(buffer,n) )
;end






pro spp_swp_ptp_file_read,files ; this should now replaced by spp_ptp_file_read

  t0 = systime(1)
  spp_apid_data,/clear,rt_flag=0
  
  for i=0,n_elements(files)-1 do begin
     file = files[i]
     file_open,'r',file,unit=lun,dlevel=4
     sizebuf = bytarr(2)
     fi = file_info(file)
     dprint,dlevel=1,'Reading file: '+file+' LUN:'+strtrim(lun,2)+'   Size: '+strtrim(fi.size,2)
     while ~eof(lun) do begin
        point_lun,-lun,fp
        readu,lun,sizebuf
        ;point_lun,lun,fp
        sz = sizebuf[0]*256 + sizebuf[1]
        if sz lt 17 then begin
           dprint,format="('Bad PTP packet size',i,' in file: ',a,' at file position: ',i)",sz,file,fp
           break
        endif
        buffer = bytarr(sz-2)
        readu,lun,buffer
        spp_swp_ptp_pkt_handler,[sizebuf,buffer] ;,time=systime(1)   ;,size=ptp_size
     endwhile
     free_lun,lun
  endfor
  dt = systime(1)-t0
  dprint,format='("Finished loading in ",f0.1," seconds")',dt
  spp_apid_data,/finish,rt_flag=1

end




; this should now be replaced by spp_ptp_stream_read
;pro spp_swp_ptp_stream_read,buffer,info=info  ;,time=time
;
;  bsize= n_elements(buffer) * (size(/n_dimen,buffer) ne 0)
;  time = info.time_received
;  
;  if n_elements( *info.exec_proc_ptr ) ne 0 then begin 
;     ;; Handle remainder of buffer from previous call               
;     remainder =  *info.exec_proc_ptr
;     dprint,dlevel=4,'Using remainder buffer from previous call'
;     dprint,dlevel=3,/phelp, remainder
;     undefine , *info.exec_proc_ptr
;     if bsize gt 0 then  spp_ptp_stream_read, [remainder,buffer],info=info
;     return
;  endif
;
;  
;  ;if debug() then dprint,/phelp,time_string(time),buffer,dlevel=3
;  p=0L
;  while p lt bsize do begin
;     if p gt bsize-3 then begin
;        dprint,dlevel=1,'Warning PTP stream size can not be read ',p,bsize
;        ptp_size = 17           ; (minimum value possible) Dummy value that will trigger end of buffer
;     endif else  ptp_size = swap_endian( uint(buffer,p) ,/swap_if_little_endian)
;     if ptp_size lt 17 then begin
;        dprint,dlevel=1,'PTP packet size is too small!'
;        dprint,dlevel=1,p,ptp_size,buffer,/phelp
;        break
;     endif
;     if p+ptp_size gt bsize then begin ; Buffer doesn't have complete pkt.                                            
;        dprint,dlevel=3,'Buffer has incomplete packet. Saving ',n_elements(buffer)-p,' bytes for next call.'
;       ;dprint,dlevel=1,p,ptp_size,buffer,/phelp
;        *info.exec_proc_ptr = buffer[p:*]                   
;      ;; Store remainder of buffer to be used on the next call to this procedure
;        return
;        break
;     endif
;     spp_swp_ptp_pkt_handler,buffer[p:p+ptp_size-1],time=time
;     p += ptp_size
;  endwhile
;  if p ne bsize then dprint,dlevel=1,'Buffer incomplete',p,ptp_size,bsize
;  return
;end
;





pro spp_swp_msg_pkt_handler,buffer,time=time
  source = 0b
  spare = 0b
  ptp_scid = 0u
  path =  0u
  ptp_size = 0u
  utime = time
  ptp_header ={ ptp_time:utime, $
                ptp_scid: 0u, $
                ptp_source:source, $
                ptp_spare:spare, $
                ptp_path:path, $
                ptp_size:ptp_size }
  spp_ccsds_pkt_handler,buffer,ptp_header = ptp_header
  return
end


pro spp_swp_msg_stream_read,buffer, info=info  

  bsize= n_elements(buffer)
  time = info.time_received

  ;;Handle remainder of buffer from previous call
  if n_elements( *info.exec_proc_ptr ) ne 0 then begin   
     remainder =  *info.exec_proc_ptr
     if debug(3) then begin
        dprint,dlevel=2,'Using remainder buffer from previous call'
        dprint,dlevel=2,/phelp, remainder
        hexprint,remainder[0:31]
     endif
     undefine , *info.exec_proc_ptr
     if bsize gt 0 then  spp_msg_stream_read, [remainder,buffer],info=info
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
        ;hexprint,buffer,nbytes=32
     endif
     
     if sync ne 'a829'x then begin
        dprint,format='(i,z,z,i,a)',ptr,sync,code,psize,dlevel=0,    ' Sync not recognized'
        ;;hexprint,buffer
        return
     endif

     if psize lt 12 then begin
        dprint,format="('Bad MSG packet size',i,' in file: ',a,' at file position: ',i)",psize,'???',0
        break
     endif


     if ptr+6+psize gt bsize then begin
        dprint,dlevel=3,'Buffer has incomplete packet. Saving ',n_elements(buffer)-ptr,' bytes for next call.'
        *info.exec_proc_ptr = buffer[ptr:*] 
        ;; Store remainder of buffer to be used on the next call to
        ;; this procedure
        return
        break
     endif
     
     if debug(3) then begin
        dprint,format='(i,i,z,z,i)',ptr,bsize,sync,code,psize,dlevel=3
        ;hexprint,buffer[ptr+6:ptr+6+psize-1] ;,nbytes=32
        hexprint,buffer[ptr:ptr+6+psize-1] ;,nbytes=32
     endif
     
     case code of
        'c1'x :begin
           time_status = spp_swemulator_time_status(buffer[ptr:ptr+6+psize-1])
           store_data,/append,'swemulator_',data=time_status,tagnames='*'
        end
        'c2'x : dprint,dlevel=2,"Can't deal with C2 messages now"
        'c3'x :begin
           spp_swp_msg_pkt_handler,buffer[ptr+6:ptr+6+psize-1],time=time
        end
        else:  dprint,dlevel=1,'Unknown code'
     endcase
     ptr += ( psize+6)
  endwhile
  if ptr ne bsize then dprint,'MSG buffer size error?'
  return
end














pro spp_swp_msg_file_read,files
  
;  common spp_msg_file_read, time_status
  t0 = systime(1)
  spp_apid_data,/clear,rt_flag=0
  
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
        ;continue
        endif
        if psize gt 2L^13 then begin
           dprint,format="('Large MSG packet size',i,' in file: ',a,' at file position: ',i)",psize,file,fp
           hexprint,msg_header
        endif
        
        buffer = bytarr(psize)
        readu,lun,buffer
        
        ; Read only a single message and pass it on             
        spp_msg_stream_read,[sizebuf,buffer] ,time=systime(1) 

        if 0 then begin
           w= where(buffer ne 0,nw)
           if code eq 'c1'x then begin
              time_status = spp_swemulator_time_status(buffer)
              dprint,dlevel=3,time_status
              ;hexprint,buffer
              ;v = swap_endian( uint(buffer,0,12) ,/swap_if_little_endian)
              ;dprint,v
              continue
           endif
      
      ;;hexprint,buffer
      ;;,time=systime(1)   ;,size=ptp_size
           spp_msg_pkt_handler,[sizebuf,buffer]   
           if nw lt 20000 then begin
              dprint,dlevel=1,code,psize,nw,fp
           endif
        endif
     endwhile
     free_lun,lun
  endfor
  dt = systime(1)-t0
  dprint,format='("Finished loading in ",f0.1," seconds")',dt
  spp_apid_data,/finish,rt_flag=1
end








;function spp_swp_log_decomp,bdata,ctype,compress=compress
;
;  if n_elements(ctype) eq 0 then ctype = 0
;
;  clog_19_8=[ $
;              0,       1,      2,      3,      4,      5,      6,      7,  $
;              8,       9,     10,     11,     12,     13,     14,     15,  $
;              16,     17,     18,     19,     20,     21,     22,     23,  $
;              24,     25,     26,     27,     28,     29,     30,     31,  $
;              32,     34,     36,     38,     40,     42,     44,     46,  $
;              48,     50,     52,     54,     56,     58,     60,     62,  $
;              64,     68,     72,     76,     80,     84,     88,     92,  $
;              96,    100,    104,    108,    112,    116,    120,    124,  $
;             128,    136,    144,    152,    160,    168,    176,    184,  $
;             192,    200,    208,    216,    224,    232,    240,    248,  $
;             256,    272,    288,    304,    320,    336,    352,    368,  $
;             384,    400,    416,    432,    448,    464,    480,    496,  $
;             512,    544,    576,    608,    640,    672,    704,    736,  $
;             768,    800,    832,    864,    896,    928,    960,    992,  $
;            1024,   1088,   1152,   1216,   1280,   1344,   1408,   1472,  $
;            1536,   1600,   1664,   1728,   1792,   1856,   1920,   1984,  $
;            2048,   2176,   2304,   2432,   2560,   2688,   2816,   2944,  $
;            3072,   3200,   3328,   3456,   3584,   3712,   3840,   3968,  $
;            4096,   4352,   4608,   4864,   5120,   5376,   5632,   5888,  $
;            6144,   6400,   6656,   6912,   7168,   7424,   7680,   7936,  $
;            8192,   8704,   9216,   9728,  10240,  10752,  11264,  11776,  $
;           12288,  12800,  13312,  13824,  14336,  14848,  15360,  15872,  $
;           16384,  17408,  18432,  19456,  20480,  21504,  22528,  23552,  $
;           24576,  25600,  26624,  27648,  28672,  29696,  30720,  31744,  $
;           32768,  34816,  36864,  38912,  40960,  43008,  45056,  47104,  $
;           49152,  51200,  53248,  55296,  57344,  59392,  61440,  63488,  $
;           65536,  69632,  73728,  77824,  81920,  86016,  90112,  94208,  $
;           98304, 102400, 106496, 110592, 114688, 118784, 122880, 126976,  $
;          131072, 139264, 147456, 155648, 163840, 172032, 180224, 188416,  $
;          196608, 204800, 212992, 221184, 229376, 237568, 245760, 253952,  $
;          262144, 278528, 294912, 311296, 327680, 344064, 360448, 376832,  $
;          393216, 409600, 425984, 442368, 458752, 475136, 491520, 507904]
;
;
;
;  clog_12_8=long([  $
;             0,    1,    2,    3,    4,    5,    6,    7,  $
;             8,    9,   10,   11,   12,   13,   14,   15,  $
;            16,   17,   18,   19,   20,   21,   22,   23,  $
;            24,   25,   26,   27,   28,   29,   30,   31,  $
;            32,   33,   34,   35,   36,   37,   38,   39,  $
;            40,   41,   42,   43,   44,   45,   46,   47,  $
;            48,   49,   50,   51,   52,   53,   54,   55,  $
;            56,   57,   58,   59,   60,   61,   62,   63,  $
;            64,   66,   68,   70,   72,   74,   76,   78,  $
;            80,   82,   84,   86,   88,   90,   92,   94,  $
;            96,   98,  100,  102,  104,  106,  108,  110,  $
;           112,  114,  116,  118,  120,  122,  124,  126,  $
;           128,  132,  136,  140,  144,  148,  152,  156,  $
;           160,  164,  168,  172,  176,  180,  184,  188,  $
;           192,  196,  200,  204,  208,  212,  216,  220,  $
;           224,  228,  232,  236,  240,  244,  248,  252,  $
;           256,  264,  272,  280,  288,  296,  304,  312,  $
;           320,  328,  336,  344,  352,  360,  368,  376,  $
;           384,  392,  400,  408,  416,  424,  432,  440,  $
;           448,  456,  464,  472,  480,  488,  496,  504,  $
;           512,  528,  544,  560,  576,  592,  608,  624,  $
;           640,  656,  672,  688,  704,  720,  736,  752,  $
;           768,  784,  800,  816,  832,  848,  864,  880,  $
;           896,  912,  928,  944,  960,  976,  992, 1008,  $
;          1024, 1056, 1088, 1120, 1152, 1184, 1216, 1248,  $
;          1280, 1312, 1344, 1376, 1408, 1440, 1472, 1504,  $
;          1536, 1568, 1600, 1632, 1664, 1696, 1728, 1760,  $
;          1792, 1824, 1856, 1888, 1920, 1952, 1984, 2016,  $
;          2048, 2112, 2176, 2240, 2304, 2368, 2432, 2496,  $
;          2560, 2624, 2688, 2752, 2816, 2880, 2944, 3008,  $
;          3072, 3136, 3200, 3264, 3328, 3392, 3456, 3520,  $
;          3584, 3648, 3712, 3776, 3840, 3904, 3968, 4032 ])
;
;  
;  ;clog = [[clog_19_8],[clog_12_8]]
;  ;printdat,clog
;  clog = ctype and 1 ? clog_12_8 : clog_19_8
;  if keyword_set(compress) then begin
;     comp = interp(indgen(256),clog*.99999,bdata,index=i)
;     return,fix(i)
;  endif
;
;  return, clog[byte(bdata)]
;
;end







;;-----------------------------------------------------------------------------
;; From SPP_CRIB

;pro spp_init_realtime,filename=filename,base=base
;
;  common spp_crib_com2, recorder_base,exec_base
;
;  exec,exec_base, exec_text = $
;       'tplot,verbose=0,trange=systime(1)+[-1,.05]*300'  
;  host = 'localhost'
;  host = '128.32.98.101'
;  host = 'ABIAD-SW'
;  recorder,recorder_base,title='GSEOS PTP',$
;           port=2028,$
;           host=host,$
;           exec_proc='spp_swp_ptp_stream_read',$
;           destination='spp_raw_YYYYMMDD_hhmmss.ptp'
;
;  printdat,recorder_base,filename,exec_base,/value
;  
;  ;spp_swp_apid_data_init,save=1
;  ;spp_apid_data,'3b9'x,name='SWEAP SPAN-I Events',rt_tags='*'
;  ;spp_apid_data,'3bb'x,name='SWEAP SPAN-I Rates',rt_tags='*CNTS'
;  ;spp_apid_data,'3be'x,name='SWEAP SPAN-I HKP',rt_tags='*'
;  ;spp_apid_data, rt_flag = 1
;  ;spp_swp_manip_init
;  ;wait,1
;  
;  spp_set_tplot_options
;  
;  ;;--------------------------------------------------
;  ;; Useful command to see what APIDs have been loaded
;  ;spp_apid_data,apdata=ap
;  ;print_struct,ap
;  ;;-------------------------------------------------
;  
;  if 0 then begin
;     f1= file_search('spp*.ptp')
;     spp_apid_data,rt_flag=0
;     spp_ptp_file_read,f1[-1]
;     spp_apid_data,rt_flag=1
;  endif
;  base = recorder_base
;
;end


;function spp_swp_spani_thermaltest1_files
;  src = spp_file_source()
;  pathnames = 'spp/sweap/prelaunch/gsedata/EM/spanai/201502??_*/PTP_data.dat'
;  printdat,src
;  files=file_retrieve(pathnames,_extra=src)
;  return,files
;end


pro poisson_plot,s,index=index

  if not keyword_set(s) then s = tsample()
  nd = size(/dimen,s)
  ;avg = average(s,1)
  ;tot = total(s,1)
  ;par = poisson()
  if n_elements(index) eq 0  then index = 2
  i=index
  s_i = s[*,i]
  cs_i = spp_sweap_log_decomp( s_i,/comp)
  h = histbins(cs_i,xb,binsize=1)
  par.avg = average(s_i)
  par.h   = nd[0]
  printdat,par
  xv=dindgen(10000)
  ;pc =  poisson(xv,param=par)
  printdat,pc
  cxv = spp_sweap_log_decomp( xv,/comp)
  cpc = average_hist(pc,cxv,xbins=ccxv,binsize=1,/ret_total)
  plot,xb,h, psym=4,xrange=minmax([ccxv,cxv,xb]),yrange=minmax([pc,h,cpc])
  oplot,xb,h,psym=10
  ;oplot,xv,pc,color=6,psym=10
  oplot,ccxv,cpc,color=6,psym=10

end


;pro print_rates,t
;
;  if ~keyword_set(t) then ctime,t,npoint=2,/silent
;  
;  valids=tsample('spp_spanai_rates_VALID_CNTS',t,/average)
;  multis=tsample('spp_spanai_rates_MULTI_CNTS',t,/average)
;  ostarts=tsample('spp_spanai_rates_START_CNTS',t,/average)
;  ostops =tsample('spp_spanai_rates_STOP_CNTS',t,/average)
;  
;  print,findgen(16)
;  print
;  print,valids
;  print,multis
;  print,ostarts
;  print,ostops
;  
;  starts = ostarts+valids
;  stops = ostops+valids
;  print
;  print,valids/starts
;  print,valids/stops
;
;end



pro spp_tof_histogram,trange=trange,xrange=xrange,ylog=ylog,binsize=binsize,noerase=noerase,channels=channels,xlog=xlog

  if ~keyword_set(trange) then ctime,trange,npoints=2
  csize = 2
  spp_apid_data,'3B9'x,apdata=ap
  ;print_struct,ap
  events = *ap.dataptr
  if not keyword_set(tragne) then ctime,trange
  
  if keyword_set(trange) then begin
     w = where(events.time ge trange[0] and events.time le trange[1],nw)
     if nw ne 0 then events = events[w] else dprint,'No points selected - using all'
  endif

  col = bytescale(indgen(16))
  nc = n_elements(col)
  ;if ~keyword_set(xrange) then xrange=[450,600]
  if ~keyword_set(binsize) then binsize = 1
  h = histbins(events.tof,xb,binsize=binsize,shift=0,/extend_range)
  
  if keyword_set(ylog) then begin
     mx = max(h)
     yrange = [mx/10^(ylog+3),mx]
     yrange  = [.5,mx*2]
  endif
  
  if keyword_set(xlog) then begin
     xrange = minmax(/pos,xb) > 10
  endif

  
  plot,/nodata,xb,h * 1.1,xrange=xrange,$
       charsize=csize,$
       yrange=yrange,$
       ylog=ylog,$
       ystyle=3,$
       noerase=noerase,$
       xtitle='Time of Flight channel',$
       ytitle='Counts',xlog=xlog
  mxt = max(h)
  if ~keyword_set(channels) then channels = reverse(indgen(16))
  for i=0,n_elements(channels)-1 do begin
     ch = channels[i]
     c=col[ch mod nc]
     w = where(events.channel eq ch, nw)
     if nw eq 0 then continue
     h = histbins(events[w].tof,xb,binsize=binsize,shift=0)
     oplot,xb,h,color=c,psym=10
     oplot,xb,h,color=c,psym=1
     mx = max(h,b)
     xyouts,xb[b],h[b]+mxt*.03,strtrim(ch,2),color=c,align=.5,charsize=2
     if keyword_set(dt)  then begin
        ;dt = findgen(44)+7
        ;pks = find_peaks(
        ;[replicate(0,round(xb[0])),h],roiw=5)
        plot,dt,pks.x0,/psym,yrange=[-100,500],xrange=[0,55],/ystyle,/xstyle,xtitle='Delay (ns)',ytitle='TOF value',title='Fit to response'
        par = polycurve()
        fit,dt[1:*],pks[1:*].x0,param=par,names='a0 a1'
        oplot,dt,(pks.x0-func(dt,param=pc)) * 10,psym=4,color=6
        oplot,xv,func(xv,param=pc)
        xv=dgen()
        oplot,xv,func(xv,param=pc)
        oplot,[0,60],[0,0],color=5,linestyle=2
        oplot,[0,60],[0,0],color=2,linestyle=2
     endif
  endfor
  

end


pro spp_message_to_value

  spp_apid_data,'7C0'x,apdata=ap
  print_struct,ap
  dat = *ap.dataptr
  w = where( strmid(dat.msg,0,4) eq 'set ')

end



;pro spp_swp_reduce,tof_range=tof_range,tof_name=tof_name
;
;  res =5.
;  
;  if 0 then begin
;     reduce_timeres_data,'spp_spanai_rates_*CNTS',res ;,trange=tr
;     get_data,'spp_spanai_rates_VALID_CNTS_t',data=d1
;     get_data,'spp_spanai_rates_START_CNTS_t',data=d3
;     get_data,'spp_spanai_rates_STOP_CNTS_t',data=d4
;     dr =d1
;     dr.y = d1.y/(d1.y+d3.y)
;     store_data,'valid_start',data=dr
;     dr.y = d1.y/(d1.y+d4.y)
;     store_data,'valid_stop',data=dr
;     dr.y = (d1.y+d3.y)/(d1.y+d4.y)
;     store_data,'start_stop',data=dr
;     dr.y = (d1.y+d4.y)/(d1.y+d3.y)
;     store_data,'stop_start',data=dr
;  endif
;
;  if 1 then begin
;     spp_apid_data,'3b9'x,apdata=ap
;     a = *ap.dataptr
;     for ch = 0 ,15 do begin
;        test = a.channel eq ch
;        if n_elements(tof_range) eq 2 then test = test and (a.tof le tof_range[1] and a.tof ge tof_range[0])
;        w = where(test,nw)
;        colors = bytescale(findgen(16))
;        ;dl = {psym:3, colors=0}
;        name =string(ch,format='("spanai_ch",i02,"_")')
;        if keyword_set(tof_name) then name += tof_name+'_'
;        if nw ne 0 then store_data,name,data=a[w],tagnames='*',dlim={TOF:{psym:3,symsize:.4,colors:colors[ch] }}
;        h=histbins(a[w].time,tb,binsize=double(res))
;        store_data,name+'TOT',tb,h,dlim={colors:colors[ch]}
;     endfor
;     store_data,'spanai_all_TOT',data='spanai_ch??_TOT'
;     
;  endif
;  
;end
;







pro spp_set_tplot_options,spec=spec
  
  clog = keyword_set(spec)
  crange = [.9,5000.]
  if keyword_set(spec) then begin
     ylim,'*rate*CNTS',-1,16,0
     options,'*rates*CNTS',spec=1,ystyle=3,symsize=.5,zrange=crange
     ;options,'*rates*CNTS_t',labels='CH'+strtrim(indgen(16),2),labflag=-1,yrange=[.01,100],/ylog,ystyle=3,psym=-1,symsize=.5
  endif else begin
     ;ylim,'*rate*CNTS',1,1,1
     options,'*rates*CNTS',spec=0,yrange=crange,ylog=1,ystyle=3,psym=-1,symsize=.5
     ;options,'*rates*CNTS_t',labels='CH'+strtrim(indgen(16),2),labflag=-1,yrange=[.01,100],/ylog,ystyle=3,psym=-1,symsize=.5
  endelse
  options,'*events*',psym=3,ystyle=3
  store_data,'log_MSG',dlimit=struct(tplot_routine='strplot')
  options,'*MON*',/ynozero
  tplot_options,'local_time',1
  tplot_options,'xtitle','Pacific Time'
  store_data,'STOP_SPEC',data='spp_spanai_rates_STOP_CNTS',dlimit=struct(spec=1,yrange=[-1,16],zrange=[.5,500],/zlog,ylog=0,/no_interp)
  store_data,'START_SPEC',data='spp_spanai_rates_START_CNTS',dlimit=struct(spec=1,yrange=[-1,16],zrange=[.5,500],/zlog,ylog=0,/no_interp)
  ;tplot,' *CMD_REC *rate*CNTS *ACC
  ;*MCP *events*
  ;log_MSG'
  if 0 then begin
     options,'spp_spane_spec_CNTS',spec=0,yrange=[1,1000],ylog=1,colors='mbcgdr'
  endif else begin
     options,'spp_spane_spec_CNTS',spec=1,yrange=[0,17],ylog=0,zrange=[1,500.],zlog=1
  endelse

end


;; end SPP_CRIB
;;-----------------------------------------------------------------------------





;;-----------------------------------------------------------------------------
;; Functions within pkt_handler

;coeff = [0.00E+00,  0.00E+00,  -5.76E-20, 5.01E-15,  -1.68E-10, 2.69E-06,  -2.33E-02, 9.33E+01]
;function spp_spc_met_to_unixtime,met
;
;  ;; long(time_double('2000-1-1/12:00'))  ;Early SWEM definition
;  epoch =  946771200d - 12L*3600   
;  ;; long(time_double('2010-1-1/0:00'))  ; Correct SWEM use
;  epoch =  1262304000              
;  unixtime =  met +  epoch
;  return,unixtime
;
;end



;function thermistor_temp,R,parameter=p,b2252=b2252,L1000=L1000
;
;  if not keyword_set(p) then begin
;     p = {func:'thermistor_temp',note:'YSI 46006 (H10000)',R0:10000.,  $
;          T0:24.988792d, t1:-24.809236d, t2:1.6864476d, t3:-0.12038317d, $
;          t4:0.0081576555d, t5:-0.00057545026d ,t6:3.1337558d-005}
;     if keyword_set(B2252) then p={func:'thermistor_temp',note:'YSI (B2252)',R0:2252.,  $
;                                   T0:24.990713d, t1:-22.808501d, t2:1.5334736d, t3:-0.10485403d, $
;                                   t4:0.0076653446d, t5:-0.00084656440d ,t6:6.1095571d-005}
;     if keyword_set(L1000) then p={func:'thermistor_temp',note:'YSI (L1000)',R0:1000.,  $
;                                   T0:25.00077d, t1:-27.123102d, t2:2.2371834d, t3:-0.20295066d, $
;                                   t4:0.022239779d, t5:-0.0024144851d ,t6:0.00013611146d}
;     ;if keyword_set(YSI4908) then p = $
;     ;   {func:'thermistor_temperature_ysi4908',note:'YSI4908'}
;  endif
;
;  if n_params() eq 0 then return,p
;  x = alog(R/p.r0)
;  T = p.t0 + p.t1*x + p.t2*x^2 + p.t3*x^3 + p.t4*x^4 +p.t5*x^5 +p.t6*x^6
;  return,t
;
;end



;function spp_sweap_therm_temp,dval,parameter=p
;  if not keyword_set (p) then begin
;     ;p = {func:'mvn_sep_therm_temp2',$
;     ;     R1:10000d, $
;     ;     xmax:1023d, $
;     ;     Rv:1d8,$
;     ;     thm:thermistor_temp()}                                                              
;     p = {func:'spp_sweap_therm_temp',$
;          R1:10000d, $
;          xmax:1023d, $
;          Rv:1d7, $
;          thm:'thermistor_resistance_ysi4908'}
;  endif
;  if n_params() eq 0 then return,p
;  ;print,dval
;  x = dval/p.xmax
;  rt = p.r1*(x/(1-x*(1+p.R1/p.Rv)))
;  tc = thermistor_resistance_ysi4908(rt,/inverse)                                
;  ;print,dval,x,rt,tc
;  return,float(tc)
;end



pro spp_swp_functions

  print, 'Compiling all SPP-SWEAP functions.'

end
