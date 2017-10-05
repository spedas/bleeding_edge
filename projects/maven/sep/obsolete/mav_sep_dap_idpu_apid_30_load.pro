function mav_idpu_apid_packet_read,fp,time=time,unit=unit,verbose=verbose
    fst = fstat(fp)
    swrd = 0u
    readu,fp,swrd
    byteorder,swrd,  /swap_if_little_endian
    cntr = 0u
    len = 0u
    valid = 0
    ccsds = uintarr(3)
    buffer = 0u
    tstr = 'Bad Sync'
    if swrd eq '0830'x then begin
        readu,fp,cntr,len
        byteorder,cntr,len,  /swap_if_little_endian
        buffer = uintarr((len+1)/2 -3)
        readu,fp,ccsds,buffer
        byteorder,ccsds,buffer, /swap_if_little_endian
        time = ccsds[0] * 2ul^16 +ccsds[1] + ccsds[2]/2d^16 + 978307200  ; + time_double('2001-1-1')
        valid = 1
        tstr = time_string(time,prec=3)
        dprint,unit=unit,verbose=verbose, dlevel=2,tstr,swrd,cntr,len,buffer, format='(" ",a-24," | ",3(" ",Z04),360Z5)'
    endif else begin
        buffer=0
        dprint,unit=unit,verbose=verbose, dlevel=0,tstr,swrd,     format='(" ",a-24," | ",Z6)'
    endelse
    pkt = {ccsds:ccsds,ctype:'c3'x, time:time, sync: swrd,  cntr:cntr,  length:len, buffer:buffer ,valid:valid}
    return,pkt
end



; |   A829    C1    8 5D75 1354 9FDB 2C49 8313    0 A101    0
; |   A829    C3   19 6417  65F 666E 98E9 663E 657B 9A80 7E8B 7FB9  132 7800 2078  BF0 9100 2D38    0    0    0    0    0    0    0    0  100 1234
; |   A829    C3  101 60FF    0    0    0    0    0    0    0    0    0    0
; |   A829    C3   3D 683B   55    0    0    0    0 AAD2 CC05 8FB3 2672 6002   55    0    0    0    0 AAD2 CC05 8FB3 2672 6002   2B    0


pro mav_sep_dap_idpu_apid_30_load,realtime=realtime

if n_elements(realtime) ne 1 then realtime=0
if keyword_set(realtime) then pathnames = 'localhost'


if not keyword_set(realtime) then begin
    source = mav_file_source()
    pathnames = 0
;    append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110411_151423_test/ipudpsci.dat
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110411_154637_sep_EMIT/ipudpsci.dat
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110411_160348_SEP_EMIT/ipudpsci.dat'
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110411_161754_sep_EMIT_HP/ipudpsci.dat'
    pathnames = 0
;;    append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110411_154637_sep_EMIT/ipudp_msg.dat'
;;    append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110411_154637_sep_EMIT/cipidpFile.dat'
    append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110411_154637_sep_EMIT/rawtcp_buf.dat'
;    append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110411_154637_SEP_EMIT/ipudp_msg.dat'
;    append_array,pathnames, 'maven/sep/prelaunch_tests/EM1/20110411_160348_SEP_EMIT/ipudp_msg.dat'
    pathnames = 0
    append_array,pathnames, 'maven/sep/testdir/20110816_184549_emit/decMISGFile.dat'
    files = file_retrieve(pathnames,_extra= source)
endif else begin
    dir = ''
    files = file_search( dir+'APID30_*.dat' )
    files = files[n_elements(files)-1]  ; get last one only
endelse

dir = file_dirname(files[0])
printdat,dir
file_open,'w','e:/temp/ipudpsci_out.txt',unit=u

c0=0
c1=0
c2=0
c3=0

time=0d


for fn = 0,n_elements(files)-1 do begin

    file = files[fn]
    dprint,dlevel=1,'FILE: ',file
    dprint,unit=u,dlevel=2,'File: ',file
    fi= file_info(file)
    if fi.exists then   file_open,'r',file,unit=fp else continue

    brk = 0

    while  not eof(fp) and not brk do begin
        pkt = mav_idpu_apid_packet_read(fp,time=time,unit=u) ;,ccsds=ccsds)
        if keyword_set(pkt) eq 0 then break
        tstr = ''
        dprint,dlevel=1,dwait=5,'Collecting Data ',time_string(pkt.time),break_requested=brk
        if keyword_set(brk) then stop
        case pkt.ctype of
        0  :  begin
            c = c0++
            tstr = '0 SYNC ERR '+time_string(systime(1),tformat='hh:mm:ss.fff')
;            dprint,unit=u, dlevel=3, c,tstr,pkt.sync, format='(i6," ",a-24," | ",2Z6,260Z5)'
        end
        'C1'x:  begin
            c= c1++
            status = mav_misg_status_decom(pkt)
            mav_gse_structure_append  ,status_ptrs, status
            time = status.time
            tstr = time_string(status.time,prec=3)
;            dprint,unit=u, dlevel=3, c,tstr,pkt.sync,pkt.ctype,pkt.length,pkt.buffer, format='(i6," ",a-24," | ",2Z6,260Z5)'
         end
        'C2'x:  begin
            c = c2++
;            dprint,unit=u, dlevel=3, c,tstr,pkt.sync,pkt.ctype,pkt.length,pkt.buffer, format='(i6," ",a-24," | ",2Z6,260Z5)'
         end
        'C3'x:  begin
            c = c3++
            dl = 3
            msg = mav_inst_message(pkt,/allow_pad)
            if (msg.valid eq 0) then tstr='Invalid Message' else tstr = ''
            if keyword_set(tstr) then dl =1
;            dprint,unit=u, dlevel=dl, c,tstr,pkt.sync,pkt.ctype,pkt.length,pkt.buffer, format='(i6," ",a-24," | ",2Z6,260Z5)'
            id0 = 0
            id0 = msg.id and '111011'b   ; make all packets look like SEP1
            case id0 of
            '08'x:  dprint,unit=u,dlevel=1,msg.length,'Event'
            '09'x:  dprint,unit=u,dlevel=1,msg.length,'Unused'
            '18'x: begin    ; Science
                mav_misg_message_proc,msg,science_ptrs,defsize=256
            end
            '19'x: begin     ; HKP
                sephkp = mav_sep_hkp_decom(msg,last=sephkp)
                mav_gse_structure_append  ,sephkp_ptrs, sephkp
;                mav_misg_message_proc,msg,hkp_ptrs,defsize=24
            end
            '1a'x: begin ; Noise
                mav_misg_message_proc,msg,noise_ptrs,defsize=60
            end
            '1b'x:  dprint,unit=u,dlevel=1,msg.length,'MemDump'
            else:
            endcase
        end
        endcase
    endwhile
    free_lun,fp
endfor

if 1 then begin
;mav_misg_message_proc,0,hkp_ptrs     ,tname = 'MAVEN_SEP_HKP'        ; finalize and create tplot variables
if keyword_set(noise_ptrs) then begin
  noisename = 'MAVEN_SEP_NOISE'
  mav_misg_message_proc,0,  noise_ptrs ,tname = noisename        ; finalize and create tplot variables
  get_data,noisename,ptr=ptr
  *ptr.y = *ptr.y - shift( *ptr.y, [1,0] )
  dt = shift(*ptr.x,-1) - shift( *ptr.x, 1)
  w = where( abs(dt) gt  2.5)
  (*ptr.y)[w,*] = 0
  *ptr.v += 0.5
  mav_misg_message_proc,0,science_ptrs ,tname = 'MAVEN_SEP_SCIENCE'        ; finalize and create tplot variables

endif


endif

mav_gse_structure_append  ,status_ptrs, tname='STATUS'
mav_gse_structure_append  ,sephkp_ptrs, tname='SEPHKP'
;append_array,status_all,index=status_index,/done
if keyword_set(u) then free_lun,u

if keyword_set(realtime) then tlimit,systime(1)+ [-500,0]
end




mav_sep_dap_idpu_apid_30_load,realtime=realtime
end