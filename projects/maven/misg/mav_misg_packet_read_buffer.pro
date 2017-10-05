; reads portion of word buffer and returns next misg packet


function mav_misg_packet_read_buffer,buffer,time=time
    bsize = n_elements(buffer)
;    cur_ptr = 0
    smallest_size = 4  ; size of smallest possible message
    ptr = 0
    pkt = 0   ; return value
    syncerrors= 0
    while ptr le (bsize - smallest_size) do begin
;    printdat,buffer,output=str,/hex  &  dprint,dlevel=3,string(ptr)+' '+str

        swrd = buffer[ptr++]            ; printdat,buffer,swrd,ctype,n,/hex
        if swrd eq 'A829'x then begin
            ctype = buffer[ptr++]
            n     = buffer[ptr++]
            if n ne 0 then begin
                if ptr gt bsize - n then begin
                    dprint,dlevel=3,'Incomplete packet ignored. found ',bsize-ptr,' of ',n,' words'
                    return,0
                endif
                data = buffer[ptr: ptr+n-1]    ;data = uintarr(n)
                ptr += n                             ;readu,fp,data
                pkt = {time:time, sync: swrd,  ctype:ctype,  length:n, type:2, data:data }
                break
            endif else begin
                data = 0
                dprint,'Major error 1'
                stop
            endelse
        endif else begin
            syncerrors++
            data=0
        endelse
    endwhile
    if keyword_set(syncerrors) then begin
        errmsg = string('MISG Message ',syncerrors,' sync errors ')
        dprint,errmsg,dlevel=1
        store_data,'MISG_ERROR_NOTE',time,errmsg,dlim={tplot_routine:'strplot'},/append
    endif
    if ptr lt bsize then dprint,dlevel=5,'Warning - Multiple messages per Buffer'
    if ptr eq bsize then buffer =0 else buffer= buffer[ptr:*]
    return,pkt
end






