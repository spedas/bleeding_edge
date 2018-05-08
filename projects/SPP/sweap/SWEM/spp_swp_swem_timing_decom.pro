pro spp_timing_temp

get_data,'spp_swem_timing_FIELDS_CLK_CYCLES',data=d
clk = d.y
dc = long(clk)-long(shift(clk,1))
dc[0]=dc[1]
over = dc lt 0
dc += over * 2L^25
store_data,'foo2',data={x:d.x,y:dc}

end



function spp_swp_swem_timing_decom,ccsds,ptp_header=ptp_header,apdat=apdat

common spp_swp_swem_timing_decom_com2,  last_str,  fields_dt

if n_params() eq 0 then begin
  dprint,'Not working yet.'
  return,!null
endif


ccsds_data = spp_swp_ccsds_data(ccsds)

;printdat,ccsds.pkt_size

if ccsds.pkt_size eq 56 then begin
  dprint,'boot mode ignored',dlevel=4,dwait=30
  return,0
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
;  return,0
  
endif else if ccsds.pkt_size ge 66 then begin
  if ccsds.pkt_size gt 66 then dprint,'Op debug mode',dlevel=3, ccsds.pkt_size, dwait=30
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
endif else begin
  if debug(3) then begin
    dprint,'Timing packet error',ccsds.pkt_size,dlevel=2
    hexprint,ccsds_data
  endif
  return,0
endelse


;
;printdat,ptp_header


;last_str = 0

nan= !values.d_nan
if ~keyword_set(last_str) then last_str = {sample_clk_per:sample_clk_per-1, scpps_met_time:scpps_met_time-1, sample_met: nan, sc_time:nan,  $
     fields_f123:nan, fields_met:nan, drift:nan, fields_clk_cycles:0ul,clks_per_pps:0ul}

;cludge to force the fields quantities to be nearly the same
;delvar,fields_dt
if n_elements(fields_dt) eq 0 then fields_dt = floor(fields_met - fields_f123)
fields_f123 += fields_dt 

ttt = sample_met
;ttt = fields_met
  
sample_clk_per_delta =    double( uint( ( sample_clk_per - last_str.sample_clk_per) ) )
 
time_drift = (sample_MET - sample_clk_per * (2d^24 / 19.2d6) ) mod 1


df0 = uint( sample_clk_per - last_str.sample_clk_per)

fields_clk_cycles_delta = long( fix( fields_clk_cycles - last_str.fields_clk_cycles ) ) 

;fields_clk_cycles_delta =  fields_clk_cycles_delta / df0


;if debug(5) then begin
;  ;dprint,str.fields_clk_cycles_delta
;  hexprint,[fields_clk_cycles,fields_clk_cycles_delta,ulong(sample_clk_per_delta)]
;endif



dseq = ccsds.seqn_delta
k = 2ul^25

clks_per_pps_delta =     ( clks_per_pps - last_str.clks_per_pps  ) and (k-1)
clks_per_pps_delta = ( clks_per_pps_delta + k *floor(dseq * 19.2d6/k) ) / dseq


if debug(5) then begin
  hexprint,[clks_per_pps,clks_per_pps_delta]
;  dprint,clks_per_pps,clks_per_pps_delta
endif
;dprint,ptp_header.ptp_time - floor(ptp_header.ptp_time)
 
str = {time:   ccsds.time  ,$
       time_delta:  ccsds.time_delta / ccsds.seqn_delta   ,$
       ptp_delay_time:  ptp_header.ptp_time - ccsds.time, $
       seqn : ccsds.seqn, $
       seqn_delta:  ccsds.seqn_delta < 15u , $
       sample_clk_per: sample_clk_per  , $                                     ; err
     scpps_met_time:    scpps_met_time ,$
     scpps_met_time_delta:  scpps_met_time - last_str.scpps_met_time, $
     MET_TIME_DIFF:   scpps_met_time - ccsds.met, $
     sample_MET_subsec:  sample_MET_subsec ,$
     fields_clk_cycles:  fields_clk_cycles,$
       fields_clk_cycles_delta:  fields_clk_cycles_delta,$
     fields_clk_transition:  fields_clk_transition ,$
     fields_subsec:         fields_subsec ,$                                  ; err
     fields_MET_subsec:  fields_MET_subsec ,$                                  ; err
     MET_jitter:      MET_jitter ,$
     sc_time_subSEC: sc_time_subSEC, $
     sample_MET:        sample_MET ,$
     fields_F123:      fields_f123 ,$
     fields_MET:       fields_met ,$
     sc_time :         sc_time, $
     sample_clk_per_delta:      sample_clk_per_delta  , $
     fields_f123_delta:    (fields_F123 - last_str.fields_F123) / ccsds.seqn_delta , $
     fields_met_delta:     (fields_met - last_str.fields_met) / ccsds.seqn_delta , $
     sample_met_delta:     (sample_met - last_str.sample_met) / sample_clk_per_delta , $
     sc_time_delta:        (sc_time - last_str.sc_time) / ccsds.seqn_delta , $
     sample_MET_diff:       sample_MET - ttt, $
     fields_F123_diff:      fields_f123 -ttt ,$
     fields_MET_diff:       fields_met  -ttt ,$
     sc_time_diff :         sc_time    - ttt, $
     drift:     time_drift, $
     drift_delta:  (time_drift -last_str.drift) / ccsds.seqn_delta , $
     clks_per_pps:  clks_per_pps, $                                                ; err
     clks_per_pps_delta:  long(clks_per_pps_delta - 19200000L), $
     scsubsecsatpps:scsubsecsatpps,$                                         ; err
     fields_smpl_timerr :fields_smpl_timerr,$                                         ; err
     gap:  ccsds.gap }
       
;tploprintdat,str

  if debug(apdat.dlevel+3,msg='SWEM Timing') then begin
     dprint,dlevel=2,'generic:',ccsds.apid,ccsds.pkt_size+7, n_elements(ccsds_data)
     hexprint,ccsds_data
  endif

  last_str = str

  return,str

end

;; tplot,'spp_spani_hkp_DTIME APID spp_swem_timing_FIELDS_CLK_CYCLES_DELTA spp_swem_timing_CLKS_PER_PPS_DELTA spp_swem_timing_DRIFT spp_spani_hkp_ALL_TEM


