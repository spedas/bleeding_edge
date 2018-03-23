;+
; spp_swp_spi_prod_apdat
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2018-03-22 09:29:23 -0700 (Thu, 22 Mar 2018) $
; $LastChangedRevision: 24932 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/spp_swp_spi_prod_apdat__define.pro $
;-



pro spp_swp_spi_prod_apdat::prod_16A, strct

  pname = '16A_'
  data = *strct.pdata
  strct2 = {time:strct.time, $
    SPEC:data,  $
    gap: strct.gap}
    
  if self.save_raw && self.prod_16A then   self.prod_16A.append, strct2
;  self.store_data, strct2, pname
  return
end



pro spp_swp_spi_prod_apdat::prod_32E, strct

  pname = '32E_'
  data = *strct.pdata
  strct2 = {time:strct.time, $
    SPEC:data,  $
    gap: strct.gap}

  if self.save_raw && self.prod_32E then   self.prod_32E.append, strct2
  ;  self.store_data, strct2, pname
  return
end





;;----------------------------------------------
;;Product Full Sweep: Archive - 32Ex16A -
pro spp_swp_spi_prod_apdat::prod_32Ex16A, strct
  pname = '32Ex16A_'
  data = *strct.pdata

  data = reform(data,32,16,/overwrite)
  spec1 = total(data,2)
  spec2 = total(data,1 )

  strct2 = {time:strct.time, $
    spec1:spec1, $
    spec2:spec2, $
    gap: strct.gap}

  if self.save_raw && self.prod_32Ex16A  then   self.prod_32Ex16A.append, strct2
;  self.store_data, strct2, pname

end



;
;pro spp_swp_spi_prod_apdat::prod_16Ax32E, strct
;  message,'bad routine'
;  pname = '16Ax32E_'
;  strct = {time:header_str.time, $
;    cnts_Anode:data,  $
;    gap: 0}
;  if apdat.rt_flag && apdat.ttags then begin
;    ;if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
;    store_data,apdat.tname+pname,data=strct, tagnames=apdat.ttags, /append
;  endif
;end


pro spp_swp_spi_prod_apdat::prod_8Dx32Ex16A, strct   ; this function needs fixing

  cnts = *strct.pdata
  if n_elements(cnts) ne 4096 then begin
    dprint,'bad size'
    return
  endif
  
  pname = '8Dx32Ex16A_'
  dprint,pname
  
  strct.def_spec   = total(reform(/overwrite,cnts,8,32*16),2)
  strct.anode_spec = total(reform(/overwrite,cnts,8*32,16),1)
  cnts = reform(/overwrite,cnts,8,32,16)
  strct.nrg_spec =   total(  total( cnts, 1 ),2)

  strct2 = {time:strct.time, $  ; add more in the future
    cnts:cnts, $
    gap: strct.gap}


  

  if self.save_raw && self.prod_8Dx32Ex16A then   self.prod_8Dx32Ex16A.append, strct2
;  self.store_data, strct2, pname
end



pro spp_swp_spi_prod_apdat::prod_32Ex16Ax4M, strct  ; this function needs fixing
  cnts = *strct.pdata
  if n_elements(cnts) ne 2048 then begin
    dprint,'bad size'
    return
  endif
  pname = '32Ex16Ax4M_'

  strct.anode_spec = total( total(reform(/overwrite,cnts,32,16,4),1), 2)
  strct.nrg_spec =  total( reform(/overwrite,cnts,32,16*4), 2 )
  strct.mass_spec = total( reform(/overwrite,cnts,32*16,4), 1 )
  cnts = reform(/overwrite,cnts,32,16,4)

  strct2 = {time:strct.time, $  ; add more in the future
    cnts:cnts, $
    gap: strct.gap}

    
  if self.save_raw && self.prod_32Ex16Ax4M then   self.prod_32Ex16Ax4M.append, strct2
;  self.store_data, strct2, pname
end



pro spp_swp_spi_prod_apdat::prod_8Dx32EX16Ax2M, strct   ; this function needs fixing
  if n_elements(data) ne 8192 then begin
    dprint,'bad size'
    return
  endif
  pname = '8Dx32Ex16Ax2M_'
  cnts = *strct.pdata

  cnts = reform(cnts,8,32,16,2,/overwrite)

  strct2 = {time:strct.time, $  ; add more in the future
    cnts:cnts, $
    gap: strct.gap}

  strct.anode_spec = total( reform(cnts,8*32,16) , 1)
  strct.nrg_spec =  total( total(cnts,1), 2 )
  strct.def_spec =  total( total(cnts,2) ,2)
  strct.mass_spec =  total(cnts,1)
  
  if self.save_raw && self.prod_8Dx32Ex16Ax2M then   self.prod_8Dx32Ex16Ax2M.append, strct2

end



pro spp_swp_spi_prod_apdat::prod_8Dx32Ex16Ax1M, strct   ; this function needs fixing
  if n_elements(data) ne 4096 then begin
    dprint,'bad size'
    return
  endif
  pname = '8Dx32Ex16Ax1M_'
dprint,pname
  cnts = *strct.pdata

  cnts = reform(cnts,8,32,16,/over)

  strct2 = {time:strct.time, $  ; add more in the future
    cnts:cnts, $
    gap: strct.gap}

  strct.anode_spec = total( reform(cnts,8*32,16) , 1)
  strct.nrg_spec =  total( total(cnts,1), 2 )
  strct.def_spec =  total( total(cnts,2) ,2)
;  strct.mass_spec =  total(cnts,1)

  if self.save_raw  && self.prod_8Dx32Ex16Ax1M then   self.prod_8Dx32Ex16Ax1M.append, strct2
end


pro spp_swp_spi_prod_apdat::prod_16Ax16M, strct   ; this function needs fixing
  cnts = *strct.pdata
  if n_elements(cnts) ne 256 then begin
    dprint,'bad size'
    return
  endif
  pname = '16Ax16M_'
  
;  printdat,cnts

  cnts = reform(cnts,16,16,/over)

  strct2 = {time:strct.time, $  ; add more in the future
    cnts:cnts, $
    gap: strct.gap}

  strct.anode_spec =  total(cnts,2)
  strct.mass_spec =  total(cnts,1) 
  
  if self.save_raw && self.prod_16Ax16m.append then   self.prod_16Ax16m.append, strct2

end






function spp_swp_spi_prod_apdat::decom,ccsds,ptp_header
;if typename(ccsds) eq 'BYTE' then return,  self.spp_swp_spi_prod_apdat( spp_swp_ccsds_decom(ccsds) )  ;; Byte array as input

pksize = ccsds.pkt_size
if pksize le 20 then begin
  dprint,dlevel = 2, 'size error - no data ',ccsds.pkt_size,ccsds.apid
  return, 0
endif

ccsds_data = spp_swp_ccsds_data(ccsds)
if pksize ne n_elements(ccsds_data) then begin
  dprint,dlevel=1,'Product size mismatch'
  return,0
endif

header    = ccsds_data[0:19]
ns = pksize - 20
log_flag  = header[12]
mode1 = header[13]
mode2 = (swap_endian(uint(ccsds_data,14) ,/swap_if_little_endian ))
f0 = (swap_endian(uint(header,16), /swap_if_little_endian))
status_flag = header[18]
peak_bin = header[19]

;  if ptr_valid(apdat.last_ccsds) && keyword_set(*apdat.last_ccsds) then  delta_t = ccsds.time - (*(apdat.last_ccsds)).time else delta_t = !values.f_nan

compression = (header[12] and 'a0'x) ne 0
bps =  ([4,1])[ compression ]

ndat = ns / bps

if ns gt 0 then begin
  data      = ccsds_data[20:*]
  ; data_size = n_elements(data)
  if compression then    cnts = spp_swp_log_decomp(data,0) $
  else    cnts = swap_endian(ulong(data,0,ndat) ,/swap_if_little_endian )
  tcnts = total(cnts)
endif else begin
  tcnts = -1.
  cnts = 0
endelse

  str = { $
    time:        ccsds.time, $
    apid:        ccsds.apid, $
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
    f0:           f0,$
    status_flag: status_flag,$
    peak_bin:    peak_bin, $
    cnts:  tcnts,  $
    anode_spec:  fltarr(16),  $
    nrg_spec:    fltarr(32),  $
    def_spec:    fltarr(8) ,  $
    mass_spec:   fltarr(32),  $
    pdata:        ptr_new(cnts), $
    gap:         ccsds.gap  }




return,str
end


 
 


pro spp_swp_spi_prod_apdat::handler,ccsds,ptp_header

  strct = self.decom(ccsds)
  
  ns=1
  if keyword_set(strct) &&  ns gt 0 then begin
    case strct.ndat  of
      16:   self.prod_16a,  strct
;      32:   self.prod_32e,  strct
      256:  self.prod_16Ax16M, strct
      512:  self.prod_32Ex16A, strct
      2048: self.prod_32Ex16Ax4M, strct
      4096: self.prod_8Dx32Ex16A, strct
      8192: self.prod_8Dx32EX16Ax2M, strct
      else:  dprint,dlevel=3,'Size not recognized: ',strct.ndat
    endcase
  endif
 ; dprint,dlevel=2,strct.apid,strct.ndat

  if self.save_flag && keyword_set(strct) then begin
    dprint,self.name,dlevel=5,self.apid
    self.data.append,  strct
  endif


  if self.rt_flag && keyword_set(strct) then begin
    if ccsds.gap eq 1 then strct = [fill_nan(strct[0]),strct]
    store_data,self.tname,data=strct, tagnames=self.ttags , append = 1,gap_tag='GAP'
  endif
end





 
 
; 
;PRO spp_swp_spi_prod_apdat::GetProperty, array=array, npkts=npkts, apid=apid, name=name,  typename=typename, nsamples=nsamples,strct=strct,ccsds_last=ccsds_last ;,counter=counter
;COMPILE_OPT IDL2
;;IF (ARG_PRESENT(counter)) THEN counter = self.counter
;IF (ARG_PRESENT(name)) THEN name = self.name
;IF (ARG_PRESENT(apid)) THEN apid = self.apid
;IF (ARG_PRESENT(npkts)) THEN npkts = self.npkts
;IF (ARG_PRESENT(ccsds_last)) THEN ccsds_last = self.ccsds_last
;IF (ARG_PRESENT(array)) THEN array = self.data.array
;IF (ARG_PRESENT(nsamples)) THEN nsamples = self.data.size
;IF (ARG_PRESENT(typename)) THEN typename = typename(*self.data_array)
;if (arg_present(strct) ) then begin
;  strct = {spp_swp_spi_prod_apdat}
;  struct_assign , self, strct
;endif
;END
; 
 


FUNCTION spp_swp_spi_prod_apdat::Init,apid,name,_EXTRA=ex
  void = self->spp_gen_apdat::Init(apid,name)   ; Call our superclass Initialization method.
  self.save_raw = 0  ; set to 1 to save full 3 or 4 Dimensions of raw data
  self.prod_16A     = obj_new('dynamicarray',name='prod_16A')
  self.prod_16Ax16M     = obj_new('dynamicarray',name='prod_16Ax16M')
  self.prod_32Ex16A = obj_new('dynamicarray',name='prod_32Ex16A')
  self.prod_8Dx32Ex16A=  obj_new('dynamicarray',name='prod_8Dx32Ex16A')
  self.prod_32Ex16Ax4M=  obj_new('dynamicarray',name='prod_32Ex16Ax4M')
  self.prod_8Dx32EX16Ax1M=  obj_new('dynamicarray',name='prod_8Dx32EX16Ax1M')
  self.prod_8Dx32EX16Ax2M=  obj_new('dynamicarray',name='prod_8Dx32EX16Ax2M') 
  RETURN, 1
END



PRO spp_swp_spi_prod_apdat::Clear
  self->spp_gen_apdat::Clear
  self.prod_16A.array     = !null
  self.prod_16Ax16M.array = !null
  self.prod_32Ex16A.array = !null
  self.prod_8Dx32Ex16A.array = !null
  self.prod_32Ex16Ax4M.array = !null
  self.prod_8Dx32EX16Ax1M.array = !null
  self.prod_8Dx32EX16Ax2M.array = !null
END




;pro spp_swp_spi_prod_apdat::finish
;
;  store_data,self.tname,data=self.data.array, tagnames=self.ttags,gap_tag='GAP',verbose=0
;
;end

 
PRO spp_swp_spi_prod_apdat__define
void = {spp_swp_spi_prod_apdat, $
  inherits spp_gen_apdat, $    ; superclass
  save_raw: 0b, $
  prod_16A     : obj_new(), $
  prod_16Ax16M     : obj_new(), $
  prod_32Ex16A : obj_new(), $
  prod_8Dx32Ex16A:  obj_new(), $
  prod_32Ex16Ax4M:  obj_new(), $
  prod_8Dx32EX16Ax1M:  obj_new(), $
  prod_8Dx32EX16Ax2M:  obj_new() $
  }
END



