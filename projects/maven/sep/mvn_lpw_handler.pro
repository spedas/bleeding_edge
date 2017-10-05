

function  mav_apid_lpw_decoder1,ccsds
common mav_apid_lpw_decoder1_com, mask16,mask8,bin_c,index_arr,flip_8
if not keyword_set(mask16) then mvn_lpw_r_mask,mask16,mask8,bin_c,index_arr,flip_8 

data = ccsds.data
data = uint(data,0,n_elements(data)/2)  & byteorder,data,/swap_if_little_endian


;;EUV Packet
;   total_euv_length = 0
;   if nn_EUV GT 0 and nn_act_EUV GT 0 then begin     
;t1=SYSTIME(1,/seconds)                   ;to check on speed
;     ;EUV Preallocations
;     THERM   = fltarr(nn_EUV,16)
;     DIODE_A = fltarr(nn_EUV,16)
;     DIODE_B = fltarr(nn_EUV,16)
;     DIODE_C = fltarr(nn_EUV,16)
;     DIODE_D = fltarr(nn_EUV,16)
;     FOR ni=0L,nn_EUV-1 do begin
;       i                     = pkt_EUV[ni]   ;which paket in the large file 
;       counter               = counter_specific[i]   ;get the right counter     
i=0
counter_all1 = [9999]
counter = 0
place = 0
offset1 = 7 - 5  ; account for 5 word header
p7=0
compression = 'on'
newfile_unsigned = data
;       EUV_config[i] = newfile_unsigned[counter+place+offset1-1]
    if compression EQ 'on' then begin    
          ptr=1L*(counter+place+offset1)                       ; which 16 bit package to start with
;          ptr_end=ptr+(length2[i]-len_offset)              ; this has to be checked!!!
          nn_e=0 
          dl =3
          dprint,ptr,nn_e ,dlevel=dl
          therm    = mvn_lpw_r_block16(newfile_unsigned,ptr,nn_e,mask16,bin_c,index_arr,16,edac_on)
          if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,counter,counter_all1[i],' pointer ',ptr,nn_e,' Packet EUV temp'
          dprint,ptr,nn_e ,dlevel=dl
          diode_a  = mvn_lpw_r_block16(newfile_unsigned,ptr,nn_e,mask16,bin_c,index_arr,16,edac_on)
          if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,counter,counter_all1[i],' pointer ',ptr,nn_e,' Packet EUV DIODE A'
          dprint,ptr,nn_e ,dlevel=dl
          diode_b  = mvn_lpw_r_block16(newfile_unsigned,ptr,nn_e,mask16,bin_c,index_arr,16,edac_on)
          if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,counter,counter_all1[i],' pointer ',ptr,nn_e,' Packet EUV DIODE B'
          dprint,ptr,nn_e ,dlevel=dl
          diode_c  = mvn_lpw_r_block16(newfile_unsigned,ptr,nn_e,mask16,bin_c,index_arr,16,edac_on)
          if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,counter,counter_all1[i],' pointer ',ptr,nn_e,' Packet EUV DIODE C'
          dprint,ptr,nn_e ,dlevel=dl
          diode_d  = mvn_lpw_r_block16(newfile_unsigned,ptr,nn_e,mask16,bin_c,index_arr,16,edac_on)
          if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,counter,counter_all1[i],' pointer ',ptr,nn_e,' Packet EUV DIODE D'
          dprint,ptr,nn_e ,dlevel=dl
      ;Check the amount of data left over - ptr is moved (by mvn_lpw_r_multi_decompress) up to the first bit after the compressed data, so 0 is ok.
 ;     if ptr_end-ptr lt 0 or ptr_end-ptr gt 32 then message,/info,string(ptr_end-ptr,format='(%"Did not decompress the right amount of data, %d bytes left over")')
    end else begin
      for z = 0,31,2 do begin
        dummy = string(newfile_signed[counter+place+offset1+z],format='(B016)')+string(newfile_signed[counter+place+offset1+z+1],format = '(B016)')
        reads, dummy, THERM_dummy, format = '(B032)'
        THERM[ni,z/2] = THERM_dummy
        dummy = string(newfile_signed[counter+place+offset1+z+32],format = '(B016)')+string(newfile_signed[counter+place+offset1+z+1+32],format = '(B016)')
        reads, dummy, DIODEA_dummy, format = '(B032)'
        DIODE_A[ni,z/2] = DIODEA_dummy
        dummy = string(newfile_signed[counter+place+offset1+z+2*32],format = '(B016)')+string(newfile_signed[counter+place+offset1+z+1+2*32], format = '(B016)')
        reads, dummy, DIODEB_dummy, format = '(B032)'
        DIODE_B[ni,z/2] = DIODEB_dummy
        dummy = string(newfile_signed[counter+place+offset1+z+3*32],format = '(B016)')+string(newfile_signed[counter+place+offset1+z+1+3*32], format = '(B016)')
        reads, dummy, DIODEC_dummy, format = '(B032)'
        DIODE_C[ni,z/2] = DIODEC_dummy
        dummy = string(newfile_signed[counter+place+offset1+z+4*32],format = '(B016)')+string(newfile_signed[counter+place+offset1+z+1+4*32], format = '(B016)')
        reads, dummy, DIODED_dummy, format = '(B032)'
        DIODE_D[ni,z/2] = DIODED_dummy
      endfor
    end       
    p7 = p7 + 1 ; keeps track of how many EUV packets there are   
 ;     ENDFOR   ;loop over the packets
;t2=SYSTIME(1,/seconds)                       ;to check on speed
;print,'#### EUV ',ni,i,' time ', t2-t1,' seconds' 

;printdat,therm,diode_a

 ;     EUV_SC = SC[pkt_EUV]
 ;     for seqIndx = 1, nn_EUV-1 do $
 ;         if EUV_SC[seqIndx] NE EUV_SC[seqIndx-1]+1 then print, 'EUV Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', EUV_SC[seqIndx-1], '  SC(seqIndx) =', EUV_SC[seqIndx]
 ;     if (EUV_SC[nn_EUV-1]-EUV_SC[0]+1) NE p7 then print, 'EUV Sequence Count Failed. Should be', p7, ' Reporting ',(EUV_SC[nn_EUV-1]-EUV_SC[0]+1)
 ;     total_euv_length = total(length[pkt_EUV]+7)  
 ; endif  ELSE BEGIN ; if no packet was found
 ;     THERM   = -1 &     DIODE_A = -1 &     DIODE_B = -1 &     DIODE_C = -1 &     DIODE_D = -1 & ENDELSE


dt = 1d
   dd = { time: ccsds.time, $ ; + dindgen(16) * dt, $
          data: [[  therm ] , [diode_a] ,[diode_b] ,  [diode_c] , [ diode_d]] }
   

  return,dd
end




function mav_apid_lpw_diag_decom,ccsds,lastpkt=lastpkt

;dprint,dlevel=2,'APID ',ccsds.apid,ccsds.seq_cntr,ccsds.size ,format='(a,z03," ",i,i)'
data = ccsds.data
if not keyword_set(lastpkt) then lastpkt = ccsds

str = {time:ccsds.time  ,$
       dtime:  ccsds.time - lastpkt.time ,$
       size: ccsds.size , $
       seq_cntr:  ccsds.seq_cntr   ,$
       seq_dcntr:  fix( ccsds.seq_cntr - lastpkt.seq_cntr )   ,$
       valid: 1 }
return, str
end




function mav_apid_lpw_euv_decom,ccsds,lastpkt=lastpkt

dprint,dlevel=3,'APID ',ccsds.apid,ccsds.seq_cntr,ccsds.size ,format='(a,z03," ",i,i)'
data = ccsds.data
if not keyword_set(lastpkt) then lastpkt = ccsds
;printdat,ccsds
dat = mav_apid_lpw_decoder1(ccsds)

str = {time:ccsds.time  ,$
       dtime:  ccsds.time - lastpkt.time ,$
       seq_cntr:  ccsds.seq_cntr   ,$
       seq_dcntr:  fix( ccsds.seq_cntr - lastpkt.seq_cntr )   ,$
       diodes: fltarr(4) ,$
       therm:  0. ,$
       valid: 1 }
       
time = dat.time +dindgen(16)
diodes = dat.data[*,[1,2,3,4]]
therm = dat.data[*,0]

ns = 16
mstr = replicate(str,ns)
mstr.time = time
mstr.therm =therm
mstr.diodes = transpose(diodes)

;store_data,/append,'lpw_euv_diodes',mstr.time,diodes
;store_data,/append,'lpw_euv_therm',mstr.time,therm
dprint,therm,dlevel=3

return, mstr

end


function mav_apid_lpw_xxxx_decom,ccsds,lastpkt=lastpkt

;dprint,dlevel=2,'APID ',ccsds.apid,ccsds.seq_cntr,ccsds.size ,format='(a,z03," ",i,i)'
data = ccsds.data
if not keyword_set(lastpkt) then lastpkt = ccsds

str = {time:ccsds.time  ,$
       dtime:  ccsds.time - lastpkt.time ,$
       size: ccsds.size ,$
       seq_cntr:  ccsds.seq_cntr   ,$
       seq_dcntr:  fix( ccsds.seq_cntr - lastpkt.seq_cntr )   ,$
       valid: 1 }
return, str

end




pro mvn_lpw_handler,ccsds,decom=decom,reset=reset,clear=clear,set_realtime=set_realtime,debug=debug
    common mav_apid_lpw_handler_com,manage,realtime,lpw_diag,lpw_spec,apid50x,apid51x,apid52x

    if not keyword_set(ccsds) then begin
        if n_elements(reset) ne 0 then begin
           manage = reset
           clear = keyword_set(reset)
        endif
        if n_elements(set_realtime) ne 0 then realtime=set_realtime
        if keyword_set(debug) then begin
           dprint,phelp=3,manage,realtime,apid52x
           return
        endif
        dprint,dlevel=2,'LPW handler: ', keyword_set(clear) ? 'Clearing old data' : 'Finalizing'
        mav_gse_structure_append, clear=clear,  apid50x   
        mav_gse_structure_append, clear=clear,  apid51x
        mav_gse_structure_append, clear=clear,  apid52x   ,tname = 'mvn_lpw_euv', tags='THERM DIODES'
        return
    endif
    if not keyword_set(manage) then return

    dprint,'LPW hello ',ccsds.apid,dlevel=3,dwait=20.
    if ((ccsds.apid and '50'x) ne '50'x) then return
    Case ccsds.apid of
      '50'x: mav_gse_structure_append  ,apid50x, realtime=realtime, tname='lpw_diag',(lpw_diag=mav_apid_lpw_diag_decom(ccsds,last=lpw_diag))
      '51'x: mav_gse_structure_append  ,apid51x, realtime=realtime, tname='lpw_51',mav_apid_lpw_xxxx_decom(ccsds)
      '52'x: mav_gse_structure_append  ,apid52x, realtime=realtime, tname='lpw_euv', mav_apid_lpw_euv_decom(ccsds)
 ;     '52'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='lpw_52',mav_apid_lpw_euv_decom(ccsds)   ; EUV
 ;     '53'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='lpw_53',mav_apid_lpw_xxxx_decom(ccsds)
 ;     '54'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='lpw_54',mav_apid_lpw_xxxx_decom(ccsds)
 ;     '55'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='lpw_55',mav_apid_lpw_xxxx_decom(ccsds)
 ;     '56'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='lpw_56',mav_apid_lpw_xxxx_decom(ccsds)
 ;     '57'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='lpw_57',mav_apid_lpw_xxxx_decom(ccsds)
 ;     '58'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='lpw_58',mav_apid_lpw_xxxx_decom(ccsds)
 ;     '59'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='lpw_59',mav_apid_lpw_xxxx_decom(ccsds)
 ;     '5A'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='lpw_5A',mav_apid_lpw_xxxx_decom(ccsds)
 ;     '5B'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='lpw_5B',mav_apid_lpw_xxxx_decom(ccsds)
 ;     '5C'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='lpw_5C',mav_apid_lpw_xxxx_decom(ccsds)
 ;     '5D'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='lpw_5D',mav_apid_lpw_xxxx_decom(ccsds)
 ;     '5E'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='lpw_5E',mav_apid_lpw_xxxx_decom(ccsds)
 ;     '5F'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='lpw_5F',mav_apid_lpw_xxxx_decom(ccsds)
 ;     '60'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='lpw_60',mav_apid_lpw_xxxx_decom(ccsds)
 ;     '61'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='lpw_61',mav_apid_lpw_xxxx_decom(ccsds)
 ;     '62'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='lpw_62',mav_apid_lpw_xxxx_decom(ccsds)
 ;     '67'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='lpw_67',mav_apid_lpw_xxxx_decom(ccsds)
       else: return    ; Do nothing if not a LPW packet
    endcase 
    decom = 1
end
