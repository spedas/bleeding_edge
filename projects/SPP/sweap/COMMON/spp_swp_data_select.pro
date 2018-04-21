; $LastChangedBy: phyllisw2 $
; $LastChangedDate: 2018-04-20 12:18:10 -0700 (Fri, 20 Apr 2018) $
; $LastChangedRevision: 25092 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/COMMON/spp_swp_data_select.pro $




function spp_swp_data_select,bytearray,startbit,nbits

  startbyte = startbit / 8; + 2
  startshft = startbit mod 8
  endbyte   = (startbit+nbits-1) / 8
  endshft  = (startbit+nbits) mod 8
  nbytes = endbyte - startbyte +1
  v=0UL
  mask = 2u ^ (8-startshft) - 1
;  dprint,startbyte,startshft,endbyte,endshft,nbytes,mask
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
    else:  dprint,'error',nbytes
  endcase
  return,v
end

