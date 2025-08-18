;+
;FUNCTION: 
;	MVN_SWIA_PACKET_DECOMPRESS
;PURPOSE: 
;	Function to decompress a compressed telemetry packet.  
;	Adaptation of Davin's IDL adaptation of PRH's C code for packet including header.
;	Contains a bunch of functions for manipulating individual bits and bytes. 
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE: 
;	Result = MVN_SWIA_PACKET_DECOMPRESS(Bfr)
;INPUTS: 
;	Bfr: The compressed packet (bytes), including CCSDS header
;OUTPUTS: 
;	Returns the uncompressed packet (bytes), including header, length field updated
;
; $LastChangedBy: jimmpc1 $
; $LastChangedDate: 2017-03-24 12:16:02 -0700 (Fri, 24 Mar 2017) $
; $LastChangedRevision: 23024 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_packet_decompress.pro $
;
;-
function mvn_swia_packet_decompress,bfr  ; returns decompressed ccsds packet data for the particle instruments

compile_opt idl2

  cmpbyte = bfr[12]
  if (cmpbyte) and 128 eq 0 then return,bfr   ; pkt not actually compressed return raw data.
  pktbits = 8*(bfr[4]*256+bfr[5] + 7)
  pktbits = pktbits - 32
  
  decomp_bfr= bytarr(4096)   ; max possible size uncompressed
 
  for j = 0,15 do decomp_bfr[j] = bfr[j]  ; First nn bytes are not compressed
  DcmInx = 16		;Start Byte		
  BitInx = DcmInx*8 	;Start Bit

  while (BitInx lt Pktbits and DcmInx lt 4064) do begin      ; While Bits remain
    Type = mvn_pfdpu_GetBits(bfr,bitinx, 2 );
    case (Type) of
       0: b32 = mvn_pfdpu_DecodeA(bfr, bitinx)
       1: b32 = mvn_pfdpu_DecodeB(bfr, bitinx)
       2: b32=  mvn_pfdpu_DecodeC(bfr, bitinx)
       3: b32 = mvn_pfdpu_DecodeD(bfr, bitinx)
    endcase   
    decomp_bfr[DcmInx:DcmInx+31] = B32
    DcmInx += 32
  endwhile
    
  decomp_size = DcmInx;
  decomp_bfr[4] = (decomp_size-7) / 256
  decomp_bfr[5] = (decomp_size-7) mod 256
  
  ddata = decomp_bfr[0:decomp_size-1]
  return, ddata
  
  
end


