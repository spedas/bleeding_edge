
function spp_swp_spani_product_decom,ccsds, ptp_header=ptp_header, apdat=apdat


  b = ccsds.data
  if n_elements(b) le 20 then begin
     print,'ERROR: CCSDS data packet smaller than 20 bytes'
     return, 0
  endif

  ;psize = 269+7
  ;if n_elements(b) ne psize then begin
  ;   dprint,dlevel=1,dwait=30., 'Size error ',$
  ;          string(ccsds.size + 7,ccsds.apid,format='(i4," - ",z03)')
  ;endif
  
  time = ccsds.time
  apid_name = string(format='(z02)',b[1])
  data_size = n_elements(b) - 20 ; size of data (20 bytes of header)
  cnts =  float( spp_sweap_log_decomp( b[20:*], 0) )
  ns = n_elements(cnts)
  total_cnts = total(cnts)
  spec1 = cnts
  spec2 = 0
  spec3 = 0
  cnts_full = cnts

dprint,dlevel=3,apid_name,' ',ns

  case data_size of 
     4096: begin
       spec3 = cnts
        cnts  = reform(cnts,256,16,/overwrite)
        spec1 = total(cnts,1)
        spec2 = total(cnts,2)
 ;       printdat,apdat,/hex
;        spec1 = total(total(cnts,3),2)
;        spec2 = total(total(cnts,1),2)
;        spec3 = total(total(cnts,1),1)
        ;printdat,spec1,spec2,spec3
     end
     2048: begin
       cnts  = reform(cnts,16,16,8,/overwrite)
       spec1 = total(total(cnts,3),2)
       spec2 = total(total(cnts,1),2)
       spec3 = total(total(cnts,1),1)
     end
     512: begin
        cnts  = reform(cnts,32,16,/overwrite)
        spec1 = total(cnts,2)
        spec2 = total(cnts,1)
     end
     256: begin
        cnts = reform(cnts,8,32,/overwrite)
        spec1 = total(cnts,2)
        spec2 = total(cnts,1)
     end
     128: begin
       dprint,dlevel=4,apdat.apid,format='(z)'
       cnts = reform(cnts,8,16,/overwrite)
       spec1 = total(cnts,2)
       spec2 = total(cnts,1)        
     end
     64: begin
       dprint,dlevel=4,apdat.apid,format='(z)'
       cnts = reform(cnts,16,4,/overwrite)
       spec1 = total(cnts,2)
       spec2 = total(cnts,1)
     end
     32: begin
        spec1 = cnts                                ;     printdat,cnts
     end
     16: begin
       spec1 = cnts                                ;     printdat,cnts
     end
     8: begin
       spec1 = cnts                                ;     printdat,cnts
     end
     4: begin
       spec1 = cnts                                ;     printdat,cnts
     end
     else: begin
;       printdat,ccsds
       dprint,dlevel=2,  string(ccsds.apid,data_size,  format='("Packet 0x",z04, " Unknown data size:",i5, " wait")') ; ,dwait=10.
       return, 0
    end
  endcase
  
    
  prod_str = { $
             time: time, $
             ;name:apid_name, $
             apid: b[1], $
             ;met: ccsds.met,  $
             seq_cntr: ccsds.seq_cntr, $
             mode:  b[13] , $
             cnts1: spec1 , $
             cnts2: spec2 , $
             cnts3: spec3 , $
             cnts_full: cnts_full, $
             cnts_total: total_cnts, $
             gap: 0 }

  return,prod_str
end


