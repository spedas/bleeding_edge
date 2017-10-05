; this routine takes a packet (either from MISG or APID30) and returns the instrument message.

function mav_inst_msg,wbuffer,time,pkt=pkt
;  wbuffer = pkt.buffer
  if keyword_set(pkt) then begin
      wbuffer = pkt.data
      if size(/type,wbuffer) eq  1 then begin                  ; convert from bytes to words
          wbuffer = uint(wbuffer,0,n_elements(wbuffer)/2)
          byteorder,wbuffer,/swap_if_little_endian
      endif
      time = pkt.time
  endif
  hdr = wbuffer[0]
  id = ishft(hdr,-10)
  length = (hdr and '03ff'x) + 1
  valid  = n_elements(wbuffer)  ge length+1         ; should be eq  - extra word slipping in somewhere
  if valid eq 0 then data=0   else    data = wbuffer[1:length]
  ;data = wbuffer[1:length]
  imsg = {time:time,valid:valid, id:id, length:length, hdr:hdr, data:data}
  return,imsg
end

; this routine takes a packet (either from MISG or APID30) and processes it.


pro mav_inst_msg_handler,pkt,status=status

    msg = mav_inst_msg(pkt=pkt)
    if (msg.valid eq 0) then begin
         tstr='Invalid MISG Message'
         dprint,dlevel=3,tstr
         store_data,'CMNBLK_ERROR',pkt.time,tstr,/append,dlim={tplot_routine:'strplot'}
    endif 

 ;   mav_sep_msg_handler,msg,status=status
    mav_sta_msg_handler,msg
   ; printdat,msg,/hex
  ;  hexprint,msg.data
    
   
;    mav_lpw_msg_handler,msg


end

