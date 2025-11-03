; $LastChangedBy: davin-mac $
; $LastChangedDate: 2025-10-27 11:02:52 -0700 (Mon, 27 Oct 2025) $
; $LastChangedRevision: 33797 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_sci_apdat__define.pro $


function swfo_stis_sci_apdat::decom,ccsds   ,source_dict=source_dict      ;,header,ptp_header=ptp_header,apdat=apdat
;  common swfo_stis_sci_com4, lastdat, last_str
  ccsds_data = swfo_ccsds_data(ccsds)
  str1=swfo_stis_ccsds_header_decom(ccsds)
  ;if str1.fpga_rev gt 209 then ccsds_data=ccsds_data[0:-3]

  ;hkp = swfo_apdat('stis_hkp2')
  ;hkp_sample = hkp.last_data       ; retrieve last hkp packet

  if debug(5) then begin
    dprint,dlevel=4,'SST',ccsds.pkt_size, n_elements(ccsds_data), ccsds.apid,'  ', time_string(ccsds.time)
    hexprint,ccsds_data
    ;hexprint,swfo_data_select(ccsds_data,80,8)
  endif

  ; The counts array is a ulong since a uint can not handle the full dynamic range.
  ; (19 bit accums for compressed science packets)

  hs = 24
  case n_elements(ccsds_data) of
    hs+256:   scidata = ulong(swfo_stis_log_decomp(ccsds_data[hs:hs+256-1]))
    hs+256+2: scidata = ulong(swfo_stis_log_decomp(ccsds_data[hs:hs+256-1]))
    hs+672:   scidata = ulong(swfo_stis_log_decomp(ccsds_data[hs:hs+672-1]))
    hs+672+2: scidata = ulong(swfo_stis_log_decomp(ccsds_data[hs:hs+672-1]))
    hs+512:   scidata = ulong(swap_endian( uint(ccsds_data,hs,256) ,/swap_if_little_endian))
    hs+512+2:   scidata = ulong(swap_endian( uint(ccsds_data,hs,256) ,/swap_if_little_endian))
    hs+1344:  scidata = ulong(swap_endian( uint(ccsds_data,hs,672) ,/swap_if_little_endian))
    hs+1344+2:  scidata = ulong(swap_endian( uint(ccsds_data,hs,672) ,/swap_if_little_endian))
    else :  begin
      scidata = ulong(swfo_stis_log_decomp(ccsds_data[hs:*]))
      dprint,'Unknown science packet size:',n_elements(ccsds_data)
    end
  endcase

  nbins = n_elements(scidata)
  if nbins gt 672 then begin
    dprint,'Science array size larger than 672:',nbins,'Chopping off the rest of the array.'
    scidata=scidata[0:671]
  endif


;  if n_elements(last_str) eq 0 || (abs(last_str.time-ccsds.time) gt 65) then lastdat = scidata
;  lastdat = scidata

  ;  if duration eq 0 then duration = 1u   ; cluge to fix lack of proper output in early version FPGA


  if 1 then begin
    str2 = {$
      nbins:    nbins,  $
      counts:   fltarr(672) , $
      valid: 1, $
      gap:ccsds.gap}
    str2.counts=scidata

    str=create_struct(str1,str2)
 

  endif else begin
    ; Force all structures to have exactly 672 elements. If the LUT is being used then only the first 256 will be used
    total6=fltarr(6)
    total14=fltarr(14)
    str2 = {$
      nbins:    nbins,  $
      counts:   fltarr(672) , $
      total:    total(scidata),$
      total2:   0.,$
      total6:   total6,$
      total14:  total14,$
      rate:     0.,$
      rate2:    0.,$
      ;  rate6_raw:    total6,$
      rate6    :    total6, $
      scaled_rate6:total6,$
      ;  rate14_raw:   total14,$
      rate14:   total14,$
      sigma14:  total14,$
      avgbin14: total14,$
      valid: 1, $
      gap:ccsds.gap}

    p=replicate(swfo_stis_nse_find_peak(),14)
    if nbins eq 672 then begin

      ;    for fto=1,7 do begin
      ;      for tid=0,1 do begin
      ;        bin=(fto-1)*2+tid
      ;        total14[bin]=total(scidata[48*bin:48*bin+47])
      ;      endfor
      ;    endfor

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

    endif else begin
      dprint,'mode not allowed',dlevel=2,verbose=self.verbose
    endelse



    str2.counts=scidata
    str2.total6=total6
    str2.total14=total14
    str2.rate=str2.total/str1.duration
    str2.rate2=str2.total2/str1.duration
    str2.rate6=total6/str1.duration
    str2.scaled_rate6=str2.rate6/str1.pulser_frequency[0]
    str2.rate14=total14/str1.duration
    str2.sigma14=p.s
    str2.avgbin14=p.x0
    lut_map        = struct_value(hkp_sample,'USER_09',default=6b)
    ;use_lut        = struct_value(hkp_sample,'xxxx',default=0b)   ; needs fixing
    ;sci_nonlut_mode   = 1b and struct_value(hkp_sample,'SCI_MODE_BITS',default=0b)
    sci_nonlut_mode   = (str1.detector_bits and 64) ne 0
    sci_decimate = (str1.detector_bits and 128) ne 0
    ; sci_detectorenable = (str1.detector_bits and 63) ne 0
    sci_resolution     = struct_value(hkp_sample,'SCI_RESOLUTION',default=3b)
    sci_translate      = struct_value(hkp_sample,'SCI_TRANSLATE',default=0u)


    str3={ $
      ;use_lut: use_lut, $
      lut_map: lut_map, $
      sci_nonlut_mode: sci_nonlut_mode, $
      sci_decimate: sci_decimate, $
      sci_translate: sci_translate, $
      sci_resolution: sci_resolution $
    }

    ;printdat,str3

    str=create_struct(str1,str2,str3)

    if debug(4) then begin

      printdat,str
      dprint,time_string(str.time,/local)
    endif

  endelse



  last_str =str
  return,str
end



pro swfo_stis_sci_apdat::handler2,struct_stis_sci  ,source_dict=source_dict

  pb = 0
  makefile=0

  ;if source_dict.haskey('headerstr') && source_dict.headerstr.haskey('replay') && source_dict.headerstr.replay  then begin
  if 1 then begin
    if self.replay  then begin
      pb = self.replay_bit
      prefix=self.prefix  ;'pb_'
    endif else begin
      pb = 0
      prefix= self.prefix  ;''
    endelse
    
  endif else begin
    if source_dict.haskey('replay')  && source_dict.replay  then begin
      pb = 0x800
      prefix='pb_'
    endif else begin
      pb = 0
      prefix= ''
    endelse
    
  endelse

  tname = 'swfo_'+prefix+'stis_'

  sciobj = swfo_apdat(0x350 or pb)   ; stis_sci
  nseobj = swfo_apdat(0x351 or pb)   ; stis_nse
  hkpobj = swfo_apdat(0x35f or pb)   ; stis_hkp2
  sc100obj = swfo_apdat(prefix+'sc_100')  ; apid 100
  sc110obj = swfo_apdat(prefix+'sc_110')  ; apid 110


  sci_last = sciobj.last_data    ; this should be identical to struct_stis_sci
  nse_last = nseobj.last_data
  hkp_last = hkpobj.last_data

 if ~isa(sci_last) || ~isa(nse_last) || ~isa(hkp_last) then begin
   dprint,'bad sci/nse/hkp data'
   return
 endif

  sc100_last = sc100obj.last_data
  sc110_last = sc110obj.last_data

  ; l0b = swfo_stis_sci_level_0b(sci_last,nse_last,hkp_last,sc100_dat=sc100_last, sc110_dat=sc110_last, playback=pb)
  l0b = swfo_stis_sci_level_0b(sci_dat=sci_last,nse_dat=nse_last,hkp_dat=hkp_last,sc100_dat=sc100_last, sc110_dat=sc110_last, playback=pb)

  if isa(l0b,/null) then begin
    dprint , 'Bad L0B'
    return
  endif

  if  ~obj_valid(self.level_0b) then begin
    dprint,'Creating Science level 0B for: '+self.name
    ddata = dynamicarray(name=self.prefix+'Science_L0b')
    self.level_0b = ddata
  endif

  if isa(self.level_0b,'dynamicarray') then begin
    size = self.level_0b.size
    self.level_0b.append, l0b
    if size eq 0 then begin
      store_data,tname+'L0b',data = self.level_0b,tagnames = '*'  , verbose=1 ;, time_tag = 'TIME_UNIX';,val_tag='_NRG'    ; warning don't use time_tag keyword
      options,tname+'L0b_SCI_COUNTS',spec=1
    endif
  endif
  
  
  ; experimental version of level 0b
  ; l0b_v2 = swfo_stis_sci_l0b(sci_dat=sci_last,nse_dat=nse_last,hkp_dat=hkp_last,sc100_dat=sc100_last, sc110_dat=sc110_last, playback=pb)
  ; if  ~obj_valid(self.level_xx) then begin
  ;   dprint,'Creating Science level 0B for: '+self.name
  ;   ddata = dynamicarray(name=self.prefix+'Science_L0b_v2')
  ;   self.level_xx = ddata
  ; endif
  ; if isa(self.level_xx,'dynamicarray') then begin
  ;   size = self.level_xx.size
  ;   self.level_xx.append, l0b_v2
  ;   if size eq 0 then begin
  ;     store_data,tname+'L0x',data = self.level_xx,tagnames = '*'  , verbose=1 ;, time_tag = 'TIME_UNIX';,val_tag='_NRG'    ; warning don't use time_tag keyword
  ;     options,tname+'L0x_SCI_COUNTS',spec=1
  ;   endif
  ; endif
  ;  return

  if  ~obj_valid(self.level_1a) then begin
    dprint,'Creating Science level 1a for ',self.name
    self.level_1a = dynamicarray(name=self.prefix + 'Science_L1a')
  endif

  L1a = swfo_stis_sci_level_1a(l0b)

  if isa(self.level_1a,'dynamicarray') then begin
    size = self.level_1a.size
    self.level_1a.append, L1a
    if size eq 0 then begin
      store_data,tname+'L1a',data = self.level_1a,tagnames = '*'
      store_data,tname+'L1a',data = self.level_1a,tagnames = 'SPEC_??',val_tag='_NRG'
      store_data,tname+'L1a',data = self.level_1a,tagnames = 'SPEC_???',val_tag='_NRG'
      store_data,tname+'L1a',data = self.level_1a,tagnames = 'SPEC_????',val_tag='_NRG'
      options,tname+'L1a_SPEC_??',spec=1, zlog=1, ylog=1
      options,tname+'L1a_SPEC_???',spec=1, zlog=1, ylog=1
      options,tname+'L1a_SPEC_????',spec=1, zlog=1, ylog=1

    endif
    if makefile then begin
      self.ncdf_make_file,ddata=self.level_1a, trange=trange,type='L1A'
    endif
  endif



  if  ~obj_valid(self.level_1b) then begin
    dprint,'Creating Science level 1b'
    self.level_1b = dynamicarray(name='Science_L1b')
  endif


  L1b = swfo_stis_sci_level_1b(L1a)


  if isa(self.level_1b,'dynamicarray') then begin
    size = self.level_1b.size
    self.level_1b.append, L1b
    if size eq 0 then begin
      store_data,tname+'L1b',data = self.level_1b,tagnames = '*'
      store_data,tname+'L1b',data = self.level_1b,tagnames = '*_ion_flux',val_tag='ion_energy'
      ; options,tname+'L1b_SPEC_??',spec=1
      store_data,tname+'L1b',data = self.level_1b,tagnames = '*_elec_flux',val_tag='elec_energy'
      ; options,tname+'L1b_*_FLUX',spec=1, zlog=1, ylog=1
      ; stop
    endif
    if makefile then begin
      self.ncdf_make_file,ddata=self.level_1b, trange=trange,type='L1B'
    endif
  endif




  if 0 then begin
    res = self.file_resolution

    if res gt 0 && isa(sci_last) && sci_last.time gt (self.lastfile_time + res) then begin
      makefile =1
      trange = self.lastfile_time + [0,res]
      self.lastfile_time = floor( sci_last.time /res) * res
      dprint,dlevel=2,'Make new file ',time_string(self.lastfile_time,prec=3)+'  '+time_string(sci_last.time,prec=3)
    endif else makefile = 0
    if makefile then  begin
      self.ncdf_make_file,ddata=self.level_0b, trange=trange,type='L0B'
    endif
  endif



end



pro swfo_stis_sci_apdat::create_tplot_vars,ttags=ttags
  dprint,dlevel=2,verbose=self.verbose,'Creating tplot variables for: ',self.name
  if ~keyword_set(ttags) then ttags = self.ttags
  dyndata = self.data
  if isa(dyndata,'dynamicarray') && keyword_set(self.tname) then begin
    store_data,self.tname,data=dyndata, tagnames=ttags, gap_tag='GAP',verbose = 1  ;self.verbose
  endif

  if isa(self.level_1a,'dynamicarray') then begin
    store_data,'stis_l1a',data=self.level_1a,tagnames='SPEC_??',val_tag='_NRG',verbose=1
    options,'stis_l1a_SPEC_??',spec=1,yrange=[5.,8000],/ylog,/zlog,/default
  endif

end

;function swfo_stis_sci_apdat::init,


;end



PRO swfo_stis_sci_apdat__define

  void = {swfo_stis_sci_apdat, $
    inherits swfo_gen_apdat, $    ; superclass
    ;    inherits generic_apdat,  $
    level_xx: obj_new(),  $       ; experimental: This will be a an ordered hash that contains all higher level data products
    level_0b: obj_new(),  $       ; Level 0B data is stored in the "data" variable of swfo_gen_apdat
    ;level_0b_all: obj_new(),  $       ; This will hold a dynamic array of structures that include data from 3 STIS apids  (Science + Noise + hkp2)
    level_1a: obj_new(),  $
    level_1b: obj_new(),  $
    level_2b: obj_new(),  $
    flag: 0 $
  }
END
