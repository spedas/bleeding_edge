; $LastChangedBy: davin-mac $
; $LastChangedDate: 2023-12-02 00:05:21 -0800 (Sat, 02 Dec 2023) $
; $LastChangedRevision: 32261 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/swx/swx_swem_timing_apdat__define.pro $

function swx_swem_timing_oper_decom,ccsds_data

  sz = n_elements(ccsds_data)
  if sz eq 0 then ccsds_data=!null
  if sz lt 66 then padding = bytarr(66-sz) else padding = !null
  buff = [ccsds_data,padding]
  valid = keyword_set(ccsds_data) ne 0
  str={ $
    time:         !values.d_nan, $
    ;MET:          !values.d_nan,  $
    apid:         0u, $
    seqn:         0u,  $
    seqn_delta:   0u,  $
    seqn_group:   0b,  $
    pkt_size:     0ul,  $
    source_apid:  0u,  $
    source_hash:  0ul,  $
    compr_ratio:  0.,  $
    met:       spp_swp_data_select(buff,48,32) , $
    SW_SAMPLECLKPER  :    spp_swp_data_select(buff, 80  ,  16), $   ;  AKA  F0
    SW_SCPPSMETTIME   :   spp_swp_data_select(buff, 96  ,  32), $
    SW_SAMPLEMETSUBSECS : spp_swp_data_select(buff, 128 ,  32), $  ; not needed
    SW_SAMPLEMETSECS   :  spp_swp_data_select(buff,  160 ,  32), $ ; not needed
    ;  (SW_tim_FIELDS)   : spp_swp_data_select(buff, 192 ,  32), $
    SW_FIELDSCLKCYCLES  : spp_swp_data_select(buff,   192 ,  31), $
    SW_FIELDS_CLK_ACT   :   spp_swp_data_select(buff,  223 ,  1), $
    SW_FIELDSF1F2   :     spp_swp_data_select(buff, 224 ,  32), $  ; not needed
    SW_FIELDSF3   :       spp_swp_data_select(buff, 256 ,  16), $  ; not needed
    SW_FIELDSMETSECS   :  spp_swp_data_select(buff,  272 ,  32), $   ; not needed
    SW_FIELDSMETSUBSECS : spp_swp_data_select(buff, 304 ,  16), $  ; not needed
    SW_METJITTER    :     spp_swp_data_select(buff, 320 ,  32), $
    SW_SCTIMESECS   :     spp_swp_data_select(buff, 352 ,  32), $  ; not needed
    SW_SCTIMESUBSECS   :  spp_swp_data_select(buff,  384 ,  16), $  ; not needed
    SW_FIELDSF0   :       spp_swp_data_select(buff, 400 ,  32), $
    SW_SCSUBSECSATPPS   : spp_swp_data_select(buff, 432 ,  32), $
    SW_FIELDSSMPLTIMERR : spp_swp_data_select(buff, 464 ,  32), $
    SW_TICKSBTWN1PPS    : spp_swp_data_select(buff, 496 ,  32), $
    ;  SW_tim_reserve :          spp_swp_data_select(buff, 528 ,  32), $
    fields_met:   spp_swp_data_select(buff,272,48)   / 2d^16, $
    sc_met:      spp_swp_data_select(buff,352,48)   / 2d^16, $
    fields_F123: spp_swp_data_select(buff,224,48)   / 2d^16, $
    sample_met:  spp_swp_data_select(buff,160,32)  + spp_swp_data_select(buff, 128+16 ,  16) / 2d^16 , $
    valid:valid , $
    gap:0b }

  return, str
end

;sample_clk_per = spp_swp_data_select(ccsds_data,80,16)
;scpps_met_time = spp_swp_data_select(ccsds_data,96,32)
;sample_MET_subsec=  spp_swp_data_select(ccsds_data,128,32)
;fields_subsec=      spp_swp_data_select(ccsds_data,256,16)
;fields_MET_subsec=  spp_swp_data_select(ccsds_data,304,16)
;sc_time_subsec  =  spp_swp_data_select(ccsds_data,384,16)
;MET_jitter=       spp_swp_data_select(ccsds_data,320,32)
;sample_MET = spp_swp_data_select(ccsds_data,160,32) + sample_MET_subsec/ 2d^16
;fields_f123 = spp_swp_data_select(ccsds_data,224,32) +fields_subsec / 2d^16
;fields_met  = spp_swp_data_select(ccsds_data,272,32) +fields_MET_subsec / 2d^16
;sc_time     = spp_swp_data_select(ccsds_data,352,32) +sc_time_subsec / 2d^16
;fields_f0 = spp_swp_data_select(ccsds_data,400,32)
;scsubsecsatpps =  spp_swp_data_select(ccsds_data,432,32)
;fields_smpl_timerr = spp_swp_data_select(ccsds_data,464,32)
;clks_per_pps = spp_swp_data_select(ccsds_data,496,32)
;fields_clk_cycles = spp_swp_data_select(ccsds_data,192,32)
;fields_clk_transition=  fields_clk_cycles and 1
;fields_clk_cycles = ishft( fields_clk_cycles,-1)
;


function swx_swem_timing_apdat::decom ,ccsds,  source_dict=source_dict  ;,header,ptp_header=ptp_header   ;,apdat=apdat

  if n_params() eq 0 then begin
    dprint,'Not working yet.'
    return,!null
  endif

  ccsds_data = swx_ccsds_data(ccsds)

  str = swx_swem_timing_oper_decom(ccsds_data)
  struct_assign,ccsds,str,/nozero

  if ccsds.pkt_size eq 56 then begin
    dprint,'boot mode',dlevel=4,dwait=30

    if 0 then begin   ; old code - maybe from boot mode
      values = swap_endian(ulong(ccsds_data,10,11) )
      values2 = uintarr(4) ;  swap_endian(ulong(ccsds_data,448/8,4) )
      sc_time_subsecs =  (swap_endian(uint(ccsds_data,432/8,1) ,/swap_if_little_endian ))[0]

      sample_MET_subsec=   values[2]
      fields_clk_transition=  values[4] and 1
      fields_subsec=          values[6]
      fields_MET_subsec=  values[8]
      sc_time_subsec  = 0u    ;  not sure what it was
      MET_jitter=       values[9]

      sample_clk_per = uint( values[0] )
      scpps_met_time = values[1]
      sample_MET = values[3] + values[2]/ 2d^16
      fields_f123 = values[5] + values[6] / 2d^16
      fields_met = values[7] + values[8] / 2d^16
      sc_time = values[10] + sc_time_subsecs / 2d^16
      fields_f0 =   values2[0]
      scsubsecsatpps =   values2[1]
      fields_smpl_timerr = values2[2]
      clks_per_pps = values2[3]
      fields_clk_cycles =  ishft(values[4],-1)
      ;  return,str
    endif
  endif

  if ccsds.pkt_size gt 66 then dprint,'Op debug mode',dlevel=3, ccsds.pkt_size, dwait=30

  if 0 then begin
    sample_clk_per = spp_swp_data_select(ccsds_data,80,16)
    scpps_met_time = spp_swp_data_select(ccsds_data,96,32)
    sample_MET_subsec=  spp_swp_data_select(ccsds_data,128,32)
    fields_subsec=      spp_swp_data_select(ccsds_data,256,16)
    fields_MET_subsec=  spp_swp_data_select(ccsds_data,304,16)
    sc_time_subsec  =  spp_swp_data_select(ccsds_data,384,16)
    MET_jitter=       spp_swp_data_select(ccsds_data,320,32)
    sample_MET = spp_swp_data_select(ccsds_data,160,32) + sample_MET_subsec/ 2d^16
    fields_f123 = spp_swp_data_select(ccsds_data,224,32) +fields_subsec / 2d^16
    fields_met  = spp_swp_data_select(ccsds_data,272,32) +fields_MET_subsec / 2d^16
    sc_time     = spp_swp_data_select(ccsds_data,352,32) +sc_time_subsec / 2d^16
    fields_f0 = spp_swp_data_select(ccsds_data,400,32)
    scsubsecsatpps =  spp_swp_data_select(ccsds_data,432,32)
    fields_smpl_timerr = spp_swp_data_select(ccsds_data,464,32)
    clks_per_pps = spp_swp_data_select(ccsds_data,496,32)
    fields_clk_cycles = spp_swp_data_select(ccsds_data,192,32)
    fields_clk_transition=  fields_clk_cycles and 1
    fields_clk_cycles = ishft( fields_clk_cycles,-1)
  endif

  if 1 then begin

    last_str = *self.last_time_str_p
    if ~keyword_set(last_str) || str.gap then last_str = fill_nan(str)


    ;cludge to force the fields quantities to be nearly the same
    ;delvar,fields_dt

    ; if n_elements(fields_dt) eq 0 then fields_dt = floor(str.fields_met - str.fields_f123)
    ; fields_f123 += fields_dt

    ttt = str.sample_met
    ;ttt = fields_met
    ;  dprint
    ;  printdat,str

    time_delta = str.time - last_str.time
    met_delta = str.met - last_str.met
    sample_clk_per = str.sw_sampleclkper
    sample_clk_per_delta =     str.sw_sampleclkper - last_str.sw_sampleclkper
    sample_met_delta  =  (str.sample_met - last_str.sample_met)     ; / sample_clk_per_delta

    time_drift = (str.sample_MET - str.sw_sampleclkper * (2d^24 / 19.2d6) ) mod 1
    ;time_drift_delta = (str.sample_MET - last_str.sample_MET) - sample_clk_per_delta * (2d^24/19.2d6)
    time_drift_delta = (sample_met_delta - sample_clk_per_delta * (2d^24/19.2d6)) / (str.met - last_str.met)


    df0 = uint( str.sw_sampleclkper - last_str.sw_sampleclkper)

    fields_clk_cycles_delta = long( fix( str.SW_FIELDSCLKCYCLES - last_str.SW_FIELDSCLKCYCLES ) )
    fields_clk_cycles_delta =  str.SW_FIELDSCLKCYCLES - last_str.SW_FIELDSCLKCYCLES

    ;fields_clk_cycles_delta =  fields_clk_cycles_delta / df0

    seqn_delta = ccsds.seqn_delta
    if 1 then begin
      k = 2ul^25
      clks_per_pps_delta =     ( str.SW_TICKSBTWN1PPS - last_str.SW_TICKSBTWN1PPS  )   and (k-1)    ; account for 25 bit counter
      clks_per_pps_delta = double( clks_per_pps_delta + k *floor(met_delta * 19.2d6/k) ) / met_delta
    endif else begin
      overflow =  (str.SW_TICKSBTWN1PPS lt last_str.SW_TICKSBTWN1PPS) * 2UL^25                 ; account for 25 bit counter
      clks_per_pps_delta =  (overflow + str.SW_TICKSBTWN1PPS - last_str.SW_TICKSBTWN1PPS  )
    endelse

    if keyword_set(ptp_header) then ptp_time = ptp_header.ptp_time else ptp_time = !values.d_nan

    str2 = {    $
      time:         ccsds.time, $
      MET:          ccsds.met,  $
      apid:         ccsds.apid, $
      seqn:         ccsds.seqn,  $
      seqn_delta:   ccsds.seqn_delta,  $
      seqn_group:   ccsds.seqn_group,  $
      pkt_size:     ccsds.pkt_size,  $
      source_apid:  ccsds.source_apid,  $
      source_hash:  ccsds.source_hash,  $
      compr_ratio:  ccsds.compr_ratio,  $
      time_delta:  time_delta / ccsds.seqn_delta   ,$
      ptp_delay_time:  ptp_time - str.time, $
      sample_clk_per  : sample_clk_per,  $ ; AKA: F0
      sample_clk_per_delta:      sample_clk_per_delta  , $
      ;  scpps_met_time:   str.scpps_met_time ,$
      scpps_met_time_delta:  str.sw_scppsmettime - last_str.sw_scppsmettime, $
      ;    MET_TIME_DIFF:   scpps_met_time - ccsds.met, $
      ;    sample_MET_subsec:  sample_MET_subsec ,$
      ;    fields_clk_cycles:  fields_clk_cycles,$
      fields_clk_cycles_delta:  fields_clk_cycles_delta,$
      ;    fields_clk_transition:  fields_clk_transition ,$
      ;    fields_subsec:         fields_subsec ,$                                  ; err
      ;    fields_MET_subsec:  fields_MET_subsec ,$                                  ; err
      ;    MET_jitter:      str.sw_METjitter ,$
      sc_time_subSECs:    str.sw_sctimesubSECs, $
      ;    sample_MET:        str.sample_MET ,$
      ;    fields_F123:      str.fields_f123 ,$
      ;    fields_MET:       str.fields_met ,$
      ;    sc_time :         str.sc_time, $
      fields_f123_delta:    (str.fields_F123 - last_str.fields_F123) / seqn_delta , $
      fields_met_delta:     (str.fields_met - last_str.fields_met) / seqn_delta , $
      sample_met_delta:     sample_met_delta,  $
      sc_met_delta:        (str.sc_met - last_str.sc_met) / seqn_delta , $
      sample_MET_diff:       str.sample_MET - ttt, $
      ;    fields_F123_diff:      str.fields_f123 -ttt ,$
      ;    fields_MET_diff:       str.fields_met  -ttt ,$
      sc_met_diff :         str.sc_met    - ttt, $
      drift:     time_drift, $
      drift_DELTA:  time_drift_delta , $
      ;    drift_delta:  (time_drift -last_str.drift) / ccsds.seqn_delta , $
      ;    clks_per_pps:  clks_per_pps, $                                                ; err
      ticks_btwn_1pps:  str.SW_TICKSBTWN1PPS, $
      clks_per_pps_delta:  clks_per_pps_delta- 19200000L , $  ;
      ;    scsubsecsatpps:scsubsecsatpps,$                                         ; err
      ;   fields_smpl_timerr :fields_smpl_timerr,$                                         ; err
      gap:  str.gap }

    *self.last_time_str_p = str

    if debug(self.dlevel+3,msg='SWEM Timing') then begin
      printdat,str2
      ;dprint,dlevel=2,'generic:',ccsds.apid,ccsds.pkt_size+7, n_elements(ccsds_data)
      ;hexprint,ccsds_data
    endif
    dprint,dlevel=5,'End of time packet decom'

  endif

  *self.last_data_p = str

  return,str2

end

;; tplot,'spp_spani_hkp_DTIME APID spp_swem_timing_FIELDS_CLK_CYCLES_DELTA spp_swem_timing_CLKS_PER_PPS_DELTA spp_swem_timing_DRIFT spp_spani_hkp_ALL_TEM

function swx_swem_timing_apdat::init,apid,name,_extra=ex
  valid = self->swx_gen_apdat::Init(apid,name,EXTRA=ex)
  self.last_time_str_p = ptr_new(!null)
  self.data2 = obj_new('dynamicarray')
  return,valid
end


pro  swx_swem_timing_apdat__define
  void = {swx_swem_timing_apdat, $
    inherits swx_gen_apdat, $
    data2: obj_new(), $
    last_time_str_p: ptr_new(), $
    flag: 0 $
  }
end
