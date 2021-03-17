; $LastChangedBy: davin-mac $
; $LastChangedDate: 2020-12-25 13:50:40 -0800 (Fri, 25 Dec 2020) $
; $LastChangedRevision: 29558 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/COMMON/spp_swp_data_select.pro $

;  This routine extracts  byte(s) or uint(s) or ulong(s) or ulong64 from an array of bytes
;  The input can be either 1 dimensional (returns scalar) or 2-dimensional (returns 1D vector)
;  Keywords:
;     SIGNED :  if set, the output is cast into the appropriate signed quantity
;   Words can cross byte boundaries.  If items don't cross byte boundaries then it is faster to access bytes directly
;  Written by Davin Larson 2017-06-02


function spp_swp_data_select,bytearray,startbit,nbits,signed=signed

  nd = size(/n_dimen,bytearray)
  if dimen1(bytearray) * 8 lt (startbit+nbits) then begin
    dprint,dlevel=1,'Extraction error'
    message,'Bad Input - input array not large enough'
    return, 0
  endif
  startbyte = startbit / 8               
  startshft = startbit mod 8
  endbyte   = (startbit+nbits-1) / 8
  endshft  = 7 -  ( (startbit+nbits-1) mod 8)
  nbytes = endbyte - startbyte +1
  v=0ULL
  mask =  ishft(1u,8-startshft) - 1     
;  dprint,dlevel=2,startbyte,startshft,endbyte,endshft,nbytes,mask
  for i = 0,nbytes-1 do begin
    v = ishft(v,8) + bytearray[startbyte+i,*]
    if mask ne 0 then begin
      v = v and mask
      mask = 0
    endif
  endfor
  if endshft ne 0 then v = ishft(v,-endshft)
  final_nbytes = (nbits-1) / 8 + 1
  if keyword_set(signed) then final_nbytes = -final_nbytes
  case final_nbytes of
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
    else:  dprint,dlevel=1,'Error',nbytes
  endcase
  return, (nd eq 1) ? v[0] : reform( v ,/overwrite)     ; get rid of annoying first dimension 0f 1 for 2D inputs    
end

