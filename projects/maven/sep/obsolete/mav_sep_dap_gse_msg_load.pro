obsolete file



;
function mav_inst_message,pkt,allow_pad=allow_pad
  hdr = pkt.buffer[0]
  id = ishft(hdr,-10)
  length = (hdr and '03ff'x) + 1
  valid  = pkt.length  eq length+1
  if keyword_set(allow_pad) then valid=pkt.valid
  if valid eq 0 then data=0   else   data = pkt.buffer[1:length]
  imsg = {time:pkt.time,valid:valid, id:id, length:length, hdr:hdr, data:data}
  return,imsg
end




pro mav_misg_message_proc,msg,ptrs,tname=tname,defsize=defsize

if not keyword_set(ptrs) then begin
   if not keyword_set(defsize) then defsize = msg.length
   ptrs = {x:ptr_new(0),  y:ptr_new(0),  xi:ptr_new(0),  yi:ptr_new(0), v:ptr_new(0), defsize:defsize }
endif

if keyword_set(msg) then begin
   if msg.valid eq 0 then begin
      dprint,'Invalid message'
   endif else begin
     append_array,*ptrs.x, msg.time, index = *(ptrs.xi)
     append_array,*ptrs.y, msg.data, index = *(ptrs.yi)
   endelse
endif else begin
   append_array, *ptrs.x, index= *ptrs.xi,/done
   append_array, *ptrs.y, index= *ptrs.yi,/done
   *ptrs.y = reform(*ptrs.y,*ptrs.yi/ *ptrs.xi, *ptrs.xi)
   *ptrs.y = transpose(*ptrs.y)
   *ptrs.v = findgen( *ptrs.yi/ *ptrs.xi )
   if size(/type,tname) eq 7 then    store_data,tname,data=ptrs,dlim = {spec:1}
endelse
end






pro mav_gse_structure_append,ptrs,str,tname=tname,tags=tags

  if keyword_set(str) then begin
     if not keyword_set(ptrs) then ptrs = {x:ptr_new(0),  xi:ptr_new(0)  }
     append_array,*ptrs.x, str, index= *ptrs.xi
  endif else begin
     if keyword_set(ptrs) then  append_array, *ptrs.x, index= *ptrs.xi,/done
     if size(/type,tname) eq 7 then begin
        if not keyword_set(ptrs) then begin
           dprint,'No data for ',tname
           return
        endif
        str_all = *ptrs.x
        if not keyword_set(tags) then tags = tag_names( str_all )
        time = str_all.time
        for i = 0,n_elements(tags)-1 do begin
            if tags[i] eq 'TIME' then continue
            dlim = 0
            vvalue=0
            str_element,str_all,tags[i],yvalue
            dim= size(yvalue,/dimensions)
            if n_elements(dim) eq 2 then begin
                yvalue=transpose(yvalue)
                vvalue=findgen(dim[0])
     ;           dlim = {spec:1}
            endif
            if strpos(tags[i],'FLAG') ge 0 then dlim =struct(dlim,tplot_routine='bitplot',colors='bmgr')
            store_data,tname+'_'+tags[i], time, yvalue,vvalue ,dlim=dlim
        endfor
        ptr_free,ptr_extract(ptrs)
     endif
  endelse
end



function mav_misg_status_decom,pkt,rec_time = rec_time
   if not keyword_set(rec_time) then rec_time = systime(1)
   buffer_uint = pkt.buffer
   sampletime = buffer_uint[0]
   utc_time = buffer_uint[1] * 2ul^16 + buffer_uint[2] + buffer_uint[3]/2d^16
   if utc_time lt 323308800L then utc_time -= 7L*3600  ; long(time_double('2011-4-1') - time_double('2001-1-1') )
   time = utc_time + 978307200   ;  ulong( time_double('2001-1-1') )
 ;  time = utc_time +  946684800  ; 2000-1-1  
;   if time gt rec_time + 100 or time lt rec_time - 1e5 then time = rec_time
   status = {time       :   time,               $
             sample_time:   sampletime        ,$
             time_delay :   rec_time - time   ,$
             utc_time   :   utc_time         ,  $
             fpga_rev   :   byte(ishft( buffer_uint[4],-8) ) ,  $
             mode_flags :   byte( buffer_uint[4] and 'FF'x )   ,  $
             fifo_cntr  :   byte(ishft(buffer_uint[5],-8))   ,   $
             fifo_flags :   byte(buffer_uint[5] and 'FF'x)    , $
             act_flags  :   buffer_uint[6],  $
             act_time   :   buffer_uint[7],  $
             xtr1_flags :   buffer_uint[8],  $
             xtr2_flags :   buffer_uint[9]  }
   return,status
end



function mav_sep_hkp_decom,msg,last_hkp=last_hkp
   if msg.valid eq 0 then return, fill_nan(last_hkp)
   time = msg.time
   dtime =  0d   ; msg.time - last_hkp.time
   data = [msg.hdr,msg.data]
   amonitor = fix(data[1:8])
   mapid    = byte( ishft( data[9],-8 ) )
   fpga_rev = byte( data[9] and 'ff'x  )
   vcmd_cntr = byte(  ishft( data[10],-8) )
   vcmd_rate= 0b
   icmd_cntr =  byte( data[10] and 'ff'x  )
   icmd_rate = 0b
   mode_flags    =  data[11]
   noise_flags    =  data[12]
   noise_res     = byte(  ishft(data[12],-8) and '111'b )
   noise_per    =   byte(data[12] and 'ff'x)
   mem_addr     =  data[13]
   mem_checksum =  byte(  ishft( data[14] ,-8) )
   pps_cntr     =  byte(  data[14] and 'ff'x )
   event_cntr   =  data[15]
   rate_cntr    =  data[16:21]
   cntr1 = byte( ishft( data[22],-12 ) and 'f'x )
   cntr2 = byte( ishft( data[22],-8 ) and 'f'x )
   cntr3 = byte( ishft( data[22],-4 ) and 'f'x )
   cntr4 = byte( ishft( data[22],0 ) and 'f'x )
   timeout_cntrs = [cntr1,cntr2,cntr3,cntr4]
   det_timeout   = byte(ishft(data[23],-8) )
   nopeak_cntr   = byte( data[23] and 'ff'x )
   nopeak_rate   = 0b
   reserved      = data[24]


   sephkp = {time :      time,      $
             dtime :    dtime,  $
             amonitor:  amonitor,   $
             mapid:     mapid,  $
             fpga_rev:   fpga_rev,  $
             vcmd_cntr :   vcmd_cntr  ,   $
             vcmd_rate :   vcmd_rate , $
             icmd_cntr :   icmd_cntr, $
             icmd_rate :   icmd_rate,  $
             mode_flags   :   mode_flags   ,  $
             noise_flags   :   noise_flags   ,  $
             noise_res   :   noise_res   ,  $
             noise_per   :   noise_per   ,  $
             mem_addr   :   mem_addr   ,  $
             mem_checksum:  mem_checksum,  $
             pps_cntr:  pps_cntr,  $
             event_cntr:  event_cntr,  $
             rate_cntr:  rate_cntr,  $
             timeout_cntrs:  timeout_cntrs,  $
             det_timeout:  det_timeout,  $
             nopeak_cntr:  nopeak_cntr,  $
             nopeak_rate:  nopeak_rate,  $
             reserved_flags:  reserved    }

    if keyword_set(last_hkp) then begin
        sephkp.dtime  = sephkp.time - last_hkp.time
        sephkp.nopeak_rate = sephkp.nopeak_cntr - last_hkp.nopeak_cntr
        sephkp.vcmd_rate = sephkp.vcmd_cntr - last_hkp.vcmd_cntr
        sephkp.icmd_rate = sephkp.icmd_cntr - last_hkp.icmd_cntr
    endif

   return,sephkp
end




function mav_sep_noise_decom,msg,hkppkt=hkp,last_noise=last
    if msg.valid eq 0 then return, 0
    lastdata =keyword_set(last) ? last.data : 0u
    ddata = msg.data - lastdata
    noise_res = keyword_set(hkp) ? hkp.noise_res   : 0b
    noise_per = keyword_set(hkp) ? hkp.noise_per   : 0b
    noise_flags=keyword_set(hkp) ? hkp.noise_flags : 0u

    p= replicate(find_peak(),6)
    x = (dindgen(10)-4.5) * ( 2d ^ (noise_res-3))
    d = reform(ddata,10,6)
    for j=0,5 do begin
        p[j] = find_peak(d[*,j],x)
    endfor
    sepnoise = {time    :    msg.time,      $
             flags      :   noise_flags   ,  $
             res        :   noise_res                 ,  $
             per        :   noise_per   ,  $
             tot        :   p.a  ,$
             baseline   :   p.x0 ,$
             sigma      :   p.s  ,$
             ddata      :   ddata,  $
             eff        :   p.a * (noise_per #  replicate(1,6)),   $
             data       :   msg.data    }
   return,sepnoise
end






function mav_sep_science_decom,msg,hkppkt=hkp   , last=last

    if msg.valid eq 0 then return,0  ; fill_nan(last)

    tot = total(/preserve,msg.data)
    mapid = keyword_set(hkp) ? hkp.mapid : 0b
    event_cntr  = keyword_set(hkp) ? hkp.event_cntr : 0u
    diff_cntr  = keyword_set(last)  ? fix(tot) - fix(last.event_cntr) : 0

    pp = find_peaks(msg.data,threshold = 4,roiw=14)
    p = pp[0]

    strct = {time      :    msg.time,      $
            mapid      :    mapid   ,  $
            data       :    msg.data ,  $
            event_cntr :    event_cntr ,   $
            diff_cntr  :    diff_cntr  ,   $
            total      :    tot, $
            A      :    p.a   ,  $
            x0     :    p.x0  , $
            s      :    p.s   ,  $
            valid      :    msg.valid   }

    return,strct
end





function mav_sep_memdump_decom,msg  ,hkppkt=hkp    , last=last
    if msg.valid eq 0 then return,0
    if keyword_set(hkp) then addr= hkp.mem_addr else addr = 0u
    if keyword_set(last) then LUT = last.lut  else lut = bytarr(2L^17)
    if keyword_set(last) then mlut= last.mlut else mlut= bytarr(2L^12)
;    data = msg.data
    data = byte(msg.data,0,2*n_elements(msg.data))
    lut[addr:addr+2048-1] =  data
    maddr = addr and 'fff'x
    mlut[maddr:maddr+2048-1] = data   ; single FTOTelescope

    strct = {time      :    msg.time,      $
            addr       :    addr  ,   $
            lut        :    lut ,  $
            mlut       :    mlut,  $
            valid      :    msg.valid   }

    return,strct
end





function mav_misg_packet_read_file,fp,time=time
        fst = fstat(fp)
        cur_ptr = fst.cur_ptr
        smallest_size = 10
        if fst.cur_ptr gt fst.size-smallest_size then return,0  ; don't read if the smallest possible packet isn't available
        swrd = 0u
        readu,fp,swrd
        byteorder,swrd,  /swap_if_little_endian
        ctype = 0u
        n = 0u
        if swrd eq 'A829'x then begin
            readu,fp,ctype,n
            byteorder,ctype,n,  /swap_if_little_endian
            if n ne 0 then begin
                if fst.cur_ptr gt fst.size-n*2 then begin
                    dprint,'Incomplete packet ignored. found ',fst.size-fst.cur_ptr,' of ',n*2,' bytes'
                    point_lun,fp,cur_ptr  ;            skip_lun,fp,-3*2  ;go back 3 words
                    return,0
                endif
                data = uintarr(n)
                readu,fp,data
                byteorder,data, /swap_if_little_endian
            endif else data = 0
        endif else data=0
    pkt = { time:time, sync: swrd,  ctype:ctype,  length:n, buffer:data }
    return,pkt
end





function mav_misg_packet_read_buffer,buffer,time=time
    bsize = n_elements(buffer)
    cur_ptr = 0
    smallest_size = 5  ; size of smallest possible message
    ptr = 0
    pkt = 0   ; return value
    while ptr lt bsize - smallest_size do begin
        swrd = buffer[ptr++]
        if swrd eq 'A829'x then begin
            ctype = buffer[ptr++]
            n     = buffer[ptr++]
            if n ne 0 then begin
                if ptr gt bsize - n then begin
                    dprint,'Incomplete packet ignored. found ',bsize-cur_ptr,' of ',n,' words'
                    return,0
                endif
                data = buffer[ptr: ptr+n-1]    ;data = uintarr(n)
                ptr += n                             ;readu,fp,data
                pkt = {time:time, sync: swrd,  ctype:ctype,  length:n, buffer:data }
                break
            endif else begin
                data = 0
                dprint,'Major error 1'
                stop
            endelse
        endif else begin
            data=0
            dprint,'Sync error ',ptr,swrd,dlevel=4
        endelse
    endwhile
    if ptr eq bsize then buffer =0 else buffer= buffer[ptr-1:*]
    return,pkt
end




pro set_tplot_options

options,'SEP_SCIENCE_DATA',spec=1,PANEL_SIZE=3,ZRANGE=[.8,500],ZLOG=1,yrange=[0,260.],ystyle=3
options,'SEP_NOISE_DDATA',spec=1,PANEL_SIZE=1.5,ZRANGE=[.8,100],ZLOG=1,yrange=[0,60.],ystyle=2
;ylim,'MAVEN_SEP_SCIENCE',-1,180
STORE_data,'SEP_RATES',data='SEP_HKP_NOPEAK_RATE SEP_HKP_EVENT_CNTR SEP_HKP_RATE_CNTR',dlim={panel_size:2}
options,'SEP_HKP_NOPEAK_RATE',psym=-3 ;,colors='b'
options,'SEP_HKP_?CMD_RATE',psym=-1,yrange=[0,10],ystyle=3
ylim,'SEP_RATES',.8,1e5,1
tplot_options,'no_interp',1
options,'SEP_NOISE_BASELINE',constant=0.
ylim,'SEP_NOISE_BASELINE',-5,5
ylim,'SEP_NOISE_SIGMA',0,6
tplot,'SEP_HKP_VCMD_RATE SEP_NOISE_BASELINE SEP_NOISE_SIGMA SEP_NOISE_DDATA SEP_SCIENCE_DATA SEP_RATES'

end


pro print_buffer,buffer,time=time
    if keyword_set(time) then print,time_string(time,/local), ' ',n_elements(buffer),' words'
    hexprint,buffer
end



pro mav_misg_process_buffer,buffer,time=time
    common lbuffer_com2,lbuffer,npktcollected

    if n_elements(npktcollected) eq 0 then npktcollected =0u

    dim = size(/dimension,lbuffer)
    if keyword_set(dim) then lbuffer = [lbuffer,buffer] else lbuffer = buffer
    brk=0

    while keyword_set(size(/dimension,lbuffer)) do begin
        pkt =mav_misg_packet_read_buffer(lbuffer,time=time)
        if keyword_set(pkt)  then begin
            tstr = time_string(pkt.time)
 ;           dprint,dlevel=3,tstr,pkt.sync,pkt.ctype,pkt.length,pkt.buffer,format = '(a,128Z6)'
            mav_misg_process_packet,pkt
        endif else begin
            dprint,'No pkt'
            break
        endelse
        time = struct_value(pkt,'time',default=0d)
        dprint,dlevel=1,dwait=10,'Collecting Data ',time_string(time),break_requested=brk
        if keyword_set(brk) then stop
    endwhile
end




pro mav_misg_process_packet,pkt
    common MISG_PROCESS_COM,  $
    status, status_ptrs,  $
    sephkp, sephkp_ptrs,  $
    sepscience, sepscience_ptrs, $
    sepnoise,   sepnoise_ptrs

    c=0
    tstr = time_string(pkt.time)
    case pkt.ctype of
    0:  begin
;        c = c0++
        tstr = '0 SYNC ERR '+time_string(systime(1),tformat='hh:mm:ss.fff')
        dprint,unit=u, dlevel=3, c,tstr,pkt.sync, format='(i6," ",a-24," | ",2Z6,260Z5)'
    end
    'C1'x:  begin
;            c= c1++
        status = mav_misg_status_decom(pkt)
        dprint,status.time_delay,dlevel=4
;            mav_gse_structure_append  ,status_ptrs, status
        time = status.time
        tstr = time_string(status.time,prec=3)
        dprint,unit=u, dlevel=3, c,tstr,pkt.sync,pkt.ctype,pkt.length,pkt.buffer, format='(i6," ",a-24," | ",2Z6,260Z5)'
    end
    'C2'x:  begin
;            c = c2++
        dprint,unit=u, dlevel=3, c,tstr,pkt.sync,pkt.ctype,pkt.length,pkt.buffer, format='(i6," ",a-24," | ",2Z6,260Z5)'
    end
    'C3'x:  begin
;            c = c3++
        dl = 3
        msg = mav_inst_message(pkt)
        if (msg.valid eq 0) then tstr='Invalid Message' else tstr = ''
        if keyword_set(tstr) then dl =1
        dprint,unit=u, dlevel=dl, c,tstr,pkt.sync,pkt.ctype,pkt.length,pkt.buffer, format='(i6," ",a-24," | ",2Z6,260Z5)'
        id0 = 0
        id0 = msg.id and '111011'b   ; make all packets look like SEP1
        case id0 of
            '08'x:  dprint,unit=u,dlevel=1,msg.length,'Event'
            '09'x:  dprint,unit=u,dlevel=1,msg.length,'Unused'
            '18'x: begin    ; Science
                sepscience = mav_sep_science_decom(msg,hkp=sephkp ,last=sepscience)  ;,last=lastscience)
;                mav_gse_structure_append,  sepscience_ptrs, sepscience
                end
            '19'x: begin     ; HKP
                sephkp = mav_sep_hkp_decom(msg,last=sephkp)
;                mav_gse_structure_append  ,sephkp_ptrs, sephkp
                end
            '1a'x: begin ; Noise
                sepnoise = mav_sep_noise_decom(msg,hkp=sephkp,last=sepnoise)
;                printdat,sepnoise
;                mav_gse_structure_append, sepnoise_ptrs, sepnoise
                end
            '1b'x:  dprint,unit=u,dlevel=1,msg.length,' MemDump'
            else:   begin
                dprint,unit=u, dlevel=1,msg.length,' Unknown Packet'
                dprint,dlevel=0,msg.length, ' Unknown Packet'
            endelse

        endcase
        end
    endcase

end










pro mav_sep_dap_misg_all_msg_load,realtime=realtime

if n_elements(realtime) ne 1 then realtime=0
if keyword_set(realtime) then pathnames = 'localhost'


if not keyword_set(realtime) then realtime=0

if realtime le 0 then begin
    source = mav_file_source()
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110302_113728_sample/misg_inst_msg.dat'
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110316_172036_NoiseTest/misg_all_msg.dat'
;   pathname = 'maven/sep/prelaunch_tests/EM1/20110316_171559_NoiseTest/misg_all_msg.dat'
    pathnames = 0
;   append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110321_160650_general/misg_all_msg.dat'
;   append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110321_160944_general/misg_all_msg.dat'
;   append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110321_164500_general/misg_all_msg.dat'
;   append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110321_164816_general/misg_all_msg.dat'
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110325_160624_general2/misg_all_msg.dat'
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110325_161732_general2/misg_all_msg.dat'
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110325_183831_general2/misg_all_msg.dat'
    pathnames = 0
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110328_144528_general3/misg_all_msg.dat'
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110329_095904_general/misg_all_msg.dat'
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110329_125357_general/misg_all_msg.dat'
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110329_145741_general/misg_all_msg.dat'
    pathnames = 0
;   append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110330_125018_general/misg_all_msg.dat'
;   append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110330_125043_general/misg_all_msg.dat'
;   append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110330_150521_general/misg_all_msg.dat'
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110330_151720_general/misg_all_msg.dat'
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110330_153017_general/misg_all_msg.dat'
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110330_161134_general/misg_all_msg.dat'
    pathnames = 0
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110405_081840_longterm/misg_all_msg.dat'
    pathnames = 0
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110427_093200_bad_sync_misg/misg_all_msg.dat'
    pathnames = 0
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM2/20110429_183534_longterm/misg_all_msg.dat'
    pathnames = 0
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM2/20110430_210746_/misg_all_msg.dat'
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM2/20110502_112714_highrate/misg_all_msg.dat'
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM2/20110502_113343_highrate2/misg_all_msg.dat'
    pathnames = 0
    append_array,pathnames, 'maven/sep/prelaunch_tests/realtime/STREAM_20110504_160610.dat'
    pathnames =0
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM2/20110507_082921_/misg_all_msg.dat
    pathnames = 0
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM2/20110506_215457_sweeptest/misg_all_msg.dat'
    pathnames = 0
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM2/20110506_215457_sweeptest/misg_all_msg.dat'
    pathnames = 0
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM2/20110504_072654_test/misg_all_msg.dat'
    pathnames = 0
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM2/20110712_163708_tpsweep/misg_all_msg.dat'
    pathnames = 0
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM2/20110811_100509_test/misg_all_msg.dat'
    pathnames = 0
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM2/20110824_213915_test/misg_all_msg.dat'
    files = file_retrieve(pathnames,_extra= source)
    files = file_retrieve('maven/sep/prelaunch_tests/EM2/2011*/misg_all_msg.dat',/last_version,_extra=source)
endif

if keyword_set(realtime) then  begin
    dir = ''
    rtfiles = file_search( dir+'STREAM_*.dat' )
    nf = n_elements(rtfiles)
    rtfiles = rtfiles[sort(rtfiles)]
    rtfiles = rtfiles[nf-abs(realtime):*]
    append_array,files,rtfiles
endif

file_open,'w','misg_all_msg_out.txt',unit=u,dlevel=2

c0=0
c1=0
c2=0
c3=0
time=0d


for fn = 0,n_elements(files)-1 do begin
    bad_message_cntr=0

    file = files[fn]
    dprint,dlevel=2,'Processing: ',file
    dprint,unit=u,dlevel=2,'File: ',file
    fi= file_info(file)
    if fi.exists then   file_open,'r',file,unit=fp,dlevel=3 else continue
    brk = 0

  while  not eof(fp) and not brk do begin
     pkt = mav_misg_packet_read_file(fp,time=time)
     if keyword_set(pkt) eq 0 then break
     tstr = ''
     dprint,dlevel=1,dwait=5,'Collecting Data ',time_string(pkt.time),break_requested=brk
     if keyword_set(brk) then stop
     case pkt.ctype of
          0  :  begin
            c = c0++
            tstr = '0 SYNC ERR '+time_string(systime(1),tformat='hh:mm:ss.fff')
            dprint,unit=u, dlevel=2, c,tstr,pkt.sync, format='(i6," ",a-24," | ",2Z6,260Z5)'
          end
        'C1'x:  begin
            c= c1++
            status = mav_misg_status_decom(pkt)
            mav_gse_structure_append  ,status_ptrs, status
            time = status.time
            tstr = time_string(status.time,prec=3)
            dprint,unit=u, dlevel=2, c,tstr,pkt.sync,pkt.ctype,pkt.length,pkt.buffer, format='(i6," ",a-24," | ",2Z6,260Z5)'
         end
        'C2'x:  begin
            c = c2++
            dprint,unit=u, dlevel=2, c,tstr,pkt.sync,pkt.ctype,pkt.length,pkt.buffer, format='(i6," ",a-24," | ",2Z6,260Z5)'
         end
        'C3'x:  begin
            c = c3++
            dl = 2
            msg = mav_inst_message(pkt)
            if (msg.valid eq 0) then begin
                tstr='Invalid Message'
                bad_message_cntr++
            endif else tstr = ''
            if keyword_set(tstr) then dl =1
            dprint,unit=u, dlevel=dl, c,tstr,pkt.sync,pkt.ctype,pkt.length,pkt.buffer, format='(i6," ",a-24," | ",2Z6,260Z5)'
            id0 = 0
            id0 = msg.id and '111011'b   ; make all packets look like SEP1
            case id0 of
             '08'x:  dprint,unit=u,dlevel=1,msg.length,'Event'
             '09'x:  dprint,unit=u,dlevel=1,msg.length,'Unused'
             '18'x: begin    ; Science
                sepscience = mav_sep_science_decom(msg,hkp=sephkp ,last=sepscience)  ;,last=lastscience)
                mav_gse_structure_append,  sepscience_ptrs, sepscience
               end
             '19'x: begin     ; HKP
                sephkp = mav_sep_hkp_decom(msg,last=sephkp)
                mav_gse_structure_append  ,sephkp_ptrs, sephkp
               end
             '1a'x: begin ; Noise
                sepnoise = mav_sep_noise_decom(msg,hkp=sephkp,last=sepnoise)
                mav_gse_structure_append, sepnoise_ptrs, sepnoise
              end
             '1b'x: begin
                 dprint,unit=u,dlevel=1,msg.length,'MemDump'
                 sepmemdump = mav_sep_memdump_decom(msg,hkp=sephkp,last=sepmemdump)
                 mav_gse_structure_append, sepmemdump_ptrs, sepmemdump
                end
             else:

            endcase
         end
     endcase
   endwhile
   if bad_message_cntr ne 0 then dprint,'Warning!',bad_message_cntr,' Bad Messages'
   free_lun,fp
endfor

timespan,minmax((*status_ptrs.x).time)

mav_gse_structure_append  ,status_ptrs,      tname='MISG_STATUS'
mav_gse_structure_append  ,sephkp_ptrs,      tname='SEP_HKP'
mav_gse_structure_append  ,sepnoise_ptrs,    tname= 'SEP_NOISE'
mav_gse_structure_append  ,sepscience_ptrs,  tname = 'SEP_SCIENCE'
mav_gse_structure_append  ,sepmemdump_ptrs,  tname = 'SEP_MEMDUMP'
if keyword_set(u) then free_lun,u
tplot_options,title = file


if keyword_set(realtime) then begin
;   set_tplot_options
   now = systime(1)
   tlimit,now+ [-300,0] +10 ;,verbose=0
   timebar,now
endif
end







;pro mav_sep_gse_noise_pkt_proc,pkt
;sepn = keyword_set(pkt.id and 4)
;name = 'mav_sep' + (['1','2'])(sepn)+'_noise'
;get_data,name,ptr=ptr
;if not keyword_set(ptr) then begin
;   ptr = {x:ptr_new(0),  y:ptr_new(0),  xi:ptr_new(0),  yi:ptr_new(0) }
;   store_data,name,data=ptr
;endif
;
;append_array,*ptr.x,pkt.time,index= *(ptr.xi)
;append_array,*ptr.y, [pkt.buffer], index = *(ptr.yi)
;
;; append_array, *ptr.x, index= *ptr.xi,/done
;; append_array, *ptr.y, index= *ptr.yi,/done
;
;end







pro mav_sep_gse_science_pkt_proc,pkt,ptrs,tname=tname

if not keyword_set(ptrs) then begin
   ptrs = {x:ptr_new(0),  y:ptr_new(0),  xi:ptr_new(0),  yi:ptr_new(0), v:ptr_new(0) }
endif

if keyword_set(pkt) then begin
;   if pkt.size ne 45 then stop
   append_array,*ptrs.x,pkt.time,index= *(ptrs.xi)
   append_array,*ptrs.y, pkt.buffer, index = *(ptrs.yi)
endif else begin
   append_array, *ptrs.x, index= *ptrs.xi,/done
   append_array, *ptrs.y, index= *ptrs.yi,/done
   *ptrs.y = reform(*ptrs.y,*ptrs.yi/ *ptrs.xi, *ptrs.xi)
   *ptrs.y = transpose(*ptrs.y)
   *ptrs.v = findgen( *ptrs.yi/ *ptrs.xi )
   if size(/type,tname) eq 7 then    store_data,tname,data=ptrs,dlim = {spec:1}
endelse
end




function mav_read_gse_packet,fp,time,ccsds=ccsds
  if keyword_set(ccsds) then begin
     ccsds_buffer = uintarr(6)
     readu,fp,ccsds_buffer  &  byteorder,ccsds_buffer,/swap_if_little_endian
     time = ccsds_buffer[3] * 2ul^16 +ccsds_buffer[4] + ccsds_buffer[5]/2d^16 + time_double('2001-1-1')
  endif else ccsds_buffer=0u
  hdr = 0u
  readu,fp,hdr
  byteorder,hdr,/swap_if_little_endian
  id = ishft(hdr,-10)
  size = (hdr and '03ff'x)+1
  if id eq 0 then message,'Header error'
  buffer = uintarr(size)
  readu,fp,buffer
  byteorder,buffer,/swap_if_little_endian
  pkt = {ccsds:ccsds_buffer, id:id, size:size, hdr:hdr,time:double(time), buffer:buffer}
  return,pkt
end





pro mav_sep_dap_misg_inst_msg_load

source = mav_file_source()

pathnames=0
;pathnames = 'maven/sep/prelaunch_tests/EM1/20110321_164500_general/misg_inst_msg.dat'
;pathnames = 'maven/sep/prelaunch_tests/EM1/20110321_164500_general/decMISGFile.dat'  & ccsds=0
;pathnames = 'maven/sep/prelaunch_tests/EM1/20110321_164500_general/hsk1Pkts.dat'  & ccsds=1
;pathnames = 'maven/sep/prelaunch_tests/EM1/20110321_164500_general/misg_inst_msg.dat' & ccsds=0
;pathnames = 'maven/sep/prelaunch_tests/EM1/20110321_164816_general/hsk1Pkts.dat'  & ccsds=1
;append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110321_164816_general/decMISGFile.dat'  & ccsds=0
append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110325_160624_general2/decMISGFile.dat'  & ccsds=0
append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110325_161732_general2/decMISGFile.dat'  & ccsds=0
append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110325_183831_general2/decMISGFile.dat'  & ccsds=0
pathnames=0
append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110325_160624_general2/misg_inst_msg.dat'  & ccsds=0
append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110325_161732_general2/misg_inst_msg.dat'  & ccsds=0
append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110325_183831_general2/misg_inst_msg.dat'  & ccsds=0  & outfile='misg_inst_msg_out.txt'

pathnames=0
append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110325_160624_general2/hsk1Pkts.dat'  & ccsds=1
append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110325_161732_general2/hsk1Pkts.dat'  & ccsds=1
append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110325_183831_general2/hsk1Pkts.dat'  & ccsds=1  & outfile='hsk1Pkts_out.txt'

;append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110325_183831_general2/hsk1Pkts.dat'  & ccsds=1  & outfile='hsk1Pkts_out.txt'



;file_open,'w','misg_inst_msg_out.txt',unit=u
if keyword_set(outfile) then file_open,'w',outfile,unit=u  else u=-1


for fn=0,n_elements(pathnames)-1 do begin
  file = file_retrieve(pathnames[fn],_extra=source)
  dprint,unit=u,dlevel=2,'File: ',file

  fi= file_info(file)

  if fi.exists eq 0 then continue

  file_open,'r',file,unit=fp
;file_open,'w','testout.txt',unit=u

;  dirpos2 = strpos(pathnames[fn],/reverse_search,'/')
;  dirpos1 = strpos(pathnames[fn],/reverse_search,'/',dirpos2-1)
;  time = str2time(tformat = 'YYYYMMDD_hhmmss', strmid(pathnames[fn],dirpos1+1,15) )


  while not eof(fp) do begin
     if 1 then begin
     pkt = mav_read_gse_packet(fp,time,ccsds=ccsds)
     id0 = pkt.id and '111011'b           ; Make all packets look like SEP 1 packet
     wrd=0
     wtype=0
     case id0 of
       '08'x:  dprint,unit=u,dlevel=4,pkt.size,'Event'
       '09'x:  dprint,unit=u,dlevel=4,pkt.size,'Unused'
       '18'x: begin    ; Science
           dprint,unit=u, dlevel=4,'',wrd,pkt.hdr,pkt.size,pkt.buffer, format='(i4,a24," | ",2Z6,260Z5)'
           mav_sep_gse_science_pkt_proc,pkt,science_ptrs
        end
       '19'x: begin     ; HKP
           dprint,unit=u, dlevel=4,'',wrd,pkt.hdr,pkt.size,pkt.buffer, format='(i4,a24," | ",2Z6,260Z5)'
           mav_sep_gse_science_pkt_proc,pkt,hkp_ptrs
        end
       '1a'x: begin ; Noise
           dprint,unit=u, dlevel=4,'',wrd,pkt.hdr,pkt.size,pkt.buffer, format='(i4,a24," | ",2Z6,260Z5)'
           mav_sep_gse_science_pkt_proc,pkt,noise_ptrs
        end
       '1b'x:  dprint,unit=u,dlevel=4,pkt.size,'MemDump'
     endcase
     endif
;   printdat,/hex,pkt
     time += 1/3d    ;  added one third second  (3 different messages each second)
  endwhile
  free_lun,fp
endfor

mav_sep_gse_science_pkt_proc,0,hkp_ptrs     ,tname = 'MAVEN_SEP_HKP'        ; finalize and create tplot variables
noisename = 'MAVEN_SEP_NOISE'
mav_sep_gse_science_pkt_proc,0,  noise_ptrs ,tname = noisename        ; finalize and create tplot variables
get_data,noisename,ptr=ptr
*ptr.y = *ptr.y - shift( *ptr.y, [1,0] )
(*ptr.y)[0,*] = 0
mav_sep_gse_science_pkt_proc,0,science_ptrs ,tname = 'MAVEN_SEP_SCIENCE'        ; finalize and create tplot variables

if keyword_set(u) then free_lun,u
end



; ;     dprint,unit=u,dlevel=2,i++,wrd,format='(2Z)'
;      if i ne 0 then begin
;      dprint,dlevel=0,i,' File error'
;      if 0 then begin
;        buffer = uintarr(256)
;        point_lun,-fp,pos0
;        printdat,pos0
;        pos = pos0 -512 *2
;        point_lun,fp,pos  ; backup
;
;        for j=0,3 do begin
;          point_lun,-fp,pos
;          printdat,pos
;          readu,fp,buffer  & byteorder,buffer,  /swap_if_little_endian
;          print,buffer,format='(16Z)'
;        endfor
;        point_lun,fp,pos0   ; return pointer
;        endif
;        stop
;   endif



pro mav_sep_noise_plot
 res = 'c'xu and 7
 noise = [0,0,0,0,'29'xu,'08d1'xu,'4792'xu,'5d26'xu,'13a6'xu,'8c'xu]
 xbins  = (findgen(10)-4.5 ) * 2^res
 ps = mgauss()  & ps.shift = 1 & ps.binsize = 2^res & ps.g.a = total(noise)*2^res & ps.g.s=2^res
 fit,xbins,noise,param=ps,name = 'g',itmax=30
 plot,xbins,noise,psym=4,xtitle = 'ADC units',ytitle='Counts',title='Noise Spectrum'
 pf,ps,color=2
 print,double(noise)
 print,func(param=ps,[xbins])
 printdat,ps,output = outs
 outs = [outs,string('sigma=', ps.g.s*6000./2l^15,' keV rms')]
 xyouts,.11,.9,strjoin(outs+'!c'),/norm

end

pro display_times
times = 0
append_array,times, '18:17:11'
append_array,times, '18:18:43'
append_array,times, '18:20:38'
append_array,times, '18:21:45'
append_array,times, '18:21:59'
append_array,times, '18:26:19'
append_array,times, '18:34:41'
append_array,times, '18:35:32'
append_array,times, '18:36:14'
append_array,times, '18:36:41'

tt = time_double('2011-3-25/'+times)+20 +7*3600L
store_data,'tbars',tt,tt*0
tplot_options,'timebar','tbars'
timebar,tt
end



;
;
;
;
;pro mav_common_load,realtime=realtime,pathname=pathname
;
;realtime=1
;
;if n_elements(realtime) ne 1 then realtime=0
;if keyword_set(realtime) then pathnames = 'localhost'
;
;
;if not keyword_set(realtime) then realtime=0
;
;if realtime le 0 then begin
;    source = mav_file_source()
;    pathnames = 0
;    append_array,pathnames, 'maven/sep/prelaunch_tests/EM2/20110824_213915_test/misg_all_msg.dat'
;    files = file_retrieve(pathnames,_extra= source)
;    files = file_retrieve('maven/sep/prelaunch_tests/EM2/2011*/misg_all_msg.dat',/last_version,_extra=source)
;endif
;
;if keyword_set(realtime) then  begin
;    dir = ''
;    rtfiles = file_search( dir+'CmnBlk_*.dat' )
;    nf = n_elements(rtfiles)
;    rtfiles = rtfiles[sort(rtfiles)]
;    rtfiles = rtfiles[nf-abs(realtime):*]
;    append_array,files,rtfiles
;endif
;
;file_open,'w','common_out.txt',unit=u,dlevel=2
;
;time=0d
;
;
;for fn = 0,n_elements(files)-1 do begin
;    bad_message_cntr=0
;
;    file = files[fn]
;    dprint,dlevel=2,'Processing: ',file
;    dprint,unit=u,dlevel=2,'File: ',file
;    fi= file_info(file)
;    if fi.exists then   file_open,'r',file,unit=fp,dlevel=3 else continue
;    brk = 0
;
;  while  not eof(fp) and not brk do begin
;     pkt = mav_common_block_read_file(fp,time=time)
;     if keyword_set(pkt) eq 0 then break
;     tstr = ''
;     dprint,dlevel=1,dwait=5,'Collecting Data ',time_string(pkt.time),break_requested=brk
;     if keyword_set(brk) then stop
;     printdat,pkt,/hex
;   endwhile
;   if bad_message_cntr ne 0 then dprint,'Warning!',bad_message_cntr,' Bad Messages'
;   free_lun,fp
;endfor
;
;timespan,minmax((*status_ptrs.x).time)
;
;mav_gse_structure_append  ,status_ptrs,      tname='MISG_STATUS'
;mav_gse_structure_append  ,sephkp_ptrs,      tname='SEP_HKP'
;mav_gse_structure_append  ,sepnoise_ptrs,    tname= 'SEP_NOISE'
;mav_gse_structure_append  ,sepscience_ptrs,  tname = 'SEP_SCIENCE'
;mav_gse_structure_append  ,sepmemdump_ptrs,  tname = 'SEP_MEMDUMP'
;if keyword_set(u) then free_lun,u
;tplot_options,title = file
;
;
;if keyword_set(realtime) then begin
;;   set_tplot_options
;   now = systime(1)
;   tlimit,now+ [-300,0] +10 ;,verbose=0
;   timebar,now
;endif
;end
;





;mav_sep_dap_misg_inst_msg_load
brk = 1
repeat begin
  mav_sep_dap_misg_all_msg_load ,realtime=realtime
  if not keyword_set(init) then set_tplot_options
  init =1
  dprint,'Waiting',break=brk
  if brk eq 1 then break
  wait,10
endrep until 0

if 0 then begin
tplot
timebar,'2011-03-25/23:25:07.494'
timebar,'2011-03-25/23:55:01.494'
endif
end

