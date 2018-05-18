; $LastChangedBy: davin-mac $
; $LastChangedDate: 2018-05-17 05:03:47 -0700 (Thu, 17 May 2018) $
; $LastChangedRevision: 25232 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/COMMON/spp_swp_data_select.pro $

;  This routine extracts a single byte or uint or ulong or ulong64 from an array of bytes
;   Words can cross byte boundaries.  If items don't cross byte boundaries then it is faster to access bytes directly


function spp_swp_data_select,bytearray,startbit,nbits

  if n_elements(bytearray) * 8 lt (startbit+nbits) then begin
    dprint,dlevel=1,'Extraction error'
    stop
    return, 0
  endif
  startbyte = startbit / 8               
  startshft = startbit mod 8
  endbyte   = (startbit+nbits-1) / 8
  endshft  = 7 -  ( (startbit+nbits-1) mod 8)
  nbytes = endbyte - startbyte +1
  v=0ULL
  mask =  ishft(1u,8-startshft) - 1      ;2uL ^ (8-startshft) - 1
;  dprint,dlevel=2,startbyte,startshft,endbyte,endshft,nbytes,mask
  for i = 0,nbytes-1 do begin
    v = ishft(v,8) + bytearray[startbyte+i]
    if mask ne 0 then begin
      v = v and mask
      mask = 0
    endif
  endfor
  if endshft ne 0 then v = ishft(v,-endshft)
  case (nbits-1) / 8 + 1 of
    1:    v = byte(v)
    2:    v = uint(v)
    3:    v = ulong(v)
    4:    v = ulong(v)
    6:    v = ulong64(v)   
    8 :   v = ulong64(v)   
    else:  dprint,dlevel=2,'Error',nbytes
  endcase
  return,v
end

