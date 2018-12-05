; $LastChangedBy: davin-mac $
; $LastChangedDate: 2018-12-04 12:32:15 -0800 (Tue, 04 Dec 2018) $
; $LastChangedRevision: 26232 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/decom/spani/spp_swp_spani_product_decom2.pro $


function spp_swp_spani_16A, data, header_str=header_str, apdat=apdat

;printdat,data,header_str,apdat
pname = '16A_'
strct = {time:header_str.time, $
         SPEC:data,  $
         gap: 0}

;if  apdat.save && keyword_set(strct) then begin
;  ;if ccsds.gap eq 1 then append_array, *apdat.dataptr,
;  ;fill_nan(strct), index = *apdat.dataindex
;  append_array, *apdat.dataptr, strct, index = *apdat.dataindex
;endif
if apdat.rt_flag && apdat.ttags then begin
  ;if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
  store_data,apdat.tname+pname,data=strct, tagnames=apdat.ttags, /append
endif
return,0
end


;;----------------------------------------------
;;Product Full Sweep: Archive - 32Ex16A - 





function spp_swp_spani_32Ex16A, data, header_str=header_str, apdat=apdat
  pname = '32Ex16A_'
  strct = {time:header_str.time, $
    cnts_Anode:data,  $
    gap: 0}

  if apdat.rt_flag && apdat.ttags then begin
    ;if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
    store_data,apdat.tname+pname,data=strct, tagnames=apdat.ttags, /append
  endif

  data = reform(data,32,16,/overwrite)
  spec1 = total(data,2)
  spec2 = total(data,1 )

  strct = {time:header_str.time, $
    spec1:spec1, $
    spec2:spec2, $
    gap: 0}

  if apdat.rt_flag && apdat.ttags then begin
    ;if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
    store_data,apdat.tname+pname,data=strct, tagnames=apdat.ttags, /append
  endif

end




function spp_swp_spani_16Ax32E, data, header_str=header_str, apdat=apdat
message,'bad routine'
  pname = '16Ax32E_'
  strct = {time:header_str.time, $
    cnts_Anode:data,  $
    gap: 0}

  if apdat.rt_flag && apdat.ttags then begin
    ;if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
    store_data,apdat.tname+pname,data=strct, tagnames=apdat.ttags, /append
  endif


end


function spp_swp_spani_8Dx32Ex16A, data, header_str=header_str, apdat=apdat   ; this function needs fixing

  if n_elements(data) ne 4096 then begin
    dprint,'bad size'
    return,0
  endif
  pname = '8Dx32Ex16A_'
  spec1 = total(reform(data,16,8*32),2)   ; This is wrong
  spec2 = total( total(data,1) ,2 )      ;  This is wrong
  spec3 = total(reform(data,16*8,32),1)    ; This is wrong
  spec23 = total(reform(data,16,8*32),1)   ; this is wrong
  spec12 = total(reform(data,8*32,16),2)
  spec123 = reform(data,8*32*16) 
  
  strct = {time:header_str.time, $
    spec1:spec1, $
    spec2:spec2, $
    spec3:spec3, $
    spec23:spec23, $
    spec12:spec12, $
    spec123:spec123, $
    gap: 0}

  if apdat.rt_flag && apdat.ttags then begin
    ;if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
    store_data,apdat.tname+pname,data=strct, tagnames=apdat.ttags, /append
  endif

end



function spp_swp_spani_32Ex16Ax4M, data, header_str=header_str, apdat=apdat   ; this function needs fixing
  if n_elements(data) ne 2048 then begin
    dprint,'bad size'
    return,0
  endif
  pname = '32Ex16Ax4M_'
  data = reform(data,32,16,4,/overwrite)
  spec1 = total(reform(data,32,16*4),2)
  spec2 = total( total(data,1) ,2 )
  spec3 = total(reform(data,32*16,4),1)
  spec23 = total(reform(data,32,16*4),1)

  strct = {time:header_str.time, $
    spec1:spec1, $
    spec2:spec2, $
    spec3:spec3, $
    spec23:spec23, $
    gap: 0}

  if apdat.rt_flag && apdat.ttags then begin
    ;if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
    store_data,apdat.tname+pname,data=strct, tagnames=apdat.ttags, /append
  endif
end



function spp_swp_spani_8Dx32EX16Ax2M, data, header_str=header_str, apdat=apdat   ; this function needs fixing
  if n_elements(data) ne 8192 then begin
    dprint,'bad size'
    return,0
  endif
  pname = '8Dx32Ex16Ax2M_'
  data = reform(data,8,32,16,2,/overwrite)
  spec1 = total(reform(data,8,32*16*2),2)
  spec2 = total( total(data,1) ,2 )
  spec3 = total(total(reform(data,8*32,16,2),1) ,2)
  spec23 = total(total(reform(data,8,32*16,2),1), 2)
  
;  printdat,spec1,spec2,spec2,spec23

  strct = {time:header_str.time, $
    spec1:spec1, $
    spec2:spec2, $
    spec3:spec3, $
    spec23:spec23, $
    gap: 0}

  if apdat.rt_flag && apdat.ttags then begin
    ;if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
    store_data,apdat.tname+pname,data=strct, tagnames=apdat.ttags, /append
  endif
end



function spp_swp_spani_8Dx32Ex16Ax1M, data, header_str=header_str, apdat=apdat   ; this function needs fixing
  if n_elements(data) ne 4096 then begin
    dprint,'bad size'
    return,0
  endif
  pname = '8Dx32Ex16Ax1M_'
  data = reform(data,8,32,16,/overwrite)
  spec1 = total(reform(data,8,32*16),2)
  spec2 = total( total(data,1) ,2 )
  spec3 = total(reform(data,8*32,16),1)
  spec23 = total(reform(data,8,32*16),1)

  strct = {time:header_str.time, $
    spec1:spec1, $
    spec2:spec2, $
    spec3:spec3, $
    spec23:spec23, $
    gap: 0}

  if apdat.rt_flag && apdat.ttags then begin
    ;if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
    store_data,apdat.tname+pname,data=strct, tagnames=apdat.ttags, /append
  endif
end


function spp_swp_spani_16Ax16M, data, header_str=header_str, apdat=apdat   ; this function needs fixing
  if n_elements(data) ne 256 then begin
    dprint,'bad size'
    return,0
  endif
  pname = '16Ax16M_'
  data = reform(data,16,16,/overwrite)
  spec1 = total(data,2)
  spec2 = total(data,1 )

  strct = {time:header_str.time, $
    spec1:spec1, $
    spec2:spec2, $
    gap: 0}

  if apdat.rt_flag && apdat.ttags then begin
 ;   printdat,apdat.ttags
    ;if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
    store_data,apdat.tname+pname,data=strct, tagnames=apdat.ttags, /append
  endif
end




function spp_swp_spani_product_decom2, ccsds, ptp_header=ptp_header, apdat=apdat

  ;;-------------------------------------------
  ;; Parse data
  
  if n_params() eq 0 then begin
    dprint,'Not working yet.'
    return,!null
  endif

  if isa(apdat) then begin
    if isa(apdat.data,'dynamicarray') && apdat.data.size eq 0  then begin    ; initialization
      hdr = dynamicarray(name='hdr_')
      a0016 = dynamicarray(name='16A_')
      a0256 = dynamicarray(name='a0256_')
      a0512 = dynamicarray(name='16Ax32E_')
      a2048 = dynamicarray(name='a2048_')
      a4096 = dynamicarray(name='16Ax8Dx32E_')
      a8192 = dynamicarray(name='a8192_')
      apdat.data.append, [hdr,a0016,a0256,a0512,a2048,a4096,a8192]
    endif else if isa(apdat.data) then begin
      darrays = apdat.data.array
      hdr = darrays[0]
      a0016 = darrays[1]
      a0256 = darrays[2]
      a0512 = darrays[3]
      a2048 = darrays[4]
      a4096 = darrays[5]
      a8192 = darrays[6]
    endif
  endif


  
  pksize = ccsds.pkt_size
  if pksize le 20 then begin
    dprint,dlevel = 2, 'size error - no data'
    return, 0
  endif
  
  ccsds_data = spp_swp_ccsds_data(ccsds)  
  if pksize ne n_elements(ccsds_data) then begin
    dprint,dlevel=1,'Product size mismatch'
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
    cnts_total:  tcnts,  $
    pdata:        ptr_new(data), $
    gap:         ccsds.gap  }


hdr.append ,str

if  ns gt 0 then begin

  res = 0
  case ndat  of
    16:   a0016.append,  spp_swp_spani_16A(data, header_str=str, apdat=apdat)
    256:  a0256.append,  spp_swp_spani_16Ax16M(data,header_str=str, apdat = apdat)
    512:  a0512.append,   spp_swp_spani_32Ex16A(data, header_str=str, apdat=apdat)
    2048: a2048.append,   spp_swp_spani_32Ex16Ax4M(data, header_str=str, apdat=apdat)
    4096: a4096.append,   spp_swp_spani_8Dx32Ex16A(data, header_str=str, apdat=apdat)
    8192: a8192.append,  spp_swp_spani_8Dx32EX16Ax2M(data, header_str=str, apdat=apdat)
    else:  dprint,dlevel=3,'Size not recognized: ',ndat
  endcase
  
  
  
endif

  return, 0


end
