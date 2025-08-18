;+
; spp_swp_span_prod
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2025-06-12 05:00:47 -0700 (Thu, 12 Jun 2025) $
; $LastChangedRevision: 33381 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/common/spp_swp_span_prod__define.pro $
;-
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
;  12   | LTCSNNNN | L = Log Compressed LTCSNNNN_bits
;       |          | T = No Targeted Sweep
;       |          | C = Compress/Truncate TOF
;       |          | S = Summing or smp_flag (S = 0 Sampling, S = 1 Summing)
;       |          | N = 2^N Sum/Sample Period: the number of accumulation periods (1/4 NYS)
;  13   | QQQQQQQQ | arch_bits :same format as LTCSNNNN_bits, but copied from archive to survey products. all bits are 0 for archive products.
;  14   | mmmmmmmm | Mode2 Upper Byte| ions:      MMPP PPEE EEEE TTTT: M - Mass, P - Product, E - Energy, T - Time
;  15   | mmmmmmmm | Mode2 Lower Byte| electrons: EEEE EEEE PPPP PPPP
;  16   | FFFFFFFF | F0 Counter Upper Byte
;  17   | FFFFFFFF | F0 Counter Lower Byte
;  18   | AAtHDDDD | status_bits
;       |          | A = Attenuator State: 0:undefined, 1:atten_out, 2: atten_in, 3: undefined
;       |          | t = Test Pulser
;       |          | H = HV Enable
;       |          | D = HV Mode ;spoiler test: 2nd bit set
;  19   | XXXXXXXX | peak_bin
;
; 20 - Science Product Data
;

pro spp_swp_span_prod__define ,productstr, ccsds

  productstr = !null

  if not keyword_set(ccsds) then begin
    dummybuf = byte([11, 68, 192, 190, 0, 13, 16, 120, 39, 204, 16, 120, 39, 203, 2, 20, 0, 0, 0, 1])
    ccsds = spp_swp_ccsds_decom(dummybuf)
  endif

  pksize = ccsds.pkt_size
  ;ccsds_data = spp_swp_ccsds_data(ccsds)
  ccsds_data = *ccsds.pdata

  if pksize ne n_elements(ccsds_data) then begin
    dprint,dlevel=1,'Product size mismatch'
    return
  endif

  apid = byte(ccsds.apid)
  ;  detnum = (ishft(apid,-4) and 'F'x) < 8
  ;  detectors = ['?','?','?','?','SWEM','SPC','SPA','SPB','SPI']
  ;  detname = detectors[detnum]
  product_bits=0b
  if (apid and 'E0'x) eq '60'x then begin ;span - electron packets
    product_bits or= ishft( ((apid and 'ff'xb) - '60'xb ) and '6'xb , 3)
    product_bits or= ishft( (apid and '10'xb) , 2) ;set detector num (spa or spb)
    product_bits or= ishft( (apid and '1'xb)  , 2) ;set product number
  endif

  if (apid and '80'x) ne 0  then begin   ;  span - ion packets
    tmp = (apid and 'ff'xb) -'80'xb
    product_bits or= ishft(  tmp / 12b, 4 )
    product_bits or= tmp mod 12b
    product_bits or= '80'xb
  endif

  ion      = (product_bits and '80'xb ) ne 0
  det      = (product_bits and '40'xb ) ne 0
  survey   = (product_bits and '20'xb ) ne 0
  targeted = (product_bits and '10'xb ) ne 0
  prodnum  =  product_bits and '0f'xb

  header = ccsds_data[0:19]
  LTCSNNNN_bits = header[12]
  arch_bits = header[13]
  mode2 = (swap_endian(uint(header,14),/swap_if_little_endian ))
  f0 =    (swap_endian(uint(header,16),/swap_if_little_endian))
  status_bits = header[18]
  peak_bin = header[19]

  if ion then trg_flag = ishft(header[12],-6) and 1b else trg_flag = ishft(mode2,-7) and 1b ;1=no targeted
  smp_flag = ishft(header[12],-4) and 1b ;1=summing
  arc_flag = ishft(header[13],-4) and 1b ;1=summing
  smp_accum = header[12] and 15b
  arc_accum = header[13] and 15b

  num_total = 2ul^smp_accum ;in 1/4 NYS accumulation periods
  num_accum = 2ul^(smp_flag*smp_accum)
  if survey then begin
    num_total *= 2ul^arc_accum
    num_accum *= 2ul^(arc_flag*arc_accum)
  endif
  
  compression = (LTCSNNNN_bits and '80'x) ne 0
  if compression eq 0 then dprint,'Log Compression is NOT on!',dlevel=3

  bps = ([4,1])[compression]
  ns = pksize - 20
  ndat = ns / bps
  if ns gt 0 then begin
    data = ccsds_data[20:*]
    ; data_size = n_elements(data)
    if compression then cnts = float( spp_swp_log_decomp(data,0) ) $
    else cnts = float(swap_endian(ulong(data,0,ndat),/swap_if_little_endian ))
    tcnts = total(cnts)
  endif else begin
    tcnts = -1.
    cnts = 0.
  endelse
  
  nys=2d^24/19.2d6 ;0.8738
  trg_num=([2d,1d])[trg_flag]

  productstr = {spp_swp_span_prod, $
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
    ndat:         ndat, $
    datasize:     ns, $
    LTCSNNNN_bits:LTCSNNNN_bits, $
    arch_bits:    arch_bits,  $
    mode2_ori:    mode2,  $
    mode2:        mode2,  $
    f0:           f0,   $
    status_bits:  status_bits,$
    peak_bin:     peak_bin, $
    product_bits: product_bits,  $
    num_total:    num_total, $
    num_accum:    num_accum, $
    time_total:   num_total*nys/4d*trg_num, $
    time_accum:   num_accum*nys/4d, $
    cnts:         tcnts,  $
    ano_spec:     fltarr(16),  $
    nrg_spec:     fltarr(32),  $
    def_spec:     fltarr(8) ,  $
    mas_spec:     fltarr(16),  $
    pdata:        ptr_new(cnts), $
    gap:          ccsds.gap  }

end