;+
; $LastChangedBy: ali $
; $LastChangedDate: 2021-06-14 10:41:21 -0700 (Mon, 14 Jun 2021) $
; $LastChangedRevision: 30043 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_rates_apdat__define.pro $
;
; SPP_SWP_SPI_RATES_APDAT
;
; APID: 0x3BB
; Descritpion: SPAN-Ai Rates Package
; Size: 112 Bytes
;
;----------------------------------------------
; Byte  |   Bits   |        Data Value
;----------------------------------------------
;   0   | 00001aaa | ApID Upper Byte
;   1   | aaaaaaaa | ApID Lower Byte
;   2   | 11cccccc | Sequence Count Upper Byte
;   3   | cccccccc | Sequence Count Lower Byte
;   4   | LLLLLLLL | Message Length Upper Byte
;   5   | LLLLLLLL | Message Length Lower Byte
;   6   | MMMMMMMM | MET Byte 5
;   7   | MMMMMMMM | MET Byte 4
;   8   | MMMMMMMM | MET Byte 3
;   9   | MMMMMMMM | MET Byte 2
;  10   | ssssssss | MET Byte 1 [subseconds]
;  11   | ssssssss | s = MET subseconds
;       |          | x = Cycle Count LSBs
;       |          |     (sub NYS Indicator)
;  12   | LTCSNNNN | L = Log Compressed
;       |          | T = No Targeted Sweep
;       |          | C = Compress/Truncate TOF
;       |          | S = Summing
;       |          | N = 2^N Sum/Sample Period
;  13   | QQQQQQQQ | Spare
;  14   | mmmmmmmm | Mode ID Upper Byte
;  15   | mmmmmmmm | Mode ID Lower Byte
;  16   | FFFFFFFF | F0 Counter Upper Byte
;  17   | FFFFFFFF | F0 Counter Lower Byte
;  18   | AAtHDDDD | A = Attenuator State
;       |          | t = Test Pulser
;       |          | H = HV Enable
;       |          | D = HV Mode
;  19   | XXXXXXXX | X = Peak Count Step
;  20   | 000000fT | f = Full histogram
;       |          | T = Target Histogram
;  21   | NNNNCCCC | N = 2^N
;       |          | C = Channel
;  22   | XXXXXXXX | Maximum HV Step
;  23   | UUUUUUUU | Minimum HV Step
;
; 20 - 111
; --------
; Rates data in 19->8 bit compression where:
;
;    CH    - Channel
;    VAL   - Valid Events
;    NVAL  - Non Valid Events
;    STNSP - Start No Stop
;    SPNST - Stop  No Start
;    VE -
;    VE - Valid Events
;    ## - Anode
;
;           |   Byte3   |   Byte2   |   Byte1   |   Byte0   |
;  20 -  23 |  CH00VAL  |  CH00NVAL | CH00STNSP | CH00SPNST |
;  24 -  27 |  CH01VAL  |  CH01NVAL | CH01STNSP | CH01SPNST |
;  ...
;  80 -  83 |  CH15VAL  |  CH15NVAL | CH15STNSP | CH15SPNST |
;  84 -  87 |  CH00ST   |  CH00SP   | CH01SP    | CH02ST    |
;  88 -  91 |  CH02SP   |  CH03SP   | CH04ST    | CH04SP    |
;  92 -  95 |  CH05SP   |  CH06ST   | CH06SP    | CH07SP    |
;  96 -  99 |  CH08ST   |  CH08SP   | CH09SP    | CH10ST    |
; 100 - 103 |  CH10SP   |  CH11ST   | CH11SP    | CH12ST    |
; 104 - 107 |  CH12SP   |  CH13ST   | CH13SP    | CH14ST    |
; 108 - 111 |  CH14SP   |  CH15ST   | CH15SP    |    0      |
;
;-

function spp_swp_spi_rates_apdat::decom,ccsds ,source_dict=source_dict ;, ptp_header=ptp_header, apdat=apdat

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
  rates = float( reform( spp_swp_log_decomp( ccsds_data[20:83] , 0 ) ,4,16))
  rates2 = float( reform( spp_swp_log_decomp( ccsds_data[20+16*4:*] , 0 ) ))
  startbins = [0,0,3,3,6,6, 9, 9,12,12,15,17,19,21,23,25]
  stopbins =  [1,2,4,5,7,8,10,11,13,14,16,18,20,22,24,26]

  rates_str = { $
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
    mode:               b[13] , $
    valid_cnts:         reform( rates[0,*]) , $
    multi_cnts:         reform( rates[1,*]), $
    start_nostop_cnts:  reform( rates[2,*] ), $
    stop_nostart_cnts:  reform( rates[3,*]) , $
    starts_cnts:        rates2[startbins] , $
    stops_cnts:         rates2[stopbins] , $
    gap:          ccsds.gap}

  ;anode =0
  if n_elements(anode) ne 0 then begin
    dprint,dlevel=2,rates_str.starts_cnts[anode],rates_str.stops_cnts[anode],rates_str.valid_cnts[anode],rates_str.multi_cnts[anode]

  endif

  ;dprint,sf0
  ;printdat,ccsds,/hex
  ;  if sf0 and 1 then return,0    ; This gets rid of targeted packets

  return,rates_str

end


PRO spp_swp_spi_rates_apdat__define
  void = {spp_swp_spi_rates_apdat, $
    inherits spp_gen_apdat, $    ; superclass
    ;   temp1 : 0u, $
    ;   buffer: ptr_new(),   $
    flag: 0 $
  }
END
