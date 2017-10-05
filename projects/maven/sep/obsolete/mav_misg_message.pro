
; Takes MISG packet and returns instrument message

function mav_misg_message,pkt   ;,allow_pad=allow_pad
  data = pkt.data
  if size(/type,data) eq 1 then begin
    data=uint(data,0,n_elements(data)/2)
    byteorder,data,/swap_if_little_endian
  endif
  hdr = data[0]
  id = ishft(hdr,-10)
  length = (hdr and '03ff'x) + 1
  valid  = n_elements(data)  eq length+1
;  if keyword_set(allow_pad) then valid=  1;pkt.valid
  if valid eq 0 then data=0   else   data = data[1:length]
  imsg = {time:pkt.time,valid:valid, id:id, length:length, type:2, hdr:hdr, data:data}
  return,imsg
end

