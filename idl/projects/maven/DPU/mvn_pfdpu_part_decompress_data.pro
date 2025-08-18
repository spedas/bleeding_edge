function mvn_pfdpu_part_decompress_data,cpkt,cfactor=cfactor  ; returns decompressed ccsds packet data for the particle instruments

  bfr = cpkt.data
  cmpbyte = bfr[2]
  cfactor=1.
  if ((cmpbyte) and 128) eq 0 then return,bfr   ; pkt not actually compressed return raw data.
;  dprint,'Decompressing',cpkt.apid,format = '(a,z3)',dlevel=3
  comp_size = n_elements(bfr)
  decomp_bfr= bytarr(2048 + 32)   ; max possible size uncompressed
  pktbits = 8 * (comp_size)
 
  nn = 6
  for DcmInx = 0,nn-1 do decomp_bfr[DcmInx] = bfr[DcmInx]  ; First nn bytes are not compressed
  BitInx = DcmInx*8;               // Start Bit

  while (BitInx lt (Pktbits-32) ) do begin      ;  // While Bits remain
    Type = mvn_pfdpu_GetBits(bfr,bitinx, 2 );
;    dprint,bitinx,type
    case (Type) of
       0: b32 = mvn_pfdpu_DecodeA(bfr, bitinx)
       1: b32 = mvn_pfdpu_DecodeB(bfr, bitinx)
       2: b32=  mvn_pfdpu_DecodeC(bfr, bitinx)
       3: b32 = mvn_pfdpu_DecodeD(bfr, bitinx)
    endcase   
;    dprint,type,b32,format = '(i2,"  ",32(" ",Z02))',dlevel=3
    if DcmInx ge 2048 then begin
        dprint,'Decompression error'
        error=1
        break
    endif
    decomp_bfr[DcmInx:DcmInx+31] = B32
    DcmInx += 32
  endwhile
    
  decomp_size = DcmInx;
  ddata = decomp_bfr[0:decomp_size-1]
 ; hexprint,ddata
  cfactor = float(decomp_size)/float(comp_size)
  return, ddata
end


