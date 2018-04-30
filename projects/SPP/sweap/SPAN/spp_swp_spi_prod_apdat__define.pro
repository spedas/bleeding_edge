;+
; spp_swp_spi_prod_apdat
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2018-04-28 19:31:32 -0700 (Sat, 28 Apr 2018) $
; $LastChangedRevision: 25144 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/spp_swp_spi_prod_apdat__define.pro $
;-



;;-----------------------------------------------;;
;;                     16A                       ;;
;;-----------------------------------------------;;
;; This function needs fixing
PRO spp_swp_spi_prod_apdat::prod_16A, strct
   pname = '16A_'
   cnts  = *strct.pdata
   IF n_elements(cnts) NE 16 THEN BEGIN
      dprint,'Bad size: '+$
             string(n_elements(cnts))+ $
             ' instead of 16'
      return
   ENDIF
   tot = total(cnts)
   strct.nrg_spec   = tot
   strct.def_spec   = tot
   strct.mass_spec  = tot
   strct.anode_spec = cnts
   strct2 = {gap:strct.gap,$
             time:strct.time, $
             spec1:strct.anode_spec}
   IF self.save_raw && self.prod_16A THEN $
    self.prod_16A.append, strct2
   return
END



;;-----------------------------------------------;;
;;                     08D                       ;;
;;-----------------------------------------------;;
PRO spp_swp_spi_prod_apdat::prod_08D, strct
   pname = '08D_'
   cnts  = *strct.pdata
   IF n_elements(cnts) NE 8 THEN BEGIN
      dprint,'Bad size: '+$
             string(n_elements(cnts))+ $
             ' instead of 8'
      return
   ENDIF
   tot = total(cnts)
   strct.nrg_spec   = tot
   strct.def_spec   = cnts
   strct.mass_spec  = tot
   strct.anode_spec = tot
   strct2 = {gap:strct.gap,$
             time:strct.time, $
             spec1:strct.def_spec}
   IF self.save_raw && self.prod_08D THEN $
    self.prod_08D.append, strct2
   return
END



;;-----------------------------------------------;;
;;                     32E                       ;;
;;-----------------------------------------------;;
PRO spp_swp_spi_prod_apdat::prod_32E, strct
   pname = '32E_'
   cnts  = *strct.pdata
   IF n_elements(cnts) NE 32 THEN BEGIN
      dprint,'Bad size: '+$
             string(n_elements(cnts))+ $
             ' instead of 32'
      return
   ENDIF
   tot = total(cnts)
   strct.nrg_spec   = cnts
   strct.def_spec   = tot
   strct.mass_spec  = tot
   strct.anode_spec = tot
   strct2 = {gap:strct.gap,$
             time:strct.time, $
             spec1:strct.nrg_spec}
   IF self.save_raw && self.prod_32E THEN $
    self.prod_32E.append, strct2
   return
END



;;-----------------------------------------------;;
;;                   08Dx16A                     ;;
;;-----------------------------------------------;;
PRO spp_swp_spi_prod_apdat::prod_08Dx16A, strct
   pname = '08Dx16A_'
   cnts  = *strct.pdata
   IF n_elements(cnts) NE 128 THEN BEGIN
      dprint,'Bad size: '+$
             string(n_elements(cnts))+ $
             ' instead of 128'
      return
   ENDIF
   cnts  = reform(cnts,8,16,/overwrite)
   tot = total(cnts)
   strct.nrg_spec   = tot
   strct.def_spec   = total(cnts,2)
   strct.mass_spec  = tot
   strct.anode_spec = total(cnts,1)
   strct2 = {gap:strct.gap,$
             time:strct.time, $
             spec1:strct.nrg_spec}
   IF self.save_raw && self.prod_32E THEN $
    self.prod_32E.append, strct2
   return
END



;;-----------------------------------------------;;
;;                   32Ex16A                     ;;
;;-----------------------------------------------;;
PRO spp_swp_spi_prod_apdat::prod_32Ex16A, strct
   pname = '32Ex16A_'
   cnts  = *strct.pdata
   if n_elements(cnts) ne 512 then begin
      dprint,'Bad size: '+$
             string(n_elements(cnts))+ $
             ' instead of 512'
      return
   endif
   cnts  = reform(cnts,32,16,/overwrite)
   tot = total(cnts)
   strct.nrg_spec   = total(cnts,2)
   strct.def_spec   = tot
   strct.mass_spec  = tot
   strct.anode_spec = total(cnts,1)
   strct2 = {gap:strct.gap,$
             time:strct.time,$
             spec1:strct.nrg,$
             spec2:strct.anode}
   if self.save_raw && self.prod_32Ex16A then $
    self.prod_32Ex16A.append,strct2
END



;;-----------------------------------------------;;
;;                   32Ex16M                     ;;
;;-----------------------------------------------;;
;; This function needs fixing
PRO spp_swp_spi_prod_apdat::prod_32Ex16M, strct
   cnts = *strct.pdata
   IF n_elements(cnts) NE 512 THEN BEGIN
      dprint,'[32Ex16M] Bad size: '+$
             string(n_elements(data))+ $
             ' instead of 512'
      return
   ENDIF
;   printdat,strct
   pname = '32Ex16M_'
   data = *strct.pdata
   data = reform(data,32,16,/overwrite)
   spec1 = total(data,1)
   spec2 = total(data,2 )
   strct2 = {time:strct.time, $
             spec1:spec1, $
             spec2:spec2, $
             gap: strct.gap}
   ;;cnts             = reform(/overwrite,cnts,8,32,16)
   ;;strct.nrg_spec   = total(  total( cnts, 1 ),2)
   ;;strct.def_spec   = total(reform(/overwrite,cnts,8,32*16),2)
   ;;strct.mass_spec  = 
   ;;strct.anode_spec = total(reform(/overwrite,cnts,8*32,16),1)
   ;;strct.nrg_spec = spec2
   ;;strct.mass_spec = spec1
   if self.save_raw && self.prod_32Ex16M then $
    self.prod_32Ex16M.append,strct2
   ;; self.store_data, strct2, pname
END



;;-----------------------------------------------;;
;;                 08Dx32Ex16A                   ;;
;;-----------------------------------------------;;
;; This function needs fixing
PRO spp_swp_spi_prod_apdat::prod_08Dx32Ex16A, strct   
   cnts = *strct.pdata
   IF n_elements(cnts) NE 4096 THEN BEGIN
      dprint,'Bad size: '+$
             string(n_elements(cnts))+ $
             ' instead of 4096'
      return
   ENDIF
   pname = '08Dx32Ex16A_'
   ;;cnts             = reform(/overwrite,cnts,8,32,16)
   ;;strct.nrg_spec   = total(  total( cnts, 1 ),2)
   ;;strct.def_spec   = total(reform(/overwrite,cnts,8,32*16),2)
   ;;strct.mass_spec  = 
   ;;strct.anode_spec = total(reform(/overwrite,cnts,8*32,16),1)

   strct2 = {time:strct.time,$  
             cnts:cnts,$
             gap: strct.gap}
   IF self.save_raw && self.prod_08Dx32Ex16A THEN $
    self.prod_08Dx32Ex16A.append, strct2
END



;;-----------------------------------------------;;
;;                 32Ex16Ax4M                    ;;
;;-----------------------------------------------;;
;; This function needs fixing
PRO spp_swp_spi_prod_apdat::prod_32Ex16Ax4M, strct  
   cnts = *strct.pdata
   if n_elements(cnts) ne 2048 then begin
      dprint,'Bad size: '+$
             string(n_elements(cnts))+ $
             ' instead of 2048'
      return
   endif
   pname = '32Ex16Ax4M_'
   ;;strct.nrg_spec   = total( reform(/overwrite,cnts,32,16*4), 2 )
   ;;strct.def_spec   = 
   ;;strct.mass_spec  = total( reform(/overwrite,cnts,32*16,4), 1 )
   ;;strct.anode_spec = total( total(reform(/overwrite,cnts,32,16,4),1), 2)
   cnts = reform(/overwrite,cnts,32,16,4)
   ;; Add more in the future
   strct2 = {time:strct.time, $  
             cnts:cnts, $
             gap: strct.gap}
   if self.save_raw && self.prod_32Ex16Ax4M then $
    self.prod_32Ex16Ax4M.append, strct2
   ;;self.store_data, strct2, pname
END



;;-----------------------------------------------;;
;;               08Dx32Ex16Ax4M                  ;;
;;-----------------------------------------------;;
;; This function needs fixing
PRO spp_swp_spi_prod_apdat::prod_08Dx32EX16Ax2M, strct   
   cnts = *strct.pdata
   if n_elements(cnts) ne 8192 then begin
      dprint,'Bad size: '+$
             string(n_elements(data))+ $
             ' instead of 8192'
      return
   endif
   pname = '08Dx32Ex16Ax2M_'
   cnts = reform(cnts,8,32,16,2,/overwrite)
   strct2 = {time:strct.time, $ 
             cnts:cnts, $
             gap: strct.gap}
   strct.nrg_spec   = total( total(cnts,1), 2 )
   strct.def_spec   = total( total(cnts,2) ,2)
   strct.mass_spec  = total(cnts,1)
   strct.anode_spec = total( reform(cnts,8*32,16) , 1)
   if self.save_raw && self.prod_08Dx32Ex16Ax2M then $
    self.prod_08Dx32Ex16Ax2M.append, strct2
END



;;-----------------------------------------------;;
;;                   16Ax16M                     ;;
;;-----------------------------------------------;;
;; This function needs fixing
PRO spp_swp_spi_prod_apdat::prod_16Ax16M, strct
   cnts = *strct.pdata
   if n_elements(cnts) ne 256 then begin
      dprint,'Bad size: '+$
             string(n_elements(cnts))+ $
             ' instead of 256'
      return
   endif
   pname = '16Ax16M_'
   cnts = reform(cnts,16,16,/over)
   ;; Add more in the future
   strct2 = {time:strct.time, $  
             cnts:cnts, $
             gap: strct.gap}
   strct.anode_spec =  total(cnts,2)
   strct.mass_spec =  total(cnts,1) 
   if self.save_raw && self.prod_16Ax16m.append then $
    self.prod_16Ax16m.append, strct2
END 



;;-----------------------------------------------;;
;;                   08Dx32E                     ;;
;;-----------------------------------------------;;
;; This function needs fixing
PRO spp_swp_spi_prod_apdat::prod_8Dx32E, strct
   cnts = *strct.pdata
   IF n_elements(cnts) NE 256 THEN BEGIN
      dprint,'Bad size: '+$
             string(n_elements(cnts))+ $
             ' instead of 256'
      return
   ENDIF
   pname = '08Dx32E_'
   cnts = reform(cnts,256)
   cnts2 = reform(cnts,8,32,/over)
   ;; Add more in the future
   strct2 = {time:strct.time, $ 
             cnts:cnts,  $
             cnts2:cnts2,$
             gap: strct.gap}
   strct.def_spec = total(cnts,2)
   strct.nrg_spec = total(cnts,1) 
   strct.full_spec = cnts
   IF self.save_raw && self.prod_08Dx32E.append THEN $
    self.prod_08Dx32E.append, strct2
END 



FUNCTION spp_swp_spi_prod_apdat::decom,ccsds,ptp_header

   ;; Check CCSDS Packet Size
   pksize = ccsds.pkt_size
   IF pksize LE 20 THEN BEGIN
      dprint,dlevel = 2, 'size error - no data ',ccsds.pkt_size,ccsds.apid
      return, 0
   ENDIF

   ;; Check CCSDS Size Match
   ccsds_data = spp_swp_ccsds_data(ccsds)
   IF pksize NE n_elements(ccsds_data) THEN BEGIN
      dprint,dlevel=1,'Product size mismatch'
      return,0
   ENDIF

   ;; Parse Header
   ns       = pksize - 20
   header   = ccsds_data[0:19]
   log_flag = header[12]
   mode1    = header[13]
   mode2    = (swap_endian(uint(ccsds_data,14),/swap_if_little_endian))
   f0       = (swap_endian(uint(header,16),/swap_if_little_endian))
   status_flag = header[18]
   peak_bin    = header[19]
   compression = (header[12] and 'a0'x) ne 0
   bps  =  ([4,1])[ compression ]
   ndat = ns / bps

   IF ns GT 0 THEN BEGIN
      data      = ccsds_data[20:*]
      ;; data_size = n_elements(data)
      if compression then cnts = spp_swp_log_decomp(data,0) $
      else cnts = swap_endian(ulong(data,0,ndat) ,/swap_if_little_endian )
      tcnts = total(cnts)
   ENDIF ELSE BEGIN
      tcnts = -1.
      cnts = 0
   ENDELSE 

   str = { $

         time:        ccsds.time,$
         apid:        ccsds.apid,$
         time_delta:  ccsds.time_delta,$
         seqn:        ccsds.seqn,$
         seqn_delta:  ccsds.seqn_delta,$
         seq_group:   ccsds.seq_group,$
         pkt_size:    ccsds.pkt_size,$
         gap:         ccsds.gap,$

         f0:          f0,$
         datasize:    ns,$
         ndat:        ndat,$
         mode1:       mode1,$
         mode2:       mode2,$
         log_flag:    log_flag,$
         status_flag: status_flag,$

         moms:        lonarr(104),$
   
         cnts:        tcnts,$
         peak_bin:    peak_bin,$
         nrg_spec:    fltarr(32),$
         def_spec:    fltarr(8),$
         mass_spec:   fltarr(32),$
         full_spec:   fltarr(256),$
         anode_spec:  fltarr(16),$
         pdata:       ptr_new(cnts)}

   return,str

END



PRO spp_swp_spi_prod_apdat::handler,ccsds,ptp_header

   strct = self.decom(ccsds)
   ns=1
   IF keyword_set(strct) && ns gt 0 THEN BEGIN
      CASE strct.ndat OF
         16:self.prod_16A,             strct
         32:self.prod_32E,             strct
         128:self.prod_08Dx16A,        strct
         256:self.prod_08Dx32E,        strct
         ;;256: self.prod_16Ax16M,       strct
         512:self.prod_32Ex16M,        strct
         ;;512:self.prod_32Ex16A,        strct
         2048:self.prod_32Ex16Ax4M,    strct
         4096:self.prod_08Dx32Ex16A,    strct
         8192:self.prod_08Dx32EX16Ax2M, strct
         else: dprint,dlevel=4,'Size not recognized: ',strct.ndat
      ENDCASE
   endif
   ;; dprint,dlevel=2,strct.apid,strct.ndat
   if self.save_flag && keyword_set(strct) then begin
      dprint,self.name,dlevel=5,self.apid
      self.data.append, strct
   endif
   if self.rt_flag && keyword_set(strct) then begin
      if ccsds.gap eq 1 then strct = [fill_nan(strct[0]),strct]
      store_data,self.tname, data=strct, $
                 tagnames=self.ttags, $
                 append = 1,$
                 gap_tag='GAP'
   ENDIF
END

FUNCTION spp_swp_spi_prod_apdat::Init,apid,name,_EXTRA=ex
   ;; Call our superclass Initialization method.
   void = self->spp_gen_apdat::Init(apid,name)   
   ;; Set to 1 to save full 3 or 4 Dimensions of raw data
   self.save_raw = 0
   self.prod_16A            = obj_new('dynamicarray',name='prod_16A')
   self.prod_08Dx32E        = obj_new('dynamicarray',name='prod_08Dx32E')
   self.prod_16Ax16M        = obj_new('dynamicarray',name='prod_16Ax16M')
   self.prod_32Ex16A        = obj_new('dynamicarray',name='prod_32Ex16A')
   self.prod_32Ex16M        = obj_new('dynamicarray',name='prod_32Ex16M')
   self.prod_08Dx32Ex16A    = obj_new('dynamicarray',name='prod_08Dx32Ex16A')
   self.prod_32Ex16Ax4M     = obj_new('dynamicarray',name='prod_32Ex16Ax4M')
   self.prod_08Dx32EX16Ax1M = obj_new('dynamicarray',name='prod_08Dx32EX16Ax1M')
   self.prod_08Dx32EX16Ax2M = obj_new('dynamicarray',name='prod_08Dx32EX16Ax2M')
   RETURN, 1
END

PRO spp_swp_spi_prod_apdat::Clear
   self->spp_gen_apdat::Clear
   self.prod_16A.array            = !null
   self.prod_16Ax16M.array        = !null
   self.prod_08Dx32E.array        = !null
   self.prod_32Ex16A.array        = !null
   self.prod_32Ex16M.array        = !null
   self.prod_08Dx32Ex16A.array    = !null
   self.prod_32Ex16Ax4M.array     = !null
   self.prod_08Dx32EX16Ax1M.array = !null
   self.prod_08Dx32EX16Ax2M.array = !null
END

PRO spp_swp_spi_prod_apdat__define

   void = {spp_swp_spi_prod_apdat, $
           ;; Superclass
           inherits spp_gen_apdat,$ 
           save_raw: 0b,$
           prod_16A:            obj_new(),$
           prod_08Dx32E:        obj_new(),$
           prod_16Ax16M:        obj_new(),$
           prod_32Ex16A:        obj_new(),$
           prod_32Ex16M:        obj_new(),$
           prod_08Dx32Ex16A:    obj_new(),$
           prod_32Ex16Ax4M:     obj_new(),$
           prod_08Dx32EX16Ax1M: obj_new(),$
           prod_08Dx32EX16Ax2M: obj_new() $
          }
END










;;PRO spp_swp_spi_prod_apdat::finish
;;   store_data,self.tname, data=self.data.array, $
;;              tagnames=self.ttags,$
;;              gap_tag='GAP',$
;;              verbose=0
;;END 


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


;;-----------------------------------------------;;
;;               08Dx32Ex16Ax1M                  ;;
;;-----------------------------------------------;;
;; This function needs fixing
;pro spp_swp_spi_prod_apdat::prod_8Dx32Ex16Ax1M, strct   
;  if n_elements(data) ne 4096 then begin
;    dprint,'bad size'
;    return
;  endif
;  pname = '8Dx32Ex16Ax1M_'
;
;  cnts = *strct.pdata
;
;  cnts = reform(cnts,8,32,16,/over)
;
;  strct2 = {time:strct.time, $  ; add more in the future
;    cnts:cnts, $
;    gap: strct.gap}
;
;  strct.anode_spec = total( reform(cnts,8*32,16) , 1)
;  strct.nrg_spec =  total( total(cnts,1), 2 )
;  strct.def_spec =  total( total(cnts,2) ,2)
;  strct.mass_spec =  total(cnts,1)
;
;  if self.save_raw  && self.prod_8Dx32Ex16Ax1M then $
;   self.prod_8Dx32Ex16Ax1M.append, strct2
;end


