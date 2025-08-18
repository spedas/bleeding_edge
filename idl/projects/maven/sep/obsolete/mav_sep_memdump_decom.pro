
function mav_sep_memdump_decom,msg  ,hkppkt=hkp    , last=last
    if msg.valid eq 0 then return,0
;    if keyword_set(hkp) then addr= hkp.mem_addr else addr = 0u
    if keyword_set(last) then LUT = last.lut  else lut = bytarr(2L^17 + 4096)
;    lastlut = lut
;    if keyword_set(last) then mlut= last.mlut else mlut= bytarr(2L^12)
;    data = msg.data
    addr = msg.data[1]   + 2L^16 * msg.data[0]
    data = byte(msg.data,4,2*n_elements(msg.data)-4)
    ndata = n_elements(data)

    lut[addr:addr+ndata-1] =  data
;    maddr = addr and 'fff'x

    mav_sep_lut_decom,lut[2L^16:2L^17-1],brr=brr,labels=labels

    strct = {time      :    msg.time,      $
            addr       :    addr  ,   $
            lut        :    lut ,  $
            range      :    brr ,  $
            valid      :    msg.valid   }

;printdat,labels
colors='BBBBGGGGMMMMRRRRCCCCYYYY'
sepn = (msg.id and '000100'b) ne 0  ; determine SEPN
SEPname = (['SEP1','SEP2'])[sepn]
store_data,SEPname+'_MEMDUMP_RANGE',dlim=struct(constant=brr,labels=labels,labflag=2,psym=-1,linestyle=1,colors=colors)

if 1 then begin
    dprint,dlevel=4,phelp=2,msg,strct
;    savetomain,strct
;    dprint,dlevel=3,'Saved memory dump to strct in main level'
    ps = get_plot_state()
    wi,5
    cols = [0,0,2,2,4,4,1,1,6,6,0,0,3,3,5,5]
    overplot=0
    for i=16L,32-1 do begin
        if overplot then  oplot, strct.lut[i * 4096:i*4096 + 4095],col=cols[i mod 16]  $
        else             plot , strct.lut[i * 4096:i*4096 + 4095],col=cols[i mod 16],ystyle=3,yrange = [0,256],xstyle=3
        overplot=1
    endfor
    restore_plot_state,ps
endif
    return,strct
end

