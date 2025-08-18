;$LastChangedBy: rlivi04 $
;$LastChangedDate: 2023-01-31 16:42:00 -0800 (Tue, 31 Jan 2023) $
;$LastChangedRevision: 31451 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/esa/common/esc_fram_apdat__define.pro $


;; ----------------------------------------
;; | Bytes |  Bit  |    Data Value        |
;; |---------------------------------------
;; |  0-1  |       |    iMCPV       [V]   |
;; |  2-3  |       |    iDEF1V      [V]   |
;; |  4-5  |       |    eMCPV       [V]   |
;; |  6-7  |       |    eDEF1V      [V]   |
;; |  8-9  |       |    iMCPI       [mA]  |
;; | 10-11 |       |    iDEF2V      [V]   |
;; | 12-13 |       |    eMCPI       [mA]  |
;; | 14-15 |       |    eDEF2V      [V]   |
;; | 16-17 |       |    iRAWV       [V]   |
;; | 18-19 |       |    iSPOILERV   [V]   |
;; | 20-21 |       |    eRAWV       [V]   |
;; | 22-23 |       |    eSpoilerV   [V]   |
;; | 24-25 |       |    iRAWI       [mA]  |
;; | 26-27 |       |    iHEMIV      [V]   |
;; | 28-29 |       |    eRAWI       [mA]  |
;; | 30-31 |       |    eHEMIV      [V]   |
;; | 32-33 |       |    iACCELV     [V]   |
;; | 34-35 |       |    EESA_P8V    [V]   |
;; | 36-37 |       |    EESA_P1P5V  [V]   |
;; | 38-39 |       |    EESA_P5VI   [mA]  |
;; | 40-41 |       |    iACCELI     [mA]  |
;; | 42-43 |       |    EESA_P5V    [V]   |
;; | 44-45 |       |    EESA_P1P5VI [mA]  |
;; | 46-47 |       |    EESA_N5VI   [mA]  |
;; | 48-49 |       |    iANALT      [C]   |
;; | 50-51 |       |    EESA_N5V    [V]   |
;; | 52-53 |       |    DIGITALT    [C]   |
;; | 54-55 |       |    EESA_P8VI   [mA]  |
;; | 56-57 |       |    eANALT      [C]   |
;; | 58-59 |       |    EESA_N8V    [V]   |
;; | 60-61 |       |    eANODET     [C]   |
;; | 62-63 |       |    EESA_N8VI   [mA]  |




FUNCTION esc_dhkp_boot_struct,ccsds_data

   str={$
       SW_FSWSTATE:       esc_data_select(ccsds_data,  80, 16), $
       SW_EVENTCTR:       esc_data_select(ccsds_data,  96, 32), $
       SW_LASTFSWEVENT:   esc_data_select(ccsds_data, 128, 32), $
       SW_CMDCOUNTER:long(esc_data_select(ccsds_data, 160 ,32)),$
       SW_CMDSTATUS_bits: esc_data_select(ccsds_data, 192, 16), $
       ;;(SW_GLOBALSTATUS): esc_data_select(ccsds_data,  192 ,  32) , $
       SW_GLOBAL:         esc_data_select(ccsds_data, 192, 16), $
       SW_FPGAVER:        esc_data_select(ccsds_data, 224,  8), $
       SW_STATUS:         esc_data_select(ccsds_data, 232,  8), $
       gap: 0b}
   return,str

end


FUNCTION esc_dhkp_oper_struct,ccsds_data

   IF n_elements(ccsds_data) EQ 0 THEN ccsds_data = bytarr(90)

   str = {$
         time:         !values.d_nan, $
         MET:          !values.d_nan,  $
         apid:         0u, $
         seqn:         0u,  $
         seqn_delta:   0u,  $
         seqn_group:   0b,  $
         pkt_size:     0ul,  $
         source_apid:  0u,  $
         source_hash:  0ul,  $
         compr_ratio:  0.,  $
         
         iMCPV:esc_data_select(ccsds_data, 80,8),$
         iDEF1V:     0,$
         eMCPV:      0,$
         eDEF1V:     0,$
         iMCPI:      0,$
         iDEF2V:     0,$
         eMCPI:      0,$
         eDEF2V:     0,$
         iRAWV:      0,$
         iSPOILERV:  0,$
         eRAWV:      0,$
         eSpoilerV:  0,$
         iRAWI:      0,$
         iHEMIV:     0,$
         eRAWI:      0,$
         eHEMIV:     0,$
         iACCELV:    0,$
         EESA_P8V:   0,$
         EESA_P1P5V: 0,$
         EESA_P5VI:  0,$
         iACCELI:    0,$
         EESA_P5V:   0,$
         EESA_P1P5VI:0,$
         EESA_N5VI:  0,$
         iANALT:     0,$
         EESA_N5V:   0,$
         DIGITALT:   0,$
         EESA_P8VI:  0,$
         eANALT:     0,$
         EESA_N8V:   0,$
         eANODET:    0,$
         EESA_N8VI:  0,$

         SW_PWR_CONFIG_bits:  esc_data_select(ccsds_data, 80  ,  8), $   
         SW_MISC_CONFIG_bits: esc_data_select(ccsds_data, 88  ,  8), $
         SW_EVENT_CTR:        esc_data_select(ccsds_data,   88  ,  4), $ 
         SW_SWEM_CONFIG_bits: esc_data_select(ccsds_data,   96  ,  8), $
         SW_LASTFSWEVENT2:    esc_data_select(ccsds_data,   96  ,  4), $  
         SW_SPANAICONFIG:     esc_data_select(ccsds_data,  112 ,  8), $
         SW_SPANAIMODE:       esc_data_select(ccsds_data,   112 ,  4), $
         SW_PRVSPANAIERR:     esc_data_select(ccsds_data,   116 ,  4), $
         SW_SPANAE_CONFIG:    esc_data_select(ccsds_data,  120 ,  8), $
         SW_SPANAEMODE:       esc_data_select(ccsds_data,     120 ,  4), $
         SW_PRVSPANAEERR: esc_data_select(ccsds_data,  124 ,  4), $
         SW_SPANBCONFIG: esc_data_select(ccsds_data,   128 ,  8), $
         SW_SPANBMODE: esc_data_select(ccsds_data,    128 ,  4), $
         SW_PRVSPANBERR: esc_data_select(ccsds_data,    132 ,  4), $
         SW_SPCCONFIG: esc_data_select(ccsds_data,   136 ,  8), $ ;()
         SW_SPCMODE: esc_data_select(ccsds_data,    136 ,  4), $
         SW_PRVSPCERR: esc_data_select(ccsds_data,    140 ,  4), $
         SW_FSWSTATE: esc_data_select(ccsds_data,  144 ,  8), $         ; 16bit in boot
         SW_EVENTCTR: esc_data_select(ccsds_data,  152 ,  32), $        ; 32 bit in boot
         SW_LASTFSWEVENT: esc_data_select(ccsds_data,  184 ,  16), $    ; 32 bit in boot
         SW_CMDCOUNTER: long(esc_data_select(ccsds_data,  200 ,  32)), $ ; 32 bit in boot
         SW_CMDSTATUS_bits: esc_data_select(ccsds_data,   232 ,  32), $  ; 16 bit in boot
         SW_GLOBALSTATUS_bits: esc_data_select(ccsds_data, 264 ,  32), $ ;()
         SW_GLOBAL: esc_data_select(ccsds_data,   264 ,  16), $
         SW_FPGAVER: esc_data_select(ccsds_data,    280 ,  8), $
         SW_STATUS: esc_data_select(ccsds_data,   288 ,  8), $
         SW_CDISTATUS_bits: esc_data_select(ccsds_data,   296 ,  32), $
         SW_SRVRDPTR: esc_data_select(ccsds_data,  328 ,  32), $
         SW_SRVWRPTR: esc_data_select(ccsds_data,  368 ,  32), $ ; line added on 2017- 12-10
         SW_ARCRDPTR: esc_data_select(ccsds_data,  392 ,  32), $
         SW_SSRWRADDR:   esc_data_select(ccsds_data,   424 ,  32), $
         SW_SSRRDADDR:  esc_data_select(ccsds_data,   456 ,  32), $
         SW_SPANAECTL: esc_data_select(ccsds_data,   488 ,  8), $
         SW_SPANBCTL: esc_data_select(ccsds_data,  496 ,  8), $
         SW_SPANAICTL: esc_data_select(ccsds_data,   504 ,  8), $
         SW_SPCCTL: esc_data_select(ccsds_data,  512 ,  8), $
         SW_SPANAHTRCTL: esc_data_select(ccsds_data,   520 ,  8), $
         SW_SPANBHTRCTL: esc_data_select(ccsds_data,   528 ,  8), $
         SW_SPANAECVRCTL: esc_data_select(ccsds_data,  536 ,  8), $
         SW_SPANBCVRCTL: esc_data_select(ccsds_data,   544 ,  8), $
         SW_SPANAICVRCTL: esc_data_select(ccsds_data,  552 ,  8), $
         SW_SPANAEATNCTL: esc_data_select(ccsds_data,  560 ,  8), $
         SW_SPANBATNCTL: esc_data_select(ccsds_data,   568 ,  8), $
         SW_SPANAIATNCTL: esc_data_select(ccsds_data,  576 ,  8), $
         SW_DCBOVERCUR: esc_data_select(ccsds_data,  584 ,  8), $
         SW_SEQSTATUSIDX: esc_data_select(ccsds_data,  592 ,  8), $
         SW_SEQSTATUS: esc_data_select(ccsds_data,  600 ,  16), $
         SW_MONSTATUS: esc_data_select(ccsds_data,  616 ,  8), $
         SW_PWRDOWNWARN: esc_data_select(ccsds_data,  624 ,  8), $
         SW_SSRBADBLKCNT:esc_data_select(ccsds_data,  632 ,  8), $
         SW_FSWVERSION: esc_data_select(ccsds_data, 640  ,  16),$
         SW_OSCPUUSAGE: esc_data_select(ccsds_data,  656  ,  8), $
         SW_OSERRCOUNT: esc_data_select(ccsds_data,  664  ,  16), $
         SW_b1_reserve: esc_data_select(ccsds_data,  680  ,  8), $
         SW_w1_reserve: esc_data_select(ccsds_data,  688  ,  16), $
         SW_w2_reserve: esc_data_select(ccsds_data,  704  ,  16), $
         gap:0B}
   return, str
END


FUNCTION esc_fram_apdat::decom, ccsds, source_dict=source_dict

   ;; Decommutate the CCSDS Packet
   ccsds_data = esc_ccsds_data(ccsds)

   ;; Boot packet
   if ccsds.pkt_size eq 30 then begin 

      ;; Decommutate Digiatl Housekeeping
      bootstr = esc_swem_dhkp_boot_struct(ccsds_data)

      ;; Get default structure format
      str2 = esc_swem_dhkp_oper_struct(!null) 

      ;; Fill DHKP into structure
      struct_assign, bootstr, str2,/nozero
      struct_assign, ccsds,   str2,/nozero

      ;; Debugging
      IF debug(6) THEN BEGIN
         dprint,'DHKP packet for boot mode ????',ccsds.pkt_size,dlevel=4   ,dwait = 10
         ;; hexprint,ccsds_data
      ENDIF
      
      return, str2

   ENDIF

   ;; dprint,ccsds.pkt_size

   ;; Pad it
   if ccsds.pkt_size lt 90 then ccsds_data = [ccsds_data,bytarr(90-ccsds.pkt_size)]

   ;; Most recent version  90 bytes long
   if ccsds.pkt_size ne 90 then begin 
      ;; dprint,'wrong size',dwait=20,dlevel=2,ccsds.pkt_size
      dprint,dlevel=2,"Unknown DHKP packet size:",ccsds.pkt_size,dwait=20
   ENDIF

   
   str2 = esc_swem_dhkp_oper_struct(ccsds_data)
   struct_assign,ccsds,str2,/nozero
   ;; printdat,str2,/hex

   return,str2

end


PRO esc_fram_apdat__define

   void = {esc_fram_apdat, $
           ;; Superclass
           inherits esc_gen_apdat, $ 
           flag: 0 $
          }
END





;;################# BACKUP ##############
   ;;IF n_params() EQ 0 then begin
   ;;   dprint,'Not working yet.'
   ;;   return,!null
   ;;endif

