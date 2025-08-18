;+
;Helper function for packet decompression
;-
function swx_swem_GetBit,bfr,bitinx
  inx = bitinx / 8
  bit = bitinx mod 8
  bmask = [128b,64b,32b,16b,8b,4b,2b,1b]
  bitinx++
  return ,  (bfr[Inx] and bmask[bit]) ne 0
end




;+
;Helper function for packet decompression
;-
function swx_swem_GetBits,bfr,bitinx, leng
  if leng gt (n_elements(bfr)*8 - bitinx) then begin
    return,0
  endif
  r=0
  for i=0,leng-1 do begin              ;  for(i=0;i<leng;i++)
    r = r*2 + swx_swem_GetBit(bfr,bitinx)
  endfor
  return, r
end




;+
;Helper function for packet decompression
;-
function  swx_swem_NextA,bfr,bitinx
  if(swx_swem_GetBits(bfr,bitinx,1) eq 0) then return,0  ;  // 0
  if(swx_swem_GetBits(bfr,bitinx,1) eq 0) then return,1  ;  // 10
  n = swx_swem_GetBits(bfr,bitinx,2)
  if( n lt 3 ) then return, n+2            ;  // 1100-1110
  n = swx_swem_GetBits(bfr,bitinx,8)
  return,n                                ;     // 1111xxxxxxxx
end



;+
;Helper function for packet decompression
;-
function swx_swem_DecodeA, bfr,bitinx
  dst = bytarr(32)
  ;  dprint,bitinx,dlevel=3
  for i=0,32-1 do begin            ;  for(i=0;i<32;i++)
    dst[i] =  swx_swem_NextA(bfr,bitinx)
    ;    dprint,bitinx,dst[i],format='(i4," ",z02)',dlevel=3
  endfor
  return,dst
end



;+
;Helper function for packet decompression
;-
function swx_swem_NextB,bfr,bitinx
  n = swx_swem_GetBits(bfr,bitinx,3);

  case n of
    0: return, (0)
    1: return, (1)
    2: return,( 2 + swx_swem_GetBits(bfr,bitinx,1));
    3: return,( 4 + swx_swem_GetBits(bfr,bitinx,2));
    4: begin
      m = swx_swem_GetBits(bfr,bitinx,2);
      if( m eq 0 )  then return,( 8 );
      if( m eq 1 )  then begin
        p = swx_swem_GetBits(bfr,bitinx,2);
        if( p lt 3) then return,( 9 + p);
        return,( swx_swem_GetBits(bfr,bitinx, 8 ));
      endif
      if( m eq 2 ) then begin
        p = swx_swem_GetBits(bfr,bitinx,2);
        if( p gt 0) then return,( -12 + p);
        return,( - swx_swem_GetBits(bfr,bitinx, 8 ));
      endif
      if( m eq 3 ) then return,( -8 );
    end;
    5: return,( -7 + swx_swem_GetBits(bfr,bitinx,2));
    6: return,( -3 + swx_swem_GetBits(bfr,bitinx,1));
    7: return,( -1 );
  endcase
end



;+
;Helper function for packet decompression
;-
function swx_swem_DecodeB, bfr,bitinx
  dst = bytarr(32)
  R =  swx_swem_GetBits(bfr,bitinx,8)
  dst[0] = R
  for i=1,32-1 do begin    ;  for(i=0;i<31;i++)
    Del = swx_swem_NextB( bfr,bitinx);    // Each B value is a delta
    R += Del;
    dst[i] = R;
  endfor
  return,dst
end




;+
; Helper function for packet decompressions
;-
function swx_swem_NextC,bfr,bitinx
  n = swx_swem_GetBits(bfr,bitinx,4);
  switch (n) of
    0:
    1:
    2:
    3: return,(n);
    4: return,( 4 + swx_swem_GetBits(bfr,bitinx,1));
    5: return,( 6 + swx_swem_GetBits(bfr,bitinx,1));
    6: return,( 8 + swx_swem_GetBits(bfr,bitinx,1));
    7: if( swx_swem_GetBits(bfr,bitinx,1) eq 0) then return,(10) $
    else return,( 11 + swx_swem_GetBits(bfr,bitinx,1));
    8: begin
      m = swx_swem_GetBits(bfr,bitinx,2);
      if( m eq 0 ) then return,( 13 );
      if( m eq 1 ) then begin
        p = swx_swem_GetBits(bfr,bitinx,1);
        if( p eq 0) then return,( 14 );
        return,( swx_swem_GetBits(bfr,bitinx,8 ));
      endif
      if( m eq 2 ) then begin
        p = swx_swem_GetBits(bfr,bitinx,1);
        if( p eq 1) then return,( -14 );
        return,( -swx_swem_GetBits(bfr,bitinx,8 ));
      endif
      if( m eq 3 ) then return,( -13 ); break;
    end
    9: if( swx_swem_GetBits(bfr,bitinx,1) eq 1) then return,(-10) $
    else  return,( -12 + swx_swem_GetBits(bfr,bitinx,1));
    10: return,( -9 + swx_swem_GetBits(bfr,bitinx,1));
    11: return,( -7 + swx_swem_GetBits(bfr,bitinx,1));
    12: return,( -5 + swx_swem_GetBits(bfr,bitinx,1));
    13: return,( -3 );
    14: return,( -2 );
    15: return,( -1 );
  endswitch
end


;+
;Helper function for packet decompression
;-
function swx_swem_DecodeC, bfr,bitinx
  dst = bytarr(32)
  R =  swx_swem_GetBits(bfr,bitinx,8)
  dst[0] = R
  for i=1,32-1 do begin    ;  for(i=0;i<31;i++)
    Del = swx_swem_NextC( bfr,bitinx);    // Each B value is a delta
    R += Del;
    dst[i] = R;
  endfor
  return, dst
end


;+
;Helper function for packet decompression
;-
function swx_swem_NextD,bfr,bitinx
  n = swx_swem_GetBits(bfr,bitinx,4);
  switch (n) of
    0:
    1:
    2:
    3: return,(n);
    4: return,( 4 + swx_swem_GetBits(bfr,bitinx,1));
    5: return,( 6 + swx_swem_GetBits(bfr,bitinx,1));
    6: return,( 8 + swx_swem_GetBits(bfr,bitinx,1));
    7: if( swx_swem_GetBits(bfr,bitinx,1) eq 0) then return,(10) $
    else return,( 11 + swx_swem_GetBits(bfr,bitinx,1));
    8: begin
      m = swx_swem_GetBits(bfr,bitinx,4);
      if( m lt 7 ) then return,( 13+m );
      if( m eq 7 ) then return,(  swx_swem_GetBits(bfr,bitinx,8));
      if( m eq 8 ) then return,( -swx_swem_GetBits(bfr,bitinx,8));
      if( m gt 8 ) then return,( -28+m );
    end  ; break;
    9: if( swx_swem_GetBits(bfr,bitinx,1) eq 1) then return,(-10) else $
      return,( -12 + swx_swem_GetBits(bfr,bitinx,1));
    10: return,( -9 + swx_swem_GetBits(bfr,bitinx,1));
    11: return,( -7 + swx_swem_GetBits(bfr,bitinx,1));
    12: return,( -5 + swx_swem_GetBits(bfr,bitinx,1));
    13: return,( -3 );
    14: return,( -2 );
    15: return,( -1 );
  endswitch
end

;+
;Helper function for packet decompression
;-
function swx_swem_DecodeD, bfr,bitinx
  dst = bytarr(32)
  R =  swx_swem_GetBits(bfr,bitinx,8)
  dst[0] = R
  for i=1,32-1 do begin    ;  for(i=0;i<31;i++)
    Del = swx_swem_NextD( bfr,bitinx);    // Each B value is a delta
    R += Del;
    dst[i] = R;
  endfor
  return,dst
end



function swx_swem_part_decompress_data,bfr,decomp_size = decomp_size,stuff_size=stuff_size,cfactor=cfactor ;  ; returns decompressed ccsds packet data for the particle instruments

;  bfr = cpkt.data
;  cmpbyte = bfr[2]
  cfactor=1.
;  if ((cmpbyte) and 128) eq 0 then return,bfr   ; pkt not actually compressed return raw data.
;  dprint,'Decompressing',cpkt.apid,format = '(a,z3)',dlevel=3
  comp_size = n_elements(bfr)
  decomp_bfr= bytarr(comp_size*8 + 32)   ; max possible size uncompressed
  pktbits = 8 * (comp_size)
 
  nn = 20
  for DcmInx = 0L,nn-1 do decomp_bfr[DcmInx] = bfr[DcmInx]  ; First nn bytes are not compressed
  BitInx = DcmInx*8;               // Start Bit

  while (BitInx lt (Pktbits-32) ) do begin      ;  // While Bits remain
    Type = swx_swem_GetBits(bfr,bitinx, 2 );
 ;   dprint,bitinx,type,dlevel=2
    case (Type) of
       0: b32 = swx_swem_DecodeA(bfr, bitinx)
       1: b32 = swx_swem_DecodeB(bfr, bitinx)
       2: b32=  swx_swem_DecodeC(bfr, bitinx)
       3: b32 = swx_swem_DecodeD(bfr, bitinx)
    endcase   
;    dprint,type,b32,format = '(i2,"  ",32(" ",Z02))',dlevel=3
    if DcmInx ge n_elements(decomp_bfr) then begin
        dprint,'Decompression error'
        error=1
        break
    endif
    decomp_bfr[DcmInx:DcmInx+31] = B32
    DcmInx += 32
  endwhile
    
  decomp_size = DcmInx;
  ddata = decomp_bfr[0:decomp_size-1]
  if keyword_set(stuff_size) then begin
    pkt_size = decomp_size-7
    ddata[4] = ishft(pkt_size,-8)
    ddata[5] = pkt_size and 'ff'x
  endif
  cfactor = float(decomp_size)/float(comp_size)
  return, ddata
end


