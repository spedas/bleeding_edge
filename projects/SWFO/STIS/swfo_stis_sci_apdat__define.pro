; $LastChangedBy: ali $
; $LastChangedDate: 2021-09-24 13:30:58 -0700 (Fri, 24 Sep 2021) $
; $LastChangedRevision: 30316 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_sci_apdat__define.pro $


function swfo_stis_sci_apdat::decom,ccsds,source_dict=source_dict      ;,header,ptp_header=ptp_header,apdat=apdat
  common swfo_stis_sci_com4, lastdat, last_str
  ccsds_data = swfo_ccsds_data(ccsds)

  if debug(5) then begin
    dprint,dlevel=4,'SST',ccsds.pkt_size, n_elements(ccsds_data), ccsds.apid
    hexprint,ccsds_data[0:31]
    hexprint,swfo_data_select(ccsds_data,80,8)
  endif

  if n_elements(ccsds_data) eq 20+256 then begin ;log-compressed science packets
    scidata=uint(spp_swp_log_decomp(ccsds_data[20:*]))
  endif else scidata = swap_endian( uint(ccsds_data,20,256) ,/swap_if_little_endian)
  if n_elements(last_str) eq 0 || (abs(last_str.time-ccsds.time) gt 300) then lastdat = scidata
  lastdat = scidata

  MET_raw  =  swfo_data_select(ccsds_data,(6)*8, 6*8  )
  duration  =  swfo_data_select(ccsds_data,(12)*8, 16  )
  mode2 =       swfo_data_select(ccsds_data,(14)*8, 16  )
  status_bits = swfo_data_select(ccsds_data,(16)*8, 16  )
  noise_bits = swfo_data_select(ccsds_data,(18)*8, 16  )

  if duration eq 0 then duration = 1u   ; cluge to fix lack of proper output in early version FPGA

  str = {time:ccsds.time,  $
    met: ccsds.met,   $
    met_raw: met_raw, $
    seqn:    ccsds.seqn,$
    pkt_size:    ccsds.pkt_size, $
    duration:       duration , $
    mode2:       mode2 , $
    status_bits:  status_bits, $
    noise_bits:  noise_bits, $
    noise_period:  noise_bits and 255u,  $
    noise_res:    ishft(noise_bits,-8) and 7u , $
    counts:    scidata , $
    gap:  0b }
  str.gap = ccsds.gap

  if debug(3) then begin
    printdat,str
    printdat,time_string(str.time,/local)
  endif

  last_str =str
  return,str

end


pro swfo_stis_sci_apdat::handler2,strct,source_dict=source_dict

  ;printdat,self
  ;printdat,strct

  ;return  ; for now
  strct_1 = swfo_stis_sci_level_1(strct)
  ;printdat,strct_1
  ;return
  if ~obj_valid(self.level_1a) then begin
    dprint,'Creating Science level 1'
    self.level_1a = dynamicarray(name='Science_L1a')
  endif
  da = self.level_1a
  ;printdat,strct
  da.append, strct_1
end


PRO swfo_stis_sci_apdat__define

  void = {swfo_stis_sci_apdat, $
    inherits swfo_gen_apdat, $    ; superclass
    level_1a: obj_new(),  $
    level_1b: obj_new(),  $
    level_2b: obj_new(),  $
    flag: 0 $
  }
END
