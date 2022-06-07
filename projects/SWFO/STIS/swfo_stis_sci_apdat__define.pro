; $LastChangedBy: ali $
; $LastChangedDate: 2022-06-06 14:34:31 -0700 (Mon, 06 Jun 2022) $
; $LastChangedRevision: 30844 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_sci_apdat__define.pro $


function swfo_stis_sci_apdat::decom,ccsds,source_dict=source_dict      ;,header,ptp_header=ptp_header,apdat=apdat
  common swfo_stis_sci_com4, lastdat, last_str
  ccsds_data = swfo_ccsds_data(ccsds)

  if debug(3) then begin
    dprint,dlevel=2,'SST',ccsds.pkt_size, n_elements(ccsds_data), ccsds.apid,'  ', time_string(ccsds.time)
    hexprint,ccsds_data
    ;hexprint,swfo_data_select(ccsds_data,80,8)
  endif

  hs = 24
  case n_elements(ccsds_data) of
    hs+256:  scidata = ulong(swfo_stis_log_decomp(ccsds_data[hs:*]))
    hs+672:  scidata = ulong(swfo_stis_log_decomp(ccsds_data[hs:*]))
    hs+512:  scidata = swap_endian( uint(ccsds_data,hs,256) ,/swap_if_little_endian)
    hs+1344: scidata = swap_endian( uint(ccsds_data,hs,672) ,/swap_if_little_endian)
    else :  begin
      scidata = ccsds_data[hs:*]
      print,n_elements(ccsds_data)
    end
  endcase

  nbins = n_elements(scidata)


  if n_elements(last_str) eq 0 || (abs(last_str.time-ccsds.time) gt 65) then lastdat = scidata
  lastdat = scidata

  ;  if duration eq 0 then duration = 1u   ; cluge to fix lack of proper output in early version FPGA

  str1=swfo_stis_ccsds_header_decom(ccsds)

  ; Force all structures to have exactly 672 elements. If the LUT is being used then only the first 256 will be used
  total6=replicate(0ul,6)
  ftotid=replicate(0ul,14)
  str2 = {$
    nbins:    nbins,  $
    counts:   ulonarr(672) , $
    total:    total(scidata,/preserve),$
    total6:   total6,$
    total14:  ftotid,$
    rate:     0.,$
    rate6:    replicate(0.,6),$
    rate14:   replicate(0.,14),$
    gap:ccsds.gap}

  ; sometime in the future the counts array should be changed to a ulong since a uint can not handle the full dynamic range. (19 bit accums)

  if nbins eq 672 then begin

    for fto=1,7 do begin
      for tid=0,1 do begin
        bin=(fto-1)*2+tid
        ftotid[bin]=total(scidata[48*bin:48*bin+47],/preserve)
      endfor
    endfor

    foreach tid,[0,1] do begin
      total6[0+tid*3]=ftotid[0+tid]+ftotid[4+tid]+ftotid[ 8+tid]+ftotid[12+tid]
      total6[1+tid*3]=ftotid[2+tid]+ftotid[4+tid]+ftotid[10+tid]+ftotid[12+tid]
      total6[2+tid*3]=ftotid[6+tid]+ftotid[8+tid]+ftotid[10+tid]+ftotid[12+tid]
    endforeach

  endif

  str2.counts = scidata
  str2.total6=total6
  str2.total14=ftotid
  str2.rate = float(str2.total)/str1.duration
  str2.rate6=float(total6)/str1.duration
  str2.rate14=float(ftotid)/str1.duration

  str=create_struct(str1,str2)

  if debug(4) then begin

    printdat,str
    dprint,time_string(str.time,/local)
  endif

  last_str =str
  return,str
end


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
    if makefile then   self.ncdf_make_file,ddata=self.level_1a, trange=trange,type='L1A_'
  endif


  if isa(self.level_1b,'dynamicarray') then begin
    struct_stis_sci_level_1b = swfo_stis_sci_level_1b(sci_last)
    self.level_1b.append, struct_stis_sci_level_1b
    if makefile then   self.ncdf_make_file,ddata=self.level_1b, trange=trange,type='L1B_'
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
