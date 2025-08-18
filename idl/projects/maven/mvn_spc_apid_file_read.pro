

function mvn_spc_apid_decom_byte_pkt,buffer

    forward_function gseos_cmnblk_decom_byte_pkt

    if buffer[1] eq '90'x then return,gseos_cmnblk_decom_byte_pkt( [byte(['EB'x,'92'x, 0b, 0b]),buffer[2:25],[0b,0b],buffer[28:*]] )  ; kludge to make old format work.

    dbuff = uint(buffer,0,16)
    byteorder,dbuff,/swap_if_little_endian

    data_size=  dbuff[14] * 2UL^16 + dbuff[15]
    if data_size gt n_elements(buffer)+32 then begin
        dprint,'CMNBLK Size error!  - SEQ_CNTR=',dbuff[3]
    endif
    data_size = data_size < (n_elements(buffer)-32)  ; safety
    if data_size eq 0 then begin
      dprint,dlevel=3,'CMNBLK with NO DATA  - SEQ_CNTR=',dbuff[3]
      data=0 
    endif  else data = buffer[32:32+data_size-1]

    pkt = { time:0d, $
            valid   :  1,   $
            sync:     dbuff[0],  $
            length  : dbuff[1] *2UL^16 + dbuff[2],  $
            seq_cntr: dbuff[3],  $
            cc1     : dbuff[4],  $
            cc2     : dbuff[5],  $
            cc3     : dbuff[6],  $
            clk_sec : dbuff[7] *2UL^16 + dbuff[8],   $
            clk_sub : dbuff[9],   $
            mid1    : byte(ishft(dbuff[10],-8)) , $
            mid2    : byte(dbuff[10]), $
            mid3    : byte(ishft(dbuff[11],-8)), $
            mid4    : byte(dbuff[11]), $
            user1   : dbuff[12], $
            data_byteorder: byte(ishft(dbuff[13],-8)), $
            data_type: byte(dbuff[13]) , $
            data_size:  data_size, $
            buffer:data }

    epoch =  978307200d    ; long(time_double('2001-1-1'))  ; valid for files prior to about June, 2012
    epoch =  946771200d    ; long(time_double('2000-1-2'))  ; Normal use
    pkt.time =  pkt.clk_sec + pkt.clk_sub/2d^16 +  epoch    ;

;printdat,/hex,pkt
    return,pkt
end







PRO mvn_spc_apid_read_buffer,buffer1,time=time

;,count=count,eofile=eofile, trange=trange,$
;                     decom=decom, outputfp=outputfp, display_widget=display_widget,_extra=ex

    eofile =0
    count=0L
    localtime=1
    treceived = systime(1)
    msg = time_string(treceived,tformat='hh:mm:ss - ',local=localtime)
    if keyword_set(display_widget) then  widget_control,display_widget,set_value=msg

;    sync = bytarr(2)
;    lenbuff = bytarr(4)
;    header = bytarr(11)
    b1 =byte(0)
    b2=b1
    seq  = 0u
    size = 0u
    met = 0ul 
    bbb = 0b
    checksum = 0u
    nbad=0
    apid_map = bytarr(256)
    apid_map[['50'x,'51'x,'52'x,'62'x]] = 1
 ;   apid_map['51'x] = 2
    i = 0L
    bsize = n_elements(buffer1)
; hexprint,buffer1
    while i lt bsize do begin
;        if eof(fileunit) then begin
;            eofile = 1
;            break
;        endif
;        fs = fstat(fileunit)
;        remaining = fs.size - fs.cur_ptr
        remaining = bsize - i
        if remaining lt 11 then begin  ;  minimum size of spacecraft packet
            dprint,'Incomplete header at end of file - quitting ',remaining,' bytes left',dlevel=1
            break
        endif
        b1 = buffer1[i++]    ;        readu,fileunit,b1
        if b1 eq 8b then begin
            if nbad ne 0 then begin
                dprint,nbad, ' Bad sync bytes'
                nbad = 0
            endif
            b2 = buffer1[i++]  ;            readu,fileunit,b2
            
            if apid_map[ b2 ] ne 0  then begin
                if apid_map[b2] eq 2 then stop
                seq = (uint(buffer1,i,1))[0]  & i+=2    &   byteorder,/swap_if_little_endian,seq   ;             readu,fileunit,seq      
                size = (uint(buffer1,i,1))[0] & i+=2     &   byteorder,/swap_if_little_endian,size ;             readu,fileunit,size     
                met = (ulong(buffer1,i,1))[0] & i+=4     &   byteorder,/swap_if_little_endian,/lswap,met;             readu,fileunit,MET     
                bbb = buffer1[i++]                  ; readu,fileunit,bbb  ; &   byteorder,/swap_if_little_endian,checksum
                dprint,dlevel=4,seq,size,met ,bbb 
                buffer = buffer1[i:i+size-6-1] & i+= (size-6)   ; buffer = bytarr(size-6)   ;                readu,fileunit,buffer
                checksum = uint(buffer1,i,1)  & i+=2  &   byteorder,/swap_if_little_endian,checksum    ;                readu,fileunit,checksum 
 ;               hexprint,buffer
 ;               printdat,/hex,checksum
                spcpkt = { $
                  time: double(mvn_spc_met_to_unixtime(met))  , $
                  spc_MET: met,  $
                  mid4:0, $
                  checksum:checksum, $
                  buffer:buffer  }
                  
                mav_pfdpu_cmnblk_handler, spcpkt
            endif else begin
                nbad++
                dprint,'apid =',b1,b2,format='(a,x,x)'
            endelse
        endif else begin ;  sync error -   read bytes one at a time
            nbad++
        endelse

    endwhile
;    append_array,buffer,index=count


    if keyword_set(time) then begin
        dprint,dlevel=4,time_string(time),' ',n_elements(buffer),' bytes'
        if n_elements(last_time) ne 0 then begin
            store_data,'RAW_DATA_RATE',time,count/(time-last_time),/append
        endif
        last_time = time
    endif
    return
end








PRO mvn_spc_apid_readu,fileunit,count=count,eofile=eofile, trange=trange,$
                     decom=decom, outputfp=outputfp, display_widget=display_widget,_extra=ex

    eofile =0
;    if not keyword_set(buffer) then buffer= bytarr(2L^10)
;    b=buffer[0]
;    maxsize = 2L^20   ; 1 Meg
    count=0L
    localtime=1
    treceived = systime(1)
    msg = time_string(treceived,tformat='hh:mm:ss - ',local=localtime)
    if keyword_set(display_widget) then  widget_control,display_widget,set_value=msg

;    sync = bytarr(2)
;    lenbuff = bytarr(4)
;    header = bytarr(11)
    b1 =byte(0)
    b2=b1
    seq  = 0u
    size = 0u
    met = 0ul 
    bbb = 0b
    checksum = 0u
    nbad=0
    apid_map = bytarr(256)
    apid_map[['50'x,'51'x,'52'x,'62'x]] = 1
 ;   apid_map['51'x] = 2
    while file_poll_input(fileunit,timeout=0) do begin
        if eof(fileunit) then begin
            eofile = 1
            break
        endif
        fs = fstat(fileunit)
        remaining = fs.size - fs.cur_ptr
        dprint,dwait=10,dlevel=1,100.*double(fs.cur_ptr)/fs.size,fs.name,format='(f5.1,"%   ",a)'
        if remaining lt 11 then begin  ;  minimum size of spacecraft packet
            dprint,'Incomplete header at end of file - quitting ',remaining,' bytes left',dlevel=1
            break
        endif
        readu,fileunit,b1
        if b1 eq 8b then begin
            if nbad ne 0 then begin
                dprint,nbad, ' Bad sync bytes'
                nbad = 0
            endif
            readu,fileunit,b2
            
            if apid_map[ b2 ] ne 0  then begin
                if apid_map[b2] eq 2 then stop
                readu,fileunit,seq        &   byteorder,/swap_if_little_endian,seq
                readu,fileunit,size       &   byteorder,/swap_if_little_endian,size
                readu,fileunit,MET      &   byteorder,/swap_if_little_endian,/lswap,met
                readu,fileunit,bbb  ; &   byteorder,/swap_if_little_endian,checksum
 ;               printdat,/hex,seq,size,met ,bbb 
                buffer = bytarr(size-6)
                fs = fstat(fileunit)
                remaining = fs.size - fs.cur_ptr
                if remaining lt n_elements(buffer) then begin  ;  incomplete packet
                   dprint,'Incomplete packet at end of file - quitting ',remaining,' bytes left',dlevel=1
                   break
                endif
                readu,fileunit,buffer
                readu,fileunit,checksum &   byteorder,/swap_if_little_endian,checksum
 ;               hexprint,buffer
 ;               printdat,/hex,checksum
                spcpkt = { $
                  time: double(mvn_spc_met_to_unixtime(met))  , $
                  spc_MET: met,  $
                  mid4:0, $
                  checksum:checksum, $
                  buffer:buffer  }
                  
                mvn_pfdpu_cmnblk_handler, spcpkt   ;,trange=trange
            endif else begin
                nbad++
                dprint,'apid =',b1,b2,format='(a,x,x)'
            endelse
        endif else begin ;  sync error -   read bytes one at a time
            nbad++
        endelse

    endwhile
;    append_array,buffer,index=count


    if keyword_set(time) then begin
        dprint,dlevel=4,time_string(time),' ',n_elements(buffer),' bytes'
        if n_elements(last_time) ne 0 then begin
            store_data,'RAW_DATA_RATE',time,count/(time-last_time),/append
        endif
        last_time = time
    endif
    return
end







pro mvn_spc_apid_file_read,files=files,trange=trange

for i=0,n_elements(files)-1 do begin
   file=files[i]
   file_open,'r',file,unit=ifp,dlevel=3
   if ifp eq 0 then begin
      dprint,'Invalid file: ',file
      continue
   endif
   firstbyte = 0b
   readu,ifp,firstbyte
   point_lun,ifp,0
   on_ioerror,bad
   if firstbyte eq 'EB'x then begin                   ; Kludge to trap for common blocks
      mvn_cmnblk_readu,ifp,trange=trange,decom=1
   endif     else begin
      mvn_spc_apid_readu,ifp,trange=trange
   endelse
   bad: ;print,!err_string
   free_lun,ifp
endfor
return
end
