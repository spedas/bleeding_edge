
pro mav_misg_pkt_handler,cmnpkt   ;,time=time  ,completed=completed

  common MAV_MISG_PKT_HANDLER_COM, $
    status,  $
    last_dbuffer,  $
    last_cmnpkt  

    if ~keyword_set(cmnpkt) then return
    last_cmnpkt = cmnpkt

    if cmnpkt.mid4 eq 1 then begin   ; decommutate commands sent TO MISG   needs fixing
         if cmnpkt.mid3 eq 3  then  mav_sep_msg_handler,cmdpkt=cmnpkt     ; SEP commands (kludge)
;        mav_gse_command_decom,cmnpkt,memstate,hkp=sephkp,membuff=membuff
;        mav_gse_structure_append  ,memstate_ptrs, memstate, realtime=realtime
        return
    endif

    if not keyword_set(time) then time = cmnpkt.time
    if keyword_set(status)   then time = status.time

    dbuffer = uint(cmnpkt.buffer,0,cmnpkt.data_size/2)
    byteorder,dbuffer,/swap_if_little_endian

    if size(/n_dimen, last_dbuffer) eq 1 then begin
        dbuffer = [last_dbuffer,dbuffer]
    endif

    last_dbuffer=0

    while size(/n_dimen,dbuffer) ne 0 do begin

        misgpkt = mav_misg_packet_read_buffer(dbuffer,time=time)
        if not keyword_set(misgpkt) then begin
            dprint,'MISG packet error',dlevel=3
            last_dbuffer = dbuffer
            store_data,'CMNBLK_ERROR',cmnpkt.time,1,/append,dlim={psym:1}
            break
        endif

       tstr = 'xxx'
        case misgpkt.ctype of
        0:  begin
            tstr = '0 SYNC ERR '+time_string(systime(1),tformat='hh:mm:ss.fff')
            dprint,unit=u, dlevel=1, c,tstr,misgpkt.sync, format='(i6," ",a-24," | ",2Z6,260Z5)'
        end
        'C1'x:  begin    
            realtime=1    
            status = mav_misg_status_decom(misgpkt,rec_time=cmnpkt.time,last_status=status)
            ;printdat,status,realtime
            mav_gse_structure_append  ,status_ptrs, status  , realtime=realtime, tname='MISG_STATUS'
            time = status.time
        end
        'C2'x:    dprint,unit=u, dlevel=3,tstr,misgpkt.sync,misgpkt.ctype,misgpkt.length,misgpkt.data, format='(a-24," | ",2Z6,260Z5)'
        'C3'x:    mav_inst_msg_handler,misgpkt,status=status
        endcase
    endwhile

end


