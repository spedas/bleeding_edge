; $LastChangedBy: ali $
; $LastChangedDate: 2023-03-13 12:33:02 -0700 (Mon, 13 Mar 2023) $
; $LastChangedRevision: 31621 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_sci_apdat__define.pro $


function swfo_stis_sci_apdat::decom,ccsds,source_dict=source_dict      ;,header,ptp_header=ptp_header,apdat=apdat
  common swfo_stis_sci_com4, lastdat, last_str
  ccsds_data = swfo_ccsds_data(ccsds)
  
  hkp = swfo_apdat('stis_hkp2')
  hkp_sample = hkp.last_data       ; retrieve last hkp packet

  if debug(3) then begin
    dprint,dlevel=2,'SST',ccsds.pkt_size, n_elements(ccsds_data), ccsds.apid,'  ', time_string(ccsds.time)
    hexprint,ccsds_data
    ;hexprint,swfo_data_select(ccsds_data,80,8)
  endif

  ; The counts array is a ulong since a uint can not handle the full dynamic range.
  ; (19 bit accums for compressed science packets)

  hs = 24
  case n_elements(ccsds_data) of
    hs+256:  scidata = ulong(swfo_stis_log_decomp(ccsds_data[hs:*]))
    hs+672:  scidata = ulong(swfo_stis_log_decomp(ccsds_data[hs:*]))
    hs+512:  scidata = ulong(swap_endian( uint(ccsds_data,hs,256) ,/swap_if_little_endian))
    hs+1344: scidata = ulong(swap_endian( uint(ccsds_data,hs,672) ,/swap_if_little_endian))
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
  total6=fltarr(6)
  total14=fltarr(14)
  str2 = {$
    nbins:    nbins,  $
    counts:   ulonarr(672) , $
    total:    total(scidata),$
    total2:   0.,$
    total6:   total6,$
    total14:  total14,$
    rate:     0.,$
    rate2:    0.,$
    rate6:    total6,$
    scaled_rate6:total6,$
    rate14:   total14,$
    sigma14:  total14,$
    avgbin14: total14,$
    gap:ccsds.gap}

  p=replicate(swfo_stis_nse_find_peak(),14)
  if nbins eq 672 then begin

    ;    for fto=1,7 do begin
    ;      for tid=0,1 do begin
    ;        bin=(fto-1)*2+tid
    ;        total14[bin]=total(scidata[48*bin:48*bin+47])
    ;      endfor
    ;    endfor

    d=reform(scidata,[48,14])
    total14=total(d,1)
    foreach tid,[0,1] do begin
      total6[0+tid*3]=total14[0+tid]+total14[4+tid]+total14[ 8+tid]+total14[12+tid]
      total6[1+tid*3]=total14[2+tid]+total14[4+tid]+total14[10+tid]+total14[12+tid]
      total6[2+tid*3]=total14[6+tid]+total14[8+tid]+total14[10+tid]+total14[12+tid]
    endforeach
    str2.total2=total(total6)

    for j=0,13 do begin
      p[j]=swfo_stis_nse_find_peak(d[*,j])
    endfor

  endif

  str2.counts=scidata
  str2.total6=total6
  str2.total14=total14
  str2.rate=str2.total/str1.duration
  str2.rate2=str2.total2/str1.duration
  str2.rate6=total6/str1.duration
  str2.scaled_rate6=str2.rate6/str1.pulser_frequency
  str2.rate14=total14/str1.duration
  str2.sigma14=p.s
  str2.avgbin14=p.x0
  
  
  lut_map        = struct_value(hkp_sample,'USER_09',default=6b)
  ;use_lut        = struct_value(hkp_sample,'xxxx',default=0b)   ; needs fixing
  sci_nonlut_mode   = struct_value(hkp_sample,'SCI_NONLUT_MODE',default=0b) 
  sci_resolution     = struct_value(hkp_sample,'SCI_RESOLUTION',default=3b)
  sci_translate      = struct_value(hkp_sample,'SCI_TRANSLATE',default=0u)

  
  str3={ $
    ;use_lut: use_lut, $
    lut_map: lut_map, $
    sci_nonlut_mode: sci_nonlut_mode, $
    sci_translate: sci_translate, $
    sci_resolution: sci_resolution $  
    }
    
  ;printdat,str3

  str=create_struct(str1,str2,str3)

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
  if  ~obj_valid(self.level_1a) then begin
    dprint,'Creating Science level 1'
    self.level_1a = dynamicarray(name='Science_L1a')
    first_level_1a = 1
  endif

  sciobj = swfo_apdat('stis_sci')
  nseobj = swfo_apdat('stis_nse')
  hkpobj = swfo_apdat('stis_hkp2')

  sci_last = sciobj.last_data    ; this should be identical to struct_stis_sci_level_0b
  nse_last = nseobj.last_data
  hkp_last = hkpobj.last_data

  res = self.file_resolution

  if res gt 0 && isa(sci_last) && sci_last.time gt (self.lastfile_time + res) then begin
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
    struct_stis_sci_level_1a = swfo_stis_sci_level_1a(sci_last)
    self.level_1a.append, struct_stis_sci_level_1a
    if keyword_set(first_level_1a) then begin
      store_data,'stis',data = da,tagnames = 'SPEC_??',val_tag='_NRG'
      options,'stis_SPEC_??',spec=1
    endif
    if makefile then   self.ncdf_make_file,ddata=self.level_1a, trange=trange,type='L1A_'
  endif


  if isa(self.level_1b,'dynamicarray') then begin
    struct_stis_sci_level_1b = swfo_stis_sci_level_1b(sci_last)
    self.level_1b.append, struct_stis_sci_level_1b
    if makefile then   self.ncdf_make_file,ddata=self.level_1b, trange=trange,type='L1B_'
  endif

end



pro swfo_stis_sci_apdat::create_tplot_vars,ttags=ttags
  dprint,dlevel=2,verbose=self.verbose,'Creating tplot variables for: ',self.name
  if ~keyword_set(ttags) then ttags = self.ttags
  dyndata = self.data
  if isa(dyndata,'dynamicarray') && keyword_set(self.tname) then begin
    store_data,self.tname,data=dyndata, tagnames=ttags, gap_tag='GAP',verbose = self.verbose
  endif
  
  if isa(self.level_1a,'dynamicarray') then begin
    store_data,'stis_l1a',data=self.level_1a,tagnames='SPEC_??',val_tag='_NRG'
    options,'stis_l1a_SPEC_??',spec=1,yrange=[5.,8000],/ylog,/zlog,/default
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
