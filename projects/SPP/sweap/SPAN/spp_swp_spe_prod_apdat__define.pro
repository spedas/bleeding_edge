;+
; spp_swp_spe_prod_apdat
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2018-05-25 18:08:06 -0700 (Fri, 25 May 2018) $
; $LastChangedRevision: 25278 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/spp_swp_spe_prod_apdat__define.pro $
;-



pro spp_swp_spe_prod_apdat::prod_16A, strct

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


pro spp_swp_spe_prod_apdat::prod_32E, strct

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
pro spp_swp_spe_prod_apdat::prod_8Dx32E, strct
  pname = '8Dx32E_'
  cnts = *strct.pdata
  cnts_orig = cnts

  cnts = reform(cnts,8,32,/over)
  strct.anode_spec = 0.
  strct.nrg_spec = total(cnts,1)
  strct.def_spec =  total(cnts,2)
  strct.full_spec = cnts_orig

  strct2 = {time:strct.time, $  ; add more in the future
    cnts:cnts, $
    gap: strct.gap}

  self.prod_16Ax32E.append, strct2
  ; if self.rt_flag then  self.store_data, strct2, pname

end

;;----------------------------------------------
;;Product Full Sweep: Archive - 32Ex16A -
pro spp_swp_spe_prod_apdat::prod_16Ax32E, strct
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




pro spp_swp_spe_prod_apdat::prod_16Ax8Dx32E, strct   ; this function needs fixing

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








function spp_swp_spe_prod_apdat::decom,ccsds,ptp_header
;if typename(ccsds) eq 'BYTE' then return,  self.spp_swp_spe_prod_apdat( spp_swp_ccsds_decom(ccsds) )  ;; Byte array as input

pksize = ccsds.pkt_size
if pksize le 20 then begin
  dprint,dlevel = 2, 'size error - no data'
  return, !null
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


compression = (header[12] and 'a0'x) ne 0
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
  full_spec:   fltarr(256), $
  pdata:        ptr_new(cnts), $
  gap:         ccsds.gap  }

return,str
end




pro spp_swp_spe_prod_apdat::handler,ccsds,ptp_header

  strct = self.decom(ccsds)
  
  ns=keyword_set(strct)
  if  ns gt 0 then begin
    case strct.ndat  of
      16:   self.prod_16a,  strct
      32:   self.prod_32e,  strct
      256:  self.prod_8Dx32E, strct
      512:  self.prod_16Ax32E, strct
      4096: self.prod_16Ax8Dx32E, strct
      else:  dprint,dlevel=self.dlevel+1,'Size not recognized: ',strct.ndat,dwait=300,' APID: ',self.apid
    endcase
  endif

  if self.save_flag && keyword_set(strct) then begin
    dprint,self.name,dlevel=5,self.apid
    self.data.append,  strct
  endif


  if self.rt_flag && keyword_set(strct) then begin
    if ccsds.gap eq 1 then strct = [fill_nan(strct[0]),strct]
    store_data,self.tname,data=strct, tagnames=self.ttags , append = 1,gap_tag='GAP'
  endif
  
  *self.last_data_p = strct
  if debug(self.dlevel+3) then begin
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



