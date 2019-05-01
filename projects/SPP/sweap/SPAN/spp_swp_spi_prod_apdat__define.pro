;+
;
; SPP_SWP_SPI_PROD_APDAT
;
; APID: 0x380-0x3AF
; Descritpion: SPAN-Ai Science Packet
; Size: Vairable
;
;----------------------------------------------
; Byte  |   Bits   |        Data Value
;----------------------------------------------
;   0   | 00001aaa | ApID Upper Byte
;   1   | aaaaaaaa | ApID Lower Byte
;   2   | 11cccccc | Sequence Count Upper Byte
;   3   | cccccccc | Sequence Count Lower Byte
;   4   | LLLLLLLL | Message Length Upper Byte
;   5   | LLLLLLLL | Message Length Lower Byte
;   6   | MMMMMMMM | MET Byte 5
;   7   | MMMMMMMM | MET Byte 4
;   8   | MMMMMMMM | MET Byte 3
;   9   | MMMMMMMM | MET Byte 2
;  10   | ssssssss | MET Byte 1 [subseconds]
;  11   | ssssssss | s = MET subseconds
;       |          | x = Cycle Count LSBs
;       |          |     (sub NYS Indicator)
;  12   | LTCSNNNN | L = Log Compressed
;       |          | T = No Targeted Sweep
;       |          | C = Compress/Truncate TOF
;       |          | S = Summing
;       |          | N = 2^N Sum/Sample Period
;  13   | QQQQQQQQ | Spare
;  14   | mmmmmmmm | Mode ID Upper Byte
;  15   | mmmmmmmm | Mode ID Lower Byte
;  16   | FFFFFFFF | F0 Counter Upper Byte
;  17   | FFFFFFFF | F0 Counter Lower Byte
;  18   | AAtHDDDD | A = Attenuator State
;       |          | t = Test Pulser
;       |          | H = HV Enable
;       |          | D = HV Mode
;  19   | XXXXXXXX | X = Peak Count Step
;
; 20 - ???
; --------
; Science Product Data
;
;
;
; spp_swp_spi_prod_apdat
; $LastChangedBy: rlivi2 $
; $LastChangedDate: 2019-04-30 16:27:37 -0700 (Tue, 30 Apr 2019) $
; $LastChangedRevision: 27155 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/spp_swp_spi_prod_apdat__define.pro $
;-



;;-----------------------------------------------;;
;;                     08D                       ;;
;;-----------------------------------------------;;
PRO spp_swp_spi_prod_apdat::proc_08D, strct
   pname = '08D_'
   cnts  = *strct.pdata
   IF n_elements(cnts) NE 8 THEN BEGIN
      dprint,'Bad size: '+$
             string(n_elements(cnts))+ $
             ' instead of 8'
      return
   ENDIF
   tot = total(cnts)
   strct.nrg_spec = tot
   strct.def_spec = cnts
   strct.mas_spec = tot
   strct.ano_spec = tot
   strct2 = {gap:strct.gap,$
             time:strct.time, $
             spec1:strct.def_spec}
   IF self.save_raw && self.prod_08D THEN $
    self.prod_08D.append, strct2
   return
END

;;-----------------------------------------------;;
;;                     16A                       ;;
;;-----------------------------------------------;;
PRO spp_swp_spi_prod_apdat::proc_16A, strct
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
   self.prod_16A.append, strct2
END

;;-----------------------------------------------;;
;;                     32E                       ;;
;;-----------------------------------------------;;
PRO spp_swp_spi_prod_apdat::proc_32E, strct
   pname = '32E_'
   cnts  = *strct.pdata
   IF n_elements(cnts) NE 32 THEN BEGIN
      dprint,'Bad size: '+$
             string(n_elements(cnts))+ $
             ' instead of 32'
      return
   ENDIF
   tot = total(cnts)
   strct.nrg_spec = cnts
   strct.def_spec = tot
   strct.mas_spec = tot
   strct.ano_spec = tot
   strct2 = {gap:strct.gap,$
             time:strct.time, $
             spec1:strct.nrg_spec}
   self.prod_32E.append, strct2
END

;;-----------------------------------------------;;
;;                   08Dx16A                     ;;
;;-----------------------------------------------;;
PRO spp_swp_spi_prod_apdat::proc_08Dx16A, strct
   cnts  = *strct.pdata
   IF n_elements(cnts) NE 128 THEN BEGIN
      dprint,'Bad size: '+$
             string(n_elements(cnts))+ $
             ' instead of 128'
      return
   ENDIF
   pname = '08Dx16A_'
   cnts = reform(cnts,8,16,/overwrite)
   tot  = total(cnts)
   strct.nrg_spec = tot
   strct.def_spec = total(cnts,2)
   strct.mas_spec = tot
   strct.ano_spec = total(cnts,1)
   strct2 = {gap:strct.gap,$
             time:strct.time, $
             cnts:cnts}
   self.prod_08Dx16A.append, strct2
END

;;-----------------------------------------------;;
;;                   08Dx32E                     ;;
;;-----------------------------------------------;;
PRO spp_swp_spi_prod_apdat::proc_08Dx32E, strct
   pname = '08Dx32E_'
   cnts  = *strct.pdata
   IF n_elements(cnts) NE 256 THEN BEGIN
      dprint,'Bad size: '+$
             string(n_elements(cnts))+ $
             ' instead of 256'
      return
   ENDIF
   cnts  = reform(cnts,8,32,/overwrite)
   strct.def_spec = total(cnts,2)
   strct.nrg_spec = total(cnts,1)
   strct.mas_spec = total(cnts)
   strct.ano_spec = total(cnts)
   strct2 = {gap:strct.gap,$
             time:strct.time, $
             def_spec:strct.def_spec,$
             nrg_spec:strct.nrg_spec,$
             mas_spec:strct.mas_spec,$
             ano_spec:strct.ano_spec,$
             cnts:cnts}
   self.prod_08Dx32E.append, strct2
END

;;-----------------------------------------------;;
;;                   32Ex16A                     ;;
;;-----------------------------------------------;;
PRO spp_swp_spi_prod_apdat::proc_32Ex16A, strct
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
   strct.def_spec = tot
   strct.nrg_spec = total(cnts,2)
   strct.mas_spec = tot
   strct.ano_spec = total(cnts,1)
   strct2 = {gap:strct.gap,$
             cnts:cnts,$
             def_spec:strct.def_spec,$
             nrg_spec:strct.nrg_spec,$
             mas_spec:strct.mas_spec,$
             ano_spec:strct.ano_spec,$
             time:strct.time}
   self.prod_32Ex16A.append,strct2
END

;;-----------------------------------------------;;
;;                                               ;;
;;-----------------------------------------------;;
PRO spp_swp_spi_prod_apdat::proc_256, strct
   pname = '256'
   cnts  = *strct.pdata
   if n_elements(cnts) ne 256 then begin
      dprint,'Bad size: '+$
             string(n_elements(cnts))+ $
             ' instead of 256'
      return
   endif
   cnts  = reform(cnts,16,16,/overwrite)
   tot = total(cnts)
   strct.nrg_spec   = total(cnts,2)
   strct.def_spec   = tot
   strct.mass_spec  = tot
   strct.anode_spec = total(cnts,1)
   strct2 = {gap:strct.gap,$
             time:strct.time,$
             cnts:cnts}
   self.prod_256.append,strct2
END

;;-----------------------------------------------;;
;;                   32Ex16M                     ;;
;;-----------------------------------------------;;
PRO spp_swp_spi_prod_apdat::proc_32Ex16M, strct
   cnts = *strct.pdata
   IF n_elements(cnts) NE 512 THEN BEGIN
      dprint,'Bad size: '+$
             string(n_elements(data))+ $
             ' instead of 512'
      return
   ENDIF
   pname = '32Ex16M_'
   cnts = reform(/overwrite,cnts,32,16)
   strct.nrg_spec = total(cnts,2)
   strct.def_spec = total(cnts)
   strct.mas_spec = total(cnts,1)
   strct.ano_spec = total(cnts)
   strct2 = {time:strct.time, $
             cnts:cnts, $
             def_spec:strct.def_spec,$
             nrg_spec:strct.nrg_spec,$
             mas_spec:strct.mas_spec,$
             ano_spec:strct.ano_spec,$
             gap: strct.gap}
   self.prod_32Ex16M.append,strct2
END

;;-----------------------------------------------;;
;;                 08Dx32Ex08A                   ;;
;;-----------------------------------------------;;
PRO spp_swp_spi_prod_apdat::proc_08Dx32Ex08A, strct   
   cnts = *strct.pdata
   IF n_elements(cnts) NE 2048 THEN BEGIN
      dprint,'Bad size: '+$
             string(n_elements(cnts))+ $
             ' instead of 2048'
      return
   ENDIF
   pname = '08Dx32Ex08A_'
   cnts  = reform(/overwrite,cnts,8,32,8)
   strct.def_spec  = total(total(cnts,2),2)
   strct.nrg_spec  = total(total(cnts,1),2)
   strct.mas_spec  = total(cnts)
   strct.ano_spec  = total(total(cnts,1),1)
   strct2 = {time:strct.time,$  
             cnts:cnts,$
             def_spec:strct.def_spec,$
             nrg_spec:strct.nrg_spec,$
             mas_spec:strct.mas_spec,$
             ano_spec:strct.ano_spec,$
             gap: strct.gap}
   self.prod_08Dx32Ex08A.append, strct2
END

;;-----------------------------------------------;;
;;                 08Dx32Ex16A                   ;;
;;-----------------------------------------------;;
PRO spp_swp_spi_prod_apdat::proc_08Dx32Ex16A, strct   
   cnts = *strct.pdata
   IF n_elements(cnts) NE 4096 THEN BEGIN
      dprint,'Bad size: '+$
             string(n_elements(cnts))+ $
             ' instead of 4096'
      return
   ENDIF
   pname = '08Dx32Ex16A_'
   cnts  = reform(/overwrite,cnts,8,32,16)
   strct.def_spec = total(total(cnts,2),2)
   strct.nrg_spec = total(total(cnts,1),2)
   strct.mas_spec = total(cnts)
   strct.ano_spec = total(total(cnts,1),1)
   strct2 = {time:strct.time,$  
             cnts:cnts,$
             gap: strct.gap}
   self.prod_08Dx32Ex16A.append, strct2
END

;;-----------------------------------------------;;
;;                 32Ex16Ax04M                   ;;
;;-----------------------------------------------;;
PRO spp_swp_spi_prod_apdat::proc_32Ex16Ax04M, strct  
   cnts = *strct.pdata
   if n_elements(cnts) ne 2048 then begin
      dprint,'Bad size: '+$
             string(n_elements(cnts))+ $
             ' instead of 2048'
      return
   endif
   pname = '32Ex16Ax04M_'
   cnts = reform(/overwrite,cnts,32,16*4)
   strct.nrg_spec = total(total(cnts,2),2)
   strct.def_spec = total(cnts)
   strct.mas_spec = total(total(cnts,1),1)
   strct.ano_spec = total(total(cnts,1),2)
   strct2 = {time:strct.time, $  
             cnts:cnts, $
             gap: strct.gap}
   self.prod_32Ex16Ax4M.append, strct2
END

;;-----------------------------------------------;;
;;               08Dx32Ex16Ax04M                 ;;
;;-----------------------------------------------;;
PRO spp_swp_spi_prod_apdat::proc_08Dx32EX16Ax2M, strct   
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
   strct.def_spec = total(total(cnts,2),2)
   strct.nrg_spec = total(total(cnts,1),2)
   strct.mas_spec = total(total(cnts,1),2)
   strct.ano_spec = total(total(cnts,1),2)
   self.prod_08Dx32Ex16Ax2M.append, strct2
END

;;-----------------------------------------------;;
;;                   16Ax16M                     ;;
;;-----------------------------------------------;;
PRO spp_swp_spi_prod_apdat::proc_16Ax16M, strct
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
   strct.mass_spec  =  total(cnts,1) 
   self.prod_16Ax16M.append, strct2
END 

FUNCTION spp_swp_spi_prod_apdat::decom,ccsds,source_dict=source_dict

   ;; Check CCSDS Packet Size
   pksize = ccsds.pkt_size
   IF pksize LE 20 THEN BEGIN
      dprint,dlevel = 2, 'size error - no data ',$
             ccsds.pkt_size,ccsds.apid
      return, !null
   ENDIF
   
   if ccsds.aggregate ne 0 then begin
     return, self.decom_aggregate(ccsds,source_dict=source_dict)
   endif

   ;; Check CCSDS Size Match
   ccsds_data = spp_swp_ccsds_data(ccsds)
   IF pksize NE n_elements(ccsds_data) THEN BEGIN
      dprint,dlevel=1,'Product size mismatch'
      return,!null
   ENDIF
   
   

   if 1 then begin    ; New merged method

     spp_swp_span_prod__define,str,ccsds

   endif else begin
     message,'Obsolete'

     if 0 && (abs(ccsds.time - 1.5363835e+09) lt 100) && (ccsds.apid eq '3a0'x) then begin
       timebar,ccsds.time
       stop
     endif

     ;; Parse Header
     ns = pksize - 20
     header = ccsds_data[0:19]
     log_flag = header[12]
     mode1 = header[13]
     mode2 = (swap_endian(uint(ccsds_data,14),/swap_if_little_endian))
     f0 = (swap_endian(uint(header,16),/swap_if_little_endian))
     status_bits = header[18]
     peak_bin = header[19]
     compression = (header[12] and 'a0'x) ne 0
     bps  =  ([4,1])[ compression ]
     ndat = ns / bps

     IF ns GT 0 THEN BEGIN
       data      = ccsds_data[20:*]
       if compression then cnts = float(spp_swp_log_decomp(data,0)) $
       else cnts = swap_endian(ulong(data,0,ndat) ,/swap_if_little_endian )
       tcnts = total(cnts)
     ENDIF ELSE BEGIN
       tcnts = -1.
       cnts = 0.
     ENDELSE

     emode2_ori = mode2
     if ccsds.time gt 1.5409458e+09 &&  ccsds.time lt 1.5422472e+09 then mode2 = uint('0025'x)
     tmode = mode2 and 'f'x
     emode = ishft(mode2,-4) and 'f'x
     ;   emode = emode_ori
     pmode = ishft(mode2,-8) and 'f'x
     mmode = ishft(mode2,-12) and 'f'x
     str = { $
       time:        ccsds.time,$
       met:         ccsds.met, $
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
       emode2_ori:   emode2_ori, $
       tmode:       tmode, $
       emode:       emode, $
       pmode:       pmode, $
       mmode:       mmode, $
       log_flag:    log_flag,$
       status_bits: status_bits,$
       cnts:        tcnts,$
       peak_bin:    peak_bin,$
       def_spec:    fltarr(8),$
       ano_spec:    fltarr(16),$
       nrg_spec:    fltarr(32),$
       mas_spec:    fltarr(16),$
       ;         ful_spec:    fltarr(256),$
       pdata:       ptr_new(cnts)}
    
   endelse

   return,str
END

PRO spp_swp_spi_prod_apdat::handler,ccsds,source_dict=source_dict

   strcts = self.decom(ccsds)
   if debug(self.dlevel+4,msg='hello') then begin
     dprint,self.apid
     ccsds_data = spp_swp_ccsds_data(ccsds)
     hexprint,ccsds_data
   endif

   ns=n_elements(strcts)
   for i=0,ns-1 do begin
      strct = strcts[i]
      CASE strct.ndat OF
         16:self.proc_16A, strct
         32:self.proc_32E, strct
         128:self.proc_08Dx16A, strct
         ;;256:self.proc_256, strct
         ;;256: self.proc_16Ax16M, strct
         256:self.proc_08Dx32E, strct
         512:self.proc_32Ex16M, strct
         ;;512:self.proc_32Ex16A,strct
         ;;2048:self.proc_32Ex16Ax04M, strct
         2048:self.proc_08Dx32Ex08A, strct
         4096:self.proc_08Dx32Ex16A, strct
         8192:self.proc_08Dx32EX16Ax2M, strct
         else: dprint,dlevel=4,'Size not recognized: ',strct.ndat
      ENDCASE
      strcts[i] = strct
   endfor

   if self.save_flag && keyword_set(strcts) then begin
      dprint,self.name,dlevel=5,self.apid
      self.data.append, strcts
   endif
   
   if self.rt_flag && keyword_set(strcts) then begin
      if ccsds.gap eq 1 then strcts = [fill_nan(strcts[0]),strcts]
      store_data,self.tname, data=strcts, $
                 tagnames=self.ttags, $
                 append = 1,$
                 gap_tag='GAP'
   ENDIF
   if keyword_set(strct) then  *self.last_data_p = strct
   
END

FUNCTION spp_swp_spi_prod_apdat::Init,apid,name,_EXTRA=ex
   ;; Call our superclass Initialization method.
   void = self->spp_gen_apdat::Init(apid,name)
   ;; Set to 1 to save full 3 or 4 Dimensions of raw data
   self.save_raw = 0
   self.prod_16A            = obj_new('dynamicarray',name='prod_16A')
   self.prod_32E            = obj_new('dynamicarray',name='prod_32E')
   self.prod_08Dx16A        = obj_new('dynamicarray',name='prod_08Dx16A')
   self.prod_08Dx32E        = obj_new('dynamicarray',name='prod_08Dx32E')
   self.prod_16Ax16M        = obj_new('dynamicarray',name='prod_16Ax16M')
   self.prod_256            = obj_new('dynamicarray',name='prod_256')
   self.prod_32Ex16A        = obj_new('dynamicarray',name='prod_32Ex16A')
   self.prod_32Ex16M        = obj_new('dynamicarray',name='prod_32Ex16M')
   self.prod_08Dx32Ex08A    = obj_new('dynamicarray',name='prod_08Dx32Ex08A')
   self.prod_08Dx32Ex16A    = obj_new('dynamicarray',name='prod_08Dx32Ex16A')
   self.prod_32Ex16Ax04M    = obj_new('dynamicarray',name='prod_32Ex16Ax04M')
   self.prod_08Dx32EX16Ax1M = obj_new('dynamicarray',name='prod_08Dx32EX16Ax1M')
   self.prod_08Dx32EX16Ax2M = obj_new('dynamicarray',name='prod_08Dx32EX16Ax2M')
   RETURN, 1
END

PRO spp_swp_spi_prod_apdat::Clear
   self->spp_gen_apdat::Clear
   self.prod_16A.array            = !null
   self.prod_32E.array            = !null
   self.prod_16Ax16M.array        = !null
   self.prod_256.array            = !null
   self.prod_08Dx16A.array        = !null
   self.prod_08Dx32E.array        = !null
   self.prod_32Ex16A.array        = !null
   self.prod_32Ex16M.array        = !null
   self.prod_08Dx32Ex08A.array    = !null
   self.prod_08Dx32Ex16A.array    = !null
   self.prod_32Ex16Ax04M.array    = !null
   self.prod_08Dx32EX16Ax1M.array = !null
   self.prod_08Dx32EX16Ax2M.array = !null
END

PRO spp_swp_spi_prod_apdat__define

   void = {spp_swp_spi_prod_apdat, $
           ;; Superclass
           inherits spp_gen_apdat,$ 
           save_raw: 0b,$
           prod_16A:            obj_new(),$    ; dynamic arrays to hold each type different type of product
           prod_32E:            obj_new(),$  
           prod_08Dx16A:        obj_new(),$
           prod_08Dx32E:        obj_new(),$
           prod_16Ax16M:        obj_new(),$
           prod_256:            obj_new(),$
           prod_32Ex16A:        obj_new(),$
           prod_32Ex16M:        obj_new(),$
           prod_08Dx32Ex08A:    obj_new(),$
           prod_08Dx32Ex16A:    obj_new(),$
           prod_32Ex16Ax04M:    obj_new(),$
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
;pro spp_swp_spi_prod_apdat::proc_8Dx32Ex16Ax1M, strct   
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


