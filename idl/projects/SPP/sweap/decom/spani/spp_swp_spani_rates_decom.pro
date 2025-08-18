
function spp_swp_spani_rates_decom,ccsds, ptp_header=ptp_header, apdat=apdat

  if n_params() eq 0 then begin
    dprint,'Not working yet.',dlevel=2
    return,!null
  endif

  ccsds_data = spp_swp_ccsds_data(ccsds)

  b = ccsds_data
  psize = 105+7
  if n_elements(b) ne psize then begin
     dprint,dlevel=1, 'Size error ',ccsds.pkt_size,ccsds.apid
     return,0
  endif  

  ;dprint,time_string(ccsds.time)
  sf0 = ccsds_data[11] and 3
  ;print,sf0
  time = ccsds.time
  ;hexprint,ccsds_data[0:29]
  ;rates = float( reform( float( ccsds_data[20:83] ) ,4,16))
  rates = float( reform( spp_sweap_log_decomp( ccsds_data[20:83] , 0 ) ,4,16))
  rates2 = float( reform( spp_sweap_log_decomp( ccsds_data[20+16*4:*] , 0 ) ))
  startbins = [0,0,3,3,6,6, 9, 9,12,12,15,17,19,21,23,25]
  stopbins =  [1,2,4,5,7,8,10,11,13,14,16,18,20,22,24,26]

  rates_str = { $
    time:               time, $
    met:                ccsds.met,  $
    seqn:               ccsds.seqn, $
    mode:               b[13] , $
    valid_cnts:         reform( rates[0,*]) , $
    multi_cnts:         reform( rates[1,*]), $
    start_nostop_cnts:  reform( rates[2,*] ), $
    stop_nostart_cnts:  reform( rates[3,*]) , $
    starts_cnts:        rates2[startbins] , $
    stops_cnts:         rates2[stopbins] , $
    gap:                0 }


;anode =0
  if n_elements(anode) ne 0 then begin
    dprint,dlevel=2,rates_str.starts_cnts[anode],rates_str.stops_cnts[anode],rates_str.valid_cnts[anode],rates_str.multi_cnts[anode]
    
  endif
  
  ;dprint,sf0
  ;printdat,ccsds,/hex
;  if sf0 and 1 then return,0    ; This gets rid of targeted packets

  return,rates_str

end

