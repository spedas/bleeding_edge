pro gseos_cmnblk_gpib,pkt


data = pkt.buffer
data = float(data,0,n_elements(data)/4)
byteorder,data,/lswap,/swap_if_little_endian
dprint,dlevel=4,phelp=2,data,pkt.mid3

name = 'GPIB_'+strtrim(fix(pkt.mid3),2)
if n_elements(data) eq 6 then store_data,name,pkt.time,transpose(data),/append  $
else begin
    dprint,format='("Bad PS ",a," size",i3,"  ",10f)',name,n_elements(data),data     ; this error detection belongs in store_data
    store_data,/append,'CMNBLK_ERROR',pkt.time,3
endelse



end