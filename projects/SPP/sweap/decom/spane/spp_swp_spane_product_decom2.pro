; $LastChangedBy: phyllisw2 $
; $LastChangedDate: 2018-10-02 16:22:53 -0700 (Tue, 02 Oct 2018) $
; $LastChangedRevision: 25889 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/decom/spane/spp_swp_spane_product_decom2.pro $

;; --------NOTE THIS IS REPLACED WITH SPP_SWP_PROD_APDAT__DEFINE-------- ;;

function spp_swp_spane_16A, data, header_str=header_str, apdat=apdat,pname=pname

pname = '16A_'
strct = {time:header_str.time, $
         SPEC:float(data),  $
         gap: 0}

;if apdat.rt_flag && apdat.rt_tags then begin
;  ;if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
;  store_data,apdat.tname+pname,data=strct, tagnames=apdat.rt_tags, /append
;endif
return,strct
end

function spp_swp_spane_32E, data, header_str=header_str, apdat=apdat,pname=pname

  pname = '32E_'
  strct = {time:header_str.time, $
    SPEC:float(data),  $
    gap: 0}

  ;if apdat.rt_flag && apdat.rt_tags then begin
  ;  ;if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
  ;  store_data,apdat.tname+pname,data=strct, tagnames=apdat.rt_tags, /append
  ;endif
  return,strct
end

function spp_swp_spane_8Dx32E, data, header_str=header_str, apdat=apdat,pname=pname
  pname = '8Dx32E_'
  
  spec1 = total(reform(data,8*32),2)
  spec2 = total( total(reform(data,8,32),1) ,2 )

  strct = {time:header_str.time, $
    spec1:spec1, $
    spec2:spec2, $
    gap: 0}
    
  ;  if apdat.rt_flag && apdat.rt_tags then begin
  ;    ;if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
  ;    store_data,apdat.tname+pname,data=strct, tagnames=apdat.rt_tags, /append
  ;  endif
  return, strct

end

;;----------------------------------------------
;;Product Full Sweep: Archive - 32Ex16A - '361'x

function spp_swp_spane_16Ax32E, data, header_str=header_str, apdat=apdat,pname=pname
  pname = '16Ax32E_'
  strct = {time:header_str.time, $
    cnts_Anode:float(data),  $
    gap: 0}

;  if apdat.rt_flag && apdat.rt_tags then begin
;    ;if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
;    store_data,apdat.tname+pname,data=strct, tagnames=apdat.rt_tags, /append
;  endif
  return, strct

end


function spp_swp_spane_16Ax8Dx32E, data, header_str=header_str, apdat=apdat ,pname=pname  ; this function needs fixing

  pname = '16Ax8Dx32E_'
  if n_elements(data) ne 4096 then begin
    dprint,'bad size'
    return,0
  endif
    
  spec1 = total(reform(data,16,8*32),2)
  spec2 = total( total(reform(data,16,8,32),1) ,2 )
  spec3 = total(reform(data,16*8,32),1)
  spec23 = total(reform(data,16,8*32),1)
   
  strct = {time:header_str.time, $
    spec1:spec1, $
    spec2:spec2, $
    spec3:spec3, $
    spec23:spec23, $
    gap: 0}

;  if apdat.rt_flag && apdat.rt_tags then begin
;    ;if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
;    store_data,apdat.tname+pname,data=strct, tagnames=apdat.rt_tags, /append
;  endif
  
  return,strct
end





function spp_swp_spane_product_decom2, ccsds, ptp_header=ptp_header, apdat=apdat

  if isa(apdat.data,'dynamicarray') && apdat.data.size eq 0  then begin    ; initialization
    hdr = dynamicarray(name='hdr_')
    a0016 = dynamicarray(name='16A_')
    a0032 = dynamicarray(name='32E_')
    a0256 = dynamicarray(name='16Ax32E_')
    a0512 = dynamicarray(name='16Ax32E_')
    a4096 = dynamicarray(name='16Ax8Dx32E_') 
    apdat.data.append, [hdr,a0016,a0032,a00256,a0512,a4096]
  endif else if isa(apdat.data) then begin
    darrays = apdat.data.array
    hdr = darrays[0]
    a0016 = darrays[1]
    a0032 = darrays[4]
    a0256 = darrays[5]
    a0512 = darrays[2]
    a4096 = darrays[3]
  endif

;  struct_arrays = *apdat.dataptr


;  if n_params() eq 0 then begin    ; This will get called after the file is loaded to save parameters in tplot.
;    ;printdat,struct_arrays
;    if ptr_valid(apdat.dataptr) then begin
;      struct_arrays = *apdat.dataptr
;      store_data,apdat.tname,data= struct_arrays.hdr.array,tagnames= apdat.tfields
;      store_data,apdat.tname+struct_arrays.a0016.name,data= struct_arrays.a0016.array, tagnames= '*'
;      store_data,apdat.tname+struct_arrays.a0512.name,data= struct_arrays.a0512.array, tagnames= '*'
;      store_data,apdat.tname+struct_arrays.a4096.name,data= struct_arrays.a4096.array, tagnames= '*'
;    endif
;    return, !null
;  endif

  ;;-------------------------------------------
  ;; Parse data
  
  pksize = ccsds.pkt_size
  if pksize le 20 then begin
    dprint,dlevel = 2, 'size error - no data'
    return, 0
  endif
  
  ccsds_data = spp_swp_ccsds_data(ccsds)  
  
  if pksize ne n_elements(ccsds_data) then begin
    dprint,dlevel=1,'Product size mismatch', n_elements(ccsds_data)
    return,0
  endif

  header    = ccsds_data[0:19]
  ns = pksize - 20   
  log_flag    = header[12]
  mode1 = header[13]
  mode2 = (swap_endian(uint(ccsds_data,14) ,/swap_if_little_endian ))
  f0 = (swap_endian(uint(header,16), /swap_if_little_endian))
  status_flag = header[18]
  peak_bin = header[19]

;  if ptr_valid(apdat.last_ccsds) && keyword_set(*apdat.last_ccsds) then  delta_t = ccsds.time - (*(apdat.last_ccsds)).time else delta_t = !values.f_nan

  compression = (header[12] and 'a0'x) ne 0
  bps =  ([4,1])[ compression ]
  
  ndat = ns / bps
  if ndat * bps ne ns then begin
    dprint,'decom error',dlevel=2
    return, 0
  endif

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
;    datasize:    ns, $
    log_flag:    log_flag, $
    mode1:        mode1,  $
    mode2:        mode2,  $
    f0:           f0,$
    status_flag: status_flag,$
    peak_bin:    peak_bin, $
    cnts_total:  tcnts,  $
;    pdata:        ptr_new(data), $
    gap:         ccsds.gap  }
    
    printdat, tcnts

  spp_save_data,hdr,str,apdat=apdat,pname='hdr_'

  res = 0
  case ndat  of
    16: begin
       res = spp_swp_spane_16A(cnts, header_str=str, apdat=apdat,pname=pname)
       spp_save_data,a0016,res,apdat=apdat,pname=pname
    end
    32: begin
       res = spp_swp_spane_32E(cnts, header_str=str, apdat=apdat,pname=pname)
       spp_save_data,a0032,res,apdat=apdat,pname=pname
    end
    256: begin
        res = spp_swp_spane_8Dx32E(cnts, header_str=str, apdat=apdat,pname=pname)
      spp_save_data,a0256,res,apdat=apdat,pname=pname
    end
    512: begin
        res = spp_swp_spane_16Ax32E(cnts, header_str=str, apdat=apdat,pname=pname)
        spp_save_data,a0512,res,apdat=apdat,pname=pname
    end
    4096: begin
       res = spp_swp_spane_16Ax8Dx32E(cnts, header_str=str, apdat=apdat,pname=pname)
       spp_save_data,a4096,res,apdat=apdat,pname=pname
    end
    else:  if debug(2,msg='Unknown data size') then begin
        hexprint,header
        dprint,dlevel=2,'Size: ',ndat,' compression: ',compression
      endif
  endcase

  
  return, 0


end
