pro mav_apid_counter,ccsds
;   common mav_apid_counter_com, pkts_cntr
   common mav_apid_counter_com, last_seqs,last_cmnblk, avg_dt, avg_len, int_bytes, int_time, int_blks

;   pkstat = {apid:0b, num:0L}
;   if not keyword_set(pkts_cntr) then begin
;       pkts_cntr = replicate(pkstat,256)
;       pkts_cntr.apid = bindgen(256)
;   endif
;   apid = byte(ccsds.apid)
;   pkts_cntr[apid].num += 1

dprint,'Please replace with mvn_pfdpu_cmnblk_handler'

if not keyword_set(ccsds) then begin   ; clean up
     last_seqs=0
     last_cmnblk=0
     avg_dt=0
     avg_len=0
     int_bytes=0
     int_time=0
     int_blks = 0
     store_data,'MAV_APID_*',/clear
     return
endif

   
    store_data,'MAV_APIDS',ccsds.time,ccsds.apid,dlim={psym:4,symsize:.4,constant:indgen(16)*16,panel_size:2,ystyle:3},/append

    time = ccsds.time + ccsds.time_diff           ; time data received by GSEOS  (cmnblock time)
    if n_elements(int_bytes) eq 0 then int_bytes=0L
    if n_elements(int_blks)  eq 0 then int_blks=0L
    if n_elements(int_time)  eq 0 then int_time=floor(time)-1
    int_bytes += ccsds.size
    int_blks  += 1
    if floor(time) ne int_time then begin
        append=1
        store_data,'MAV_APID_DATA_RATE',append=append,double(floor(time)), int_bytes/double(floor(time) - floor(int_time))
        store_data,'MAV_APID_PKT_RATE',append=append,double(floor(time)), int_blks/double(floor(time) - floor(int_time))
        int_time = floor(time)
        int_blks  = 0L
        int_bytes = 0L
    endif

;        st = {apid: ccsds.apid && 0xff ,  seq: ccsds.seq_cntr}
        if not keyword_set(last_seqs) then  last_seqs = replicate(0u,256)
        apid = ccsds.apid and 'ff'x
        dcntr = fix(ccsds.seq_cntr - last_seqs[apid] -1)
        if dcntr  ne 0 then begin
          ;  if apid ne 1 then 
            dprint,dlevel=3,format='("seq_cntr skipped: ",i," for APID ",Z02,"x")',dcntr,apid
            store_data,'MAV_APID_SKIPPED',/append,ccsds.time,apid,dlim={psym:4,psymsize:.4,colors:6}
        endif
        last_seqs[apid]  = ccsds.seq_cntr
;   dprint,dlevel=2,
end




pro mav_pfdpu_cmnblk_handler,cmnblk,trange=trange,cleanup=cleanup
common mav_pfdpu_cmnblk_handler_com,command_ptrs

message,'Obsolete
   ; if cmnblk.mid3 ne 3 then begin
   ;     dprint,'New mid3:', cmnblk.mid3
   ;     printdat,cmnblk
   ; endif
   

   
    
if size(/type,cmnblk) eq 8 then begin
    if cmnblk.mid4 eq 1 then begin                     ;  Commands sent to IDPU
        if n_elements(cmnblk.buffer) eq 20 then begin
            mav_gse_structure_append  ,command_ptrs, realtime=realtime, tname='pfp_cmds',cmnblk
        endif else begin
            printdat,output=outs,cmnblk.buffer,/hex
            dprint,dlevel=2,'PFDPU commands: '+outs
        endelse
        return
    endif

    ;  Data  from PFDPU  - always in the form of ccsds packets
    if n_elements(cmnblk.buffer) lt 12 then begin
        dprint,'Common Block size error'
        dprint,phelp=2,cmnblk
        return
    endif

    header = uint(cmnblk.buffer,0,6)  &  byteorder,header,/swap_if_little_endian
    MET = (header[3]*2UL^16 + header[4])
    time = mvn_spc_met_to_unixtime(MET)
    ccsds = { $
        apid: header[0] and '7FF'x , $
        seq_cntr: header[1] and '3FFF'x , $
        size : header[2] + 7  , $
        time: time,  $
        MET:  MET,   $
        code0 : ishft( header[0],15), $
        code1 : ishft( header[1],14), $
        time_diff: cmnblk.time - time, $   ; time to get transferred from PFDPU to GSEOS
        data:  cmnblk.buffer[10:*], $
        valid : 1b }

    if ccsds.size ne (n_elements(ccsds.data) +10) then begin
        dprint,dlevel=1,format='(a," x",z04,i7,i7)','CCSDS size error',ccsds.apid,ccsds.size,n_elements(ccsds.data)
    endif
    
    dprint,dlevel=4,format='("APID ",Z02,"x ",a,i5,i4,i4," | "20(" ",Z02))',ccsds.apid,time_string(ccsds.time),ccsds.seq_cntr,ccsds.size,n_elements(ccsds.data),cmnblk.buffer[0:19]
;    printdat,ccsds

    if MET lt  358000000 then begin
        dl = 1
 ;       if systime(1) lt  1353191858 + 24*3600L  then dl=3
        dprint,dlevel=dl,'Time code error: ',time_string(time),' apid=',ccsds.apid,format='(a,a,a,"x",z)'
        ccsds.valid = 0
;        printdat,/hex,ccsds
    endif 
    if ccsds.valid eq 0 then return                      ; might want to remove this error checking line

endif    else  begin
    dprint,dlevel=1,'Erasing Command_ptrs'
    ptr_free,ptr_extract(command_ptrs)
    command_ptrs = 0
endelse


    decom=0
 ;   if ccsds.time lt trange[0] then return
 ;   if ccsds.time gt trange[1] then return
    mav_apid_counter,ccsds
    mav_apid_sep_handler,ccsds,decom=decom
    mav_apid_mag_handler,ccsds,decom=decom
    mav_apid_swia_handler,ccsds,decom=decom
    mav_apid_swea_handler,ccsds,decom=decom
    mav_apid_sta_handler,ccsds,decom=decom
    mav_apid_lpw_handler,ccsds,decom=decom
    mav_apid_misc_handler,ccsds,decom=decom    ; Generic PFP packets
    mav_apid_30_handler,ccsds,decom=decom
;    if decom eq 0 then dprint,dlevel=4,'Unknown APID ',ccsds.apid,ccsds.seq_cntr,ccsds.size ,format='(a,z03," ",i,i)'
          
end
