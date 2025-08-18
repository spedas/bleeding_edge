
function mav_swea_hkp_pfdpu_decom,ccsds
;dprint,dlevel=2,'APID ',ccsds.apid,ccsds.seq_cntr,ccsds.size ,format='(a,z03," ",i,i)'
;data = ccsds.data
data = ccsds.data  ;   one byte values
data2 = uint(data,0,n_elements(data)/2)   ; 2 byte values
byteorder,data2,/swap_if_little_endian
imonitors = fix(data2[0:23])
fmonitors = float(imonitors)  ; Dave - apply cal factors here

subsec = data[0]*256 + data[1]
swia_struct1 = {  $         ;  Some one else must finish this
    time: ccsds.time, $
    monitors:fmonitors, $   ; add whatever things you want here
    SWELVPST: fmonitors[0] * 1., $  ; must be fixed
    SWEMCPHV: -0.152588 *fmonitors[1] , $
    SWENRV  : -0.000203 * fmonitors[2]   , $
    SWEAnalHV: -0.030518*fmonitors[3]  , $
    SWEDef1HV: -0.073360*fmonitors[4]  , $
    SWEDef2HV: -0.073360*fmonitors[5]  , $   ; add more stuff as needed
    other_stuff: data[48:*], $   
    valid:1   }            
return,swia_struct1
end

function mav_apid_swea_3D_decom,ccsds
data = mav_pfdpu_part_decompress_data(ccsds)
subsec = data[0]*256 + data[1]
ccode = ishft(data[3],6)
LUT = data[4]
ddata = reform( mav_log_decomp(data[6:*],ccode), 80, 16 )
swea_struct1 = {  $
    time: ccsds.time, $
    ccode:ccode,  $
    data: ddata, $         
    valid:1   }        
return,swea_struct1
end


function mav_apid_swea_xxxxx_decom,ccsds   ; generic decomutator
data = mav_pfdpu_part_decompress_data(ccsds)
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


function mav_apid_swea_spectra_decom,ccsds
;dprint,dlevel=2,'APID ',ccsds.apid,ccsds.seq_cntr,ccsds.size ,format='(a,z03," ",i,i)'
;data = ccsds.data
data = mav_pfdpu_part_decompress_data(ccsds)
nsample = 64
size = nsample*16+6  ; This is a guess.  Decompressed size isn't always correct.
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
    data:fltarr(nsample), $         
    valid:1   }        
swia_structs = replicate(swia_struct1,16)
swia_structs.time += dindgen(16)*8.       ; 8 second time resolution
swia_structs.data = reform(ddata,nsample,16)        
;print,swia_structs.data
return,swia_structs
end





pro mav_apid_swea_handler,ccsds,decom=decom,reset=reset
    common mav_apid_swea_handler_com,manage,realtime,swea_hkp,a,b,d,e
 ;   dprint,'test 0'
    if n_elements(reset) ne 0 then begin
        manage = reset
        swia_hkp =0
        realtime=1
        return
    endif
    if not keyword_set(manage) then return
    if not keyword_set(ccsds) then return
 ;   dprint,'test 1'

    Case ccsds.apid of
      '28'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='swea_hkp',(swea_hkp=mav_swea_hkp_pfdpu_decom(ccsds))
      'A0'x: begin
            swea_3d = mav_apid_swea_3d_decom(ccsds)
;            mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='swea_3D',swea_3d
            s1 = total(swea_3d.data,1)
            mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='swea_3D_sum1',{time:swea_3d.time,data:s1}
            s2 = total(swea_3d.data,2)
            mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='swea_3D_sum2',{time:swea_3d.time,data:s2}
         end
      'A1'x: begin
            swea_3d = mav_apid_swea_3d_decom(ccsds)
;            mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='swea_3D',swea_3d
            s1 = total(swea_3d.data,1)
            mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='swea_archive_3D_sum1',{time:swea_3d.time,data:s1}
            s2 = total(swea_3d.data,2)
            mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='swea_archive_3D_sum2',{time:swea_3d.time,data:s2}
         end
      'A2'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='swea_PAD',(swea_a2=mav_apid_swea_xxxxx_decom(ccsds))
;      'a3'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='swea_x83',(swia_spec=mav_apid_swea_xxxxx_decom(ccsds))
;      'A4'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='swia_x84',(swia_spec=mav_apid_swea_xxxxx_decom(ccsds))
;      'a5'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='swia_x85',(swia_spec=mav_apid_swea_xxxxx_decom(ccsds))
      'a4'x: begin
          swea_spec=mav_apid_swea_spectra_decom(ccsds)
          mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='swea_spec',swea_spec
          end
       else: return    ; Do nothing if not a SWEA packet
    endcase 
    decom = 1
end
