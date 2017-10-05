;+
;FUNCTION:   mav_pfdpu_part_decompress_data2
;PURPOSE:
;  Decompresses ESA science packets (SWEA/SWIA/STATIC).  If the packet is already
;  uncompressed, it is simply returned unchanged.
;
;USAGE:
;  decompressed_pkt = mav_pfdpu_part_decompress_data2(compressed_pkt)
;
;INPUTS:
;       compressed_pkt:  ESA science packet that is possibly compressed.
;
;KEYWORDS:
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-03-22 14:24:35 -0700 (Sun, 22 Mar 2015) $
; $LastChangedRevision: 17163 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mav_pfdpu_part_decompress_data2.pro $
;
;CREATED BY:    David L. Mitchell  04-25-13
;FILE: mav_pfdpu_part_decompress_data2.pro
;-

compile_opt idl2

function mav_pfdpu_getbit,bfr,bitinx
  inx = bitinx / 8
  bit = bitinx mod 8
  bmask = [128b,64b,32b,16b,8b,4b,2b,1b]
  bitinx++
  return, (bfr[Inx] and bmask[bit]) ne 0
end

function mav_pfdpu_GetBits,bfr,bitinx, leng
  if leng gt (n_elements(bfr)*8 - bitinx) then begin
     return,0
  endif
  r=0
  for i=0,leng-1 do begin
      r = r*2 + mav_pfdpu_GetBit(bfr,bitinx)
  endfor
  return, r
end

function  mav_pfdpu_NextA,bfr,bitinx
  if(mav_pfdpu_GetBits(bfr,bitinx,1) eq 0) then return,0  ;  // 0
  if(mav_pfdpu_GetBits(bfr,bitinx,1) eq 0) then return,1  ;  // 10    
  n = mav_pfdpu_GetBits(bfr,bitinx,2)    
  if( n lt 3 ) then return, n+2            ;  // 1100-1110 
  n = mav_pfdpu_GetBits(bfr,bitinx,8)    
  return, n                                ;     // 1111xxxxxxxx
end

function mav_pfdpu_NextB,bfr,bitinx
  n = mav_pfdpu_GetBits(bfr,bitinx,3)
  case n of 
     0: return, (0)
     1: return, (1)  
     2: return,( 2 + mav_pfdpu_GetBits(bfr,bitinx,1))
     3: return,( 4 + mav_pfdpu_GetBits(bfr,bitinx,2))
     4: begin
         m = mav_pfdpu_GetBits(bfr,bitinx,2);
         if( m eq 0 )  then return,( 8 )
         if( m eq 1 )  then begin
             p = mav_pfdpu_GetBits(bfr,bitinx,2)
             if( p lt 3) then return,( 9 + p)
             return,( mav_pfdpu_GetBits(bfr,bitinx, 8 ))
         endif
         if( m eq 2 ) then begin
             p = mav_pfdpu_GetBits(bfr,bitinx,2)
             if( p gt 0) then return,( -12 + p)
             return,( - mav_pfdpu_GetBits(bfr,bitinx, 8 ))
         endif
         if( m eq 3 ) then return,( -8 )
       end;
     5: return,( -7 + mav_pfdpu_GetBits(bfr,bitinx,2))
     6: return,( -3 + mav_pfdpu_GetBits(bfr,bitinx,1))
     7: return,( -1 )
   endcase
end

function mav_pfdpu_NextC,bfr,bitinx
  n = mav_pfdpu_GetBits(bfr,bitinx,4)
  switch (n) of
   0: 
   1: 
   2:
   3: return,(n);
   4: return,( 4 + mav_pfdpu_GetBits(bfr,bitinx,1) )
   5: return,( 6 + mav_pfdpu_GetBits(bfr,bitinx,1) )
   6: return,( 8 + mav_pfdpu_GetBits(bfr,bitinx,1) )
   7: if( mav_pfdpu_GetBits(bfr,bitinx,1) eq 0) then return,( 10 ) $ 
      else return,( 11 + mav_pfdpu_GetBits(bfr,bitinx,1) )
   8: begin 
      m = mav_pfdpu_GetBits(bfr, bitinx, 2)
      if( m eq 0 ) then return,( 13 )
      if( m eq 1 ) then begin
          p = mav_pfdpu_GetBits(bfr, bitinx, 1)
          if( p eq 0) then return,( 14 )
          return,( mav_pfdpu_GetBits(bfr,bitinx,8) )
      endif
      if( m eq 2 ) then begin
          p = mav_pfdpu_GetBits(bfr,bitinx,1)
          if( p eq 1) then return,( -14 )
          return,( -mav_pfdpu_GetBits(bfr,bitinx,8) )
      endif
      if( m eq 3 ) then return,( -13 )
      end
   9: if( mav_pfdpu_GetBits(bfr,bitinx,1) eq 1) then return,( -10 ) $
      else  return,( -12 + mav_pfdpu_GetBits(bfr,bitinx,1) )
   10: return,( -9 + mav_pfdpu_GetBits(bfr,bitinx,1) )
   11: return,( -7 + mav_pfdpu_GetBits(bfr,bitinx,1) )
   12: return,( -5 + mav_pfdpu_GetBits(bfr,bitinx,1) )
   13: return,( -3 )
   14: return,( -2 )
   15: return,( -1 )
  endswitch
end

function mav_pfdpu_NextD, bfr, bitinx
  n = mav_pfdpu_GetBits(bfr,bitinx,4)
  switch (n) of
   0: 
   1: 
   2:
   3: return,(n)
   4: return,( 4 + mav_pfdpu_GetBits(bfr,bitinx,1))
   5: return,( 6 + mav_pfdpu_GetBits(bfr,bitinx,1))
   6: return,( 8 + mav_pfdpu_GetBits(bfr,bitinx,1))
   7: if( mav_pfdpu_GetBits(bfr,bitinx,1) eq 0) then return,(10) $
      else return,( 11 + mav_pfdpu_GetBits(bfr,bitinx,1))
   8: begin 
      m = mav_pfdpu_GetBits(bfr,bitinx,4)
      if( m lt 7 ) then return,( 13+m )
      if( m eq 7 ) then return,(  mav_pfdpu_GetBits(bfr,bitinx,8))
      if( m eq 8 ) then return,( -mav_pfdpu_GetBits(bfr,bitinx,8))
      if( m gt 8 ) then return,( -28+m )
     end  
   9: if( mav_pfdpu_GetBits(bfr,bitinx,1) eq 1) then return,(-10) else $
      return,( -12 + mav_pfdpu_GetBits(bfr,bitinx,1))
   10: return,( -9 + mav_pfdpu_GetBits(bfr,bitinx,1))
   11: return,( -7 + mav_pfdpu_GetBits(bfr,bitinx,1))
   12: return,( -5 + mav_pfdpu_GetBits(bfr,bitinx,1))
   13: return,( -3 )
   14: return,( -2 )
   15: return,( -1 )
  endswitch
end

function mav_pfdpu_DecodeA, bfr, bitinx 
  dst = bytarr(32)
;  dprint,bitinx,dlevel=3
  for i=0,32-1 do begin
    dst[i] =  mav_pfdpu_NextA(bfr, bitinx)
;    dprint,bitinx,dst[i],format='(i4," ",z02)',dlevel=3
  endfor
  return, dst 
end

function mav_pfdpu_DecodeB, bfr, bitinx
  dst = bytarr(32)
  R =  mav_pfdpu_GetBits(bfr,bitinx,8)
  dst[0] = R
  for i=1,32-1 do begin
    Del = mav_pfdpu_NextB(bfr, bitinx)  ;  each B value is a delta
    R += Del;
    dst[i] = R;
  endfor
  return, dst
end

function mav_pfdpu_DecodeC, bfr, bitinx
  dst = bytarr(32)
  R =  mav_pfdpu_GetBits(bfr, bitinx, 8)
  dst[0] = R
  for i=1,32-1 do begin
    Del = mav_pfdpu_NextC(bfr, bitinx)  ;  each B value is a delta
        R += Del;
    dst[i] = R;
  endfor
  return, dst
end

function mav_pfdpu_DecodeD, bfr, bitinx
  dst = bytarr(32)
  R =  mav_pfdpu_GetBits(bfr, bitinx, 8)
  dst[0] = R
  for i=1,32-1 do begin
    Del = mav_pfdpu_NextD(bfr, bitinx)   ;  each B value is a delta
    R += Del;
    dst[i] = R;
  endfor
  return, dst
end


function mav_pfdpu_part_decompress_data2, bfr

  compile_opt idl2

; returns decompressed ccsds packet data for the particle instruments

  cmpbyte = bfr[12]
  if (cmpbyte and 128) eq 0 then return,bfr   ; pkt not actually compressed return raw data.
  pktbits = 8*(bfr[4]*256+bfr[5] + 7)
  pktbits = pktbits - 32
  
  decomp_bfr = bytarr(4096)   ; max possible size uncompressed
 
  for j = 0,15 do decomp_bfr[j] = bfr[j]  ; First nn bytes are not compressed
  DcmInx = 16		    ; Start Byte		
  BitInx = DcmInx*8 	; Start Bit

  while (BitInx lt Pktbits ) do begin        ; While Bits remain
    Type = mav_pfdpu_GetBits(bfr, bitinx, 2)
    case (Type) of
       0: b32 = mav_pfdpu_DecodeA(bfr, bitinx)
       1: b32 = mav_pfdpu_DecodeB(bfr, bitinx)
       2: b32 = mav_pfdpu_DecodeC(bfr, bitinx)
       3: b32 = mav_pfdpu_DecodeD(bfr, bitinx)
    endcase
    if (DcmInx+31 gt 4095) then begin
      print,"decompression error"
      break
    endif
    decomp_bfr[DcmInx:DcmInx+31] = B32
    DcmInx += 32
  endwhile
    
  decomp_size = DcmInx
  decomp_bfr[4] = (decomp_size-7) / 256
  decomp_bfr[5] = (decomp_size-7) mod 256
  
  ddata = decomp_bfr[0:decomp_size-1]
  return, ddata
  
  
end


