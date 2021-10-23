; $LastChangedBy: davin-mac $
; $LastChangedDate: 2021-10-22 13:39:39 -0700 (Fri, 22 Oct 2021) $
; $LastChangedRevision: 30383 $
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




pro swfo_stis_sci_apdat::handler2,struct_stis_sci_level_0b  ,source_dict=source_dict

  ;printdat,struct_stis_sci_level_0b
  ;return;
  if 0 && ~obj_valid(self.level_1a) then begin
    dprint,'Creating Science level 1'
    self.level_1a = dynamicarray(name='Science_L1a')
  endif

  sciobj = swfo_apdat('stis_sci')
  nseobj = swfo_apdat('stis_nse')
  hkpobj = swfo_apdat('stis_hkp2')

  sci_last = sciobj.last_data    ; this should be identical to struct_stis_sci_level_0b
  nse_last = nseobj.last_data
  hkp_last = hkpobj.last_data
  
  res = self.file_resolution
  
  if res gt 0 and sci_last.time gt (self.lastfile_time + res) then begin
    makefile =1 
    trange = self.lastfile_time + [0,res]
    self.lastfile_time = floor( sci_last.time /res) * res
    dprint,dlevel=2,'Make new file ',time_string(self.lastfile_time,prec=3)+'  '+time_string(sci_last.time,prec=3)
  endif else makefile = 0
  
  if isa(self.level_0b,'dynamicarray') then begin
    self.level_0b.append, sci_last
    if makefile then   self.ncdf_make_file,ddata=self.level_0b, trange=trange,type='_L0b'
  endif

  if isa(self.level_0b_all,'dynamicarray') then begin
    if makefile then   self.ncdf_make_file,ddata=self.level_0b_all, trange=trange,type='_all_L0b'
    ignore_tags = ['pkt_size','MET_RAW']
    sci_all = {time:0d,nse_reltime:0d, hkp_reltime:0d}
    extract_tags, sci_all, sci_last, except=ignore_tags
    extract_tags, sci_all, nse_last, except=ignore_tags, /preserve
    extract_tags, sci_all, hkp_last, except=ignore_tags, /preserve
    sci_all.nse_reltime = sci_last.time - struct_value(nse_last,'time',default = !values.d_nan )
    sci_all.nse_reltime = sci_last.time - struct_value(hkp_last,'time',default = !values.d_nan ) 
    self.level_0b.append, sci_all   
  endif
  
  
  if isa(self.level_1a,'dynamicarray') then begin
    struct_stis_sci_level_1a = swfo_stis_sci_level_1(sci_last)
    self.level_1a.append, struct_stis_sci_level_1a
    if makefile then   self.ncdf_make_file,ddata=self.level_0b_all, trange=trange,type='L1A_'
  endif
end


PRO swfo_stis_sci_apdat__define

  void = {swfo_stis_sci_apdat, $
    inherits swfo_gen_apdat, $    ; superclass
    file_resolution: 0d,  $
    lastfile_time : 0d,  $
    level_0b: obj_new(),  $
    level_0b_all: obj_new(),  $       ; This will hold a dynamic array of structures that include data from 3 STIS apids  (Science + Noise + hkp2)
    level_1a: obj_new(),  $
    level_1b: obj_new(),  $
    level_2b: obj_new(),  $
    flag: 0 $
  }
END
