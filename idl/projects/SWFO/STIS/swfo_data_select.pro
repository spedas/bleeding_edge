; $LastChangedBy: davin-mac $
; $LastChangedDate: 2024-09-10 22:51:25 -0700 (Tue, 10 Sep 2024) $
; $LastChangedRevision: 32817 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_data_select.pro $

;  This routine extracts  byte(s) or uint(s) or ulong(s) or ulong64 from an array of bytes
;  The input can be either 1 dimensional (returns scalar) or 2-dimensional (returns 1D vector)
;  Keywords:
;     SIGNED :  if set, the output is cast into the appropriate signed quantity
;   Words can cross byte boundaries.  
;   usage:
;   value = spp_swp_data_select(bytearray,startbit,nbits)
;  Written by Davin Larson 2017-06-02


function swfo_data_select,bytearray,startbit,nbits,signed=signed,test=test

  cast_nbytes = (nbits-1) / 8 + 1
  if keyword_set(signed) then cast_nbytes = -cast_nbytes

  if n_elements(startbit) gt 1 then begin
    res = []
    for i=0,n_elements(startbit)-1 do begin
      res = [res,swfo_data_select(bytearray,startbit[i],nbits,signed=signed,test=test)]
    endfor
    return,res
  endif

  nd = size(/n_dimen,bytearray)
  if dimen1(bytearray) * 8 lt (startbit+nbits) then begin
    dprint,dlevel=3,'Extraction error: Array too small. ',n_elements(bytearray),startbit,nbits[0]
    ;message,'',/cont
    v = 0
  endif else begin
    startbyte = startbit / 8
    startshft = startbit mod 8
    endbyte   = (startbit+nbits-1) / 8
    nbytes = endbyte - startbyte +1

    if ~keyword_set(test) then begin
      v =ulong64( bytearray[startbyte++,*] )
      b = (8-startshft)
      if startshft ne 0 then begin
        mask =  ishft(255b,-startshft)
        v = v and mask    ; mask off higher order bits
      endif
      while b le nbits-8 do  begin
        v = ishft(v,8) + bytearray[startbyte++,*]    ; get middle bytes
        b +=8
      endwhile
      if b ne nbits then begin
        s = nbits-b
        v = ishft(v,s)
        if s gt 0 then begin   ; get last byte
          v += ishft(bytearray[startbyte++,*],s-8)
        endif
      endif
      if startbyte ne endbyte+1 then message,'Problem'

    endif else begin
      endshft  = 7 -  ( (startbit+nbits-1) mod 8)
      v=0ULL                ; This method will fail if nbits > 56 because highest order bits will roll over and get lost
      mask =  ishft(1u,8-startshft) - 1
      for i = 0,nbytes-1 do begin
        v = ishft(v,8) + bytearray[startbyte+i,*]
        if mask ne 0 then begin
          v = v and mask
          mask = 0
        endif
      endfor
      if endshft ne 0 then v = ishft(v,-endshft)
    endelse
 
  endelse

  case cast_nbytes of
    1:    v = byte(v)
    2:    v = uint(v)
    3:    v = ulong(v)
    4:    v = ulong(v)
    6:    v = ulong64(v)   
    8 :   v = ulong64(v)
    -1:   v = fix(v)     ; IDL does not have a signed byte
    -2:   v = fix(v)
    -3:   v = long(v)
    -4:   v = long(v)
    -6:   v = long64(v)
    -8:   v = long64(v)   
    else:  dprint,dlevel=1,'Error',nbytes,cast_nbytes
  endcase
  return, (nd eq 1) ? v[0] : reform( v ,/overwrite)     ; get rid of annoying first dimension of 1 for 2D inputs    
end

