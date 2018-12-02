;+
; spp_swp_spe_prod_apdat
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2018-12-01 07:52:04 -0800 (Sat, 01 Dec 2018) $
; $LastChangedRevision: 26217 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/spp_swp_spe_prod_apdat__define.pro $
;-



pro spp_swp_spe_prod_apdat::proc_16A, strct

  pname = '16A_'
  
  cnts = *strct.pdata
  strct2 = {time:strct.time, $
    cnts:cnts,  $
    gap: strct.gap}
  
  strct.anode_spec = cnts
  strct.nrg_spec = 0.
  strct.def_spec = 0.
    
  self.prod_16A.append, strct2
;  if self.rt_flag then  self.store_data, strct2, pname
end


pro spp_swp_spe_prod_apdat::proc_32E, strct

  pname = '32E_'

  cnts = *strct.pdata
  strct2 = {time:strct.time, $
    cnts:cnts,  $
    gap: strct.gap}

  strct.anode_spec = 0.
  strct.nrg_spec = cnts
  strct.def_spec = 0.

  self.prod_32E.append, strct2
  ;  if self.rt_flag then  self.store_data, strct2, pname
end


;;----------------------------------------------
;;Product Full Sweep: Archive - 32Ex16A -
pro spp_swp_spe_prod_apdat::proc_8Dx32E, strct
  pname = '8Dx32E_'
  cnts = *strct.pdata
  cnts_orig = cnts

  cnts = reform(cnts,8,32,/over)
  strct.anode_spec = 0.
  strct.nrg_spec = total(cnts,1)
  strct.def_spec =  total(cnts,2)
;  strct.full_spec = cnts_orig

  strct2 = {time:strct.time, $  ; add more in the future
    cnts:cnts, $
    gap: strct.gap}

  self.prod_16Ax32E.append, strct2
  ; if self.rt_flag then  self.store_data, strct2, pname

end

;;----------------------------------------------
;;Product Full Sweep: Archive - 32Ex16A -
pro spp_swp_spe_prod_apdat::proc_16Ax32E, strct
  pname = '16Ax32E_'
  cnts = *strct.pdata

  cnts = reform(cnts,16,32,/over)
  strct.anode_spec = total(cnts,2)
  strct.nrg_spec = total(cnts,1)
  strct.def_spec = 0.

  strct2 = {time:strct.time, $  ; add more in the future
    cnts:cnts, $
    gap: strct.gap}

  self.prod_16Ax32E.append, strct2
 ; if self.rt_flag then  self.store_data, strct2, pname

end




pro spp_swp_spe_prod_apdat::proc_16Ax8Dx32E, strct   ; this function needs fixing

  data = *strct.pdata
  if n_elements(data) ne 4096 then begin
    dprint,'bad size'
    return
  endif
  pname = '16Ax8Dx32E_'

  cnts = *strct.pdata

  cnts = reform(cnts,16,8,32,/over)

  strct2 = {time:strct.time, $  ; add more in the future
    cnts:cnts, $
    gap: strct.gap}
  
  strct.anode_spec = total( total(cnts,2), 2)
  strct.nrg_spec =  total( total(cnts,1), 1 )
  strct.def_spec =  total( total(cnts,1) ,2)

  self.prod_16Ax8Dx32E.append, strct2
;  if self.rt_flag then  self.store_data, strct2, pname
end








function spp_swp_spe_prod_apdat::decom,ccsds ,source_dict=source_dict  ;,ptp_header
;if typename(ccsds) eq 'BYTE' then return,  self.spp_swp_spe_prod_apdat( spp_swp_ccsds_decom(ccsds) )  ;; Byte array as input

pksize = ccsds.pkt_size
if pksize le 20 then begin
  dprint,dlevel = 2, 'size error - no data'
  return, !null
endif

if ccsds.aggregate ne 0 then begin
  return, self.decom_aggregate(ccsds,source_dict=source_dict)  
endif



archive = ccsds.apid and '8'x                ; archive packet determined from the apid  for spane

if 1 then begin    ; New merged method
  spp_swp_span_prod__define,str,ccsds
  
endif else begin
  ccsds_data = spp_swp_ccsds_data(ccsds)

  if pksize ne n_elements(ccsds_data) then begin
    dprint,dlevel=1,'Product size mismatch'
    return,!null
  endif

  header    = ccsds_data[0:19]
  ns = pksize - 20
  log_flag  = header[12]
  ;sample_flag =



  if archive then begin
    mode1 = header[13]
    arc_sum  = 0

  endif else begin    ; survey packet
    mode1 = 0
    arc_sum  = header[13]

  endelse

  ;nsamples =


  mode2 = (swap_endian(uint(ccsds_data,14) ,/swap_if_little_endian ))
  tmode = mode2 and 'ff'x
  emode = ishft(mode2 ,-8)
  f0 = (swap_endian(uint(header,16), /swap_if_little_endian))
  status_bits = header[18]
  peak_bin = header[19]


  compression = (log_flag and 'a0'x) ne 0
  bps =  ([4,1])[ compression ]

  ndat = ns / bps

  if ns gt 0 then begin
    data      = ccsds_data[20:*]
    ; data_size = n_elements(data)
    if compression then    cnts = float( spp_swp_log_decomp(data,0) ) $
    else    cnts = float(swap_endian(ulong(data,0,ndat) ,/swap_if_little_endian ))
    tcnts = total(cnts)
  endif else begin
    tcnts = -1.
    cnts = 0.
  endelse

  product_type = 0

  str = { $
    time:        ccsds.time, $
    met:         0d, $
;    epoch:      0LL,  $
    f0:           f0,$
    apid:        ccsds.apid, $
    source:      0UL,   $
    time_delta:  ccsds.time_delta, $
    seqn:        ccsds.seqn,  $
    seqn_delta:  ccsds.seqn_delta,  $
    seq_group:   ccsds.seq_group,  $
    pkt_size :   ccsds.pkt_size,  $
    ndat:        ndat, $
    datasize:    ns, $
    log_flag:    log_flag, $
    mode1:        mode1,  $
    mode2:        mode2,  $
    tmode:       tmode, $
    emode:       emode, $
    product_type: product_type,  $
    status_bits: status_bits,$
    peak_bin:    peak_bin, $
    cnts:  tcnts,  $
    anode_spec:  fltarr(16),  $
    nrg_spec:    fltarr(32),  $
    def_spec:    fltarr(8) ,  $
    nrg_vals:    fltarr(32),  $
    ;  full_spec:   fltarr(256), $
    pdata:        ptr_new(cnts), $
    gap:         ccsds.gap  }
  
endelse



return,str
end


;function hex,i
; return, string(format='(Z)',i)
;end



pro spp_swp_spe_prod_apdat::handler,ccsds,source_dict = source_dict   ;,ptp_header,source_info=source_info

  strcts = self.decom(ccsds)
  if debug(self.dlevel+4,msg='hello') then begin
    dprint,self.apid,strcts.ndat
    ccsds_data = spp_swp_ccsds_data(ccsds)
    ;hexprint,ccsds_data
  endif
  
;  print,ns
  
  ns=n_elements(strcts)
  for i=0,ns-1 do begin
    strct = strcts[i]
    case strct.ndat  of
      16:   self.proc_16a,  strct
      32:   self.proc_32e,  strct
      256:  self.proc_8Dx32E, strct
      512:  self.proc_16Ax32E, strct
      4096: self.proc_16Ax8Dx32E, strct
      else:  begin
        dprint,dlevel=self.dlevel+1,'Size not recognized: ',strct.ndat,' APID: ',(self.apid)
        if debug(self.dlevel+2) then begin
          hexprint, spp_swp_ccsds_data(ccsds)
        endif
      end
    endcase  
    strcts[i] = strct  
  endfor

  if self.save_flag && keyword_set(strcts) then begin
    dprint,self.name,dlevel=5,self.apid
    self.data.append,  strcts
  endif


  if self.rt_flag && keyword_set(strcts) then begin
    if ccsds.gap eq 1 then strcts = [fill_nan(strcts[0]),strcts]
    store_data,self.tname,data=strcts, tagnames=self.ttags , append = 1,gap_tag='GAP'
  endif
  
  if keyword_set(strct) then *self.last_data_p = strct
  if debug(self.dlevel+3,msg='hello2') then begin
    ;printdat,ccsds  
    hexprint,(*ccsds.pdata)[0:31]
    
  endif
  
end
 





FUNCTION spp_swp_spe_prod_apdat::Init,apid,name,_EXTRA=ex
  void = self->spp_gen_apdat::Init(apid,name)   ; Call our superclass Initialization method.
  self.prod_16A        = obj_new('dynamicarray',name='prod_16A_')
  self.prod_32E       =  obj_new('dynamicarray',name='prod_32E_')
  self.prod_8Dx32E    =  obj_new('dynamicarray',name='prod_8Dx32E_')
  self.prod_16Ax32E    = obj_new('dynamicarray',name='prod_16Ax32E_')
  self.prod_16Ax8Dx32E=  obj_new('dynamicarray',name='prod_16Ax8Dx32E_')
  RETURN, 1
END



PRO spp_swp_spe_prod_apdat::Clear
  self->spp_gen_apdat::Clear
  self.prod_16A.array     = !null
  self.prod_32E.array     = !null
  self.prod_8Dx32E.array  = !null
  self.prod_16Ax32E.array = !null
  self.prod_16Ax8Dx32E.array = !null
END


;PRO spp_swp_spe_prod_apdat::makecdf,trange=trange
;
;  dprint,/phelp,time_string(trange)
;  datarray = self.data.array
;  if keyword_set(trange) then begin
;    w= where(datarray.time ge trange[0] and datarray.time lt trange[1],/null)
;    datarray = datarray[w]
;  endif
;  if ~keyword_set(datarray) then return
;  w = where( datarray.ndat eq datarray.datasize,/null)
;  datarray = datarray[w]
;  if ~keyword_set(datarray) then return
;
;  if keyword_set(datarray) then begin
;    cdf = spp_swp_span_makecdf(datarray)  ;, datanovary,  varnames=varnames, ignore=ignore,_extra=ex
;    pathformat = self.cdf_pathname
;    filename = time_string(trange[0],tformat=pathformat)
;    filename = str_sub(filename,'$NAME$',self.name)
;    filename = root_data_dir() + filename
;    cdf.write,filename
;    obj_destroy,cdf
;    
;  endif
;end
 
function spp_swp_spe_prod_apdat::cdf_global_attributes
  global_att= self.spp_gen_apdat::cdf_global_attributes()
  global_att['InstrumentLead_name'] = 'P. Whittlesey'
  global_att['InstrumentLead_email'] = 'phyllisw@berkeley.edu'
  global_att['InstrumentLead_affiliation'] = 'U.C. Berkeley Space Sciences Laboratory'
  global_att = global_att + self.sw_version()
  return,global_att
end


;
;pro spp_swp_spe_prod_apdat::finish
;
;  dprint,dlevel=2,'Finishing ',self.name,self.apid
;  store_data,self.tname,data=self.data.array, tagnames=self.ttags,gap_tag='GAP',verbose=0
;
;;  store_data, self.prod_16A.array , self.prod_16A.name
;;  store_data, self.prod_16Ax32E.array , self.prod_16Ax32E.name
;;  store_data, self.prod_16Ax8Dx32E.array , self.prod_16Ax8Dx32E.name
;end

 
PRO spp_swp_spe_prod_apdat__define
void = {spp_swp_spe_prod_apdat, $
  inherits spp_gen_apdat, $    ; superclass
  prod_16A     : obj_new(), $
  prod_32E     : obj_new(), $
  prod_8Dx32E  :obj_new(), $
  prod_16Ax32E : obj_new(), $
  prod_16Ax8Dx32E:  obj_new() $
  }
END



