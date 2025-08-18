;$LastChangedBy: davin-mac $
;$LastChangedDate: 2023-12-02 00:05:21 -0800 (Sat, 02 Dec 2023) $
;$LastChangedRevision: 32261 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/swx/swx_swem_dhkp_apdat__define.pro $

function swx_swem_dhkp_boot_struct,ccsds_data
  str={$
    SW_FSWSTATE: spp_swp_data_select(ccsds_data,  80  ,  16) , $
    SW_EVENTCTR: spp_swp_data_select(ccsds_data,  96  ,  32) , $
    SW_LASTFSWEVENT: spp_swp_data_select(ccsds_data,  128 ,  32) , $
    SW_CMDCOUNTER: long( spp_swp_data_select(ccsds_data,  160 ,  32) ), $
    SW_CMDSTATUS_bits: spp_swp_data_select(ccsds_data,   192 ,  16) , $
    ;(SW_GLOBALSTATUS): spp_swp_data_select(ccsds_data,  192 ,  32) , $
    SW_GLOBAL: spp_swp_data_select(ccsds_data,   192 ,  16) , $
    SW_FPGAVER: spp_swp_data_select(ccsds_data,    224,   8) , $
    SW_STATUS: spp_swp_data_select(ccsds_data,   232,   8) , $
    gap: 0b}
  return,str
end


function swx_swem_dhkp_oper_struct,ccsds_data
  if n_elements(ccsds_data) eq 0 then ccsds_data = bytarr(90)
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
    SW_PWR_CONFIG_bits: spp_swp_data_select(ccsds_data, 80  ,  8), $   ;   SW_PWRSPARE, SW_ACTPWR ,  SW_SPANBHTR, SW_SPANAHTR  , SW_SPANBPWR ,   SW_SPANAEPWR  , SW_SPANAIPWR ,  SW_SPCPWR   87  UB  1
    SW_MISC_CONFIG_bits: spp_swp_data_select(ccsds_data, 88  ,  8), $
    SW_EVENT_CTR: spp_swp_data_select(ccsds_data,   88  ,  4), $       ;  SW_FLPLBPROG ,  SW_FIELDSCLK  ,SW_LINK_A_ACTIVE  ,SW_LINK_B_ACTIVE    95  UB  1
    SW_SWEM_CONFIG_bits: spp_swp_data_select(ccsds_data,   96  ,  8), $
    SW_LASTFSWEVENT2: spp_swp_data_select(ccsds_data,   96  ,  4), $  ;  SW_FSWSPARE ,  SW_FSWCSCI  ,  SW_BOOTMODE ,  SW_WDRSTDET  ,  SW_SWEM3P3V 1 104 UB  8
    SW_SPANAICONFIG: spp_swp_data_select(ccsds_data,  112 ,  8), $
    SW_SPANAIMODE: spp_swp_data_select(ccsds_data,   112 ,  4), $
    SW_PRVSPANAIERR: spp_swp_data_select(ccsds_data,   116 ,  4), $
    SW_SPANAE_CONFIG: spp_swp_data_select(ccsds_data,  120 ,  8), $
    SW_SPANAEMODE: spp_swp_data_select(ccsds_data,     120 ,  4), $
    SW_PRVSPANAEERR: spp_swp_data_select(ccsds_data,  124 ,  4), $
    SW_SPANBCONFIG: spp_swp_data_select(ccsds_data,   128 ,  8), $
    SW_SPANBMODE: spp_swp_data_select(ccsds_data,    128 ,  4), $
    SW_PRVSPANBERR: spp_swp_data_select(ccsds_data,    132 ,  4), $
    SW_SPCCONFIG: spp_swp_data_select(ccsds_data,   136 ,  8), $     ;()
    SW_SPCMODE: spp_swp_data_select(ccsds_data,    136 ,  4), $
    SW_PRVSPCERR: spp_swp_data_select(ccsds_data,    140 ,  4), $
    SW_FSWSTATE: spp_swp_data_select(ccsds_data,  144 ,  8), $              ; 16bit in boot
    SW_EVENTCTR: spp_swp_data_select(ccsds_data,  152 ,  32), $             ; 32 bit in boot
    SW_LASTFSWEVENT: spp_swp_data_select(ccsds_data,  184 ,  16), $         ; 32 bit in boot
    SW_CMDCOUNTER: long(spp_swp_data_select(ccsds_data,  200 ,  32)), $     ; 32 bit in boot
    SW_CMDSTATUS_bits: spp_swp_data_select(ccsds_data,   232 ,  32), $           ; 16 bit in boot
    SW_GLOBALSTATUS_bits: spp_swp_data_select(ccsds_data, 264 ,  32), $    ;()
    SW_GLOBAL: spp_swp_data_select(ccsds_data,   264 ,  16), $
    SW_FPGAVER: spp_swp_data_select(ccsds_data,    280 ,  8), $
    SW_STATUS: spp_swp_data_select(ccsds_data,   288 ,  8), $
    SW_CDISTATUS_bits: spp_swp_data_select(ccsds_data,   296 ,  32), $
    SW_SRVRDPTR: spp_swp_data_select(ccsds_data,  328 ,  32), $
    SW_SRVWRPTR: spp_swp_data_select(ccsds_data,  368 ,  32), $    ; line added on 2017- 12-10
    SW_ARCRDPTR: spp_swp_data_select(ccsds_data,  392 ,  32), $
    SW_SSRWRADDR:   spp_swp_data_select(ccsds_data,   424 ,  32), $
    SW_SSRRDADDR:  spp_swp_data_select(ccsds_data,   456 ,  32), $
    SW_SPANAECTL: spp_swp_data_select(ccsds_data,   488 ,  8), $
    SW_SPANBCTL: spp_swp_data_select(ccsds_data,  496 ,  8), $
    SW_SPANAICTL: spp_swp_data_select(ccsds_data,   504 ,  8), $
    SW_SPCCTL: spp_swp_data_select(ccsds_data,  512 ,  8), $
    SW_SPANAHTRCTL: spp_swp_data_select(ccsds_data,   520 ,  8), $
    SW_SPANBHTRCTL: spp_swp_data_select(ccsds_data,   528 ,  8), $
    SW_SPANAECVRCTL: spp_swp_data_select(ccsds_data,  536 ,  8), $
    SW_SPANBCVRCTL: spp_swp_data_select(ccsds_data,   544 ,  8), $
    SW_SPANAICVRCTL: spp_swp_data_select(ccsds_data,  552 ,  8), $
    SW_SPANAEATNCTL: spp_swp_data_select(ccsds_data,  560 ,  8), $
    SW_SPANBATNCTL: spp_swp_data_select(ccsds_data,   568 ,  8), $
    SW_SPANAIATNCTL: spp_swp_data_select(ccsds_data,  576 ,  8), $
    SW_DCBOVERCUR: spp_swp_data_select(ccsds_data,  584 ,  8), $
    SW_SEQSTATUSIDX: spp_swp_data_select(ccsds_data,  592 ,  8), $
    SW_SEQSTATUS: spp_swp_data_select(ccsds_data,  600 ,  16), $
    SW_MONSTATUS: spp_swp_data_select(ccsds_data,  616 ,  8), $
    SW_PWRDOWNWARN: spp_swp_data_select(ccsds_data,  624 ,  8), $
    SW_SSRBADBLKCNT:spp_swp_data_select(ccsds_data,  632 ,  8), $
    SW_FSWVERSION: spp_swp_data_select(ccsds_data, 640  ,  16),$
    SW_OSCPUUSAGE: spp_swp_data_select(ccsds_data,  656  ,  8), $
    SW_OSERRCOUNT: spp_swp_data_select(ccsds_data,  664  ,  16), $
    SW_b1_reserve: spp_swp_data_select(ccsds_data,  680  ,  8), $
    SW_w1_reserve: spp_swp_data_select(ccsds_data,  688  ,  16), $
    SW_w2_reserve: spp_swp_data_select(ccsds_data,  704  ,  16), $
    gap:0B}
  return, str
end


function swx_swem_dhkp_apdat::decom,ccsds, source_dict=source_dict   ;,ptp_header=ptp_header

  if n_params() eq 0 then begin
    dprint,'Not working yet.'
    return,!null
  endif

  ccsds_data = swx_ccsds_data(ccsds)

  if ccsds.pkt_size eq 30 then begin    ;  boot packet
    bootstr = swx_swem_dhkp_boot_struct(ccsds_data)
    str2 = swx_swem_dhkp_oper_struct(!null)    ; get default structure format

    struct_assign,bootstr,str2,/nozero
    struct_assign,ccsds,str2,/nozero
    if debug(6) then begin
      dprint,'DHKP packet for boot mode ????',ccsds.pkt_size,dlevel=4   ,dwait = 10
      ;    hexprint,ccsds_data
    endif
    return, str2
  endif

  ;dprint,ccsds.pkt_size
  if ccsds.pkt_size lt 90 then ccsds_data = [ccsds_data,bytarr(90-ccsds.pkt_size)]  ; pad it

  if ccsds.pkt_size ne 90 then begin   ; Most recent version  90 bytes long
    ;  dprint,'wrong size',dwait=20,dlevel=2,ccsds.pkt_size
    dprint,dlevel=2,"Unknown DHKP packet size:",ccsds.pkt_size,dwait=20
  endif
  str2 = swx_swem_dhkp_oper_struct(ccsds_data)
  struct_assign,ccsds,str2,/nozero
  ;printdat,str2,/hex

  return,str2

end


PRO swx_swem_dhkp_apdat__define

  void = {swx_swem_dhkp_apdat, $
    inherits swx_gen_apdat, $    ; superclass
    flag: 0 $
  }
END





