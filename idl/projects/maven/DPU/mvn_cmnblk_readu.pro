

function gseos_cmnblk_decom_byte_pkt,buffer

    if buffer[1] eq '90'x then return,gseos_cmnblk_decom_byte_pkt([byte(['EB'x,'92'x, 0b, 0b]),buffer[2:25],[0b,0b],buffer[28:*]])  ; kludge to make old format work.

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



PRO mvn_cmnblk_readu,fileunit,count=count,eofile=eofile, trange=trange,$
                     decom=decom, outputfp=outputfp, display_widget=display_widget,_extra=ex

    eofile =0
;    if not keyword_set(buffer) then buffer= bytarr(2L^10)
;    b=buffer[0]
;    maxsize = 2L^20   ; 1 Meg
    count=0L
    localtime=1
    treceived = systime(1)
    if keyword_set(display_widget) then begin
       msg = time_string(treceived,tformat='hh:mm:ss - ',local=localtime)
       widget_control,display_widget,set_value=msg
    endif
    
    
    sync = bytarr(2)
    lenbuff = bytarr(4)
    
    while file_poll_input(fileunit,timeout=0) do begin
        if eof(fileunit) then begin
            eofile = 1
            break
        endif
        fs = fstat(fileunit)
        remaining = fs.size - fs.cur_ptr
        if remaining lt 16 then begin
            dprint,'Incomplete header at end of file - quitting ',remaining,' bytes left',dlevel=1
            break
        endif
        dprint,dwait=10.,float(fs.cur_ptr)/float(fs.size),fs.cur_ptr,fs.size
        readu,fileunit,sync
        if (sync[0] eq 'EB'x) && (sync[1] eq '92'x) then begin
            readu,fileunit,lenbuff
            len = (((lenbuff[0]*256L)+lenbuff[1]*256L)+lenbuff[2])*256L+lenbuff[3]
            len = len*2
            if len gt 2L^21 then message,'Error: size is too big'
            buff2 = bytarr(len-6)
            fs = fstat(fileunit)
            remaining = fs.size - fs.cur_ptr
            if remaining lt (len-6) then begin
              dprint,'Incomplete packet at end of file - quitting ',remaining,' bytes left',dlevel=1
              break
            endif
            readu,fileunit,buff2
            pkbuff = [sync,lenbuff,buff2]
            count += len
            if keyword_set(outputfp) then begin
                writeu,outputfp, pkbuff
                flush,outputfp
            endif
            sz = len
            if sz ne 0 then  msg1 = string(/print,sz,pkbuff[0:(sz < 128)-1],format='(i ," bytes: ", 128(" ",Z02))')    $
            else   msg1 = 'No data available'
            if keyword_set(display_widget) then  widget_control,display_widget,set_value=msg+msg1


            if keyword_set(decom) then begin
                cmnpkt =  gseos_cmnblk_decom_byte_pkt(pkbuff)
                if ~((n_elements(trange) ge 1) && cmnpkt.time lt trange[0]) then $
                    mvn_gse_cmnblk_pkt_handler,cmnpkt
            endif
        endif else begin
            dprint, format="('CMNBLK sync error: ',2Z02)",sync
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



