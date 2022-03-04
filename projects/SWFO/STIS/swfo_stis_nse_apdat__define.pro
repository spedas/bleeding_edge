; $LastChangedBy: ali $
; $LastChangedDate: 2022-03-03 12:58:24 -0800 (Thu, 03 Mar 2022) $
; $LastChangedRevision: 30647 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_nse_apdat__define.pro $


function swfo_stis_nse_apdat::decom,ccsds,source_dict=source_dict      ;,header,ptp_header=ptp_header,apdat=apdat
  common swfo_stis_nse_com4, lastdat, last_str
  ccsds_data = swfo_ccsds_data(ccsds)

  if debug(5) then begin
    dprint,dlevel=4,'SST',ccsds.pkt_size, n_elements(ccsds_data), ccsds.apid
    hexprint,ccsds_data[0:31]
    hexprint,swfo_data_select(ccsds_data,80,8)
  endif

  flt=1.
  hs= 24

  nsedata = swap_endian( uint(ccsds_data,hs,60) ,/swap_if_little_endian)

  ; if ptr_valid(self.last_data_p) && keyword_set(*self.last_data_p) then nse_diff2 = nsedata - *self.last_data_p else nse_diff2 = 0*nsedata

  ;help,self.last_data

  if n_elements(last_str) eq 0 || (abs(last_str.time-ccsds.time) gt 300) then lastdat = nsedata
  nse_diff = nsedata-lastdat
  lastdat = nsedata

  ;dprint,reform(nse_diff,10,6)

  str1=swfo_stis_ccsds_header_decom(ccsds)

  str2 = {$
    nhist:   float(nse_diff) , $
    gap:ccsds.gap}

  str=create_struct(str1,str2)

  if debug(3) then begin
    printdat,str
    printdat,time_string(str.time,/local)
  endif

  last_str =str

  return,str

end


pro swfo_stis_nse_apdat::handler2,strct,source_dict=source_dict

  ;printdat,self
  if ~obj_valid(self.level_1a) then begin
    dprint,'help'
    self.level_1a = dynamicarray(name='Noise_L1a')
  endif
  da =   self.level_1a
  strct_1 = swfo_stis_nse_level_1(strct)
  ;printdat,strct
  da.append, strct_1
end


PRO swfo_stis_nse_apdat__define

  void = {swfo_stis_nse_apdat, $
    inherits swfo_gen_apdat, $    ; superclass
    level_1a: obj_new(),  $
    level_1b: obj_new(),  $
    level_2b: obj_new(),  $
    flag: 0 $
  }
END
