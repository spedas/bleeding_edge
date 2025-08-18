; This routine serves the dual purpose of decomutating MISG messages and PFDPU packets

function mvn_sep_hkp_pfdpu_decom,pkt,last_hkp=last_hkp,memstate=memstate,gap=gap
   if pkt.valid eq 0 then return, fill_nan(last_hkp)
   time = pkt.time
   met = pkt.met
   dtime =  0d   ; msg.time - last_hkp.time
   seq_dcntr = 0 ;
   if keyword_set(last_hkp) then begin
     dtime = pkt.time - last_hkp.time
     seq_dcntr = fix( pkt.seq_cntr - last_hkp.seq_cntr)
     gap = seq_dcntr ne 1
   endif
   data = pkt.data
   if  size(/type,data) eq 1 then begin     ; convert to uint if necessary (used for ccsds packets)
;      dprint,'debug:'
;      printdat,pkt
      seq_cntr = pkt.seq_cntr
      data = uint( pkt.data,0,n_elements(pkt.data)/2)
      byteorder,data,/swap_if_little_endian
   endif else begin        ; 
      last_dacs = keyword_set(memstate) ? memstate.dacs : replicate (0u,12)
      data = [data,replicate(0u,8),last_dacs]
   endelse
   amonitor = fix(data[0:7])
   mapid    = byte( ishft( data[8],-8 ) )
   fpga_rev = byte( data[8] and 'ff'x  )
   vcmd_cntr = byte(  ishft( data[9],-8) )   ; valid command counter
   vcmd_rate= 0b
   icmd_cntr =  byte( data[9] and 'ff'x  )
   icmd_rate = 0b
   cmd_dcntr  = byte( keyword_set(memstate) ?  (memstate.ncmds mod 256) - vcmd_cntr : 0 )
   mode_flags    =  data[10]
   noise_flags    =  data[11]
   noise_res     = byte(  ishft(data[11],-8) and '111'b )
   noise_per    =   byte(data[11] and 'ff'x)
   mem_addr     =  data[12]
   mem_checksum =  byte(  ishft( data[13] ,-8) )
   pps_cntr     =  byte(  data[13] and 'ff'x )
   event_cntr   =  data[14]
   rate_cntr    =  data[15:20]
   cntr1 = byte( ishft( data[21],-12 ) and 'f'x )
   cntr2 = byte( ishft( data[21],-8 ) and 'f'x )
   cntr3 = byte( ishft( data[21],-4 ) and 'f'x )
   cntr4 = byte( ishft( data[21],0 ) and 'f'x )
   timeout_cntrs = [cntr1,cntr2,cntr3,cntr4]
   det_timeout   = byte(ishft(data[22],-8) )
   nopeak_cntr   = byte( data[22] and 'ff'x )
   nopeak_rate   = 0b
   reserved      = data[23]
   if (n_elements(data) ne 45)  then begin
         dprint,'HKP pkt error ',n_elements(data),' ne 45'
         data = [data,replicate(data[0],20)] 
   endif
     ; enhanced version from PFDPU
      TableVER = byte(ishft(data [24], -8))                      ; SEP table version
      Compcode = byte(data[24])           ; "Options [ xxxxNNCC ]: CC=Compression Type for SCI data; NN=Compression Type for NOI data."
      RTAVG = byte(ishft(data[25], -8))                    ;SEP RT Spectra Avg Interval 2^N, N=[0..5]
      ARCAVG = byte(data[25])         ;SEP Arc Spectra Avg Interval 2^N, N=[0..5]  
      LUTADR=byte(ishft(data[26], -8))                   ;Lookup Table Directory Index 
      LUTCSM=byte(data [26])          ;Lookup Table Checksum Expected
      CSMLMT=byte(ishft(data[27], -8))                    ;CSM Failure Limit
      CSMCTR= byte(data[27])         ;CSM Failure Count
      RSTLMT=byte(ishft(data[28], -8))                    ;Reset if No Messages in Seconds
      RSTSEC=byte(data[28])          ;Reset Seconds Since Last Message
      BINMAX=byte(ishft(data[29], -8))                    ; Spectra Bins Maximum
      ATTPER= byte(data[29])         ; Attenuator Movement Period =2^N
      ATTIN= data[30]                                       ;Attenuator In Threshold
      ATTOUT= data [31]                                      ;Attenuator Out Threshold
      BIASLIM= data [32]                                      ;Bias lim threshold
      DACS = data[33:44] 
;      SEP1T1ODT: data [32], $                                       ;Telescope 1, O Detector Threshold
;      SEP1T1TDT: data [33], $                                       ;Telescope 1, T Detector Threshold
;      SEP1T1FDT: data [34], $                                       ;Telescope 1, F Detector Threshold
;      SEP1T1AUX: data [35], $                                       ;telescope 1 auxiliary
;      SEP1T2ODT: data [36], $                                       ;Telescope 2, O Detector Threshold
;      SEP1T2TDT: data [37], $                                       ;Telescope 2, T Detector Threshold
;      SEP1T2FDT: data [38], $                                       ;Telescope 2, F Detector Thresholdv
;      SEP1T2AUX: data [39], $                                       ;Telescope 2 auxiliary
;      SEP1TPH0: data [40], $                                       ;pulse height O
;      SEP1TPHT: data [41], $                                       ;pulse height T
;      SEP1TPHF: data [42], $                                       ;pulse height F
;      SEP1BIAS: data [43] $                                       ;Bias voltage
   
  ; else dprint,'SEP HKP error.', n_elemt
   
   par_dap = mvn_sep_therm_temp2()
   par_dap.r1 = 51000.
   par_dap.rv = 1e9
   par_dap.xmax = 2.5
   par_s1 = par_dap
   par_s2 = par_s1

   sephkp = {time :      time,      $
             met: met,  $
             et:  !values.d_nan,  $
             f0:  0UL,  $
             dtime :    dtime,  $
             seq_cntr: seq_cntr, $
             seq_dcntr: seq_dcntr, $
             amonitor:  amonitor,   $
             Amon_Bias_voltage: amonitor[0] * (38.57*2.5/2L^15), $
             Amon_Bias_current: amonitor[1] * 2.5/ 2L^15, $
             Amon_TEMP_DAP: func(par=par_dap,amonitor[2] * 2.5/ 2L^15), $
             Amon_P5VD: amonitor[3] * 2.5/ 2L^15 * 5/2., $
             Amon_P5VA: amonitor[4] * 2.5/ 2L^15 * 5/2., $
             Amon_M5VA: amonitor[5] * 2.5/ 2L^15 * 5/2., $
             Amon_TEMP_S1: func(par=par_s1,amonitor[6] * 2.5/ 2L^15), $
             Amon_TEMP_S2: func(par=par_s2,amonitor[7] * 2.5/ 2L^15), $
             mapid:     mapid,  $
             fpga_rev:   fpga_rev,  $
             vcmd_cntr :   vcmd_cntr  ,   $
             vcmd_rate :   vcmd_rate , $
             icmd_cntr :   icmd_cntr, $
             icmd_rate :   icmd_rate,  $
             cmd_dcntr :   cmd_dcntr,  $
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
             reserved:  reserved,  $    ; always 0x1234
             TableVER : byte(ishft(data [24], -8)), $                      ; SEP table version
             Compcode : byte(data[24]) , $           ; "Options [ xxxxNNCC ]: CC=Compression Type for SCI data; NN=Compression Type for NOI data."
             RTAVG  : byte(ishft(data[25], -8)), $                    ;SEP RT Spectra Avg Interval 2^N, N=[0..5]
             ARCAVG : byte(data[25]), $         ;SEP Arc Spectra Avg Interval 2^N, N=[0..5]  
             LUTADR : byte(ishft(data[26], -8)), $                   ;Lookup Table Directory Index 
             LUTCSM : byte(data [26]), $          ;Lookup Table Checksum Expected
             CSMLMT : byte(ishft(data[27], -8)), $                    ;CSM Failure Limit
             CSMCTR : byte(data[27]),$         ;CSM Failure Count
             RSTLMT : byte(ishft(data[28], -8)),$                    ;Reset if No Messages in Seconds
             RSTSEC : byte(data[28]),$          ;Reset Seconds Since Last Message
             BINMAX : byte(ishft(data[29], -8)),$                    ; Spectra Bins Maximum
             ATTPER : byte(data[29]),$         ; Attenuator Movement Period =2^N
             ATTIN : data[30] ,$                                      ;Attenuator In Threshold
             ATTOUT : data [31] ,$                                     ;Attenuator Out Threshold
             BIASLIM: data [32] ,$                                     ;Bias lim threshold
             DACS : data[33:44] }

    ;dprint,sephkp.pps_cntr,dlevel=2
    ;printdat,/valu,sephkp,out=sss
    ;display_text,44,exec_text=sss

    if keyword_set(last_hkp) then begin
        sephkp.dtime  = sephkp.time - last_hkp.time
        sephkp.nopeak_rate = sephkp.nopeak_cntr - last_hkp.nopeak_cntr
        sephkp.vcmd_rate = sephkp.vcmd_cntr - last_hkp.vcmd_cntr
        sephkp.icmd_rate = sephkp.icmd_cntr - last_hkp.icmd_cntr
    endif

   return,sephkp
end

