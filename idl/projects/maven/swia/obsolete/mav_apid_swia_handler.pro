
function mav_swia_hkp_pfdpu_decom,ccsds
;dprint,dlevel=2,'APID ',ccsds.apid,ccsds.seq_cntr,ccsds.size ,format='(a,z03," ",i,i)'
;data = ccsds.data
data = ccsds.data  ;   one byte values
data2 = uint(data,0,n_elements(data)/2)   ; 2 byte values
byteorder,data2,/swap_if_little_endian

subsec = data[0]*256 + data[1]
swia_struct1 = {  $         ;  Some one else must finish this
    time: ccsds.time, $
    monitors:fix(data2[0:23]), $ 
    other_stuff: data[48:*], $   
    valid:1   }            
return,swia_struct1
end

function mav_apid_swia_spectra_decom,ccsds
;dprint,dlevel=2,'APID ',ccsds.apid,ccsds.seq_cntr,ccsds.size ,format='(a,z03," ",i,i)'
;data = ccsds.data
data = mav_pfdpu_part_decompress_data(ccsds)
size = 48*16+6  ; This is a guess.  Decompressed size isn't always correct.
if n_elements(data) ne size then begin
    dprint,ccsds.apid,n_elements(ccsds.data),n_elements(data),format='(z02,i5,i5)'
    data = data[0:size-1] ;  data might not be correct size after decompression
endif
subsec = data[0]*256 + data[1]
ccode = data[2]
ccode = ishft(data[2],6)
ddata = mav_log_decomp(data[6:*],ccode)
swia_struct1 = {  $
    time: ccsds.time, $
    ccode:ccode,  $
    data:fltarr(48), $         
    valid:1   }        
swia_structs = replicate(swia_struct1,16)
swia_structs.time += dindgen(16)*8.       ; 8 second time resolution
swia_structs.data = reform(ddata,48,16)        
return,swia_structs
end


function mav_apid_swia_xxxxx_decom,ccsds   ; generic decomutator
data = mav_pfdpu_part_decompress_data(ccsds)
;size = 48*16+6  ; This is a guess.  Decompressed size isn't always correct.
;if n_elements(data) ne size then begin
;    dprint,ccsds.apid,n_elements(ccsds.data),n_elements(data),format='(z02,i5,i5)'
;    data = data[0:size-1] ;  data might not be correct size after decompression
;endif
subsec = data[0]*256 + data[1]
;ccode = data[2]
;ccode = ishft(data[2],6)
;ddata = mav_log_decomp(data[6:*],ccode)
swia_struct1 = {  $
    time: ccsds.time, $
    data:data[6:*], $         
    valid:1   }        
return,swia_struct1
end



pro mav_apid_swia_handler,ccsds,decom=decom,reset=reset
    common mav_apid_swia_handler_com,manage,realtime,swia_hkp,a,b,d,e
;    dprint,'test 0'
    if n_elements(reset) ne 0 then begin
        manage = reset
        swia_hkp =0
        realtime=1
        return
    endif
    if not keyword_set(manage) then return
    if not keyword_set(ccsds) then return

    Case ccsds.apid of
      '29'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='swia_hkp',(swia_hkp=mav_swia_hkp_pfdpu_decom(ccsds))
      '80'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='swia_x80',(swia_spec=mav_apid_swia_xxxxx_decom(ccsds))
      '81'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='swia_x81',(swia_spec=mav_apid_swia_xxxxx_decom(ccsds))
      '82'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='swia_x82',(swia_spec=mav_apid_swia_xxxxx_decom(ccsds))
      '83'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='swia_x83',(swia_spec=mav_apid_swia_xxxxx_decom(ccsds))
      '84'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='swia_x84',(swia_spec=mav_apid_swia_xxxxx_decom(ccsds))
      '85'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='swia_x85',(swia_spec=mav_apid_swia_xxxxx_decom(ccsds))
      '86'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='swia_spec',(swia_spec=mav_apid_swia_spectra_decom(ccsds))
       else: return    ; Do nothing if not a SWIA packet
    endcase 
    decom = 1
end
