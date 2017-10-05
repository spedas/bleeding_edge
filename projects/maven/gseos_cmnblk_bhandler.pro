



function gseos_cmnblkbyte_pkt,buffer

    if buffer[1] eq '90'x then return,gseos_cmnblkbyte_pkt([byte(['EB'x,'92'x, 0b, 0b]),buffer[2:25],[0b,0b],buffer[28:*]])  ; kludge to make old format work.

    dbuff = uint(buffer,0,16); changing from bytes to words.
    byteorder,dbuff,/swap_if_little_endian
;printdat,/hex,dbuff

    data_size=  dbuff[14] * 2UL^16 + dbuff[15]
    if data_size gt n_elements(buffer)+32 then dprint,'Size error!'
    data_size = data_size < (n_elements(buffer)-32)  ; safety
    if data_size gt 0 then   data = buffer[32:32+data_size-1] else begin
      data = 0b
      dprint,'Common block with zero length'
    endelse
    
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

    epoch = 946771200d    ; long(time_double('2000-1-2'))   ; good for files collected after June 2012
;    dprint,epoch
;    epoch += 365L * 24 *3600  ; change - reason unknown 9-1-2012   ; comment out this line when looking at PFDPU data.
    pkt.time =  pkt.clk_sec + pkt.clk_sub/2d^16 + epoch
    if pkt.time gt  1354752000 then pkt.time -= 12*3600d   ;  changed during testing at LM after 2012-12-06

;printdat,/hex,pkt
;    dprint,dlevel=2,time_string(pkt.time)

    return,pkt
end



pro dump_buffer,buffer,time=time

    common dump_buffer_com, last_time

    if keyword_set(time) then begin
        dprint,dlevel=3,time_string(time),' ',n_elements(buffer),' bytes'
        if n_elements(last_time) ne 0 then begin
            store_data,'RAW_DATA_RATE2',time,n_elements(buffer)/(time-last_time),/append
        endif
        last_time = time
    endif
 ;   store_data,'RECORDER_NBYTES',time,n_elements(buffer),/append

    ;hexprint,buffer
end



pro gseos_cmnblk_bhandler,buffer,time=time,remainder=remainder

common gseos_cmnblk_bhandler_com,  last_cmnblk, last_time, avg_rate, avg_n

nb = n_elements(buffer) * (size(/n_dimen,buffer) gt 0)

if keyword_set(time) then begin
    dprint,dlevel=4,time_string(time),' ',n_elements(buffer),' bytes'
 ;  avg_rate= 0d
    avg_time = 60
    if n_elements(last_time) ne 0 then begin
        deltat = time-last_time
        rate = nb/deltat
        store_data,'RAW_DATA_RATE',time,rate,/append
        avg_n = (avg_time/deltat) > 1
        avg_rate =  ( rate + (avg_n-1)*avg_rate)/avg_n
        store_data,'RAW_DATA_RATE_SM',time,avg_rate,/append
    endif else begin
        avg_rate = 0d
        avg_n = 35
    endelse
    last_time = time
endif
;dprint,dlevel=4,buffer,format= '(32(" ",Z02))'


i=0L
j=0L
while (i lt nb-6) do begin
    if  buffer[i] eq 'EB'x && (buffer[i+1] eq '92'x || buffer[i+1] eq '90'x) then begin ; the appropriate start words are EB92
        lenw = buffer[i+2] * 256UL + buffer[i+3]         ; number of bytes in cmnblk pkt
        if buffer[i+1] eq '90'x then begin               ; Format #1
            len = lenw
        endif else begin
            lenw =  lenw * 2UL^16 + buffer[i+4] *256u + buffer[i+5]
            len = lenw*2
        endelse
        if i+len le nb then begin
            pbuff = buffer[i:i+len-1]
            dprint,dlevel=4,j++,len,pbuff,format='(i2,i4,":",32(" ",Z02))'
            cmnpkt = gseos_cmnblkbyte_pkt(pbuff)
            if keyword_set(last_cmnblk) && ((dcntr = cmnpkt.seq_cntr - last_cmnblk.seq_cntr -1) ne 0) then begin
                errmsg = string('Missed ',strtrim(dcntr,2),' CMNBLKS',i,len,nb)
                dprint,errmsg
                store_data,'CMNBLK_ERROR_NOTE',cmnpkt.time,errmsg,/append,dlim={tplot_routine:'strplot',colors:6}
            endif
            last_cmnblk = cmnpkt
            mvn_gse_cmnblk_pkt_handler,cmnpkt
            i = i+len
        endif else begin
            dprint,dlevel=5,/phelp,i,len,nb
            dprint,dlevel=5,'Incomplete packet - remainder provided'
            break
        endelse
    endif else begin
        dprint,dlevel=1,'Lost Sync: ', i,dwait=1.
        i = i+1
    endelse
;    dprint,dlevel=3,'End of buffer'
endwhile
if i eq nb then remainder = 0 else remainder = buffer[i:nb-1]
return
end

