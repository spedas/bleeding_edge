;+
; Handle various type of common block packets
; executes appropriate decommutator given a generic common block packet
;-






;  This routine computes stats for common block data
pro mvn_gse_cmnblk_stats,cmnblk,append=append

    common mvn_gse_cmnblk_stats_com, last_cmnblk, avg_dt, avg_len, int_bytes, int_time, int_blks

    append = 1

    if keyword_set(last_cmnblk)  then begin

        dtime = cmnblk.time - last_cmnblk.time
        if dtime lt -1.0 then begin
            dprint,dlevel=2,'Negative time increment:', time_string(cmnblk.time) ,dtime, 'seconds'
        endif

        dcntr = cmnblk.seq_cntr - last_cmnblk.seq_cntr-1
        if dcntr ne 0 then begin
            append=2
            errmsg = string('Missed ',strtrim(dcntr,2),' CMNBLKS  seq_cntr=',cmnblk.seq_cntr) ;,i,len,nb)
            dprint,errmsg,dlevel=1
            store_data,'CMNBLK_ERROR_NOTE',cmnblk.time,errmsg,append=append,dlim={tplot_routine:'strplot',colors:6}
        endif
        store_data,'CMNBLK_SEQ_DCNTR',append=append,cmnblk.time, dcntr

        dt = cmnblk.time - last_cmnblk.time
        len = cmnblk.length*2.
        avgx = .2
        avg_len = (avgx * len+ (keyword_set(avg_len) ? avg_len : len) )/(1+avgx)
        avg_dt  = (avgx * dt + (keyword_set(avg_dt)  ? avg_dt  : dt ) )/(1+avgx)
        store_data,'CMNBLK_AVG_DATA_RATE',append=append,cmnblk.time, avg_len/avg_dt
;        endelse
    endif

    last_cmnblk = cmnblk

    delaytime = systime(1) - cmnblk.time
    store_data,'CMNBLK_TIME_DELAY',append=append,cmnblk.time,delaytime

    if n_elements(int_bytes) eq 0 then int_bytes=0L
    if n_elements(int_blks)  eq 0 then int_blks=0L
    if n_elements(int_time)  eq 0 then int_time=floor(cmnblk.time)-1
    int_bytes += cmnblk.length*2
    int_blks  += 1
    if floor(cmnblk.time) ne int_time then begin
        store_data,'CMNBLK_DATA_RATE',append=append,double(floor(cmnblk.time)), int_bytes/double(floor(cmnblk.time) - floor(int_time))
        store_data,'CMNBLK_BLK_RATE',append=append,double(floor(cmnblk.time)), int_blks/double(floor(cmnblk.time) - floor(int_time))
        int_time = floor(cmnblk.time)
        int_blks  = 0L
        int_bytes = 0L
    endif

end






pro  mvn_gse_cmnblk_pkt_handler,cmnblk   

    mvn_gse_cmnblk_stats,cmnblk,append=append

    if cmnblk.mid1 ne 1 then dprint,'Not a MAVEN instrument cmnblk'
    dl=2
 ;   dprint,dlevel=2,cmnblk.mid2," ",time_string(cmnblk.time)
    case cmnblk.mid2 of
        5:  mvn_pfdpu_cmnblk_handler,cmnblk     ;  dprint,dlevel=dl,'PFDPU packet'
        1:  mav_log_message_handler,cmnblk     ; dprint,dlevel=dl,'Log Message'
        2:  dprint,dlevel=dl,'Error Message'   ; not implemented yet
        3:  mav_user_note_handler,cmnblk
; ;;;;       4:  mav_gse_misg_msg_handler,cmnblk    ; old method
        4:  mav_misg_pkt_handler,cmnblk       ; newer method 6/2/2012
        6:  gseos_cmnblk_gpib_handler,cmnblk
        7:  dprint,dlevel=dl,'Manipulator packet'
        8:  dprint,dlevel=dl,'Spacecraft packet'
        else:  dprint,dlevel=0,'Undefined CMNBLK packet # ',cmnblk.mid2


    endcase



end